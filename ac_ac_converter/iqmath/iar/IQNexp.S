//*****************************************************************************
//
// IQexp.S - Fixed point e^x
//
// Copyright (c) 2010 Texas Instruments Incorporated.  All rights reserved.
// TI Information - Selective Disclosure
//
//*****************************************************************************

//*****************************************************************************
//
// Function:   _IQNexp
//
//*****************************************************************************
//
// C Usage:    extern long _IQNexp(long X); // with saturation and rounding
//
//-----------------------------------------------------------------------------
//
// On Entry:   r0     = Val in IQ format
//
// Regs Used:  r0-r3, r12
//
// On Exit:    r0     = e^x result in IQ format
//             r0     = max value "0x7FFFFFFF" if result saturates
//
// Q range:    30 to 1
//
//-----------------------------------------------------------------------------
//
// Algorithm:
//
//      Step 0)  Multiply the input by log(2).  This allows us to perform the
//               remaining calculations as 2^x, which has nice properties.
//
//      Step 1)  Separate the fractional and integer portion of the input. The
//               The integer portion is saved for step 3.  If it will saturate,
//               bail out now.
//
//      Step 2)  Calculate 2^frac(x) using a 7th order polynomial.  The
//               coefficients have been selected to minimize the maximal error
//               over the range of x=[0,1].  Please see the attached python
//               script that was used to find these optimal coefficients.
//               Using these coefficients, rather than a Taylor series, allows
//               us to use ~3-4 fewer terms in the expansion with similar
//               accuracy.  Note that these coefficients are slightly different
//               than the ones used for exp2 and should not be used
//               interchangeably.
//
//      Step 3)  Shift result of step 3 per the integer portion of the input.
//               Saturate and round as appropriate.
//
//##### INTERNAL BEGIN #####
//-----------------------------------------------------------------------------
//
// Future Work:
//   I estimate that there are on the order of 3-6 cycles that can be
//   recovered from this algorithm by re-arranging some of the registers in
//   the interaction between steps 0 and 1.
//
//   The multiplication by 1/ln(2) is currently implemented as a
//   post-compensated unsigned multiply.  Implementing it as a signed multiply
//   would remove the .reapply_sign_ branch, and would likely obviate the
//   clean up code surrounding it.
//
//##### INTERNAL END #####
//-----------------------------------------------------------------------------
//
// Benchmark:
//      Overflow  :           38 Cycles
//      Large Positive Input: 96 Cycles
//      Large Negative Input: 98 Cycles
//      Small Positive Input: 96 Cycles
//      Small Negative Input: 96 Cycles
//
//*****************************************************************************

//*****************************************************************************
//
// _IQ1exp
//
//*****************************************************************************
    section CODE__IQ1exp:CODE(2)
    thumb
    export  _IQ1exp
_IQ1exp
    //
    // Take the absolute value of the input.
    //
    teq     r0, #0
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply input by 1/log(2). This transforms the problem from e^x to 2^x
    // The register set {r0,r2,r3} represents X in GQ-2 format.
    //
    ldr     r12, one_over_ln_2_2_1
    mov     r1, #0
    umull   r3, r2, r12, r0
    ldr     r12, one_over_ln_2_1_1
    umlal   r2, r1, r12, r0

    //
    // Place fractional portion of input in r3 in Q32
    //
    lsl     r3, r3, #31
    orr     r3, r3, r2, lsl #1

    //
    // Reapply the sign of the input.
    //
    bpl     reapply_sign_1

    //
    // For Q=1 or Q=2, it is more effective to explicitly test for the single
    // case in which we generate a carry into the shift value: X = 0xFFFFFFFE
    // In this special case, return early with the precomputed answer.
    // For all other cases, the inaccuracy created by doing this is masked by
    // the low resolution of such a low value of Q.
    //
    teq     r0, #2
    itt     eq
        moveq   r0, #1
        bxeq    lr
    rsb     r3, r3, #0
    rsb     r1, r1, #0

    //
    // Calculate the final shift required.
    // This calculation is (integer portion of X)-(30-Q)
    // If this is negative, it will cause saturation later: bail now.
    //
reapply_sign_1
    lsl     r12, r1, #1
    add     r12, r12, r2, lsr #31
    rsbs    r12, r12, #(30 - 1)
    bmi     exp_saturation_1
    mov     r1, r3

    //
    // Calculate the approximating polynomial.
    // R0 Result in Q30
    // R1 X, fractional portion in Q32
    // R2 Coefficient
    // R3 Multiplication scratch space.
    //
    ldr     r2, coefficient_7_1
    umull   r3, r0, r2, r1
    ldr     r2, coefficient_6_1
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_5_1
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_4_1
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_3_1
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_2_1
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_1_1
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_0_1
    adds    r0, r0, r2

    //
    // Shift answer down per previously calculated value and round.
    // NOTE:  If r12 is zero, the carry bit will "stick" at whatever it was
    // and will not be updated by lsrs.  This can cause one count of error in
    // these cases.  The adds just above is intended to reset the carry to 0.
    // This is likely unnecessary, as it helps less than 0.5% of the time. It
    // incurs no cycle count penalty, so it stays for now.
    //
    lsrs    r0, r0, r12
    adc     r0, r0, #0

    //
    // The shift instruction ignores the upper bits.  If those bits are set,
    // set the output to 0 manually.
    //
    lsrs    r12, r12, #5
    it      ne
        movne   r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Handles the case where the result saturates.
    //
exp_saturation_1
    mvn     r0, #0x80000000
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
one_over_ln_2_1_1
    dcd     0x5c551d94
one_over_ln_2_2_1
    dcd     0xae0bf85e
coefficient_0_1
    dcd     0x3fffffff
coefficient_1_1
    dcd     0x2c5c861b
coefficient_2_1
    dcd     0x0f5fde0d
coefficient_3_1
    dcd     0x038d669b
coefficient_4_1
    dcd     0x009d817c
coefficient_5_1
    dcd     0x00160186
coefficient_6_1
    dcd     0x00025756
coefficient_7_1
    dcd     0x00005ae9

//*****************************************************************************
//
// _IQ2exp
//
//*****************************************************************************
    section CODE__IQ2exp:CODE(2)
    thumb
    export  _IQ2exp
_IQ2exp
    //
    // Take the absolute value of the input.
    //
    teq     r0, #0
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply input by 1/log(2). This transforms the problem from e^x to 2^x
    // The register set {r0,r2,r3} represents X in GQ-2 format.
    //
    ldr     r12, one_over_ln_2_2_2
    mov     r1, #0
    umull   r3, r2, r12, r0
    ldr     r12, one_over_ln_2_1_2
    umlal   r2, r1, r12, r0

    //
    // Place fractional portion of input in r3 in Q32
    //
    mov     r3, r2

    //
    // Reapply the sign of the input.
    //
    bpl     reapply_sign_2

    //
    // For Q=1 or Q=2, it is more effective to explicitly test for the single
    // case in which we generate a carry into the shift value: X = 0xFFFFFFFE
    // In this special case, return early with the precomputed answer.
    // For all other cases, the inaccuracy created by doing this is masked by
    // the low resolution of such a low value of Q.
    //
    teq     r0, #2
    itt     eq
        moveq   r0, #2
        bxeq    lr
    rsb     r1, r1, #0

    //
    // Calculate the final shift required.
    // This calculation is (integer portion of X)-(30-Q)
    // If this is negative, it will cause saturation later: bail now.
    //
reapply_sign_2
    rsbs    r12, r1, #(30 - 2)
    bmi     exp_saturation_2
    mov     r1, r3

    //
    // Calculate the approximating polynomial.
    // R0 Result in Q30
    // R1 X, fractional portion in Q32
    // R2 Coefficient
    // R3 Multiplication scratch space.
    //
    ldr     r2, coefficient_7_2
    umull   r3, r0, r2, r1
    ldr     r2, coefficient_6_2
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_5_2
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_4_2
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_3_2
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_2_2
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_1_2
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_0_2
    adds    r0, r0, r2

    //
    // Shift answer down per previously calculated value and round.
    // NOTE:  If r12 is zero, the carry bit will "stick" at whatever it was
    // and will not be updated by lsrs.  This can cause one count of error in
    // these cases.  The adds just above is intended to reset the carry to 0.
    // This is likely unnecessary, as it helps less than 0.5% of the time. It
    // incurs no cycle count penalty, so it stays for now.
    //
    lsrs    r0, r0, r12
    adc     r0, r0, #0

    //
    // The shift instruction ignores the upper bits.  If those bits are set,
    // set the output to 0 manually.
    //
    lsrs    r12, r12, #5
    it      ne
        movne   r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Handles the case where the result saturates.
    //
exp_saturation_2
    mvn     r0, #0x80000000
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
one_over_ln_2_1_2
    dcd     0x5c551d94
one_over_ln_2_2_2
    dcd     0xae0bf85e
coefficient_0_2
    dcd     0x3fffffff
coefficient_1_2
    dcd     0x2c5c861b
coefficient_2_2
    dcd     0x0f5fde0d
coefficient_3_2
    dcd     0x038d669b
coefficient_4_2
    dcd     0x009d817c
coefficient_5_2
    dcd     0x00160186
coefficient_6_2
    dcd     0x00025756
coefficient_7_2
    dcd     0x00005ae9

//*****************************************************************************
//
// _IQ3exp
//
//*****************************************************************************
    section CODE__IQ3exp:CODE(2)
    thumb
    export  _IQ3exp
_IQ3exp
    //
    // Take the absolute value of the input.
    //
    teq     r0, #0
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply input by 1/log(2). This transforms the problem from e^x to 2^x
    // The register set {r0,r2,r3} represents X in GQ-2 format.
    //
    ldr     r12, one_over_ln_2_2_3
    mov     r1, #0
    umull   r3, r2, r12, r0
    ldr     r12, one_over_ln_2_1_3
    umlal   r2, r1, r12, r0

    //
    // Place fractional portion of input in r1 in Q32
    //
    lsl     r3, r1, #(96 - (62 + 3))
    orr     r3, r3, r2, lsr #(3 - 2)

    //
    // Reapply the sign of the input.
    //
    bpl     reapply_sign_3

    rsbs    r3, r3, #0
    it      mi
        addmi   r1, r1, #(1 << (3 - 3))
        rsb     r1, r1, #0

    //
    // Calculate the final shift required.
    // This calculation is (integer portion of X)-(30-Q)
    // If this is negative, it will cause saturation later: bail now.
    //
reapply_sign_3
    asr     r12, r1, #(3 - 2)
    rsbs    r12, r12, #(30 - 3)
    bmi     exp_saturation_3
    mov     r1, r3

    //
    // Calculate the approximating polynomial.
    // R0 Result in Q30
    // R1 X, fractional portion in Q32
    // R2 Coefficient
    // R3 Multiplication scratch space.
    //
    ldr     r2, coefficient_7_3
    umull   r3, r0, r2, r1
    ldr     r2, coefficient_6_3
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_5_3
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_4_3
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_3_3
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_2_3
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_1_3
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_0_3
    adds    r0, r0, r2

    //
    // Shift answer down per previously calculated value and round.
    // NOTE:  If r12 is zero, the carry bit will "stick" at whatever it was
    // and will not be updated by lsrs.  This can cause one count of error in
    // these cases.  The adds just above is intended to reset the carry to 0.
    // This is likely unnecessary, as it helps less than 0.5% of the time. It
    // incurs no cycle count penalty, so it stays for now.
    //
    lsrs    r0, r0, r12
    adc     r0, r0, #0

    //
    // The shift instruction ignores the upper bits.  If those bits are set,
    // set the output to 0 manually.
    //
    lsrs    r12, r12, #5
    it      ne
        movne   r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Handles the case where the result saturates.
    //
exp_saturation_3
    mvn     r0, #0x80000000
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
one_over_ln_2_1_3
    dcd     0x5c551d94
one_over_ln_2_2_3
    dcd     0xae0bf85e
coefficient_0_3
    dcd     0x3fffffff
coefficient_1_3
    dcd     0x2c5c861b
coefficient_2_3
    dcd     0x0f5fde0d
coefficient_3_3
    dcd     0x038d669b
coefficient_4_3
    dcd     0x009d817c
coefficient_5_3
    dcd     0x00160186
coefficient_6_3
    dcd     0x00025756
coefficient_7_3
    dcd     0x00005ae9

//*****************************************************************************
//
// _IQ4exp
//
//*****************************************************************************
    section CODE__IQ4exp:CODE(2)
    thumb
    export  _IQ4exp
_IQ4exp
    //
    // Take the absolute value of the input.
    //
    teq     r0, #0
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply input by 1/log(2). This transforms the problem from e^x to 2^x
    // The register set {r0,r2,r3} represents X in GQ-2 format.
    //
    ldr     r12, one_over_ln_2_2_4
    mov     r1, #0
    umull   r3, r2, r12, r0
    ldr     r12, one_over_ln_2_1_4
    umlal   r2, r1, r12, r0

    //
    // Place fractional portion of input in r1 in Q32
    //
    lsl     r3, r1, #(96 - (62 + 4))
    orr     r3, r3, r2, lsr #(4 - 2)

    //
    // Reapply the sign of the input.
    //
    bpl     reapply_sign_4

    rsbs    r3, r3, #0
    it      mi
        addmi   r1, r1, #(1 << (4 - 3))
        rsb     r1, r1, #0

    //
    // Calculate the final shift required.
    // This calculation is (integer portion of X)-(30-Q)
    // If this is negative, it will cause saturation later: bail now.
    //
reapply_sign_4
    asr     r12, r1, #(4 - 2)
    rsbs    r12, r12, #(30 - 4)
    bmi     exp_saturation_4
    mov     r1, r3

    //
    // Calculate the approximating polynomial.
    // R0 Result in Q30
    // R1 X, fractional portion in Q32
    // R2 Coefficient
    // R3 Multiplication scratch space.
    //
    ldr     r2, coefficient_7_4
    umull   r3, r0, r2, r1
    ldr     r2, coefficient_6_4
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_5_4
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_4_4
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_3_4
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_2_4
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_1_4
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_0_4
    adds    r0, r0, r2

    //
    // Shift answer down per previously calculated value and round.
    // NOTE:  If r12 is zero, the carry bit will "stick" at whatever it was
    // and will not be updated by lsrs.  This can cause one count of error in
    // these cases.  The adds just above is intended to reset the carry to 0.
    // This is likely unnecessary, as it helps less than 0.5% of the time. It
    // incurs no cycle count penalty, so it stays for now.
    //
    lsrs    r0, r0, r12
    adc     r0, r0, #0

    //
    // The shift instruction ignores the upper bits.  If those bits are set,
    // set the output to 0 manually.
    //
    lsrs    r12, r12, #5
    it      ne
        movne   r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Handles the case where the result saturates.
    //
exp_saturation_4
    mvn     r0, #0x80000000
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
one_over_ln_2_1_4
    dcd     0x5c551d94
one_over_ln_2_2_4
    dcd     0xae0bf85e
coefficient_0_4
    dcd     0x3fffffff
coefficient_1_4
    dcd     0x2c5c861b
coefficient_2_4
    dcd     0x0f5fde0d
coefficient_3_4
    dcd     0x038d669b
coefficient_4_4
    dcd     0x009d817c
coefficient_5_4
    dcd     0x00160186
coefficient_6_4
    dcd     0x00025756
coefficient_7_4
    dcd     0x00005ae9

//*****************************************************************************
//
// _IQ5exp
//
//*****************************************************************************
    section CODE__IQ5exp:CODE(2)
    thumb
    export  _IQ5exp
_IQ5exp
    //
    // Take the absolute value of the input.
    //
    teq     r0, #0
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply input by 1/log(2). This transforms the problem from e^x to 2^x
    // The register set {r0,r2,r3} represents X in GQ-2 format.
    //
    ldr     r12, one_over_ln_2_2_5
    mov     r1, #0
    umull   r3, r2, r12, r0
    ldr     r12, one_over_ln_2_1_5
    umlal   r2, r1, r12, r0

    //
    // Place fractional portion of input in r1 in Q32
    //
    lsl     r3, r1, #(96 - (62 + 5))
    orr     r3, r3, r2, lsr #(5 - 2)

    //
    // Reapply the sign of the input.
    //
    bpl     reapply_sign_5

    rsbs    r3, r3, #0
    it      mi
        addmi   r1, r1, #(1 << (5 - 3))
        rsb     r1, r1, #0

    //
    // Calculate the final shift required.
    // This calculation is (integer portion of X)-(30-Q)
    // If this is negative, it will cause saturation later: bail now.
    //
reapply_sign_5
    asr     r12, r1, #(5 - 2)
    rsbs    r12, r12, #(30 - 5)
    bmi     exp_saturation_5
    mov     r1, r3

    //
    // Calculate the approximating polynomial.
    // R0 Result in Q30
    // R1 X, fractional portion in Q32
    // R2 Coefficient
    // R3 Multiplication scratch space.
    //
    ldr     r2, coefficient_7_5
    umull   r3, r0, r2, r1
    ldr     r2, coefficient_6_5
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_5_5
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_4_5
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_3_5
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_2_5
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_1_5
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_0_5
    adds    r0, r0, r2

    //
    // Shift answer down per previously calculated value and round.
    // NOTE:  If r12 is zero, the carry bit will "stick" at whatever it was
    // and will not be updated by lsrs.  This can cause one count of error in
    // these cases.  The adds just above is intended to reset the carry to 0.
    // This is likely unnecessary, as it helps less than 0.5% of the time. It
    // incurs no cycle count penalty, so it stays for now.
    //
    lsrs    r0, r0, r12
    adc     r0, r0, #0

    //
    // The shift instruction ignores the upper bits.  If those bits are set,
    // set the output to 0 manually.
    //
    lsrs    r12, r12, #5
    it      ne
        movne   r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Handles the case where the result saturates.
    //
exp_saturation_5
    mvn     r0, #0x80000000
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
one_over_ln_2_1_5
    dcd     0x5c551d94
one_over_ln_2_2_5
    dcd     0xae0bf85e
coefficient_0_5
    dcd     0x3fffffff
coefficient_1_5
    dcd     0x2c5c861b
coefficient_2_5
    dcd     0x0f5fde0d
coefficient_3_5
    dcd     0x038d669b
coefficient_4_5
    dcd     0x009d817c
coefficient_5_5
    dcd     0x00160186
coefficient_6_5
    dcd     0x00025756
coefficient_7_5
    dcd     0x00005ae9

//*****************************************************************************
//
// _IQ6exp
//
//*****************************************************************************
    section CODE__IQ6exp:CODE(2)
    thumb
    export  _IQ6exp
_IQ6exp
    //
    // Take the absolute value of the input.
    //
    teq     r0, #0
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply input by 1/log(2). This transforms the problem from e^x to 2^x
    // The register set {r0,r2,r3} represents X in GQ-2 format.
    //
    ldr     r12, one_over_ln_2_2_6
    mov     r1, #0
    umull   r3, r2, r12, r0
    ldr     r12, one_over_ln_2_1_6
    umlal   r2, r1, r12, r0

    //
    // Place fractional portion of input in r1 in Q32
    //
    lsl     r3, r1, #(96 - (62 + 6))
    orr     r3, r3, r2, lsr #(6 - 2)

    //
    // Reapply the sign of the input.
    //
    bpl     reapply_sign_6

    rsbs    r3, r3, #0
    it      mi
        addmi   r1, r1, #(1 << (6 - 3))
        rsb     r1, r1, #0

    //
    // Calculate the final shift required.
    // This calculation is (integer portion of X)-(30-Q)
    // If this is negative, it will cause saturation later: bail now.
    //
reapply_sign_6
    asr     r12, r1, #(6 - 2)
    rsbs    r12, r12, #(30 - 6)
    bmi     exp_saturation_6
    mov     r1, r3

    //
    // Calculate the approximating polynomial.
    // R0 Result in Q30
    // R1 X, fractional portion in Q32
    // R2 Coefficient
    // R3 Multiplication scratch space.
    //
    ldr     r2, coefficient_7_6
    umull   r3, r0, r2, r1
    ldr     r2, coefficient_6_6
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_5_6
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_4_6
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_3_6
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_2_6
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_1_6
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_0_6
    adds    r0, r0, r2

    //
    // Shift answer down per previously calculated value and round.
    // NOTE:  If r12 is zero, the carry bit will "stick" at whatever it was
    // and will not be updated by lsrs.  This can cause one count of error in
    // these cases.  The adds just above is intended to reset the carry to 0.
    // This is likely unnecessary, as it helps less than 0.5% of the time. It
    // incurs no cycle count penalty, so it stays for now.
    //
    lsrs    r0, r0, r12
    adc     r0, r0, #0

    //
    // The shift instruction ignores the upper bits.  If those bits are set,
    // set the output to 0 manually.
    //
    lsrs    r12, r12, #5
    it      ne
        movne   r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Handles the case where the result saturates.
    //
exp_saturation_6
    mvn     r0, #0x80000000
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
one_over_ln_2_1_6
    dcd     0x5c551d94
one_over_ln_2_2_6
    dcd     0xae0bf85e
coefficient_0_6
    dcd     0x3fffffff
coefficient_1_6
    dcd     0x2c5c861b
coefficient_2_6
    dcd     0x0f5fde0d
coefficient_3_6
    dcd     0x038d669b
coefficient_4_6
    dcd     0x009d817c
coefficient_5_6
    dcd     0x00160186
coefficient_6_6
    dcd     0x00025756
coefficient_7_6
    dcd     0x00005ae9

//*****************************************************************************
//
// _IQ7exp
//
//*****************************************************************************
    section CODE__IQ7exp:CODE(2)
    thumb
    export  _IQ7exp
_IQ7exp
    //
    // Take the absolute value of the input.
    //
    teq     r0, #0
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply input by 1/log(2). This transforms the problem from e^x to 2^x
    // The register set {r0,r2,r3} represents X in GQ-2 format.
    //
    ldr     r12, one_over_ln_2_2_7
    mov     r1, #0
    umull   r3, r2, r12, r0
    ldr     r12, one_over_ln_2_1_7
    umlal   r2, r1, r12, r0

    //
    // Place fractional portion of input in r1 in Q32
    //
    lsl     r3, r1, #(96 - (62 + 7))
    orr     r3, r3, r2, lsr #(7 - 2)

    //
    // Reapply the sign of the input.
    //
    bpl     reapply_sign_7

    rsbs    r3, r3, #0
    it      mi
        addmi   r1, r1, #(1 << (7 - 3))
        rsb     r1, r1, #0

    //
    // Calculate the final shift required.
    // This calculation is (integer portion of X)-(30-Q)
    // If this is negative, it will cause saturation later: bail now.
    //
reapply_sign_7
    asr     r12, r1, #(7 - 2)
    rsbs    r12, r12, #(30 - 7)
    bmi     exp_saturation_7
    mov     r1, r3

    //
    // Calculate the approximating polynomial.
    // R0 Result in Q30
    // R1 X, fractional portion in Q32
    // R2 Coefficient
    // R3 Multiplication scratch space.
    //
    ldr     r2, coefficient_7_7
    umull   r3, r0, r2, r1
    ldr     r2, coefficient_6_7
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_5_7
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_4_7
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_3_7
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_2_7
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_1_7
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_0_7
    adds    r0, r0, r2

    //
    // Shift answer down per previously calculated value and round.
    // NOTE:  If r12 is zero, the carry bit will "stick" at whatever it was
    // and will not be updated by lsrs.  This can cause one count of error in
    // these cases.  The adds just above is intended to reset the carry to 0.
    // This is likely unnecessary, as it helps less than 0.5% of the time. It
    // incurs no cycle count penalty, so it stays for now.
    //
    lsrs    r0, r0, r12
    adc     r0, r0, #0

    //
    // The shift instruction ignores the upper bits.  If those bits are set,
    // set the output to 0 manually.
    //
    lsrs    r12, r12, #5
    it      ne
        movne   r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Handles the case where the result saturates.
    //
exp_saturation_7
    mvn     r0, #0x80000000
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
one_over_ln_2_1_7
    dcd     0x5c551d94
one_over_ln_2_2_7
    dcd     0xae0bf85e
coefficient_0_7
    dcd     0x3fffffff
coefficient_1_7
    dcd     0x2c5c861b
coefficient_2_7
    dcd     0x0f5fde0d
coefficient_3_7
    dcd     0x038d669b
coefficient_4_7
    dcd     0x009d817c
coefficient_5_7
    dcd     0x00160186
coefficient_6_7
    dcd     0x00025756
coefficient_7_7
    dcd     0x00005ae9

//*****************************************************************************
//
// _IQ8exp
//
//*****************************************************************************
    section CODE__IQ8exp:CODE(2)
    thumb
    export  _IQ8exp
_IQ8exp
    //
    // Take the absolute value of the input.
    //
    teq     r0, #0
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply input by 1/log(2). This transforms the problem from e^x to 2^x
    // The register set {r0,r2,r3} represents X in GQ-2 format.
    //
    ldr     r12, one_over_ln_2_2_8
    mov     r1, #0
    umull   r3, r2, r12, r0
    ldr     r12, one_over_ln_2_1_8
    umlal   r2, r1, r12, r0

    //
    // Place fractional portion of input in r1 in Q32
    //
    lsl     r3, r1, #(96 - (62 + 8))
    orr     r3, r3, r2, lsr #(8 - 2)

    //
    // Reapply the sign of the input.
    //
    bpl     reapply_sign_8

    rsbs    r3, r3, #0
    it      mi
        addmi   r1, r1, #(1 << (8 - 3))
        rsb     r1, r1, #0

    //
    // Calculate the final shift required.
    // This calculation is (integer portion of X)-(30-Q)
    // If this is negative, it will cause saturation later: bail now.
    //
reapply_sign_8
    asr     r12, r1, #(8 - 2)
    rsbs    r12, r12, #(30 - 8)
    bmi     exp_saturation_8
    mov     r1, r3

    //
    // Calculate the approximating polynomial.
    // R0 Result in Q30
    // R1 X, fractional portion in Q32
    // R2 Coefficient
    // R3 Multiplication scratch space.
    //
    ldr     r2, coefficient_7_8
    umull   r3, r0, r2, r1
    ldr     r2, coefficient_6_8
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_5_8
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_4_8
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_3_8
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_2_8
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_1_8
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_0_8
    adds    r0, r0, r2

    //
    // Shift answer down per previously calculated value and round.
    // NOTE:  If r12 is zero, the carry bit will "stick" at whatever it was
    // and will not be updated by lsrs.  This can cause one count of error in
    // these cases.  The adds just above is intended to reset the carry to 0.
    // This is likely unnecessary, as it helps less than 0.5% of the time. It
    // incurs no cycle count penalty, so it stays for now.
    //
    lsrs    r0, r0, r12
    adc     r0, r0, #0

    //
    // The shift instruction ignores the upper bits.  If those bits are set,
    // set the output to 0 manually.
    //
    lsrs    r12, r12, #5
    it      ne
        movne   r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Handles the case where the result saturates.
    //
exp_saturation_8
    mvn     r0, #0x80000000
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
one_over_ln_2_1_8
    dcd     0x5c551d94
one_over_ln_2_2_8
    dcd     0xae0bf85e
coefficient_0_8
    dcd     0x3fffffff
coefficient_1_8
    dcd     0x2c5c861b
coefficient_2_8
    dcd     0x0f5fde0d
coefficient_3_8
    dcd     0x038d669b
coefficient_4_8
    dcd     0x009d817c
coefficient_5_8
    dcd     0x00160186
coefficient_6_8
    dcd     0x00025756
coefficient_7_8
    dcd     0x00005ae9

//*****************************************************************************
//
// _IQ9exp
//
//*****************************************************************************
    section CODE__IQ9exp:CODE(2)
    thumb
    export  _IQ9exp
_IQ9exp
    //
    // Take the absolute value of the input.
    //
    teq     r0, #0
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply input by 1/log(2). This transforms the problem from e^x to 2^x
    // The register set {r0,r2,r3} represents X in GQ-2 format.
    //
    ldr     r12, one_over_ln_2_2_9
    mov     r1, #0
    umull   r3, r2, r12, r0
    ldr     r12, one_over_ln_2_1_9
    umlal   r2, r1, r12, r0

    //
    // Place fractional portion of input in r1 in Q32
    //
    lsl     r3, r1, #(96 - (62 + 9))
    orr     r3, r3, r2, lsr #(9 - 2)

    //
    // Reapply the sign of the input.
    //
    bpl     reapply_sign_9

    rsbs    r3, r3, #0
    it      mi
        addmi   r1, r1, #(1 << (9 - 3))
        rsb     r1, r1, #0

    //
    // Calculate the final shift required.
    // This calculation is (integer portion of X)-(30-Q)
    // If this is negative, it will cause saturation later: bail now.
    //
reapply_sign_9
    asr     r12, r1, #(9 - 2)
    rsbs    r12, r12, #(30 - 9)
    bmi     exp_saturation_9
    mov     r1, r3

    //
    // Calculate the approximating polynomial.
    // R0 Result in Q30
    // R1 X, fractional portion in Q32
    // R2 Coefficient
    // R3 Multiplication scratch space.
    //
    ldr     r2, coefficient_7_9
    umull   r3, r0, r2, r1
    ldr     r2, coefficient_6_9
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_5_9
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_4_9
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_3_9
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_2_9
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_1_9
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_0_9
    adds    r0, r0, r2

    //
    // Shift answer down per previously calculated value and round.
    // NOTE:  If r12 is zero, the carry bit will "stick" at whatever it was
    // and will not be updated by lsrs.  This can cause one count of error in
    // these cases.  The adds just above is intended to reset the carry to 0.
    // This is likely unnecessary, as it helps less than 0.5% of the time. It
    // incurs no cycle count penalty, so it stays for now.
    //
    lsrs    r0, r0, r12
    adc     r0, r0, #0

    //
    // The shift instruction ignores the upper bits.  If those bits are set,
    // set the output to 0 manually.
    //
    lsrs    r12, r12, #5
    it      ne
        movne   r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Handles the case where the result saturates.
    //
exp_saturation_9
    mvn     r0, #0x80000000
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
one_over_ln_2_1_9
    dcd     0x5c551d94
one_over_ln_2_2_9
    dcd     0xae0bf85e
coefficient_0_9
    dcd     0x3fffffff
coefficient_1_9
    dcd     0x2c5c861b
coefficient_2_9
    dcd     0x0f5fde0d
coefficient_3_9
    dcd     0x038d669b
coefficient_4_9
    dcd     0x009d817c
coefficient_5_9
    dcd     0x00160186
coefficient_6_9
    dcd     0x00025756
coefficient_7_9
    dcd     0x00005ae9

//*****************************************************************************
//
// _IQ10exp
//
//*****************************************************************************
    section CODE__IQ10exp:CODE(2)
    thumb
    export  _IQ10exp
_IQ10exp
    //
    // Take the absolute value of the input.
    //
    teq     r0, #0
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply input by 1/log(2). This transforms the problem from e^x to 2^x
    // The register set {r0,r2,r3} represents X in GQ-2 format.
    //
    ldr     r12, one_over_ln_2_2_10
    mov     r1, #0
    umull   r3, r2, r12, r0
    ldr     r12, one_over_ln_2_1_10
    umlal   r2, r1, r12, r0

    //
    // Place fractional portion of input in r1 in Q32
    //
    lsl     r3, r1, #(96 - (62 + 10))
    orr     r3, r3, r2, lsr #(10 - 2)

    //
    // Reapply the sign of the input.
    //
    bpl     reapply_sign_10

    rsbs    r3, r3, #0
    it      mi
        addmi   r1, r1, #(1 << (10 - 3))
        rsb     r1, r1, #0

    //
    // Calculate the final shift required.
    // This calculation is (integer portion of X)-(30-Q)
    // If this is negative, it will cause saturation later: bail now.
    //
reapply_sign_10
    asr     r12, r1, #(10 - 2)
    rsbs    r12, r12, #(30 - 10)
    bmi     exp_saturation_10
    mov     r1, r3

    //
    // Calculate the approximating polynomial.
    // R0 Result in Q30
    // R1 X, fractional portion in Q32
    // R2 Coefficient
    // R3 Multiplication scratch space.
    //
    ldr     r2, coefficient_7_10
    umull   r3, r0, r2, r1
    ldr     r2, coefficient_6_10
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_5_10
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_4_10
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_3_10
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_2_10
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_1_10
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_0_10
    adds    r0, r0, r2

    //
    // Shift answer down per previously calculated value and round.
    // NOTE:  If r12 is zero, the carry bit will "stick" at whatever it was
    // and will not be updated by lsrs.  This can cause one count of error in
    // these cases.  The adds just above is intended to reset the carry to 0.
    // This is likely unnecessary, as it helps less than 0.5% of the time. It
    // incurs no cycle count penalty, so it stays for now.
    //
    lsrs    r0, r0, r12
    adc     r0, r0, #0

    //
    // The shift instruction ignores the upper bits.  If those bits are set,
    // set the output to 0 manually.
    //
    lsrs    r12, r12, #5
    it      ne
        movne   r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Handles the case where the result saturates.
    //
exp_saturation_10
    mvn     r0, #0x80000000
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
one_over_ln_2_1_10
    dcd     0x5c551d94
one_over_ln_2_2_10
    dcd     0xae0bf85e
coefficient_0_10
    dcd     0x3fffffff
coefficient_1_10
    dcd     0x2c5c861b
coefficient_2_10
    dcd     0x0f5fde0d
coefficient_3_10
    dcd     0x038d669b
coefficient_4_10
    dcd     0x009d817c
coefficient_5_10
    dcd     0x00160186
coefficient_6_10
    dcd     0x00025756
coefficient_7_10
    dcd     0x00005ae9

//*****************************************************************************
//
// _IQ11exp
//
//*****************************************************************************
    section CODE__IQ11exp:CODE(2)
    thumb
    export  _IQ11exp
_IQ11exp
    //
    // Take the absolute value of the input.
    //
    teq     r0, #0
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply input by 1/log(2). This transforms the problem from e^x to 2^x
    // The register set {r0,r2,r3} represents X in GQ-2 format.
    //
    ldr     r12, one_over_ln_2_2_11
    mov     r1, #0
    umull   r3, r2, r12, r0
    ldr     r12, one_over_ln_2_1_11
    umlal   r2, r1, r12, r0

    //
    // Place fractional portion of input in r1 in Q32
    //
    lsl     r3, r1, #(96 - (62 + 11))
    orr     r3, r3, r2, lsr #(11 - 2)

    //
    // Reapply the sign of the input.
    //
    bpl     reapply_sign_11

    rsbs    r3, r3, #0
    it      mi
        addmi   r1, r1, #(1 << (11 - 3))
        rsb     r1, r1, #0

    //
    // Calculate the final shift required.
    // This calculation is (integer portion of X)-(30-Q)
    // If this is negative, it will cause saturation later: bail now.
    //
reapply_sign_11
    asr     r12, r1, #(11 - 2)
    rsbs    r12, r12, #(30 - 11)
    bmi     exp_saturation_11
    mov     r1, r3

    //
    // Calculate the approximating polynomial.
    // R0 Result in Q30
    // R1 X, fractional portion in Q32
    // R2 Coefficient
    // R3 Multiplication scratch space.
    //
    ldr     r2, coefficient_7_11
    umull   r3, r0, r2, r1
    ldr     r2, coefficient_6_11
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_5_11
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_4_11
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_3_11
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_2_11
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_1_11
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_0_11
    adds    r0, r0, r2

    //
    // Shift answer down per previously calculated value and round.
    // NOTE:  If r12 is zero, the carry bit will "stick" at whatever it was
    // and will not be updated by lsrs.  This can cause one count of error in
    // these cases.  The adds just above is intended to reset the carry to 0.
    // This is likely unnecessary, as it helps less than 0.5% of the time. It
    // incurs no cycle count penalty, so it stays for now.
    //
    lsrs    r0, r0, r12
    adc     r0, r0, #0

    //
    // The shift instruction ignores the upper bits.  If those bits are set,
    // set the output to 0 manually.
    //
    lsrs    r12, r12, #5
    it      ne
        movne   r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Handles the case where the result saturates.
    //
exp_saturation_11
    mvn     r0, #0x80000000
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
one_over_ln_2_1_11
    dcd     0x5c551d94
one_over_ln_2_2_11
    dcd     0xae0bf85e
coefficient_0_11
    dcd     0x3fffffff
coefficient_1_11
    dcd     0x2c5c861b
coefficient_2_11
    dcd     0x0f5fde0d
coefficient_3_11
    dcd     0x038d669b
coefficient_4_11
    dcd     0x009d817c
coefficient_5_11
    dcd     0x00160186
coefficient_6_11
    dcd     0x00025756
coefficient_7_11
    dcd     0x00005ae9

//*****************************************************************************
//
// _IQ12exp
//
//*****************************************************************************
    section CODE__IQ12exp:CODE(2)
    thumb
    export  _IQ12exp
_IQ12exp
    //
    // Take the absolute value of the input.
    //
    teq     r0, #0
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply input by 1/log(2). This transforms the problem from e^x to 2^x
    // The register set {r0,r2,r3} represents X in GQ-2 format.
    //
    ldr     r12, one_over_ln_2_2_12
    mov     r1, #0
    umull   r3, r2, r12, r0
    ldr     r12, one_over_ln_2_1_12
    umlal   r2, r1, r12, r0

    //
    // Place fractional portion of input in r1 in Q32
    //
    lsl     r3, r1, #(96 - (62 + 12))
    orr     r3, r3, r2, lsr #(12 - 2)

    //
    // Reapply the sign of the input.
    //
    bpl     reapply_sign_12

    rsbs    r3, r3, #0
    it      mi
        addmi   r1, r1, #(1 << (12 - 3))
        rsb     r1, r1, #0

    //
    // Calculate the final shift required.
    // This calculation is (integer portion of X)-(30-Q)
    // If this is negative, it will cause saturation later: bail now.
    //
reapply_sign_12
    asr     r12, r1, #(12 - 2)
    rsbs    r12, r12, #(30 - 12)
    bmi     exp_saturation_12
    mov     r1, r3

    //
    // Calculate the approximating polynomial.
    // R0 Result in Q30
    // R1 X, fractional portion in Q32
    // R2 Coefficient
    // R3 Multiplication scratch space.
    //
    ldr     r2, coefficient_7_12
    umull   r3, r0, r2, r1
    ldr     r2, coefficient_6_12
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_5_12
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_4_12
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_3_12
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_2_12
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_1_12
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_0_12
    adds    r0, r0, r2

    //
    // Shift answer down per previously calculated value and round.
    // NOTE:  If r12 is zero, the carry bit will "stick" at whatever it was
    // and will not be updated by lsrs.  This can cause one count of error in
    // these cases.  The adds just above is intended to reset the carry to 0.
    // This is likely unnecessary, as it helps less than 0.5% of the time. It
    // incurs no cycle count penalty, so it stays for now.
    //
    lsrs    r0, r0, r12
    adc     r0, r0, #0

    //
    // The shift instruction ignores the upper bits.  If those bits are set,
    // set the output to 0 manually.
    //
    lsrs    r12, r12, #5
    it      ne
        movne   r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Handles the case where the result saturates.
    //
exp_saturation_12
    mvn     r0, #0x80000000
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
one_over_ln_2_1_12
    dcd     0x5c551d94
one_over_ln_2_2_12
    dcd     0xae0bf85e
coefficient_0_12
    dcd     0x3fffffff
coefficient_1_12
    dcd     0x2c5c861b
coefficient_2_12
    dcd     0x0f5fde0d
coefficient_3_12
    dcd     0x038d669b
coefficient_4_12
    dcd     0x009d817c
coefficient_5_12
    dcd     0x00160186
coefficient_6_12
    dcd     0x00025756
coefficient_7_12
    dcd     0x00005ae9

//*****************************************************************************
//
// _IQ13exp
//
//*****************************************************************************
    section CODE__IQ13exp:CODE(2)
    thumb
    export  _IQ13exp
_IQ13exp
    //
    // Take the absolute value of the input.
    //
    teq     r0, #0
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply input by 1/log(2). This transforms the problem from e^x to 2^x
    // The register set {r0,r2,r3} represents X in GQ-2 format.
    //
    ldr     r12, one_over_ln_2_2_13
    mov     r1, #0
    umull   r3, r2, r12, r0
    ldr     r12, one_over_ln_2_1_13
    umlal   r2, r1, r12, r0

    //
    // Place fractional portion of input in r1 in Q32
    //
    lsl     r3, r1, #(96 - (62 + 13))
    orr     r3, r3, r2, lsr #(13 - 2)

    //
    // Reapply the sign of the input.
    //
    bpl     reapply_sign_13

    rsbs    r3, r3, #0
    it      mi
        addmi   r1, r1, #(1 << (13 - 3))
        rsb     r1, r1, #0

    //
    // Calculate the final shift required.
    // This calculation is (integer portion of X)-(30-Q)
    // If this is negative, it will cause saturation later: bail now.
    //
reapply_sign_13
    asr     r12, r1, #(13 - 2)
    rsbs    r12, r12, #(30 - 13)
    bmi     exp_saturation_13
    mov     r1, r3

    //
    // Calculate the approximating polynomial.
    // R0 Result in Q30
    // R1 X, fractional portion in Q32
    // R2 Coefficient
    // R3 Multiplication scratch space.
    //
    ldr     r2, coefficient_7_13
    umull   r3, r0, r2, r1
    ldr     r2, coefficient_6_13
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_5_13
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_4_13
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_3_13
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_2_13
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_1_13
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_0_13
    adds    r0, r0, r2

    //
    // Shift answer down per previously calculated value and round.
    // NOTE:  If r12 is zero, the carry bit will "stick" at whatever it was
    // and will not be updated by lsrs.  This can cause one count of error in
    // these cases.  The adds just above is intended to reset the carry to 0.
    // This is likely unnecessary, as it helps less than 0.5% of the time. It
    // incurs no cycle count penalty, so it stays for now.
    //
    lsrs    r0, r0, r12
    adc     r0, r0, #0

    //
    // The shift instruction ignores the upper bits.  If those bits are set,
    // set the output to 0 manually.
    //
    lsrs    r12, r12, #5
    it      ne
        movne   r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Handles the case where the result saturates.
    //
exp_saturation_13
    mvn     r0, #0x80000000
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
one_over_ln_2_1_13
    dcd     0x5c551d94
one_over_ln_2_2_13
    dcd     0xae0bf85e
coefficient_0_13
    dcd     0x3fffffff
coefficient_1_13
    dcd     0x2c5c861b
coefficient_2_13
    dcd     0x0f5fde0d
coefficient_3_13
    dcd     0x038d669b
coefficient_4_13
    dcd     0x009d817c
coefficient_5_13
    dcd     0x00160186
coefficient_6_13
    dcd     0x00025756
coefficient_7_13
    dcd     0x00005ae9

//*****************************************************************************
//
// _IQ14exp
//
//*****************************************************************************
    section CODE__IQ14exp:CODE(2)
    thumb
    export  _IQ14exp
_IQ14exp
    //
    // Take the absolute value of the input.
    //
    teq     r0, #0
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply input by 1/log(2). This transforms the problem from e^x to 2^x
    // The register set {r0,r2,r3} represents X in GQ-2 format.
    //
    ldr     r12, one_over_ln_2_2_14
    mov     r1, #0
    umull   r3, r2, r12, r0
    ldr     r12, one_over_ln_2_1_14
    umlal   r2, r1, r12, r0

    //
    // Place fractional portion of input in r1 in Q32
    //
    lsl     r3, r1, #(96 - (62 + 14))
    orr     r3, r3, r2, lsr #(14 - 2)

    //
    // Reapply the sign of the input.
    //
    bpl     reapply_sign_14

    rsbs    r3, r3, #0
    it      mi
        addmi   r1, r1, #(1 << (14 - 3))
        rsb     r1, r1, #0

    //
    // Calculate the final shift required.
    // This calculation is (integer portion of X)-(30-Q)
    // If this is negative, it will cause saturation later: bail now.
    //
reapply_sign_14
    asr     r12, r1, #(14 - 2)
    rsbs    r12, r12, #(30 - 14)
    bmi     exp_saturation_14
    mov     r1, r3

    //
    // Calculate the approximating polynomial.
    // R0 Result in Q30
    // R1 X, fractional portion in Q32
    // R2 Coefficient
    // R3 Multiplication scratch space.
    //
    ldr     r2, coefficient_7_14
    umull   r3, r0, r2, r1
    ldr     r2, coefficient_6_14
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_5_14
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_4_14
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_3_14
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_2_14
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_1_14
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_0_14
    adds    r0, r0, r2

    //
    // Shift answer down per previously calculated value and round.
    // NOTE:  If r12 is zero, the carry bit will "stick" at whatever it was
    // and will not be updated by lsrs.  This can cause one count of error in
    // these cases.  The adds just above is intended to reset the carry to 0.
    // This is likely unnecessary, as it helps less than 0.5% of the time. It
    // incurs no cycle count penalty, so it stays for now.
    //
    lsrs    r0, r0, r12
    adc     r0, r0, #0

    //
    // The shift instruction ignores the upper bits.  If those bits are set,
    // set the output to 0 manually.
    //
    lsrs    r12, r12, #5
    it      ne
        movne   r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Handles the case where the result saturates.
    //
exp_saturation_14
    mvn     r0, #0x80000000
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
one_over_ln_2_1_14
    dcd     0x5c551d94
one_over_ln_2_2_14
    dcd     0xae0bf85e
coefficient_0_14
    dcd     0x3fffffff
coefficient_1_14
    dcd     0x2c5c861b
coefficient_2_14
    dcd     0x0f5fde0d
coefficient_3_14
    dcd     0x038d669b
coefficient_4_14
    dcd     0x009d817c
coefficient_5_14
    dcd     0x00160186
coefficient_6_14
    dcd     0x00025756
coefficient_7_14
    dcd     0x00005ae9

//*****************************************************************************
//
// _IQ15exp
//
//*****************************************************************************
    section CODE__IQ15exp:CODE(2)
    thumb
    export  _IQ15exp
_IQ15exp
    //
    // Take the absolute value of the input.
    //
    teq     r0, #0
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply input by 1/log(2). This transforms the problem from e^x to 2^x
    // The register set {r0,r2,r3} represents X in GQ-2 format.
    //
    ldr     r12, one_over_ln_2_2_15
    mov     r1, #0
    umull   r3, r2, r12, r0
    ldr     r12, one_over_ln_2_1_15
    umlal   r2, r1, r12, r0

    //
    // Place fractional portion of input in r1 in Q32
    //
    lsl     r3, r1, #(96 - (62 + 15))
    orr     r3, r3, r2, lsr #(15 - 2)

    //
    // Reapply the sign of the input.
    //
    bpl     reapply_sign_15

    rsbs    r3, r3, #0
    it      mi
        addmi   r1, r1, #(1 << (15 - 3))
        rsb     r1, r1, #0

    //
    // Calculate the final shift required.
    // This calculation is (integer portion of X)-(30-Q)
    // If this is negative, it will cause saturation later: bail now.
    //
reapply_sign_15
    asr     r12, r1, #(15 - 2)
    rsbs    r12, r12, #(30 - 15)
    bmi     exp_saturation_15
    mov     r1, r3

    //
    // Calculate the approximating polynomial.
    // R0 Result in Q30
    // R1 X, fractional portion in Q32
    // R2 Coefficient
    // R3 Multiplication scratch space.
    //
    ldr     r2, coefficient_7_15
    umull   r3, r0, r2, r1
    ldr     r2, coefficient_6_15
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_5_15
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_4_15
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_3_15
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_2_15
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_1_15
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_0_15
    adds    r0, r0, r2

    //
    // Shift answer down per previously calculated value and round.
    // NOTE:  If r12 is zero, the carry bit will "stick" at whatever it was
    // and will not be updated by lsrs.  This can cause one count of error in
    // these cases.  The adds just above is intended to reset the carry to 0.
    // This is likely unnecessary, as it helps less than 0.5% of the time. It
    // incurs no cycle count penalty, so it stays for now.
    //
    lsrs    r0, r0, r12
    adc     r0, r0, #0

    //
    // The shift instruction ignores the upper bits.  If those bits are set,
    // set the output to 0 manually.
    //
    lsrs    r12, r12, #5
    it      ne
        movne   r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Handles the case where the result saturates.
    //
exp_saturation_15
    mvn     r0, #0x80000000
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
one_over_ln_2_1_15
    dcd     0x5c551d94
one_over_ln_2_2_15
    dcd     0xae0bf85e
coefficient_0_15
    dcd     0x3fffffff
coefficient_1_15
    dcd     0x2c5c861b
coefficient_2_15
    dcd     0x0f5fde0d
coefficient_3_15
    dcd     0x038d669b
coefficient_4_15
    dcd     0x009d817c
coefficient_5_15
    dcd     0x00160186
coefficient_6_15
    dcd     0x00025756
coefficient_7_15
    dcd     0x00005ae9

//*****************************************************************************
//
// _IQ16exp
//
//*****************************************************************************
    section CODE__IQ16exp:CODE(2)
    thumb
    export  _IQ16exp
_IQ16exp
    //
    // Take the absolute value of the input.
    //
    teq     r0, #0
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply input by 1/log(2). This transforms the problem from e^x to 2^x
    // The register set {r0,r2,r3} represents X in GQ-2 format.
    //
    ldr     r12, one_over_ln_2_2_16
    mov     r1, #0
    umull   r3, r2, r12, r0
    ldr     r12, one_over_ln_2_1_16
    umlal   r2, r1, r12, r0

    //
    // Place fractional portion of input in r1 in Q32
    //
    lsl     r3, r1, #(96 - (62 + 16))
    orr     r3, r3, r2, lsr #(16 - 2)

    //
    // Reapply the sign of the input.
    //
    bpl     reapply_sign_16

    rsbs    r3, r3, #0
    it      mi
        addmi   r1, r1, #(1 << (16 - 3))
        rsb     r1, r1, #0

    //
    // Calculate the final shift required.
    // This calculation is (integer portion of X)-(30-Q)
    // If this is negative, it will cause saturation later: bail now.
    //
reapply_sign_16
    asr     r12, r1, #(16 - 2)
    rsbs    r12, r12, #(30 - 16)
    bmi     exp_saturation_16
    mov     r1, r3

    //
    // Calculate the approximating polynomial.
    // R0 Result in Q30
    // R1 X, fractional portion in Q32
    // R2 Coefficient
    // R3 Multiplication scratch space.
    //
    ldr     r2, coefficient_7_16
    umull   r3, r0, r2, r1
    ldr     r2, coefficient_6_16
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_5_16
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_4_16
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_3_16
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_2_16
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_1_16
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_0_16
    adds    r0, r0, r2

    //
    // Shift answer down per previously calculated value and round.
    // NOTE:  If r12 is zero, the carry bit will "stick" at whatever it was
    // and will not be updated by lsrs.  This can cause one count of error in
    // these cases.  The adds just above is intended to reset the carry to 0.
    // This is likely unnecessary, as it helps less than 0.5% of the time. It
    // incurs no cycle count penalty, so it stays for now.
    //
    lsrs    r0, r0, r12
    adc     r0, r0, #0

    //
    // The shift instruction ignores the upper bits.  If those bits are set,
    // set the output to 0 manually.
    //
    lsrs    r12, r12, #5
    it      ne
        movne   r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Handles the case where the result saturates.
    //
exp_saturation_16
    mvn     r0, #0x80000000
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
one_over_ln_2_1_16
    dcd     0x5c551d94
one_over_ln_2_2_16
    dcd     0xae0bf85e
coefficient_0_16
    dcd     0x3fffffff
coefficient_1_16
    dcd     0x2c5c861b
coefficient_2_16
    dcd     0x0f5fde0d
coefficient_3_16
    dcd     0x038d669b
coefficient_4_16
    dcd     0x009d817c
coefficient_5_16
    dcd     0x00160186
coefficient_6_16
    dcd     0x00025756
coefficient_7_16
    dcd     0x00005ae9

//*****************************************************************************
//
// _IQ17exp
//
//*****************************************************************************
    section CODE__IQ17exp:CODE(2)
    thumb
    export  _IQ17exp
_IQ17exp
    //
    // Take the absolute value of the input.
    //
    teq     r0, #0
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply input by 1/log(2). This transforms the problem from e^x to 2^x
    // The register set {r0,r2,r3} represents X in GQ-2 format.
    //
    ldr     r12, one_over_ln_2_2_17
    mov     r1, #0
    umull   r3, r2, r12, r0
    ldr     r12, one_over_ln_2_1_17
    umlal   r2, r1, r12, r0

    //
    // Place fractional portion of input in r1 in Q32
    //
    lsl     r3, r1, #(96 - (62 + 17))
    orr     r3, r3, r2, lsr #(17 - 2)

    //
    // Reapply the sign of the input.
    //
    bpl     reapply_sign_17

    rsbs    r3, r3, #0
    it      mi
        addmi   r1, r1, #(1 << (17 - 3))
        rsb     r1, r1, #0

    //
    // Calculate the final shift required.
    // This calculation is (integer portion of X)-(30-Q)
    // If this is negative, it will cause saturation later: bail now.
    //
reapply_sign_17
    asr     r12, r1, #(17 - 2)
    rsbs    r12, r12, #(30 - 17)
    bmi     exp_saturation_17
    mov     r1, r3

    //
    // Calculate the approximating polynomial.
    // R0 Result in Q30
    // R1 X, fractional portion in Q32
    // R2 Coefficient
    // R3 Multiplication scratch space.
    //
    ldr     r2, coefficient_7_17
    umull   r3, r0, r2, r1
    ldr     r2, coefficient_6_17
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_5_17
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_4_17
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_3_17
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_2_17
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_1_17
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_0_17
    adds    r0, r0, r2

    //
    // Shift answer down per previously calculated value and round.
    // NOTE:  If r12 is zero, the carry bit will "stick" at whatever it was
    // and will not be updated by lsrs.  This can cause one count of error in
    // these cases.  The adds just above is intended to reset the carry to 0.
    // This is likely unnecessary, as it helps less than 0.5% of the time. It
    // incurs no cycle count penalty, so it stays for now.
    //
    lsrs    r0, r0, r12
    adc     r0, r0, #0

    //
    // The shift instruction ignores the upper bits.  If those bits are set,
    // set the output to 0 manually.
    //
    lsrs    r12, r12, #5
    it      ne
        movne   r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Handles the case where the result saturates.
    //
exp_saturation_17
    mvn     r0, #0x80000000
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
one_over_ln_2_1_17
    dcd     0x5c551d94
one_over_ln_2_2_17
    dcd     0xae0bf85e
coefficient_0_17
    dcd     0x3fffffff
coefficient_1_17
    dcd     0x2c5c861b
coefficient_2_17
    dcd     0x0f5fde0d
coefficient_3_17
    dcd     0x038d669b
coefficient_4_17
    dcd     0x009d817c
coefficient_5_17
    dcd     0x00160186
coefficient_6_17
    dcd     0x00025756
coefficient_7_17
    dcd     0x00005ae9

//*****************************************************************************
//
// _IQ18exp
//
//*****************************************************************************
    section CODE__IQ18exp:CODE(2)
    thumb
    export  _IQ18exp
_IQ18exp
    //
    // Take the absolute value of the input.
    //
    teq     r0, #0
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply input by 1/log(2). This transforms the problem from e^x to 2^x
    // The register set {r0,r2,r3} represents X in GQ-2 format.
    //
    ldr     r12, one_over_ln_2_2_18
    mov     r1, #0
    umull   r3, r2, r12, r0
    ldr     r12, one_over_ln_2_1_18
    umlal   r2, r1, r12, r0

    //
    // Place fractional portion of input in r1 in Q32
    //
    lsl     r3, r1, #(96 - (62 + 18))
    orr     r3, r3, r2, lsr #(18 - 2)

    //
    // Reapply the sign of the input.
    //
    bpl     reapply_sign_18

    rsbs    r3, r3, #0
    it      mi
        addmi   r1, r1, #(1 << (18 - 3))
        rsb     r1, r1, #0

    //
    // Calculate the final shift required.
    // This calculation is (integer portion of X)-(30-Q)
    // If this is negative, it will cause saturation later: bail now.
    //
reapply_sign_18
    asr     r12, r1, #(18 - 2)
    rsbs    r12, r12, #(30 - 18)
    bmi     exp_saturation_18
    mov     r1, r3

    //
    // Calculate the approximating polynomial.
    // R0 Result in Q30
    // R1 X, fractional portion in Q32
    // R2 Coefficient
    // R3 Multiplication scratch space.
    //
    ldr     r2, coefficient_7_18
    umull   r3, r0, r2, r1
    ldr     r2, coefficient_6_18
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_5_18
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_4_18
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_3_18
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_2_18
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_1_18
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_0_18
    adds    r0, r0, r2

    //
    // Shift answer down per previously calculated value and round.
    // NOTE:  If r12 is zero, the carry bit will "stick" at whatever it was
    // and will not be updated by lsrs.  This can cause one count of error in
    // these cases.  The adds just above is intended to reset the carry to 0.
    // This is likely unnecessary, as it helps less than 0.5% of the time. It
    // incurs no cycle count penalty, so it stays for now.
    //
    lsrs    r0, r0, r12
    adc     r0, r0, #0

    //
    // The shift instruction ignores the upper bits.  If those bits are set,
    // set the output to 0 manually.
    //
    lsrs    r12, r12, #5
    it      ne
        movne   r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Handles the case where the result saturates.
    //
exp_saturation_18
    mvn     r0, #0x80000000
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
one_over_ln_2_1_18
    dcd     0x5c551d94
one_over_ln_2_2_18
    dcd     0xae0bf85e
coefficient_0_18
    dcd     0x3fffffff
coefficient_1_18
    dcd     0x2c5c861b
coefficient_2_18
    dcd     0x0f5fde0d
coefficient_3_18
    dcd     0x038d669b
coefficient_4_18
    dcd     0x009d817c
coefficient_5_18
    dcd     0x00160186
coefficient_6_18
    dcd     0x00025756
coefficient_7_18
    dcd     0x00005ae9

//*****************************************************************************
//
// _IQ19exp
//
//*****************************************************************************
    section CODE__IQ19exp:CODE(2)
    thumb
    export  _IQ19exp
_IQ19exp
    //
    // Take the absolute value of the input.
    //
    teq     r0, #0
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply input by 1/log(2). This transforms the problem from e^x to 2^x
    // The register set {r0,r2,r3} represents X in GQ-2 format.
    //
    ldr     r12, one_over_ln_2_2_19
    mov     r1, #0
    umull   r3, r2, r12, r0
    ldr     r12, one_over_ln_2_1_19
    umlal   r2, r1, r12, r0

    //
    // Place fractional portion of input in r1 in Q32
    //
    lsl     r3, r1, #(96 - (62 + 19))
    orr     r3, r3, r2, lsr #(19 - 2)

    //
    // Reapply the sign of the input.
    //
    bpl     reapply_sign_19

    rsbs    r3, r3, #0
    it      mi
        addmi   r1, r1, #(1 << (19 - 3))
        rsb     r1, r1, #0

    //
    // Calculate the final shift required.
    // This calculation is (integer portion of X)-(30-Q)
    // If this is negative, it will cause saturation later: bail now.
    //
reapply_sign_19
    asr     r12, r1, #(19 - 2)
    rsbs    r12, r12, #(30 - 19)
    bmi     exp_saturation_19
    mov     r1, r3

    //
    // Calculate the approximating polynomial.
    // R0 Result in Q30
    // R1 X, fractional portion in Q32
    // R2 Coefficient
    // R3 Multiplication scratch space.
    //
    ldr     r2, coefficient_7_19
    umull   r3, r0, r2, r1
    ldr     r2, coefficient_6_19
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_5_19
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_4_19
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_3_19
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_2_19
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_1_19
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_0_19
    adds    r0, r0, r2

    //
    // Shift answer down per previously calculated value and round.
    // NOTE:  If r12 is zero, the carry bit will "stick" at whatever it was
    // and will not be updated by lsrs.  This can cause one count of error in
    // these cases.  The adds just above is intended to reset the carry to 0.
    // This is likely unnecessary, as it helps less than 0.5% of the time. It
    // incurs no cycle count penalty, so it stays for now.
    //
    lsrs    r0, r0, r12
    adc     r0, r0, #0

    //
    // The shift instruction ignores the upper bits.  If those bits are set,
    // set the output to 0 manually.
    //
    lsrs    r12, r12, #5
    it      ne
        movne   r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Handles the case where the result saturates.
    //
exp_saturation_19
    mvn     r0, #0x80000000
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
one_over_ln_2_1_19
    dcd     0x5c551d94
one_over_ln_2_2_19
    dcd     0xae0bf85e
coefficient_0_19
    dcd     0x3fffffff
coefficient_1_19
    dcd     0x2c5c861b
coefficient_2_19
    dcd     0x0f5fde0d
coefficient_3_19
    dcd     0x038d669b
coefficient_4_19
    dcd     0x009d817c
coefficient_5_19
    dcd     0x00160186
coefficient_6_19
    dcd     0x00025756
coefficient_7_19
    dcd     0x00005ae9

//*****************************************************************************
//
// _IQ20exp
//
//*****************************************************************************
    section CODE__IQ20exp:CODE(2)
    thumb
    export  _IQ20exp
_IQ20exp
    //
    // Take the absolute value of the input.
    //
    teq     r0, #0
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply input by 1/log(2). This transforms the problem from e^x to 2^x
    // The register set {r0,r2,r3} represents X in GQ-2 format.
    //
    ldr     r12, one_over_ln_2_2_20
    mov     r1, #0
    umull   r3, r2, r12, r0
    ldr     r12, one_over_ln_2_1_20
    umlal   r2, r1, r12, r0

    //
    // Place fractional portion of input in r1 in Q32
    //
    lsl     r3, r1, #(96 - (62 + 20))
    orr     r3, r3, r2, lsr #(20 - 2)

    //
    // Reapply the sign of the input.
    //
    bpl     reapply_sign_20

    rsbs    r3, r3, #0
    it      mi
        addmi   r1, r1, #(1 << (20 - 3))
        rsb     r1, r1, #0

    //
    // Calculate the final shift required.
    // This calculation is (integer portion of X)-(30-Q)
    // If this is negative, it will cause saturation later: bail now.
    //
reapply_sign_20
    asr     r12, r1, #(20 - 2)
    rsbs    r12, r12, #(30 - 20)
    bmi     exp_saturation_20
    mov     r1, r3

    //
    // Calculate the approximating polynomial.
    // R0 Result in Q30
    // R1 X, fractional portion in Q32
    // R2 Coefficient
    // R3 Multiplication scratch space.
    //
    ldr     r2, coefficient_7_20
    umull   r3, r0, r2, r1
    ldr     r2, coefficient_6_20
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_5_20
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_4_20
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_3_20
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_2_20
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_1_20
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_0_20
    adds    r0, r0, r2

    //
    // Shift answer down per previously calculated value and round.
    // NOTE:  If r12 is zero, the carry bit will "stick" at whatever it was
    // and will not be updated by lsrs.  This can cause one count of error in
    // these cases.  The adds just above is intended to reset the carry to 0.
    // This is likely unnecessary, as it helps less than 0.5% of the time. It
    // incurs no cycle count penalty, so it stays for now.
    //
    lsrs    r0, r0, r12
    adc     r0, r0, #0

    //
    // The shift instruction ignores the upper bits.  If those bits are set,
    // set the output to 0 manually.
    //
    lsrs    r12, r12, #5
    it      ne
        movne   r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Handles the case where the result saturates.
    //
exp_saturation_20
    mvn     r0, #0x80000000
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
one_over_ln_2_1_20
    dcd     0x5c551d94
one_over_ln_2_2_20
    dcd     0xae0bf85e
coefficient_0_20
    dcd     0x3fffffff
coefficient_1_20
    dcd     0x2c5c861b
coefficient_2_20
    dcd     0x0f5fde0d
coefficient_3_20
    dcd     0x038d669b
coefficient_4_20
    dcd     0x009d817c
coefficient_5_20
    dcd     0x00160186
coefficient_6_20
    dcd     0x00025756
coefficient_7_20
    dcd     0x00005ae9

//*****************************************************************************
//
// _IQ21exp
//
//*****************************************************************************
    section CODE__IQ21exp:CODE(2)
    thumb
    export  _IQ21exp
_IQ21exp
    //
    // Take the absolute value of the input.
    //
    teq     r0, #0
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply input by 1/log(2). This transforms the problem from e^x to 2^x
    // The register set {r0,r2,r3} represents X in GQ-2 format.
    //
    ldr     r12, one_over_ln_2_2_21
    mov     r1, #0
    umull   r3, r2, r12, r0
    ldr     r12, one_over_ln_2_1_21
    umlal   r2, r1, r12, r0

    //
    // Place fractional portion of input in r1 in Q32
    //
    lsl     r3, r1, #(96 - (62 + 21))
    orr     r3, r3, r2, lsr #(21 - 2)

    //
    // Reapply the sign of the input.
    //
    bpl     reapply_sign_21

    rsbs    r3, r3, #0
    it      mi
        addmi   r1, r1, #(1 << (21 - 3))
        rsb     r1, r1, #0

    //
    // Calculate the final shift required.
    // This calculation is (integer portion of X)-(30-Q)
    // If this is negative, it will cause saturation later: bail now.
    //
reapply_sign_21
    asr     r12, r1, #(21 - 2)
    rsbs    r12, r12, #(30 - 21)
    bmi     exp_saturation_21
    mov     r1, r3

    //
    // Calculate the approximating polynomial.
    // R0 Result in Q30
    // R1 X, fractional portion in Q32
    // R2 Coefficient
    // R3 Multiplication scratch space.
    //
    ldr     r2, coefficient_7_21
    umull   r3, r0, r2, r1
    ldr     r2, coefficient_6_21
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_5_21
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_4_21
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_3_21
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_2_21
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_1_21
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_0_21
    adds    r0, r0, r2

    //
    // Shift answer down per previously calculated value and round.
    // NOTE:  If r12 is zero, the carry bit will "stick" at whatever it was
    // and will not be updated by lsrs.  This can cause one count of error in
    // these cases.  The adds just above is intended to reset the carry to 0.
    // This is likely unnecessary, as it helps less than 0.5% of the time. It
    // incurs no cycle count penalty, so it stays for now.
    //
    lsrs    r0, r0, r12
    adc     r0, r0, #0

    //
    // The shift instruction ignores the upper bits.  If those bits are set,
    // set the output to 0 manually.
    //
    lsrs    r12, r12, #5
    it      ne
        movne   r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Handles the case where the result saturates.
    //
exp_saturation_21
    mvn     r0, #0x80000000
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
one_over_ln_2_1_21
    dcd     0x5c551d94
one_over_ln_2_2_21
    dcd     0xae0bf85e
coefficient_0_21
    dcd     0x3fffffff
coefficient_1_21
    dcd     0x2c5c861b
coefficient_2_21
    dcd     0x0f5fde0d
coefficient_3_21
    dcd     0x038d669b
coefficient_4_21
    dcd     0x009d817c
coefficient_5_21
    dcd     0x00160186
coefficient_6_21
    dcd     0x00025756
coefficient_7_21
    dcd     0x00005ae9

//*****************************************************************************
//
// _IQ22exp
//
//*****************************************************************************
    section CODE__IQ22exp:CODE(2)
    thumb
    export  _IQ22exp
_IQ22exp
    //
    // Take the absolute value of the input.
    //
    teq     r0, #0
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply input by 1/log(2). This transforms the problem from e^x to 2^x
    // The register set {r0,r2,r3} represents X in GQ-2 format.
    //
    ldr     r12, one_over_ln_2_2_22
    mov     r1, #0
    umull   r3, r2, r12, r0
    ldr     r12, one_over_ln_2_1_22
    umlal   r2, r1, r12, r0

    //
    // Place fractional portion of input in r1 in Q32
    //
    lsl     r3, r1, #(96 - (62 + 22))
    orr     r3, r3, r2, lsr #(22 - 2)

    //
    // Reapply the sign of the input.
    //
    bpl     reapply_sign_22

    rsbs    r3, r3, #0
    it      mi
        addmi   r1, r1, #(1 << (22 - 3))
        rsb     r1, r1, #0

    //
    // Calculate the final shift required.
    // This calculation is (integer portion of X)-(30-Q)
    // If this is negative, it will cause saturation later: bail now.
    //
reapply_sign_22
    asr     r12, r1, #(22 - 2)
    rsbs    r12, r12, #(30 - 22)
    bmi     exp_saturation_22
    mov     r1, r3

    //
    // Calculate the approximating polynomial.
    // R0 Result in Q30
    // R1 X, fractional portion in Q32
    // R2 Coefficient
    // R3 Multiplication scratch space.
    //
    ldr     r2, coefficient_7_22
    umull   r3, r0, r2, r1
    ldr     r2, coefficient_6_22
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_5_22
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_4_22
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_3_22
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_2_22
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_1_22
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_0_22
    adds    r0, r0, r2

    //
    // Shift answer down per previously calculated value and round.
    // NOTE:  If r12 is zero, the carry bit will "stick" at whatever it was
    // and will not be updated by lsrs.  This can cause one count of error in
    // these cases.  The adds just above is intended to reset the carry to 0.
    // This is likely unnecessary, as it helps less than 0.5% of the time. It
    // incurs no cycle count penalty, so it stays for now.
    //
    lsrs    r0, r0, r12
    adc     r0, r0, #0

    //
    // The shift instruction ignores the upper bits.  If those bits are set,
    // set the output to 0 manually.
    //
    lsrs    r12, r12, #5
    it      ne
        movne   r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Handles the case where the result saturates.
    //
exp_saturation_22
    mvn     r0, #0x80000000
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
one_over_ln_2_1_22
    dcd     0x5c551d94
one_over_ln_2_2_22
    dcd     0xae0bf85e
coefficient_0_22
    dcd     0x3fffffff
coefficient_1_22
    dcd     0x2c5c861b
coefficient_2_22
    dcd     0x0f5fde0d
coefficient_3_22
    dcd     0x038d669b
coefficient_4_22
    dcd     0x009d817c
coefficient_5_22
    dcd     0x00160186
coefficient_6_22
    dcd     0x00025756
coefficient_7_22
    dcd     0x00005ae9

//*****************************************************************************
//
// _IQ23exp
//
//*****************************************************************************
    section CODE__IQ23exp:CODE(2)
    thumb
    export  _IQ23exp
_IQ23exp
    //
    // Take the absolute value of the input.
    //
    teq     r0, #0
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply input by 1/log(2). This transforms the problem from e^x to 2^x
    // The register set {r0,r2,r3} represents X in GQ-2 format.
    //
    ldr     r12, one_over_ln_2_2_23
    mov     r1, #0
    umull   r3, r2, r12, r0
    ldr     r12, one_over_ln_2_1_23
    umlal   r2, r1, r12, r0

    //
    // Place fractional portion of input in r1 in Q32
    //
    lsl     r3, r1, #(96 - (62 + 23))
    orr     r3, r3, r2, lsr #(23 - 2)

    //
    // Reapply the sign of the input.
    //
    bpl     reapply_sign_23

    rsbs    r3, r3, #0
    it      mi
        addmi   r1, r1, #(1 << (23 - 3))
        rsb     r1, r1, #0

    //
    // Calculate the final shift required.
    // This calculation is (integer portion of X)-(30-Q)
    // If this is negative, it will cause saturation later: bail now.
    //
reapply_sign_23
    asr     r12, r1, #(23 - 2)
    rsbs    r12, r12, #(30 - 23)
    bmi     exp_saturation_23
    mov     r1, r3

    //
    // Calculate the approximating polynomial.
    // R0 Result in Q30
    // R1 X, fractional portion in Q32
    // R2 Coefficient
    // R3 Multiplication scratch space.
    //
    ldr     r2, coefficient_7_23
    umull   r3, r0, r2, r1
    ldr     r2, coefficient_6_23
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_5_23
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_4_23
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_3_23
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_2_23
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_1_23
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_0_23
    adds    r0, r0, r2

    //
    // Shift answer down per previously calculated value and round.
    // NOTE:  If r12 is zero, the carry bit will "stick" at whatever it was
    // and will not be updated by lsrs.  This can cause one count of error in
    // these cases.  The adds just above is intended to reset the carry to 0.
    // This is likely unnecessary, as it helps less than 0.5% of the time. It
    // incurs no cycle count penalty, so it stays for now.
    //
    lsrs    r0, r0, r12
    adc     r0, r0, #0

    //
    // The shift instruction ignores the upper bits.  If those bits are set,
    // set the output to 0 manually.
    //
    lsrs    r12, r12, #5
    it      ne
        movne   r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Handles the case where the result saturates.
    //
exp_saturation_23
    mvn     r0, #0x80000000
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
one_over_ln_2_1_23
    dcd     0x5c551d94
one_over_ln_2_2_23
    dcd     0xae0bf85e
coefficient_0_23
    dcd     0x3fffffff
coefficient_1_23
    dcd     0x2c5c861b
coefficient_2_23
    dcd     0x0f5fde0d
coefficient_3_23
    dcd     0x038d669b
coefficient_4_23
    dcd     0x009d817c
coefficient_5_23
    dcd     0x00160186
coefficient_6_23
    dcd     0x00025756
coefficient_7_23
    dcd     0x00005ae9

//*****************************************************************************
//
// _IQ24exp
//
//*****************************************************************************
    section CODE__IQ24exp:CODE(2)
    thumb
    export  _IQ24exp
_IQ24exp
    //
    // Take the absolute value of the input.
    //
    teq     r0, #0
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply input by 1/log(2). This transforms the problem from e^x to 2^x
    // The register set {r0,r2,r3} represents X in GQ-2 format.
    //
    ldr     r12, one_over_ln_2_2_24
    mov     r1, #0
    umull   r3, r2, r12, r0
    ldr     r12, one_over_ln_2_1_24
    umlal   r2, r1, r12, r0

    //
    // Place fractional portion of input in r1 in Q32
    //
    lsl     r3, r1, #(96 - (62 + 24))
    orr     r3, r3, r2, lsr #(24 - 2)

    //
    // Reapply the sign of the input.
    //
    bpl     reapply_sign_24

    rsbs    r3, r3, #0
    it      mi
        addmi   r1, r1, #(1 << (24 - 3))
        rsb     r1, r1, #0

    //
    // Calculate the final shift required.
    // This calculation is (integer portion of X)-(30-Q)
    // If this is negative, it will cause saturation later: bail now.
    //
reapply_sign_24
    asr     r12, r1, #(24 - 2)
    rsbs    r12, r12, #(30 - 24)
    bmi     exp_saturation_24
    mov     r1, r3

    //
    // Calculate the approximating polynomial.
    // R0 Result in Q30
    // R1 X, fractional portion in Q32
    // R2 Coefficient
    // R3 Multiplication scratch space.
    //
    ldr     r2, coefficient_7_24
    umull   r3, r0, r2, r1
    ldr     r2, coefficient_6_24
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_5_24
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_4_24
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_3_24
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_2_24
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_1_24
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_0_24
    adds    r0, r0, r2

    //
    // Shift answer down per previously calculated value and round.
    // NOTE:  If r12 is zero, the carry bit will "stick" at whatever it was
    // and will not be updated by lsrs.  This can cause one count of error in
    // these cases.  The adds just above is intended to reset the carry to 0.
    // This is likely unnecessary, as it helps less than 0.5% of the time. It
    // incurs no cycle count penalty, so it stays for now.
    //
    lsrs    r0, r0, r12
    adc     r0, r0, #0

    //
    // The shift instruction ignores the upper bits.  If those bits are set,
    // set the output to 0 manually.
    //
    lsrs    r12, r12, #5
    it      ne
        movne   r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Handles the case where the result saturates.
    //
exp_saturation_24
    mvn     r0, #0x80000000
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
one_over_ln_2_1_24
    dcd     0x5c551d94
one_over_ln_2_2_24
    dcd     0xae0bf85e
coefficient_0_24
    dcd     0x3fffffff
coefficient_1_24
    dcd     0x2c5c861b
coefficient_2_24
    dcd     0x0f5fde0d
coefficient_3_24
    dcd     0x038d669b
coefficient_4_24
    dcd     0x009d817c
coefficient_5_24
    dcd     0x00160186
coefficient_6_24
    dcd     0x00025756
coefficient_7_24
    dcd     0x00005ae9

//*****************************************************************************
//
// _IQ25exp
//
//*****************************************************************************
    section CODE__IQ25exp:CODE(2)
    thumb
    export  _IQ25exp
_IQ25exp
    //
    // Take the absolute value of the input.
    //
    teq     r0, #0
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply input by 1/log(2). This transforms the problem from e^x to 2^x
    // The register set {r0,r2,r3} represents X in GQ-2 format.
    //
    ldr     r12, one_over_ln_2_2_25
    mov     r1, #0
    umull   r3, r2, r12, r0
    ldr     r12, one_over_ln_2_1_25
    umlal   r2, r1, r12, r0

    //
    // Place fractional portion of input in r1 in Q32
    //
    lsl     r3, r1, #(96 - (62 + 25))
    orr     r3, r3, r2, lsr #(25 - 2)

    //
    // Reapply the sign of the input.
    //
    bpl     reapply_sign_25

    rsbs    r3, r3, #0
    it      mi
        addmi   r1, r1, #(1 << (25 - 3))
        rsb     r1, r1, #0

    //
    // Calculate the final shift required.
    // This calculation is (integer portion of X)-(30-Q)
    // If this is negative, it will cause saturation later: bail now.
    //
reapply_sign_25
    asr     r12, r1, #(25 - 2)
    rsbs    r12, r12, #(30 - 25)
    bmi     exp_saturation_25
    mov     r1, r3

    //
    // Calculate the approximating polynomial.
    // R0 Result in Q30
    // R1 X, fractional portion in Q32
    // R2 Coefficient
    // R3 Multiplication scratch space.
    //
    ldr     r2, coefficient_7_25
    umull   r3, r0, r2, r1
    ldr     r2, coefficient_6_25
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_5_25
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_4_25
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_3_25
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_2_25
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_1_25
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_0_25
    adds    r0, r0, r2

    //
    // Shift answer down per previously calculated value and round.
    // NOTE:  If r12 is zero, the carry bit will "stick" at whatever it was
    // and will not be updated by lsrs.  This can cause one count of error in
    // these cases.  The adds just above is intended to reset the carry to 0.
    // This is likely unnecessary, as it helps less than 0.5% of the time. It
    // incurs no cycle count penalty, so it stays for now.
    //
    lsrs    r0, r0, r12
    adc     r0, r0, #0

    //
    // The shift instruction ignores the upper bits.  If those bits are set,
    // set the output to 0 manually.
    //
    lsrs    r12, r12, #5
    it      ne
        movne   r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Handles the case where the result saturates.
    //
exp_saturation_25
    mvn     r0, #0x80000000
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
one_over_ln_2_1_25
    dcd     0x5c551d94
one_over_ln_2_2_25
    dcd     0xae0bf85e
coefficient_0_25
    dcd     0x3fffffff
coefficient_1_25
    dcd     0x2c5c861b
coefficient_2_25
    dcd     0x0f5fde0d
coefficient_3_25
    dcd     0x038d669b
coefficient_4_25
    dcd     0x009d817c
coefficient_5_25
    dcd     0x00160186
coefficient_6_25
    dcd     0x00025756
coefficient_7_25
    dcd     0x00005ae9

//*****************************************************************************
//
// _IQ26exp
//
//*****************************************************************************
    section CODE__IQ26exp:CODE(2)
    thumb
    export  _IQ26exp
_IQ26exp
    //
    // Take the absolute value of the input.
    //
    teq     r0, #0
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply input by 1/log(2). This transforms the problem from e^x to 2^x
    // The register set {r0,r2,r3} represents X in GQ-2 format.
    //
    ldr     r12, one_over_ln_2_2_26
    mov     r1, #0
    umull   r3, r2, r12, r0
    ldr     r12, one_over_ln_2_1_26
    umlal   r2, r1, r12, r0

    //
    // Place fractional portion of input in r1 in Q32
    //
    lsl     r3, r1, #(96 - (62 + 26))
    orr     r3, r3, r2, lsr #(26 - 2)

    //
    // Reapply the sign of the input.
    //
    bpl     reapply_sign_26

    rsbs    r3, r3, #0
    it      mi
        addmi   r1, r1, #(1 << (26 - 3))
        rsb     r1, r1, #0

    //
    // Calculate the final shift required.
    // This calculation is (integer portion of X)-(30-Q)
    // If this is negative, it will cause saturation later: bail now.
    //
reapply_sign_26
    asr     r12, r1, #(26 - 2)
    rsbs    r12, r12, #(30 - 26)
    bmi     exp_saturation_26
    mov     r1, r3

    //
    // Calculate the approximating polynomial.
    // R0 Result in Q30
    // R1 X, fractional portion in Q32
    // R2 Coefficient
    // R3 Multiplication scratch space.
    //
    ldr     r2, coefficient_7_26
    umull   r3, r0, r2, r1
    ldr     r2, coefficient_6_26
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_5_26
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_4_26
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_3_26
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_2_26
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_1_26
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_0_26
    adds    r0, r0, r2

    //
    // Shift answer down per previously calculated value and round.
    // NOTE:  If r12 is zero, the carry bit will "stick" at whatever it was
    // and will not be updated by lsrs.  This can cause one count of error in
    // these cases.  The adds just above is intended to reset the carry to 0.
    // This is likely unnecessary, as it helps less than 0.5% of the time. It
    // incurs no cycle count penalty, so it stays for now.
    //
    lsrs    r0, r0, r12
    adc     r0, r0, #0

    //
    // The shift instruction ignores the upper bits.  If those bits are set,
    // set the output to 0 manually.
    //
    lsrs    r12, r12, #5
    it      ne
        movne   r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Handles the case where the result saturates.
    //
exp_saturation_26
    mvn     r0, #0x80000000
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
one_over_ln_2_1_26
    dcd     0x5c551d94
one_over_ln_2_2_26
    dcd     0xae0bf85e
coefficient_0_26
    dcd     0x3fffffff
coefficient_1_26
    dcd     0x2c5c861b
coefficient_2_26
    dcd     0x0f5fde0d
coefficient_3_26
    dcd     0x038d669b
coefficient_4_26
    dcd     0x009d817c
coefficient_5_26
    dcd     0x00160186
coefficient_6_26
    dcd     0x00025756
coefficient_7_26
    dcd     0x00005ae9

//*****************************************************************************
//
// _IQ27exp
//
//*****************************************************************************
    section CODE__IQ27exp:CODE(2)
    thumb
    export  _IQ27exp
_IQ27exp
    //
    // Take the absolute value of the input.
    //
    teq     r0, #0
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply input by 1/log(2). This transforms the problem from e^x to 2^x
    // The register set {r0,r2,r3} represents X in GQ-2 format.
    //
    ldr     r12, one_over_ln_2_2_27
    mov     r1, #0
    umull   r3, r2, r12, r0
    ldr     r12, one_over_ln_2_1_27
    umlal   r2, r1, r12, r0

    //
    // Place fractional portion of input in r1 in Q32
    //
    lsl     r3, r1, #(96 - (62 + 27))
    orr     r3, r3, r2, lsr #(27 - 2)

    //
    // Reapply the sign of the input.
    //
    bpl     reapply_sign_27

    rsbs    r3, r3, #0
    it      mi
        addmi   r1, r1, #(1 << (27 - 3))
        rsb     r1, r1, #0

    //
    // Calculate the final shift required.
    // This calculation is (integer portion of X)-(30-Q)
    // If this is negative, it will cause saturation later: bail now.
    //
reapply_sign_27
    asr     r12, r1, #(27 - 2)
    rsbs    r12, r12, #(30 - 27)
    bmi     exp_saturation_27
    mov     r1, r3

    //
    // Calculate the approximating polynomial.
    // R0 Result in Q30
    // R1 X, fractional portion in Q32
    // R2 Coefficient
    // R3 Multiplication scratch space.
    //
    ldr     r2, coefficient_7_27
    umull   r3, r0, r2, r1
    ldr     r2, coefficient_6_27
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_5_27
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_4_27
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_3_27
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_2_27
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_1_27
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_0_27
    adds    r0, r0, r2

    //
    // Shift answer down per previously calculated value and round.
    // NOTE:  If r12 is zero, the carry bit will "stick" at whatever it was
    // and will not be updated by lsrs.  This can cause one count of error in
    // these cases.  The adds just above is intended to reset the carry to 0.
    // This is likely unnecessary, as it helps less than 0.5% of the time. It
    // incurs no cycle count penalty, so it stays for now.
    //
    lsrs    r0, r0, r12
    adc     r0, r0, #0

    //
    // The shift instruction ignores the upper bits.  If those bits are set,
    // set the output to 0 manually.
    //
    lsrs    r12, r12, #5
    it      ne
        movne   r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Handles the case where the result saturates.
    //
exp_saturation_27
    mvn     r0, #0x80000000
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
one_over_ln_2_1_27
    dcd     0x5c551d94
one_over_ln_2_2_27
    dcd     0xae0bf85e
coefficient_0_27
    dcd     0x3fffffff
coefficient_1_27
    dcd     0x2c5c861b
coefficient_2_27
    dcd     0x0f5fde0d
coefficient_3_27
    dcd     0x038d669b
coefficient_4_27
    dcd     0x009d817c
coefficient_5_27
    dcd     0x00160186
coefficient_6_27
    dcd     0x00025756
coefficient_7_27
    dcd     0x00005ae9

//*****************************************************************************
//
// _IQ28exp
//
//*****************************************************************************
    section CODE__IQ28exp:CODE(2)
    thumb
    export  _IQ28exp
_IQ28exp
    //
    // Take the absolute value of the input.
    //
    teq     r0, #0
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply input by 1/log(2). This transforms the problem from e^x to 2^x
    // The register set {r0,r2,r3} represents X in GQ-2 format.
    //
    ldr     r12, one_over_ln_2_2_28
    mov     r1, #0
    umull   r3, r2, r12, r0
    ldr     r12, one_over_ln_2_1_28
    umlal   r2, r1, r12, r0

    //
    // Place fractional portion of input in r1 in Q32
    //
    lsl     r3, r1, #(96 - (62 + 28))
    orr     r3, r3, r2, lsr #(28 - 2)

    //
    // Reapply the sign of the input.
    //
    bpl     reapply_sign_28

    rsbs    r3, r3, #0
    it      mi
        addmi   r1, r1, #(1 << (28 - 3))
        rsb     r1, r1, #0

    //
    // Calculate the final shift required.
    // This calculation is (integer portion of X)-(30-Q)
    // If this is negative, it will cause saturation later: bail now.
    //
reapply_sign_28
    asr     r12, r1, #(28 - 2)
    rsbs    r12, r12, #(30 - 28)
    bmi     exp_saturation_28
    mov     r1, r3

    //
    // Calculate the approximating polynomial.
    // R0 Result in Q30
    // R1 X, fractional portion in Q32
    // R2 Coefficient
    // R3 Multiplication scratch space.
    //
    ldr     r2, coefficient_7_28
    umull   r3, r0, r2, r1
    ldr     r2, coefficient_6_28
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_5_28
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_4_28
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_3_28
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_2_28
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_1_28
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_0_28
    adds    r0, r0, r2

    //
    // Shift answer down per previously calculated value and round.
    // NOTE:  If r12 is zero, the carry bit will "stick" at whatever it was
    // and will not be updated by lsrs.  This can cause one count of error in
    // these cases.  The adds just above is intended to reset the carry to 0.
    // This is likely unnecessary, as it helps less than 0.5% of the time. It
    // incurs no cycle count penalty, so it stays for now.
    //
    lsrs    r0, r0, r12
    adc     r0, r0, #0

    //
    // The shift instruction ignores the upper bits.  If those bits are set,
    // set the output to 0 manually.
    //
    lsrs    r12, r12, #5
    it      ne
        movne   r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Handles the case where the result saturates.
    //
exp_saturation_28
    mvn     r0, #0x80000000
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
one_over_ln_2_1_28
    dcd     0x5c551d94
one_over_ln_2_2_28
    dcd     0xae0bf85e
coefficient_0_28
    dcd     0x3fffffff
coefficient_1_28
    dcd     0x2c5c861b
coefficient_2_28
    dcd     0x0f5fde0d
coefficient_3_28
    dcd     0x038d669b
coefficient_4_28
    dcd     0x009d817c
coefficient_5_28
    dcd     0x00160186
coefficient_6_28
    dcd     0x00025756
coefficient_7_28
    dcd     0x00005ae9

//*****************************************************************************
//
// _IQ29exp
//
//*****************************************************************************
    section CODE__IQ29exp:CODE(2)
    thumb
    export  _IQ29exp
_IQ29exp
    //
    // Take the absolute value of the input.
    //
    teq     r0, #0
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply input by 1/log(2). This transforms the problem from e^x to 2^x
    // The register set {r0,r2,r3} represents X in GQ-2 format.
    //
    ldr     r12, one_over_ln_2_2_29
    mov     r1, #0
    umull   r3, r2, r12, r0
    ldr     r12, one_over_ln_2_1_29
    umlal   r2, r1, r12, r0

    //
    // Place fractional portion of input in r1 in Q32
    //
    lsl     r3, r1, #(96 - (62 + 29))
    orr     r3, r3, r2, lsr #(29 - 2)

    //
    // Reapply the sign of the input.
    //
    bpl     reapply_sign_29

    rsbs    r3, r3, #0
    it      mi
        addmi   r1, r1, #(1 << (29 - 3))
        rsb     r1, r1, #0

    //
    // Calculate the final shift required.
    // This calculation is (integer portion of X)-(30-Q)
    // If this is negative, it will cause saturation later: bail now.
    //
reapply_sign_29
    asr     r12, r1, #(29 - 2)
    rsbs    r12, r12, #(30 - 29)
    bmi     exp_saturation_29
    mov     r1, r3

    //
    // Calculate the approximating polynomial.
    // R0 Result in Q30
    // R1 X, fractional portion in Q32
    // R2 Coefficient
    // R3 Multiplication scratch space.
    //
    ldr     r2, coefficient_7_29
    umull   r3, r0, r2, r1
    ldr     r2, coefficient_6_29
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_5_29
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_4_29
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_3_29
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_2_29
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_1_29
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_0_29
    adds    r0, r0, r2

    //
    // Shift answer down per previously calculated value and round.
    // NOTE:  If r12 is zero, the carry bit will "stick" at whatever it was
    // and will not be updated by lsrs.  This can cause one count of error in
    // these cases.  The adds just above is intended to reset the carry to 0.
    // This is likely unnecessary, as it helps less than 0.5% of the time. It
    // incurs no cycle count penalty, so it stays for now.
    //
    lsrs    r0, r0, r12
    adc     r0, r0, #0

    //
    // The shift instruction ignores the upper bits.  If those bits are set,
    // set the output to 0 manually.
    //
    lsrs    r12, r12, #5
    it      ne
        movne   r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Handles the case where the result saturates.
    //
exp_saturation_29
    mvn     r0, #0x80000000
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
one_over_ln_2_1_29
    dcd     0x5c551d94
one_over_ln_2_2_29
    dcd     0xae0bf85e
coefficient_0_29
    dcd     0x3fffffff
coefficient_1_29
    dcd     0x2c5c861b
coefficient_2_29
    dcd     0x0f5fde0d
coefficient_3_29
    dcd     0x038d669b
coefficient_4_29
    dcd     0x009d817c
coefficient_5_29
    dcd     0x00160186
coefficient_6_29
    dcd     0x00025756
coefficient_7_29
    dcd     0x00005ae9

//*****************************************************************************
//
// _IQ30exp
//
//*****************************************************************************
    section CODE__IQ30exp:CODE(2)
    thumb
    export  _IQ30exp
_IQ30exp
    //
    // Take the absolute value of the input.
    //
    teq     r0, #0
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply input by 1/log(2). This transforms the problem from e^x to 2^x
    // The register set {r0,r2,r3} represents X in GQ-2 format.
    //
    ldr     r12, one_over_ln_2_2_30
    mov     r1, #0
    umull   r3, r2, r12, r0
    ldr     r12, one_over_ln_2_1_30
    umlal   r2, r1, r12, r0

    //
    // Place fractional portion of input in r1 in Q32
    //
    lsl     r3, r1, #(96 - (62 + 30))
    orr     r3, r3, r2, lsr #(30 - 2)

    //
    // Reapply the sign of the input.
    //
    bpl     reapply_sign_30

    rsbs    r3, r3, #0
    it      mi
        addmi   r1, r1, #(1 << (30 - 3))
        rsb     r1, r1, #0

    //
    // Calculate the final shift required.
    // This calculation is (integer portion of X)-(30-Q)
    // If this is negative, it will cause saturation later: bail now.
    //
reapply_sign_30
    asr     r12, r1, #(30 - 2)
    rsbs    r12, r12, #(30 - 30)
    bmi     exp_saturation_30
    mov     r1, r3

    //
    // Calculate the approximating polynomial.
    // R0 Result in Q30
    // R1 X, fractional portion in Q32
    // R2 Coefficient
    // R3 Multiplication scratch space.
    //
    ldr     r2, coefficient_7_30
    umull   r3, r0, r2, r1
    ldr     r2, coefficient_6_30
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_5_30
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_4_30
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_3_30
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_2_30
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_1_30
    add     r0, r0, r2
    umull   r3, r0, r0, r1
    ldr     r2, coefficient_0_30
    adds    r0, r0, r2

    //
    // Shift answer down per previously calculated value and round.
    // NOTE:  If r12 is zero, the carry bit will "stick" at whatever it was
    // and will not be updated by lsrs.  This can cause one count of error in
    // these cases.  The adds just above is intended to reset the carry to 0.
    // This is likely unnecessary, as it helps less than 0.5% of the time. It
    // incurs no cycle count penalty, so it stays for now.
    //
    lsrs    r0, r0, r12
    adc     r0, r0, #0

    //
    // The shift instruction ignores the upper bits.  If those bits are set,
    // set the output to 0 manually.
    //
    lsrs    r12, r12, #5
    it      ne
        movne   r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Handles the case where the result saturates.
    //
exp_saturation_30
    mvn     r0, #0x80000000
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
one_over_ln_2_1_30
    dcd     0x5c551d94
one_over_ln_2_2_30
    dcd     0xae0bf85e
coefficient_0_30
    dcd     0x3fffffff
coefficient_1_30
    dcd     0x2c5c861b
coefficient_2_30
    dcd     0x0f5fde0d
coefficient_3_30
    dcd     0x038d669b
coefficient_4_30
    dcd     0x009d817c
coefficient_5_30
    dcd     0x00160186
coefficient_6_30
    dcd     0x00025756
coefficient_7_30
    dcd     0x00005ae9

    end
