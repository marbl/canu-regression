#!/bin/sh

#  Attempt to (re)configure SGE.  For unknown reasons, jobs submitted
#  to SGE, and running under SGE, fail to read the shell init scripts,
#  and so they don't set up SGE (or ANY other paths, etc) properly.
#  For the record, interactive logins (qlogin) DO set the environment.

if [ "x$SGE_ROOT" != "x" -a \
     -e  $SGE_ROOT/$SGE_CELL/common/settings.sh ]; then
  . $SGE_ROOT/$SGE_CELL/common/settings.sh
fi

regr=`pwd`
regr=`dirname $regr`
regr=`basename $regr`

perl ../../compare.pl -recipe drosophila-f1-sequel -regression $regr -fail

exit 0
