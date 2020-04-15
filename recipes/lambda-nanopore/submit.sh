#!/bin/sh

syst=`uname -s`
arch=`uname -m | sed s/x86_64/amd64/`

./canu/$syst-$arch/bin/canu \
  -p asm \
  -d lambda-nanopore \
  genomeSize=50k \
  onSuccess=../../recipes/lambda-nanopore/success.sh \
  onFailure=../../recipes/lambda-nanopore/failure.sh \
  -nanopore ../recipes/lambda-nanopore/reads/*xz

exit 0
