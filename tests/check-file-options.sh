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

if [ x$mod = x ] ; then
    echo "Usage:  check-file-options.sh [A | B | C | D] -- check Nanopore assemblies"
    echo "        check-file-options.sh [E | F | G | H] -- check HiFi assemblies"
    echo "        check-file-options.sh all"
    echo "        check-file-options.sh check"
    exit 0
fi

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

#  This is just gross.
#
#  optsS are the 'sizing' options.  optsG are the 'grid options'.  They're in
#  two strings because it seems not possible to get the gridOptins passed as
#  one string unless the variable itself is surrounded by quotes - as in
#  "$optsG" (including the quotes).  Every other attempt I made kept
#  splitting optsS into individual words, resulting in canu seeing option
#  words such as: "gridOptions=-pe or gridOptions=-pe/
#
#  These sizes are carefully chosen so that everything will fit in a fairly
#  small executive process.

optsS="genomeSize=50k useGrid=true corMemory=4g corThreads=2 ovlMemory=6g ovlThreads=4 mhapMemory=6g batMemory=4g redMemory=6g oeaMemory=4g cnsPartitions=1 executiveMemory=8g executiveThreads=4 gridOptionsExecutive="
optsG="gridOptions=-pe thread 2"


#
#  Declare success if there is a contigs.fasta output,
#  regardless of if having anything in it.  All we care
#  is that the pipeline ran.  Also check that the proper
#  stages ran.
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
        if [   -e ${dd}/canu-scripts/canu.02.out ] ; then
            echo ${dd} has canu.02.out, but should not.
        fi
        if [ ! -e ${dd}/canu-scripts/canu.01.out ] ; then
            echo ${dd} has no canu.01.out, but should.
        fi
        if [   -e ${dd}/canu-scripts/canu.01.out ] ; then
            cor=`grep -c CORRECTION ${dd}/canu-scripts/canu.01.out`
            obt=`grep -c TRIMMING   ${dd}/canu-scripts/canu.01.out`
            utg=`grep -c ASSEMBLY   ${dd}/canu-scripts/canu.01.out`

            if [ ${TAG} = "A" ] ; then
                if [ $cor -eq 0 ] ; then echo ${dd} did not correct reads, but should have. ; fi
                if [ $obt -eq 0 ] ; then echo ${dd} did not trim reads, but should have. ; fi
                if [ $utg -eq 0 ] ; then echo ${dd} did not assemble reads, but should have. ; fi
            fi

            if [ ${TAG} = "B" ] ; then
                if [ $cor -eq 1 ] ; then echo ${dd} corrected reads, but should not have. ; fi
                if [ $obt -eq 0 ] ; then echo ${dd} did not trim reads, but should have. ; fi
                if [ $utg -eq 0 ] ; then echo ${dd} did not assemble reads, but should have. ; fi
            fi

            if [ ${TAG} = "C" ] ; then
                if [ $cor -eq 1 ] ; then echo ${dd} corrected reads, but should not have. ; fi
                if [ $obt -eq 1 ] ; then echo ${dd} trimmed reads, but should not have. ; fi
                if [ $utg -eq 0 ] ; then echo ${dd} did not assemble reads, but should have. ; fi
            fi

            if [ ${TAG} = "D" ] ; then
                echo ${dd} H should not be calling check_success.
            fi

            if [ ${TAG} = "E" ] ; then
                if [ $cor -eq 1 ] ; then echo ${dd} corrected reads, but should not have. ; fi
                if [ $obt -eq 1 ] ; then echo ${dd} trimmed reads, but should not have. ; fi
                if [ $utg -eq 0 ] ; then echo ${dd} did not assemble reads, but should have. ; fi
            fi

            if [ ${TAG} = "F" ] ; then
                if [ $cor -eq 1 ] ; then echo ${dd} corrected reads, but should not have. ; fi
                if [ $obt -eq 1 ] ; then echo ${dd} trimmed reads, but should not have. ; fi
                if [ $utg -eq 0 ] ; then echo ${dd} did not assemble reads, but should have. ; fi
            fi

            if [ ${TAG} = "G" ] ; then
                if [ $cor -eq 1 ] ; then echo ${dd} corrected reads, but should not have. ; fi
                if [ $obt -eq 0 ] ; then echo ${dd} did not trim reads, but should have. ; fi
                if [ $utg -eq 0 ] ; then echo ${dd} did not assemble reads, but should have. ; fi
            fi

            if [ ${TAG} = "H" ] ; then
                echo ${dd} H should not be calling check_success.
            fi
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
#  Suspend grid operations to make job submission quicker.
#

for Q in `qconf -sql` ; do
  echo Disabling queue $Q.
  qmod -d $Q > /dev/null 2> /dev/null
done

#
#  Normal Nanopore assembly
#

if [ x$mod = xall -o x$mod = "xA" ] ; then
    echo Starting A part 1.
    canu ${optsS} "${optsG}" -p asm -d A001            -nanopore                      ${fileA} > A001.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d A002            -nanopore           -raw       ${fileA} > A002.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d A004            -nanopore           -untrimmed ${fileA} > A004.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d A006            -nanopore-raw                  ${fileA} > A006.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d A007            -nanopore-raw       -raw       ${fileA} > A007.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d A009            -nanopore-raw       -untrimmed ${fileA} > A009.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d A021 -raw       -nanopore                      ${fileA} > A021.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d A022 -raw       -nanopore           -raw       ${fileA} > A022.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d A024 -raw       -nanopore           -untrimmed ${fileA} > A024.err 2>&1
    wait
    echo Starting A part 2.
    canu ${optsS} "${optsG}" -p asm -d A026 -raw       -nanopore-raw                  ${fileA} > A026.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d A027 -raw       -nanopore-raw       -raw       ${fileA} > A027.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d A029 -raw       -nanopore-raw       -untrimmed ${fileA} > A029.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d A061 -untrimmed -nanopore                      ${fileA} > A061.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d A062 -untrimmed -nanopore           -raw       ${fileA} > A062.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d A064 -untrimmed -nanopore           -untrimmed ${fileA} > A064.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d A066 -untrimmed -nanopore-raw                  ${fileA} > A066.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d A067 -untrimmed -nanopore-raw       -raw       ${fileA} > A067.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d A069 -untrimmed -nanopore-raw       -untrimmed ${fileA} > A069.err 2>&1
    wait
fi

#
#  Pre-corrected Nanopore assembly
#

if [ x$mod = xall -o x$mod = "xB" ] ; then
    echo Starting B part 1.
    canu ${optsS} "${optsG}" -p asm -d B003            -nanopore           -corrected ${fileB} > B003.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d B011            -nanopore-corrected            ${fileB} > B011.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d B013            -nanopore-corrected -corrected ${fileB} > B013.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d B014            -nanopore-corrected -untrimmed ${fileB} > B014.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d B041 -corrected -nanopore                      ${fileB} > B041.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d B043 -corrected -nanopore           -corrected ${fileB} > B043.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d B044 -corrected -nanopore           -untrimmed ${fileB} > B044.err 2>&1
    wait
    echo Starting B part 2.
    canu ${optsS} "${optsG}" -p asm -d B051 -corrected -nanopore-corrected            ${fileB} > B051.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d B053 -corrected -nanopore-corrected -corrected ${fileB} > B053.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d B054 -corrected -nanopore-corrected -untrimmed ${fileB} > B054.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d B063 -untrimmed -nanopore           -corrected ${fileB} > B063.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d B071 -untrimmed -nanopore-corrected            ${fileB} > B071.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d B073 -untrimmed -nanopore-corrected -corrected ${fileB} > B073.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d B074 -untrimmed -nanopore-corrected -untrimmed ${fileB} > B074.err 2>&1
    wait
fi

#
#  Pre-trimmed Nanopore assembly
#

if [ x$mod = xall -o x$mod = "xC" ] ; then
    echo Starting C part 1.
    canu ${optsS} "${optsG}" -p asm -d C005            -nanopore           -trimmed   ${fileC} > C005.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d C015            -nanopore-corrected -trimmed   ${fileC} > C015.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d C045 -corrected -nanopore           -trimmed   ${fileC} > C045.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d C055 -corrected -nanopore-corrected -trimmed   ${fileC} > C055.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d C081 -trimmed   -nanopore                      ${fileC} > C081.err 2>&1
    wait
    echo Starting C part 2.
    canu ${optsS} "${optsG}" -p asm -d C083 -trimmed   -nanopore           -corrected ${fileC} > C083.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d C085 -trimmed   -nanopore           -trimmed   ${fileC} > C085.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d C091 -trimmed   -nanopore-corrected            ${fileC} > C091.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d C093 -trimmed   -nanopore-corrected -corrected ${fileC} > C093.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d C095 -trimmed   -nanopore-corrected -trimmed   ${fileC} > C095.err 2>&1
    wait
fi

#
#  Invalid assemblies.
#

if [ x$mod = xall -o x$mod = "xD" ] ; then
    echo Starting D part 1.
    canu ${optsS} "${optsG}" -p asm -d D008            -nanopore-raw       -corrected ${fileB} > D008.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d D010            -nanopore-raw       -trimmed   ${fileD} > D010.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d D012            -nanopore-corrected -raw       ${fileD} > D012.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d D023 -raw       -nanopore           -corrected ${fileD} > D023.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d D025 -raw       -nanopore           -trimmed   ${fileD} > D025.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d D028 -raw       -nanopore-raw       -corrected ${fileD} > D028.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d D030 -raw       -nanopore-raw       -trimmed   ${fileD} > D030.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d D031 -raw       -nanopore-corrected            ${fileD} > D031.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d D032 -raw       -nanopore-corrected -raw       ${fileD} > D032.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d D033 -raw       -nanopore-corrected -corrected ${fileD} > D033.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d D034 -raw       -nanopore-corrected -untrimmed ${fileD} > D034.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d D035 -raw       -nanopore-corrected -trimmed   ${fileD} > D035.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d D042 -corrected -nanopore           -raw       ${fileD} > D042.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d D046 -corrected -nanopore-raw                  ${fileD} > D046.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d D047 -corrected -nanopore-raw       -raw       ${fileD} > D047.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d D048 -corrected -nanopore-raw       -corrected ${fileD} > D048.err 2>&1
    wait
    echo Starting D part 2.
    canu ${optsS} "${optsG}" -p asm -d D049 -corrected -nanopore-raw       -untrimmed ${fileD} > D049.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d D050 -corrected -nanopore-raw       -trimmed   ${fileD} > D050.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d D052 -corrected -nanopore-corrected -raw       ${fileD} > D052.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d D065 -untrimmed -nanopore           -trimmed   ${fileD} > D065.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d D068 -untrimmed -nanopore-raw       -corrected ${fileD} > D068.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d D070 -untrimmed -nanopore-raw       -trimmed   ${fileD} > D070.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d D072 -untrimmed -nanopore-corrected -raw       ${fileD} > D072.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d D075 -untrimmed -nanopore-corrected -trimmed   ${fileD} > D075.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d D082 -trimmed   -nanopore           -raw       ${fileD} > D082.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d D084 -trimmed   -nanopore           -untrimmed ${fileD} > D084.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d D086 -trimmed   -nanopore-raw                  ${fileD} > D086.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d D087 -trimmed   -nanopore-raw       -raw       ${fileD} > D087.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d D088 -trimmed   -nanopore-raw       -corrected ${fileD} > D088.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d D089 -trimmed   -nanopore-raw       -untrimmed ${fileD} > D089.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d D090 -trimmed   -nanopore-raw       -trimmed   ${fileD} > D090.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d D092 -trimmed   -nanopore-corrected -raw       ${fileD} > D092.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d D094 -trimmed   -nanopore-corrected -untrimmed ${fileD} > D094.err 2>&1
    wait
fi

#
#  Normal HiFi assembly
#

if [ x$mod = xall -o x$mod = "xE" ] ; then
    echo Starting E.
    canu ${optsS} "${optsG}" -p asm -d E016            -pacbio-hifi                   ${fileE} > E016.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d E017            -pacbio-hifi        -raw       ${fileE} > E017.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d E036 -raw       -pacbio-hifi                   ${fileE} > E036.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d E037 -raw       -pacbio-hifi        -raw       ${fileE} > E037.err 2>&1
    wait
fi

#
#  Normal HiFi assembly, special case to allow reasonable options
#

if [ x$mod = xall -o x$mod = "xF" ] ; then
    echo Starting F part 1.
    canu ${optsS} "${optsG}" -p asm -d F018            -pacbio-hifi        -corrected ${fileF} > F018.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d F038 -raw       -pacbio-hifi        -corrected ${fileF} > F038.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d F020            -pacbio-hifi        -trimmed   ${fileF} > F020.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d F040 -raw       -pacbio-hifi        -trimmed   ${fileF} > F040.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d F056 -corrected -pacbio-hifi                   ${fileF} > F056.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d F057 -corrected -pacbio-hifi        -raw       ${fileF} > F057.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d F058 -corrected -pacbio-hifi        -corrected ${fileF} > F058.err 2>&1
    wait
    echo Starting F part 2.
    canu ${optsS} "${optsG}" -p asm -d F059 -corrected -pacbio-hifi        -untrimmed ${fileF} > F059.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d F060 -corrected -pacbio-hifi        -trimmed   ${fileF} > F060.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d F078 -untrimmed -pacbio-hifi        -corrected ${fileF} > F078.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d F096 -trimmed   -pacbio-hifi                   ${fileF} > F096.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d F097 -trimmed   -pacbio-hifi        -raw       ${fileF} > F097.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d F098 -trimmed   -pacbio-hifi        -corrected ${fileF} > F098.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d F100 -trimmed   -pacbio-hifi        -trimmed   ${fileF} > F100.err 2>&1
    wait
fi

#
#  HiFi assembly with trimming - these all fail.
#

if [ x$mod = xall -o x$mod = "xG" ] ; then
    echo Starting G.
    canu ${optsS} "${optsG}" -p asm -d G039 -raw       -pacbio-hifi        -untrimmed ${fileG} > G039.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d G019            -pacbio-hifi        -untrimmed ${fileG} > G019.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d G079 -untrimmed -pacbio-hifi        -untrimmed ${fileG} > G079.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d G076 -untrimmed -pacbio-hifi                   ${fileG} > G076.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d G077 -untrimmed -pacbio-hifi        -raw       ${fileG} > G077.err 2>&1
    wait
fi

#
#  HiFi errors
#

if [ x$mod = xall -o x$mod = "xH" ] ; then
    echo Starting H.
    canu ${optsS} "${optsG}" -p asm -d H080 -untrimmed -pacbio-hifi        -trimmed   ${fileF} > H080.err 2>&1
    canu ${optsS} "${optsG}" -p asm -d H099 -trimmed   -pacbio-hifi        -untrimmed ${fileH} > H099.err 2>&1
    wait
fi

#
#  Enable queues.
#

for Q in `qconf -sql` ; do
  echo Enabling queue $Q.
  qmod -e $Q > /dev/null 2> /dev/null
done

exit 0
