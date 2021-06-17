#!/bin/sh

syst=`uname -s`
arch=`uname -m | sed s/x86_64/amd64/`

if [ -e canu/build/bin/canu ] ; then
  inst="build"
else
  inst="$syst-$arch"
fi

#  To make this script a little bit less specific to each assembly,
#  it needs the name of the assembly as the only argument.
#
#  Unfortunately, you still need to customize this script for genome
#  size and any special options.

recp=$1

if [ x$recp = x ] ; then
  echo "usage: $0 <recp>"
  exit 1
fi

if [ ! -e "../recipes/$recp/success.sh" ] ; then
  echo "Failed to find '../recipes/$recp/success.sh'."
  exit 1
fi

if [ ! -e "../recipes/$recp/failure.sh" ] ; then
  echo "Failed to find '../recipes/$recp/failure.sh'."
  exit 1
fi

#  Load is consistently 75%
#
#  refBlockLength 5000000000 resulted in 2105 jobs from 10 minutes to 3.5 hours
#  refBlockLength 7500000000 resulted in 2105 jobs from 10 minutes to 3.5 hours
#
#  cns jobs 18 and 19 fail with default memory, 
./canu/$inst/bin/canu \
  -p asm \
  -d $recp \
  genomeSize=3100000000 \
  homoPolyCompress=true correctedErrorRate=0.08 obtOvlRefBlockLength=7500000000 utgOvlRefBlockLength=7500000000 \
  onSuccess=../../recipes/$recp/success.sh \
  onFailure=../../recipes/$recp/failure.sh \
  cnsMemory=64g \
  -nanopore -corrected ../recipes/$recp/reads/*.[gx]z

exit 0
