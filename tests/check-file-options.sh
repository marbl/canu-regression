#!/bin/sh

#  Run a variety of command line options and check that we run to completion
#  or fail to run, whichever is expected.
#
#  Usage:  check-file-options.sh [A | B | C | D]
#          check-file-options.sh [E | F | G | H]
#          check-file-options.sh all
#          check-file-options.sh check
#
#  ABCD are Nanopore tests.
#  EFGH are HiFi tests.
#
#  Please read the script before running.  Pay attention to the fact
#  that assemblies are run locally and in parallel.

mod=$1

raw="/data/reads/lambda/lambda.campen.nanopore.fasta.xz"
cor="/data/reads/lambda/lambda.campen.nanopore.corrected.fasta.gz"
tri="/data/reads/lambda/lambda.campen.nanopore.trimmed.fasta.gz"

fileA=$raw  #  Normal Nanopore
fileB=$cor  #  Pre-corrected Nanopore
fileC=$tri  #  Pre-trimmed Nanopore
fileD=$raw  #  Invalid cases

fileE=$tri   #  Normal HiFi
fileF=$tri   #  Pre-corrected HiFi
fileG=$cor   #  HiFi with trimming enabled
fileH=$raw   #  Invalid cases

#
#  Declare success if there is a contigs.fasta output,
#  regardless of if having anything in it.  All we care
#  is that the pipeline ran.
#
check_success() {
    TAG=$1
    dirs=`ls -d ${TAG}??? 2> /dev/null`

    if [ "x$dirs" = "x" ] ; then
        echo No runs for ${TAG}.
    fi

    for dd in `ls -d ${TAG}??? 2> /dev/null` ; do
        if [ ! -e ${dd}/asm.contigs.fasta ] ; then
            echo ${dd} has no output, but should.
        fi
    done
}

#
#  A little more complicated.  Report errors if
#  there are contigs, or if the error logging doesn't
#  end with ABORT.
#
check_failure() {
    TAG=$1
    dirs=`ls -d ${TAG}??? 2> /dev/null`

    if [ "x$dirs" = "x" ] ; then
        echo No runs for ${TAG}.
    fi

    for dd in $dirs ; do
        if [ -e ${dd}/asm.contigs.fasta ] ; then
            echo ${dd} ran to completion, but should have failed.
            continue
        fi

        if [ ! -e ${dd}.err ] ; then
            echo ${dd} has no .err output.
        elif [ `tail -n 1 ${dd}.err` != "ABORT:" ] ; then
            echo ${dd} does not end with an ABORT.
        fi
    done
}

#
#  Check results.
#

if [ x$mod = xcheck ] ; then
    check_success A
    check_success B
    check_success C
    check_failure D
    check_success E
    check_success F
    check_success G
    check_failure H
    exit 0
fi

#
#  Normal Nanopore assembly
#

if [ x$mod = xall -o x$mod = "xA" ] ; then
    canu useGrid=false -p asm -d A001 genomeSize=50k              -nanopore                        ${fileA} > A001.err 2>&1 &
    canu useGrid=false -p asm -d A002 genomeSize=50k              -nanopore           -raw         ${fileA} > A002.err 2>&1 &
    canu useGrid=false -p asm -d A004 genomeSize=50k              -nanopore           -full-length ${fileA} > A004.err 2>&1 &
    canu useGrid=false -p asm -d A006 genomeSize=50k              -nanopore-raw                    ${fileA} > A006.err 2>&1 &
    canu useGrid=false -p asm -d A007 genomeSize=50k              -nanopore-raw       -raw         ${fileA} > A007.err 2>&1 &
    canu useGrid=false -p asm -d A009 genomeSize=50k              -nanopore-raw       -full-length ${fileA} > A009.err 2>&1 &
    canu useGrid=false -p asm -d A021 genomeSize=50k -raw         -nanopore                        ${fileA} > A021.err 2>&1 &
    canu useGrid=false -p asm -d A022 genomeSize=50k -raw         -nanopore           -raw         ${fileA} > A022.err 2>&1 &
    canu useGrid=false -p asm -d A024 genomeSize=50k -raw         -nanopore           -full-length ${fileA} > A024.err 2>&1 &
    wait
    canu useGrid=false -p asm -d A026 genomeSize=50k -raw         -nanopore-raw                    ${fileA} > A026.err 2>&1 &
    canu useGrid=false -p asm -d A027 genomeSize=50k -raw         -nanopore-raw       -raw         ${fileA} > A027.err 2>&1 &
    canu useGrid=false -p asm -d A029 genomeSize=50k -raw         -nanopore-raw       -full-length ${fileA} > A029.err 2>&1 &
    canu useGrid=false -p asm -d A061 genomeSize=50k -full-length -nanopore                        ${fileA} > A061.err 2>&1 &
    canu useGrid=false -p asm -d A062 genomeSize=50k -full-length -nanopore           -raw         ${fileA} > A062.err 2>&1 &
    canu useGrid=false -p asm -d A064 genomeSize=50k -full-length -nanopore           -full-length ${fileA} > A064.err 2>&1 &
    canu useGrid=false -p asm -d A066 genomeSize=50k -full-length -nanopore-raw                    ${fileA} > A066.err 2>&1 &
    canu useGrid=false -p asm -d A067 genomeSize=50k -full-length -nanopore-raw       -raw         ${fileA} > A067.err 2>&1 &
    canu useGrid=false -p asm -d A069 genomeSize=50k -full-length -nanopore-raw       -full-length ${fileA} > A069.err 2>&1 &
    wait
fi

#
#  Pre-corrected Nanopore assembly
#

if [ x$mod = xall -o x$mod = "xB" ] ; then
    canu useGrid=false -p asm -d B003 genomeSize=50k              -nanopore           -corrected   ${fileB} > B003.err 2>&1 &
    canu useGrid=false -p asm -d B011 genomeSize=50k              -nanopore-corrected              ${fileB} > B011.err 2>&1 &
    canu useGrid=false -p asm -d B013 genomeSize=50k              -nanopore-corrected -corrected   ${fileB} > B013.err 2>&1 &
    canu useGrid=false -p asm -d B014 genomeSize=50k              -nanopore-corrected -full-length ${fileB} > B014.err 2>&1 &
    canu useGrid=false -p asm -d B041 genomeSize=50k -corrected   -nanopore                        ${fileB} > B041.err 2>&1 &
    canu useGrid=false -p asm -d B043 genomeSize=50k -corrected   -nanopore           -corrected   ${fileB} > B043.err 2>&1 &
    canu useGrid=false -p asm -d B044 genomeSize=50k -corrected   -nanopore           -full-length ${fileB} > B044.err 2>&1 &
    wait
    canu useGrid=false -p asm -d B051 genomeSize=50k -corrected   -nanopore-corrected              ${fileB} > B051.err 2>&1 &
    canu useGrid=false -p asm -d B053 genomeSize=50k -corrected   -nanopore-corrected -corrected   ${fileB} > B053.err 2>&1 &
    canu useGrid=false -p asm -d B054 genomeSize=50k -corrected   -nanopore-corrected -full-length ${fileB} > B054.err 2>&1 &
    canu useGrid=false -p asm -d B063 genomeSize=50k -full-length -nanopore           -corrected   ${fileB} > B063.err 2>&1 &
    canu useGrid=false -p asm -d B071 genomeSize=50k -full-length -nanopore-corrected              ${fileB} > B071.err 2>&1 &
    canu useGrid=false -p asm -d B073 genomeSize=50k -full-length -nanopore-corrected -corrected   ${fileB} > B073.err 2>&1 &
    canu useGrid=false -p asm -d B074 genomeSize=50k -full-length -nanopore-corrected -full-length ${fileB} > B074.err 2>&1 &
    wait
fi

#
#  Pre-trimmed Nanopore assembly
#

if [ x$mod = xall -o x$mod = "xC" ] ; then
    canu useGrid=false -p asm -d C005 genomeSize=50k              -nanopore           -trimmed     ${fileC} > C005.err 2>&1 &
    canu useGrid=false -p asm -d C015 genomeSize=50k              -nanopore-corrected -trimmed     ${fileC} > C015.err 2>&1 &
    canu useGrid=false -p asm -d C045 genomeSize=50k -corrected   -nanopore           -trimmed     ${fileC} > C045.err 2>&1 &
    canu useGrid=false -p asm -d C055 genomeSize=50k -corrected   -nanopore-corrected -trimmed     ${fileC} > C055.err 2>&1 &
    canu useGrid=false -p asm -d C081 genomeSize=50k -trimmed     -nanopore                        ${fileC} > C081.err 2>&1 &
    wait
    canu useGrid=false -p asm -d C083 genomeSize=50k -trimmed     -nanopore           -corrected   ${fileC} > C083.err 2>&1 &
    canu useGrid=false -p asm -d C085 genomeSize=50k -trimmed     -nanopore           -trimmed     ${fileC} > C085.err 2>&1 &
    canu useGrid=false -p asm -d C091 genomeSize=50k -trimmed     -nanopore-corrected              ${fileC} > C091.err 2>&1 &
    canu useGrid=false -p asm -d C093 genomeSize=50k -trimmed     -nanopore-corrected -corrected   ${fileC} > C093.err 2>&1 &
    canu useGrid=false -p asm -d C095 genomeSize=50k -trimmed     -nanopore-corrected -trimmed     ${fileC} > C095.err 2>&1 &
    wait
fi

#
#  Invalid assemblies.
#

if [ x$mod = xall -o x$mod = "xD" ] ; then
    canu useGrid=false -p asm -d D008 genomeSize=50k              -nanopore-raw       -corrected   ${fileB} > D008.err 2>&1 &
    canu useGrid=false -p asm -d D010 genomeSize=50k              -nanopore-raw       -trimmed     ${fileD} > D010.err 2>&1 &
    canu useGrid=false -p asm -d D012 genomeSize=50k              -nanopore-corrected -raw         ${fileD} > D012.err 2>&1 &
    canu useGrid=false -p asm -d D023 genomeSize=50k -raw         -nanopore           -corrected   ${fileD} > D023.err 2>&1 &
    canu useGrid=false -p asm -d D025 genomeSize=50k -raw         -nanopore           -trimmed     ${fileD} > D025.err 2>&1 &
    canu useGrid=false -p asm -d D028 genomeSize=50k -raw         -nanopore-raw       -corrected   ${fileD} > D028.err 2>&1 &
    canu useGrid=false -p asm -d D030 genomeSize=50k -raw         -nanopore-raw       -trimmed     ${fileD} > D030.err 2>&1 &
    canu useGrid=false -p asm -d D031 genomeSize=50k -raw         -nanopore-corrected              ${fileD} > D031.err 2>&1 &
    canu useGrid=false -p asm -d D032 genomeSize=50k -raw         -nanopore-corrected -raw         ${fileD} > D032.err 2>&1 &
    canu useGrid=false -p asm -d D033 genomeSize=50k -raw         -nanopore-corrected -corrected   ${fileD} > D033.err 2>&1 &
    canu useGrid=false -p asm -d D034 genomeSize=50k -raw         -nanopore-corrected -full-length ${fileD} > D034.err 2>&1 &
    canu useGrid=false -p asm -d D035 genomeSize=50k -raw         -nanopore-corrected -trimmed     ${fileD} > D035.err 2>&1 &
    canu useGrid=false -p asm -d D042 genomeSize=50k -corrected   -nanopore           -raw         ${fileD} > D042.err 2>&1 &
    canu useGrid=false -p asm -d D046 genomeSize=50k -corrected   -nanopore-raw                    ${fileD} > D046.err 2>&1 &
    canu useGrid=false -p asm -d D047 genomeSize=50k -corrected   -nanopore-raw       -raw         ${fileD} > D047.err 2>&1 &
    canu useGrid=false -p asm -d D048 genomeSize=50k -corrected   -nanopore-raw       -corrected   ${fileD} > D048.err 2>&1 &
    wait
    canu useGrid=false -p asm -d D049 genomeSize=50k -corrected   -nanopore-raw       -full-length ${fileD} > D049.err 2>&1 &
    canu useGrid=false -p asm -d D050 genomeSize=50k -corrected   -nanopore-raw       -trimmed     ${fileD} > D050.err 2>&1 &
    canu useGrid=false -p asm -d D052 genomeSize=50k -corrected   -nanopore-corrected -raw         ${fileD} > D052.err 2>&1 &
    canu useGrid=false -p asm -d D065 genomeSize=50k -full-length -nanopore           -trimmed     ${fileD} > D065.err 2>&1 &
    canu useGrid=false -p asm -d D068 genomeSize=50k -full-length -nanopore-raw       -corrected   ${fileD} > D068.err 2>&1 &
    canu useGrid=false -p asm -d D070 genomeSize=50k -full-length -nanopore-raw       -trimmed     ${fileD} > D070.err 2>&1 &
    canu useGrid=false -p asm -d D072 genomeSize=50k -full-length -nanopore-corrected -raw         ${fileD} > D072.err 2>&1 &
    canu useGrid=false -p asm -d D075 genomeSize=50k -full-length -nanopore-corrected -trimmed     ${fileD} > D075.err 2>&1 &
    canu useGrid=false -p asm -d D082 genomeSize=50k -trimmed     -nanopore           -raw         ${fileD} > D082.err 2>&1 &
    canu useGrid=false -p asm -d D084 genomeSize=50k -trimmed     -nanopore           -full-length ${fileD} > D084.err 2>&1 &
    canu useGrid=false -p asm -d D086 genomeSize=50k -trimmed     -nanopore-raw                    ${fileD} > D086.err 2>&1 &
    canu useGrid=false -p asm -d D087 genomeSize=50k -trimmed     -nanopore-raw       -raw         ${fileD} > D087.err 2>&1 &
    canu useGrid=false -p asm -d D088 genomeSize=50k -trimmed     -nanopore-raw       -corrected   ${fileD} > D088.err 2>&1 &
    canu useGrid=false -p asm -d D089 genomeSize=50k -trimmed     -nanopore-raw       -full-length ${fileD} > D089.err 2>&1 &
    canu useGrid=false -p asm -d D090 genomeSize=50k -trimmed     -nanopore-raw       -trimmed     ${fileD} > D090.err 2>&1 &
    canu useGrid=false -p asm -d D092 genomeSize=50k -trimmed     -nanopore-corrected -raw         ${fileD} > D092.err 2>&1 &
    canu useGrid=false -p asm -d D094 genomeSize=50k -trimmed     -nanopore-corrected -full-length ${fileD} > D094.err 2>&1 &
    wait
fi

#
#  Normal HiFi assembly
#

if [ x$mod = xall -o x$mod = "xE" ] ; then
    canu useGrid=false -p asm -d E016 genomeSize=50k              -pacbio-hifi                     ${fileE} > E016.err 2>&1 &
    canu useGrid=false -p asm -d E017 genomeSize=50k              -pacbio-hifi        -raw         ${fileE} > E017.err 2>&1 &
    canu useGrid=false -p asm -d E036 genomeSize=50k -raw         -pacbio-hifi                     ${fileE} > E036.err 2>&1 &
    canu useGrid=false -p asm -d E037 genomeSize=50k -raw         -pacbio-hifi        -raw         ${fileE} > E037.err 2>&1 &
    wait
fi

#
#  Normal HiFi assembly, special case to allow reasonable options
#

if [ x$mod = xall -o x$mod = "xF" ] ; then
    canu useGrid=false -p asm -d F018 genomeSize=50k              -pacbio-hifi        -corrected   ${fileF} > F018.err 2>&1 &
    canu useGrid=false -p asm -d F038 genomeSize=50k -raw         -pacbio-hifi        -corrected   ${fileF} > F038.err 2>&1 &
    canu useGrid=false -p asm -d F020 genomeSize=50k              -pacbio-hifi        -trimmed     ${fileF} > F020.err 2>&1 &
    canu useGrid=false -p asm -d F040 genomeSize=50k -raw         -pacbio-hifi        -trimmed     ${fileF} > F040.err 2>&1 &
    canu useGrid=false -p asm -d F056 genomeSize=50k -corrected   -pacbio-hifi                     ${fileF} > F056.err 2>&1 &
    canu useGrid=false -p asm -d F057 genomeSize=50k -corrected   -pacbio-hifi        -raw         ${fileF} > F057.err 2>&1 &
    canu useGrid=false -p asm -d F058 genomeSize=50k -corrected   -pacbio-hifi        -corrected   ${fileF} > F058.err 2>&1 &
    wait
    canu useGrid=false -p asm -d F059 genomeSize=50k -corrected   -pacbio-hifi        -full-length ${fileF} > F059.err 2>&1 &
    canu useGrid=false -p asm -d F060 genomeSize=50k -corrected   -pacbio-hifi        -trimmed     ${fileF} > F060.err 2>&1 &
    canu useGrid=false -p asm -d F078 genomeSize=50k -full-length -pacbio-hifi        -corrected   ${fileF} > F078.err 2>&1 &
    canu useGrid=false -p asm -d F096 genomeSize=50k -trimmed     -pacbio-hifi                     ${fileF} > F096.err 2>&1 &
    canu useGrid=false -p asm -d F097 genomeSize=50k -trimmed     -pacbio-hifi        -raw         ${fileF} > F097.err 2>&1 &
    canu useGrid=false -p asm -d F098 genomeSize=50k -trimmed     -pacbio-hifi        -corrected   ${fileF} > F098.err 2>&1 &
    canu useGrid=false -p asm -d F100 genomeSize=50k -trimmed     -pacbio-hifi        -trimmed     ${fileF} > F100.err 2>&1 &
    wait
fi

#
#  HiFi assembly with trimming - these all fail.
#

if [ x$mod = xall -o x$mod = "xG" ] ; then
    canu useGrid=false -p asm -d G039 genomeSize=50k -raw         -pacbio-hifi        -full-length ${fileG} > G039.err 2>&1 &
    canu useGrid=false -p asm -d G019 genomeSize=50k              -pacbio-hifi        -full-length ${fileG} > G019.err 2>&1 &
    canu useGrid=false -p asm -d G079 genomeSize=50k -full-length -pacbio-hifi        -full-length ${fileG} > G079.err 2>&1 &
    canu useGrid=false -p asm -d G076 genomeSize=50k -full-length -pacbio-hifi                     ${fileG} > G076.err 2>&1 &
    canu useGrid=false -p asm -d G077 genomeSize=50k -full-length -pacbio-hifi        -raw         ${fileG} > G077.err 2>&1 &
    wait
fi

#
#  HiFi errors
#

if [ x$mod = xall -o x$mod = "xH" ] ; then
    canu useGrid=false -p asm -d H080 genomeSize=50k -full-length -pacbio-hifi        -trimmed     ${fileF} > H080.err 2>&1 &
    canu useGrid=false -p asm -d H099 genomeSize=50k -trimmed     -pacbio-hifi        -full-length ${fileH} > H099.err 2>&1 &
    wait
fi

exit 0
