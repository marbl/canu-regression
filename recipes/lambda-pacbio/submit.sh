#!/bin/sh

syst=`uname -s`
arch=`uname -m | sed s/x86_64/amd64/`

./canu/$syst-$arch/bin/canu executiveThreads=8 executiveMemory=16g \
  -p asm \
  -d lambda-pacbio \
  genomeSize=50k \
  onSuccess=../../recipes/lambda-pacbio/success.sh \
  onFailure=../../recipes/lambda-pacbio/failure.sh \
  -pacbio ../recipes/lambda-pacbio/reads/*xz

exit 0
