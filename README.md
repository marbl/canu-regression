A regression test suite and historical results for the [Canu](https://github.com/marbl/canu)
single molecule sequence assembler.

## Background

This is a set of scripts and configurations to compare results of Canu across
different code points.  The driver script will update a local copy of the
canu github repo, checkout a specific version of Canu, and launch a
(user-supplied) set of assemblies.

Each assembly will compare itself against a reference genome (using quast)
and then compare quast results against a previously chosen curated assembly
and report differences in the quast results.

## Usage

The main driver is regression.pl.  This will update the local repo, checkout
a specific version of Canu, build, and then launch assemblies on the grid.

The "chosen curated assembly" can be updated using update-refasm.sh.  


## Milestones

Nothing more than a list of special dates.  It's quite out of date.

Date            | Hash                                     | Milestone
--------------- | ---------------------------------------- | ------------------------------------------------------
2020-10-16-1821 | 5638f7d9a5379373310ab62c28aa0cdbd864722d | Canu 2.1.1, branch v2.1-maintenance
2020-08-24-1052 | dd71f16d5c31e0f6d30297c215a9c62353079da9 | Canu 2.1,   branch v2.1-maintenance
2020-08-19-2326 | 7bb8a2435e3f8d2d9a73be44b2c9fef3cccd32a5 | Canu 2.1    master, (just after release)
2020-07-22-1735 | afcb34fde3fb9445d57f8b311f92794f9c96baa5 | Build in 'build' instead of 'OSTYPE-MACHINETYPE'.  (Regression might not work before this)
2020-03-18-0351 | 541200a23245ebe71ad2b46f6d8f500431a1725e | Canu 2.0,   branch v2.0-maintenance
--------------- | ---------------------------------------- | ------------------------------------------------------
--------------- | ---------------------------------------- | ------------------------------------------------------
2018-09-18-0752 |                                          | trio support full run
2018-09-05-1307 |                                          | meryl v2 full run (complete)
2018-08-13-0800 |                                          | 
2018-07-30-1450 |                                          | 
2018-07-26-1654 |                                          | 
2018-05-16-1124 |                                          | 
2018-05-08-1454 |                                          | edlib patches
2018-05-04-0314 |                                          | last seqStore change<br>RED fails, ran by hand (fixed on 05-05)
2018-04-16-0545 |                                          | bogart bugs, after ovlStore bugs fixed<br>FAILED - gkpStore partitioning (still) has bad BLOB pointers
2018-03-28-1108 |                                          | before ovlStore changes<br>FAILED - gkpStore partitioning has bad BLOB pointers
2018-03-13-2009 |                                          | gkpStore changes<br>FAILED - gkpStore partitioning has bad BLOB pointers
2018-03-13-1715 |                                          | before gkpStore changes
2018-02-27-0846 |                                          | v1.7
--------------- | ---------------------------------------- | ------------------------------------------------------
2018-02-09-1146 |                                          | Use both read length and overlap length to filter evidence for correction.<br>No change and I forget (in the two months it took to run it) what was exactly being tested.<br>NOTE!  These have BAD job sizes for RED, resulting in VERY VERY small jobs.
2018-02-08-1804 |                                          | (before the next one)
--------------- | ---------------------------------------- | ------------------------------------------------------
2017-08-14-1539 |                                          | v1.6
2017-10-11-1435 |                                          | Minor bugfixes, new installation structure, 
2017-10-05-2341 |                                          | One gkpStore.<br>Pseudo-QV's for corrected reads.<br>Output read names from mhap, not just per-job ID.<br>Remove -w option from overlapInCore.  
2017-09-23-1710 |                                          | Bug fix; don't crash when no corrected sequence is generated for any read.
2017-09-22-1613 |                                          | Emit only single longest corrected read piece.  Bug fixes in grid support.
2017-09-20-1513 |                                          | Bug fixes in overlap store histogram.
2017-09-18-1358 |                                          | Use corStore for correction.<br>Estimate overlap scores; changes to overlap store stats data.<br>Overlap scores are 16-bit integers.<br>Fix inconsistent overlap scores introduced in last commit.
2017-08-24-0051 |                                          | KNOWN BAD; overlap scores computed using inconsistent functions!<br>Merge falcon_sense and input generation.
2017-08-14-1539 |                                          | v1.6 (MISSING); just minor stuff since last commit.
2017-08-11-0829 |                                          | Minor logging change and bug fix.
2017-08-10-1830 |                                          | Bogart: dead bubble popping code removal, errorProfile memory optimization.
2017-08-02-0645 |                                          | Bug fixes.
2017-07-28-2128 |                                          | Bug fixes and intermediate file cleanup.
2017-07-25-2009 |                                          | 
2017-07-03-1413 |                                          | 
2017-06-29-1114 |                                          | 
2017-06-09-1607 |                                          | 
2017-06-07-1055 |                                          | 
2017-05-19-1828 |                                          | 
2017-05-10-1930 |                                          | 
--------------- | ---------------------------------------- | ------------------------------------------------------
2017-04-17-1531 |                                          | v1.5
2017-03-10-0053 |                                          | alignPair rewrite
2017-03-10-0051 |                                          | alignPair rewrite, previous commit
2017-01-27-0903 |                                          | errorRate replacement
2017-01-27-0803 |                                          | errorRate replacement, previous commit
2017-01-06-0241 |                                          | stageDirectory (so nothing big will run before this)
--------------- | ---------------------------------------- | ------------------------------------------------------
2016-12-12-2155 |                                          | v1.4
2016-11-08-1117 |                                          | first that works
2016-11-07-1826 |                                          | adds support for onSuccess, but doesn't work
--------------- | ---------------------------------------- | ------------------------------------------------------
