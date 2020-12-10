#!/bin/sh

#  Attempt to (re)configure SGE.  For unknown reasons, jobs submitted
#  to SGE, and running under SGE, fail to read the shell init scripts,
#  and so they don't set up SGE (or ANY other paths, etc) properly.
#  For the record, interactive logins (qlogin) DO set the environment.

if [ "x$SGE_ROOT" != "x" -a \
     -e  $SGE_ROOT/$SGE_CELL/common/settings.sh ]; then
  . $SGE_ROOT/$SGE_CELL/common/settings.sh
fi

regr=`pwd`              # e.g., /assembly/canu-regression/2020-05-21-1327-master-cafc287f0c6a/drosophila-f1-hifi-24k
recp=`basename $regr`   # e.g., drosophila-f1-hifi-24k
regr=`dirname $regr`    # e.g., /assembly/canu-regression/2020-05-21-1327-master-cafc287f0c6a
regr=`basename $regr`   # e.g., 2020-05-21-1327-master-cafc287f0c6a

perl ../../compare.pl -recipe $recp -regression $regr -fail

exit 0
