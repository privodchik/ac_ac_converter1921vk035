//*****************************************************************************
//
// IQisqrt.S - Fixed point inverse square root
//
// Copyright (c) 2010 Texas Instruments Incorporated.  All rights reserved.
// TI Information - Selective Disclosure
//
//*****************************************************************************

//*****************************************************************************
//
// Function:   _IQNisqrt
//
//*****************************************************************************
//
// C Usage:    extern long _IQNisqrt(long X); // with saturation and rounding
//
//-----------------------------------------------------------------------------
//
// On Entry:   r0     = Val in IQ format
//
// Regs Used:  XAR7, XAR6, XAR5, XAR4
//             XT, P, XAR0
//
// On Exit:    r0     = 1/sqrt(X) result in IQ format
//             r0     = 0 if input is -ve or 0
//             r0     = max value "0x7FFFFFFF" if result saturates
//
// Q range:    30 to 1
//
//-----------------------------------------------------------------------------
//
// Algorithm:  The procedure for calculating "Y = 1/sqrt(X)" is as follows:
//
//      Step 1)  Normalize input to be Q32 (1.0 0.5)
//               This guarantees the result to be in the range of (2.0 1.0)
//
//      Step 2)  Obtain initial estimate from "_IQisqrtTable"
//               using the upper 9-bits of the normalized value.
//
//      Step 3) Use Newton-Raphson algorithm to improve accuracy.
//              Repeat following equation two times. First iteration
//              gives 16-bit accuracy. Second iteration gives 32-bit
//              accuracy:
//
//                     Y(n+1) = Yn*(1.5 - Yn*Yn*V/2)
//
//                     Yn = 1/sqrt(V)
//
//             Step 4) Denormalize result, round and saturate:
//
//                     Y = Yn / sqrt(2^n)
//
//-----------------------------------------------------------------------------
//
// Benchmark:
//
//  Q <= 20, L is even : 57
//  Q <= 20, L is odd  : 63
//  Q >  20, L is even : 59
//  Q >  20, L is odd  : 65
//  Negative or Zero   : 19
//  Overflow           : 17
//
//*****************************************************************************

//*****************************************************************************
//
// The isqrt table is used.
//
//*****************************************************************************
    import  isqrt_table

//*****************************************************************************
//
// _IQ1isqrt
//
//*****************************************************************************
    section CODE__IQ1isqrt:CODE(2)
    thumb
    export  _IQ1isqrt
_IQ1isqrt
    //
    // Normalize Input to (1.0 0.5) in Q32
    // If the input is zero or negative, bail out early
    // If the output will overflow, bail out early.  Some values of Q can not
    // overflow, so this escape is partially preprocessed.
    //
    clz     r3, r0
    and     r2, r3, #0x1F
    cbz     r2, isqrt_neg_or_zero1
    lsl     r0, r0, r3

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
    // r2 = Yn * N (Q31)
    //
    umull   r12, r2, r0, r1

    //
    // r2 = Yn * Yn * N /2 (Q31)
    //
    umull   r12, r2, r2, r1

    //
    // r2 = 1.5- Yn * Yn * N /2 (Q31)
    //
    rsb     r2, r2, #0xC0000000

    //
    // r1 = Yn * (1.5- Yn * Yn * N /2) (Q31)
    //
    umull   r12, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r12, r2, r0, r1
    umull   r12, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r12, r0, r2, r1
    lsl     r0, r0, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    rsb     r3, r3, #(94 - (3 * 1))
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    //
    itt     cs
        ldrcs   r2, sqrt_half_1
        umullcs r1, r0, r2, r0

    //
    // Actually denormalize per above preparation
    // Round result and prevent overflow
    //
    lsrs    r0, r0, r3
    adcs    r0, r0, #0
    it      mi
        mvnmi   r0, #0x80000000

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Returns 0 if the input value is negative or zero
    //
isqrt_neg_or_zero1
    mov     r0, #0
    bx      lr

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
// _IQ2isqrt
//
//*****************************************************************************
    section CODE__IQ2isqrt:CODE(2)
    thumb
    export  _IQ2isqrt
_IQ2isqrt
    //
    // Normalize Input to (1.0 0.5) in Q32
    // If the input is zero or negative, bail out early
    // If the output will overflow, bail out early.  Some values of Q can not
    // overflow, so this escape is partially preprocessed.
    //
    clz     r3, r0
    and     r2, r3, #0x1F
    cbz     r2, isqrt_neg_or_zero2
    lsl     r0, r0, r3

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
    // r2 = Yn * N (Q31)
    //
    umull   r12, r2, r0, r1

    //
    // r2 = Yn * Yn * N /2 (Q31)
    //
    umull   r12, r2, r2, r1

    //
    // r2 = 1.5- Yn * Yn * N /2 (Q31)
    //
    rsb     r2, r2, #0xC0000000

    //
    // r1 = Yn * (1.5- Yn * Yn * N /2) (Q31)
    //
    umull   r12, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r12, r2, r0, r1
    umull   r12, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r12, r0, r2, r1
    lsl     r0, r0, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    rsb     r3, r3, #(94 - (3 * 2))
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    //
    itt     cs
        ldrcs   r2, sqrt_half_2
        umullcs r1, r0, r2, r0

    //
    // Actually denormalize per above preparation
    // Round result and prevent overflow
    //
    lsrs    r0, r0, r3
    adcs    r0, r0, #0
    it      mi
        mvnmi   r0, #0x80000000

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Returns 0 if the input value is negative or zero
    //
isqrt_neg_or_zero2
    mov     r0, #0
    bx      lr

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
// _IQ3isqrt
//
//*****************************************************************************
    section CODE__IQ3isqrt:CODE(2)
    thumb
    export  _IQ3isqrt
_IQ3isqrt
    //
    // Normalize Input to (1.0 0.5) in Q32
    // If the input is zero or negative, bail out early
    // If the output will overflow, bail out early.  Some values of Q can not
    // overflow, so this escape is partially preprocessed.
    //
    clz     r3, r0
    and     r2, r3, #0x1F
    cbz     r2, isqrt_neg_or_zero3
    lsl     r0, r0, r3

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
    // r2 = Yn * N (Q31)
    //
    umull   r12, r2, r0, r1

    //
    // r2 = Yn * Yn * N /2 (Q31)
    //
    umull   r12, r2, r2, r1

    //
    // r2 = 1.5- Yn * Yn * N /2 (Q31)
    //
    rsb     r2, r2, #0xC0000000

    //
    // r1 = Yn * (1.5- Yn * Yn * N /2) (Q31)
    //
    umull   r12, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r12, r2, r0, r1
    umull   r12, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r12, r0, r2, r1
    lsl     r0, r0, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    rsb     r3, r3, #(94 - (3 * 3))
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    //
    itt     cs
        ldrcs   r2, sqrt_half_3
        umullcs r1, r0, r2, r0

    //
    // Actually denormalize per above preparation
    // Round result and prevent overflow
    //
    lsrs    r0, r0, r3
    adcs    r0, r0, #0
    it      mi
        mvnmi   r0, #0x80000000

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Returns 0 if the input value is negative or zero
    //
isqrt_neg_or_zero3
    mov     r0, #0
    bx      lr

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
// _IQ4isqrt
//
//*****************************************************************************
    section CODE__IQ4isqrt:CODE(2)
    thumb
    export  _IQ4isqrt
_IQ4isqrt
    //
    // Normalize Input to (1.0 0.5) in Q32
    // If the input is zero or negative, bail out early
    // If the output will overflow, bail out early.  Some values of Q can not
    // overflow, so this escape is partially preprocessed.
    //
    clz     r3, r0
    and     r2, r3, #0x1F
    cbz     r2, isqrt_neg_or_zero4
    lsl     r0, r0, r3

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
    // r2 = Yn * N (Q31)
    //
    umull   r12, r2, r0, r1

    //
    // r2 = Yn * Yn * N /2 (Q31)
    //
    umull   r12, r2, r2, r1

    //
    // r2 = 1.5- Yn * Yn * N /2 (Q31)
    //
    rsb     r2, r2, #0xC0000000

    //
    // r1 = Yn * (1.5- Yn * Yn * N /2) (Q31)
    //
    umull   r12, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r12, r2, r0, r1
    umull   r12, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r12, r0, r2, r1
    lsl     r0, r0, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    rsb     r3, r3, #(94 - (3 * 4))
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    //
    itt     cs
        ldrcs   r2, sqrt_half_4
        umullcs r1, r0, r2, r0

    //
    // Actually denormalize per above preparation
    // Round result and prevent overflow
    //
    lsrs    r0, r0, r3
    adcs    r0, r0, #0
    it      mi
        mvnmi   r0, #0x80000000

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Returns 0 if the input value is negative or zero
    //
isqrt_neg_or_zero4
    mov     r0, #0
    bx      lr

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
// _IQ5isqrt
//
//*****************************************************************************
    section CODE__IQ5isqrt:CODE(2)
    thumb
    export  _IQ5isqrt
_IQ5isqrt
    //
    // Normalize Input to (1.0 0.5) in Q32
    // If the input is zero or negative, bail out early
    // If the output will overflow, bail out early.  Some values of Q can not
    // overflow, so this escape is partially preprocessed.
    //
    clz     r3, r0
    and     r2, r3, #0x1F
    cbz     r2, isqrt_neg_or_zero5
    lsl     r0, r0, r3

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
    // r2 = Yn * N (Q31)
    //
    umull   r12, r2, r0, r1

    //
    // r2 = Yn * Yn * N /2 (Q31)
    //
    umull   r12, r2, r2, r1

    //
    // r2 = 1.5- Yn * Yn * N /2 (Q31)
    //
    rsb     r2, r2, #0xC0000000

    //
    // r1 = Yn * (1.5- Yn * Yn * N /2) (Q31)
    //
    umull   r12, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r12, r2, r0, r1
    umull   r12, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r12, r0, r2, r1
    lsl     r0, r0, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    rsb     r3, r3, #(94 - (3 * 5))
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    //
    itt     cs
        ldrcs   r2, sqrt_half_5
        umullcs r1, r0, r2, r0

    //
    // Actually denormalize per above preparation
    // Round result and prevent overflow
    //
    lsrs    r0, r0, r3
    adcs    r0, r0, #0
    it      mi
        mvnmi   r0, #0x80000000

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Returns 0 if the input value is negative or zero
    //
isqrt_neg_or_zero5
    mov     r0, #0
    bx      lr

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
// _IQ6isqrt
//
//*****************************************************************************
    section CODE__IQ6isqrt:CODE(2)
    thumb
    export  _IQ6isqrt
_IQ6isqrt
    //
    // Normalize Input to (1.0 0.5) in Q32
    // If the input is zero or negative, bail out early
    // If the output will overflow, bail out early.  Some values of Q can not
    // overflow, so this escape is partially preprocessed.
    //
    clz     r3, r0
    and     r2, r3, #0x1F
    cbz     r2, isqrt_neg_or_zero6
    lsl     r0, r0, r3

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
    // r2 = Yn * N (Q31)
    //
    umull   r12, r2, r0, r1

    //
    // r2 = Yn * Yn * N /2 (Q31)
    //
    umull   r12, r2, r2, r1

    //
    // r2 = 1.5- Yn * Yn * N /2 (Q31)
    //
    rsb     r2, r2, #0xC0000000

    //
    // r1 = Yn * (1.5- Yn * Yn * N /2) (Q31)
    //
    umull   r12, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r12, r2, r0, r1
    umull   r12, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r12, r0, r2, r1
    lsl     r0, r0, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    rsb     r3, r3, #(94 - (3 * 6))
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    //
    itt     cs
        ldrcs   r2, sqrt_half_6
        umullcs r1, r0, r2, r0

    //
    // Actually denormalize per above preparation
    // Round result and prevent overflow
    //
    lsrs    r0, r0, r3
    adcs    r0, r0, #0
    it      mi
        mvnmi   r0, #0x80000000

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Returns 0 if the input value is negative or zero
    //
isqrt_neg_or_zero6
    mov     r0, #0
    bx      lr

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
// _IQ7isqrt
//
//*****************************************************************************
    section CODE__IQ7isqrt:CODE(2)
    thumb
    export  _IQ7isqrt
_IQ7isqrt
    //
    // Normalize Input to (1.0 0.5) in Q32
    // If the input is zero or negative, bail out early
    // If the output will overflow, bail out early.  Some values of Q can not
    // overflow, so this escape is partially preprocessed.
    //
    clz     r3, r0
    and     r2, r3, #0x1F
    cbz     r2, isqrt_neg_or_zero7
    lsl     r0, r0, r3

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
    // r2 = Yn * N (Q31)
    //
    umull   r12, r2, r0, r1

    //
    // r2 = Yn * Yn * N /2 (Q31)
    //
    umull   r12, r2, r2, r1

    //
    // r2 = 1.5- Yn * Yn * N /2 (Q31)
    //
    rsb     r2, r2, #0xC0000000

    //
    // r1 = Yn * (1.5- Yn * Yn * N /2) (Q31)
    //
    umull   r12, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r12, r2, r0, r1
    umull   r12, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r12, r0, r2, r1
    lsl     r0, r0, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    rsb     r3, r3, #(94 - (3 * 7))
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    //
    itt     cs
        ldrcs   r2, sqrt_half_7
        umullcs r1, r0, r2, r0

    //
    // Actually denormalize per above preparation
    // Round result and prevent overflow
    //
    lsrs    r0, r0, r3
    adcs    r0, r0, #0
    it      mi
        mvnmi   r0, #0x80000000

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Returns 0 if the input value is negative or zero
    //
isqrt_neg_or_zero7
    mov     r0, #0
    bx      lr

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
// _IQ8isqrt
//
//*****************************************************************************
    section CODE__IQ8isqrt:CODE(2)
    thumb
    export  _IQ8isqrt
_IQ8isqrt
    //
    // Normalize Input to (1.0 0.5) in Q32
    // If the input is zero or negative, bail out early
    // If the output will overflow, bail out early.  Some values of Q can not
    // overflow, so this escape is partially preprocessed.
    //
    clz     r3, r0
    and     r2, r3, #0x1F
    cbz     r2, isqrt_neg_or_zero8
    lsl     r0, r0, r3

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
    // r2 = Yn * N (Q31)
    //
    umull   r12, r2, r0, r1

    //
    // r2 = Yn * Yn * N /2 (Q31)
    //
    umull   r12, r2, r2, r1

    //
    // r2 = 1.5- Yn * Yn * N /2 (Q31)
    //
    rsb     r2, r2, #0xC0000000

    //
    // r1 = Yn * (1.5- Yn * Yn * N /2) (Q31)
    //
    umull   r12, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r12, r2, r0, r1
    umull   r12, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r12, r0, r2, r1
    lsl     r0, r0, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    rsb     r3, r3, #(94 - (3 * 8))
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    //
    itt     cs
        ldrcs   r2, sqrt_half_8
        umullcs r1, r0, r2, r0

    //
    // Actually denormalize per above preparation
    // Round result and prevent overflow
    //
    lsrs    r0, r0, r3
    adcs    r0, r0, #0
    it      mi
        mvnmi   r0, #0x80000000

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Returns 0 if the input value is negative or zero
    //
isqrt_neg_or_zero8
    mov     r0, #0
    bx      lr

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
// _IQ9isqrt
//
//*****************************************************************************
    section CODE__IQ9isqrt:CODE(2)
    thumb
    export  _IQ9isqrt
_IQ9isqrt
    //
    // Normalize Input to (1.0 0.5) in Q32
    // If the input is zero or negative, bail out early
    // If the output will overflow, bail out early.  Some values of Q can not
    // overflow, so this escape is partially preprocessed.
    //
    clz     r3, r0
    and     r2, r3, #0x1F
    cbz     r2, isqrt_neg_or_zero9
    lsl     r0, r0, r3

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
    // r2 = Yn * N (Q31)
    //
    umull   r12, r2, r0, r1

    //
    // r2 = Yn * Yn * N /2 (Q31)
    //
    umull   r12, r2, r2, r1

    //
    // r2 = 1.5- Yn * Yn * N /2 (Q31)
    //
    rsb     r2, r2, #0xC0000000

    //
    // r1 = Yn * (1.5- Yn * Yn * N /2) (Q31)
    //
    umull   r12, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r12, r2, r0, r1
    umull   r12, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r12, r0, r2, r1
    lsl     r0, r0, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    rsb     r3, r3, #(94 - (3 * 9))
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    //
    itt     cs
        ldrcs   r2, sqrt_half_9
        umullcs r1, r0, r2, r0

    //
    // Actually denormalize per above preparation
    // Round result and prevent overflow
    //
    lsrs    r0, r0, r3
    adcs    r0, r0, #0
    it      mi
        mvnmi   r0, #0x80000000

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Returns 0 if the input value is negative or zero
    //
isqrt_neg_or_zero9
    mov     r0, #0
    bx      lr

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
// _IQ10isqrt
//
//*****************************************************************************
    section CODE__IQ10isqrt:CODE(2)
    thumb
    export  _IQ10isqrt
_IQ10isqrt
    //
    // Normalize Input to (1.0 0.5) in Q32
    // If the input is zero or negative, bail out early
    // If the output will overflow, bail out early.  Some values of Q can not
    // overflow, so this escape is partially preprocessed.
    //
    clz     r3, r0
    and     r2, r3, #0x1F
    cbz     r2, isqrt_neg_or_zero10
    lsl     r0, r0, r3

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
    // r2 = Yn * N (Q31)
    //
    umull   r12, r2, r0, r1

    //
    // r2 = Yn * Yn * N /2 (Q31)
    //
    umull   r12, r2, r2, r1

    //
    // r2 = 1.5- Yn * Yn * N /2 (Q31)
    //
    rsb     r2, r2, #0xC0000000

    //
    // r1 = Yn * (1.5- Yn * Yn * N /2) (Q31)
    //
    umull   r12, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r12, r2, r0, r1
    umull   r12, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r12, r0, r2, r1
    lsl     r0, r0, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    rsb     r3, r3, #(94 - (3 * 10))
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    //
    itt     cs
        ldrcs   r2, sqrt_half_10
        umullcs r1, r0, r2, r0

    //
    // Actually denormalize per above preparation
    // Round result and prevent overflow
    //
    lsrs    r0, r0, r3
    adcs    r0, r0, #0
    it      mi
        mvnmi   r0, #0x80000000

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Returns 0 if the input value is negative or zero
    //
isqrt_neg_or_zero10
    mov     r0, #0
    bx      lr

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
// _IQ11isqrt
//
//*****************************************************************************
    section CODE__IQ11isqrt:CODE(2)
    thumb
    export  _IQ11isqrt
_IQ11isqrt
    //
    // Normalize Input to (1.0 0.5) in Q32
    // If the input is zero or negative, bail out early
    // If the output will overflow, bail out early.  Some values of Q can not
    // overflow, so this escape is partially preprocessed.
    //
    clz     r3, r0
    and     r2, r3, #0x1F
    cbz     r2, isqrt_neg_or_zero11
    lsl     r0, r0, r3

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
    // r2 = Yn * N (Q31)
    //
    umull   r12, r2, r0, r1

    //
    // r2 = Yn * Yn * N /2 (Q31)
    //
    umull   r12, r2, r2, r1

    //
    // r2 = 1.5- Yn * Yn * N /2 (Q31)
    //
    rsb     r2, r2, #0xC0000000

    //
    // r1 = Yn * (1.5- Yn * Yn * N /2) (Q31)
    //
    umull   r12, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r12, r2, r0, r1
    umull   r12, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r12, r0, r2, r1
    lsl     r0, r0, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    rsb     r3, r3, #(94 - (3 * 11))
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    //
    itt     cs
        ldrcs   r2, sqrt_half_11
        umullcs r1, r0, r2, r0

    //
    // Actually denormalize per above preparation
    // Round result and prevent overflow
    //
    lsrs    r0, r0, r3
    adcs    r0, r0, #0
    it      mi
        mvnmi   r0, #0x80000000

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Returns 0 if the input value is negative or zero
    //
isqrt_neg_or_zero11
    mov     r0, #0
    bx      lr

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
// _IQ12isqrt
//
//*****************************************************************************
    section CODE__IQ12isqrt:CODE(2)
    thumb
    export  _IQ12isqrt
_IQ12isqrt
    //
    // Normalize Input to (1.0 0.5) in Q32
    // If the input is zero or negative, bail out early
    // If the output will overflow, bail out early.  Some values of Q can not
    // overflow, so this escape is partially preprocessed.
    //
    clz     r3, r0
    and     r2, r3, #0x1F
    cbz     r2, isqrt_neg_or_zero12
    lsl     r0, r0, r3

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
    // r2 = Yn * N (Q31)
    //
    umull   r12, r2, r0, r1

    //
    // r2 = Yn * Yn * N /2 (Q31)
    //
    umull   r12, r2, r2, r1

    //
    // r2 = 1.5- Yn * Yn * N /2 (Q31)
    //
    rsb     r2, r2, #0xC0000000

    //
    // r1 = Yn * (1.5- Yn * Yn * N /2) (Q31)
    //
    umull   r12, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r12, r2, r0, r1
    umull   r12, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r12, r0, r2, r1
    lsl     r0, r0, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    rsb     r3, r3, #(94 - (3 * 12))
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    //
    itt     cs
        ldrcs   r2, sqrt_half_12
        umullcs r1, r0, r2, r0

    //
    // Actually denormalize per above preparation
    // Round result and prevent overflow
    //
    lsrs    r0, r0, r3
    adcs    r0, r0, #0
    it      mi
        mvnmi   r0, #0x80000000

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Returns 0 if the input value is negative or zero
    //
isqrt_neg_or_zero12
    mov     r0, #0
    bx      lr

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
// _IQ13isqrt
//
//*****************************************************************************
    section CODE__IQ13isqrt:CODE(2)
    thumb
    export  _IQ13isqrt
_IQ13isqrt
    //
    // Normalize Input to (1.0 0.5) in Q32
    // If the input is zero or negative, bail out early
    // If the output will overflow, bail out early.  Some values of Q can not
    // overflow, so this escape is partially preprocessed.
    //
    clz     r3, r0
    and     r2, r3, #0x1F
    cbz     r2, isqrt_neg_or_zero13
    lsl     r0, r0, r3

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
    // r2 = Yn * N (Q31)
    //
    umull   r12, r2, r0, r1

    //
    // r2 = Yn * Yn * N /2 (Q31)
    //
    umull   r12, r2, r2, r1

    //
    // r2 = 1.5- Yn * Yn * N /2 (Q31)
    //
    rsb     r2, r2, #0xC0000000

    //
    // r1 = Yn * (1.5- Yn * Yn * N /2) (Q31)
    //
    umull   r12, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r12, r2, r0, r1
    umull   r12, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r12, r0, r2, r1
    lsl     r0, r0, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    rsb     r3, r3, #(94 - (3 * 13))
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    //
    itt     cs
        ldrcs   r2, sqrt_half_13
        umullcs r1, r0, r2, r0

    //
    // Actually denormalize per above preparation
    // Round result and prevent overflow
    //
    lsrs    r0, r0, r3
    adcs    r0, r0, #0
    it      mi
        mvnmi   r0, #0x80000000

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Returns 0 if the input value is negative or zero
    //
isqrt_neg_or_zero13
    mov     r0, #0
    bx      lr

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
// _IQ14isqrt
//
//*****************************************************************************
    section CODE__IQ14isqrt:CODE(2)
    thumb
    export  _IQ14isqrt
_IQ14isqrt
    //
    // Normalize Input to (1.0 0.5) in Q32
    // If the input is zero or negative, bail out early
    // If the output will overflow, bail out early.  Some values of Q can not
    // overflow, so this escape is partially preprocessed.
    //
    clz     r3, r0
    and     r2, r3, #0x1F
    cbz     r2, isqrt_neg_or_zero14
    lsl     r0, r0, r3

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
    // r2 = Yn * N (Q31)
    //
    umull   r12, r2, r0, r1

    //
    // r2 = Yn * Yn * N /2 (Q31)
    //
    umull   r12, r2, r2, r1

    //
    // r2 = 1.5- Yn * Yn * N /2 (Q31)
    //
    rsb     r2, r2, #0xC0000000

    //
    // r1 = Yn * (1.5- Yn * Yn * N /2) (Q31)
    //
    umull   r12, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r12, r2, r0, r1
    umull   r12, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r12, r0, r2, r1
    lsl     r0, r0, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    rsb     r3, r3, #(94 - (3 * 14))
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    //
    itt     cs
        ldrcs   r2, sqrt_half_14
        umullcs r1, r0, r2, r0

    //
    // Actually denormalize per above preparation
    // Round result and prevent overflow
    //
    lsrs    r0, r0, r3
    adcs    r0, r0, #0
    it      mi
        mvnmi   r0, #0x80000000

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Returns 0 if the input value is negative or zero
    //
isqrt_neg_or_zero14
    mov     r0, #0
    bx      lr

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
// _IQ15isqrt
//
//*****************************************************************************
    section CODE__IQ15isqrt:CODE(2)
    thumb
    export  _IQ15isqrt
_IQ15isqrt
    //
    // Normalize Input to (1.0 0.5) in Q32
    // If the input is zero or negative, bail out early
    // If the output will overflow, bail out early.  Some values of Q can not
    // overflow, so this escape is partially preprocessed.
    //
    clz     r3, r0
    and     r2, r3, #0x1F
    cbz     r2, isqrt_neg_or_zero15
    lsl     r0, r0, r3

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
    // r2 = Yn * N (Q31)
    //
    umull   r12, r2, r0, r1

    //
    // r2 = Yn * Yn * N /2 (Q31)
    //
    umull   r12, r2, r2, r1

    //
    // r2 = 1.5- Yn * Yn * N /2 (Q31)
    //
    rsb     r2, r2, #0xC0000000

    //
    // r1 = Yn * (1.5- Yn * Yn * N /2) (Q31)
    //
    umull   r12, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r12, r2, r0, r1
    umull   r12, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r12, r0, r2, r1
    lsl     r0, r0, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    rsb     r3, r3, #(94 - (3 * 15))
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    //
    itt     cs
        ldrcs   r2, sqrt_half_15
        umullcs r1, r0, r2, r0

    //
    // Actually denormalize per above preparation
    // Round result and prevent overflow
    //
    lsrs    r0, r0, r3
    adcs    r0, r0, #0
    it      mi
        mvnmi   r0, #0x80000000

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Returns 0 if the input value is negative or zero
    //
isqrt_neg_or_zero15
    mov     r0, #0
    bx      lr

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
// _IQ16isqrt
//
//*****************************************************************************
    section CODE__IQ16isqrt:CODE(2)
    thumb
    export  _IQ16isqrt
_IQ16isqrt
    //
    // Normalize Input to (1.0 0.5) in Q32
    // If the input is zero or negative, bail out early
    // If the output will overflow, bail out early.  Some values of Q can not
    // overflow, so this escape is partially preprocessed.
    //
    clz     r3, r0
    and     r2, r3, #0x1F
    cbz     r2, isqrt_neg_or_zero16
    lsl     r0, r0, r3

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
    // r2 = Yn * N (Q31)
    //
    umull   r12, r2, r0, r1

    //
    // r2 = Yn * Yn * N /2 (Q31)
    //
    umull   r12, r2, r2, r1

    //
    // r2 = 1.5- Yn * Yn * N /2 (Q31)
    //
    rsb     r2, r2, #0xC0000000

    //
    // r1 = Yn * (1.5- Yn * Yn * N /2) (Q31)
    //
    umull   r12, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r12, r2, r0, r1
    umull   r12, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r12, r0, r2, r1
    lsl     r0, r0, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    rsb     r3, r3, #(94 - (3 * 16))
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    //
    itt     cs
        ldrcs   r2, sqrt_half_16
        umullcs r1, r0, r2, r0

    //
    // Actually denormalize per above preparation
    // Round result and prevent overflow
    //
    lsrs    r0, r0, r3
    adcs    r0, r0, #0
    it      mi
        mvnmi   r0, #0x80000000

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Returns 0 if the input value is negative or zero
    //
isqrt_neg_or_zero16
    mov     r0, #0
    bx      lr

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
// _IQ17isqrt
//
//*****************************************************************************
    section CODE__IQ17isqrt:CODE(2)
    thumb
    export  _IQ17isqrt
_IQ17isqrt
    //
    // Normalize Input to (1.0 0.5) in Q32
    // If the input is zero or negative, bail out early
    // If the output will overflow, bail out early.  Some values of Q can not
    // overflow, so this escape is partially preprocessed.
    //
    clz     r3, r0
    and     r2, r3, #0x1F
    cbz     r2, isqrt_neg_or_zero17
    lsl     r0, r0, r3

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
    // r2 = Yn * N (Q31)
    //
    umull   r12, r2, r0, r1

    //
    // r2 = Yn * Yn * N /2 (Q31)
    //
    umull   r12, r2, r2, r1

    //
    // r2 = 1.5- Yn * Yn * N /2 (Q31)
    //
    rsb     r2, r2, #0xC0000000

    //
    // r1 = Yn * (1.5- Yn * Yn * N /2) (Q31)
    //
    umull   r12, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r12, r2, r0, r1
    umull   r12, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r12, r0, r2, r1
    lsl     r0, r0, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    rsb     r3, r3, #(94 - (3 * 17))
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    //
    itt     cs
        ldrcs   r2, sqrt_half_17
        umullcs r1, r0, r2, r0

    //
    // Actually denormalize per above preparation
    // Round result and prevent overflow
    //
    lsrs    r0, r0, r3
    adcs    r0, r0, #0
    it      mi
        mvnmi   r0, #0x80000000

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Returns 0 if the input value is negative or zero
    //
isqrt_neg_or_zero17
    mov     r0, #0
    bx      lr

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
// _IQ18isqrt
//
//*****************************************************************************
    section CODE__IQ18isqrt:CODE(2)
    thumb
    export  _IQ18isqrt
_IQ18isqrt
    //
    // Normalize Input to (1.0 0.5) in Q32
    // If the input is zero or negative, bail out early
    // If the output will overflow, bail out early.  Some values of Q can not
    // overflow, so this escape is partially preprocessed.
    //
    clz     r3, r0
    and     r2, r3, #0x1F
    cbz     r2, isqrt_neg_or_zero18
    lsl     r0, r0, r3

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
    // r2 = Yn * N (Q31)
    //
    umull   r12, r2, r0, r1

    //
    // r2 = Yn * Yn * N /2 (Q31)
    //
    umull   r12, r2, r2, r1

    //
    // r2 = 1.5- Yn * Yn * N /2 (Q31)
    //
    rsb     r2, r2, #0xC0000000

    //
    // r1 = Yn * (1.5- Yn * Yn * N /2) (Q31)
    //
    umull   r12, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r12, r2, r0, r1
    umull   r12, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r12, r0, r2, r1
    lsl     r0, r0, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    rsb     r3, r3, #(94 - (3 * 18))
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    //
    itt     cs
        ldrcs   r2, sqrt_half_18
        umullcs r1, r0, r2, r0

    //
    // Actually denormalize per above preparation
    // Round result and prevent overflow
    //
    lsrs    r0, r0, r3
    adcs    r0, r0, #0
    it      mi
        mvnmi   r0, #0x80000000

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Returns 0 if the input value is negative or zero
    //
isqrt_neg_or_zero18
    mov     r0, #0
    bx      lr

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
// _IQ19isqrt
//
//*****************************************************************************
    section CODE__IQ19isqrt:CODE(2)
    thumb
    export  _IQ19isqrt
_IQ19isqrt
    //
    // Normalize Input to (1.0 0.5) in Q32
    // If the input is zero or negative, bail out early
    // If the output will overflow, bail out early.  Some values of Q can not
    // overflow, so this escape is partially preprocessed.
    //
    clz     r3, r0
    and     r2, r3, #0x1F
    cbz     r2, isqrt_neg_or_zero19
    lsl     r0, r0, r3

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
    // r2 = Yn * N (Q31)
    //
    umull   r12, r2, r0, r1

    //
    // r2 = Yn * Yn * N /2 (Q31)
    //
    umull   r12, r2, r2, r1

    //
    // r2 = 1.5- Yn * Yn * N /2 (Q31)
    //
    rsb     r2, r2, #0xC0000000

    //
    // r1 = Yn * (1.5- Yn * Yn * N /2) (Q31)
    //
    umull   r12, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r12, r2, r0, r1
    umull   r12, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r12, r0, r2, r1
    lsl     r0, r0, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    rsb     r3, r3, #(94 - (3 * 19))
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    //
    itt     cs
        ldrcs   r2, sqrt_half_19
        umullcs r1, r0, r2, r0

    //
    // Actually denormalize per above preparation
    // Round result and prevent overflow
    //
    lsrs    r0, r0, r3
    adcs    r0, r0, #0
    it      mi
        mvnmi   r0, #0x80000000

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Returns 0 if the input value is negative or zero
    //
isqrt_neg_or_zero19
    mov     r0, #0
    bx      lr

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
// _IQ20isqrt
//
//*****************************************************************************
    section CODE__IQ20isqrt:CODE(2)
    thumb
    export  _IQ20isqrt
_IQ20isqrt
    //
    // Normalize Input to (1.0 0.5) in Q32
    // If the input is zero or negative, bail out early
    // If the output will overflow, bail out early.  Some values of Q can not
    // overflow, so this escape is partially preprocessed.
    //
    clz     r3, r0
    and     r2, r3, #0x1F
    cbz     r2, isqrt_neg_or_zero20
    lsl     r0, r0, r3

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
    // r2 = Yn * N (Q31)
    //
    umull   r12, r2, r0, r1

    //
    // r2 = Yn * Yn * N /2 (Q31)
    //
    umull   r12, r2, r2, r1

    //
    // r2 = 1.5- Yn * Yn * N /2 (Q31)
    //
    rsb     r2, r2, #0xC0000000

    //
    // r1 = Yn * (1.5- Yn * Yn * N /2) (Q31)
    //
    umull   r12, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r12, r2, r0, r1
    umull   r12, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r12, r0, r2, r1
    lsl     r0, r0, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    rsb     r3, r3, #(94 - (3 * 20))
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    //
    itt     cs
        ldrcs   r2, sqrt_half_20
        umullcs r1, r0, r2, r0

    //
    // Actually denormalize per above preparation
    // Round result and prevent overflow
    //
    lsrs    r0, r0, r3
    adcs    r0, r0, #0
    it      mi
        mvnmi   r0, #0x80000000

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Returns 0 if the input value is negative or zero
    //
isqrt_neg_or_zero20
    mov     r0, #0
    bx      lr

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
// _IQ21isqrt
//
//*****************************************************************************
    section CODE__IQ21isqrt:CODE(2)
    thumb
    export  _IQ21isqrt
_IQ21isqrt
    //
    // Normalize Input to (1.0 0.5) in Q32
    // If the input is zero or negative, bail out early
    // If the output will overflow, bail out early.  Some values of Q can not
    // overflow, so this escape is partially preprocessed.
    //
    clz     r3, r0
    and     r2, r3, #0x1F
    cbz     r2, isqrt_neg_or_zero21
    cmp     r3, #94-3*21
    bcs     isqrt_will_overflow21
    lsl     r0, r0, r3

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
    // r2 = Yn * N (Q31)
    //
    umull   r12, r2, r0, r1

    //
    // r2 = Yn * Yn * N /2 (Q31)
    //
    umull   r12, r2, r2, r1

    //
    // r2 = 1.5- Yn * Yn * N /2 (Q31)
    //
    rsb     r2, r2, #0xC0000000

    //
    // r1 = Yn * (1.5- Yn * Yn * N /2) (Q31)
    //
    umull   r12, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r12, r2, r0, r1
    umull   r12, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r12, r0, r2, r1
    lsl     r0, r0, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    rsb     r3, r3, #(94 - (3 * 21))
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    //
    itt     cs
        ldrcs   r2, sqrt_half_21
        umullcs r1, r0, r2, r0

    //
    // Actually denormalize per above preparation
    // Round result and prevent overflow
    //
    lsrs    r0, r0, r3
    adcs    r0, r0, #0
    it      mi
        mvnmi   r0, #0x80000000

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Returns 0 if the input value is negative or zero
    //
isqrt_neg_or_zero21
    mov     r0, #0
    bx      lr
isqrt_will_overflow21
    mvn     r0, #0x80000000
    bx      lr

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
// _IQ22isqrt
//
//*****************************************************************************
    section CODE__IQ22isqrt:CODE(2)
    thumb
    export  _IQ22isqrt
_IQ22isqrt
    //
    // Normalize Input to (1.0 0.5) in Q32
    // If the input is zero or negative, bail out early
    // If the output will overflow, bail out early.  Some values of Q can not
    // overflow, so this escape is partially preprocessed.
    //
    clz     r3, r0
    and     r2, r3, #0x1F
    cbz     r2, isqrt_neg_or_zero22
    cmp     r3, #94-3*22
    bcs     isqrt_will_overflow22
    lsl     r0, r0, r3

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
    // r2 = Yn * N (Q31)
    //
    umull   r12, r2, r0, r1

    //
    // r2 = Yn * Yn * N /2 (Q31)
    //
    umull   r12, r2, r2, r1

    //
    // r2 = 1.5- Yn * Yn * N /2 (Q31)
    //
    rsb     r2, r2, #0xC0000000

    //
    // r1 = Yn * (1.5- Yn * Yn * N /2) (Q31)
    //
    umull   r12, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r12, r2, r0, r1
    umull   r12, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r12, r0, r2, r1
    lsl     r0, r0, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    rsb     r3, r3, #(94 - (3 * 22))
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    //
    itt     cs
        ldrcs   r2, sqrt_half_22
        umullcs r1, r0, r2, r0

    //
    // Actually denormalize per above preparation
    // Round result and prevent overflow
    //
    lsrs    r0, r0, r3
    adcs    r0, r0, #0
    it      mi
        mvnmi   r0, #0x80000000

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Returns 0 if the input value is negative or zero
    //
isqrt_neg_or_zero22
    mov     r0, #0
    bx      lr
isqrt_will_overflow22
    mvn     r0, #0x80000000
    bx      lr

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
// _IQ23isqrt
//
//*****************************************************************************
    section CODE__IQ23isqrt:CODE(2)
    thumb
    export  _IQ23isqrt
_IQ23isqrt
    //
    // Normalize Input to (1.0 0.5) in Q32
    // If the input is zero or negative, bail out early
    // If the output will overflow, bail out early.  Some values of Q can not
    // overflow, so this escape is partially preprocessed.
    //
    clz     r3, r0
    and     r2, r3, #0x1F
    cbz     r2, isqrt_neg_or_zero23
    cmp     r3, #94-3*23
    bcs     isqrt_will_overflow23
    lsl     r0, r0, r3

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
    // r2 = Yn * N (Q31)
    //
    umull   r12, r2, r0, r1

    //
    // r2 = Yn * Yn * N /2 (Q31)
    //
    umull   r12, r2, r2, r1

    //
    // r2 = 1.5- Yn * Yn * N /2 (Q31)
    //
    rsb     r2, r2, #0xC0000000

    //
    // r1 = Yn * (1.5- Yn * Yn * N /2) (Q31)
    //
    umull   r12, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r12, r2, r0, r1
    umull   r12, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r12, r0, r2, r1
    lsl     r0, r0, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    rsb     r3, r3, #(94 - (3 * 23))
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    //
    itt     cs
        ldrcs   r2, sqrt_half_23
        umullcs r1, r0, r2, r0

    //
    // Actually denormalize per above preparation
    // Round result and prevent overflow
    //
    lsrs    r0, r0, r3
    adcs    r0, r0, #0
    it      mi
        mvnmi   r0, #0x80000000

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Returns 0 if the input value is negative or zero
    //
isqrt_neg_or_zero23
    mov     r0, #0
    bx      lr
isqrt_will_overflow23
    mvn     r0, #0x80000000
    bx      lr

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
// _IQ24isqrt
//
//*****************************************************************************
    section CODE__IQ24isqrt:CODE(2)
    thumb
    export  _IQ24isqrt
_IQ24isqrt
    //
    // Normalize Input to (1.0 0.5) in Q32
    // If the input is zero or negative, bail out early
    // If the output will overflow, bail out early.  Some values of Q can not
    // overflow, so this escape is partially preprocessed.
    //
    clz     r3, r0
    and     r2, r3, #0x1F
    cbz     r2, isqrt_neg_or_zero24
    cmp     r3, #94-3*24
    bcs     isqrt_will_overflow24
    lsl     r0, r0, r3

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
    // r2 = Yn * N (Q31)
    //
    umull   r12, r2, r0, r1

    //
    // r2 = Yn * Yn * N /2 (Q31)
    //
    umull   r12, r2, r2, r1

    //
    // r2 = 1.5- Yn * Yn * N /2 (Q31)
    //
    rsb     r2, r2, #0xC0000000

    //
    // r1 = Yn * (1.5- Yn * Yn * N /2) (Q31)
    //
    umull   r12, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r12, r2, r0, r1
    umull   r12, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r12, r0, r2, r1
    lsl     r0, r0, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    rsb     r3, r3, #(94 - (3 * 24))
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    //
    itt     cs
        ldrcs   r2, sqrt_half_24
        umullcs r1, r0, r2, r0

    //
    // Actually denormalize per above preparation
    // Round result and prevent overflow
    //
    lsrs    r0, r0, r3
    adcs    r0, r0, #0
    it      mi
        mvnmi   r0, #0x80000000

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Returns 0 if the input value is negative or zero
    //
isqrt_neg_or_zero24
    mov     r0, #0
    bx      lr
isqrt_will_overflow24
    mvn     r0, #0x80000000
    bx      lr

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
// _IQ25isqrt
//
//*****************************************************************************
    section CODE__IQ25isqrt:CODE(2)
    thumb
    export  _IQ25isqrt
_IQ25isqrt
    //
    // Normalize Input to (1.0 0.5) in Q32
    // If the input is zero or negative, bail out early
    // If the output will overflow, bail out early.  Some values of Q can not
    // overflow, so this escape is partially preprocessed.
    //
    clz     r3, r0
    and     r2, r3, #0x1F
    cbz     r2, isqrt_neg_or_zero25
    cmp     r3, #94-3*25
    bcs     isqrt_will_overflow25
    lsl     r0, r0, r3

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
    // r2 = Yn * N (Q31)
    //
    umull   r12, r2, r0, r1

    //
    // r2 = Yn * Yn * N /2 (Q31)
    //
    umull   r12, r2, r2, r1

    //
    // r2 = 1.5- Yn * Yn * N /2 (Q31)
    //
    rsb     r2, r2, #0xC0000000

    //
    // r1 = Yn * (1.5- Yn * Yn * N /2) (Q31)
    //
    umull   r12, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r12, r2, r0, r1
    umull   r12, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r12, r0, r2, r1
    lsl     r0, r0, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    rsb     r3, r3, #(94 - (3 * 25))
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    //
    itt     cs
        ldrcs   r2, sqrt_half_25
        umullcs r1, r0, r2, r0

    //
    // Actually denormalize per above preparation
    // Round result and prevent overflow
    //
    lsrs    r0, r0, r3
    adcs    r0, r0, #0
    it      mi
        mvnmi   r0, #0x80000000

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Returns 0 if the input value is negative or zero
    //
isqrt_neg_or_zero25
    mov     r0, #0
    bx      lr
isqrt_will_overflow25
    mvn     r0, #0x80000000
    bx      lr

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
// _IQ26isqrt
//
//*****************************************************************************
    section CODE__IQ26isqrt:CODE(2)
    thumb
    export  _IQ26isqrt
_IQ26isqrt
    //
    // Normalize Input to (1.0 0.5) in Q32
    // If the input is zero or negative, bail out early
    // If the output will overflow, bail out early.  Some values of Q can not
    // overflow, so this escape is partially preprocessed.
    //
    clz     r3, r0
    and     r2, r3, #0x1F
    cbz     r2, isqrt_neg_or_zero26
    cmp     r3, #94-3*26
    bcs     isqrt_will_overflow26
    lsl     r0, r0, r3

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
    // r2 = Yn * N (Q31)
    //
    umull   r12, r2, r0, r1

    //
    // r2 = Yn * Yn * N /2 (Q31)
    //
    umull   r12, r2, r2, r1

    //
    // r2 = 1.5- Yn * Yn * N /2 (Q31)
    //
    rsb     r2, r2, #0xC0000000

    //
    // r1 = Yn * (1.5- Yn * Yn * N /2) (Q31)
    //
    umull   r12, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r12, r2, r0, r1
    umull   r12, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r12, r0, r2, r1
    lsl     r0, r0, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    rsb     r3, r3, #(94 - (3 * 26))
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    //
    itt     cs
        ldrcs   r2, sqrt_half_26
        umullcs r1, r0, r2, r0

    //
    // Actually denormalize per above preparation
    // Round result and prevent overflow
    //
    lsrs    r0, r0, r3
    adcs    r0, r0, #0
    it      mi
        mvnmi   r0, #0x80000000

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Returns 0 if the input value is negative or zero
    //
isqrt_neg_or_zero26
    mov     r0, #0
    bx      lr
isqrt_will_overflow26
    mvn     r0, #0x80000000
    bx      lr

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
// _IQ27isqrt
//
//*****************************************************************************
    section CODE__IQ27isqrt:CODE(2)
    thumb
    export  _IQ27isqrt
_IQ27isqrt
    //
    // Normalize Input to (1.0 0.5) in Q32
    // If the input is zero or negative, bail out early
    // If the output will overflow, bail out early.  Some values of Q can not
    // overflow, so this escape is partially preprocessed.
    //
    clz     r3, r0
    and     r2, r3, #0x1F
    cbz     r2, isqrt_neg_or_zero27
    cmp     r3, #94-3*27
    bcs     isqrt_will_overflow27
    lsl     r0, r0, r3

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
    // r2 = Yn * N (Q31)
    //
    umull   r12, r2, r0, r1

    //
    // r2 = Yn * Yn * N /2 (Q31)
    //
    umull   r12, r2, r2, r1

    //
    // r2 = 1.5- Yn * Yn * N /2 (Q31)
    //
    rsb     r2, r2, #0xC0000000

    //
    // r1 = Yn * (1.5- Yn * Yn * N /2) (Q31)
    //
    umull   r12, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r12, r2, r0, r1
    umull   r12, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r12, r0, r2, r1
    lsl     r0, r0, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    rsb     r3, r3, #(94 - (3 * 27))
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    //
    itt     cs
        ldrcs   r2, sqrt_half_27
        umullcs r1, r0, r2, r0

    //
    // Actually denormalize per above preparation
    // Round result and prevent overflow
    //
    lsrs    r0, r0, r3
    adcs    r0, r0, #0
    it      mi
        mvnmi   r0, #0x80000000

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Returns 0 if the input value is negative or zero
    //
isqrt_neg_or_zero27
    mov     r0, #0
    bx      lr
isqrt_will_overflow27
    mvn     r0, #0x80000000
    bx      lr

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
// _IQ28isqrt
//
//*****************************************************************************
    section CODE__IQ28isqrt:CODE(2)
    thumb
    export  _IQ28isqrt
_IQ28isqrt
    //
    // Normalize Input to (1.0 0.5) in Q32
    // If the input is zero or negative, bail out early
    // If the output will overflow, bail out early.  Some values of Q can not
    // overflow, so this escape is partially preprocessed.
    //
    clz     r3, r0
    and     r2, r3, #0x1F
    cbz     r2, isqrt_neg_or_zero28
    cmp     r3, #94-3*28
    bcs     isqrt_will_overflow28
    lsl     r0, r0, r3

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
    // r2 = Yn * N (Q31)
    //
    umull   r12, r2, r0, r1

    //
    // r2 = Yn * Yn * N /2 (Q31)
    //
    umull   r12, r2, r2, r1

    //
    // r2 = 1.5- Yn * Yn * N /2 (Q31)
    //
    rsb     r2, r2, #0xC0000000

    //
    // r1 = Yn * (1.5- Yn * Yn * N /2) (Q31)
    //
    umull   r12, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r12, r2, r0, r1
    umull   r12, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r12, r0, r2, r1
    lsl     r0, r0, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    rsb     r3, r3, #(94 - (3 * 28))
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    //
    itt     cs
        ldrcs   r2, sqrt_half_28
        umullcs r1, r0, r2, r0

    //
    // Actually denormalize per above preparation
    // Round result and prevent overflow
    //
    lsrs    r0, r0, r3
    adcs    r0, r0, #0
    it      mi
        mvnmi   r0, #0x80000000

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Returns 0 if the input value is negative or zero
    //
isqrt_neg_or_zero28
    mov     r0, #0
    bx      lr
isqrt_will_overflow28
    mvn     r0, #0x80000000
    bx      lr

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
// _IQ29isqrt
//
//*****************************************************************************
    section CODE__IQ29isqrt:CODE(2)
    thumb
    export  _IQ29isqrt
_IQ29isqrt
    //
    // Normalize Input to (1.0 0.5) in Q32
    // If the input is zero or negative, bail out early
    // If the output will overflow, bail out early.  Some values of Q can not
    // overflow, so this escape is partially preprocessed.
    //
    clz     r3, r0
    and     r2, r3, #0x1F
    cbz     r2, isqrt_neg_or_zero29
    cmp     r3, #94-3*29
    bcs     isqrt_will_overflow29
    lsl     r0, r0, r3

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
    // r2 = Yn * N (Q31)
    //
    umull   r12, r2, r0, r1

    //
    // r2 = Yn * Yn * N /2 (Q31)
    //
    umull   r12, r2, r2, r1

    //
    // r2 = 1.5- Yn * Yn * N /2 (Q31)
    //
    rsb     r2, r2, #0xC0000000

    //
    // r1 = Yn * (1.5- Yn * Yn * N /2) (Q31)
    //
    umull   r12, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r12, r2, r0, r1
    umull   r12, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r12, r0, r2, r1
    lsl     r0, r0, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    rsb     r3, r3, #(94 - (3 * 29))
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    //
    itt     cs
        ldrcs   r2, sqrt_half_29
        umullcs r1, r0, r2, r0

    //
    // Actually denormalize per above preparation
    // Round result and prevent overflow
    //
    lsrs    r0, r0, r3
    adcs    r0, r0, #0
    it      mi
        mvnmi   r0, #0x80000000

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Returns 0 if the input value is negative or zero
    //
isqrt_neg_or_zero29
    mov     r0, #0
    bx      lr
isqrt_will_overflow29
    mvn     r0, #0x80000000
    bx      lr

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
// _IQ30isqrt
//
//*****************************************************************************
    section CODE__IQ30isqrt:CODE(2)
    thumb
    export  _IQ30isqrt
_IQ30isqrt
    //
    // Normalize Input to (1.0 0.5) in Q32
    // If the input is zero or negative, bail out early
    // If the output will overflow, bail out early.  Some values of Q can not
    // overflow, so this escape is partially preprocessed.
    //
    clz     r3, r0
    and     r2, r3, #0x1F
    cbz     r2, isqrt_neg_or_zero30
    cmp     r3, #94-3*30
    bcs     isqrt_will_overflow30
    lsl     r0, r0, r3

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
    // r2 = Yn * N (Q31)
    //
    umull   r12, r2, r0, r1

    //
    // r2 = Yn * Yn * N /2 (Q31)
    //
    umull   r12, r2, r2, r1

    //
    // r2 = 1.5- Yn * Yn * N /2 (Q31)
    //
    rsb     r2, r2, #0xC0000000

    //
    // r1 = Yn * (1.5- Yn * Yn * N /2) (Q31)
    //
    umull   r12, r1, r2, r1
    lsl     r1, r1, #1

    //
    // Newton Raphson Iteration  #2
    // 11-17 Cycles
    //
    umull   r12, r2, r0, r1
    umull   r12, r2, r2, r1
    rsb     r2, r2, #0xC0000000
    umull   r12, r0, r2, r1
    lsl     r0, r0, #1

    //
    // Prepare to Denormalize result
    // r3 stores the necessary shift.
    //
    rsb     r3, r3, #(94 - (3 * 30))
    asrs    r3, r3, #1

    //
    // Correct by sqrt(2) if carry bit is set
    // This is due to the normalization to (1.0 0.5) instead of (1.0 0.25)
    //
    itt     cs
        ldrcs   r2, sqrt_half_30
        umullcs r1, r0, r2, r0

    //
    // Actually denormalize per above preparation
    // Round result and prevent overflow
    //
    lsrs    r0, r0, r3
    adcs    r0, r0, #0
    it      mi
        mvnmi   r0, #0x80000000

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Returns 0 if the input value is negative or zero
    //
isqrt_neg_or_zero30
    mov     r0, #0
    bx      lr
isqrt_will_overflow30
    mvn     r0, #0x80000000
    bx      lr

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
