//*****************************************************************************
//
// IQmag.S - Fixed point magnitude
//
// Copyright (c) 2010 Texas Instruments Incorporated.  All rights reserved.
// TI Information - Selective Disclosure
//
//*****************************************************************************

//*****************************************************************************
//
// Function:   _IQNmag
//
//*****************************************************************************
//
// C Usage:    extern long _IQNmag(long X, long Y); // with rounding & sat
//
//-----------------------------------------------------------------------------
//
// On Entry:   r0    = X in IQ format
//             r1    = Y in IQ format
//
// Regs Used:  r0-r4
//             r4 is pushed/popped to prevent clobbering.
//
// On Exit:    r0    = sqrt(X) result in IQ format
//             r0    = 0 if input is -ve or 0
//
//                      Note: The square root of any number will never
//                            overflow, hence saturation is not required.
//
// Q range:    30 to 1
//
//-----------------------------------------------------------------------------
//
// Algorithm:  The procedure for calculating "Y = sqrt(X)" is as follows:
//
//      Step 1)  Calculate Z = isqrt(X).  See _IQisqrt.S for details.
//
//      Step 2)  Calculate Y = sqrt(X) = X*isqrt(X) = Z*x
//
//      Step 3) Denormalize result and round
//
//##### INTERNAL BEGIN #####
//-----------------------------------------------------------------------------
//
// Benchmark:
//
//  Q <= 20, L is even :
//  Q <= 20, L is odd  :
//  Q >  20, L is even :
//  Q >  20, L is odd  :
//  Negative or Zero   :
//  Overflow           :
//
//##### INTERNAL END #####
//*****************************************************************************

//*****************************************************************************
//
// The isqrt table is used.
//
//*****************************************************************************
    import  isqrt_table

//*****************************************************************************
//
// _IQ1mag
//
//*****************************************************************************
    section CODE__IQ1mag:CODE(2)
    thumb
    export  _IQ1mag
_IQ1mag
    //
    // Save non-volatile registers.
    //
    push    {r4, lr}

    //
    // Sum of Squares
    // Keep 64 bit version in r12lr
    // Place 32 bit version in r0
    //
    smull   r12, lr, r0, r0
    smlal   r12, lr, r1, r1

    //
    // Place upper 32 used bits of result into r0, effectively creating a
    // normalized Q32 representation.
    // This is implemented as a 64 bit clz shift followed
    // by a 32 bit clz shift.
    // Total shift amount is stored in r3
    //
    clz     r3, lr
    rsb     r2, r3, #32
    lsrs    r0, r12, r2
    lsl     r1, lr, r3
    adcs    r0, r0, r1
    ittt    pl
        clzpl   r2, r0
        lslpl   r0, r0, r2
        addpl   r3, r2, r3

    //
    // If the result is 0, bail early.
    // We are guaranteed that the result is not negative,
    // so those checks are omitted.
    //
    teq     r0, #0
    it      eq
        popeq  {r4, pc}

    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r0, #(32 - 10)
    ldr     r1, isqrt_table_1
    ldr     r1, [r1, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // 11-17 Cycles
    // r0 is Q32, r1 is Q31
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    subs    r3, r3, #2
    bmi     mag_will_overflow1
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    itt     cs
        ldrcs   r2, sqrt_half_1
        umullcs r2, r1, r2, r1

    //
    // Multiply isqrt(x) by x to get sqrt(x)
    //
    umull   r4, r0, r0, r1

    //
    // Actually denormalize per above preparation
    // Round result
    // Note:  If r3 == 0, no rounding is performed.  This potentially creates
    // an additional count worth of error if the result is nearly saturated.
    // The extra execution time to check for this is not worthwhile.
    //
    lsrs    r0, r0, r3
    adc     r0, r0, #0

    //
    // Restore r4 and return.
    ///
    pop     {r4, pc}

    //
    // The result will overflow.
    //
mag_will_overflow1
    mvn     r0, #0x80000000
    pop     {r4, pc}

    //
    // The literal pool.
    //
    alignrom 2
    data
isqrt_table_1
    dcd     isqrt_table - 0x800
sqrt_half_1
    dcd     0xb504f334         // sqrt(1/2) in Q32

//*****************************************************************************
//
// _IQ2mag
//
//*****************************************************************************
    section CODE__IQ2mag:CODE(2)
    thumb
    export  _IQ2mag
_IQ2mag
    //
    // Save non-volatile registers.
    //
    push    {r4, lr}

    //
    // Sum of Squares
    // Keep 64 bit version in r12lr
    // Place 32 bit version in r0
    //
    smull   r12, lr, r0, r0
    smlal   r12, lr, r1, r1

    //
    // Place upper 32 used bits of result into r0, effectively creating a
    // normalized Q32 representation.
    // This is implemented as a 64 bit clz shift followed
    // by a 32 bit clz shift.
    // Total shift amount is stored in r3
    //
    clz     r3, lr
    rsb     r2, r3, #32
    lsrs    r0, r12, r2
    lsl     r1, lr, r3
    adcs    r0, r0, r1
    ittt    pl
        clzpl   r2, r0
        lslpl   r0, r0, r2
        addpl   r3, r2, r3

    //
    // If the result is 0, bail early.
    // We are guaranteed that the result is not negative,
    // so those checks are omitted.
    //
    teq     r0, #0
    it      eq
        popeq  {r4, pc}

    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r0, #(32 - 10)
    ldr     r1, isqrt_table_2
    ldr     r1, [r1, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // 11-17 Cycles
    // r0 is Q32, r1 is Q31
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    subs    r3, r3, #2
    bmi     mag_will_overflow2
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    itt     cs
        ldrcs   r2, sqrt_half_2
        umullcs r2, r1, r2, r1

    //
    // Multiply isqrt(x) by x to get sqrt(x)
    //
    umull   r4, r0, r0, r1

    //
    // Actually denormalize per above preparation
    // Round result
    // Note:  If r3 == 0, no rounding is performed.  This potentially creates
    // an additional count worth of error if the result is nearly saturated.
    // The extra execution time to check for this is not worthwhile.
    //
    lsrs    r0, r0, r3
    adc     r0, r0, #0

    //
    // Restore r4 and return.
    ///
    pop     {r4, pc}

    //
    // The result will overflow.
    //
mag_will_overflow2
    mvn     r0, #0x80000000
    pop     {r4, pc}

    //
    // The literal pool.
    //
    alignrom 2
    data
isqrt_table_2
    dcd     isqrt_table - 0x800
sqrt_half_2
    dcd     0xb504f334         // sqrt(1/2) in Q32

//*****************************************************************************
//
// _IQ3mag
//
//*****************************************************************************
    section CODE__IQ3mag:CODE(2)
    thumb
    export  _IQ3mag
_IQ3mag
    //
    // Save non-volatile registers.
    //
    push    {r4, lr}

    //
    // Sum of Squares
    // Keep 64 bit version in r12lr
    // Place 32 bit version in r0
    //
    smull   r12, lr, r0, r0
    smlal   r12, lr, r1, r1

    //
    // Place upper 32 used bits of result into r0, effectively creating a
    // normalized Q32 representation.
    // This is implemented as a 64 bit clz shift followed
    // by a 32 bit clz shift.
    // Total shift amount is stored in r3
    //
    clz     r3, lr
    rsb     r2, r3, #32
    lsrs    r0, r12, r2
    lsl     r1, lr, r3
    adcs    r0, r0, r1
    ittt    pl
        clzpl   r2, r0
        lslpl   r0, r0, r2
        addpl   r3, r2, r3

    //
    // If the result is 0, bail early.
    // We are guaranteed that the result is not negative,
    // so those checks are omitted.
    //
    teq     r0, #0
    it      eq
        popeq  {r4, pc}

    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r0, #(32 - 10)
    ldr     r1, isqrt_table_3
    ldr     r1, [r1, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // 11-17 Cycles
    // r0 is Q32, r1 is Q31
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    subs    r3, r3, #2
    bmi     mag_will_overflow3
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    itt     cs
        ldrcs   r2, sqrt_half_3
        umullcs r2, r1, r2, r1

    //
    // Multiply isqrt(x) by x to get sqrt(x)
    //
    umull   r4, r0, r0, r1

    //
    // Actually denormalize per above preparation
    // Round result
    // Note:  If r3 == 0, no rounding is performed.  This potentially creates
    // an additional count worth of error if the result is nearly saturated.
    // The extra execution time to check for this is not worthwhile.
    //
    lsrs    r0, r0, r3
    adc     r0, r0, #0

    //
    // Restore r4 and return.
    ///
    pop     {r4, pc}

    //
    // The result will overflow.
    //
mag_will_overflow3
    mvn     r0, #0x80000000
    pop     {r4, pc}

    //
    // The literal pool.
    //
    alignrom 2
    data
isqrt_table_3
    dcd     isqrt_table - 0x800
sqrt_half_3
    dcd     0xb504f334         // sqrt(1/2) in Q32

//*****************************************************************************
//
// _IQ4mag
//
//*****************************************************************************
    section CODE__IQ4mag:CODE(2)
    thumb
    export  _IQ4mag
_IQ4mag
    //
    // Save non-volatile registers.
    //
    push    {r4, lr}

    //
    // Sum of Squares
    // Keep 64 bit version in r12lr
    // Place 32 bit version in r0
    //
    smull   r12, lr, r0, r0
    smlal   r12, lr, r1, r1

    //
    // Place upper 32 used bits of result into r0, effectively creating a
    // normalized Q32 representation.
    // This is implemented as a 64 bit clz shift followed
    // by a 32 bit clz shift.
    // Total shift amount is stored in r3
    //
    clz     r3, lr
    rsb     r2, r3, #32
    lsrs    r0, r12, r2
    lsl     r1, lr, r3
    adcs    r0, r0, r1
    ittt    pl
        clzpl   r2, r0
        lslpl   r0, r0, r2
        addpl   r3, r2, r3

    //
    // If the result is 0, bail early.
    // We are guaranteed that the result is not negative,
    // so those checks are omitted.
    //
    teq     r0, #0
    it      eq
        popeq  {r4, pc}

    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r0, #(32 - 10)
    ldr     r1, isqrt_table_4
    ldr     r1, [r1, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // 11-17 Cycles
    // r0 is Q32, r1 is Q31
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    subs    r3, r3, #2
    bmi     mag_will_overflow4
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    itt     cs
        ldrcs   r2, sqrt_half_4
        umullcs r2, r1, r2, r1

    //
    // Multiply isqrt(x) by x to get sqrt(x)
    //
    umull   r4, r0, r0, r1

    //
    // Actually denormalize per above preparation
    // Round result
    // Note:  If r3 == 0, no rounding is performed.  This potentially creates
    // an additional count worth of error if the result is nearly saturated.
    // The extra execution time to check for this is not worthwhile.
    //
    lsrs    r0, r0, r3
    adc     r0, r0, #0

    //
    // Restore r4 and return.
    ///
    pop     {r4, pc}

    //
    // The result will overflow.
    //
mag_will_overflow4
    mvn     r0, #0x80000000
    pop     {r4, pc}

    //
    // The literal pool.
    //
    alignrom 2
    data
isqrt_table_4
    dcd     isqrt_table - 0x800
sqrt_half_4
    dcd     0xb504f334         // sqrt(1/2) in Q32

//*****************************************************************************
//
// _IQ5mag
//
//*****************************************************************************
    section CODE__IQ5mag:CODE(2)
    thumb
    export  _IQ5mag
_IQ5mag
    //
    // Save non-volatile registers.
    //
    push    {r4, lr}

    //
    // Sum of Squares
    // Keep 64 bit version in r12lr
    // Place 32 bit version in r0
    //
    smull   r12, lr, r0, r0
    smlal   r12, lr, r1, r1

    //
    // Place upper 32 used bits of result into r0, effectively creating a
    // normalized Q32 representation.
    // This is implemented as a 64 bit clz shift followed
    // by a 32 bit clz shift.
    // Total shift amount is stored in r3
    //
    clz     r3, lr
    rsb     r2, r3, #32
    lsrs    r0, r12, r2
    lsl     r1, lr, r3
    adcs    r0, r0, r1
    ittt    pl
        clzpl   r2, r0
        lslpl   r0, r0, r2
        addpl   r3, r2, r3

    //
    // If the result is 0, bail early.
    // We are guaranteed that the result is not negative,
    // so those checks are omitted.
    //
    teq     r0, #0
    it      eq
        popeq  {r4, pc}

    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r0, #(32 - 10)
    ldr     r1, isqrt_table_5
    ldr     r1, [r1, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // 11-17 Cycles
    // r0 is Q32, r1 is Q31
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    subs    r3, r3, #2
    bmi     mag_will_overflow5
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    itt     cs
        ldrcs   r2, sqrt_half_5
        umullcs r2, r1, r2, r1

    //
    // Multiply isqrt(x) by x to get sqrt(x)
    //
    umull   r4, r0, r0, r1

    //
    // Actually denormalize per above preparation
    // Round result
    // Note:  If r3 == 0, no rounding is performed.  This potentially creates
    // an additional count worth of error if the result is nearly saturated.
    // The extra execution time to check for this is not worthwhile.
    //
    lsrs    r0, r0, r3
    adc     r0, r0, #0

    //
    // Restore r4 and return.
    ///
    pop     {r4, pc}

    //
    // The result will overflow.
    //
mag_will_overflow5
    mvn     r0, #0x80000000
    pop     {r4, pc}

    //
    // The literal pool.
    //
    alignrom 2
    data
isqrt_table_5
    dcd     isqrt_table - 0x800
sqrt_half_5
    dcd     0xb504f334         // sqrt(1/2) in Q32

//*****************************************************************************
//
// _IQ6mag
//
//*****************************************************************************
    section CODE__IQ6mag:CODE(2)
    thumb
    export  _IQ6mag
_IQ6mag
    //
    // Save non-volatile registers.
    //
    push    {r4, lr}

    //
    // Sum of Squares
    // Keep 64 bit version in r12lr
    // Place 32 bit version in r0
    //
    smull   r12, lr, r0, r0
    smlal   r12, lr, r1, r1

    //
    // Place upper 32 used bits of result into r0, effectively creating a
    // normalized Q32 representation.
    // This is implemented as a 64 bit clz shift followed
    // by a 32 bit clz shift.
    // Total shift amount is stored in r3
    //
    clz     r3, lr
    rsb     r2, r3, #32
    lsrs    r0, r12, r2
    lsl     r1, lr, r3
    adcs    r0, r0, r1
    ittt    pl
        clzpl   r2, r0
        lslpl   r0, r0, r2
        addpl   r3, r2, r3

    //
    // If the result is 0, bail early.
    // We are guaranteed that the result is not negative,
    // so those checks are omitted.
    //
    teq     r0, #0
    it      eq
        popeq  {r4, pc}

    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r0, #(32 - 10)
    ldr     r1, isqrt_table_6
    ldr     r1, [r1, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // 11-17 Cycles
    // r0 is Q32, r1 is Q31
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    subs    r3, r3, #2
    bmi     mag_will_overflow6
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    itt     cs
        ldrcs   r2, sqrt_half_6
        umullcs r2, r1, r2, r1

    //
    // Multiply isqrt(x) by x to get sqrt(x)
    //
    umull   r4, r0, r0, r1

    //
    // Actually denormalize per above preparation
    // Round result
    // Note:  If r3 == 0, no rounding is performed.  This potentially creates
    // an additional count worth of error if the result is nearly saturated.
    // The extra execution time to check for this is not worthwhile.
    //
    lsrs    r0, r0, r3
    adc     r0, r0, #0

    //
    // Restore r4 and return.
    ///
    pop     {r4, pc}

    //
    // The result will overflow.
    //
mag_will_overflow6
    mvn     r0, #0x80000000
    pop     {r4, pc}

    //
    // The literal pool.
    //
    alignrom 2
    data
isqrt_table_6
    dcd     isqrt_table - 0x800
sqrt_half_6
    dcd     0xb504f334         // sqrt(1/2) in Q32

//*****************************************************************************
//
// _IQ7mag
//
//*****************************************************************************
    section CODE__IQ7mag:CODE(2)
    thumb
    export  _IQ7mag
_IQ7mag
    //
    // Save non-volatile registers.
    //
    push    {r4, lr}

    //
    // Sum of Squares
    // Keep 64 bit version in r12lr
    // Place 32 bit version in r0
    //
    smull   r12, lr, r0, r0
    smlal   r12, lr, r1, r1

    //
    // Place upper 32 used bits of result into r0, effectively creating a
    // normalized Q32 representation.
    // This is implemented as a 64 bit clz shift followed
    // by a 32 bit clz shift.
    // Total shift amount is stored in r3
    //
    clz     r3, lr
    rsb     r2, r3, #32
    lsrs    r0, r12, r2
    lsl     r1, lr, r3
    adcs    r0, r0, r1
    ittt    pl
        clzpl   r2, r0
        lslpl   r0, r0, r2
        addpl   r3, r2, r3

    //
    // If the result is 0, bail early.
    // We are guaranteed that the result is not negative,
    // so those checks are omitted.
    //
    teq     r0, #0
    it      eq
        popeq  {r4, pc}

    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r0, #(32 - 10)
    ldr     r1, isqrt_table_7
    ldr     r1, [r1, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // 11-17 Cycles
    // r0 is Q32, r1 is Q31
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    subs    r3, r3, #2
    bmi     mag_will_overflow7
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    itt     cs
        ldrcs   r2, sqrt_half_7
        umullcs r2, r1, r2, r1

    //
    // Multiply isqrt(x) by x to get sqrt(x)
    //
    umull   r4, r0, r0, r1

    //
    // Actually denormalize per above preparation
    // Round result
    // Note:  If r3 == 0, no rounding is performed.  This potentially creates
    // an additional count worth of error if the result is nearly saturated.
    // The extra execution time to check for this is not worthwhile.
    //
    lsrs    r0, r0, r3
    adc     r0, r0, #0

    //
    // Restore r4 and return.
    ///
    pop     {r4, pc}

    //
    // The result will overflow.
    //
mag_will_overflow7
    mvn     r0, #0x80000000
    pop     {r4, pc}

    //
    // The literal pool.
    //
    alignrom 2
    data
isqrt_table_7
    dcd     isqrt_table - 0x800
sqrt_half_7
    dcd     0xb504f334         // sqrt(1/2) in Q32

//*****************************************************************************
//
// _IQ8mag
//
//*****************************************************************************
    section CODE__IQ8mag:CODE(2)
    thumb
    export  _IQ8mag
_IQ8mag
    //
    // Save non-volatile registers.
    //
    push    {r4, lr}

    //
    // Sum of Squares
    // Keep 64 bit version in r12lr
    // Place 32 bit version in r0
    //
    smull   r12, lr, r0, r0
    smlal   r12, lr, r1, r1

    //
    // Place upper 32 used bits of result into r0, effectively creating a
    // normalized Q32 representation.
    // This is implemented as a 64 bit clz shift followed
    // by a 32 bit clz shift.
    // Total shift amount is stored in r3
    //
    clz     r3, lr
    rsb     r2, r3, #32
    lsrs    r0, r12, r2
    lsl     r1, lr, r3
    adcs    r0, r0, r1
    ittt    pl
        clzpl   r2, r0
        lslpl   r0, r0, r2
        addpl   r3, r2, r3

    //
    // If the result is 0, bail early.
    // We are guaranteed that the result is not negative,
    // so those checks are omitted.
    //
    teq     r0, #0
    it      eq
        popeq  {r4, pc}

    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r0, #(32 - 10)
    ldr     r1, isqrt_table_8
    ldr     r1, [r1, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // 11-17 Cycles
    // r0 is Q32, r1 is Q31
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    subs    r3, r3, #2
    bmi     mag_will_overflow8
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    itt     cs
        ldrcs   r2, sqrt_half_8
        umullcs r2, r1, r2, r1

    //
    // Multiply isqrt(x) by x to get sqrt(x)
    //
    umull   r4, r0, r0, r1

    //
    // Actually denormalize per above preparation
    // Round result
    // Note:  If r3 == 0, no rounding is performed.  This potentially creates
    // an additional count worth of error if the result is nearly saturated.
    // The extra execution time to check for this is not worthwhile.
    //
    lsrs    r0, r0, r3
    adc     r0, r0, #0

    //
    // Restore r4 and return.
    ///
    pop     {r4, pc}

    //
    // The result will overflow.
    //
mag_will_overflow8
    mvn     r0, #0x80000000
    pop     {r4, pc}

    //
    // The literal pool.
    //
    alignrom 2
    data
isqrt_table_8
    dcd     isqrt_table - 0x800
sqrt_half_8
    dcd     0xb504f334         // sqrt(1/2) in Q32

//*****************************************************************************
//
// _IQ9mag
//
//*****************************************************************************
    section CODE__IQ9mag:CODE(2)
    thumb
    export  _IQ9mag
_IQ9mag
    //
    // Save non-volatile registers.
    //
    push    {r4, lr}

    //
    // Sum of Squares
    // Keep 64 bit version in r12lr
    // Place 32 bit version in r0
    //
    smull   r12, lr, r0, r0
    smlal   r12, lr, r1, r1

    //
    // Place upper 32 used bits of result into r0, effectively creating a
    // normalized Q32 representation.
    // This is implemented as a 64 bit clz shift followed
    // by a 32 bit clz shift.
    // Total shift amount is stored in r3
    //
    clz     r3, lr
    rsb     r2, r3, #32
    lsrs    r0, r12, r2
    lsl     r1, lr, r3
    adcs    r0, r0, r1
    ittt    pl
        clzpl   r2, r0
        lslpl   r0, r0, r2
        addpl   r3, r2, r3

    //
    // If the result is 0, bail early.
    // We are guaranteed that the result is not negative,
    // so those checks are omitted.
    //
    teq     r0, #0
    it      eq
        popeq  {r4, pc}

    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r0, #(32 - 10)
    ldr     r1, isqrt_table_9
    ldr     r1, [r1, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // 11-17 Cycles
    // r0 is Q32, r1 is Q31
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    subs    r3, r3, #2
    bmi     mag_will_overflow9
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    itt     cs
        ldrcs   r2, sqrt_half_9
        umullcs r2, r1, r2, r1

    //
    // Multiply isqrt(x) by x to get sqrt(x)
    //
    umull   r4, r0, r0, r1

    //
    // Actually denormalize per above preparation
    // Round result
    // Note:  If r3 == 0, no rounding is performed.  This potentially creates
    // an additional count worth of error if the result is nearly saturated.
    // The extra execution time to check for this is not worthwhile.
    //
    lsrs    r0, r0, r3
    adc     r0, r0, #0

    //
    // Restore r4 and return.
    ///
    pop     {r4, pc}

    //
    // The result will overflow.
    //
mag_will_overflow9
    mvn     r0, #0x80000000
    pop     {r4, pc}

    //
    // The literal pool.
    //
    alignrom 2
    data
isqrt_table_9
    dcd     isqrt_table - 0x800
sqrt_half_9
    dcd     0xb504f334         // sqrt(1/2) in Q32

//*****************************************************************************
//
// _IQ10mag
//
//*****************************************************************************
    section CODE__IQ10mag:CODE(2)
    thumb
    export  _IQ10mag
_IQ10mag
    //
    // Save non-volatile registers.
    //
    push    {r4, lr}

    //
    // Sum of Squares
    // Keep 64 bit version in r12lr
    // Place 32 bit version in r0
    //
    smull   r12, lr, r0, r0
    smlal   r12, lr, r1, r1

    //
    // Place upper 32 used bits of result into r0, effectively creating a
    // normalized Q32 representation.
    // This is implemented as a 64 bit clz shift followed
    // by a 32 bit clz shift.
    // Total shift amount is stored in r3
    //
    clz     r3, lr
    rsb     r2, r3, #32
    lsrs    r0, r12, r2
    lsl     r1, lr, r3
    adcs    r0, r0, r1
    ittt    pl
        clzpl   r2, r0
        lslpl   r0, r0, r2
        addpl   r3, r2, r3

    //
    // If the result is 0, bail early.
    // We are guaranteed that the result is not negative,
    // so those checks are omitted.
    //
    teq     r0, #0
    it      eq
        popeq  {r4, pc}

    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r0, #(32 - 10)
    ldr     r1, isqrt_table_10
    ldr     r1, [r1, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // 11-17 Cycles
    // r0 is Q32, r1 is Q31
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    subs    r3, r3, #2
    bmi     mag_will_overflow10
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    itt     cs
        ldrcs   r2, sqrt_half_10
        umullcs r2, r1, r2, r1

    //
    // Multiply isqrt(x) by x to get sqrt(x)
    //
    umull   r4, r0, r0, r1

    //
    // Actually denormalize per above preparation
    // Round result
    // Note:  If r3 == 0, no rounding is performed.  This potentially creates
    // an additional count worth of error if the result is nearly saturated.
    // The extra execution time to check for this is not worthwhile.
    //
    lsrs    r0, r0, r3
    adc     r0, r0, #0

    //
    // Restore r4 and return.
    ///
    pop     {r4, pc}

    //
    // The result will overflow.
    //
mag_will_overflow10
    mvn     r0, #0x80000000
    pop     {r4, pc}

    //
    // The literal pool.
    //
    alignrom 2
    data
isqrt_table_10
    dcd     isqrt_table - 0x800
sqrt_half_10
    dcd     0xb504f334         // sqrt(1/2) in Q32

//*****************************************************************************
//
// _IQ11mag
//
//*****************************************************************************
    section CODE__IQ11mag:CODE(2)
    thumb
    export  _IQ11mag
_IQ11mag
    //
    // Save non-volatile registers.
    //
    push    {r4, lr}

    //
    // Sum of Squares
    // Keep 64 bit version in r12lr
    // Place 32 bit version in r0
    //
    smull   r12, lr, r0, r0
    smlal   r12, lr, r1, r1

    //
    // Place upper 32 used bits of result into r0, effectively creating a
    // normalized Q32 representation.
    // This is implemented as a 64 bit clz shift followed
    // by a 32 bit clz shift.
    // Total shift amount is stored in r3
    //
    clz     r3, lr
    rsb     r2, r3, #32
    lsrs    r0, r12, r2
    lsl     r1, lr, r3
    adcs    r0, r0, r1
    ittt    pl
        clzpl   r2, r0
        lslpl   r0, r0, r2
        addpl   r3, r2, r3

    //
    // If the result is 0, bail early.
    // We are guaranteed that the result is not negative,
    // so those checks are omitted.
    //
    teq     r0, #0
    it      eq
        popeq  {r4, pc}

    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r0, #(32 - 10)
    ldr     r1, isqrt_table_11
    ldr     r1, [r1, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // 11-17 Cycles
    // r0 is Q32, r1 is Q31
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    subs    r3, r3, #2
    bmi     mag_will_overflow11
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    itt     cs
        ldrcs   r2, sqrt_half_11
        umullcs r2, r1, r2, r1

    //
    // Multiply isqrt(x) by x to get sqrt(x)
    //
    umull   r4, r0, r0, r1

    //
    // Actually denormalize per above preparation
    // Round result
    // Note:  If r3 == 0, no rounding is performed.  This potentially creates
    // an additional count worth of error if the result is nearly saturated.
    // The extra execution time to check for this is not worthwhile.
    //
    lsrs    r0, r0, r3
    adc     r0, r0, #0

    //
    // Restore r4 and return.
    ///
    pop     {r4, pc}

    //
    // The result will overflow.
    //
mag_will_overflow11
    mvn     r0, #0x80000000
    pop     {r4, pc}

    //
    // The literal pool.
    //
    alignrom 2
    data
isqrt_table_11
    dcd     isqrt_table - 0x800
sqrt_half_11
    dcd     0xb504f334         // sqrt(1/2) in Q32

//*****************************************************************************
//
// _IQ12mag
//
//*****************************************************************************
    section CODE__IQ12mag:CODE(2)
    thumb
    export  _IQ12mag
_IQ12mag
    //
    // Save non-volatile registers.
    //
    push    {r4, lr}

    //
    // Sum of Squares
    // Keep 64 bit version in r12lr
    // Place 32 bit version in r0
    //
    smull   r12, lr, r0, r0
    smlal   r12, lr, r1, r1

    //
    // Place upper 32 used bits of result into r0, effectively creating a
    // normalized Q32 representation.
    // This is implemented as a 64 bit clz shift followed
    // by a 32 bit clz shift.
    // Total shift amount is stored in r3
    //
    clz     r3, lr
    rsb     r2, r3, #32
    lsrs    r0, r12, r2
    lsl     r1, lr, r3
    adcs    r0, r0, r1
    ittt    pl
        clzpl   r2, r0
        lslpl   r0, r0, r2
        addpl   r3, r2, r3

    //
    // If the result is 0, bail early.
    // We are guaranteed that the result is not negative,
    // so those checks are omitted.
    //
    teq     r0, #0
    it      eq
        popeq  {r4, pc}

    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r0, #(32 - 10)
    ldr     r1, isqrt_table_12
    ldr     r1, [r1, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // 11-17 Cycles
    // r0 is Q32, r1 is Q31
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    subs    r3, r3, #2
    bmi     mag_will_overflow12
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    itt     cs
        ldrcs   r2, sqrt_half_12
        umullcs r2, r1, r2, r1

    //
    // Multiply isqrt(x) by x to get sqrt(x)
    //
    umull   r4, r0, r0, r1

    //
    // Actually denormalize per above preparation
    // Round result
    // Note:  If r3 == 0, no rounding is performed.  This potentially creates
    // an additional count worth of error if the result is nearly saturated.
    // The extra execution time to check for this is not worthwhile.
    //
    lsrs    r0, r0, r3
    adc     r0, r0, #0

    //
    // Restore r4 and return.
    ///
    pop     {r4, pc}

    //
    // The result will overflow.
    //
mag_will_overflow12
    mvn     r0, #0x80000000
    pop     {r4, pc}

    //
    // The literal pool.
    //
    alignrom 2
    data
isqrt_table_12
    dcd     isqrt_table - 0x800
sqrt_half_12
    dcd     0xb504f334         // sqrt(1/2) in Q32

//*****************************************************************************
//
// _IQ13mag
//
//*****************************************************************************
    section CODE__IQ13mag:CODE(2)
    thumb
    export  _IQ13mag
_IQ13mag
    //
    // Save non-volatile registers.
    //
    push    {r4, lr}

    //
    // Sum of Squares
    // Keep 64 bit version in r12lr
    // Place 32 bit version in r0
    //
    smull   r12, lr, r0, r0
    smlal   r12, lr, r1, r1

    //
    // Place upper 32 used bits of result into r0, effectively creating a
    // normalized Q32 representation.
    // This is implemented as a 64 bit clz shift followed
    // by a 32 bit clz shift.
    // Total shift amount is stored in r3
    //
    clz     r3, lr
    rsb     r2, r3, #32
    lsrs    r0, r12, r2
    lsl     r1, lr, r3
    adcs    r0, r0, r1
    ittt    pl
        clzpl   r2, r0
        lslpl   r0, r0, r2
        addpl   r3, r2, r3

    //
    // If the result is 0, bail early.
    // We are guaranteed that the result is not negative,
    // so those checks are omitted.
    //
    teq     r0, #0
    it      eq
        popeq  {r4, pc}

    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r0, #(32 - 10)
    ldr     r1, isqrt_table_13
    ldr     r1, [r1, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // 11-17 Cycles
    // r0 is Q32, r1 is Q31
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    subs    r3, r3, #2
    bmi     mag_will_overflow13
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    itt     cs
        ldrcs   r2, sqrt_half_13
        umullcs r2, r1, r2, r1

    //
    // Multiply isqrt(x) by x to get sqrt(x)
    //
    umull   r4, r0, r0, r1

    //
    // Actually denormalize per above preparation
    // Round result
    // Note:  If r3 == 0, no rounding is performed.  This potentially creates
    // an additional count worth of error if the result is nearly saturated.
    // The extra execution time to check for this is not worthwhile.
    //
    lsrs    r0, r0, r3
    adc     r0, r0, #0

    //
    // Restore r4 and return.
    ///
    pop     {r4, pc}

    //
    // The result will overflow.
    //
mag_will_overflow13
    mvn     r0, #0x80000000
    pop     {r4, pc}

    //
    // The literal pool.
    //
    alignrom 2
    data
isqrt_table_13
    dcd     isqrt_table - 0x800
sqrt_half_13
    dcd     0xb504f334         // sqrt(1/2) in Q32

//*****************************************************************************
//
// _IQ14mag
//
//*****************************************************************************
    section CODE__IQ14mag:CODE(2)
    thumb
    export  _IQ14mag
_IQ14mag
    //
    // Save non-volatile registers.
    //
    push    {r4, lr}

    //
    // Sum of Squares
    // Keep 64 bit version in r12lr
    // Place 32 bit version in r0
    //
    smull   r12, lr, r0, r0
    smlal   r12, lr, r1, r1

    //
    // Place upper 32 used bits of result into r0, effectively creating a
    // normalized Q32 representation.
    // This is implemented as a 64 bit clz shift followed
    // by a 32 bit clz shift.
    // Total shift amount is stored in r3
    //
    clz     r3, lr
    rsb     r2, r3, #32
    lsrs    r0, r12, r2
    lsl     r1, lr, r3
    adcs    r0, r0, r1
    ittt    pl
        clzpl   r2, r0
        lslpl   r0, r0, r2
        addpl   r3, r2, r3

    //
    // If the result is 0, bail early.
    // We are guaranteed that the result is not negative,
    // so those checks are omitted.
    //
    teq     r0, #0
    it      eq
        popeq  {r4, pc}

    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r0, #(32 - 10)
    ldr     r1, isqrt_table_14
    ldr     r1, [r1, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // 11-17 Cycles
    // r0 is Q32, r1 is Q31
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    subs    r3, r3, #2
    bmi     mag_will_overflow14
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    itt     cs
        ldrcs   r2, sqrt_half_14
        umullcs r2, r1, r2, r1

    //
    // Multiply isqrt(x) by x to get sqrt(x)
    //
    umull   r4, r0, r0, r1

    //
    // Actually denormalize per above preparation
    // Round result
    // Note:  If r3 == 0, no rounding is performed.  This potentially creates
    // an additional count worth of error if the result is nearly saturated.
    // The extra execution time to check for this is not worthwhile.
    //
    lsrs    r0, r0, r3
    adc     r0, r0, #0

    //
    // Restore r4 and return.
    ///
    pop     {r4, pc}

    //
    // The result will overflow.
    //
mag_will_overflow14
    mvn     r0, #0x80000000
    pop     {r4, pc}

    //
    // The literal pool.
    //
    alignrom 2
    data
isqrt_table_14
    dcd     isqrt_table - 0x800
sqrt_half_14
    dcd     0xb504f334         // sqrt(1/2) in Q32

//*****************************************************************************
//
// _IQ15mag
//
//*****************************************************************************
    section CODE__IQ15mag:CODE(2)
    thumb
    export  _IQ15mag
_IQ15mag
    //
    // Save non-volatile registers.
    //
    push    {r4, lr}

    //
    // Sum of Squares
    // Keep 64 bit version in r12lr
    // Place 32 bit version in r0
    //
    smull   r12, lr, r0, r0
    smlal   r12, lr, r1, r1

    //
    // Place upper 32 used bits of result into r0, effectively creating a
    // normalized Q32 representation.
    // This is implemented as a 64 bit clz shift followed
    // by a 32 bit clz shift.
    // Total shift amount is stored in r3
    //
    clz     r3, lr
    rsb     r2, r3, #32
    lsrs    r0, r12, r2
    lsl     r1, lr, r3
    adcs    r0, r0, r1
    ittt    pl
        clzpl   r2, r0
        lslpl   r0, r0, r2
        addpl   r3, r2, r3

    //
    // If the result is 0, bail early.
    // We are guaranteed that the result is not negative,
    // so those checks are omitted.
    //
    teq     r0, #0
    it      eq
        popeq  {r4, pc}

    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r0, #(32 - 10)
    ldr     r1, isqrt_table_15
    ldr     r1, [r1, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // 11-17 Cycles
    // r0 is Q32, r1 is Q31
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    subs    r3, r3, #2
    bmi     mag_will_overflow15
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    itt     cs
        ldrcs   r2, sqrt_half_15
        umullcs r2, r1, r2, r1

    //
    // Multiply isqrt(x) by x to get sqrt(x)
    //
    umull   r4, r0, r0, r1

    //
    // Actually denormalize per above preparation
    // Round result
    // Note:  If r3 == 0, no rounding is performed.  This potentially creates
    // an additional count worth of error if the result is nearly saturated.
    // The extra execution time to check for this is not worthwhile.
    //
    lsrs    r0, r0, r3
    adc     r0, r0, #0

    //
    // Restore r4 and return.
    ///
    pop     {r4, pc}

    //
    // The result will overflow.
    //
mag_will_overflow15
    mvn     r0, #0x80000000
    pop     {r4, pc}

    //
    // The literal pool.
    //
    alignrom 2
    data
isqrt_table_15
    dcd     isqrt_table - 0x800
sqrt_half_15
    dcd     0xb504f334         // sqrt(1/2) in Q32

//*****************************************************************************
//
// _IQ16mag
//
//*****************************************************************************
    section CODE__IQ16mag:CODE(2)
    thumb
    export  _IQ16mag
_IQ16mag
    //
    // Save non-volatile registers.
    //
    push    {r4, lr}

    //
    // Sum of Squares
    // Keep 64 bit version in r12lr
    // Place 32 bit version in r0
    //
    smull   r12, lr, r0, r0
    smlal   r12, lr, r1, r1

    //
    // Place upper 32 used bits of result into r0, effectively creating a
    // normalized Q32 representation.
    // This is implemented as a 64 bit clz shift followed
    // by a 32 bit clz shift.
    // Total shift amount is stored in r3
    //
    clz     r3, lr
    rsb     r2, r3, #32
    lsrs    r0, r12, r2
    lsl     r1, lr, r3
    adcs    r0, r0, r1
    ittt    pl
        clzpl   r2, r0
        lslpl   r0, r0, r2
        addpl   r3, r2, r3

    //
    // If the result is 0, bail early.
    // We are guaranteed that the result is not negative,
    // so those checks are omitted.
    //
    teq     r0, #0
    it      eq
        popeq  {r4, pc}

    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r0, #(32 - 10)
    ldr     r1, isqrt_table_16
    ldr     r1, [r1, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // 11-17 Cycles
    // r0 is Q32, r1 is Q31
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    subs    r3, r3, #2
    bmi     mag_will_overflow16
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    itt     cs
        ldrcs   r2, sqrt_half_16
        umullcs r2, r1, r2, r1

    //
    // Multiply isqrt(x) by x to get sqrt(x)
    //
    umull   r4, r0, r0, r1

    //
    // Actually denormalize per above preparation
    // Round result
    // Note:  If r3 == 0, no rounding is performed.  This potentially creates
    // an additional count worth of error if the result is nearly saturated.
    // The extra execution time to check for this is not worthwhile.
    //
    lsrs    r0, r0, r3
    adc     r0, r0, #0

    //
    // Restore r4 and return.
    ///
    pop     {r4, pc}

    //
    // The result will overflow.
    //
mag_will_overflow16
    mvn     r0, #0x80000000
    pop     {r4, pc}

    //
    // The literal pool.
    //
    alignrom 2
    data
isqrt_table_16
    dcd     isqrt_table - 0x800
sqrt_half_16
    dcd     0xb504f334         // sqrt(1/2) in Q32

//*****************************************************************************
//
// _IQ17mag
//
//*****************************************************************************
    section CODE__IQ17mag:CODE(2)
    thumb
    export  _IQ17mag
_IQ17mag
    //
    // Save non-volatile registers.
    //
    push    {r4, lr}

    //
    // Sum of Squares
    // Keep 64 bit version in r12lr
    // Place 32 bit version in r0
    //
    smull   r12, lr, r0, r0
    smlal   r12, lr, r1, r1

    //
    // Place upper 32 used bits of result into r0, effectively creating a
    // normalized Q32 representation.
    // This is implemented as a 64 bit clz shift followed
    // by a 32 bit clz shift.
    // Total shift amount is stored in r3
    //
    clz     r3, lr
    rsb     r2, r3, #32
    lsrs    r0, r12, r2
    lsl     r1, lr, r3
    adcs    r0, r0, r1
    ittt    pl
        clzpl   r2, r0
        lslpl   r0, r0, r2
        addpl   r3, r2, r3

    //
    // If the result is 0, bail early.
    // We are guaranteed that the result is not negative,
    // so those checks are omitted.
    //
    teq     r0, #0
    it      eq
        popeq  {r4, pc}

    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r0, #(32 - 10)
    ldr     r1, isqrt_table_17
    ldr     r1, [r1, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // 11-17 Cycles
    // r0 is Q32, r1 is Q31
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    subs    r3, r3, #2
    bmi     mag_will_overflow17
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    itt     cs
        ldrcs   r2, sqrt_half_17
        umullcs r2, r1, r2, r1

    //
    // Multiply isqrt(x) by x to get sqrt(x)
    //
    umull   r4, r0, r0, r1

    //
    // Actually denormalize per above preparation
    // Round result
    // Note:  If r3 == 0, no rounding is performed.  This potentially creates
    // an additional count worth of error if the result is nearly saturated.
    // The extra execution time to check for this is not worthwhile.
    //
    lsrs    r0, r0, r3
    adc     r0, r0, #0

    //
    // Restore r4 and return.
    ///
    pop     {r4, pc}

    //
    // The result will overflow.
    //
mag_will_overflow17
    mvn     r0, #0x80000000
    pop     {r4, pc}

    //
    // The literal pool.
    //
    alignrom 2
    data
isqrt_table_17
    dcd     isqrt_table - 0x800
sqrt_half_17
    dcd     0xb504f334         // sqrt(1/2) in Q32

//*****************************************************************************
//
// _IQ18mag
//
//*****************************************************************************
    section CODE__IQ18mag:CODE(2)
    thumb
    export  _IQ18mag
_IQ18mag
    //
    // Save non-volatile registers.
    //
    push    {r4, lr}

    //
    // Sum of Squares
    // Keep 64 bit version in r12lr
    // Place 32 bit version in r0
    //
    smull   r12, lr, r0, r0
    smlal   r12, lr, r1, r1

    //
    // Place upper 32 used bits of result into r0, effectively creating a
    // normalized Q32 representation.
    // This is implemented as a 64 bit clz shift followed
    // by a 32 bit clz shift.
    // Total shift amount is stored in r3
    //
    clz     r3, lr
    rsb     r2, r3, #32
    lsrs    r0, r12, r2
    lsl     r1, lr, r3
    adcs    r0, r0, r1
    ittt    pl
        clzpl   r2, r0
        lslpl   r0, r0, r2
        addpl   r3, r2, r3

    //
    // If the result is 0, bail early.
    // We are guaranteed that the result is not negative,
    // so those checks are omitted.
    //
    teq     r0, #0
    it      eq
        popeq  {r4, pc}

    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r0, #(32 - 10)
    ldr     r1, isqrt_table_18
    ldr     r1, [r1, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // 11-17 Cycles
    // r0 is Q32, r1 is Q31
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    subs    r3, r3, #2
    bmi     mag_will_overflow18
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    itt     cs
        ldrcs   r2, sqrt_half_18
        umullcs r2, r1, r2, r1

    //
    // Multiply isqrt(x) by x to get sqrt(x)
    //
    umull   r4, r0, r0, r1

    //
    // Actually denormalize per above preparation
    // Round result
    // Note:  If r3 == 0, no rounding is performed.  This potentially creates
    // an additional count worth of error if the result is nearly saturated.
    // The extra execution time to check for this is not worthwhile.
    //
    lsrs    r0, r0, r3
    adc     r0, r0, #0

    //
    // Restore r4 and return.
    ///
    pop     {r4, pc}

    //
    // The result will overflow.
    //
mag_will_overflow18
    mvn     r0, #0x80000000
    pop     {r4, pc}

    //
    // The literal pool.
    //
    alignrom 2
    data
isqrt_table_18
    dcd     isqrt_table - 0x800
sqrt_half_18
    dcd     0xb504f334         // sqrt(1/2) in Q32

//*****************************************************************************
//
// _IQ19mag
//
//*****************************************************************************
    section CODE__IQ19mag:CODE(2)
    thumb
    export  _IQ19mag
_IQ19mag
    //
    // Save non-volatile registers.
    //
    push    {r4, lr}

    //
    // Sum of Squares
    // Keep 64 bit version in r12lr
    // Place 32 bit version in r0
    //
    smull   r12, lr, r0, r0
    smlal   r12, lr, r1, r1

    //
    // Place upper 32 used bits of result into r0, effectively creating a
    // normalized Q32 representation.
    // This is implemented as a 64 bit clz shift followed
    // by a 32 bit clz shift.
    // Total shift amount is stored in r3
    //
    clz     r3, lr
    rsb     r2, r3, #32
    lsrs    r0, r12, r2
    lsl     r1, lr, r3
    adcs    r0, r0, r1
    ittt    pl
        clzpl   r2, r0
        lslpl   r0, r0, r2
        addpl   r3, r2, r3

    //
    // If the result is 0, bail early.
    // We are guaranteed that the result is not negative,
    // so those checks are omitted.
    //
    teq     r0, #0
    it      eq
        popeq  {r4, pc}

    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r0, #(32 - 10)
    ldr     r1, isqrt_table_19
    ldr     r1, [r1, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // 11-17 Cycles
    // r0 is Q32, r1 is Q31
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    subs    r3, r3, #2
    bmi     mag_will_overflow19
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    itt     cs
        ldrcs   r2, sqrt_half_19
        umullcs r2, r1, r2, r1

    //
    // Multiply isqrt(x) by x to get sqrt(x)
    //
    umull   r4, r0, r0, r1

    //
    // Actually denormalize per above preparation
    // Round result
    // Note:  If r3 == 0, no rounding is performed.  This potentially creates
    // an additional count worth of error if the result is nearly saturated.
    // The extra execution time to check for this is not worthwhile.
    //
    lsrs    r0, r0, r3
    adc     r0, r0, #0

    //
    // Restore r4 and return.
    ///
    pop     {r4, pc}

    //
    // The result will overflow.
    //
mag_will_overflow19
    mvn     r0, #0x80000000
    pop     {r4, pc}

    //
    // The literal pool.
    //
    alignrom 2
    data
isqrt_table_19
    dcd     isqrt_table - 0x800
sqrt_half_19
    dcd     0xb504f334         // sqrt(1/2) in Q32

//*****************************************************************************
//
// _IQ20mag
//
//*****************************************************************************
    section CODE__IQ20mag:CODE(2)
    thumb
    export  _IQ20mag
_IQ20mag
    //
    // Save non-volatile registers.
    //
    push    {r4, lr}

    //
    // Sum of Squares
    // Keep 64 bit version in r12lr
    // Place 32 bit version in r0
    //
    smull   r12, lr, r0, r0
    smlal   r12, lr, r1, r1

    //
    // Place upper 32 used bits of result into r0, effectively creating a
    // normalized Q32 representation.
    // This is implemented as a 64 bit clz shift followed
    // by a 32 bit clz shift.
    // Total shift amount is stored in r3
    //
    clz     r3, lr
    rsb     r2, r3, #32
    lsrs    r0, r12, r2
    lsl     r1, lr, r3
    adcs    r0, r0, r1
    ittt    pl
        clzpl   r2, r0
        lslpl   r0, r0, r2
        addpl   r3, r2, r3

    //
    // If the result is 0, bail early.
    // We are guaranteed that the result is not negative,
    // so those checks are omitted.
    //
    teq     r0, #0
    it      eq
        popeq  {r4, pc}

    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r0, #(32 - 10)
    ldr     r1, isqrt_table_20
    ldr     r1, [r1, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // 11-17 Cycles
    // r0 is Q32, r1 is Q31
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    subs    r3, r3, #2
    bmi     mag_will_overflow20
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    itt     cs
        ldrcs   r2, sqrt_half_20
        umullcs r2, r1, r2, r1

    //
    // Multiply isqrt(x) by x to get sqrt(x)
    //
    umull   r4, r0, r0, r1

    //
    // Actually denormalize per above preparation
    // Round result
    // Note:  If r3 == 0, no rounding is performed.  This potentially creates
    // an additional count worth of error if the result is nearly saturated.
    // The extra execution time to check for this is not worthwhile.
    //
    lsrs    r0, r0, r3
    adc     r0, r0, #0

    //
    // Restore r4 and return.
    ///
    pop     {r4, pc}

    //
    // The result will overflow.
    //
mag_will_overflow20
    mvn     r0, #0x80000000
    pop     {r4, pc}

    //
    // The literal pool.
    //
    alignrom 2
    data
isqrt_table_20
    dcd     isqrt_table - 0x800
sqrt_half_20
    dcd     0xb504f334         // sqrt(1/2) in Q32

//*****************************************************************************
//
// _IQ21mag
//
//*****************************************************************************
    section CODE__IQ21mag:CODE(2)
    thumb
    export  _IQ21mag
_IQ21mag
    //
    // Save non-volatile registers.
    //
    push    {r4, lr}

    //
    // Sum of Squares
    // Keep 64 bit version in r12lr
    // Place 32 bit version in r0
    //
    smull   r12, lr, r0, r0
    smlal   r12, lr, r1, r1

    //
    // Place upper 32 used bits of result into r0, effectively creating a
    // normalized Q32 representation.
    // This is implemented as a 64 bit clz shift followed
    // by a 32 bit clz shift.
    // Total shift amount is stored in r3
    //
    clz     r3, lr
    rsb     r2, r3, #32
    lsrs    r0, r12, r2
    lsl     r1, lr, r3
    adcs    r0, r0, r1
    ittt    pl
        clzpl   r2, r0
        lslpl   r0, r0, r2
        addpl   r3, r2, r3

    //
    // If the result is 0, bail early.
    // We are guaranteed that the result is not negative,
    // so those checks are omitted.
    //
    teq     r0, #0
    it      eq
        popeq  {r4, pc}

    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r0, #(32 - 10)
    ldr     r1, isqrt_table_21
    ldr     r1, [r1, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // 11-17 Cycles
    // r0 is Q32, r1 is Q31
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    subs    r3, r3, #2
    bmi     mag_will_overflow21
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    itt     cs
        ldrcs   r2, sqrt_half_21
        umullcs r2, r1, r2, r1

    //
    // Multiply isqrt(x) by x to get sqrt(x)
    //
    umull   r4, r0, r0, r1

    //
    // Actually denormalize per above preparation
    // Round result
    // Note:  If r3 == 0, no rounding is performed.  This potentially creates
    // an additional count worth of error if the result is nearly saturated.
    // The extra execution time to check for this is not worthwhile.
    //
    lsrs    r0, r0, r3
    adc     r0, r0, #0

    //
    // Restore r4 and return.
    ///
    pop     {r4, pc}

    //
    // The result will overflow.
    //
mag_will_overflow21
    mvn     r0, #0x80000000
    pop     {r4, pc}

    //
    // The literal pool.
    //
    alignrom 2
    data
isqrt_table_21
    dcd     isqrt_table - 0x800
sqrt_half_21
    dcd     0xb504f334         // sqrt(1/2) in Q32

//*****************************************************************************
//
// _IQ22mag
//
//*****************************************************************************
    section CODE__IQ22mag:CODE(2)
    thumb
    export  _IQ22mag
_IQ22mag
    //
    // Save non-volatile registers.
    //
    push    {r4, lr}

    //
    // Sum of Squares
    // Keep 64 bit version in r12lr
    // Place 32 bit version in r0
    //
    smull   r12, lr, r0, r0
    smlal   r12, lr, r1, r1

    //
    // Place upper 32 used bits of result into r0, effectively creating a
    // normalized Q32 representation.
    // This is implemented as a 64 bit clz shift followed
    // by a 32 bit clz shift.
    // Total shift amount is stored in r3
    //
    clz     r3, lr
    rsb     r2, r3, #32
    lsrs    r0, r12, r2
    lsl     r1, lr, r3
    adcs    r0, r0, r1
    ittt    pl
        clzpl   r2, r0
        lslpl   r0, r0, r2
        addpl   r3, r2, r3

    //
    // If the result is 0, bail early.
    // We are guaranteed that the result is not negative,
    // so those checks are omitted.
    //
    teq     r0, #0
    it      eq
        popeq  {r4, pc}

    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r0, #(32 - 10)
    ldr     r1, isqrt_table_22
    ldr     r1, [r1, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // 11-17 Cycles
    // r0 is Q32, r1 is Q31
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    subs    r3, r3, #2
    bmi     mag_will_overflow22
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    itt     cs
        ldrcs   r2, sqrt_half_22
        umullcs r2, r1, r2, r1

    //
    // Multiply isqrt(x) by x to get sqrt(x)
    //
    umull   r4, r0, r0, r1

    //
    // Actually denormalize per above preparation
    // Round result
    // Note:  If r3 == 0, no rounding is performed.  This potentially creates
    // an additional count worth of error if the result is nearly saturated.
    // The extra execution time to check for this is not worthwhile.
    //
    lsrs    r0, r0, r3
    adc     r0, r0, #0

    //
    // Restore r4 and return.
    ///
    pop     {r4, pc}

    //
    // The result will overflow.
    //
mag_will_overflow22
    mvn     r0, #0x80000000
    pop     {r4, pc}

    //
    // The literal pool.
    //
    alignrom 2
    data
isqrt_table_22
    dcd     isqrt_table - 0x800
sqrt_half_22
    dcd     0xb504f334         // sqrt(1/2) in Q32

//*****************************************************************************
//
// _IQ23mag
//
//*****************************************************************************
    section CODE__IQ23mag:CODE(2)
    thumb
    export  _IQ23mag
_IQ23mag
    //
    // Save non-volatile registers.
    //
    push    {r4, lr}

    //
    // Sum of Squares
    // Keep 64 bit version in r12lr
    // Place 32 bit version in r0
    //
    smull   r12, lr, r0, r0
    smlal   r12, lr, r1, r1

    //
    // Place upper 32 used bits of result into r0, effectively creating a
    // normalized Q32 representation.
    // This is implemented as a 64 bit clz shift followed
    // by a 32 bit clz shift.
    // Total shift amount is stored in r3
    //
    clz     r3, lr
    rsb     r2, r3, #32
    lsrs    r0, r12, r2
    lsl     r1, lr, r3
    adcs    r0, r0, r1
    ittt    pl
        clzpl   r2, r0
        lslpl   r0, r0, r2
        addpl   r3, r2, r3

    //
    // If the result is 0, bail early.
    // We are guaranteed that the result is not negative,
    // so those checks are omitted.
    //
    teq     r0, #0
    it      eq
        popeq  {r4, pc}

    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r0, #(32 - 10)
    ldr     r1, isqrt_table_23
    ldr     r1, [r1, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // 11-17 Cycles
    // r0 is Q32, r1 is Q31
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    subs    r3, r3, #2
    bmi     mag_will_overflow23
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    itt     cs
        ldrcs   r2, sqrt_half_23
        umullcs r2, r1, r2, r1

    //
    // Multiply isqrt(x) by x to get sqrt(x)
    //
    umull   r4, r0, r0, r1

    //
    // Actually denormalize per above preparation
    // Round result
    // Note:  If r3 == 0, no rounding is performed.  This potentially creates
    // an additional count worth of error if the result is nearly saturated.
    // The extra execution time to check for this is not worthwhile.
    //
    lsrs    r0, r0, r3
    adc     r0, r0, #0

    //
    // Restore r4 and return.
    ///
    pop     {r4, pc}

    //
    // The result will overflow.
    //
mag_will_overflow23
    mvn     r0, #0x80000000
    pop     {r4, pc}

    //
    // The literal pool.
    //
    alignrom 2
    data
isqrt_table_23
    dcd     isqrt_table - 0x800
sqrt_half_23
    dcd     0xb504f334         // sqrt(1/2) in Q32

//*****************************************************************************
//
// _IQ24mag
//
//*****************************************************************************
    section CODE__IQ24mag:CODE(2)
    thumb
    export  _IQ24mag
_IQ24mag
    //
    // Save non-volatile registers.
    //
    push    {r4, lr}

    //
    // Sum of Squares
    // Keep 64 bit version in r12lr
    // Place 32 bit version in r0
    //
    smull   r12, lr, r0, r0
    smlal   r12, lr, r1, r1

    //
    // Place upper 32 used bits of result into r0, effectively creating a
    // normalized Q32 representation.
    // This is implemented as a 64 bit clz shift followed
    // by a 32 bit clz shift.
    // Total shift amount is stored in r3
    //
    clz     r3, lr
    rsb     r2, r3, #32
    lsrs    r0, r12, r2
    lsl     r1, lr, r3
    adcs    r0, r0, r1
    ittt    pl
        clzpl   r2, r0
        lslpl   r0, r0, r2
        addpl   r3, r2, r3

    //
    // If the result is 0, bail early.
    // We are guaranteed that the result is not negative,
    // so those checks are omitted.
    //
    teq     r0, #0
    it      eq
        popeq  {r4, pc}

    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r0, #(32 - 10)
    ldr     r1, isqrt_table_24
    ldr     r1, [r1, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // 11-17 Cycles
    // r0 is Q32, r1 is Q31
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    subs    r3, r3, #2
    bmi     mag_will_overflow24
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    itt     cs
        ldrcs   r2, sqrt_half_24
        umullcs r2, r1, r2, r1

    //
    // Multiply isqrt(x) by x to get sqrt(x)
    //
    umull   r4, r0, r0, r1

    //
    // Actually denormalize per above preparation
    // Round result
    // Note:  If r3 == 0, no rounding is performed.  This potentially creates
    // an additional count worth of error if the result is nearly saturated.
    // The extra execution time to check for this is not worthwhile.
    //
    lsrs    r0, r0, r3
    adc     r0, r0, #0

    //
    // Restore r4 and return.
    ///
    pop     {r4, pc}

    //
    // The result will overflow.
    //
mag_will_overflow24
    mvn     r0, #0x80000000
    pop     {r4, pc}

    //
    // The literal pool.
    //
    alignrom 2
    data
isqrt_table_24
    dcd     isqrt_table - 0x800
sqrt_half_24
    dcd     0xb504f334         // sqrt(1/2) in Q32

//*****************************************************************************
//
// _IQ25mag
//
//*****************************************************************************
    section CODE__IQ25mag:CODE(2)
    thumb
    export  _IQ25mag
_IQ25mag
    //
    // Save non-volatile registers.
    //
    push    {r4, lr}

    //
    // Sum of Squares
    // Keep 64 bit version in r12lr
    // Place 32 bit version in r0
    //
    smull   r12, lr, r0, r0
    smlal   r12, lr, r1, r1

    //
    // Place upper 32 used bits of result into r0, effectively creating a
    // normalized Q32 representation.
    // This is implemented as a 64 bit clz shift followed
    // by a 32 bit clz shift.
    // Total shift amount is stored in r3
    //
    clz     r3, lr
    rsb     r2, r3, #32
    lsrs    r0, r12, r2
    lsl     r1, lr, r3
    adcs    r0, r0, r1
    ittt    pl
        clzpl   r2, r0
        lslpl   r0, r0, r2
        addpl   r3, r2, r3

    //
    // If the result is 0, bail early.
    // We are guaranteed that the result is not negative,
    // so those checks are omitted.
    //
    teq     r0, #0
    it      eq
        popeq  {r4, pc}

    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r0, #(32 - 10)
    ldr     r1, isqrt_table_25
    ldr     r1, [r1, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // 11-17 Cycles
    // r0 is Q32, r1 is Q31
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    subs    r3, r3, #2
    bmi     mag_will_overflow25
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    itt     cs
        ldrcs   r2, sqrt_half_25
        umullcs r2, r1, r2, r1

    //
    // Multiply isqrt(x) by x to get sqrt(x)
    //
    umull   r4, r0, r0, r1

    //
    // Actually denormalize per above preparation
    // Round result
    // Note:  If r3 == 0, no rounding is performed.  This potentially creates
    // an additional count worth of error if the result is nearly saturated.
    // The extra execution time to check for this is not worthwhile.
    //
    lsrs    r0, r0, r3
    adc     r0, r0, #0

    //
    // Restore r4 and return.
    ///
    pop     {r4, pc}

    //
    // The result will overflow.
    //
mag_will_overflow25
    mvn     r0, #0x80000000
    pop     {r4, pc}

    //
    // The literal pool.
    //
    alignrom 2
    data
isqrt_table_25
    dcd     isqrt_table - 0x800
sqrt_half_25
    dcd     0xb504f334         // sqrt(1/2) in Q32

//*****************************************************************************
//
// _IQ26mag
//
//*****************************************************************************
    section CODE__IQ26mag:CODE(2)
    thumb
    export  _IQ26mag
_IQ26mag
    //
    // Save non-volatile registers.
    //
    push    {r4, lr}

    //
    // Sum of Squares
    // Keep 64 bit version in r12lr
    // Place 32 bit version in r0
    //
    smull   r12, lr, r0, r0
    smlal   r12, lr, r1, r1

    //
    // Place upper 32 used bits of result into r0, effectively creating a
    // normalized Q32 representation.
    // This is implemented as a 64 bit clz shift followed
    // by a 32 bit clz shift.
    // Total shift amount is stored in r3
    //
    clz     r3, lr
    rsb     r2, r3, #32
    lsrs    r0, r12, r2
    lsl     r1, lr, r3
    adcs    r0, r0, r1
    ittt    pl
        clzpl   r2, r0
        lslpl   r0, r0, r2
        addpl   r3, r2, r3

    //
    // If the result is 0, bail early.
    // We are guaranteed that the result is not negative,
    // so those checks are omitted.
    //
    teq     r0, #0
    it      eq
        popeq  {r4, pc}

    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r0, #(32 - 10)
    ldr     r1, isqrt_table_26
    ldr     r1, [r1, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // 11-17 Cycles
    // r0 is Q32, r1 is Q31
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    subs    r3, r3, #2
    bmi     mag_will_overflow26
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    itt     cs
        ldrcs   r2, sqrt_half_26
        umullcs r2, r1, r2, r1

    //
    // Multiply isqrt(x) by x to get sqrt(x)
    //
    umull   r4, r0, r0, r1

    //
    // Actually denormalize per above preparation
    // Round result
    // Note:  If r3 == 0, no rounding is performed.  This potentially creates
    // an additional count worth of error if the result is nearly saturated.
    // The extra execution time to check for this is not worthwhile.
    //
    lsrs    r0, r0, r3
    adc     r0, r0, #0

    //
    // Restore r4 and return.
    ///
    pop     {r4, pc}

    //
    // The result will overflow.
    //
mag_will_overflow26
    mvn     r0, #0x80000000
    pop     {r4, pc}

    //
    // The literal pool.
    //
    alignrom 2
    data
isqrt_table_26
    dcd     isqrt_table - 0x800
sqrt_half_26
    dcd     0xb504f334         // sqrt(1/2) in Q32

//*****************************************************************************
//
// _IQ27mag
//
//*****************************************************************************
    section CODE__IQ27mag:CODE(2)
    thumb
    export  _IQ27mag
_IQ27mag
    //
    // Save non-volatile registers.
    //
    push    {r4, lr}

    //
    // Sum of Squares
    // Keep 64 bit version in r12lr
    // Place 32 bit version in r0
    //
    smull   r12, lr, r0, r0
    smlal   r12, lr, r1, r1

    //
    // Place upper 32 used bits of result into r0, effectively creating a
    // normalized Q32 representation.
    // This is implemented as a 64 bit clz shift followed
    // by a 32 bit clz shift.
    // Total shift amount is stored in r3
    //
    clz     r3, lr
    rsb     r2, r3, #32
    lsrs    r0, r12, r2
    lsl     r1, lr, r3
    adcs    r0, r0, r1
    ittt    pl
        clzpl   r2, r0
        lslpl   r0, r0, r2
        addpl   r3, r2, r3

    //
    // If the result is 0, bail early.
    // We are guaranteed that the result is not negative,
    // so those checks are omitted.
    //
    teq     r0, #0
    it      eq
        popeq  {r4, pc}

    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r0, #(32 - 10)
    ldr     r1, isqrt_table_27
    ldr     r1, [r1, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // 11-17 Cycles
    // r0 is Q32, r1 is Q31
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    subs    r3, r3, #2
    bmi     mag_will_overflow27
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    itt     cs
        ldrcs   r2, sqrt_half_27
        umullcs r2, r1, r2, r1

    //
    // Multiply isqrt(x) by x to get sqrt(x)
    //
    umull   r4, r0, r0, r1

    //
    // Actually denormalize per above preparation
    // Round result
    // Note:  If r3 == 0, no rounding is performed.  This potentially creates
    // an additional count worth of error if the result is nearly saturated.
    // The extra execution time to check for this is not worthwhile.
    //
    lsrs    r0, r0, r3
    adc     r0, r0, #0

    //
    // Restore r4 and return.
    ///
    pop     {r4, pc}

    //
    // The result will overflow.
    //
mag_will_overflow27
    mvn     r0, #0x80000000
    pop     {r4, pc}

    //
    // The literal pool.
    //
    alignrom 2
    data
isqrt_table_27
    dcd     isqrt_table - 0x800
sqrt_half_27
    dcd     0xb504f334         // sqrt(1/2) in Q32

//*****************************************************************************
//
// _IQ28mag
//
//*****************************************************************************
    section CODE__IQ28mag:CODE(2)
    thumb
    export  _IQ28mag
_IQ28mag
    //
    // Save non-volatile registers.
    //
    push    {r4, lr}

    //
    // Sum of Squares
    // Keep 64 bit version in r12lr
    // Place 32 bit version in r0
    //
    smull   r12, lr, r0, r0
    smlal   r12, lr, r1, r1

    //
    // Place upper 32 used bits of result into r0, effectively creating a
    // normalized Q32 representation.
    // This is implemented as a 64 bit clz shift followed
    // by a 32 bit clz shift.
    // Total shift amount is stored in r3
    //
    clz     r3, lr
    rsb     r2, r3, #32
    lsrs    r0, r12, r2
    lsl     r1, lr, r3
    adcs    r0, r0, r1
    ittt    pl
        clzpl   r2, r0
        lslpl   r0, r0, r2
        addpl   r3, r2, r3

    //
    // If the result is 0, bail early.
    // We are guaranteed that the result is not negative,
    // so those checks are omitted.
    //
    teq     r0, #0
    it      eq
        popeq  {r4, pc}

    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r0, #(32 - 10)
    ldr     r1, isqrt_table_28
    ldr     r1, [r1, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // 11-17 Cycles
    // r0 is Q32, r1 is Q31
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    subs    r3, r3, #2
    bmi     mag_will_overflow28
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    itt     cs
        ldrcs   r2, sqrt_half_28
        umullcs r2, r1, r2, r1

    //
    // Multiply isqrt(x) by x to get sqrt(x)
    //
    umull   r4, r0, r0, r1

    //
    // Actually denormalize per above preparation
    // Round result
    // Note:  If r3 == 0, no rounding is performed.  This potentially creates
    // an additional count worth of error if the result is nearly saturated.
    // The extra execution time to check for this is not worthwhile.
    //
    lsrs    r0, r0, r3
    adc     r0, r0, #0

    //
    // Restore r4 and return.
    ///
    pop     {r4, pc}

    //
    // The result will overflow.
    //
mag_will_overflow28
    mvn     r0, #0x80000000
    pop     {r4, pc}

    //
    // The literal pool.
    //
    alignrom 2
    data
isqrt_table_28
    dcd     isqrt_table - 0x800
sqrt_half_28
    dcd     0xb504f334         // sqrt(1/2) in Q32

//*****************************************************************************
//
// _IQ29mag
//
//*****************************************************************************
    section CODE__IQ29mag:CODE(2)
    thumb
    export  _IQ29mag
_IQ29mag
    //
    // Save non-volatile registers.
    //
    push    {r4, lr}

    //
    // Sum of Squares
    // Keep 64 bit version in r12lr
    // Place 32 bit version in r0
    //
    smull   r12, lr, r0, r0
    smlal   r12, lr, r1, r1

    //
    // Place upper 32 used bits of result into r0, effectively creating a
    // normalized Q32 representation.
    // This is implemented as a 64 bit clz shift followed
    // by a 32 bit clz shift.
    // Total shift amount is stored in r3
    //
    clz     r3, lr
    rsb     r2, r3, #32
    lsrs    r0, r12, r2
    lsl     r1, lr, r3
    adcs    r0, r0, r1
    ittt    pl
        clzpl   r2, r0
        lslpl   r0, r0, r2
        addpl   r3, r2, r3

    //
    // If the result is 0, bail early.
    // We are guaranteed that the result is not negative,
    // so those checks are omitted.
    //
    teq     r0, #0
    it      eq
        popeq  {r4, pc}

    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r0, #(32 - 10)
    ldr     r1, isqrt_table_29
    ldr     r1, [r1, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // 11-17 Cycles
    // r0 is Q32, r1 is Q31
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    subs    r3, r3, #2
    bmi     mag_will_overflow29
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    itt     cs
        ldrcs   r2, sqrt_half_29
        umullcs r2, r1, r2, r1

    //
    // Multiply isqrt(x) by x to get sqrt(x)
    //
    umull   r4, r0, r0, r1

    //
    // Actually denormalize per above preparation
    // Round result
    // Note:  If r3 == 0, no rounding is performed.  This potentially creates
    // an additional count worth of error if the result is nearly saturated.
    // The extra execution time to check for this is not worthwhile.
    //
    lsrs    r0, r0, r3
    adc     r0, r0, #0

    //
    // Restore r4 and return.
    ///
    pop     {r4, pc}

    //
    // The result will overflow.
    //
mag_will_overflow29
    mvn     r0, #0x80000000
    pop     {r4, pc}

    //
    // The literal pool.
    //
    alignrom 2
    data
isqrt_table_29
    dcd     isqrt_table - 0x800
sqrt_half_29
    dcd     0xb504f334         // sqrt(1/2) in Q32

//*****************************************************************************
//
// _IQ30mag
//
//*****************************************************************************
    section CODE__IQ30mag:CODE(2)
    thumb
    export  _IQ30mag
_IQ30mag
    //
    // Save non-volatile registers.
    //
    push    {r4, lr}

    //
    // Sum of Squares
    // Keep 64 bit version in r12lr
    // Place 32 bit version in r0
    //
    smull   r12, lr, r0, r0
    smlal   r12, lr, r1, r1

    //
    // Place upper 32 used bits of result into r0, effectively creating a
    // normalized Q32 representation.
    // This is implemented as a 64 bit clz shift followed
    // by a 32 bit clz shift.
    // Total shift amount is stored in r3
    //
    clz     r3, lr
    rsb     r2, r3, #32
    lsrs    r0, r12, r2
    lsl     r1, lr, r3
    adcs    r0, r0, r1
    ittt    pl
        clzpl   r2, r0
        lslpl   r0, r0, r2
        addpl   r3, r2, r3

    //
    // If the result is 0, bail early.
    // We are guaranteed that the result is not negative,
    // so those checks are omitted.
    //
    teq     r0, #0
    it      eq
        popeq  {r4, pc}

    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r0, #(32 - 10)
    ldr     r1, isqrt_table_30
    ldr     r1, [r1, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // 11-17 Cycles
    // r0 is Q32, r1 is Q31
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r4, r2, r0, r1
    umull   r4, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r4, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    subs    r3, r3, #2
    bmi     mag_will_overflow30
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    itt     cs
        ldrcs   r2, sqrt_half_30
        umullcs r2, r1, r2, r1

    //
    // Multiply isqrt(x) by x to get sqrt(x)
    //
    umull   r4, r0, r0, r1

    //
    // Actually denormalize per above preparation
    // Round result
    // Note:  If r3 == 0, no rounding is performed.  This potentially creates
    // an additional count worth of error if the result is nearly saturated.
    // The extra execution time to check for this is not worthwhile.
    //
    lsrs    r0, r0, r3
    adc     r0, r0, #0

    //
    // Restore r4 and return.
    ///
    pop     {r4, pc}

    //
    // The result will overflow.
    //
mag_will_overflow30
    mvn     r0, #0x80000000
    pop     {r4, pc}

    //
    // The literal pool.
    //
    alignrom 2
    data
isqrt_table_30
    dcd     isqrt_table - 0x800
sqrt_half_30
    dcd     0xb504f334         // sqrt(1/2) in Q32

    end
