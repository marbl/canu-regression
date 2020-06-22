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

use List::Util qw(min max);

#
#  Some functions first.  (Search for 'parse' to find the start of main.)
#

sub readFile ($$$) {
    my $file = shift @_;
    my $linelimit = shift @_;
    my $sizelimit = shift @_;

    my $nl = 0;
    my $nb = 0;

    my $lines;

    if (-e "$file") {
        open(F, "< $file");
        while (!eof(F) && ($nl < $linelimit) && ($nb < $sizelimit)) {
            $_ = <F>;

            $lines .= $_;

            $nl += 1;
            $nb += length($_);
        }
        close(F);
    }

    if (!defined($lines)) {
        return(undef);
    }

    return("${file}:\n```\n${lines}```\n");
}



sub linediffprint ($) {
    my $l = shift @_;

    $l =~ s/\s+$//;

    return("$l\n");
}

sub linediff ($$$$@) {
    my $reffile = shift @_;
    my $asmfile = shift @_;
    my $outfile = shift @_;
    my $n       = shift @_;   #  Width of line number in report.
    my $w       = shift @_;   #  Max length of a line in the report (per file).
    my $l       = 1;
    my $m       = shift @_;   #  Max number of lines to process.
    my $context = 5;

    $n =        8   if (!defined($n) || ($n == 0));
    $w =      100   if (!defined($w) || ($w == 0));
    $m = 10000000   if (!defined($m) || ($m == 0));

    my $hfmt = "  %-${n}s %${w}.${w}s ][ %-${w}.${w}s\n";
    my $dfmt = "! %-${n}d %-${w}.${w}s ][ %-${w}.${w}s\n";
    my $sfmt = "= %-${n}d %-${w}.${w}s ][ %-${w}.${w}s\n";

    open(A, "< $reffile");
    open(B, "< $asmfile");
    open(O, "> $outfile");

    print O linediffprint(sprintf($hfmt, " ", "REFERENCE ASSEMBLY", "REGRESSION ASSEMBLY"));

    my @hist;
    my $extraP = 0;

    while ((!eof(A) ||
            !eof(B)) &&
           ($l <= $m)) {
        my $a = <A>;
        my $b = <B>;

        $a = ""   if (!defined($a));
        $b = ""   if (!defined($b));

        $a =~ s/\t/ /g;
        $b =~ s/\t/ /g;

        chomp $a;
        chomp $b;

        if ($a ne $b) {
            foreach my $h (@hist) {
                print O $h;
            }
            undef @hist;
            print O linediffprint(sprintf($dfmt, $l, $a, $b));
            $extraP = $context;
        }
        else {
            if ($extraP > 0) {
                $extraP--;
                print O linediffprint(sprintf($sfmt, $l, $a, $b));
            } else {
                push @hist, linediffprint(sprintf($sfmt, $l, $a, $b));
                if (scalar(@hist) > $context) {
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



sub diffA ($$$$$$$$@) {
    my $newf   = shift @_;
    my $misf   = shift @_;
    my $samf   = shift @_;
    my $diff   = shift @_;
    my $faif   = shift @_;
    my $difc   = shift @_;
    my $recipe = shift @_;
    my $file   = shift @_;
    my $n      = shift @_;   #  optional, see linediff() above
    my $w      = shift @_;   #  optional, see linediff() above
    my $m      = shift @_;   #  optional, see linediff() above

    my $reffile = "../../recipes/$recipe/refasm/$file";
    my $asmfile = "./$file";

    my $refpresent = -e $reffile ? 1 : 0;
    my $asmpresent = -e $asmfile ? 1 : 0;

    if (($refpresent == 0) && ($asmpresent == 0))  { $$samf .= "  $file\n";             return(0); }
    if (($refpresent == 1) && ($asmpresent == 0))  { $$misf .= "  $file\n";  $$difc++;  return(0); }
    if (($refpresent == 0) && ($asmpresent == 1))  { $$newf .= "  $file\n";  $$difc++;  return(0); }

    #  Both files exist.  Compare them.

    my $refsum = `cat $reffile | shasum`;
    my $asmsum = `cat $asmfile | shasum`;

    if ($refsum eq $asmsum)  { $$samf .= "  $file\n";             return(0); }
    else                     { $$diff .= "  $file\n";  $$difc++;             }

    linediff($reffile, $asmfile, "$asmfile.diffs", $n, $w, $m);

    return(1);
}



sub diffB ($$$$$$$$) {
    my $newf   = shift @_;
    my $misf   = shift @_;
    my $samf   = shift @_;
    my $diff   = shift @_;
    my $faif   = shift @_;
    my $difc   = shift @_;
    my $recipe = shift @_;
    my $file   = shift @_;

    my $reffile = "../../recipes/$recipe/refasm/$file";
    my $asmfile = "./$file";

    my $refpresent = -e $reffile ? 1 : 0;
    my $asmpresent = -e $asmfile ? 1 : 0;

    if (($refpresent == 0) && ($asmpresent == 0))  { $$samf .= "  $file\n";             return(0); }
    if (($refpresent == 1) && ($asmpresent == 0))  { $$misf .= "  $file\n";  $$difc++;  return(0); }
    if (($refpresent == 0) && ($asmpresent == 1))  { $$newf .= "  $file\n";  $$difc++;  return(0); }

    #  Both files exist.  Compare them.

    my $refsum = `cat $reffile | shasum`;
    my $asmsum = `cat $asmfile | shasum`;

    if ($refsum eq $asmsum)  { $$samf .= "  $file\n";             return(0); }
    else                     { $$diff .= "  $file\n";  $$difc++;  return(1); }
}



sub filterQuastReport ($$) {
    my $in = shift @_;
    my $ot = shift @_;
    my $ml = 0;

    open(IN, "< $in") or die "failed to open '$in' for reading: $!\n";
    open(OT, "> $ot") or die "failed to open '$ot' for writing: $!\n";

    $_ = <IN>;   #  Parameters
    $_ = <IN>;   #  Blank line
    $_ = <IN>;   #  Assembly name

    while (<IN>) {
        next   if ($_ =~ m/Assembly/);
        next   if ($_ =~ m/>=\s1000\sbp/);
        next   if ($_ =~ m/>=\s5000\sbp/);
        next   if ($_ =~ m/>=\s10000\sbp/);
        next   if ($_ =~ m/>=\s25000\sbp/);
        next   if ($_ =~ m/N50/);
        next   if ($_ =~ m/N75/);
        next   if ($_ =~ m/L50/);
        next   if ($_ =~ m/L75/);
        next   if ($_ =~ m/scaffold\sgap/);
        next   if ($_ =~ m/N.s\sper/);
        next   if ($_ =~ m/NA50/);
        next   if ($_ =~ m/NGA50/);
        next   if ($_ =~ m/NA75/);
        next   if ($_ =~ m/NGA75/);
        next   if ($_ =~ m/LA50/);
        next   if ($_ =~ m/LGA50/);
        next   if ($_ =~ m/LA75/);
        next   if ($_ =~ m/LGA75/);

        print OT $_;

        $ml = max($ml, length($_));
    }

    close(OT);
    close(IN);

    return $ml;
}



sub filterQuastStdout ($$) {
    my $in = shift @_;
    my $ot = shift @_;
    my $lt;
    my $ml = 0;

    open(IN, "< $in") or die "failed to open '$in' for reading: $!\n";
    open(OT, "> $ot") or die "failed to open '$ot' for writing: $!\n";

    while (<IN>) {
        s/^\s+//;
        s/\s+$//;

        if (m/^\s*Extensive\smisass/) {
            print OT "$lt\n";
            print OT "  $_\n";

            $ml = max($ml, length($lt));
            $ml = max($ml, length($_) + 2);
        }

        $lt = $_;
    }

    close(OT);
    close(IN);

    return $ml;
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
my $postSlack  = 1;
my $refregr    = "(nothing)";

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

    elsif ($arg eq "-no-slack") {
        $postSlack = 0;
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

    if ($postSlack == 1) {
        postHeading(":bangbang: *$recipe* crashed in _${regression}_.");
        postCodeBlock(undef, $lines);
    } else {
        print STDERR ("BANG $recipe crashed in ${regression}.");
        print STDERR $lines;
    }

    exit(1);
}

my @dr;

#  Attempt to figure out what we're comparing against.

{
    open(F, "ls -l ../../recipes/$recipe |");
    while (<F>) {
        if (m/refasm\s->\srefasm-(20.*-............)$/) {
            $refregr = $1;
        }
    }
    close(F);
}


#  Prepare for comparision!

my $IGNF = "";   #  To just ignore these reports.
my $newf = "";
my $misf = "";
my $samf = "";
my $diff = "";
my $faif = "";

my $IGNC = 0;
my $difc = 0;

my $report;
my @logs;

$report  = "*Report* for ${recipe}.\n";
$report .= "*Compare* ${regression} against reference ${refregr}.\n";
$report .= "\n";

my $d00 = diffA(\$newf, \$misf, \$samf, \$diff, \$faif, \$difc, $recipe, "asm.report");

$report .= "The *assembly report* has changed.\n"       if ($d00);


########################################
#  Check seqStore, report differences in what was loaded.
#

my $d01 = diffA(\$newf, \$misf, \$samf, \$diff, \$faif, \$difc, $recipe, "asm.seqStore/errorLog");
my $d02 = diffA(\$newf, \$misf, \$samf, \$diff, \$faif, \$difc, $recipe, "asm.seqStore/info.txt", 2, 60, 99);

$report .= "Both seqStore *errorLog* and *info.txt* changed.\n"       if ( $d01 &&  $d02);
$report .= "seqStore *info.txt* changed; errorLog is the same.\n"   if (!$d01 &&  $d02);
$report .= "seqStore *errorLog* changed; info.txt is the same.\n"   if ( $d01 && !$d02);

if ($d02) {
    push @logs, readFile("asm.seqStore/info.txt.diffs", 50, 8192);
}

########################################
#  Check read lengths
#

#iffA(\$newf, \$misf, \$samf, \$diff, \$faif, \$difc, $recipe, "asm.seqStore/readlengths-cor.png");
#iffA(\$newf, \$misf, \$samf, \$diff, \$faif, \$difc, $recipe, "asm.seqStore/readlengths-obt.png");
#iffA(\$newf, \$misf, \$samf, \$diff, \$faif, \$difc, $recipe, "asm.seqStore/readlengths-utg.png");

my $d03 = diffA(\$newf, \$misf, \$samf, \$diff, \$faif, \$difc, $recipe, "asm.seqStore/readlengths-cor.dat");
my $d04 = diffA(\$newf, \$misf, \$samf, \$diff, \$faif, \$difc, $recipe, "asm.seqStore/readlengths-obt.dat");
my $d05 = diffA(\$newf, \$misf, \$samf, \$diff, \$faif, \$difc, $recipe, "asm.seqStore/readlengths-utg.dat");

$report .= "*Uncorrected read lengths* changed.\n"                              if ( $d03 && !$d04 && !$d05);
$report .= "*Corrected read lengths* changed.\n"                                if (!$d03 &&  $d04 && !$d05);
$report .= "*Trimmed read lengths*  changed.\n"                                 if (!$d03 && !$d04 &&  $d05);

$report .= "Both *uncorrected and corrected read lengths* changed.\n"           if ( $d03 &&  $d04 && !$d05);
$report .= "Both *corrected and trimmed read lengths* changed.\n"               if ( $d03 && !$d04 &&  $d05);
$report .= "Both *uncorrected and trimmed read lengths* changed.\n"             if (!$d03 &&  $d04 &&  $d05);

$report .= "*Uncorrected, corrected and trimmed read lengths* all changed.\n"   if ( $d03 &&  $d04 &&  $d05);

########################################
#  Not sure how to check the intermediate reads, so we don't do it directly.
#

#iffA(\$newf, \$misf, \$samf, \$diff, \$faif, \$difc, $recipe, "asm.correctedReads.fasta.gz");
#iffA(\$newf, \$misf, \$samf, \$diff, \$faif, \$difc, $recipe, "asm.trimmedReads.fasta.gz");

my $d09 = diffA(\$newf, \$misf, \$samf, \$diff, \$faif, \$difc, $recipe, "correction/2-correction/asm.readsToCorrect.log");
my $d10 = diffA(\$newf, \$misf, \$samf, \$diff, \$faif, \$difc, $recipe, "correction/asm.loadCorrectedReads.log");

$report .= "The *list of reads to correct* changed.\n"          if ($d09);
$report .= "The *loading of corrected reads* has changed.\n"    if ($d10 && !$d09 && !$d04);

my $d11 = diffA(\$newf, \$misf, \$samf, \$diff, \$faif, \$difc, $recipe, "trimming/3-overlapbasedtrimming/asm.1.trimReads.log");
my $d12 = diffA(\$newf, \$misf, \$samf, \$diff, \$faif, \$difc, $recipe, "trimming/3-overlapbasedtrimming/asm.2.splitReads.log");

$report .= "*Read trimming logs* changed.\n"    if ($d11);
$report .= "*Read splitting logs* changed.\n"   if ($d12);

########################################
#  We save the scripts, but it's not terribly useful to diff them.
#
#iffA(\$newf, \$misf, \$samf, \$diff, \$faif, \$difc, $recipe, "canu-scripts.tar.gz");


########################################
#  All we can check for OEA is the binary file of corrections to reads.

my $d13 = diffB(\$newf, \$misf, \$samf, \$diff, \$faif, \$difc, $recipe, "unitigging/3-overlapErrorAdjustment/red.red");

$report .= "*OEA binary output 'red.red'* has changed.\n"   if ($d13);

########################################
#  bogart has a bazillion logs we can test, a file that we definitely care if
#  it has any changes, and a few summary stats we can report.

my $d14 = diffA(\$IGNF, \$IGNF, \$IGNF, \$IGNF, \$IGNF, \$IGNC, $recipe, "unitigging/4-unitigger/asm.001.filterOverlaps.thr000.num000.log");
my $d15 = diffA(\$IGNF, \$IGNF, \$IGNF, \$IGNF, \$IGNF, \$IGNC, $recipe, "unitigging/4-unitigger/asm.010.mergeOrphans.thr000.num000.log");
my $d16 = diffA(\$IGNF, \$IGNF, \$IGNF, \$IGNF, \$IGNF, \$IGNC, $recipe, "unitigging/4-unitigger/asm.012.breakRepeats.thr000.num000.log");
my $d17 = diffA(\$IGNF, \$IGNF, \$IGNF, \$IGNF, \$IGNF, \$IGNC, $recipe, "unitigging/4-unitigger/unitigger.err");

my $d18 = diffA(\$newf, \$misf, \$samf, \$diff, \$faif, \$difc, $recipe, "unitigging/4-unitigger/asm.best.edges");
my $d19 = diffA(\$newf, \$misf, \$samf, \$diff, \$faif, \$difc, $recipe, "unitigging/4-unitigger/asm.003.buildGreedy.sizes");
my $d20 = diffA(\$newf, \$misf, \$samf, \$diff, \$faif, \$difc, $recipe, "unitigging/4-unitigger/asm.012.breakRepeats.sizes");

$report .= "*Bogart logging* has differences.\n"                    if ($d14 || $d15 || $d16 || $d17);
$report .= "*Bogart best edges* are different!\n"                   if ($d18);
$report .= "*Bogart initial greedy contig sizes* are different.\n"  if ($d19);
$report .= "*Bogart post-splitting contig sizes* are different.\n"  if ($d20);

########################################
#  Check assembled contigs and the read layouts.  All we can do is report difference.
#

my $d06 = diffB(\$newf, \$misf, \$samf, \$diff, \$faif, \$difc, $recipe, "asm.contigs.fasta");
my $d07 = diffA(\$newf, \$misf, \$samf, \$diff, \$faif, \$difc, $recipe, "asm.contigs.layout.readToTig");
my $d08 = diffA(\$newf, \$misf, \$samf, \$diff, \$faif, \$difc, $recipe, "asm.contigs.layout.tigInfo");

$report .= "*Contig sequences* have changed!  (but layouts and metadata are the same)\n"     if ( $d06 && !$d07 && !$d08);
$report .= "*Contig layouts* have changed!  (but sequence and metadata are the same)\n"      if (!$d06 &&  $d07 && !$d08);
$report .= "*Contig metadata* has changed!  (but sequence and layouts are the same)\n"       if (!$d06 && !$d07 &&  $d08);

$report .= "*Contig sequences and layouts* have changed!  (but metadata is the same)\n"      if ( $d06 &&  $d07 && !$d08);
$report .= "*Contig sequences and metadata* have changed!  (but layouts are the same)\n"     if ( $d06 && !$d07 &&  $d08);
$report .= "*Contig layouts and metadata* have changed!  (but sequences are the same)\n"     if (!$d06 &&  $d07 &&  $d08);

$report .= "*Contig sequences, layouts and metadata* have all changed!\n"                    if ( $d06 &&  $d07 &&  $d08);

########################################
#  The primary check here is from quast.

my $qrp = filterQuastReport("quast/report.txt", "quast/report.txt.filtered");
my $qml = filterQuastStdout("quast/contigs_reports/contigs_report_asm-contigs.stdout", "quast/contigs_reports/contigs_report_asm-contigs.stdout.filtered");

my $d21 = diffA(\$newf, \$misf, \$samf, \$diff, \$faif, \$difc, $recipe, "quast/report.txt.filtered", 2, $qrp, 99);

my $d23 = diffA(\$newf, \$misf, \$samf, \$diff, \$faif, \$difc, $recipe, "quast/contigs_reports/misassemblies_report.txt");
my $d24 = diffA(\$newf, \$misf, \$samf, \$diff, \$faif, \$difc, $recipe, "quast/contigs_reports/transposed_report_misassemblies.txt");
my $d25 = diffA(\$newf, \$misf, \$samf, \$diff, \$faif, \$difc, $recipe, "quast/contigs_reports/unaligned_report.txt");

my $d26 = diffA(\$newf, \$misf, \$samf, \$diff, \$faif, \$difc, $recipe, "quast/contigs_reports/contigs_report_asm-contigs.mis_contigs.info");
my $d27 = diffA(\$newf, \$misf, \$samf, \$diff, \$faif, \$difc, $recipe, "quast/contigs_reports/contigs_report_asm-contigs.unaligned.info");

my $d28 = diffA(\$newf, \$misf, \$samf, \$diff, \$faif, \$difc, $recipe, "quast/contigs_reports/contigs_report_asm-contigs.stdout.filtered", 2, $qml, 99);

$report .= "*Quast* has differences.\n"   if ($d21 || $d23 || $d24 || $d25 || $d26 || $d27 || $d28);

if ($d21) {
    push @logs, readFile("quast/report.txt.filtered.diffs", 60, 8192);
}

#if ($d26) {
#    push @logs, readFile("quast/contigs_reports/contigs_report_asm-contigs.mis_contigs.info.diffs", 60, 8192);
#}

#if ($d27) {
#    push @logs, readFile("quast/contigs_reports/contigs_report_asm-contigs.unaligned.info.diffs", 60, 8192);
#}

if ($d28) {
    push @logs, readFile("quast/contigs_reports/contigs_report_asm-contigs.stdout.filtered.diffs", 60, 8192);
}

else {
    push @logs, readFile("quast/contigs_reports/contigs_report_asm-contigs.stdout.filtered", 60, 8192);
}




#  Merge all the various differences found above into a single report.

if ($newf ne "") {
    $report .= "\n";
    $report .= "Files *without a reference* to compare against:\n";
    $report .= $newf;
}

if ($misf ne "") {
    $report .= "\n";
    $report .= "Files *missing* from the assembly:\n";
    $report .= $misf;
}

if ($faif ne "") {
    $report .= "\n";
    $report .= "Files that *failed* to return a valid comparison result:\n";
    $report .= $faif;
}

#  Report the results.

if ($difc == 0) {

    if ($postSlack == 1) {
        postHeading(":canu_success: *$recipe* has no differences between _${regression}_ and reference _${refregr}_.");
    } else {
        print "SUCCESS $recipe has no differences between ${regression} and reference _${refregr}_.\n";
    }
}

else {
    if ($postSlack == 1) {
        postHeading(":canu_fail: *$recipe* has differences between _${regression}_ and reference _${refregr}_.");
        postFormattedText(undef, $report);
        foreach my $log (@logs) {
            postFormattedText(undef, $log);
        }
    } else {
        print "FAIL $recipe has differences between ${regression} and reference _${refregr}_.\n";
        print $report;
        foreach my $log (@logs) {
            print "\n----------------------------------------\n";
            print $log;
        }
    }
}

#  And leave.

exit(0);
