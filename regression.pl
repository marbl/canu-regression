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

my $doHelp  = 0;
my $doList  = "";
my $errs    = "";
my $doFetch = 1;
my $date    = undef;
my $branch  = "master";
my $hash    = undef;
my $canu    = "";

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
        $doHelp  = 1;
    }

    elsif ($arg eq "-list-refs")       { $doList = "refs"; }
    elsif ($arg eq "-list-assemblies") { $doList = "asms"; }
    elsif ($arg eq "-list-completed")  { $doList = "fini"; }
    elsif ($arg eq "-list-missing")    { $doList = "miss"; }
    elsif ($arg eq "-list-failed")     { $doList = "fail"; }

    elsif ($arg eq "-fetch") {
        $doFetch = 1;
    }

    elsif ($arg eq "-no-fetch") {
        $doFetch = 0;
    }

    elsif ($arg eq "-branch") {
        $branch  = shift @ARGV;
    }

    elsif ($arg eq "-master") {
        $branch  = "master";
    }

    elsif ($arg eq "-latest") {
        $hash    = undef;
        $date    = $now;
    }

    elsif ($arg eq "-hash") {
        $hash    = shift @ARGV;
        $date    = undef;
    }

    elsif ($arg eq "-date") {
        $hash    = undef;
        $date    = shift @ARGV;
    }

    elsif ($arg eq "-canu") {
        $doFetch = 0;
        $canu    = shift @ARGV;
        $hash    = undef;
        $date    = $now
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

$errs .= "ERROR: Exactly one of -latest, -date, -hash or -canu must be supplied.\n"   if (!defined($date) && !defined($hash) && ($canu eq "") && ($doList eq "")) ;
$errs .= "ERROR: Exactly one of -latest, -date, -hash or -canu must be supplied.\n"   if ( defined($date) &&  defined($hash) && ($canu eq "") && ($doList eq "")) ;
$errs .= "ERROR: Test file 'recipe/$tests' doesn't exist.\n"                          if ((defined($tests)) && (! -e "recipes/$tests"));
$errs .= "ERROR: -canu path must be to root of git clone.\n"                          if (($canu ne "") && (! -e "$canu/.git"));


if (($doHelp) || ($errs ne "")) {
    print "usage: $0 [options] [recipe-class | recipe-list]\n";
    print "  -(no-)fetch  Fetch (or not) updates to the repository.\n";
    print "\n";
    print "REPORTS\n";
    print "  -list-refs        List the current reference assemblies.\n";
    print "  -list-assemblies  List the assemblies and status of each (the union of the next three reports).\n";
    print "  -list-completed   List the assemblies that have completed.\n";
    print "  -list-missing     List the assemblies that have not been started in an existing regression set.\n";
    print "  -list-failed      List the assemblies that have failed to complete.\n";
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


if ($doList eq "refs") {
    my %refs;
    my @asms;
    my $mLen = 0;
    my $nRef = 0;
    my $wRef = 0;

    #  Build a map from recipe to reference assembly.
    open(F, "ls -l recipes/*/refasm |");
    while (<F>) {
        $refs{$1} = $2   if (m!\srecipes/(\S*)/refasm\s->\s(\S+)$!);
    }
    close(F);

    #  Build a list of the assemblies we know about, remember the length of
    #  the longest name (for pretty-printing) and count how assemblies many
    #  have or do not have a reference assembly.
    open(F, "ls -l recipes/*/submit.sh |");
    while (<F>) {
        if (m!\srecipes/(\S*)/submit.sh$!) {
            push @asms, $1;

            $mLen = ($mLen < length($1)) ? length($1) : $mLen;

            $nRef++   if (!exists($refs{$1}));
            $wRef++   if ( exists($refs{$1}));
        }
    }
    close(F);

    #  If assemblies without a reference exist, print them.
    if ($nRef) {
        print "\n";
        print "Assemblies without references:\n";

        foreach my $asm (sort @asms) {
            printf("  %-*s -> no reference assembly\n", $mLen, $asm)   if (!exists($refs{$asm}));
        }
    }

    #  If assemblies with a reference exist, print the reference assembly mapping.
    if ($wRef) {
        print "\n";
        print "Current reference assebmlies:\n";

        foreach my $asm (sort keys %refs) {
            printf("  %-*s -> %s\n", $mLen, $asm, $refs{$asm});
        }
    }

    exit(0);
}


if (($doList eq "asms") ||
    ($doList eq "fini") ||
    ($doList eq "miss") ||
    ($doList eq "fail")) {
    my @asms;
    my @regr;

    my $mLen = 0;

    open(F, "ls -l recipes/*/submit.sh |");
    while (<F>) {
        if (m!\srecipes/(\S*)/submit.sh$!) {
            push @asms, $1;

            $mLen = ($mLen < length($1)) ? length($1) : $mLen;
        }
    }
    close(F);

    open(F, "ls -d 20* |");
    while (<F>) {
        if (m!(\d\d\d\d-\d\d-\d\d-\d\d\d\d-\S+-............)$!) {
            push @regr, $1;

            $mLen = ($mLen < length($1)) ? length($1) : $mLen;
        }
    }
    close(F);

    foreach my $asm (sort @asms) {
        my @results;
        my $show = 0;

        foreach my $reg (sort @regr) {
            my $sta = (-e "$reg/$asm-submit.sh")         ? "YES" : "no";   #  Started?
            my $ctg = (-e "$reg/$asm/asm.contigs.fasta") ? "YES" : "no";   #  Contigs exist?
            my $qst = (-e "$reg/$asm/quast/report.txt")  ? "YES" : "no";   #  Quast exists?

            #  Some horrible if tests here.  Show results if:
            #    -list-assemblies; (show everything)
            #    -list-completed  and any of the above three tests are true.
            #    -list-missing    and the assembly was not started.
            #    -list-failed     and the assembly was started but not finished.
            #
            $show = 1   if (($doList eq "asms"));
            $show = 1   if (($doList eq "fini") && (($sta eq "YES") ||  ($ctg eq "YES") || ($qst eq "YES")));
            $show = 1   if (($doList eq "miss") && (($sta eq  "no")));
            $show = 1   if (($doList eq "fail") &&  ($sta eq "YES") && (($ctg eq  "no") || ($qst eq  "no")));

            #  Then add this assembly result to the output list if:
            #    -list-assemblies; (show everything)
            #    -list-completed and it was at least started.
            #    -list-missing   and it was not started.
            #    -list-failed    and it was started but not finished.
            #
            if ((($doList eq "asms")) ||
                (($doList eq "fini") &&  ($sta eq "YES")) ||
                (($doList eq "miss") &&  ($sta eq  "no")) ||
                (($doList eq "fail") && (($sta eq "YES") && (($ctg ne "YES") || ($qst ne "YES"))))) {
                push @results, sprintf("%-*s  %7s  %7s  %5s\n", $mLen, $reg, $sta, $ctg, $qst);
            }
        }

        if (($show) && (scalar(@results > 0))) {
            printf("\n");
            printf("%-*s  Started  Contigs  Quast\n", $mLen, $asm);
            printf("-" x $mLen . "  -------  -------  -----\n");
            foreach my $res (@results) {
                print $res;
            }
        }
    }

    exit(0);
}


#
#  Make sure we can write stuff to slack.  All the logs and results go there.
#

checkSlack();

#
#  CLONE: If there's no repo (and we're not running from a local copy) clone
#  the repo from github.
#

if (($doFetch) && ($canu eq "") && (! -d $gitrepo)) {
    my $lines;

    system("mkdir -p $gitrepo");
    system("git clone --recurse-submodules http://github.com/marbl/canu.git $gitrepo > clone.err 2>&1");

    open(F, "< clone.err");
    while (<F>) {
        next   if ($_ =~ m/Updating\sfiles/);
        $lines .= $_;
    }
    close(F);

    unlink "clone.err";

    postFormattedText("*Clone Canu* into '$gitrepo'.", $lines);
}

#
#  SWITCH BRANCH: Switch the repo to the requested branch if we're not there
#  already.
#

if (($doFetch) && ($canu eq "") && (-d $gitrepo)) {
    my $onBranch;

    open(F, "cd $gitrepo && git status |");
    while (<F>) {
        $onBranch = $1   if (m/^On\s+branch\s+(.*)$/);
    }
    close(F);
    
    if ($onBranch ne $branch) {
        my $lines;

        system("cd $gitrepo && git checkout $branch > checkout.err 2>&1");

        open(F, "< checkout.err");
        while (<F>) {
            next   if ($_ =~ m/^Switched\sto/);
            next   if ($_ =~ m/^Your\sbranch\sis\sup\sto\sdate\swith/);
            $lines .= $_;
        }
        close(F);

        unlink "$gitrepo/checkout.err";
 
        postFormattedText("*Switch from branch '$onBranch' to branch '$branch'.*", $lines);
    }
}

#
#  FETCH UPDATES: Fetch and apply any updates.  This could be done _before_
#  switching to the correct branch, but then we'd need to do basically the
#  same thing again to update the branch we just switched to.
#
#  Posting of the logs is disabled because they're a bit verbose.
#

if (($doFetch) && ($canu eq "") && (-d $gitrepo)) {
    postHeading("*Update Canu* branch $branch in '$gitrepo'.");

    system("sh ./update-repo.sh $gitrepo/src/seqrequester > update-seqrequester.out 2>&1");
    system("sh ./update-repo.sh $gitrepo/src/utility      > update-utility.out 2>&1");
    system("sh ./update-repo.sh $gitrepo/src/meryl        > update-meryl.out 2>&1");
    system("sh ./update-repo.sh $gitrepo/                 > update-canu.out 2>&1");

    #postFile("Seqrequester changes", "update-seqrequester.out");
    #postFile("Utility changes",      "update-utility.out");
    #postFile("Meryl changes",        "update-meryl.out");
    #postFile("Canu changes",         "update-canu.out");
}

#
#  PICK VERSION: Update the list of revisions, then map the date to a hash,
#  then find the date for that hash.
#

system("cd $gitrepo && git log --date=format-local:%Y-%m-%d-%H%M --pretty=tformat:'%ad %H' | sort -nr > date-to-hash");

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
}

#
#  CHECK OUT: Check out a specific version.  We're already on the correct
#  branch, so just copy the repo and checkout/update the code.
#
#  If a specific canu tree is used, just copy it over.
#
#  The double checkout is to just get a clean log.  The first checkout
#  'falsely' reports that submodules are out-of-date.
#

if (! -d "$wrkdir/$regr/canu") {
    if ($canu eq "") {
        system("mkdir -p $wrkdir/$regr/canu");
        system("cd $wrkdir/$regr/canu && rsync -a $gitrepo/ .");
        system("cd $wrkdir/$regr/canu && git checkout $hash    > initial-checkout.err 2>&1");
        system("cd $wrkdir/$regr/canu && git submodule update  > checkout.err 2>&1");
        system("cd $wrkdir/$regr/canu && git checkout $hash   >> checkout.err 2>&1");

        postFile("*Checkout $date $hash*.", "$wrkdir/$regr/canu/checkout.err");
    }
    else {
        postHeading("*Using* '$canu'.");

        system("mkdir -p $wrkdir/$regr/canu");
        system("cd $wrkdir/$regr/canu && rsync -a $canu/ .");
    }
}

#
#  COMPILE: Compile it.  Should we also remove any previous build?
#

if (! -e "$wrkdir/$regr/canu/src/make.err") {
    postHeading("*Build*.");

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
#  FIND TEST CASES: Find stuff to run.  We were either given a specific
#  recipe to use, or a recipe file.
#

if (defined($tests) && -e "recipes/$tests") {
    open(F, "< recipes/$tests");
    while (<F>) {
        chomp;
        push @recipes, "$_"   if (-e "recipes/$_/submit.sh");
    }
    close(F);
}

#
#  EXECUTE: And run them.
#

if (scalar(@recipes) == 0) {
    print "NO RECIPES supplied; no tests started.\n";
}

foreach my $recipe (@recipes) {
    print "START recipe $recipe.\n";

    if (! -e "$wrkdir/$regr/$recipe/quast/report.txt") {
        if (! -e "$wrkdir/$regr/$recipe-submit.sh") {
            postHeading("Starting recipe $recipe in $regr.");
            system("cd $wrkdir/$regr && ln -s ../recipes/$recipe/submit.sh $recipe-submit.sh");
        } else {
            postHeading("Resuming recipe $recipe in $regr.");
        }

        my $eerr = system("cd $wrkdir/$regr && sh $recipe-submit.sh $recipe > $recipe-submit.err 2>&1");

        if ($eerr) {
            postHeading("FAILED to start recipe $recipe.");
            postFile(undef, "$wrkdir/$regr/$recipe-submit.err");
        }
    } else {
        postHeading("Recipe $recipe in $regr is already finished.");
    }

}
