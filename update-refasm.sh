#!/bin/sh

###############################################################################
 #
 #  This file is part of canu, a software program that assembles whole-genome
 #  sequencing reads into contigs.
 #
 #  This software is based on:
 #    'Celera Assembler' r4587 (http://wgs-assembler.sourceforge.net)
 #    the 'kmer package' r1994 (http://kmer.sourceforge.net)
 #
 #  Except as indicated otherwise, this is a 'United States Government Work',
 #  and is released in the public domain.
 #
 #  File 'README.licenses' in the root directory of this distribution
 #  contains full conditions and disclaimers.
 ##

#  Takes no arguments.

path=`pwd`
asmn=`basename $path`
regr=`dirname  $path`
regr=`basename $regr`

echo "In directory     '$path'"
echo "Found assembly   '$asmn'"
echo "Found regression '$regr'"

if [ -e ../../recipes/$asmn/refasm-$regr ] ; then
  echo "refasm already exists in ../../recipes/$asmn/refasm-$regr"
  exit 1
fi

mkdir -p ../../recipes/$asmn/refasm-$regr

rm -f    ../../recipes/$asmn/refasm
ln -s    refasm-$regr ../../recipes/$asmn/refasm

save-file() {
    for arg in "$@" ; do
        dir=`dirname  $arg`
        nam=`basename $arg`

        if [ -e $dir/$nam ] ; then
            echo "  $arg"
            mkdir -p            ../../recipes/$asmn/refasm-$regr/$dir
            cp    -pr $dir/$nam ../../recipes/$asmn/refasm-$regr/$dir/$nam
        fi
    done
}

save-file  asm.report

save-file  asm.seqStore/errorLog
save-file  asm.seqStore/info.txt

save-file  asm.seqStore/readlengths-cor.png
save-file  asm.seqStore/readlengths-obt.png
save-file  asm.seqStore/readlengths-utg.png

save-file  asm.seqStore/readlengths-cor.dat
save-file  asm.seqStore/readlengths-obt.dat
save-file  asm.seqStore/readlengths-utg.dat

save-file  asm.correctedReads.fasta.gz
save-file  asm.trimmedReads.fasta.gz

save-file  asm.contigs.fasta
save-file  asm.contigs.layout.readToTig
save-file  asm.contigs.layout.tigInfo

save-file  canu-scripts/

save-file  correction/asm.loadCorrectedReads.log
save-file  correction/2-correction/asm.readsToCorrect.log

save-file  trimming/3-overlapbasedtrimming/asm.1.trimReads.log
save-file  trimming/3-overlapbasedtrimming/asm.2.splitReads.log

save-file  unitigging/3-overlapErrorAdjustment/red.red
save-file  unitigging/4-unitigger/asm.001.filterOverlaps.thr000.num000.log
save-file  unitigging/4-unitigger/asm.003.buildGreedy.sizes
save-file  unitigging/4-unitigger/asm.010.mergeOrphans.thr000.num000.log
save-file  unitigging/4-unitigger/asm.012.breakRepeats.thr000.num000.log
save-file  unitigging/4-unitigger/asm.012.breakRepeats.sizes
save-file  unitigging/4-unitigger/asm.best.edges
save-file  unitigging/4-unitigger/unitigger.err

save-file  quast/report.txt

save-file  quast/transposed_report.txt

save-file  quast/contigs_reports/misassemblies_report.txt
save-file  quast/contigs_reports/transposed_report_misassemblies.txt
save-file  quast/contigs_reports/unaligned_report.txt

echo "Done!"

exit 0
