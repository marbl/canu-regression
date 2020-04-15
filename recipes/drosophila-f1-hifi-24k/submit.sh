#!/bin/sh

syst=`uname -s`
arch=`uname -m | sed s/x86_64/amd64/`

./canu/$syst-$arch/bin/canu \
  -p asm \
  -d drosophila-f1-hifi-24k \
  genomeSize=139600000 \
  onSuccess=../../recipes/drosophila-f1-hifi-24k/success.sh \
  onFailure=../../recipes/drosophila-f1-hifi-24k/failure.sh \
  -pacbio-hifi ../recipes/drosophila-f1-hifi-24k/reads/*xz

exit 0
