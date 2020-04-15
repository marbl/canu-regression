#!/bin/sh

syst=`uname -s`
arch=`uname -m | sed s/x86_64/amd64/`

./canu/$syst-$arch/bin/canu \
  -p asm \
  -d drosophila-a4-pacbio-3 \
  genomeSize=139600000 \
  onSuccess=../../recipes/drosophila-a4-pacbio-3/success.sh \
  onFailure=../../recipes/drosophila-a4-pacbio-3/failure.sh \
  -pacbio ../recipes/drosophila-a4-pacbio-3/reads/*xz

exit 0
