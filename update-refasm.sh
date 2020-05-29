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

saveFile() {
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

saveFile  asm.report

saveFile  asm.seqStore/errorLog
saveFile  asm.seqStore/info.txt

saveFile  asm.seqStore/readlengths-cor.png
saveFile  asm.seqStore/readlengths-obt.png
saveFile  asm.seqStore/readlengths-utg.png

saveFile  asm.seqStore/readlengths-cor.dat
saveFile  asm.seqStore/readlengths-obt.dat
saveFile  asm.seqStore/readlengths-utg.dat

saveFile  asm.correctedReads.fasta.gz
saveFile  asm.trimmedReads.fasta.gz

saveFile  asm.contigs.fasta
saveFile  asm.contigs.layout.readToTig
saveFile  asm.contigs.layout.tigInfo

saveFile  canu-scripts/

saveFile  correction/asm.loadCorrectedReads.log
saveFile  correction/2-correction/asm.readsToCorrect.log

saveFile  trimming/3-overlapbasedtrimming/asm.1.trimReads.log
saveFile  trimming/3-overlapbasedtrimming/asm.2.splitReads.log

saveFile  unitigging/3-overlapErrorAdjustment/red.red
saveFile  unitigging/4-unitigger/asm.001.filterOverlaps.thr000.num000.log
saveFile  unitigging/4-unitigger/asm.003.buildGreedy.sizes
saveFile  unitigging/4-unitigger/asm.010.mergeOrphans.thr000.num000.log
saveFile  unitigging/4-unitigger/asm.012.breakRepeats.thr000.num000.log
saveFile  unitigging/4-unitigger/asm.012.breakRepeats.sizes
saveFile  unitigging/4-unitigger/asm.best.edges
saveFile  unitigging/4-unitigger/unitigger.err

saveFile  quast/report.txt
saveFile  quast/report.txt.filtered
saveFile  quast/contigs_reports/misassemblies_report.txt
saveFile  quast/contigs_reports/transposed_report_misassemblies.txt
saveFile  quast/contigs_reports/unaligned_report.txt
saveFile  quast/contigs_reports/contigs_report_asm-contigs.mis_contigs.info
saveFile  quast/contigs_reports/contigs_report_asm-contigs.unaligned.info
saveFile  quast/contigs_reports/contigs_report_asm-contigs.stdout
saveFile  quast/contigs_reports/contigs_report_asm-contigs.stdout.filtered

echo "Done!"

exit 0
