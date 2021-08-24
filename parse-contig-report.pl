#!/usr/bin/perl

use strict;
use List::Util qw(min max);

my (@misasm, $type, $aid, $b1, $e1, $b2, $e2, $l1, $l2, $idt, $n1, $n2);

sub filterQuastStdout ($$) {
    my $in = shift @_;
    my $ot = shift @_;

    open(IN, "< $in") or die "failed to open '$in' for reading: $!\n";

    while (<IN>) {
        s/^\s+//;
        s/\s+$//;

        #Real Alignment 1: 18027364 18061019 | 4 33649 | 33656 33646 | 99.92 | 2L tig00001804
        if (m!^\s*Real\sAlignment\s(\d+):\s(\d+)\s(\d+)\s\|\s(\d+)\s(\d+)\s\|\s(\d+)\s(\d+)\s\|\s(\d+.\d+)\s\|\s(.*)\s(.*)\s*$!) {
            if ($type ne "") {
                my $msg1 = sprintf("%15s %10d-%-10d %10d-%-10d %s\n", $n1, $b1, $e1, $2, $3, $9);
                my $msg2 = sprintf("%-23s %6.3f%%%15s%6.3f%%\n", $type, $idt, "", $8);
                my $msg3 = sprintf("%15s %10d-%-10d %10d-%-10d %s\n", $n2, $b2, $e2, $4, $5, $10);

                push @misasm, "$n1$b1\0\n$msg1$msg2$msg3";
            }

            ($type, $aid, $b1, $e1, $b2, $e2, $l1, $l2, $idt, $n1, $n2) = ("", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10);

            #$type = "";
            #$aid = $1;
            #$b1  = $2;
            #$e1  = $3;
            #$b2  = $4;
            #$e2  = $5;
            #$l1  = $6;
            #$l2  = $7;
            #$idt = $8;
            #$n1  = $9;
            #$n2  = $10;
        }

        if (m/^\s*Extensive\smisassembly\s\(inversion\)\sbetween/) {
            $type = "INVERSION";
        }

        if (m/^\s*Extensive\smisassembly\s\(translocation\)\sbetween/) {
            $type = "TRANSLOCATION";
        }

        if (m/^\s*Extensive\smisassembly\s\(relocation,\sinconsistency\s=\s(-*[0-9]*)\)\sbetween/) {
            $type = "RELOCATION";
        }
    }

    close(IN);
}


if (! -e "$ARGV[0]") {
    die "usage: $0 <contigs_report_asm-contigs.stdout>\n";
}

filterQuastStdout("$ARGV[0]", "$ARGV[0].filtered");

@misasm = sort @misasm;

foreach my $m (@misasm) {
    my ($pos, $msg) = split '\0', $m;

    print $msg;
}

exit(0);
