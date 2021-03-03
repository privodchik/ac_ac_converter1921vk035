//******************************************************************************
//
// IQasin.S - Fixed point calculation of asin in radians
//
// Copyright (c) 2010 Texas Instruments Incorporated.  All rights reserved.
// TI Information - Selective Disclosure
//
//*****************************************************************************

//*****************************************************************************
//
// Function:   _IQNasin
//
//*****************************************************************************
//
// C Usage:    extern long _IQNasin(long x);
//
//-----------------------------------------------------------------------------
//
// On Entry:   r0    = x in IQ format in pirads
//
//
// Regs Used:  r0-r3, r12
//
// On Exit:    r0    = asinPU(x)
//
//
// Q range:    30 to 1
//
//-----------------------------------------------------------------------------
//
// Algorithm Theory:
//
//      Arcsine has a singularity at x=1 and x=-1. The derivative series
//      asymptotically approaches infinity, which creates several problems:
//          A) Since higher order terms become dominant, approximating with a
//              low order polynomial requires a very dense look up table.
//          B) As the terms approach infinity, fixed point approaches suffer
//              extreme resolution loss.
//      The C2000 approach eliminates the singularity at the cost of
//      calculating sqrt by using the following identity:
//              asin(x) = pi/2 - asin(sqrt(1-x^2))
//
//      This algorithm avoids the expense of sqrt by returning to a straight
//      polynomial approximation, but has two significant details that address
//      the problems listed above.
//          A) Look-up table points are spaced semi-exponentially. That is,
//              the range [0,.5) has the same number of points as [.5,.75) and
//              [.75,.875). This allows us to appropriately shape
//              the distribution.
//          B) For each power of two segment - [0,.5), [.5,.75), etc - the
//              input is rescaled to [.5,1). This brings the coefficients for
//              higher order terms closer to the coefficients for lower order
//              terms, especially near x=1. Specifically, it reduces the
//              Nth term by 2^(N*L), where L = floor(log2(1-x)).  This also
//              allows us to operate in Q32 through-out, with out requiring
//              any floating operations.
//      These transformations do require a bit of set up, but it is
//      significantly quicker than the sqrt(1-x^2) transformation. This allows
//      this implementation to reach roughly twice the throughput as the
//      previous generation.
//
//---------------------------------------------------------------------------
//
// Algorithm:  The procedure for calculating "Y = asin(x)" is as follows:
//
//      Step 1)  Take the absolute value of x and store the original sign of x.
//
//      Step 2)  Put X in Q32 and subtract from 1.  All calculations moving
//               forward are with respect to z=1-x
//
//      Step 3)  Find the index into the lookup table.  The index partially
//               logarithmically spaced and partially linearly spaced.  This
//               is done to place relatively more lookup points closer to the
//               singularity at x=1
//               Index = (clz(z)),z[31:27]
//
//      Step 4)  Calculate 4 term polynomial based on 1-X.  Look up
//               coefficients during calculation to save memory.
//
//      Step 5)  Correct for Q, round, correct for sign.
//
//      Note:    x=0 is handles as a special case to allow for full Q32.
//               It will simply bail out immediately, returning 0.
//
//-----------------------------------------------------------------------------
//
// Benchmark:
//
//        Q <= 30       : ?? Cycles
//        Q <= 29       : ?? Cycles
//  12 <= Q <= 28       : ?? Cycles
//        Q  = 11       : ?? Cycles
//   1 <= Q <= 10       : ?? Cycles
//
//******************************************************************************

//*****************************************************************************
//
// The asin tables are used.
//
//*****************************************************************************
    import  asin_table_polynomial
    import  asin_table_flat

//*****************************************************************************
//
// _IQ1asin
//
//*****************************************************************************
    section CODE__IQ1asin:CODE(2)
    thumb
    export  _IQ1asin
_IQ1asin
    //
    // Take the negative absolute value of the input, store sign in r12
    // Taking the negative absolute value here saves 2 cycles later when we
    // truncate and look into the look up table.
    //
    asrs    r12, r0, #32
    it      pl
        rsbpl   r0, r0, #0

    //
    // Put the input in Q32, truncating mercilessly.
    // If the input is 0 or +/- 1, jump to a special handler.
    // Note that this will also jump for 1<=|x|<2.
    // We do not make any claims of what we return in |x|>1, so this is fine.
    //
    lsls    r0, r0, #(32 - 1)
    beq     input_is_zero_or_one_1

    //
    // Generate the lookup table index
    // This is given in a pseudo floating point format, with a 4 bit exponent
    // and a 5 bit mantissa.  The leading one is  omitted.  For example, the
    // number {N leading zeros, '1', A,B,C,D,etc} becomes  N,A,B,C,D
    //
    // This creates a table that has 16 entries of 4 words per log(2) chunk.
    //
    // Additionally, this section massages the input by the algorithm
    // described above. Briefly, z = (1-x) * 2^-floor(log2(1-x)).
    //
    // Since we use 64 words per bit, the last log2(64) = 6 bits are done
    // as a direct look up table to save space.
    //
    clz     r2, r0
    cmp     r2, #24
    bge     direct_lookup_1
    lsl     r0, r0, r2
    rsb     r1, r0, #-1
    lsr     r3, r1, #(32 - 5)
    bfi     r3, r2, #4, #5

    //
    // Point into the table with r3
    //
    ldr     r2, asin_table_polynomial_1
    add     r3, r2, r3, lsl #4

    //
    // Calculate the cubic approximating Polynomial
    // y = c0 + c1*x + c2*x^2 + c3*x^3
    //
    // Due to the transformation above, we can make the following assumptions:
    //      The magnitudes of c0-c3 are always less than 1.0
    //      c0 and c2 are always positive
    //      c1 and c3 are always negative
    //      x is always less than 1.0
    // This allows us to calculate the polynomial in unsigned Q32.Q32, which
    // provides a modest speed improvement over using e.g. signed Q31.
    //
    // The polynomial is re-arranged and calculated as follows:
    //      y =  c3 * x
    //      y = (c2 - y ) * x
    //      y = (c1 - y ) * x
    //      y = (c0 - y )
    //
    // r0 = x in UQ32
    // {r1,r2} = y
    // r3 = pointer to table
    // r4 = loaded coefficient
    //
    push    {lr}

    //
    // y =  c3 * x
    //
    ldr     lr, [r3]
    umull   r1, r2, r0, lr

    //
    // y = (c2 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c1 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c0 - y )
    //
    ldr     lr, [r3, #4]!
    sub     r0, lr, r2

    //
    // r0 now contains the result in UQ30
    // Normalize for Q and apply sign.
    //
    lsr     r0, r0, #(30 - 1)
    teq     r12, #0
    it      ne
        rsbne   r0, r0, #0

    //
    // Return to the caller.
    //
    pop     {pc}

    //
    // Perform a direct lookup of the value.
    //
direct_lookup_1
    ldr     r1, asin_table_flat_1
    ldr     r0, [r1, r0]
    lsr     r0, r0, #(31 - 1)
    bx      lr

    //
    // Special case handling of the value being 0 or 1.
    //
input_is_zero_or_one_1
    //
    // If the input was zero, return 0.  r0 is already appropriately set.
    //
    it      cc
    bxcc    lr
    ldr     r0, piq30_1
    lsr     r0, r0, #(30 - 1 + 1)
    teq     r12, #0xFFFFFFFF
    it      eq
        rsbeq   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
piq30_1
    dcd     0xc90fdaa2         // pi in Q30
asin_table_polynomial_1
    dcd     asin_table_polynomial
asin_table_flat_1
    dcd     asin_table_flat - 4

//*****************************************************************************
//
// _IQ2asin
//
//*****************************************************************************
    section CODE__IQ2asin:CODE(2)
    thumb
    export  _IQ2asin
_IQ2asin
    //
    // Take the negative absolute value of the input, store sign in r12
    // Taking the negative absolute value here saves 2 cycles later when we
    // truncate and look into the look up table.
    //
    asrs    r12, r0, #32
    it      pl
        rsbpl   r0, r0, #0

    //
    // Put the input in Q32, truncating mercilessly.
    // If the input is 0 or +/- 1, jump to a special handler.
    // Note that this will also jump for 1<=|x|<2.
    // We do not make any claims of what we return in |x|>1, so this is fine.
    //
    lsls    r0, r0, #(32 - 2)
    beq     input_is_zero_or_one_2

    //
    // Generate the lookup table index
    // This is given in a pseudo floating point format, with a 4 bit exponent
    // and a 5 bit mantissa.  The leading one is  omitted.  For example, the
    // number {N leading zeros, '1', A,B,C,D,etc} becomes  N,A,B,C,D
    //
    // This creates a table that has 16 entries of 4 words per log(2) chunk.
    //
    // Additionally, this section massages the input by the algorithm
    // described above. Briefly, z = (1-x) * 2^-floor(log2(1-x)).
    //
    // Since we use 64 words per bit, the last log2(64) = 6 bits are done
    // as a direct look up table to save space.
    //
    clz     r2, r0
    cmp     r2, #24
    bge     direct_lookup_2
    lsl     r0, r0, r2
    rsb     r1, r0, #-1
    lsr     r3, r1, #(32 - 5)
    bfi     r3, r2, #4, #5

    //
    // Point into the table with r3
    //
    ldr     r2, asin_table_polynomial_2
    add     r3, r2, r3, lsl #4

    //
    // Calculate the cubic approximating Polynomial
    // y = c0 + c1*x + c2*x^2 + c3*x^3
    //
    // Due to the transformation above, we can make the following assumptions:
    //      The magnitudes of c0-c3 are always less than 1.0
    //      c0 and c2 are always positive
    //      c1 and c3 are always negative
    //      x is always less than 1.0
    // This allows us to calculate the polynomial in unsigned Q32.Q32, which
    // provides a modest speed improvement over using e.g. signed Q31.
    //
    // The polynomial is re-arranged and calculated as follows:
    //      y =  c3 * x
    //      y = (c2 - y ) * x
    //      y = (c1 - y ) * x
    //      y = (c0 - y )
    //
    // r0 = x in UQ32
    // {r1,r2} = y
    // r3 = pointer to table
    // r4 = loaded coefficient
    //
    push    {lr}

    //
    // y =  c3 * x
    //
    ldr     lr, [r3]
    umull   r1, r2, r0, lr

    //
    // y = (c2 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c1 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c0 - y )
    //
    ldr     lr, [r3, #4]!
    sub     r0, lr, r2

    //
    // r0 now contains the result in UQ30
    // Normalize for Q and apply sign.
    //
    lsr     r0, r0, #(30 - 2)
    teq     r12, #0
    it      ne
        rsbne   r0, r0, #0

    //
    // Return to the caller.
    //
    pop     {pc}

    //
    // Perform a direct lookup of the value.
    //
direct_lookup_2
    ldr     r1, asin_table_flat_2
    ldr     r0, [r1, r0]
    lsr     r0, r0, #(31 - 2)
    bx      lr

    //
    // Special case handling of the value being 0 or 1.
    //
input_is_zero_or_one_2
    //
    // If the input was zero, return 0.  r0 is already appropriately set.
    //
    it      cc
    bxcc    lr
    ldr     r0, piq30_2
    lsr     r0, r0, #(30 - 2 + 1)
    teq     r12, #0xFFFFFFFF
    it      eq
        rsbeq   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
piq30_2
    dcd     0xc90fdaa2         // pi in Q30
asin_table_polynomial_2
    dcd     asin_table_polynomial
asin_table_flat_2
    dcd     asin_table_flat - 4

//*****************************************************************************
//
// _IQ3asin
//
//*****************************************************************************
    section CODE__IQ3asin:CODE(2)
    thumb
    export  _IQ3asin
_IQ3asin
    //
    // Take the negative absolute value of the input, store sign in r12
    // Taking the negative absolute value here saves 2 cycles later when we
    // truncate and look into the look up table.
    //
    asrs    r12, r0, #32
    it      pl
        rsbpl   r0, r0, #0

    //
    // Put the input in Q32, truncating mercilessly.
    // If the input is 0 or +/- 1, jump to a special handler.
    // Note that this will also jump for 1<=|x|<2.
    // We do not make any claims of what we return in |x|>1, so this is fine.
    //
    lsls    r0, r0, #(32 - 3)
    beq     input_is_zero_or_one_3

    //
    // Generate the lookup table index
    // This is given in a pseudo floating point format, with a 4 bit exponent
    // and a 5 bit mantissa.  The leading one is  omitted.  For example, the
    // number {N leading zeros, '1', A,B,C,D,etc} becomes  N,A,B,C,D
    //
    // This creates a table that has 16 entries of 4 words per log(2) chunk.
    //
    // Additionally, this section massages the input by the algorithm
    // described above. Briefly, z = (1-x) * 2^-floor(log2(1-x)).
    //
    // Since we use 64 words per bit, the last log2(64) = 6 bits are done
    // as a direct look up table to save space.
    //
    clz     r2, r0
    cmp     r2, #24
    bge     direct_lookup_3
    lsl     r0, r0, r2
    rsb     r1, r0, #-1
    lsr     r3, r1, #(32 - 5)
    bfi     r3, r2, #4, #5

    //
    // Point into the table with r3
    //
    ldr     r2, asin_table_polynomial_3
    add     r3, r2, r3, lsl #4

    //
    // Calculate the cubic approximating Polynomial
    // y = c0 + c1*x + c2*x^2 + c3*x^3
    //
    // Due to the transformation above, we can make the following assumptions:
    //      The magnitudes of c0-c3 are always less than 1.0
    //      c0 and c2 are always positive
    //      c1 and c3 are always negative
    //      x is always less than 1.0
    // This allows us to calculate the polynomial in unsigned Q32.Q32, which
    // provides a modest speed improvement over using e.g. signed Q31.
    //
    // The polynomial is re-arranged and calculated as follows:
    //      y =  c3 * x
    //      y = (c2 - y ) * x
    //      y = (c1 - y ) * x
    //      y = (c0 - y )
    //
    // r0 = x in UQ32
    // {r1,r2} = y
    // r3 = pointer to table
    // r4 = loaded coefficient
    //
    push    {lr}

    //
    // y =  c3 * x
    //
    ldr     lr, [r3]
    umull   r1, r2, r0, lr

    //
    // y = (c2 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c1 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c0 - y )
    //
    ldr     lr, [r3, #4]!
    sub     r0, lr, r2

    //
    // r0 now contains the result in UQ30
    // Normalize for Q and apply sign.
    //
    lsr     r0, r0, #(30 - 3)
    teq     r12, #0
    it      ne
        rsbne   r0, r0, #0

    //
    // Return to the caller.
    //
    pop     {pc}

    //
    // Perform a direct lookup of the value.
    //
direct_lookup_3
    ldr     r1, asin_table_flat_3
    ldr     r0, [r1, r0]
    lsr     r0, r0, #(31 - 3)
    bx      lr

    //
    // Special case handling of the value being 0 or 1.
    //
input_is_zero_or_one_3
    //
    // If the input was zero, return 0.  r0 is already appropriately set.
    //
    it      cc
    bxcc    lr
    ldr     r0, piq30_3
    lsr     r0, r0, #(30 - 3 + 1)
    teq     r12, #0xFFFFFFFF
    it      eq
        rsbeq   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
piq30_3
    dcd     0xc90fdaa2         // pi in Q30
asin_table_polynomial_3
    dcd     asin_table_polynomial
asin_table_flat_3
    dcd     asin_table_flat - 4

//*****************************************************************************
//
// _IQ4asin
//
//*****************************************************************************
    section CODE__IQ4asin:CODE(2)
    thumb
    export  _IQ4asin
_IQ4asin
    //
    // Take the negative absolute value of the input, store sign in r12
    // Taking the negative absolute value here saves 2 cycles later when we
    // truncate and look into the look up table.
    //
    asrs    r12, r0, #32
    it      pl
        rsbpl   r0, r0, #0

    //
    // Put the input in Q32, truncating mercilessly.
    // If the input is 0 or +/- 1, jump to a special handler.
    // Note that this will also jump for 1<=|x|<2.
    // We do not make any claims of what we return in |x|>1, so this is fine.
    //
    lsls    r0, r0, #(32 - 4)
    beq     input_is_zero_or_one_4

    //
    // Generate the lookup table index
    // This is given in a pseudo floating point format, with a 4 bit exponent
    // and a 5 bit mantissa.  The leading one is  omitted.  For example, the
    // number {N leading zeros, '1', A,B,C,D,etc} becomes  N,A,B,C,D
    //
    // This creates a table that has 16 entries of 4 words per log(2) chunk.
    //
    // Additionally, this section massages the input by the algorithm
    // described above. Briefly, z = (1-x) * 2^-floor(log2(1-x)).
    //
    // Since we use 64 words per bit, the last log2(64) = 6 bits are done
    // as a direct look up table to save space.
    //
    clz     r2, r0
    cmp     r2, #24
    bge     direct_lookup_4
    lsl     r0, r0, r2
    rsb     r1, r0, #-1
    lsr     r3, r1, #(32 - 5)
    bfi     r3, r2, #4, #5

    //
    // Point into the table with r3
    //
    ldr     r2, asin_table_polynomial_4
    add     r3, r2, r3, lsl #4

    //
    // Calculate the cubic approximating Polynomial
    // y = c0 + c1*x + c2*x^2 + c3*x^3
    //
    // Due to the transformation above, we can make the following assumptions:
    //      The magnitudes of c0-c3 are always less than 1.0
    //      c0 and c2 are always positive
    //      c1 and c3 are always negative
    //      x is always less than 1.0
    // This allows us to calculate the polynomial in unsigned Q32.Q32, which
    // provides a modest speed improvement over using e.g. signed Q31.
    //
    // The polynomial is re-arranged and calculated as follows:
    //      y =  c3 * x
    //      y = (c2 - y ) * x
    //      y = (c1 - y ) * x
    //      y = (c0 - y )
    //
    // r0 = x in UQ32
    // {r1,r2} = y
    // r3 = pointer to table
    // r4 = loaded coefficient
    //
    push    {lr}

    //
    // y =  c3 * x
    //
    ldr     lr, [r3]
    umull   r1, r2, r0, lr

    //
    // y = (c2 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c1 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c0 - y )
    //
    ldr     lr, [r3, #4]!
    sub     r0, lr, r2

    //
    // r0 now contains the result in UQ30
    // Normalize for Q and apply sign.
    //
    lsr     r0, r0, #(30 - 4)
    teq     r12, #0
    it      ne
        rsbne   r0, r0, #0

    //
    // Return to the caller.
    //
    pop     {pc}

    //
    // Perform a direct lookup of the value.
    //
direct_lookup_4
    ldr     r1, asin_table_flat_4
    ldr     r0, [r1, r0]
    lsr     r0, r0, #(31 - 4)
    bx      lr

    //
    // Special case handling of the value being 0 or 1.
    //
input_is_zero_or_one_4
    //
    // If the input was zero, return 0.  r0 is already appropriately set.
    //
    it      cc
    bxcc    lr
    ldr     r0, piq30_4
    lsr     r0, r0, #(30 - 4 + 1)
    teq     r12, #0xFFFFFFFF
    it      eq
        rsbeq   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
piq30_4
    dcd     0xc90fdaa2         // pi in Q30
asin_table_polynomial_4
    dcd     asin_table_polynomial
asin_table_flat_4
    dcd     asin_table_flat - 4

//*****************************************************************************
//
// _IQ5asin
//
//*****************************************************************************
    section CODE__IQ5asin:CODE(2)
    thumb
    export  _IQ5asin
_IQ5asin
    //
    // Take the negative absolute value of the input, store sign in r12
    // Taking the negative absolute value here saves 2 cycles later when we
    // truncate and look into the look up table.
    //
    asrs    r12, r0, #32
    it      pl
        rsbpl   r0, r0, #0

    //
    // Put the input in Q32, truncating mercilessly.
    // If the input is 0 or +/- 1, jump to a special handler.
    // Note that this will also jump for 1<=|x|<2.
    // We do not make any claims of what we return in |x|>1, so this is fine.
    //
    lsls    r0, r0, #(32 - 5)
    beq     input_is_zero_or_one_5

    //
    // Generate the lookup table index
    // This is given in a pseudo floating point format, with a 4 bit exponent
    // and a 5 bit mantissa.  The leading one is  omitted.  For example, the
    // number {N leading zeros, '1', A,B,C,D,etc} becomes  N,A,B,C,D
    //
    // This creates a table that has 16 entries of 4 words per log(2) chunk.
    //
    // Additionally, this section massages the input by the algorithm
    // described above. Briefly, z = (1-x) * 2^-floor(log2(1-x)).
    //
    // Since we use 64 words per bit, the last log2(64) = 6 bits are done
    // as a direct look up table to save space.
    //
    clz     r2, r0
    cmp     r2, #24
    bge     direct_lookup_5
    lsl     r0, r0, r2
    rsb     r1, r0, #-1
    lsr     r3, r1, #(32 - 5)
    bfi     r3, r2, #4, #5

    //
    // Point into the table with r3
    //
    ldr     r2, asin_table_polynomial_5
    add     r3, r2, r3, lsl #4

    //
    // Calculate the cubic approximating Polynomial
    // y = c0 + c1*x + c2*x^2 + c3*x^3
    //
    // Due to the transformation above, we can make the following assumptions:
    //      The magnitudes of c0-c3 are always less than 1.0
    //      c0 and c2 are always positive
    //      c1 and c3 are always negative
    //      x is always less than 1.0
    // This allows us to calculate the polynomial in unsigned Q32.Q32, which
    // provides a modest speed improvement over using e.g. signed Q31.
    //
    // The polynomial is re-arranged and calculated as follows:
    //      y =  c3 * x
    //      y = (c2 - y ) * x
    //      y = (c1 - y ) * x
    //      y = (c0 - y )
    //
    // r0 = x in UQ32
    // {r1,r2} = y
    // r3 = pointer to table
    // r4 = loaded coefficient
    //
    push    {lr}

    //
    // y =  c3 * x
    //
    ldr     lr, [r3]
    umull   r1, r2, r0, lr

    //
    // y = (c2 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c1 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c0 - y )
    //
    ldr     lr, [r3, #4]!
    sub     r0, lr, r2

    //
    // r0 now contains the result in UQ30
    // Normalize for Q and apply sign.
    //
    lsr     r0, r0, #(30 - 5)
    teq     r12, #0
    it      ne
        rsbne   r0, r0, #0

    //
    // Return to the caller.
    //
    pop     {pc}

    //
    // Perform a direct lookup of the value.
    //
direct_lookup_5
    ldr     r1, asin_table_flat_5
    ldr     r0, [r1, r0]
    lsr     r0, r0, #(31 - 5)
    bx      lr

    //
    // Special case handling of the value being 0 or 1.
    //
input_is_zero_or_one_5
    //
    // If the input was zero, return 0.  r0 is already appropriately set.
    //
    it      cc
    bxcc    lr
    ldr     r0, piq30_5
    lsr     r0, r0, #(30 - 5 + 1)
    teq     r12, #0xFFFFFFFF
    it      eq
        rsbeq   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
piq30_5
    dcd     0xc90fdaa2         // pi in Q30
asin_table_polynomial_5
    dcd     asin_table_polynomial
asin_table_flat_5
    dcd     asin_table_flat - 4

//*****************************************************************************
//
// _IQ6asin
//
//*****************************************************************************
    section CODE__IQ6asin:CODE(2)
    thumb
    export  _IQ6asin
_IQ6asin
    //
    // Take the negative absolute value of the input, store sign in r12
    // Taking the negative absolute value here saves 2 cycles later when we
    // truncate and look into the look up table.
    //
    asrs    r12, r0, #32
    it      pl
        rsbpl   r0, r0, #0

    //
    // Put the input in Q32, truncating mercilessly.
    // If the input is 0 or +/- 1, jump to a special handler.
    // Note that this will also jump for 1<=|x|<2.
    // We do not make any claims of what we return in |x|>1, so this is fine.
    //
    lsls    r0, r0, #(32 - 6)
    beq     input_is_zero_or_one_6

    //
    // Generate the lookup table index
    // This is given in a pseudo floating point format, with a 4 bit exponent
    // and a 5 bit mantissa.  The leading one is  omitted.  For example, the
    // number {N leading zeros, '1', A,B,C,D,etc} becomes  N,A,B,C,D
    //
    // This creates a table that has 16 entries of 4 words per log(2) chunk.
    //
    // Additionally, this section massages the input by the algorithm
    // described above. Briefly, z = (1-x) * 2^-floor(log2(1-x)).
    //
    // Since we use 64 words per bit, the last log2(64) = 6 bits are done
    // as a direct look up table to save space.
    //
    clz     r2, r0
    cmp     r2, #24
    bge     direct_lookup_6
    lsl     r0, r0, r2
    rsb     r1, r0, #-1
    lsr     r3, r1, #(32 - 5)
    bfi     r3, r2, #4, #5

    //
    // Point into the table with r3
    //
    ldr     r2, asin_table_polynomial_6
    add     r3, r2, r3, lsl #4

    //
    // Calculate the cubic approximating Polynomial
    // y = c0 + c1*x + c2*x^2 + c3*x^3
    //
    // Due to the transformation above, we can make the following assumptions:
    //      The magnitudes of c0-c3 are always less than 1.0
    //      c0 and c2 are always positive
    //      c1 and c3 are always negative
    //      x is always less than 1.0
    // This allows us to calculate the polynomial in unsigned Q32.Q32, which
    // provides a modest speed improvement over using e.g. signed Q31.
    //
    // The polynomial is re-arranged and calculated as follows:
    //      y =  c3 * x
    //      y = (c2 - y ) * x
    //      y = (c1 - y ) * x
    //      y = (c0 - y )
    //
    // r0 = x in UQ32
    // {r1,r2} = y
    // r3 = pointer to table
    // r4 = loaded coefficient
    //
    push    {lr}

    //
    // y =  c3 * x
    //
    ldr     lr, [r3]
    umull   r1, r2, r0, lr

    //
    // y = (c2 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c1 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c0 - y )
    //
    ldr     lr, [r3, #4]!
    sub     r0, lr, r2

    //
    // r0 now contains the result in UQ30
    // Normalize for Q and apply sign.
    //
    lsr     r0, r0, #(30 - 6)
    teq     r12, #0
    it      ne
        rsbne   r0, r0, #0

    //
    // Return to the caller.
    //
    pop     {pc}

    //
    // Perform a direct lookup of the value.
    //
direct_lookup_6
    ldr     r1, asin_table_flat_6
    ldr     r0, [r1, r0]
    lsr     r0, r0, #(31 - 6)
    bx      lr

    //
    // Special case handling of the value being 0 or 1.
    //
input_is_zero_or_one_6
    //
    // If the input was zero, return 0.  r0 is already appropriately set.
    //
    it      cc
    bxcc    lr
    ldr     r0, piq30_6
    lsr     r0, r0, #(30 - 6 + 1)
    teq     r12, #0xFFFFFFFF
    it      eq
        rsbeq   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
piq30_6
    dcd     0xc90fdaa2         // pi in Q30
asin_table_polynomial_6
    dcd     asin_table_polynomial
asin_table_flat_6
    dcd     asin_table_flat - 4

//*****************************************************************************
//
// _IQ7asin
//
//*****************************************************************************
    section CODE__IQ7asin:CODE(2)
    thumb
    export  _IQ7asin
_IQ7asin
    //
    // Take the negative absolute value of the input, store sign in r12
    // Taking the negative absolute value here saves 2 cycles later when we
    // truncate and look into the look up table.
    //
    asrs    r12, r0, #32
    it      pl
        rsbpl   r0, r0, #0

    //
    // Put the input in Q32, truncating mercilessly.
    // If the input is 0 or +/- 1, jump to a special handler.
    // Note that this will also jump for 1<=|x|<2.
    // We do not make any claims of what we return in |x|>1, so this is fine.
    //
    lsls    r0, r0, #(32 - 7)
    beq     input_is_zero_or_one_7

    //
    // Generate the lookup table index
    // This is given in a pseudo floating point format, with a 4 bit exponent
    // and a 5 bit mantissa.  The leading one is  omitted.  For example, the
    // number {N leading zeros, '1', A,B,C,D,etc} becomes  N,A,B,C,D
    //
    // This creates a table that has 16 entries of 4 words per log(2) chunk.
    //
    // Additionally, this section massages the input by the algorithm
    // described above. Briefly, z = (1-x) * 2^-floor(log2(1-x)).
    //
    // Since we use 64 words per bit, the last log2(64) = 6 bits are done
    // as a direct look up table to save space.
    //
    clz     r2, r0
    cmp     r2, #24
    bge     direct_lookup_7
    lsl     r0, r0, r2
    rsb     r1, r0, #-1
    lsr     r3, r1, #(32 - 5)
    bfi     r3, r2, #4, #5

    //
    // Point into the table with r3
    //
    ldr     r2, asin_table_polynomial_7
    add     r3, r2, r3, lsl #4

    //
    // Calculate the cubic approximating Polynomial
    // y = c0 + c1*x + c2*x^2 + c3*x^3
    //
    // Due to the transformation above, we can make the following assumptions:
    //      The magnitudes of c0-c3 are always less than 1.0
    //      c0 and c2 are always positive
    //      c1 and c3 are always negative
    //      x is always less than 1.0
    // This allows us to calculate the polynomial in unsigned Q32.Q32, which
    // provides a modest speed improvement over using e.g. signed Q31.
    //
    // The polynomial is re-arranged and calculated as follows:
    //      y =  c3 * x
    //      y = (c2 - y ) * x
    //      y = (c1 - y ) * x
    //      y = (c0 - y )
    //
    // r0 = x in UQ32
    // {r1,r2} = y
    // r3 = pointer to table
    // r4 = loaded coefficient
    //
    push    {lr}

    //
    // y =  c3 * x
    //
    ldr     lr, [r3]
    umull   r1, r2, r0, lr

    //
    // y = (c2 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c1 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c0 - y )
    //
    ldr     lr, [r3, #4]!
    sub     r0, lr, r2

    //
    // r0 now contains the result in UQ30
    // Normalize for Q and apply sign.
    //
    lsr     r0, r0, #(30 - 7)
    teq     r12, #0
    it      ne
        rsbne   r0, r0, #0

    //
    // Return to the caller.
    //
    pop     {pc}

    //
    // Perform a direct lookup of the value.
    //
direct_lookup_7
    ldr     r1, asin_table_flat_7
    ldr     r0, [r1, r0]
    lsr     r0, r0, #(31 - 7)
    bx      lr

    //
    // Special case handling of the value being 0 or 1.
    //
input_is_zero_or_one_7
    //
    // If the input was zero, return 0.  r0 is already appropriately set.
    //
    it      cc
    bxcc    lr
    ldr     r0, piq30_7
    lsr     r0, r0, #(30 - 7 + 1)
    teq     r12, #0xFFFFFFFF
    it      eq
        rsbeq   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
piq30_7
    dcd     0xc90fdaa2         // pi in Q30
asin_table_polynomial_7
    dcd     asin_table_polynomial
asin_table_flat_7
    dcd     asin_table_flat - 4

//*****************************************************************************
//
// _IQ8asin
//
//*****************************************************************************
    section CODE__IQ8asin:CODE(2)
    thumb
    export  _IQ8asin
_IQ8asin
    //
    // Take the negative absolute value of the input, store sign in r12
    // Taking the negative absolute value here saves 2 cycles later when we
    // truncate and look into the look up table.
    //
    asrs    r12, r0, #32
    it      pl
        rsbpl   r0, r0, #0

    //
    // Put the input in Q32, truncating mercilessly.
    // If the input is 0 or +/- 1, jump to a special handler.
    // Note that this will also jump for 1<=|x|<2.
    // We do not make any claims of what we return in |x|>1, so this is fine.
    //
    lsls    r0, r0, #(32 - 8)
    beq     input_is_zero_or_one_8

    //
    // Generate the lookup table index
    // This is given in a pseudo floating point format, with a 4 bit exponent
    // and a 5 bit mantissa.  The leading one is  omitted.  For example, the
    // number {N leading zeros, '1', A,B,C,D,etc} becomes  N,A,B,C,D
    //
    // This creates a table that has 16 entries of 4 words per log(2) chunk.
    //
    // Additionally, this section massages the input by the algorithm
    // described above. Briefly, z = (1-x) * 2^-floor(log2(1-x)).
    //
    // Since we use 64 words per bit, the last log2(64) = 6 bits are done
    // as a direct look up table to save space.
    //
    clz     r2, r0
    cmp     r2, #24
    bge     direct_lookup_8
    lsl     r0, r0, r2
    rsb     r1, r0, #-1
    lsr     r3, r1, #(32 - 5)
    bfi     r3, r2, #4, #5

    //
    // Point into the table with r3
    //
    ldr     r2, asin_table_polynomial_8
    add     r3, r2, r3, lsl #4

    //
    // Calculate the cubic approximating Polynomial
    // y = c0 + c1*x + c2*x^2 + c3*x^3
    //
    // Due to the transformation above, we can make the following assumptions:
    //      The magnitudes of c0-c3 are always less than 1.0
    //      c0 and c2 are always positive
    //      c1 and c3 are always negative
    //      x is always less than 1.0
    // This allows us to calculate the polynomial in unsigned Q32.Q32, which
    // provides a modest speed improvement over using e.g. signed Q31.
    //
    // The polynomial is re-arranged and calculated as follows:
    //      y =  c3 * x
    //      y = (c2 - y ) * x
    //      y = (c1 - y ) * x
    //      y = (c0 - y )
    //
    // r0 = x in UQ32
    // {r1,r2} = y
    // r3 = pointer to table
    // r4 = loaded coefficient
    //
    push    {lr}

    //
    // y =  c3 * x
    //
    ldr     lr, [r3]
    umull   r1, r2, r0, lr

    //
    // y = (c2 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c1 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c0 - y )
    //
    ldr     lr, [r3, #4]!
    sub     r0, lr, r2

    //
    // r0 now contains the result in UQ30
    // Normalize for Q and apply sign.
    //
    lsr     r0, r0, #(30 - 8)
    teq     r12, #0
    it      ne
        rsbne   r0, r0, #0

    //
    // Return to the caller.
    //
    pop     {pc}

    //
    // Perform a direct lookup of the value.
    //
direct_lookup_8
    ldr     r1, asin_table_flat_8
    ldr     r0, [r1, r0]
    lsr     r0, r0, #(31 - 8)
    bx      lr

    //
    // Special case handling of the value being 0 or 1.
    //
input_is_zero_or_one_8
    //
    // If the input was zero, return 0.  r0 is already appropriately set.
    //
    it      cc
    bxcc    lr
    ldr     r0, piq30_8
    lsr     r0, r0, #(30 - 8 + 1)
    teq     r12, #0xFFFFFFFF
    it      eq
        rsbeq   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
piq30_8
    dcd     0xc90fdaa2         // pi in Q30
asin_table_polynomial_8
    dcd     asin_table_polynomial
asin_table_flat_8
    dcd     asin_table_flat - 4

//*****************************************************************************
//
// _IQ9asin
//
//*****************************************************************************
    section CODE__IQ9asin:CODE(2)
    thumb
    export  _IQ9asin
_IQ9asin
    //
    // Take the negative absolute value of the input, store sign in r12
    // Taking the negative absolute value here saves 2 cycles later when we
    // truncate and look into the look up table.
    //
    asrs    r12, r0, #32
    it      pl
        rsbpl   r0, r0, #0

    //
    // Put the input in Q32, truncating mercilessly.
    // If the input is 0 or +/- 1, jump to a special handler.
    // Note that this will also jump for 1<=|x|<2.
    // We do not make any claims of what we return in |x|>1, so this is fine.
    //
    lsls    r0, r0, #(32 - 9)
    beq     input_is_zero_or_one_9

    //
    // Generate the lookup table index
    // This is given in a pseudo floating point format, with a 4 bit exponent
    // and a 5 bit mantissa.  The leading one is  omitted.  For example, the
    // number {N leading zeros, '1', A,B,C,D,etc} becomes  N,A,B,C,D
    //
    // This creates a table that has 16 entries of 4 words per log(2) chunk.
    //
    // Additionally, this section massages the input by the algorithm
    // described above. Briefly, z = (1-x) * 2^-floor(log2(1-x)).
    //
    // Since we use 64 words per bit, the last log2(64) = 6 bits are done
    // as a direct look up table to save space.
    //
    clz     r2, r0
    cmp     r2, #24
    bge     direct_lookup_9
    lsl     r0, r0, r2
    rsb     r1, r0, #-1
    lsr     r3, r1, #(32 - 5)
    bfi     r3, r2, #4, #5

    //
    // Point into the table with r3
    //
    ldr     r2, asin_table_polynomial_9
    add     r3, r2, r3, lsl #4

    //
    // Calculate the cubic approximating Polynomial
    // y = c0 + c1*x + c2*x^2 + c3*x^3
    //
    // Due to the transformation above, we can make the following assumptions:
    //      The magnitudes of c0-c3 are always less than 1.0
    //      c0 and c2 are always positive
    //      c1 and c3 are always negative
    //      x is always less than 1.0
    // This allows us to calculate the polynomial in unsigned Q32.Q32, which
    // provides a modest speed improvement over using e.g. signed Q31.
    //
    // The polynomial is re-arranged and calculated as follows:
    //      y =  c3 * x
    //      y = (c2 - y ) * x
    //      y = (c1 - y ) * x
    //      y = (c0 - y )
    //
    // r0 = x in UQ32
    // {r1,r2} = y
    // r3 = pointer to table
    // r4 = loaded coefficient
    //
    push    {lr}

    //
    // y =  c3 * x
    //
    ldr     lr, [r3]
    umull   r1, r2, r0, lr

    //
    // y = (c2 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c1 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c0 - y )
    //
    ldr     lr, [r3, #4]!
    sub     r0, lr, r2

    //
    // r0 now contains the result in UQ30
    // Normalize for Q and apply sign.
    //
    lsr     r0, r0, #(30 - 9)
    teq     r12, #0
    it      ne
        rsbne   r0, r0, #0

    //
    // Return to the caller.
    //
    pop     {pc}

    //
    // Perform a direct lookup of the value.
    //
direct_lookup_9
    ldr     r1, asin_table_flat_9
    ldr     r0, [r1, r0]
    lsr     r0, r0, #(31 - 9)
    bx      lr

    //
    // Special case handling of the value being 0 or 1.
    //
input_is_zero_or_one_9
    //
    // If the input was zero, return 0.  r0 is already appropriately set.
    //
    it      cc
    bxcc    lr
    ldr     r0, piq30_9
    lsr     r0, r0, #(30 - 9 + 1)
    teq     r12, #0xFFFFFFFF
    it      eq
        rsbeq   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
piq30_9
    dcd     0xc90fdaa2         // pi in Q30
asin_table_polynomial_9
    dcd     asin_table_polynomial
asin_table_flat_9
    dcd     asin_table_flat - 4

//*****************************************************************************
//
// _IQ10asin
//
//*****************************************************************************
    section CODE__IQ10asin:CODE(2)
    thumb
    export  _IQ10asin
_IQ10asin
    //
    // Take the negative absolute value of the input, store sign in r12
    // Taking the negative absolute value here saves 2 cycles later when we
    // truncate and look into the look up table.
    //
    asrs    r12, r0, #32
    it      pl
        rsbpl   r0, r0, #0

    //
    // Put the input in Q32, truncating mercilessly.
    // If the input is 0 or +/- 1, jump to a special handler.
    // Note that this will also jump for 1<=|x|<2.
    // We do not make any claims of what we return in |x|>1, so this is fine.
    //
    lsls    r0, r0, #(32 - 10)
    beq     input_is_zero_or_one_10

    //
    // Generate the lookup table index
    // This is given in a pseudo floating point format, with a 4 bit exponent
    // and a 5 bit mantissa.  The leading one is  omitted.  For example, the
    // number {N leading zeros, '1', A,B,C,D,etc} becomes  N,A,B,C,D
    //
    // This creates a table that has 16 entries of 4 words per log(2) chunk.
    //
    // Additionally, this section massages the input by the algorithm
    // described above. Briefly, z = (1-x) * 2^-floor(log2(1-x)).
    //
    // Since we use 64 words per bit, the last log2(64) = 6 bits are done
    // as a direct look up table to save space.
    //
    clz     r2, r0
    cmp     r2, #24
    bge     direct_lookup_10
    lsl     r0, r0, r2
    rsb     r1, r0, #-1
    lsr     r3, r1, #(32 - 5)
    bfi     r3, r2, #4, #5

    //
    // Point into the table with r3
    //
    ldr     r2, asin_table_polynomial_10
    add     r3, r2, r3, lsl #4

    //
    // Calculate the cubic approximating Polynomial
    // y = c0 + c1*x + c2*x^2 + c3*x^3
    //
    // Due to the transformation above, we can make the following assumptions:
    //      The magnitudes of c0-c3 are always less than 1.0
    //      c0 and c2 are always positive
    //      c1 and c3 are always negative
    //      x is always less than 1.0
    // This allows us to calculate the polynomial in unsigned Q32.Q32, which
    // provides a modest speed improvement over using e.g. signed Q31.
    //
    // The polynomial is re-arranged and calculated as follows:
    //      y =  c3 * x
    //      y = (c2 - y ) * x
    //      y = (c1 - y ) * x
    //      y = (c0 - y )
    //
    // r0 = x in UQ32
    // {r1,r2} = y
    // r3 = pointer to table
    // r4 = loaded coefficient
    //
    push    {lr}

    //
    // y =  c3 * x
    //
    ldr     lr, [r3]
    umull   r1, r2, r0, lr

    //
    // y = (c2 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c1 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c0 - y )
    //
    ldr     lr, [r3, #4]!
    sub     r0, lr, r2

    //
    // r0 now contains the result in UQ30
    // Normalize for Q and apply sign.
    //
    lsr     r0, r0, #(30 - 10)
    teq     r12, #0
    it      ne
        rsbne   r0, r0, #0

    //
    // Return to the caller.
    //
    pop     {pc}

    //
    // Perform a direct lookup of the value.
    //
direct_lookup_10
    ldr     r1, asin_table_flat_10
    ldr     r0, [r1, r0]
    lsr     r0, r0, #(31 - 10)
    bx      lr

    //
    // Special case handling of the value being 0 or 1.
    //
input_is_zero_or_one_10
    //
    // If the input was zero, return 0.  r0 is already appropriately set.
    //
    it      cc
    bxcc    lr
    ldr     r0, piq30_10
    lsr     r0, r0, #(30 - 10 + 1)
    teq     r12, #0xFFFFFFFF
    it      eq
        rsbeq   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
piq30_10
    dcd     0xc90fdaa2         // pi in Q30
asin_table_polynomial_10
    dcd     asin_table_polynomial
asin_table_flat_10
    dcd     asin_table_flat - 4

//*****************************************************************************
//
// _IQ11asin
//
//*****************************************************************************
    section CODE__IQ11asin:CODE(2)
    thumb
    export  _IQ11asin
_IQ11asin
    //
    // Take the negative absolute value of the input, store sign in r12
    // Taking the negative absolute value here saves 2 cycles later when we
    // truncate and look into the look up table.
    //
    asrs    r12, r0, #32
    it      pl
        rsbpl   r0, r0, #0

    //
    // Put the input in Q32, truncating mercilessly.
    // If the input is 0 or +/- 1, jump to a special handler.
    // Note that this will also jump for 1<=|x|<2.
    // We do not make any claims of what we return in |x|>1, so this is fine.
    //
    lsls    r0, r0, #(32 - 11)
    beq     input_is_zero_or_one_11

    //
    // Generate the lookup table index
    // This is given in a pseudo floating point format, with a 4 bit exponent
    // and a 5 bit mantissa.  The leading one is  omitted.  For example, the
    // number {N leading zeros, '1', A,B,C,D,etc} becomes  N,A,B,C,D
    //
    // This creates a table that has 16 entries of 4 words per log(2) chunk.
    //
    // Additionally, this section massages the input by the algorithm
    // described above. Briefly, z = (1-x) * 2^-floor(log2(1-x)).
    //
    // Since we use 64 words per bit, the last log2(64) = 6 bits are done
    // as a direct look up table to save space.
    //
    clz     r2, r0
    cmp     r2, #24
    bge     direct_lookup_11
    lsl     r0, r0, r2
    rsb     r1, r0, #-1
    lsr     r3, r1, #(32 - 5)
    bfi     r3, r2, #4, #5

    //
    // Point into the table with r3
    //
    ldr     r2, asin_table_polynomial_11
    add     r3, r2, r3, lsl #4

    //
    // Calculate the cubic approximating Polynomial
    // y = c0 + c1*x + c2*x^2 + c3*x^3
    //
    // Due to the transformation above, we can make the following assumptions:
    //      The magnitudes of c0-c3 are always less than 1.0
    //      c0 and c2 are always positive
    //      c1 and c3 are always negative
    //      x is always less than 1.0
    // This allows us to calculate the polynomial in unsigned Q32.Q32, which
    // provides a modest speed improvement over using e.g. signed Q31.
    //
    // The polynomial is re-arranged and calculated as follows:
    //      y =  c3 * x
    //      y = (c2 - y ) * x
    //      y = (c1 - y ) * x
    //      y = (c0 - y )
    //
    // r0 = x in UQ32
    // {r1,r2} = y
    // r3 = pointer to table
    // r4 = loaded coefficient
    //
    push    {lr}

    //
    // y =  c3 * x
    //
    ldr     lr, [r3]
    umull   r1, r2, r0, lr

    //
    // y = (c2 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c1 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c0 - y )
    //
    ldr     lr, [r3, #4]!
    sub     r0, lr, r2

    //
    // r0 now contains the result in UQ30
    // Normalize for Q and apply sign.
    //
    lsr     r0, r0, #(30 - 11)
    teq     r12, #0
    it      ne
        rsbne   r0, r0, #0

    //
    // Return to the caller.
    //
    pop     {pc}

    //
    // Perform a direct lookup of the value.
    //
direct_lookup_11
    ldr     r1, asin_table_flat_11
    ldr     r0, [r1, r0]
    lsr     r0, r0, #(31 - 11)
    bx      lr

    //
    // Special case handling of the value being 0 or 1.
    //
input_is_zero_or_one_11
    //
    // If the input was zero, return 0.  r0 is already appropriately set.
    //
    it      cc
    bxcc    lr
    ldr     r0, piq30_11
    lsr     r0, r0, #(30 - 11 + 1)
    teq     r12, #0xFFFFFFFF
    it      eq
        rsbeq   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
piq30_11
    dcd     0xc90fdaa2         // pi in Q30
asin_table_polynomial_11
    dcd     asin_table_polynomial
asin_table_flat_11
    dcd     asin_table_flat - 4

//*****************************************************************************
//
// _IQ12asin
//
//*****************************************************************************
    section CODE__IQ12asin:CODE(2)
    thumb
    export  _IQ12asin
_IQ12asin
    //
    // Take the negative absolute value of the input, store sign in r12
    // Taking the negative absolute value here saves 2 cycles later when we
    // truncate and look into the look up table.
    //
    asrs    r12, r0, #32
    it      pl
        rsbpl   r0, r0, #0

    //
    // Put the input in Q32, truncating mercilessly.
    // If the input is 0 or +/- 1, jump to a special handler.
    // Note that this will also jump for 1<=|x|<2.
    // We do not make any claims of what we return in |x|>1, so this is fine.
    //
    lsls    r0, r0, #(32 - 12)
    beq     input_is_zero_or_one_12

    //
    // Generate the lookup table index
    // This is given in a pseudo floating point format, with a 4 bit exponent
    // and a 5 bit mantissa.  The leading one is  omitted.  For example, the
    // number {N leading zeros, '1', A,B,C,D,etc} becomes  N,A,B,C,D
    //
    // This creates a table that has 16 entries of 4 words per log(2) chunk.
    //
    // Additionally, this section massages the input by the algorithm
    // described above. Briefly, z = (1-x) * 2^-floor(log2(1-x)).
    //
    // Since we use 64 words per bit, the last log2(64) = 6 bits are done
    // as a direct look up table to save space.
    //
    clz     r2, r0
    cmp     r2, #24
    bge     direct_lookup_12
    lsl     r0, r0, r2
    rsb     r1, r0, #-1
    lsr     r3, r1, #(32 - 5)
    bfi     r3, r2, #4, #5

    //
    // Point into the table with r3
    //
    ldr     r2, asin_table_polynomial_12
    add     r3, r2, r3, lsl #4

    //
    // Calculate the cubic approximating Polynomial
    // y = c0 + c1*x + c2*x^2 + c3*x^3
    //
    // Due to the transformation above, we can make the following assumptions:
    //      The magnitudes of c0-c3 are always less than 1.0
    //      c0 and c2 are always positive
    //      c1 and c3 are always negative
    //      x is always less than 1.0
    // This allows us to calculate the polynomial in unsigned Q32.Q32, which
    // provides a modest speed improvement over using e.g. signed Q31.
    //
    // The polynomial is re-arranged and calculated as follows:
    //      y =  c3 * x
    //      y = (c2 - y ) * x
    //      y = (c1 - y ) * x
    //      y = (c0 - y )
    //
    // r0 = x in UQ32
    // {r1,r2} = y
    // r3 = pointer to table
    // r4 = loaded coefficient
    //
    push    {lr}

    //
    // y =  c3 * x
    //
    ldr     lr, [r3]
    umull   r1, r2, r0, lr

    //
    // y = (c2 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c1 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c0 - y )
    //
    ldr     lr, [r3, #4]!
    sub     r0, lr, r2

    //
    // r0 now contains the result in UQ30
    // Normalize for Q and apply sign.
    //
    lsr     r0, r0, #(30 - 12)
    teq     r12, #0
    it      ne
        rsbne   r0, r0, #0

    //
    // Return to the caller.
    //
    pop     {pc}

    //
    // Perform a direct lookup of the value.
    //
direct_lookup_12
    ldr     r1, asin_table_flat_12
    ldr     r0, [r1, r0]
    lsr     r0, r0, #(31 - 12)
    bx      lr

    //
    // Special case handling of the value being 0 or 1.
    //
input_is_zero_or_one_12
    //
    // If the input was zero, return 0.  r0 is already appropriately set.
    //
    it      cc
    bxcc    lr
    ldr     r0, piq30_12
    lsr     r0, r0, #(30 - 12 + 1)
    teq     r12, #0xFFFFFFFF
    it      eq
        rsbeq   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
piq30_12
    dcd     0xc90fdaa2         // pi in Q30
asin_table_polynomial_12
    dcd     asin_table_polynomial
asin_table_flat_12
    dcd     asin_table_flat - 4

//*****************************************************************************
//
// _IQ13asin
//
//*****************************************************************************
    section CODE__IQ13asin:CODE(2)
    thumb
    export  _IQ13asin
_IQ13asin
    //
    // Take the negative absolute value of the input, store sign in r12
    // Taking the negative absolute value here saves 2 cycles later when we
    // truncate and look into the look up table.
    //
    asrs    r12, r0, #32
    it      pl
        rsbpl   r0, r0, #0

    //
    // Put the input in Q32, truncating mercilessly.
    // If the input is 0 or +/- 1, jump to a special handler.
    // Note that this will also jump for 1<=|x|<2.
    // We do not make any claims of what we return in |x|>1, so this is fine.
    //
    lsls    r0, r0, #(32 - 13)
    beq     input_is_zero_or_one_13

    //
    // Generate the lookup table index
    // This is given in a pseudo floating point format, with a 4 bit exponent
    // and a 5 bit mantissa.  The leading one is  omitted.  For example, the
    // number {N leading zeros, '1', A,B,C,D,etc} becomes  N,A,B,C,D
    //
    // This creates a table that has 16 entries of 4 words per log(2) chunk.
    //
    // Additionally, this section massages the input by the algorithm
    // described above. Briefly, z = (1-x) * 2^-floor(log2(1-x)).
    //
    // Since we use 64 words per bit, the last log2(64) = 6 bits are done
    // as a direct look up table to save space.
    //
    clz     r2, r0
    cmp     r2, #24
    bge     direct_lookup_13
    lsl     r0, r0, r2
    rsb     r1, r0, #-1
    lsr     r3, r1, #(32 - 5)
    bfi     r3, r2, #4, #5

    //
    // Point into the table with r3
    //
    ldr     r2, asin_table_polynomial_13
    add     r3, r2, r3, lsl #4

    //
    // Calculate the cubic approximating Polynomial
    // y = c0 + c1*x + c2*x^2 + c3*x^3
    //
    // Due to the transformation above, we can make the following assumptions:
    //      The magnitudes of c0-c3 are always less than 1.0
    //      c0 and c2 are always positive
    //      c1 and c3 are always negative
    //      x is always less than 1.0
    // This allows us to calculate the polynomial in unsigned Q32.Q32, which
    // provides a modest speed improvement over using e.g. signed Q31.
    //
    // The polynomial is re-arranged and calculated as follows:
    //      y =  c3 * x
    //      y = (c2 - y ) * x
    //      y = (c1 - y ) * x
    //      y = (c0 - y )
    //
    // r0 = x in UQ32
    // {r1,r2} = y
    // r3 = pointer to table
    // r4 = loaded coefficient
    //
    push    {lr}

    //
    // y =  c3 * x
    //
    ldr     lr, [r3]
    umull   r1, r2, r0, lr

    //
    // y = (c2 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c1 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c0 - y )
    //
    ldr     lr, [r3, #4]!
    sub     r0, lr, r2

    //
    // r0 now contains the result in UQ30
    // Normalize for Q and apply sign.
    //
    lsr     r0, r0, #(30 - 13)
    teq     r12, #0
    it      ne
        rsbne   r0, r0, #0

    //
    // Return to the caller.
    //
    pop     {pc}

    //
    // Perform a direct lookup of the value.
    //
direct_lookup_13
    ldr     r1, asin_table_flat_13
    ldr     r0, [r1, r0]
    lsr     r0, r0, #(31 - 13)
    bx      lr

    //
    // Special case handling of the value being 0 or 1.
    //
input_is_zero_or_one_13
    //
    // If the input was zero, return 0.  r0 is already appropriately set.
    //
    it      cc
    bxcc    lr
    ldr     r0, piq30_13
    lsr     r0, r0, #(30 - 13 + 1)
    teq     r12, #0xFFFFFFFF
    it      eq
        rsbeq   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
piq30_13
    dcd     0xc90fdaa2         // pi in Q30
asin_table_polynomial_13
    dcd     asin_table_polynomial
asin_table_flat_13
    dcd     asin_table_flat - 4

//*****************************************************************************
//
// _IQ14asin
//
//*****************************************************************************
    section CODE__IQ14asin:CODE(2)
    thumb
    export  _IQ14asin
_IQ14asin
    //
    // Take the negative absolute value of the input, store sign in r12
    // Taking the negative absolute value here saves 2 cycles later when we
    // truncate and look into the look up table.
    //
    asrs    r12, r0, #32
    it      pl
        rsbpl   r0, r0, #0

    //
    // Put the input in Q32, truncating mercilessly.
    // If the input is 0 or +/- 1, jump to a special handler.
    // Note that this will also jump for 1<=|x|<2.
    // We do not make any claims of what we return in |x|>1, so this is fine.
    //
    lsls    r0, r0, #(32 - 14)
    beq     input_is_zero_or_one_14

    //
    // Generate the lookup table index
    // This is given in a pseudo floating point format, with a 4 bit exponent
    // and a 5 bit mantissa.  The leading one is  omitted.  For example, the
    // number {N leading zeros, '1', A,B,C,D,etc} becomes  N,A,B,C,D
    //
    // This creates a table that has 16 entries of 4 words per log(2) chunk.
    //
    // Additionally, this section massages the input by the algorithm
    // described above. Briefly, z = (1-x) * 2^-floor(log2(1-x)).
    //
    // Since we use 64 words per bit, the last log2(64) = 6 bits are done
    // as a direct look up table to save space.
    //
    clz     r2, r0
    cmp     r2, #24
    bge     direct_lookup_14
    lsl     r0, r0, r2
    rsb     r1, r0, #-1
    lsr     r3, r1, #(32 - 5)
    bfi     r3, r2, #4, #5

    //
    // Point into the table with r3
    //
    ldr     r2, asin_table_polynomial_14
    add     r3, r2, r3, lsl #4

    //
    // Calculate the cubic approximating Polynomial
    // y = c0 + c1*x + c2*x^2 + c3*x^3
    //
    // Due to the transformation above, we can make the following assumptions:
    //      The magnitudes of c0-c3 are always less than 1.0
    //      c0 and c2 are always positive
    //      c1 and c3 are always negative
    //      x is always less than 1.0
    // This allows us to calculate the polynomial in unsigned Q32.Q32, which
    // provides a modest speed improvement over using e.g. signed Q31.
    //
    // The polynomial is re-arranged and calculated as follows:
    //      y =  c3 * x
    //      y = (c2 - y ) * x
    //      y = (c1 - y ) * x
    //      y = (c0 - y )
    //
    // r0 = x in UQ32
    // {r1,r2} = y
    // r3 = pointer to table
    // r4 = loaded coefficient
    //
    push    {lr}

    //
    // y =  c3 * x
    //
    ldr     lr, [r3]
    umull   r1, r2, r0, lr

    //
    // y = (c2 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c1 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c0 - y )
    //
    ldr     lr, [r3, #4]!
    sub     r0, lr, r2

    //
    // r0 now contains the result in UQ30
    // Normalize for Q and apply sign.
    //
    lsr     r0, r0, #(30 - 14)
    teq     r12, #0
    it      ne
        rsbne   r0, r0, #0

    //
    // Return to the caller.
    //
    pop     {pc}

    //
    // Perform a direct lookup of the value.
    //
direct_lookup_14
    ldr     r1, asin_table_flat_14
    ldr     r0, [r1, r0]
    lsr     r0, r0, #(31 - 14)
    bx      lr

    //
    // Special case handling of the value being 0 or 1.
    //
input_is_zero_or_one_14
    //
    // If the input was zero, return 0.  r0 is already appropriately set.
    //
    it      cc
    bxcc    lr
    ldr     r0, piq30_14
    lsr     r0, r0, #(30 - 14 + 1)
    teq     r12, #0xFFFFFFFF
    it      eq
        rsbeq   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
piq30_14
    dcd     0xc90fdaa2         // pi in Q30
asin_table_polynomial_14
    dcd     asin_table_polynomial
asin_table_flat_14
    dcd     asin_table_flat - 4

//*****************************************************************************
//
// _IQ15asin
//
//*****************************************************************************
    section CODE__IQ15asin:CODE(2)
    thumb
    export  _IQ15asin
_IQ15asin
    //
    // Take the negative absolute value of the input, store sign in r12
    // Taking the negative absolute value here saves 2 cycles later when we
    // truncate and look into the look up table.
    //
    asrs    r12, r0, #32
    it      pl
        rsbpl   r0, r0, #0

    //
    // Put the input in Q32, truncating mercilessly.
    // If the input is 0 or +/- 1, jump to a special handler.
    // Note that this will also jump for 1<=|x|<2.
    // We do not make any claims of what we return in |x|>1, so this is fine.
    //
    lsls    r0, r0, #(32 - 15)
    beq     input_is_zero_or_one_15

    //
    // Generate the lookup table index
    // This is given in a pseudo floating point format, with a 4 bit exponent
    // and a 5 bit mantissa.  The leading one is  omitted.  For example, the
    // number {N leading zeros, '1', A,B,C,D,etc} becomes  N,A,B,C,D
    //
    // This creates a table that has 16 entries of 4 words per log(2) chunk.
    //
    // Additionally, this section massages the input by the algorithm
    // described above. Briefly, z = (1-x) * 2^-floor(log2(1-x)).
    //
    // Since we use 64 words per bit, the last log2(64) = 6 bits are done
    // as a direct look up table to save space.
    //
    clz     r2, r0
    cmp     r2, #24
    bge     direct_lookup_15
    lsl     r0, r0, r2
    rsb     r1, r0, #-1
    lsr     r3, r1, #(32 - 5)
    bfi     r3, r2, #4, #5

    //
    // Point into the table with r3
    //
    ldr     r2, asin_table_polynomial_15
    add     r3, r2, r3, lsl #4

    //
    // Calculate the cubic approximating Polynomial
    // y = c0 + c1*x + c2*x^2 + c3*x^3
    //
    // Due to the transformation above, we can make the following assumptions:
    //      The magnitudes of c0-c3 are always less than 1.0
    //      c0 and c2 are always positive
    //      c1 and c3 are always negative
    //      x is always less than 1.0
    // This allows us to calculate the polynomial in unsigned Q32.Q32, which
    // provides a modest speed improvement over using e.g. signed Q31.
    //
    // The polynomial is re-arranged and calculated as follows:
    //      y =  c3 * x
    //      y = (c2 - y ) * x
    //      y = (c1 - y ) * x
    //      y = (c0 - y )
    //
    // r0 = x in UQ32
    // {r1,r2} = y
    // r3 = pointer to table
    // r4 = loaded coefficient
    //
    push    {lr}

    //
    // y =  c3 * x
    //
    ldr     lr, [r3]
    umull   r1, r2, r0, lr

    //
    // y = (c2 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c1 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c0 - y )
    //
    ldr     lr, [r3, #4]!
    sub     r0, lr, r2

    //
    // r0 now contains the result in UQ30
    // Normalize for Q and apply sign.
    //
    lsr     r0, r0, #(30 - 15)
    teq     r12, #0
    it      ne
        rsbne   r0, r0, #0

    //
    // Return to the caller.
    //
    pop     {pc}

    //
    // Perform a direct lookup of the value.
    //
direct_lookup_15
    ldr     r1, asin_table_flat_15
    ldr     r0, [r1, r0]
    lsr     r0, r0, #(31 - 15)
    bx      lr

    //
    // Special case handling of the value being 0 or 1.
    //
input_is_zero_or_one_15
    //
    // If the input was zero, return 0.  r0 is already appropriately set.
    //
    it      cc
    bxcc    lr
    ldr     r0, piq30_15
    lsr     r0, r0, #(30 - 15 + 1)
    teq     r12, #0xFFFFFFFF
    it      eq
        rsbeq   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
piq30_15
    dcd     0xc90fdaa2         // pi in Q30
asin_table_polynomial_15
    dcd     asin_table_polynomial
asin_table_flat_15
    dcd     asin_table_flat - 4

//*****************************************************************************
//
// _IQ16asin
//
//*****************************************************************************
    section CODE__IQ16asin:CODE(2)
    thumb
    export  _IQ16asin
_IQ16asin
    //
    // Take the negative absolute value of the input, store sign in r12
    // Taking the negative absolute value here saves 2 cycles later when we
    // truncate and look into the look up table.
    //
    asrs    r12, r0, #32
    it      pl
        rsbpl   r0, r0, #0

    //
    // Put the input in Q32, truncating mercilessly.
    // If the input is 0 or +/- 1, jump to a special handler.
    // Note that this will also jump for 1<=|x|<2.
    // We do not make any claims of what we return in |x|>1, so this is fine.
    //
    lsls    r0, r0, #(32 - 16)
    beq     input_is_zero_or_one_16

    //
    // Generate the lookup table index
    // This is given in a pseudo floating point format, with a 4 bit exponent
    // and a 5 bit mantissa.  The leading one is  omitted.  For example, the
    // number {N leading zeros, '1', A,B,C,D,etc} becomes  N,A,B,C,D
    //
    // This creates a table that has 16 entries of 4 words per log(2) chunk.
    //
    // Additionally, this section massages the input by the algorithm
    // described above. Briefly, z = (1-x) * 2^-floor(log2(1-x)).
    //
    // Since we use 64 words per bit, the last log2(64) = 6 bits are done
    // as a direct look up table to save space.
    //
    clz     r2, r0
    cmp     r2, #24
    bge     direct_lookup_16
    lsl     r0, r0, r2
    rsb     r1, r0, #-1
    lsr     r3, r1, #(32 - 5)
    bfi     r3, r2, #4, #5

    //
    // Point into the table with r3
    //
    ldr     r2, asin_table_polynomial_16
    add     r3, r2, r3, lsl #4

    //
    // Calculate the cubic approximating Polynomial
    // y = c0 + c1*x + c2*x^2 + c3*x^3
    //
    // Due to the transformation above, we can make the following assumptions:
    //      The magnitudes of c0-c3 are always less than 1.0
    //      c0 and c2 are always positive
    //      c1 and c3 are always negative
    //      x is always less than 1.0
    // This allows us to calculate the polynomial in unsigned Q32.Q32, which
    // provides a modest speed improvement over using e.g. signed Q31.
    //
    // The polynomial is re-arranged and calculated as follows:
    //      y =  c3 * x
    //      y = (c2 - y ) * x
    //      y = (c1 - y ) * x
    //      y = (c0 - y )
    //
    // r0 = x in UQ32
    // {r1,r2} = y
    // r3 = pointer to table
    // r4 = loaded coefficient
    //
    push    {lr}

    //
    // y =  c3 * x
    //
    ldr     lr, [r3]
    umull   r1, r2, r0, lr

    //
    // y = (c2 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c1 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c0 - y )
    //
    ldr     lr, [r3, #4]!
    sub     r0, lr, r2

    //
    // r0 now contains the result in UQ30
    // Normalize for Q and apply sign.
    //
    lsr     r0, r0, #(30 - 16)
    teq     r12, #0
    it      ne
        rsbne   r0, r0, #0

    //
    // Return to the caller.
    //
    pop     {pc}

    //
    // Perform a direct lookup of the value.
    //
direct_lookup_16
    ldr     r1, asin_table_flat_16
    ldr     r0, [r1, r0]
    lsr     r0, r0, #(31 - 16)
    bx      lr

    //
    // Special case handling of the value being 0 or 1.
    //
input_is_zero_or_one_16
    //
    // If the input was zero, return 0.  r0 is already appropriately set.
    //
    it      cc
    bxcc    lr
    ldr     r0, piq30_16
    lsr     r0, r0, #(30 - 16 + 1)
    teq     r12, #0xFFFFFFFF
    it      eq
        rsbeq   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
piq30_16
    dcd     0xc90fdaa2         // pi in Q30
asin_table_polynomial_16
    dcd     asin_table_polynomial
asin_table_flat_16
    dcd     asin_table_flat - 4

//*****************************************************************************
//
// _IQ17asin
//
//*****************************************************************************
    section CODE__IQ17asin:CODE(2)
    thumb
    export  _IQ17asin
_IQ17asin
    //
    // Take the negative absolute value of the input, store sign in r12
    // Taking the negative absolute value here saves 2 cycles later when we
    // truncate and look into the look up table.
    //
    asrs    r12, r0, #32
    it      pl
        rsbpl   r0, r0, #0

    //
    // Put the input in Q32, truncating mercilessly.
    // If the input is 0 or +/- 1, jump to a special handler.
    // Note that this will also jump for 1<=|x|<2.
    // We do not make any claims of what we return in |x|>1, so this is fine.
    //
    lsls    r0, r0, #(32 - 17)
    beq     input_is_zero_or_one_17

    //
    // Generate the lookup table index
    // This is given in a pseudo floating point format, with a 4 bit exponent
    // and a 5 bit mantissa.  The leading one is  omitted.  For example, the
    // number {N leading zeros, '1', A,B,C,D,etc} becomes  N,A,B,C,D
    //
    // This creates a table that has 16 entries of 4 words per log(2) chunk.
    //
    // Additionally, this section massages the input by the algorithm
    // described above. Briefly, z = (1-x) * 2^-floor(log2(1-x)).
    //
    // Since we use 64 words per bit, the last log2(64) = 6 bits are done
    // as a direct look up table to save space.
    //
    clz     r2, r0
    cmp     r2, #24
    bge     direct_lookup_17
    lsl     r0, r0, r2
    rsb     r1, r0, #-1
    lsr     r3, r1, #(32 - 5)
    bfi     r3, r2, #4, #5

    //
    // Point into the table with r3
    //
    ldr     r2, asin_table_polynomial_17
    add     r3, r2, r3, lsl #4

    //
    // Calculate the cubic approximating Polynomial
    // y = c0 + c1*x + c2*x^2 + c3*x^3
    //
    // Due to the transformation above, we can make the following assumptions:
    //      The magnitudes of c0-c3 are always less than 1.0
    //      c0 and c2 are always positive
    //      c1 and c3 are always negative
    //      x is always less than 1.0
    // This allows us to calculate the polynomial in unsigned Q32.Q32, which
    // provides a modest speed improvement over using e.g. signed Q31.
    //
    // The polynomial is re-arranged and calculated as follows:
    //      y =  c3 * x
    //      y = (c2 - y ) * x
    //      y = (c1 - y ) * x
    //      y = (c0 - y )
    //
    // r0 = x in UQ32
    // {r1,r2} = y
    // r3 = pointer to table
    // r4 = loaded coefficient
    //
    push    {lr}

    //
    // y =  c3 * x
    //
    ldr     lr, [r3]
    umull   r1, r2, r0, lr

    //
    // y = (c2 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c1 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c0 - y )
    //
    ldr     lr, [r3, #4]!
    sub     r0, lr, r2

    //
    // r0 now contains the result in UQ30
    // Normalize for Q and apply sign.
    //
    lsr     r0, r0, #(30 - 17)
    teq     r12, #0
    it      ne
        rsbne   r0, r0, #0

    //
    // Return to the caller.
    //
    pop     {pc}

    //
    // Perform a direct lookup of the value.
    //
direct_lookup_17
    ldr     r1, asin_table_flat_17
    ldr     r0, [r1, r0]
    lsr     r0, r0, #(31 - 17)
    bx      lr

    //
    // Special case handling of the value being 0 or 1.
    //
input_is_zero_or_one_17
    //
    // If the input was zero, return 0.  r0 is already appropriately set.
    //
    it      cc
    bxcc    lr
    ldr     r0, piq30_17
    lsr     r0, r0, #(30 - 17 + 1)
    teq     r12, #0xFFFFFFFF
    it      eq
        rsbeq   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
piq30_17
    dcd     0xc90fdaa2         // pi in Q30
asin_table_polynomial_17
    dcd     asin_table_polynomial
asin_table_flat_17
    dcd     asin_table_flat - 4

//*****************************************************************************
//
// _IQ18asin
//
//*****************************************************************************
    section CODE__IQ18asin:CODE(2)
    thumb
    export  _IQ18asin
_IQ18asin
    //
    // Take the negative absolute value of the input, store sign in r12
    // Taking the negative absolute value here saves 2 cycles later when we
    // truncate and look into the look up table.
    //
    asrs    r12, r0, #32
    it      pl
        rsbpl   r0, r0, #0

    //
    // Put the input in Q32, truncating mercilessly.
    // If the input is 0 or +/- 1, jump to a special handler.
    // Note that this will also jump for 1<=|x|<2.
    // We do not make any claims of what we return in |x|>1, so this is fine.
    //
    lsls    r0, r0, #(32 - 18)
    beq     input_is_zero_or_one_18

    //
    // Generate the lookup table index
    // This is given in a pseudo floating point format, with a 4 bit exponent
    // and a 5 bit mantissa.  The leading one is  omitted.  For example, the
    // number {N leading zeros, '1', A,B,C,D,etc} becomes  N,A,B,C,D
    //
    // This creates a table that has 16 entries of 4 words per log(2) chunk.
    //
    // Additionally, this section massages the input by the algorithm
    // described above. Briefly, z = (1-x) * 2^-floor(log2(1-x)).
    //
    // Since we use 64 words per bit, the last log2(64) = 6 bits are done
    // as a direct look up table to save space.
    //
    clz     r2, r0
    cmp     r2, #24
    bge     direct_lookup_18
    lsl     r0, r0, r2
    rsb     r1, r0, #-1
    lsr     r3, r1, #(32 - 5)
    bfi     r3, r2, #4, #5

    //
    // Point into the table with r3
    //
    ldr     r2, asin_table_polynomial_18
    add     r3, r2, r3, lsl #4

    //
    // Calculate the cubic approximating Polynomial
    // y = c0 + c1*x + c2*x^2 + c3*x^3
    //
    // Due to the transformation above, we can make the following assumptions:
    //      The magnitudes of c0-c3 are always less than 1.0
    //      c0 and c2 are always positive
    //      c1 and c3 are always negative
    //      x is always less than 1.0
    // This allows us to calculate the polynomial in unsigned Q32.Q32, which
    // provides a modest speed improvement over using e.g. signed Q31.
    //
    // The polynomial is re-arranged and calculated as follows:
    //      y =  c3 * x
    //      y = (c2 - y ) * x
    //      y = (c1 - y ) * x
    //      y = (c0 - y )
    //
    // r0 = x in UQ32
    // {r1,r2} = y
    // r3 = pointer to table
    // r4 = loaded coefficient
    //
    push    {lr}

    //
    // y =  c3 * x
    //
    ldr     lr, [r3]
    umull   r1, r2, r0, lr

    //
    // y = (c2 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c1 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c0 - y )
    //
    ldr     lr, [r3, #4]!
    sub     r0, lr, r2

    //
    // r0 now contains the result in UQ30
    // Normalize for Q and apply sign.
    //
    lsr     r0, r0, #(30 - 18)
    teq     r12, #0
    it      ne
        rsbne   r0, r0, #0

    //
    // Return to the caller.
    //
    pop     {pc}

    //
    // Perform a direct lookup of the value.
    //
direct_lookup_18
    ldr     r1, asin_table_flat_18
    ldr     r0, [r1, r0]
    lsr     r0, r0, #(31 - 18)
    bx      lr

    //
    // Special case handling of the value being 0 or 1.
    //
input_is_zero_or_one_18
    //
    // If the input was zero, return 0.  r0 is already appropriately set.
    //
    it      cc
    bxcc    lr
    ldr     r0, piq30_18
    lsr     r0, r0, #(30 - 18 + 1)
    teq     r12, #0xFFFFFFFF
    it      eq
        rsbeq   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
piq30_18
    dcd     0xc90fdaa2         // pi in Q30
asin_table_polynomial_18
    dcd     asin_table_polynomial
asin_table_flat_18
    dcd     asin_table_flat - 4

//*****************************************************************************
//
// _IQ19asin
//
//*****************************************************************************
    section CODE__IQ19asin:CODE(2)
    thumb
    export  _IQ19asin
_IQ19asin
    //
    // Take the negative absolute value of the input, store sign in r12
    // Taking the negative absolute value here saves 2 cycles later when we
    // truncate and look into the look up table.
    //
    asrs    r12, r0, #32
    it      pl
        rsbpl   r0, r0, #0

    //
    // Put the input in Q32, truncating mercilessly.
    // If the input is 0 or +/- 1, jump to a special handler.
    // Note that this will also jump for 1<=|x|<2.
    // We do not make any claims of what we return in |x|>1, so this is fine.
    //
    lsls    r0, r0, #(32 - 19)
    beq     input_is_zero_or_one_19

    //
    // Generate the lookup table index
    // This is given in a pseudo floating point format, with a 4 bit exponent
    // and a 5 bit mantissa.  The leading one is  omitted.  For example, the
    // number {N leading zeros, '1', A,B,C,D,etc} becomes  N,A,B,C,D
    //
    // This creates a table that has 16 entries of 4 words per log(2) chunk.
    //
    // Additionally, this section massages the input by the algorithm
    // described above. Briefly, z = (1-x) * 2^-floor(log2(1-x)).
    //
    // Since we use 64 words per bit, the last log2(64) = 6 bits are done
    // as a direct look up table to save space.
    //
    clz     r2, r0
    cmp     r2, #24
    bge     direct_lookup_19
    lsl     r0, r0, r2
    rsb     r1, r0, #-1
    lsr     r3, r1, #(32 - 5)
    bfi     r3, r2, #4, #5

    //
    // Point into the table with r3
    //
    ldr     r2, asin_table_polynomial_19
    add     r3, r2, r3, lsl #4

    //
    // Calculate the cubic approximating Polynomial
    // y = c0 + c1*x + c2*x^2 + c3*x^3
    //
    // Due to the transformation above, we can make the following assumptions:
    //      The magnitudes of c0-c3 are always less than 1.0
    //      c0 and c2 are always positive
    //      c1 and c3 are always negative
    //      x is always less than 1.0
    // This allows us to calculate the polynomial in unsigned Q32.Q32, which
    // provides a modest speed improvement over using e.g. signed Q31.
    //
    // The polynomial is re-arranged and calculated as follows:
    //      y =  c3 * x
    //      y = (c2 - y ) * x
    //      y = (c1 - y ) * x
    //      y = (c0 - y )
    //
    // r0 = x in UQ32
    // {r1,r2} = y
    // r3 = pointer to table
    // r4 = loaded coefficient
    //
    push    {lr}

    //
    // y =  c3 * x
    //
    ldr     lr, [r3]
    umull   r1, r2, r0, lr

    //
    // y = (c2 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c1 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c0 - y )
    //
    ldr     lr, [r3, #4]!
    sub     r0, lr, r2

    //
    // r0 now contains the result in UQ30
    // Normalize for Q and apply sign.
    //
    lsr     r0, r0, #(30 - 19)
    teq     r12, #0
    it      ne
        rsbne   r0, r0, #0

    //
    // Return to the caller.
    //
    pop     {pc}

    //
    // Perform a direct lookup of the value.
    //
direct_lookup_19
    ldr     r1, asin_table_flat_19
    ldr     r0, [r1, r0]
    lsr     r0, r0, #(31 - 19)
    bx      lr

    //
    // Special case handling of the value being 0 or 1.
    //
input_is_zero_or_one_19
    //
    // If the input was zero, return 0.  r0 is already appropriately set.
    //
    it      cc
    bxcc    lr
    ldr     r0, piq30_19
    lsr     r0, r0, #(30 - 19 + 1)
    teq     r12, #0xFFFFFFFF
    it      eq
        rsbeq   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
piq30_19
    dcd     0xc90fdaa2         // pi in Q30
asin_table_polynomial_19
    dcd     asin_table_polynomial
asin_table_flat_19
    dcd     asin_table_flat - 4

//*****************************************************************************
//
// _IQ20asin
//
//*****************************************************************************
    section CODE__IQ20asin:CODE(2)
    thumb
    export  _IQ20asin
_IQ20asin
    //
    // Take the negative absolute value of the input, store sign in r12
    // Taking the negative absolute value here saves 2 cycles later when we
    // truncate and look into the look up table.
    //
    asrs    r12, r0, #32
    it      pl
        rsbpl   r0, r0, #0

    //
    // Put the input in Q32, truncating mercilessly.
    // If the input is 0 or +/- 1, jump to a special handler.
    // Note that this will also jump for 1<=|x|<2.
    // We do not make any claims of what we return in |x|>1, so this is fine.
    //
    lsls    r0, r0, #(32 - 20)
    beq     input_is_zero_or_one_20

    //
    // Generate the lookup table index
    // This is given in a pseudo floating point format, with a 4 bit exponent
    // and a 5 bit mantissa.  The leading one is  omitted.  For example, the
    // number {N leading zeros, '1', A,B,C,D,etc} becomes  N,A,B,C,D
    //
    // This creates a table that has 16 entries of 4 words per log(2) chunk.
    //
    // Additionally, this section massages the input by the algorithm
    // described above. Briefly, z = (1-x) * 2^-floor(log2(1-x)).
    //
    // Since we use 64 words per bit, the last log2(64) = 6 bits are done
    // as a direct look up table to save space.
    //
    clz     r2, r0
    cmp     r2, #24
    bge     direct_lookup_20
    lsl     r0, r0, r2
    rsb     r1, r0, #-1
    lsr     r3, r1, #(32 - 5)
    bfi     r3, r2, #4, #5

    //
    // Point into the table with r3
    //
    ldr     r2, asin_table_polynomial_20
    add     r3, r2, r3, lsl #4

    //
    // Calculate the cubic approximating Polynomial
    // y = c0 + c1*x + c2*x^2 + c3*x^3
    //
    // Due to the transformation above, we can make the following assumptions:
    //      The magnitudes of c0-c3 are always less than 1.0
    //      c0 and c2 are always positive
    //      c1 and c3 are always negative
    //      x is always less than 1.0
    // This allows us to calculate the polynomial in unsigned Q32.Q32, which
    // provides a modest speed improvement over using e.g. signed Q31.
    //
    // The polynomial is re-arranged and calculated as follows:
    //      y =  c3 * x
    //      y = (c2 - y ) * x
    //      y = (c1 - y ) * x
    //      y = (c0 - y )
    //
    // r0 = x in UQ32
    // {r1,r2} = y
    // r3 = pointer to table
    // r4 = loaded coefficient
    //
    push    {lr}

    //
    // y =  c3 * x
    //
    ldr     lr, [r3]
    umull   r1, r2, r0, lr

    //
    // y = (c2 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c1 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c0 - y )
    //
    ldr     lr, [r3, #4]!
    sub     r0, lr, r2

    //
    // r0 now contains the result in UQ30
    // Normalize for Q and apply sign.
    //
    lsr     r0, r0, #(30 - 20)
    teq     r12, #0
    it      ne
        rsbne   r0, r0, #0

    //
    // Return to the caller.
    //
    pop     {pc}

    //
    // Perform a direct lookup of the value.
    //
direct_lookup_20
    ldr     r1, asin_table_flat_20
    ldr     r0, [r1, r0]
    lsr     r0, r0, #(31 - 20)
    bx      lr

    //
    // Special case handling of the value being 0 or 1.
    //
input_is_zero_or_one_20
    //
    // If the input was zero, return 0.  r0 is already appropriately set.
    //
    it      cc
    bxcc    lr
    ldr     r0, piq30_20
    lsr     r0, r0, #(30 - 20 + 1)
    teq     r12, #0xFFFFFFFF
    it      eq
        rsbeq   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
piq30_20
    dcd     0xc90fdaa2         // pi in Q30
asin_table_polynomial_20
    dcd     asin_table_polynomial
asin_table_flat_20
    dcd     asin_table_flat - 4

//*****************************************************************************
//
// _IQ21asin
//
//*****************************************************************************
    section CODE__IQ21asin:CODE(2)
    thumb
    export  _IQ21asin
_IQ21asin
    //
    // Take the negative absolute value of the input, store sign in r12
    // Taking the negative absolute value here saves 2 cycles later when we
    // truncate and look into the look up table.
    //
    asrs    r12, r0, #32
    it      pl
        rsbpl   r0, r0, #0

    //
    // Put the input in Q32, truncating mercilessly.
    // If the input is 0 or +/- 1, jump to a special handler.
    // Note that this will also jump for 1<=|x|<2.
    // We do not make any claims of what we return in |x|>1, so this is fine.
    //
    lsls    r0, r0, #(32 - 21)
    beq     input_is_zero_or_one_21

    //
    // Generate the lookup table index
    // This is given in a pseudo floating point format, with a 4 bit exponent
    // and a 5 bit mantissa.  The leading one is  omitted.  For example, the
    // number {N leading zeros, '1', A,B,C,D,etc} becomes  N,A,B,C,D
    //
    // This creates a table that has 16 entries of 4 words per log(2) chunk.
    //
    // Additionally, this section massages the input by the algorithm
    // described above. Briefly, z = (1-x) * 2^-floor(log2(1-x)).
    //
    // Since we use 64 words per bit, the last log2(64) = 6 bits are done
    // as a direct look up table to save space.
    //
    clz     r2, r0
    cmp     r2, #24
    bge     direct_lookup_21
    lsl     r0, r0, r2
    rsb     r1, r0, #-1
    lsr     r3, r1, #(32 - 5)
    bfi     r3, r2, #4, #5

    //
    // Point into the table with r3
    //
    ldr     r2, asin_table_polynomial_21
    add     r3, r2, r3, lsl #4

    //
    // Calculate the cubic approximating Polynomial
    // y = c0 + c1*x + c2*x^2 + c3*x^3
    //
    // Due to the transformation above, we can make the following assumptions:
    //      The magnitudes of c0-c3 are always less than 1.0
    //      c0 and c2 are always positive
    //      c1 and c3 are always negative
    //      x is always less than 1.0
    // This allows us to calculate the polynomial in unsigned Q32.Q32, which
    // provides a modest speed improvement over using e.g. signed Q31.
    //
    // The polynomial is re-arranged and calculated as follows:
    //      y =  c3 * x
    //      y = (c2 - y ) * x
    //      y = (c1 - y ) * x
    //      y = (c0 - y )
    //
    // r0 = x in UQ32
    // {r1,r2} = y
    // r3 = pointer to table
    // r4 = loaded coefficient
    //
    push    {lr}

    //
    // y =  c3 * x
    //
    ldr     lr, [r3]
    umull   r1, r2, r0, lr

    //
    // y = (c2 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c1 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c0 - y )
    //
    ldr     lr, [r3, #4]!
    sub     r0, lr, r2

    //
    // r0 now contains the result in UQ30
    // Normalize for Q and apply sign.
    //
    lsr     r0, r0, #(30 - 21)
    teq     r12, #0
    it      ne
        rsbne   r0, r0, #0

    //
    // Return to the caller.
    //
    pop     {pc}

    //
    // Perform a direct lookup of the value.
    //
direct_lookup_21
    ldr     r1, asin_table_flat_21
    ldr     r0, [r1, r0]
    lsr     r0, r0, #(31 - 21)
    bx      lr

    //
    // Special case handling of the value being 0 or 1.
    //
input_is_zero_or_one_21
    //
    // If the input was zero, return 0.  r0 is already appropriately set.
    //
    it      cc
    bxcc    lr
    ldr     r0, piq30_21
    lsr     r0, r0, #(30 - 21 + 1)
    teq     r12, #0xFFFFFFFF
    it      eq
        rsbeq   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
piq30_21
    dcd     0xc90fdaa2         // pi in Q30
asin_table_polynomial_21
    dcd     asin_table_polynomial
asin_table_flat_21
    dcd     asin_table_flat - 4

//*****************************************************************************
//
// _IQ22asin
//
//*****************************************************************************
    section CODE__IQ22asin:CODE(2)
    thumb
    export  _IQ22asin
_IQ22asin
    //
    // Take the negative absolute value of the input, store sign in r12
    // Taking the negative absolute value here saves 2 cycles later when we
    // truncate and look into the look up table.
    //
    asrs    r12, r0, #32
    it      pl
        rsbpl   r0, r0, #0

    //
    // Put the input in Q32, truncating mercilessly.
    // If the input is 0 or +/- 1, jump to a special handler.
    // Note that this will also jump for 1<=|x|<2.
    // We do not make any claims of what we return in |x|>1, so this is fine.
    //
    lsls    r0, r0, #(32 - 22)
    beq     input_is_zero_or_one_22

    //
    // Generate the lookup table index
    // This is given in a pseudo floating point format, with a 4 bit exponent
    // and a 5 bit mantissa.  The leading one is  omitted.  For example, the
    // number {N leading zeros, '1', A,B,C,D,etc} becomes  N,A,B,C,D
    //
    // This creates a table that has 16 entries of 4 words per log(2) chunk.
    //
    // Additionally, this section massages the input by the algorithm
    // described above. Briefly, z = (1-x) * 2^-floor(log2(1-x)).
    //
    // Since we use 64 words per bit, the last log2(64) = 6 bits are done
    // as a direct look up table to save space.
    //
    clz     r2, r0
    cmp     r2, #24
    bge     direct_lookup_22
    lsl     r0, r0, r2
    rsb     r1, r0, #-1
    lsr     r3, r1, #(32 - 5)
    bfi     r3, r2, #4, #5

    //
    // Point into the table with r3
    //
    ldr     r2, asin_table_polynomial_22
    add     r3, r2, r3, lsl #4

    //
    // Calculate the cubic approximating Polynomial
    // y = c0 + c1*x + c2*x^2 + c3*x^3
    //
    // Due to the transformation above, we can make the following assumptions:
    //      The magnitudes of c0-c3 are always less than 1.0
    //      c0 and c2 are always positive
    //      c1 and c3 are always negative
    //      x is always less than 1.0
    // This allows us to calculate the polynomial in unsigned Q32.Q32, which
    // provides a modest speed improvement over using e.g. signed Q31.
    //
    // The polynomial is re-arranged and calculated as follows:
    //      y =  c3 * x
    //      y = (c2 - y ) * x
    //      y = (c1 - y ) * x
    //      y = (c0 - y )
    //
    // r0 = x in UQ32
    // {r1,r2} = y
    // r3 = pointer to table
    // r4 = loaded coefficient
    //
    push    {lr}

    //
    // y =  c3 * x
    //
    ldr     lr, [r3]
    umull   r1, r2, r0, lr

    //
    // y = (c2 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c1 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c0 - y )
    //
    ldr     lr, [r3, #4]!
    sub     r0, lr, r2

    //
    // r0 now contains the result in UQ30
    // Normalize for Q and apply sign.
    //
    lsr     r0, r0, #(30 - 22)
    teq     r12, #0
    it      ne
        rsbne   r0, r0, #0

    //
    // Return to the caller.
    //
    pop     {pc}

    //
    // Perform a direct lookup of the value.
    //
direct_lookup_22
    ldr     r1, asin_table_flat_22
    ldr     r0, [r1, r0]
    lsr     r0, r0, #(31 - 22)
    bx      lr

    //
    // Special case handling of the value being 0 or 1.
    //
input_is_zero_or_one_22
    //
    // If the input was zero, return 0.  r0 is already appropriately set.
    //
    it      cc
    bxcc    lr
    ldr     r0, piq30_22
    lsr     r0, r0, #(30 - 22 + 1)
    teq     r12, #0xFFFFFFFF
    it      eq
        rsbeq   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
piq30_22
    dcd     0xc90fdaa2         // pi in Q30
asin_table_polynomial_22
    dcd     asin_table_polynomial
asin_table_flat_22
    dcd     asin_table_flat - 4

//*****************************************************************************
//
// _IQ23asin
//
//*****************************************************************************
    section CODE__IQ23asin:CODE(2)
    thumb
    export  _IQ23asin
_IQ23asin
    //
    // Take the negative absolute value of the input, store sign in r12
    // Taking the negative absolute value here saves 2 cycles later when we
    // truncate and look into the look up table.
    //
    asrs    r12, r0, #32
    it      pl
        rsbpl   r0, r0, #0

    //
    // Put the input in Q32, truncating mercilessly.
    // If the input is 0 or +/- 1, jump to a special handler.
    // Note that this will also jump for 1<=|x|<2.
    // We do not make any claims of what we return in |x|>1, so this is fine.
    //
    lsls    r0, r0, #(32 - 23)
    beq     input_is_zero_or_one_23

    //
    // Generate the lookup table index
    // This is given in a pseudo floating point format, with a 4 bit exponent
    // and a 5 bit mantissa.  The leading one is  omitted.  For example, the
    // number {N leading zeros, '1', A,B,C,D,etc} becomes  N,A,B,C,D
    //
    // This creates a table that has 16 entries of 4 words per log(2) chunk.
    //
    // Additionally, this section massages the input by the algorithm
    // described above. Briefly, z = (1-x) * 2^-floor(log2(1-x)).
    //
    // Since we use 64 words per bit, the last log2(64) = 6 bits are done
    // as a direct look up table to save space.
    //
    clz     r2, r0
    cmp     r2, #24
    bge     direct_lookup_23
    lsl     r0, r0, r2
    rsb     r1, r0, #-1
    lsr     r3, r1, #(32 - 5)
    bfi     r3, r2, #4, #5

    //
    // Point into the table with r3
    //
    ldr     r2, asin_table_polynomial_23
    add     r3, r2, r3, lsl #4

    //
    // Calculate the cubic approximating Polynomial
    // y = c0 + c1*x + c2*x^2 + c3*x^3
    //
    // Due to the transformation above, we can make the following assumptions:
    //      The magnitudes of c0-c3 are always less than 1.0
    //      c0 and c2 are always positive
    //      c1 and c3 are always negative
    //      x is always less than 1.0
    // This allows us to calculate the polynomial in unsigned Q32.Q32, which
    // provides a modest speed improvement over using e.g. signed Q31.
    //
    // The polynomial is re-arranged and calculated as follows:
    //      y =  c3 * x
    //      y = (c2 - y ) * x
    //      y = (c1 - y ) * x
    //      y = (c0 - y )
    //
    // r0 = x in UQ32
    // {r1,r2} = y
    // r3 = pointer to table
    // r4 = loaded coefficient
    //
    push    {lr}

    //
    // y =  c3 * x
    //
    ldr     lr, [r3]
    umull   r1, r2, r0, lr

    //
    // y = (c2 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c1 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c0 - y )
    //
    ldr     lr, [r3, #4]!
    sub     r0, lr, r2

    //
    // r0 now contains the result in UQ30
    // Normalize for Q and apply sign.
    //
    lsr     r0, r0, #(30 - 23)
    teq     r12, #0
    it      ne
        rsbne   r0, r0, #0

    //
    // Return to the caller.
    //
    pop     {pc}

    //
    // Perform a direct lookup of the value.
    //
direct_lookup_23
    ldr     r1, asin_table_flat_23
    ldr     r0, [r1, r0]
    lsr     r0, r0, #(31 - 23)
    bx      lr

    //
    // Special case handling of the value being 0 or 1.
    //
input_is_zero_or_one_23
    //
    // If the input was zero, return 0.  r0 is already appropriately set.
    //
    it      cc
    bxcc    lr
    ldr     r0, piq30_23
    lsr     r0, r0, #(30 - 23 + 1)
    teq     r12, #0xFFFFFFFF
    it      eq
        rsbeq   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
piq30_23
    dcd     0xc90fdaa2         // pi in Q30
asin_table_polynomial_23
    dcd     asin_table_polynomial
asin_table_flat_23
    dcd     asin_table_flat - 4

//*****************************************************************************
//
// _IQ24asin
//
//*****************************************************************************
    section CODE__IQ24asin:CODE(2)
    thumb
    export  _IQ24asin
_IQ24asin
    //
    // Take the negative absolute value of the input, store sign in r12
    // Taking the negative absolute value here saves 2 cycles later when we
    // truncate and look into the look up table.
    //
    asrs    r12, r0, #32
    it      pl
        rsbpl   r0, r0, #0

    //
    // Put the input in Q32, truncating mercilessly.
    // If the input is 0 or +/- 1, jump to a special handler.
    // Note that this will also jump for 1<=|x|<2.
    // We do not make any claims of what we return in |x|>1, so this is fine.
    //
    lsls    r0, r0, #(32 - 24)
    beq     input_is_zero_or_one_24

    //
    // Generate the lookup table index
    // This is given in a pseudo floating point format, with a 4 bit exponent
    // and a 5 bit mantissa.  The leading one is  omitted.  For example, the
    // number {N leading zeros, '1', A,B,C,D,etc} becomes  N,A,B,C,D
    //
    // This creates a table that has 16 entries of 4 words per log(2) chunk.
    //
    // Additionally, this section massages the input by the algorithm
    // described above. Briefly, z = (1-x) * 2^-floor(log2(1-x)).
    //
    // Since we use 64 words per bit, the last log2(64) = 6 bits are done
    // as a direct look up table to save space.
    //
    clz     r2, r0
    cmp     r2, #24
    bge     direct_lookup_24
    lsl     r0, r0, r2
    rsb     r1, r0, #-1
    lsr     r3, r1, #(32 - 5)
    bfi     r3, r2, #4, #5

    //
    // Point into the table with r3
    //
    ldr     r2, asin_table_polynomial_24
    add     r3, r2, r3, lsl #4

    //
    // Calculate the cubic approximating Polynomial
    // y = c0 + c1*x + c2*x^2 + c3*x^3
    //
    // Due to the transformation above, we can make the following assumptions:
    //      The magnitudes of c0-c3 are always less than 1.0
    //      c0 and c2 are always positive
    //      c1 and c3 are always negative
    //      x is always less than 1.0
    // This allows us to calculate the polynomial in unsigned Q32.Q32, which
    // provides a modest speed improvement over using e.g. signed Q31.
    //
    // The polynomial is re-arranged and calculated as follows:
    //      y =  c3 * x
    //      y = (c2 - y ) * x
    //      y = (c1 - y ) * x
    //      y = (c0 - y )
    //
    // r0 = x in UQ32
    // {r1,r2} = y
    // r3 = pointer to table
    // r4 = loaded coefficient
    //
    push    {lr}

    //
    // y =  c3 * x
    //
    ldr     lr, [r3]
    umull   r1, r2, r0, lr

    //
    // y = (c2 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c1 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c0 - y )
    //
    ldr     lr, [r3, #4]!
    sub     r0, lr, r2

    //
    // r0 now contains the result in UQ30
    // Normalize for Q and apply sign.
    //
    lsr     r0, r0, #(30 - 24)
    teq     r12, #0
    it      ne
        rsbne   r0, r0, #0

    //
    // Return to the caller.
    //
    pop     {pc}

    //
    // Perform a direct lookup of the value.
    //
direct_lookup_24
    ldr     r1, asin_table_flat_24
    ldr     r0, [r1, r0]
    lsr     r0, r0, #(31 - 24)
    bx      lr

    //
    // Special case handling of the value being 0 or 1.
    //
input_is_zero_or_one_24
    //
    // If the input was zero, return 0.  r0 is already appropriately set.
    //
    it      cc
    bxcc    lr
    ldr     r0, piq30_24
    lsr     r0, r0, #(30 - 24 + 1)
    teq     r12, #0xFFFFFFFF
    it      eq
        rsbeq   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
piq30_24
    dcd     0xc90fdaa2         // pi in Q30
asin_table_polynomial_24
    dcd     asin_table_polynomial
asin_table_flat_24
    dcd     asin_table_flat - 4

//*****************************************************************************
//
// _IQ25asin
//
//*****************************************************************************
    section CODE__IQ25asin:CODE(2)
    thumb
    export  _IQ25asin
_IQ25asin
    //
    // Take the negative absolute value of the input, store sign in r12
    // Taking the negative absolute value here saves 2 cycles later when we
    // truncate and look into the look up table.
    //
    asrs    r12, r0, #32
    it      pl
        rsbpl   r0, r0, #0

    //
    // Put the input in Q32, truncating mercilessly.
    // If the input is 0 or +/- 1, jump to a special handler.
    // Note that this will also jump for 1<=|x|<2.
    // We do not make any claims of what we return in |x|>1, so this is fine.
    //
    lsls    r0, r0, #(32 - 25)
    beq     input_is_zero_or_one_25

    //
    // Generate the lookup table index
    // This is given in a pseudo floating point format, with a 4 bit exponent
    // and a 5 bit mantissa.  The leading one is  omitted.  For example, the
    // number {N leading zeros, '1', A,B,C,D,etc} becomes  N,A,B,C,D
    //
    // This creates a table that has 16 entries of 4 words per log(2) chunk.
    //
    // Additionally, this section massages the input by the algorithm
    // described above. Briefly, z = (1-x) * 2^-floor(log2(1-x)).
    //
    // Since we use 64 words per bit, the last log2(64) = 6 bits are done
    // as a direct look up table to save space.
    //
    clz     r2, r0
    cmp     r2, #24
    bge     direct_lookup_25
    lsl     r0, r0, r2
    rsb     r1, r0, #-1
    lsr     r3, r1, #(32 - 5)
    bfi     r3, r2, #4, #5

    //
    // Point into the table with r3
    //
    ldr     r2, asin_table_polynomial_25
    add     r3, r2, r3, lsl #4

    //
    // Calculate the cubic approximating Polynomial
    // y = c0 + c1*x + c2*x^2 + c3*x^3
    //
    // Due to the transformation above, we can make the following assumptions:
    //      The magnitudes of c0-c3 are always less than 1.0
    //      c0 and c2 are always positive
    //      c1 and c3 are always negative
    //      x is always less than 1.0
    // This allows us to calculate the polynomial in unsigned Q32.Q32, which
    // provides a modest speed improvement over using e.g. signed Q31.
    //
    // The polynomial is re-arranged and calculated as follows:
    //      y =  c3 * x
    //      y = (c2 - y ) * x
    //      y = (c1 - y ) * x
    //      y = (c0 - y )
    //
    // r0 = x in UQ32
    // {r1,r2} = y
    // r3 = pointer to table
    // r4 = loaded coefficient
    //
    push    {lr}

    //
    // y =  c3 * x
    //
    ldr     lr, [r3]
    umull   r1, r2, r0, lr

    //
    // y = (c2 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c1 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c0 - y )
    //
    ldr     lr, [r3, #4]!
    sub     r0, lr, r2

    //
    // r0 now contains the result in UQ30
    // Normalize for Q and apply sign.
    //
    lsr     r0, r0, #(30 - 25)
    teq     r12, #0
    it      ne
        rsbne   r0, r0, #0

    //
    // Return to the caller.
    //
    pop     {pc}

    //
    // Perform a direct lookup of the value.
    //
direct_lookup_25
    ldr     r1, asin_table_flat_25
    ldr     r0, [r1, r0]
    lsr     r0, r0, #(31 - 25)
    bx      lr

    //
    // Special case handling of the value being 0 or 1.
    //
input_is_zero_or_one_25
    //
    // If the input was zero, return 0.  r0 is already appropriately set.
    //
    it      cc
    bxcc    lr
    ldr     r0, piq30_25
    lsr     r0, r0, #(30 - 25 + 1)
    teq     r12, #0xFFFFFFFF
    it      eq
        rsbeq   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
piq30_25
    dcd     0xc90fdaa2         // pi in Q30
asin_table_polynomial_25
    dcd     asin_table_polynomial
asin_table_flat_25
    dcd     asin_table_flat - 4

//*****************************************************************************
//
// _IQ26asin
//
//*****************************************************************************
    section CODE__IQ26asin:CODE(2)
    thumb
    export  _IQ26asin
_IQ26asin
    //
    // Take the negative absolute value of the input, store sign in r12
    // Taking the negative absolute value here saves 2 cycles later when we
    // truncate and look into the look up table.
    //
    asrs    r12, r0, #32
    it      pl
        rsbpl   r0, r0, #0

    //
    // Put the input in Q32, truncating mercilessly.
    // If the input is 0 or +/- 1, jump to a special handler.
    // Note that this will also jump for 1<=|x|<2.
    // We do not make any claims of what we return in |x|>1, so this is fine.
    //
    lsls    r0, r0, #(32 - 26)
    beq     input_is_zero_or_one_26

    //
    // Generate the lookup table index
    // This is given in a pseudo floating point format, with a 4 bit exponent
    // and a 5 bit mantissa.  The leading one is  omitted.  For example, the
    // number {N leading zeros, '1', A,B,C,D,etc} becomes  N,A,B,C,D
    //
    // This creates a table that has 16 entries of 4 words per log(2) chunk.
    //
    // Additionally, this section massages the input by the algorithm
    // described above. Briefly, z = (1-x) * 2^-floor(log2(1-x)).
    //
    // Since we use 64 words per bit, the last log2(64) = 6 bits are done
    // as a direct look up table to save space.
    //
    clz     r2, r0
    cmp     r2, #24
    bge     direct_lookup_26
    lsl     r0, r0, r2
    rsb     r1, r0, #-1
    lsr     r3, r1, #(32 - 5)
    bfi     r3, r2, #4, #5

    //
    // Point into the table with r3
    //
    ldr     r2, asin_table_polynomial_26
    add     r3, r2, r3, lsl #4

    //
    // Calculate the cubic approximating Polynomial
    // y = c0 + c1*x + c2*x^2 + c3*x^3
    //
    // Due to the transformation above, we can make the following assumptions:
    //      The magnitudes of c0-c3 are always less than 1.0
    //      c0 and c2 are always positive
    //      c1 and c3 are always negative
    //      x is always less than 1.0
    // This allows us to calculate the polynomial in unsigned Q32.Q32, which
    // provides a modest speed improvement over using e.g. signed Q31.
    //
    // The polynomial is re-arranged and calculated as follows:
    //      y =  c3 * x
    //      y = (c2 - y ) * x
    //      y = (c1 - y ) * x
    //      y = (c0 - y )
    //
    // r0 = x in UQ32
    // {r1,r2} = y
    // r3 = pointer to table
    // r4 = loaded coefficient
    //
    push    {lr}

    //
    // y =  c3 * x
    //
    ldr     lr, [r3]
    umull   r1, r2, r0, lr

    //
    // y = (c2 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c1 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c0 - y )
    //
    ldr     lr, [r3, #4]!
    sub     r0, lr, r2

    //
    // r0 now contains the result in UQ30
    // Normalize for Q and apply sign.
    //
    lsr     r0, r0, #(30 - 26)
    teq     r12, #0
    it      ne
        rsbne   r0, r0, #0

    //
    // Return to the caller.
    //
    pop     {pc}

    //
    // Perform a direct lookup of the value.
    //
direct_lookup_26
    ldr     r1, asin_table_flat_26
    ldr     r0, [r1, r0]
    lsr     r0, r0, #(31 - 26)
    bx      lr

    //
    // Special case handling of the value being 0 or 1.
    //
input_is_zero_or_one_26
    //
    // If the input was zero, return 0.  r0 is already appropriately set.
    //
    it      cc
    bxcc    lr
    ldr     r0, piq30_26
    lsr     r0, r0, #(30 - 26 + 1)
    teq     r12, #0xFFFFFFFF
    it      eq
        rsbeq   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
piq30_26
    dcd     0xc90fdaa2         // pi in Q30
asin_table_polynomial_26
    dcd     asin_table_polynomial
asin_table_flat_26
    dcd     asin_table_flat - 4

//*****************************************************************************
//
// _IQ27asin
//
//*****************************************************************************
    section CODE__IQ27asin:CODE(2)
    thumb
    export  _IQ27asin
_IQ27asin
    //
    // Take the negative absolute value of the input, store sign in r12
    // Taking the negative absolute value here saves 2 cycles later when we
    // truncate and look into the look up table.
    //
    asrs    r12, r0, #32
    it      pl
        rsbpl   r0, r0, #0

    //
    // Put the input in Q32, truncating mercilessly.
    // If the input is 0 or +/- 1, jump to a special handler.
    // Note that this will also jump for 1<=|x|<2.
    // We do not make any claims of what we return in |x|>1, so this is fine.
    //
    lsls    r0, r0, #(32 - 27)
    beq     input_is_zero_or_one_27

    //
    // Generate the lookup table index
    // This is given in a pseudo floating point format, with a 4 bit exponent
    // and a 5 bit mantissa.  The leading one is  omitted.  For example, the
    // number {N leading zeros, '1', A,B,C,D,etc} becomes  N,A,B,C,D
    //
    // This creates a table that has 16 entries of 4 words per log(2) chunk.
    //
    // Additionally, this section massages the input by the algorithm
    // described above. Briefly, z = (1-x) * 2^-floor(log2(1-x)).
    //
    // Since we use 64 words per bit, the last log2(64) = 6 bits are done
    // as a direct look up table to save space.
    //
    clz     r2, r0
    cmp     r2, #24
    bge     direct_lookup_27
    lsl     r0, r0, r2
    rsb     r1, r0, #-1
    lsr     r3, r1, #(32 - 5)
    bfi     r3, r2, #4, #5

    //
    // Point into the table with r3
    //
    ldr     r2, asin_table_polynomial_27
    add     r3, r2, r3, lsl #4

    //
    // Calculate the cubic approximating Polynomial
    // y = c0 + c1*x + c2*x^2 + c3*x^3
    //
    // Due to the transformation above, we can make the following assumptions:
    //      The magnitudes of c0-c3 are always less than 1.0
    //      c0 and c2 are always positive
    //      c1 and c3 are always negative
    //      x is always less than 1.0
    // This allows us to calculate the polynomial in unsigned Q32.Q32, which
    // provides a modest speed improvement over using e.g. signed Q31.
    //
    // The polynomial is re-arranged and calculated as follows:
    //      y =  c3 * x
    //      y = (c2 - y ) * x
    //      y = (c1 - y ) * x
    //      y = (c0 - y )
    //
    // r0 = x in UQ32
    // {r1,r2} = y
    // r3 = pointer to table
    // r4 = loaded coefficient
    //
    push    {lr}

    //
    // y =  c3 * x
    //
    ldr     lr, [r3]
    umull   r1, r2, r0, lr

    //
    // y = (c2 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c1 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c0 - y )
    //
    ldr     lr, [r3, #4]!
    sub     r0, lr, r2

    //
    // r0 now contains the result in UQ30
    // Normalize for Q and apply sign.
    //
    lsr     r0, r0, #(30 - 27)
    teq     r12, #0
    it      ne
        rsbne   r0, r0, #0

    //
    // Return to the caller.
    //
    pop     {pc}

    //
    // Perform a direct lookup of the value.
    //
direct_lookup_27
    ldr     r1, asin_table_flat_27
    ldr     r0, [r1, r0]
    lsr     r0, r0, #(31 - 27)
    bx      lr

    //
    // Special case handling of the value being 0 or 1.
    //
input_is_zero_or_one_27
    //
    // If the input was zero, return 0.  r0 is already appropriately set.
    //
    it      cc
    bxcc    lr
    ldr     r0, piq30_27
    lsr     r0, r0, #(30 - 27 + 1)
    teq     r12, #0xFFFFFFFF
    it      eq
        rsbeq   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
piq30_27
    dcd     0xc90fdaa2         // pi in Q30
asin_table_polynomial_27
    dcd     asin_table_polynomial
asin_table_flat_27
    dcd     asin_table_flat - 4

//*****************************************************************************
//
// _IQ28asin
//
//*****************************************************************************
    section CODE__IQ28asin:CODE(2)
    thumb
    export  _IQ28asin
_IQ28asin
    //
    // Take the negative absolute value of the input, store sign in r12
    // Taking the negative absolute value here saves 2 cycles later when we
    // truncate and look into the look up table.
    //
    asrs    r12, r0, #32
    it      pl
        rsbpl   r0, r0, #0

    //
    // Put the input in Q32, truncating mercilessly.
    // If the input is 0 or +/- 1, jump to a special handler.
    // Note that this will also jump for 1<=|x|<2.
    // We do not make any claims of what we return in |x|>1, so this is fine.
    //
    lsls    r0, r0, #(32 - 28)
    beq     input_is_zero_or_one_28

    //
    // Generate the lookup table index
    // This is given in a pseudo floating point format, with a 4 bit exponent
    // and a 5 bit mantissa.  The leading one is  omitted.  For example, the
    // number {N leading zeros, '1', A,B,C,D,etc} becomes  N,A,B,C,D
    //
    // This creates a table that has 16 entries of 4 words per log(2) chunk.
    //
    // Additionally, this section massages the input by the algorithm
    // described above. Briefly, z = (1-x) * 2^-floor(log2(1-x)).
    //
    // Since we use 64 words per bit, the last log2(64) = 6 bits are done
    // as a direct look up table to save space.
    //
    clz     r2, r0
    cmp     r2, #24
    bge     direct_lookup_28
    lsl     r0, r0, r2
    rsb     r1, r0, #-1
    lsr     r3, r1, #(32 - 5)
    bfi     r3, r2, #4, #5

    //
    // Point into the table with r3
    //
    ldr     r2, asin_table_polynomial_28
    add     r3, r2, r3, lsl #4

    //
    // Calculate the cubic approximating Polynomial
    // y = c0 + c1*x + c2*x^2 + c3*x^3
    //
    // Due to the transformation above, we can make the following assumptions:
    //      The magnitudes of c0-c3 are always less than 1.0
    //      c0 and c2 are always positive
    //      c1 and c3 are always negative
    //      x is always less than 1.0
    // This allows us to calculate the polynomial in unsigned Q32.Q32, which
    // provides a modest speed improvement over using e.g. signed Q31.
    //
    // The polynomial is re-arranged and calculated as follows:
    //      y =  c3 * x
    //      y = (c2 - y ) * x
    //      y = (c1 - y ) * x
    //      y = (c0 - y )
    //
    // r0 = x in UQ32
    // {r1,r2} = y
    // r3 = pointer to table
    // r4 = loaded coefficient
    //
    push    {lr}

    //
    // y =  c3 * x
    //
    ldr     lr, [r3]
    umull   r1, r2, r0, lr

    //
    // y = (c2 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c1 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c0 - y )
    //
    ldr     lr, [r3, #4]!
    sub     r0, lr, r2

    //
    // r0 now contains the result in UQ30
    // Normalize for Q and apply sign.
    //
    lsr     r0, r0, #(30 - 28)
    teq     r12, #0
    it      ne
        rsbne   r0, r0, #0

    //
    // Return to the caller.
    //
    pop     {pc}

    //
    // Perform a direct lookup of the value.
    //
direct_lookup_28
    ldr     r1, asin_table_flat_28
    ldr     r0, [r1, r0]
    lsr     r0, r0, #(31 - 28)
    bx      lr

    //
    // Special case handling of the value being 0 or 1.
    //
input_is_zero_or_one_28
    //
    // If the input was zero, return 0.  r0 is already appropriately set.
    //
    it      cc
    bxcc    lr
    ldr     r0, piq30_28
    lsr     r0, r0, #(30 - 28 + 1)
    teq     r12, #0xFFFFFFFF
    it      eq
        rsbeq   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
piq30_28
    dcd     0xc90fdaa2         // pi in Q30
asin_table_polynomial_28
    dcd     asin_table_polynomial
asin_table_flat_28
    dcd     asin_table_flat - 4

//*****************************************************************************
//
// _IQ29asin
//
//*****************************************************************************
    section CODE__IQ29asin:CODE(2)
    thumb
    export  _IQ29asin
_IQ29asin
    //
    // Take the negative absolute value of the input, store sign in r12
    // Taking the negative absolute value here saves 2 cycles later when we
    // truncate and look into the look up table.
    //
    asrs    r12, r0, #32
    it      pl
        rsbpl   r0, r0, #0

    //
    // Put the input in Q32, truncating mercilessly.
    // If the input is 0 or +/- 1, jump to a special handler.
    // Note that this will also jump for 1<=|x|<2.
    // We do not make any claims of what we return in |x|>1, so this is fine.
    //
    lsls    r0, r0, #(32 - 29)
    beq     input_is_zero_or_one_29

    //
    // Generate the lookup table index
    // This is given in a pseudo floating point format, with a 4 bit exponent
    // and a 5 bit mantissa.  The leading one is  omitted.  For example, the
    // number {N leading zeros, '1', A,B,C,D,etc} becomes  N,A,B,C,D
    //
    // This creates a table that has 16 entries of 4 words per log(2) chunk.
    //
    // Additionally, this section massages the input by the algorithm
    // described above. Briefly, z = (1-x) * 2^-floor(log2(1-x)).
    //
    // Since we use 64 words per bit, the last log2(64) = 6 bits are done
    // as a direct look up table to save space.
    //
    clz     r2, r0
    cmp     r2, #24
    bge     direct_lookup_29
    lsl     r0, r0, r2
    rsb     r1, r0, #-1
    lsr     r3, r1, #(32 - 5)
    bfi     r3, r2, #4, #5

    //
    // Point into the table with r3
    //
    ldr     r2, asin_table_polynomial_29
    add     r3, r2, r3, lsl #4

    //
    // Calculate the cubic approximating Polynomial
    // y = c0 + c1*x + c2*x^2 + c3*x^3
    //
    // Due to the transformation above, we can make the following assumptions:
    //      The magnitudes of c0-c3 are always less than 1.0
    //      c0 and c2 are always positive
    //      c1 and c3 are always negative
    //      x is always less than 1.0
    // This allows us to calculate the polynomial in unsigned Q32.Q32, which
    // provides a modest speed improvement over using e.g. signed Q31.
    //
    // The polynomial is re-arranged and calculated as follows:
    //      y =  c3 * x
    //      y = (c2 - y ) * x
    //      y = (c1 - y ) * x
    //      y = (c0 - y )
    //
    // r0 = x in UQ32
    // {r1,r2} = y
    // r3 = pointer to table
    // r4 = loaded coefficient
    //
    push    {lr}

    //
    // y =  c3 * x
    //
    ldr     lr, [r3]
    umull   r1, r2, r0, lr

    //
    // y = (c2 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c1 - y ) * x
    //
    ldr     lr, [r3, #4]!
    sub     lr, lr, r2
    umull   r1, r2, r0, lr

    //
    // y = (c0 - y )
    //
    ldr     lr, [r3, #4]!
    sub     r0, lr, r2

    //
    // r0 now contains the result in UQ30
    // Normalize for Q and apply sign.
    //
    lsr     r0, r0, #(30 - 29)
    teq     r12, #0
    it      ne
        rsbne   r0, r0, #0

    //
    // Return to the caller.
    //
    pop     {pc}

    //
    // Perform a direct lookup of the value.
    //
direct_lookup_29
    ldr     r1, asin_table_flat_29
    ldr     r0, [r1, r0]
    lsr     r0, r0, #(31 - 29)
    bx      lr

    //
    // Special case handling of the value being 0 or 1.
    //
input_is_zero_or_one_29
    //
    // If the input was zero, return 0.  r0 is already appropriately set.
    //
    it      cc
    bxcc    lr
    ldr     r0, piq30_29
    lsr     r0, r0, #(30 - 29 + 1)
    teq     r12, #0xFFFFFFFF
    it      eq
        rsbeq   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
piq30_29
    dcd     0xc90fdaa2         // pi in Q30
asin_table_polynomial_29
    dcd     asin_table_polynomial
asin_table_flat_29
    dcd     asin_table_flat - 4

        end
