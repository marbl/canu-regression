#!/bin/sh

#  Attempt to (re)configure SGE.  For unknown reasons, jobs submitted
#  to SGE, and running under SGE, fail to read the shell init scripts,
#  and so they don't set up SGE (or ANY other paths, etc) properly.
#  For the record, interactive logins (qlogin) DO set the environment.

if [ "x$SGE_ROOT" != "x" -a \
     -e  $SGE_ROOT/$SGE_CELL/common/settings.sh ]; then
  . $SGE_ROOT/$SGE_CELL/common/settings.sh
fi

prefix=$1

if [ -e /usr/local/apps/quast ] ; then
  module load quast
  quast="quast.py"
fi
if [ -e /work/software/bin/quast.py ] ; then
  quast="/work/software/bin/quast.py"
fi

if [ ! -e quast/report.txt ] ; then
  $quast \
    --threads 8 \
    --min-identity 90. \
    --skip-unaligned-mis-contigs \
    --min-alignment 20000 \
    --extensive-mis-size 500000 \
    --min-contig 1000000 \
    -r ../../references/drosophila-iso1.fasta \
    -o quast \
    $prefix.contigs.fasta \
  >  quast.log
  2> quast.err
fi

regr=`pwd`
regr=`dirname $regr`
regr=`basename $regr`

perl ../../compare.pl -recipe drosophila-f1-sequel -regression $regr

exit 0
