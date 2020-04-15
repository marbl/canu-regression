#!/usr/bin/env perl

###############################################################################
 #
 #  This file is part of canu, a software program that assembles whole-genome
 #  sequencing reads into contigs.
 #
 #  This software is based on:
 #    'Celera Assembler' r4587 (http://wgs-assembler.sourceforge.net)
 #    the 'kmer package' r1994 (http://kmer.sourceforge.net)
 #
 #  Except as indicated otherwise, this is a 'United States Government Work',
 #  and is released in the public domain.
 #
 #  File 'README.licenses' in the root directory of this distribution
 #  contains full conditions and disclaimers.
 ##

use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/regression";
use Slack;

#
#  Some functions first.  (Search for 'parse' to find the start of main.)
#

sub linediffprint ($) {
    my $l = shift @_;

    $l =~ s/\s+$//;

    return("$l\n");
}

sub linediff ($$$) {
    my $reffile = shift @_;
    my $asmfile = shift @_;
    my $outfile = shift @_;
    my $l = 1;

    open(A, "< $reffile");
    open(B, "< $asmfile");
    open(O, "> $outfile");

    my @hist;
    my $extraP = 0;

    while (!eof(A) && !eof(B)) {
        my $a = <A>;  chomp $a;
        my $b = <B>;  chomp $b;

        $a =~ s/\t/ /g;
        $b =~ s/\t/ /g;

        if ($a ne $b) {
            foreach my $h (@hist) {
                print O $h;
            }
            undef @hist;
            print O linediffprint(sprintf "! %-8d %-100.100s  %-100.100s\n", $l, $a, $b);
            $extraP = 10;
        }
        else {
            if ($extraP > 0) {
                $extraP--;
                print O linediffprint(sprintf "= %-8d %-100.100s  %-100.100s\n", $l, $a, $b);
            } else {
                push @hist, linediffprint(sprintf "= %-8d %-100.100s  %-100.100s\n", $l, $a, $b);
                if (scalar(@hist) > 10) {
                    shift @hist;
                }
            }
        }

        $l++;
    }

    close(A);
    close(B);
    close(O);
}



sub diffA ($$) {
    my $recipe = shift @_;
    my $file   = shift @_;

    my $reffile = "../../recipes/$recipe/refasm/$file";
    my $asmfile = "./$file";

    my $refpresent = -e $reffile ? 1 : 0;
    my $asmpresent = -e $asmfile ? 1 : 0;

    return("SAME $file")   if (($refpresent == 0) && ($asmpresent == 0));
    return("MISS $file")   if (($refpresent == 1) && ($asmpresent == 0));
    return("NEW  $file")   if (($refpresent == 0) && ($asmpresent == 1));

    #  Both files exist.  Compare them.

    my $refsum = `cat $reffile | shasum`;
    my $asmsum = `cat $asmfile | shasum`;

    return("SAME $file")   if ($refsum eq $asmsum);

    linediff($reffile, $asmfile, "$asmfile.diffs");

    return("DIFF $file");
}



sub diffB ($$) {
    my $recipe = shift @_;
    my $file   = shift @_;

    my $reffile = "../../recipes/$recipe/refasm/$file";
    my $asmfile = "./$file";

    my $refpresent = -e $reffile ? 1 : 0;
    my $asmpresent = -e $asmfile ? 1 : 0;

    return("SAME $file")   if (($refpresent == 0) && ($asmpresent == 0));
    return("MISS $file")   if (($refpresent == 1) && ($asmpresent == 0));
    return("NEW  $file")   if (($refpresent == 0) && ($asmpresent == 1));

    #  Both files exist.  Compare them.

    my $refsum = `cat $reffile | shasum`;
    my $asmsum = `cat $asmfile | shasum`;

    return("SAME $file")   if ($refsum eq $asmsum);
    return("DIFF $file");
}

#
#  Parse the command line.
#

my $doHelp     = 0;
my $recipe     = undef;
my $regression = undef;
my $asm        = "asm";
my $failed     = 0;
my $md5        = "md5sum";

$md5 = "/sbin/md5"         if (-e "/sbin/md5");         #  BSDs.
$md5 = "/usr/bin/md5sum"   if (-e "/usr/bin/md5sum");   #  Linux.

while (scalar(@ARGV) > 0) {
    my $arg = shift @ARGV;

    if    ($arg eq "-recipe") {
        $recipe = shift @ARGV;
    }

    elsif ($arg eq "-regression") {
        $regression = shift @ARGV;

        #  Parse date-branch-hash from name, limit hash to 12 letters.
        if ($regression =~ m/(\d\d\d\d-\d\d-\d\d-\d\d\d\d)(-*.*)-(............)/) {
            $regression = "$1$2-$3";
        }
    }

    elsif ($arg eq "-assembly") {
        $asm = shift @ARGV;
    }

    elsif ($arg eq "-fail") {
        $failed = 1;
    }

    else {
        die "unknown option '$arg'.\n";
    }
}

$doHelp = 1   if (!defined($recipe));
$doHelp = 1   if (!defined($regression));

if ($doHelp) {
    print STDERR "usage: $0 ...\n";
    print STDERR "  -recipe R       Name of recipe for this test.\n";
    print STDERR "  -regression R   Directory name of regression test.\n";
    print STDERR "  -assembly A     Name of assembly files (default 'asm').\n";
    print STDERR "\n";
    print STDERR "  -fail           If set, report the assembly failed to finish.\n";
    print STDERR "\n";
    exit(0);
}


if ($failed) {
    my @lines;
    my $linesLen = 0;

    if (open(F, "< canu.out")) {
        while (<F>) {
            $linesLen += length($_);
            push @lines, $_;

            while ((scalar(@lines) > 0) && ($linesLen > 2000)) {
                $linesLen -= length($lines[0]);
                shift @lines;
            }
        }
        close(F);
    }

    my $lines = join "", @lines;

    postHeading(":bangbang: *$recipe* crashed in _${regression}_.");
    postText(undef, $lines);

    exit(1);
}

my @dr;

push @dr, diffA($recipe, "asm.report");

push @dr, diffA($recipe, "asm.seqStore/errorLog");
push @dr, diffA($recipe, "asm.seqStore/info.txt");

#iffA($recipe, "asm.seqStore/readlengths-cor.png");
#iffA($recipe, "asm.seqStore/readlengths-obt.png");
#iffA($recipe, "asm.seqStore/readlengths-utg.png");

push @dr, diffA($recipe, "asm.seqStore/readlengths-cor.dat");
push @dr, diffA($recipe, "asm.seqStore/readlengths-obt.dat");
push @dr, diffA($recipe, "asm.seqStore/readlengths-utg.dat");

#iffA($recipe, "asm.correctedReads.fasta.gz");
#iffA($recipe, "asm.trimmedReads.fasta.gz");

#iffA($recipe, "asm.contigs.fasta");
push @dr, diffA($recipe, "asm.contigs.layout.readToTig");
push @dr, diffA($recipe, "asm.contigs.layout.tigInfo");

#iffA($recipe, "canu-scripts.tar.gz");

push @dr, diffA($recipe, "correction/asm.loadCorrectedReads.log");
push @dr, diffA($recipe, "correction/2-correction/asm.readsToCorrect.log");

push @dr, diffA($recipe, "trimming/3-overlapbasedtrimming/asm.1.trimReads.log");
push @dr, diffA($recipe, "trimming/3-overlapbasedtrimming/asm.2.splitReads.log");

push @dr, diffB($recipe, "unitigging/3-overlapErrorAdjustment/red.red");
push @dr, diffA($recipe, "unitigging/4-unitigger/asm.001.filterOverlaps.thr000.num000.log");
push @dr, diffA($recipe, "unitigging/4-unitigger/asm.003.buildGreedy.sizes");
push @dr, diffA($recipe, "unitigging/4-unitigger/asm.010.mergeOrphans.thr000.num000.log");
push @dr, diffA($recipe, "unitigging/4-unitigger/asm.012.breakRepeats.thr000.num000.log");
push @dr, diffA($recipe, "unitigging/4-unitigger/asm.012.breakRepeats.sizes");
push @dr, diffA($recipe, "unitigging/4-unitigger/asm.best.edges");
push @dr, diffA($recipe, "unitigging/4-unitigger/unitigger.err");

push @dr, diffA($recipe, "quast/report.txt");

push @dr, diffA($recipe, "quast/transposed_report.txt");

push @dr, diffA($recipe, "quast/contigs_reports/misassemblies_report.txt");
push @dr, diffA($recipe, "quast/contigs_reports/transposed_report_misassemblies.txt");
push @dr, diffA($recipe, "quast/contigs_reports/unaligned_report.txt");



my $newf = "";
my $misf = "";
my $samf = "";
my $diff = "";
my $faif = "";
my $difc = 0;

foreach my $dr (@dr) {
    if    ($dr =~ m/^NEW\s+(.*)/) {
        $newf .= "$1 (NEW in assembly)\n";
        $difc += 1;
    }

    elsif ($dr =~ m/^MISS\s+(.*)/) {
        $misf .= "$1 (MISSING from assembly)\n";
        $difc += 1;
    }

    elsif ($dr =~ m/^SAME\s+(.*)/) {
        $samf .= "$1\n";
    }

    elsif ($dr =~ m/^DIFF\s+(.*)/) {
        $diff .= "$1\n";
        $difc += 1;
    }

    else {
        $faif .= "$1 (UNKNOWN)\n";
        $difc += 1;
    }
}

if ($difc == 0) {
    print ":canu_success: *$recipe* passed in _${regression}_.\n";
    postHeading(":canu_success: *$recipe* passed in _${regression}_.");
    exit(0);
}

print ":canu_fail: *$recipe* has differences in _${regression}_.\n";
postHeading(":canu_fail: *$recipe* has differences in _${regression}_.");

if ($newf ne "") {
    postText(undef, $newf);
}

if ($misf ne "") {
    postText(undef, $misf);
}

if ($diff ne "") {
    postText(undef, $diff);
}

if ($faif ne "") {
    postText(undef, $faif);
}

exit(0);
