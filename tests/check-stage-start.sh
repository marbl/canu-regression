#!/bin/sh

#  Run a variety of command line options and check that we run to completion
#  or fail to run, whichever is expected.
#
#  Usage:  check-stage-start.sh
#
#  Takes about 40 minutes.

mod=$1

raw="/data/reads/lambda/lambda.campen.nanopore.fasta.xz"
cor="/data/reads/lambda/lambda.campen.nanopore.corrected.fasta.gz"
tri="/data/reads/lambda/lambda.campen.nanopore.trimmed.fasta.gz"

#  Unlike check-file-options.sh, we CANNOT run these tests on the grid
#  (easily).  The tests depend on restarting canu on a previously completed
#  run.  We CAN, however, run them in the background in parallel.

opts="genomeSize=50k useGrid=false"

#
#  Check results.
#
#  Success is a bit harder than in check-file-options.sh, since
#  there's no consistency in success/fail for the TAGs.
#  We're forced to check each one individually.
#

report_success() {
    dd=$1
    cor=$2
    obt=$3
    utg=$4
    COR=$5
    OBT=$6
    UTG=$7
    cns=$8
    CNS=$9

    if [ $cor -eq 0 ] ; then echo ${dd} did not correct reads, but should have.        ; fi
    if [ $obt -eq 0 ] ; then echo ${dd} did not trim reads, but should have.           ; fi
    if [ $utg -eq 0 ] ; then echo ${dd} did not assemble reads, but should have.       ; fi

    if [ $COR -eq 0 ] ; then echo ${dd} corrected reads, but should not have.          ; fi
    if [ $OBT -eq 0 ] ; then echo ${dd} trimmed reads, but should not have.            ; fi
    if [ $UTG -eq 0 ] ; then echo ${dd} assembled reads, but should not have.          ; fi

    if [ $cns -eq 0 ] ; then echo ${dd} did not generate an assembly, but should have. ; fi
    if [ $CNS -eq 0 ] ; then echo ${dd} generated an assembly but should not have.     ; fi
}

check_success() {
    for lf in A1 \
              Bc1 Bc2 Bc3 Bc4 \
              Bt1 Bt2 Bt3 Bt4 \
              Ba1 Ba2 Ba3 Ba4 \
              C1-1 C1-2 C1-3 C1-4 C1-5 C1-6 \
              C2-1 C2-2 C2-3 C2-4 C2-5 C2-6 \
              C3-1 C3-2 C3-3 C3-4 C3-5 C3-6 \
              D1-1 D1-2 \
              E1 E2 E3 ; do
        dd=`echo $lf | sed s/-[[:digit:]]//`

        cor=0  #  Set to true if we detect that this module
        obt=0  #  was run and that we expected it to.
        utg=0

        COR=1  #  Set to true if we detect that this module 
        OBT=1  #  did NOT run and we expected it not to.
        UTG=1

        if [ -e ${lf}.err ] ; then
            cor=`cat ${lf}.err | grep -c CORRECTION`
            obt=`cat ${lf}.err | grep -c TRIMMING`
            utg=`cat ${lf}.err | grep -c ASSEMBLY`

            COR=`expr 1 - $cor`
            OBT=`expr 1 - $obt`
            UTG=`expr 1 - $utg`
        fi

        cns=0
        CNS=1

        if [ -e ${dd}/asm.contigs.fasta ] ; then
            cns=1
            CNS=0
        fi

        #echo $cor $obt $utg $COR $OBT $UTG $cns $CNS

        #  True if the output doesn't exist and it should not exist --+-------------------+
        #  Set to 1 if the output should exist.                       |                   |
        #                                                            _|_                  |
        #  True if the output exists and it should ----+------------' | `------------+    |
        #  Set to 1 if the output should not exist.    |              |              |    |
        #                                              +----+----+    +----+----+    |    |
        #  Exactly one of lower, UPPER should          |    |    |    |    |    |    |    |
        #  be explicitly set to 0 or 1.                |    |    |    |    |    |    |    |
        #                                              cor  obt  utg COR  OBT  UTG   cns  CNS
        if [ x$lf = xA1   ] ; then report_success $lf $cor $obt $utg  1    1    1   $cns  1   ; fi # ok

        if [ x$lf = xBc1  ] ; then report_success $lf $cor  1    1    1   $OBT $UTG  1   $CNS ; fi # Correct raw reads.
        if [ x$lf = xBc2  ] ; then report_success $lf  1    1    1   $COR $OBT $UTG  1   $CNS ; fi # Correct corrected reads, do nothing.
        if [ x$lf = xBc3  ] ; then report_success $lf  1    1    1   $COR $OBT $UTG  1   $CNS ; fi # Correct trimmed reads, do nothing.
        if [ x$lf = xBc4  ] ; then report_success $lf  1    1    1   $COR $OBT $UTG  1   $CNS ; fi # Correct cor+trim reads, do nothing.

        if [ x$lf = xBt1  ] ; then report_success $lf  1    1    1   $COR $OBT $UTG  1   $CNS ; fi # Trimming raw reads, should fail.
        if [ x$lf = xBt2  ] ; then report_success $lf  1   $obt  1   $COR  1   $UTG  1   $CNS ; fi # Trimming raw reads.
        if [ x$lf = xBt3  ] ; then report_success $lf  1    1    1   $COR $OBT $UTG  1   $CNS ; fi # Trimming trimmed reads, do nothing.
        if [ x$lf = xBt4  ] ; then report_success $lf  1    1    1   $COR $OBT $UTG  1   $CNS ; fi # Trimming cor+trim reads, do nothing.

        if [ x$lf = xBa1  ] ; then report_success $lf  1    1    1   $COR $OBT $UTG  1   $CNS ; fi # Assembling raw reads, should fail.
        if [ x$lf = xBa2  ] ; then report_success $lf  1    1   $utg $COR $OBT  1   $cns  1   ; fi # Assembling corrected reads.
        if [ x$lf = xBa3  ] ; then report_success $lf  1    1   $utg $COR $OBT  1   $cns  1   ; fi # Assembling trimmed reads.
        if [ x$lf = xBa4  ] ; then report_success $lf  1    1   $utg $COR $OBT  1   $cns  1   ; fi # Assembling cor+trim reads.

        if [ x$lf = xC1-1 ] ; then report_success $lf $cor  1    1    1   $OBT $UTG $cns  1   ; fi # Only correction.
        if [ x$lf = xC1-2 ] ; then report_success $lf  1    1    1   $COR $OBT $UTG $cns  1   ; fi # Again, do nothing. 
        if [ x$lf = xC1-3 ] ; then report_success $lf  1   $obt  1   $COR  1   $UTG $cns  1   ; fi # Only trimming.
        if [ x$lf = xC1-4 ] ; then report_success $lf  1    1    1   $COR $OBT $UTG $cns  1   ; fi # Again, do nothing. 
        if [ x$lf = xC1-5 ] ; then report_success $lf  1    1   $utg $COR $OBT  1   $cns  1   ; fi # Only assembly.
        if [ x$lf = xC1-6 ] ; then report_success $lf  1    1    1   $COR $OBT $UTG $cns  1   ; fi # Again, do nothing. 

        if [ x$lf = xC2-1 ] ; then report_success $lf $cor  1    1    1   $OBT $UTG $cns  1   ; fi # Only correction.
        if [ x$lf = xC2-2 ] ; then report_success $lf  1    1    1   $COR $OBT $UTG $cns  1   ; fi # Again, do nothing. 
        if [ x$lf = xC2-3 ] ; then report_success $lf  1   $obt  1   $COR  1   $UTG $cns  1   ; fi # Only trimming.
        if [ x$lf = xC2-4 ] ; then report_success $lf  1    1    1   $COR $OBT $UTG $cns  1   ; fi # Again, do nothing. 
        if [ x$lf = xC2-5 ] ; then report_success $lf  1    1   $utg $COR $OBT  1   $cns  1   ; fi # Only assembly.
        if [ x$lf = xC2-6 ] ; then report_success $lf  1    1    1   $COR $OBT $UTG $cns  1   ; fi # Again, do nothing. 

        if [ x$lf = xC3-1 ] ; then report_success $lf $cor  1    1    1   $OBT $UTG $cns  1   ; fi # Only correction.
        if [ x$lf = xC3-2 ] ; then report_success $lf  1    1    1   $COR $OBT $UTG $cns  1   ; fi # Again, do nothing. 
        if [ x$lf = xC3-3 ] ; then report_success $lf  1   $obt  1   $COR  1   $UTG $cns  1   ; fi # Only trimming.
        if [ x$lf = xC3-4 ] ; then report_success $lf  1    1    1   $COR $OBT $UTG $cns  1   ; fi # Again, do nothing. 
        if [ x$lf = xC3-5 ] ; then report_success $lf  1    1   $utg $COR $OBT  1   $cns  1   ; fi # Only assembly.
        if [ x$lf = xC3-6 ] ; then report_success $lf  1    1    1   $COR $OBT $UTG $cns  1   ; fi # Again, do nothing. 

        if [ x$lf = xD1-1 ] ; then report_success $lf $cor  1    1    1   $OBT $UTG  1   $CNS ; fi # Makes corrected reads.
        if [ x$lf = xD1-2 ] ; then report_success $lf  1    1    1   $COR $OBT $UTG  1   $CNS ; fi # Fails to assembled untrimmed reads.

        if [ x$lf = xE1   ] ; then report_success $lf  1    1   $utg $COR $OBT  1   $cns  1   ; fi # .
        if [ x$lf = xE2   ] ; then report_success $lf  1    1   $utg $COR $OBT  1   $cns  1   ; fi # .
        if [ x$lf = xE3   ] ; then report_success $lf  1    1   $utg $COR $OBT  1   $cns  1   ; fi # .
    done
}




#
#  Check results.
#

if [ x$mod = xcheck ] ; then
    check_success
    exit 0
fi

#
#  Run normally.
#

if [ x$mod = xall -o x$mod = "xA" ] ; then
    echo Starting A jobs.

    canu $opts -p asm -d A1 -nanopore ${raw} > A1.err 2>&1 &

    wait
fi

#
#  Test that we can start from all the places that make sense (and some that
#  don't).
#

if [ x$mod = xall -o x$mod = "xB" ] ; then
    echo Starting B jobs.

    canu $opts -p asm -d Bc1 -correct  -nanopore                     ${raw} > Bc1.err 2>&1 &
    canu $opts -p asm -d Bc2 -correct  -nanopore -corrected          ${raw} > Bc2.err 2>&1 &
    canu $opts -p asm -d Bc3 -correct  -nanopore            -trimmed ${raw} > Bc3.err 2>&1 &
    canu $opts -p asm -d Bc4 -correct  -nanopore -corrected -trimmed ${raw} > Bc4.err 2>&1 &

    canu $opts -p asm -d Bt1 -trim     -nanopore                     ${cor} > Bt1.err 2>&1 &
    canu $opts -p asm -d Bt2 -trim     -nanopore -corrected          ${cor} > Bt2.err 2>&1 &
    canu $opts -p asm -d Bt3 -trim     -nanopore            -trimmed ${cor} > Bt3.err 2>&1 &
    canu $opts -p asm -d Bt4 -trim     -nanopore -corrected -trimmed ${cor} > Bt4.err 2>&1 &

    canu $opts -p asm -d Ba1 -assemble -nanopore                     ${tri} > Ba1.err 2>&1 &
    canu $opts -p asm -d Ba2 -assemble -nanopore -corrected          ${tri} > Ba2.err 2>&1 &
    canu $opts -p asm -d Ba3 -assemble -nanopore            -trimmed ${tri} > Ba3.err 2>&1 &
    canu $opts -p asm -d Ba4 -assemble -nanopore -corrected -trimmed ${tri} > Ba4.err 2>&1 &

    wait
fi

#
#  Test restarts in the same directory.
#   - C1 tests if we can restart with no input files supplied.
#   - C2 tests if we can restart with    input files supplied.
#   - C3 tests if we can restart with different input files and types supplied.
#
#  All test that restarting a finished stage does nothing.

if [ x$mod = xall -o x$mod = "xC" ] ; then
    echo Starting C jobs.

    canu $opts -p asm -d C1 -correct   -nanopore ${raw} > C1-1.err 2>&1 && \
    canu $opts -p asm -d C1 -correct                    > C1-2.err 2>&1 && \
    canu $opts -p asm -d C1 -trim                       > C1-3.err 2>&1 && \
    canu $opts -p asm -d C1 -trim                       > C1-4.err 2>&1 && \
    canu $opts -p asm -d C1 -assemble                   > C1-5.err 2>&1 && \
    canu $opts -p asm -d C1 -assemble                   > C1-6.err 2>&1 &

    canu $opts -p asm -d C2 -correct   -nanopore ${raw} > C2-1.err 2>&1 && \
    canu $opts -p asm -d C2 -correct   -nanopore ${raw} > C2-2.err 2>&1 && \
    canu $opts -p asm -d C2 -trim      -nanopore ${raw} > C2-3.err 2>&1 && \
    canu $opts -p asm -d C2 -trim      -nanopore ${raw} > C2-4.err 2>&1 && \
    canu $opts -p asm -d C2 -assemble  -nanopore ${raw} > C2-5.err 2>&1 && \
    canu $opts -p asm -d C2 -assemble  -nanopore ${raw} > C2-6.err 2>&1 &

    canu $opts -p asm -d C3 -correct   -nanopore            ${cor} > C3-1.err 2>&1 && \
    canu $opts -p asm -d C3 -correct   -nanopore -corrected ${raw} > C3-2.err 2>&1 && \
    canu $opts -p asm -d C3 -trim      -nanopore -raw       ${tri} > C3-3.err 2>&1 && \
    canu $opts -p asm -d C3 -trim      -nanopore -trimmed   ${tri} > C3-4.err 2>&1 && \
    canu $opts -p asm -d C3 -assemble  -nanopore -raw       ${cor} > C3-5.err 2>&1 && \
    canu $opts -p asm -d C3 -assemble  -nanopore -corrected ${raw} > C3-6.err 2>&1 &

    wait
fi

#
#  Run only correction and assembly.
#

if [ x$mod = xall -o x$mod = "xD" ] ; then
    echo Starting D jobs.

    canu $opts -p asm -d D1 -correct   -nanopore ${raw} > D1-1.err 2>&1 && \
    canu $opts -p asm -d D1 -assemble                   > D1-2.err 2>&1 &

    wait
fi

#
#  Run only assembly.
#

if [ x$mod = xall -o x$mod = "xE" ] ; then
    echo Starting E jobs.

    canu $opts -p asm -d E1 -assemble  -corrected          -nanopore ${tri} > E1.err 2>&1 && \
    canu $opts -p asm -d E2 -assemble  -corrected -trimmed -nanopore ${tri} > E2.err 2>&1 && \
    canu $opts -p asm -d E3 -assemble             -trimmed -nanopore ${tri} > E3.err 2>&1 &

    wait
fi



#  COMPATIBILITY MODE
#
#  The last fails because it doesn't load as trimmed data.
#
#canu $opts -p asm -d stage-compat-1            -nanopore-raw         READS/1-raw.fasta  > stage-compat-1.err 2>&1
#canu $opts -p asm -d stage-compat-2 -correct   -nanopore-raw         READS/1-raw.fasta  > stage-compat-2.err 2>&1
#canu $opts -p asm -d stage-compat-3 -trim      -nanopore-corrected   READS/2-co*.fasta  > stage-compat-3.err 2>&1
#canu $opts -p asm -d stage-compat-4 -assemble  -nanopore-corrected   READS/3-tr*.fasta  > stage-compat-4.err 2>&1
