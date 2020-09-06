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

use Time::Local;
use Cwd qw(getcwd abs_path);

my $wrkdir        = abs_path(".");
my $gitrepo       = abs_path("canu-master-repo");   #  NEEDS to be full path, not relative, for rsync.

my $tz            = `date +%z`;              chomp $tz;     #  What timezone we're in.
my $now           = `date +%Y-%m-%d-%H%M`;   chomp $now;    #  Current date and time.
my $dow           = `date +%w`;              chomp $dow;    #  Day of week, used to decide when to run big tests.

#
#  Parse the command line.
#

my $doHelp   = 0;
my $errs     = "";
my $doFetch  = 1;
my $date     = undef;
my $branch   = "master";
my $hash     = undef;
my $canu     = "";

my $regr     = undef;      #  Eventually set to "$date-$branch-$hash"
my $tests    = undef;
my @recipes;

while (scalar(@ARGV) > 0) {
    my $arg  = shift @ARGV;
    my $test = $arg;
    my $recp = $arg;

    $test =~ s/-//;
    $test =~ tr/a-z/A-Z/;
    $test =  "zzz$test";

    $recp =~ s!recipes/!!;

    if   (($arg eq "-h") ||
          ($arg eq "-help")) {
        $doHelp = 1;
    }

    elsif ($arg eq "-fetch") {
        $doFetch = 1;
    }

    elsif ($arg eq "-no-fetch") {
        $doFetch = 0;
    }

    elsif ($arg eq "-branch") {
        $branch = shift @ARGV;
    }

    elsif ($arg eq "-master") {
        $branch = "master";
    }

    elsif ($arg eq "-latest") {
        $hash = undef;
        $date = $now;
    }

    elsif ($arg eq "-hash") {
        $hash = shift @ARGV;
        $date = undef;
    }

    elsif ($arg eq "-date") {
        $hash = undef;
        $date = shift @ARGV;
    }

    elsif ($arg eq "-canu") {
        $canu = shift @ARGV;
        $hash = undef;
        $date = $now
    }

    elsif ($arg eq "-quick")             {  $tests = "zzzQUICK";   }
    elsif ($arg eq "-daily")             {  $tests = "zzzDAILY";   }
    elsif ($arg eq "-weekly")            {  $tests = "zzzWEEKLY";  }
    elsif (-e "recipes/$test")           {  $tests = $test;        }
    elsif (-e "recipes/$recp/submit.sh") {  push @recipes, $recp;  }

    else {
        $errs .= "ERROR: Unknown option '$arg'.\n";
    }
}

$errs .= "ERROR: Exactly one of -latest, -date, -hash or -canu must be supplied.\n"   if (!defined($date) && !defined($hash) && ($canu eq ""));
$errs .= "ERROR: Exactly one of -latest, -date, -hash or -canu must be supplied.\n"   if ( defined($date) &&  defined($hash) && ($canu eq ""));
$errs .= "ERROR: Test file 'recipe/$tests' doesn't exist.\n"                          if ((defined($tests)) && (! -e "recipes/$tests"));
$errs .= "ERROR: -canu path must be to root of git clone.\n"                          if (($canu ne "") && (! -e "$canu/.git"));

checkSlack();

if (($doHelp) || ($errs ne "")) {
    print "usage: $0 [options] [recipe-class | recipe-list]\n";
    print "  -(no-)fetch  Fetch (or not) updates to the repository.\n";
    print "\n";
    print "BRANCH SELECTION\n";
    print "  -branch B    Test branch 'B'.\n";
    print "  -master      Test the master branch (default).\n";
    print "\n";
    print "CODE SELECTION (exactly one must be supplied)\n";
    print "  -latest      Use the latest code.\n";
    print "  -hash H      Use a specific historical hash.\n";
    print "  -date D      Use a specific historical date.  Format YYYY-MM-DD-HHMM.\n";
    print "\n";
    print "  -canu P      Use a pre-compiled version found in path P.\n";
    print "\n";
    print "TEST SELECTION (exactly one must be supplied)\n";
    print "  -quick       Lambda, both PacBio and Nanopore.\n";
    print "  -daily       Several drosophila, PacBio, Nanopore and HiFi.\n";
    print "  -weekly      (nothing yet)\n";
    print "\n";
    print "Logging ends up in Slack.  Progress is reported to stdout.\n";
    print "\n";

    print "$errs\n"   if ($errs ne "");

    exit(0);
}

checkSlack();

#
#  Fetch the latest repo.
#

if (($doFetch) && ($canu eq "")) {
    if (! -d "$gitrepo") {
        print STDERR "FETCHING REPO\n";

        postHeading("*Cloning Canu* into '$gitrepo'.");

        system("mkdir -p $gitrepo");
        system("git clone http://github.com/marbl/canu.git $gitrepo > clone.err 2>&1");
        system("cd $gitrepo && git submodule init > submo.err 2>&1");

        postFile(undef,          "clone.err");
        postFile(undef, "$gitrepo/submo.err");

        unlink          "clone.err";
        unlink "$gitrepo/submo.err";
    }
    else {
        print STDERR "UPDATING REPO\n";

        postHeading("*Updating Canu* in '$gitrepo'.");

        system("cd $gitrepo && git fetch > fetch.err 2>&1");
        system("cd $gitrepo && git merge --stat > merge.err 2>&1");
        system("cd $gitrepo && git submodule update --remote --merge > submo.err 2>&1");

        postFile(undef, "$gitrepo/fetch.err");
        postFile(undef, "$gitrepo/merge.err");
        postFile(undef, "$gitrepo/submo.err");

        unlink "$gitrepo/fetch.err";
        unlink "$gitrepo/merge.err";
        unlink "$gitrepo/submo.err";
    }
}

#
#  Switch to the branch we want to use, then update the list of revisions in
#  it.
#

if ($canu eq "") {
    postHeading("*Check out* branch '$branch'.");

    system("cd $gitrepo && git checkout $branch > check.err 2>&1");
    system("cd $gitrepo && git merge --stat > merge.err 2>&1");

    postFile(undef, "$gitrepo/check.err");
    postFile(undef, "$gitrepo/merge.err");

    unlink "$gitrepo/check.err";
    unlink "$gitrepo/merge.err";
}
else {
    postHeading("*Using* canu in '$canu'.");

    $gitrepo = $canu;   #  Needed to get date-to-hash and date and hash set below.
    $date    = $now;
}

system("cd $gitrepo && git log --date=format-local:%Y-%m-%d-%H%M --pretty=tformat:'%ad %H' | sort -nr > date-to-hash");

#
#  If given a date, scan the repo to find the closest hash.
#

if (defined($date)) {
    my $bestdate;
    my $besthash;
    my $trigger  = 0;

    open(F, "< $gitrepo/date-to-hash") or die "Failed to open '$gitrepo/date-to-hash' for reading: $!\n";
    while (<F>) {
        chomp;

        if (m/^(\d\d\d\d-\d\d-\d\d-\d\d\d\d)\s+(.*)$/) {
            my $d = $1;
            my $h = $2;

            if ($d le $date) {
                $bestdate = $d;
                $besthash = $h;

                last;
            }
        } else {
            die "Malformed date-to-hash: '$_'\n";
        }
    }
    close(F);

    die "No bestdate?\n"   if (!defined($bestdate));

    $hash = $besthash;
}

#
#  Figure out the date for this hash.
#

if (!defined($hash)) {
    die "Failed to find a hash?\n";
}

if (defined($hash)) {
    undef $date;

    open(F, "< $gitrepo/date-to-hash") or die "Failed to open '$gitrepo/date-to-hash' for reading: $!\n";
    while (<F>) {
        chomp;

        if (m/^(\d\d\d\d-\d\d-\d\d-\d\d\d\d)\s+(.*)$/) {
            my $d = $1;
            my $h = $2;

            $date = $d   if ($hash eq $h);
        } else {
            die "Malformed date-to-hash: '$_'\n";
        }
    }
    close(F);

    if (!defined($date)) {
        die "Failed to find date for hash $hash.  Wrong branch?\n";
    }

    $regr = "$date-$branch-" . substr($hash, 0, 12);

    print STDERR "USING $regr\n";
}

#
#  Check out a version.
#

if (! -d "$wrkdir/$regr/canu") {
    if ($canu eq "") {
        print STDERR "CHECKOUT $regr\n";

        #  Clone the repo and checkout the proper version.

        system("mkdir -p $wrkdir/$regr/canu");
        system("cd $wrkdir/$regr/canu && rsync -a $gitrepo/ .");
        system("cd $wrkdir/$regr/canu && git checkout -b regression-$regr $hash > checkout.err 2>&1");
    }
    else {
        print STDERR "COPY from $canu to $regr\n";

        system("mkdir -p $wrkdir/$regr/canu");
        system("cd $wrkdir/$regr/canu && rsync -a $canu/ .");
    }

    #  Save a log of changes.

    #if ($ldate ne "") {
    #    system("cd $wrkdir/$regr/canu && git log --after=\"$ldate\" --until=\"$tdate\" > ../canu.updates");
    #}
}

#
#  Compile it.
#

if (! -e "$wrkdir/$regr/canu/src/make.err") {
    print STDERR "BUILD $regr\n";

    postHeading("*Building* branch '$branch'.");

    system("cd $wrkdir/$regr/canu/src && gmake -j 8 > make.out 2> make.err");   #  Once, with threads.
    system("cd $wrkdir/$regr/canu/src && gmake      > make.out 2> make.err");   #  Again, without, to get errors.

    #
    #  Check for compilation errors.
    #

    my $isOK = 0;
    my $ot = "";
    my $ce = "";

    open(ERRS, "< $wrkdir/$regr/canu/src/make.out");
    while (! eof(ERRS)) {
        $_ = <ERRS>;

        if (m/^Success!\s*$/) {
            $isOK=1;        
        }

        $ot .= $_;
    }
    close(F);

    open(ERRS, "< $wrkdir/$regr/canu/src/make.err");
    while (! eof(ERRS)) {
        $_ = <ERRS>;

        next   if (m/At\sglobal\sscope/);
        next   if (m/unrecognized\scommand\sline\soption/);
        next   if (m/^ar:/);

        if (m/warning:\s#warning/) {
            #$wn .= $_;
            $_ = <ERRS>;
            $_ = <ERRS>;
            next;
        }

        $ce .= $_;
    }
    close(F);

    if ($isOK) {
        postCodeBlock(undef, $ot);
        postHeading(":canu_success: *Build was successful*.");
    }

    else {
        postCodeBlock(undef, $ot);
        postCodeBlock(undef, $ce);
        postHeading(":canu_fail: *BUILD FAILED*.");

        exit(1);
    }
}

#
#  Find stuff to run.  We were either given a specific recipe to use, or a
#  recipe file.
#

#if (-e "recipes/$tests/submit.sh") {
#    push @recipes, $tests;
#}

if (defined($tests) && -e "recipes/$tests") {
    open(F, "< recipes/$tests");
    while (<F>) {
        chomp;
        push @recipes, "$_"   if (-e "recipes/$_/submit.sh");
    }
    close(F);
}

#
#  And run them.
#

if (scalar(@recipes) == 0) {
    print "NO RECIPES supplied; no tests started.\n";
}

foreach my $recipe (@recipes) {
    print "START recipe $recipe.\n";

    postHeading("Starting recipe $recipe in $regr.");

    my $lerr = system("cd $wrkdir/$regr && ln -s ../recipes/$recipe/submit.sh $recipe-submit.sh");
    my $eerr = system("cd $wrkdir/$regr && sh $recipe-submit.sh $recipe > $recipe-submit.err 2>&1");

    if ($eerr) {
        postHeading("FAILED to start recipe $recipe.");
        postFile(undef, "$wrkdir/$regr/$recipe-submit.err");
    }
}
