#!/bin/sh

syst=`uname -s`
arch=`uname -m | sed s/x86_64/amd64/`
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


./canu/$syst-$arch/bin/canu executiveThreads=8 executiveMemory=16g \
  -p asm \
  -d $recp \
  genomeSize=50k \
  onSuccess=../../recipes/$recp/success.sh \
  onFailure=../../recipes/$recp/failure.sh \
  -pacbio ../recipes/$recp/reads/*xz

exit 0
