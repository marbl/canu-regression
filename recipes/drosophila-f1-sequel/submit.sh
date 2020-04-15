#!/bin/sh

syst=`uname -s`
arch=`uname -m | sed s/x86_64/amd64/`

./canu/$syst-$arch/bin/canu \
  -p asm \
  -d drosophila-f1-sequel \
  genomeSize=139600000 \
  corPartitions=24 \
  corPartitionMin=5000 \
  onSuccess=../../recipes/drosophila-f1-sequel/success.sh \
  onFailure=../../recipes/drosophila-f1-sequel/failure.sh \
   -pacbio ../recipes/drosophila-f1-sequel/reads/*xz

exit 0
