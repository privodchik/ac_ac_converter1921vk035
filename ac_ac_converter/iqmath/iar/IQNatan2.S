//******************************************************************************
//
// IQatan2.S - Fixed point calculation of atan2 in radians
//
// Copyright (c) 2010 Texas Instruments Incorporated.  All rights reserved.
// TI Information - Selective Disclosure
//
//******************************************************************************

//******************************************************************************
//
// Function:   _IQNatan2
//
//******************************************************************************
//
// C Usage:    extern long _IQNatan2(long y,long x);
//
//-----------------------------------------------------------------------------
//
// On Entry:   r0    = y in IQ format
//             r1    = x in IQ format
//
// Regs Used:
//
// On Exit:    r0    = atan2(y,x)
//
//
// Q range:    29 to 1
//
//-----------------------------------------------------------------------------
//
// Algorithm:  The procedure for calculating "Z = atan2(y,x)" is as follows:
//
// Algorithm:
//          Step 1) Take the absolute value of both inputs and store sign
//                  information
//
//          Step 2) Choose whether to calculate as Z = atan(x/y)
//                                              or Z = pi/2-acot(y/x)
//                  This is done to keep the calculated ratio within
//                  representable limits: [0,1)
//                  if |x|>|y|
//                      Numerator   = |y|
//                      Denominator = |x|
//                  else
//                      Numerator   = |x|
//                      Denominator = |y|
//
//          Step 3) Ratio = Numerator / Denominator : [0,1)
//
//          Step 4) Use the upper 8 bits of Ratio to look up coefficients for
//                  the approximating polynomial.
//
//          Step 5) Calculate the appoximating polynomial.
//              partial_angle : [0,pi/4)
//
//          Step 6) Place the resulting angle in the correct octant.
//              if |x|>|y|
//                  partial_angle = pi/2-partial_angle
//
//              if x>=0 and y>=0
//                  result = partial_angle
//              if x>=0 and y>=0 and |x|<|y|
//                  result = - partial_angle
//              if x<0  and y>=0 and |x|<|y|
//                  result = pi - partial_angle
//              if x>=0 and y>=0 and |x|>|y|
//                  result = pi + partial_angle
//
//-----------------------------------------------------------------------------
//
// Benchmark:
//      Equal Inputs  :  40-48 Cycles
//      x=y=0         :  20 Cycles
//      Octant 1      :  99 Cycles
//      Octant 2      : 103 Cycles
//      Octant 3      : 105 Cycles
//      Octant 4      : 100 Cycles
//      Octant 5      : 103 Cycles
//      Octant 6      : 107 Cycles
//      Octant 7      : 105 Cycles
//      Octant 8      : 101 Cycles
//  Note:
//   Inputs of less than 16 bits process up to 2 cycles quicker.
//   Some regions within an octant will process up to 2 cycles quicker; This
//   happens due to early break out from a UMULL for small inputs.
//
//*****************************************************************************

//*****************************************************************************
//
// The division and atan2PU tables are used.
//
//*****************************************************************************
    import  div_table
    import  atan2PU_table

//*****************************************************************************
//
// _IQ1atan2
//
//*****************************************************************************
    section CODE__IQ1atan2:CODE(2)
    thumb
    export  _IQ1atan2
_IQ1atan2
    //
    // Take absolute values of inputs and store sign information in r12.
    // r12[29] =  Y < 0
    // r12[30] =  X < 0
    // r12[31] = |Y|>|X|
    //
    ands    r12, r0, #0x80000000
    it      ne
        rsbne   r0, r0, #0
    lsls    r2, r1, #1
    it      cs
        rsbcs   r1, r1, #0
    rrx     r12, r12

    //
    // Place the larger of the two inputs in r1, the smaller in r0.
    // Remember this decision in R12.
    //
    cmp     r0, r1
    rrx     r12, r12
    beq     operands_are_equal_1
    ittt    hi
        movhi   r2, r0
        movhi   r0, r1
        movhi   r1, r2

    //
    // Divide r0 by r1 to find the ratio
    // Save state to stack.
    //
    push    {r4, r5}

    //
    // Normalize denominator to (1.0 0.5) in Q32
    //
    clz     r5, r1
    lsl     r1, r1, r5

    //
    //    r0 numerator GQ       r1 normalized denominator Q32
    //    r2 1/denominator Q31  r3 normalization n I
    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r1, #(32 - 10)
    ldr     r3, div_table_1
    ldr     r2, [r3, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // Dm = 2(Dm - Dm^2*Dnorm/2)
    // r2 = 2(r2 - r2^2*r1/2)
    // r1:Q32, r2:Q31
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sub     r3, r2, r3
    lsl     r2, r3, #1

    //
    // Newton Raphson Iteration  #2
    // 8-12 Cycles
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sbc     r2, r2, r3

    //
    // Multiply numerator by 1/denominator:
    // r2 is in Q29
    //
    umull   r1, r0, r0, r2

    //
    // Prepare the shift values.
    // Put the result in Q31.
    // Do not round, for fear of overflow.
    //
    add     r5, r5, #2
    rsb     r4, r5, #32
    lsr     r1, r1, r4
    lsl     r0, r0, r5
    add     r0, r0, r1

    //
    // r0 holds the calculated ratio of the inputs as UQ32.
    // r1 - r5 are available for use, r4 is saved on the stack.
    // r12 contains information on which octant the final result should be in.
    //
    // Use the top 8 bits of the ratio as a table index into the lookup table.
    // Multiply it by 3 because there are 3 coefficients per index value.
    //
    // There may be a wasted cycle here; It adds the offset to the table index
    // separately. This is so that r3 is updated to the appropriate position
    // for the next 2 loads.
    //
    lsr     r2, r0, #(32 - 8)
    add     r2, r2, r2, lsl #1
    ldr     r3, atan2PU_table_1
    add     r3, r3, r2, lsl #2

    //
    // r0       ratio of inputs in UQ32
    // {r1,r2}
    // r3       Pointer into lookup table
    // r4       Loaded coefficient
    //
    ldr     r4, [r3]
    umull   r2, r1, r4, r0
    ldrd    r4, r5, [r3, #4]!
    sub     r4, r4, r1
    umull   r2, r1, r0, r4
    add     r0, r1, r5

    //
    // Divide by four to get to Q30.  Consider working this into coefficients
    // to save one cycle.
    //
    lsr     r0, r0, #2

    //
    // r0 : atanPU of input, within the first octant, UQ30.  [0,.5)
    // R12: Destination Octant >
    //      r12[31] = |Y|>|X|
    //      r12[30] =  X < 0
    //      r12[29] =  Y < 0
    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
equal_operands_reentry_point_1
    lsls    r12, r12, #1

    //
    //  if(|y|>|x|) r0 = 0.5 - r0
    //
    it      cs
        rsbcs   r0, r0, #0x20000000

    //
    //  if( x < 0 ) r0 = 1.0 - r0
    //
    it      mi
        rsbmi   r0, r0, #0x40000000

    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
    lsls    r12, r12, #1
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply by pi to return to radians from CPU.
    //
    ldr     r1, piq29_1
    smull   r1, r0, r1, r0

    //
    // Shift result to normalize from Q27.
    //
    asrs    r0, r0, #(27 - 1)
    adc     r0, r0, #0
    pop     {r4, r5}
    bx      lr

    //
    // If the operands are (0,0), the answer is defined to be zero.  This is
    // consistent with the standard C definition.
    //
operands_are_equal_1
    teq     r0, #0
    it      eq
        bxeq    lr

    //
    // If the operands are equal but nonzero, the result is one of the 45's
    // Skip the division etc and re-enter normal program flow just before
    // octant determination after setting the "result" to an eighth PU radian.
    //
    // Push r4 and r5 for consistency, even though we don't use them in this
    // execution path.
    //
    mov     r0, #0x10000000
    push    {r4, r5}
    b       equal_operands_reentry_point_1

    //
    // The literal pool.
    //
    alignrom 2
    data
piq29_1
    dcd     0x6487ed51         // pi in Q29
div_table_1
    dcd     div_table - 0x800
atan2PU_table_1
    dcd     atan2PU_table

//*****************************************************************************
//
// _IQ2atan2
//
//*****************************************************************************
    section CODE__IQ2atan2:CODE(2)
    thumb
    export  _IQ2atan2
_IQ2atan2
    //
    // Take absolute values of inputs and store sign information in r12.
    // r12[29] =  Y < 0
    // r12[30] =  X < 0
    // r12[31] = |Y|>|X|
    //
    ands    r12, r0, #0x80000000
    it      ne
        rsbne   r0, r0, #0
    lsls    r2, r1, #1
    it      cs
        rsbcs   r1, r1, #0
    rrx     r12, r12

    //
    // Place the larger of the two inputs in r1, the smaller in r0.
    // Remember this decision in R12.
    //
    cmp     r0, r1
    rrx     r12, r12
    beq     operands_are_equal_2
    ittt    hi
        movhi   r2, r0
        movhi   r0, r1
        movhi   r1, r2

    //
    // Divide r0 by r1 to find the ratio
    // Save state to stack.
    //
    push    {r4, r5}

    //
    // Normalize denominator to (1.0 0.5) in Q32
    //
    clz     r5, r1
    lsl     r1, r1, r5

    //
    //    r0 numerator GQ       r1 normalized denominator Q32
    //    r2 1/denominator Q31  r3 normalization n I
    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r1, #(32 - 10)
    ldr     r3, div_table_2
    ldr     r2, [r3, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // Dm = 2(Dm - Dm^2*Dnorm/2)
    // r2 = 2(r2 - r2^2*r1/2)
    // r1:Q32, r2:Q31
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sub     r3, r2, r3
    lsl     r2, r3, #1

    //
    // Newton Raphson Iteration  #2
    // 8-12 Cycles
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sbc     r2, r2, r3

    //
    // Multiply numerator by 1/denominator:
    // r2 is in Q29
    //
    umull   r1, r0, r0, r2

    //
    // Prepare the shift values.
    // Put the result in Q31.
    // Do not round, for fear of overflow.
    //
    add     r5, r5, #2
    rsb     r4, r5, #32
    lsr     r1, r1, r4
    lsl     r0, r0, r5
    add     r0, r0, r1

    //
    // r0 holds the calculated ratio of the inputs as UQ32.
    // r1 - r5 are available for use, r4 is saved on the stack.
    // r12 contains information on which octant the final result should be in.
    //
    // Use the top 8 bits of the ratio as a table index into the lookup table.
    // Multiply it by 3 because there are 3 coefficients per index value.
    //
    // There may be a wasted cycle here; It adds the offset to the table index
    // separately. This is so that r3 is updated to the appropriate position
    // for the next 2 loads.
    //
    lsr     r2, r0, #(32 - 8)
    add     r2, r2, r2, lsl #1
    ldr     r3, atan2PU_table_2
    add     r3, r3, r2, lsl #2

    //
    // r0       ratio of inputs in UQ32
    // {r1,r2}
    // r3       Pointer into lookup table
    // r4       Loaded coefficient
    //
    ldr     r4, [r3]
    umull   r2, r1, r4, r0
    ldrd    r4, r5, [r3, #4]!
    sub     r4, r4, r1
    umull   r2, r1, r0, r4
    add     r0, r1, r5

    //
    // Divide by four to get to Q30.  Consider working this into coefficients
    // to save one cycle.
    //
    lsr     r0, r0, #2

    //
    // r0 : atanPU of input, within the first octant, UQ30.  [0,.5)
    // R12: Destination Octant >
    //      r12[31] = |Y|>|X|
    //      r12[30] =  X < 0
    //      r12[29] =  Y < 0
    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
equal_operands_reentry_point_2
    lsls    r12, r12, #1

    //
    //  if(|y|>|x|) r0 = 0.5 - r0
    //
    it      cs
        rsbcs   r0, r0, #0x20000000

    //
    //  if( x < 0 ) r0 = 1.0 - r0
    //
    it      mi
        rsbmi   r0, r0, #0x40000000

    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
    lsls    r12, r12, #1
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply by pi to return to radians from CPU.
    //
    ldr     r1, piq29_2
    smull   r1, r0, r1, r0

    //
    // Shift result to normalize from Q27.
    //
    asrs    r0, r0, #(27 - 2)
    adc     r0, r0, #0
    pop     {r4, r5}
    bx      lr

    //
    // If the operands are (0,0), the answer is defined to be zero.  This is
    // consistent with the standard C definition.
    //
operands_are_equal_2
    teq     r0, #0
    it      eq
        bxeq    lr

    //
    // If the operands are equal but nonzero, the result is one of the 45's
    // Skip the division etc and re-enter normal program flow just before
    // octant determination after setting the "result" to an eighth PU radian.
    //
    // Push r4 and r5 for consistency, even though we don't use them in this
    // execution path.
    //
    mov     r0, #0x10000000
    push    {r4, r5}
    b       equal_operands_reentry_point_2

    //
    // The literal pool.
    //
    alignrom 2
    data
piq29_2
    dcd     0x6487ed51         // pi in Q29
div_table_2
    dcd     div_table - 0x800
atan2PU_table_2
    dcd     atan2PU_table

//*****************************************************************************
//
// _IQ3atan2
//
//*****************************************************************************
    section CODE__IQ3atan2:CODE(2)
    thumb
    export  _IQ3atan2
_IQ3atan2
    //
    // Take absolute values of inputs and store sign information in r12.
    // r12[29] =  Y < 0
    // r12[30] =  X < 0
    // r12[31] = |Y|>|X|
    //
    ands    r12, r0, #0x80000000
    it      ne
        rsbne   r0, r0, #0
    lsls    r2, r1, #1
    it      cs
        rsbcs   r1, r1, #0
    rrx     r12, r12

    //
    // Place the larger of the two inputs in r1, the smaller in r0.
    // Remember this decision in R12.
    //
    cmp     r0, r1
    rrx     r12, r12
    beq     operands_are_equal_3
    ittt    hi
        movhi   r2, r0
        movhi   r0, r1
        movhi   r1, r2

    //
    // Divide r0 by r1 to find the ratio
    // Save state to stack.
    //
    push    {r4, r5}

    //
    // Normalize denominator to (1.0 0.5) in Q32
    //
    clz     r5, r1
    lsl     r1, r1, r5

    //
    //    r0 numerator GQ       r1 normalized denominator Q32
    //    r2 1/denominator Q31  r3 normalization n I
    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r1, #(32 - 10)
    ldr     r3, div_table_3
    ldr     r2, [r3, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // Dm = 2(Dm - Dm^2*Dnorm/2)
    // r2 = 2(r2 - r2^2*r1/2)
    // r1:Q32, r2:Q31
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sub     r3, r2, r3
    lsl     r2, r3, #1

    //
    // Newton Raphson Iteration  #2
    // 8-12 Cycles
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sbc     r2, r2, r3

    //
    // Multiply numerator by 1/denominator:
    // r2 is in Q29
    //
    umull   r1, r0, r0, r2

    //
    // Prepare the shift values.
    // Put the result in Q31.
    // Do not round, for fear of overflow.
    //
    add     r5, r5, #2
    rsb     r4, r5, #32
    lsr     r1, r1, r4
    lsl     r0, r0, r5
    add     r0, r0, r1

    //
    // r0 holds the calculated ratio of the inputs as UQ32.
    // r1 - r5 are available for use, r4 is saved on the stack.
    // r12 contains information on which octant the final result should be in.
    //
    // Use the top 8 bits of the ratio as a table index into the lookup table.
    // Multiply it by 3 because there are 3 coefficients per index value.
    //
    // There may be a wasted cycle here; It adds the offset to the table index
    // separately. This is so that r3 is updated to the appropriate position
    // for the next 2 loads.
    //
    lsr     r2, r0, #(32 - 8)
    add     r2, r2, r2, lsl #1
    ldr     r3, atan2PU_table_3
    add     r3, r3, r2, lsl #2

    //
    // r0       ratio of inputs in UQ32
    // {r1,r2}
    // r3       Pointer into lookup table
    // r4       Loaded coefficient
    //
    ldr     r4, [r3]
    umull   r2, r1, r4, r0
    ldrd    r4, r5, [r3, #4]!
    sub     r4, r4, r1
    umull   r2, r1, r0, r4
    add     r0, r1, r5

    //
    // Divide by four to get to Q30.  Consider working this into coefficients
    // to save one cycle.
    //
    lsr     r0, r0, #2

    //
    // r0 : atanPU of input, within the first octant, UQ30.  [0,.5)
    // R12: Destination Octant >
    //      r12[31] = |Y|>|X|
    //      r12[30] =  X < 0
    //      r12[29] =  Y < 0
    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
equal_operands_reentry_point_3
    lsls    r12, r12, #1

    //
    //  if(|y|>|x|) r0 = 0.5 - r0
    //
    it      cs
        rsbcs   r0, r0, #0x20000000

    //
    //  if( x < 0 ) r0 = 1.0 - r0
    //
    it      mi
        rsbmi   r0, r0, #0x40000000

    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
    lsls    r12, r12, #1
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply by pi to return to radians from CPU.
    //
    ldr     r1, piq29_3
    smull   r1, r0, r1, r0

    //
    // Shift result to normalize from Q27.
    //
    asrs    r0, r0, #(27 - 3)
    adc     r0, r0, #0
    pop     {r4, r5}
    bx      lr

    //
    // If the operands are (0,0), the answer is defined to be zero.  This is
    // consistent with the standard C definition.
    //
operands_are_equal_3
    teq     r0, #0
    it      eq
        bxeq    lr

    //
    // If the operands are equal but nonzero, the result is one of the 45's
    // Skip the division etc and re-enter normal program flow just before
    // octant determination after setting the "result" to an eighth PU radian.
    //
    // Push r4 and r5 for consistency, even though we don't use them in this
    // execution path.
    //
    mov     r0, #0x10000000
    push    {r4, r5}
    b       equal_operands_reentry_point_3

    //
    // The literal pool.
    //
    alignrom 2
    data
piq29_3
    dcd     0x6487ed51         // pi in Q29
div_table_3
    dcd     div_table - 0x800
atan2PU_table_3
    dcd     atan2PU_table

//*****************************************************************************
//
// _IQ4atan2
//
//*****************************************************************************
    section CODE__IQ4atan2:CODE(2)
    thumb
    export  _IQ4atan2
_IQ4atan2
    //
    // Take absolute values of inputs and store sign information in r12.
    // r12[29] =  Y < 0
    // r12[30] =  X < 0
    // r12[31] = |Y|>|X|
    //
    ands    r12, r0, #0x80000000
    it      ne
        rsbne   r0, r0, #0
    lsls    r2, r1, #1
    it      cs
        rsbcs   r1, r1, #0
    rrx     r12, r12

    //
    // Place the larger of the two inputs in r1, the smaller in r0.
    // Remember this decision in R12.
    //
    cmp     r0, r1
    rrx     r12, r12
    beq     operands_are_equal_4
    ittt    hi
        movhi   r2, r0
        movhi   r0, r1
        movhi   r1, r2

    //
    // Divide r0 by r1 to find the ratio
    // Save state to stack.
    //
    push    {r4, r5}

    //
    // Normalize denominator to (1.0 0.5) in Q32
    //
    clz     r5, r1
    lsl     r1, r1, r5

    //
    //    r0 numerator GQ       r1 normalized denominator Q32
    //    r2 1/denominator Q31  r3 normalization n I
    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r1, #(32 - 10)
    ldr     r3, div_table_4
    ldr     r2, [r3, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // Dm = 2(Dm - Dm^2*Dnorm/2)
    // r2 = 2(r2 - r2^2*r1/2)
    // r1:Q32, r2:Q31
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sub     r3, r2, r3
    lsl     r2, r3, #1

    //
    // Newton Raphson Iteration  #2
    // 8-12 Cycles
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sbc     r2, r2, r3

    //
    // Multiply numerator by 1/denominator:
    // r2 is in Q29
    //
    umull   r1, r0, r0, r2

    //
    // Prepare the shift values.
    // Put the result in Q31.
    // Do not round, for fear of overflow.
    //
    add     r5, r5, #2
    rsb     r4, r5, #32
    lsr     r1, r1, r4
    lsl     r0, r0, r5
    add     r0, r0, r1

    //
    // r0 holds the calculated ratio of the inputs as UQ32.
    // r1 - r5 are available for use, r4 is saved on the stack.
    // r12 contains information on which octant the final result should be in.
    //
    // Use the top 8 bits of the ratio as a table index into the lookup table.
    // Multiply it by 3 because there are 3 coefficients per index value.
    //
    // There may be a wasted cycle here; It adds the offset to the table index
    // separately. This is so that r3 is updated to the appropriate position
    // for the next 2 loads.
    //
    lsr     r2, r0, #(32 - 8)
    add     r2, r2, r2, lsl #1
    ldr     r3, atan2PU_table_4
    add     r3, r3, r2, lsl #2

    //
    // r0       ratio of inputs in UQ32
    // {r1,r2}
    // r3       Pointer into lookup table
    // r4       Loaded coefficient
    //
    ldr     r4, [r3]
    umull   r2, r1, r4, r0
    ldrd    r4, r5, [r3, #4]!
    sub     r4, r4, r1
    umull   r2, r1, r0, r4
    add     r0, r1, r5

    //
    // Divide by four to get to Q30.  Consider working this into coefficients
    // to save one cycle.
    //
    lsr     r0, r0, #2

    //
    // r0 : atanPU of input, within the first octant, UQ30.  [0,.5)
    // R12: Destination Octant >
    //      r12[31] = |Y|>|X|
    //      r12[30] =  X < 0
    //      r12[29] =  Y < 0
    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
equal_operands_reentry_point_4
    lsls    r12, r12, #1

    //
    //  if(|y|>|x|) r0 = 0.5 - r0
    //
    it      cs
        rsbcs   r0, r0, #0x20000000

    //
    //  if( x < 0 ) r0 = 1.0 - r0
    //
    it      mi
        rsbmi   r0, r0, #0x40000000

    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
    lsls    r12, r12, #1
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply by pi to return to radians from CPU.
    //
    ldr     r1, piq29_4
    smull   r1, r0, r1, r0

    //
    // Shift result to normalize from Q27.
    //
    asrs    r0, r0, #(27 - 4)
    adc     r0, r0, #0
    pop     {r4, r5}
    bx      lr

    //
    // If the operands are (0,0), the answer is defined to be zero.  This is
    // consistent with the standard C definition.
    //
operands_are_equal_4
    teq     r0, #0
    it      eq
        bxeq    lr

    //
    // If the operands are equal but nonzero, the result is one of the 45's
    // Skip the division etc and re-enter normal program flow just before
    // octant determination after setting the "result" to an eighth PU radian.
    //
    // Push r4 and r5 for consistency, even though we don't use them in this
    // execution path.
    //
    mov     r0, #0x10000000
    push    {r4, r5}
    b       equal_operands_reentry_point_4

    //
    // The literal pool.
    //
    alignrom 2
    data
piq29_4
    dcd     0x6487ed51         // pi in Q29
div_table_4
    dcd     div_table - 0x800
atan2PU_table_4
    dcd     atan2PU_table

//*****************************************************************************
//
// _IQ5atan2
//
//*****************************************************************************
    section CODE__IQ5atan2:CODE(2)
    thumb
    export  _IQ5atan2
_IQ5atan2
    //
    // Take absolute values of inputs and store sign information in r12.
    // r12[29] =  Y < 0
    // r12[30] =  X < 0
    // r12[31] = |Y|>|X|
    //
    ands    r12, r0, #0x80000000
    it      ne
        rsbne   r0, r0, #0
    lsls    r2, r1, #1
    it      cs
        rsbcs   r1, r1, #0
    rrx     r12, r12

    //
    // Place the larger of the two inputs in r1, the smaller in r0.
    // Remember this decision in R12.
    //
    cmp     r0, r1
    rrx     r12, r12
    beq     operands_are_equal_5
    ittt    hi
        movhi   r2, r0
        movhi   r0, r1
        movhi   r1, r2

    //
    // Divide r0 by r1 to find the ratio
    // Save state to stack.
    //
    push    {r4, r5}

    //
    // Normalize denominator to (1.0 0.5) in Q32
    //
    clz     r5, r1
    lsl     r1, r1, r5

    //
    //    r0 numerator GQ       r1 normalized denominator Q32
    //    r2 1/denominator Q31  r3 normalization n I
    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r1, #(32 - 10)
    ldr     r3, div_table_5
    ldr     r2, [r3, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // Dm = 2(Dm - Dm^2*Dnorm/2)
    // r2 = 2(r2 - r2^2*r1/2)
    // r1:Q32, r2:Q31
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sub     r3, r2, r3
    lsl     r2, r3, #1

    //
    // Newton Raphson Iteration  #2
    // 8-12 Cycles
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sbc     r2, r2, r3

    //
    // Multiply numerator by 1/denominator:
    // r2 is in Q29
    //
    umull   r1, r0, r0, r2

    //
    // Prepare the shift values.
    // Put the result in Q31.
    // Do not round, for fear of overflow.
    //
    add     r5, r5, #2
    rsb     r4, r5, #32
    lsr     r1, r1, r4
    lsl     r0, r0, r5
    add     r0, r0, r1

    //
    // r0 holds the calculated ratio of the inputs as UQ32.
    // r1 - r5 are available for use, r4 is saved on the stack.
    // r12 contains information on which octant the final result should be in.
    //
    // Use the top 8 bits of the ratio as a table index into the lookup table.
    // Multiply it by 3 because there are 3 coefficients per index value.
    //
    // There may be a wasted cycle here; It adds the offset to the table index
    // separately. This is so that r3 is updated to the appropriate position
    // for the next 2 loads.
    //
    lsr     r2, r0, #(32 - 8)
    add     r2, r2, r2, lsl #1
    ldr     r3, atan2PU_table_5
    add     r3, r3, r2, lsl #2

    //
    // r0       ratio of inputs in UQ32
    // {r1,r2}
    // r3       Pointer into lookup table
    // r4       Loaded coefficient
    //
    ldr     r4, [r3]
    umull   r2, r1, r4, r0
    ldrd    r4, r5, [r3, #4]!
    sub     r4, r4, r1
    umull   r2, r1, r0, r4
    add     r0, r1, r5

    //
    // Divide by four to get to Q30.  Consider working this into coefficients
    // to save one cycle.
    //
    lsr     r0, r0, #2

    //
    // r0 : atanPU of input, within the first octant, UQ30.  [0,.5)
    // R12: Destination Octant >
    //      r12[31] = |Y|>|X|
    //      r12[30] =  X < 0
    //      r12[29] =  Y < 0
    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
equal_operands_reentry_point_5
    lsls    r12, r12, #1

    //
    //  if(|y|>|x|) r0 = 0.5 - r0
    //
    it      cs
        rsbcs   r0, r0, #0x20000000

    //
    //  if( x < 0 ) r0 = 1.0 - r0
    //
    it      mi
        rsbmi   r0, r0, #0x40000000

    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
    lsls    r12, r12, #1
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply by pi to return to radians from CPU.
    //
    ldr     r1, piq29_5
    smull   r1, r0, r1, r0

    //
    // Shift result to normalize from Q27.
    //
    asrs    r0, r0, #(27 - 5)
    adc     r0, r0, #0
    pop     {r4, r5}
    bx      lr

    //
    // If the operands are (0,0), the answer is defined to be zero.  This is
    // consistent with the standard C definition.
    //
operands_are_equal_5
    teq     r0, #0
    it      eq
        bxeq    lr

    //
    // If the operands are equal but nonzero, the result is one of the 45's
    // Skip the division etc and re-enter normal program flow just before
    // octant determination after setting the "result" to an eighth PU radian.
    //
    // Push r4 and r5 for consistency, even though we don't use them in this
    // execution path.
    //
    mov     r0, #0x10000000
    push    {r4, r5}
    b       equal_operands_reentry_point_5

    //
    // The literal pool.
    //
    alignrom 2
    data
piq29_5
    dcd     0x6487ed51         // pi in Q29
div_table_5
    dcd     div_table - 0x800
atan2PU_table_5
    dcd     atan2PU_table

//*****************************************************************************
//
// _IQ6atan2
//
//*****************************************************************************
    section CODE__IQ6atan2:CODE(2)
    thumb
    export  _IQ6atan2
_IQ6atan2
    //
    // Take absolute values of inputs and store sign information in r12.
    // r12[29] =  Y < 0
    // r12[30] =  X < 0
    // r12[31] = |Y|>|X|
    //
    ands    r12, r0, #0x80000000
    it      ne
        rsbne   r0, r0, #0
    lsls    r2, r1, #1
    it      cs
        rsbcs   r1, r1, #0
    rrx     r12, r12

    //
    // Place the larger of the two inputs in r1, the smaller in r0.
    // Remember this decision in R12.
    //
    cmp     r0, r1
    rrx     r12, r12
    beq     operands_are_equal_6
    ittt    hi
        movhi   r2, r0
        movhi   r0, r1
        movhi   r1, r2

    //
    // Divide r0 by r1 to find the ratio
    // Save state to stack.
    //
    push    {r4, r5}

    //
    // Normalize denominator to (1.0 0.5) in Q32
    //
    clz     r5, r1
    lsl     r1, r1, r5

    //
    //    r0 numerator GQ       r1 normalized denominator Q32
    //    r2 1/denominator Q31  r3 normalization n I
    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r1, #(32 - 10)
    ldr     r3, div_table_6
    ldr     r2, [r3, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // Dm = 2(Dm - Dm^2*Dnorm/2)
    // r2 = 2(r2 - r2^2*r1/2)
    // r1:Q32, r2:Q31
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sub     r3, r2, r3
    lsl     r2, r3, #1

    //
    // Newton Raphson Iteration  #2
    // 8-12 Cycles
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sbc     r2, r2, r3

    //
    // Multiply numerator by 1/denominator:
    // r2 is in Q29
    //
    umull   r1, r0, r0, r2

    //
    // Prepare the shift values.
    // Put the result in Q31.
    // Do not round, for fear of overflow.
    //
    add     r5, r5, #2
    rsb     r4, r5, #32
    lsr     r1, r1, r4
    lsl     r0, r0, r5
    add     r0, r0, r1

    //
    // r0 holds the calculated ratio of the inputs as UQ32.
    // r1 - r5 are available for use, r4 is saved on the stack.
    // r12 contains information on which octant the final result should be in.
    //
    // Use the top 8 bits of the ratio as a table index into the lookup table.
    // Multiply it by 3 because there are 3 coefficients per index value.
    //
    // There may be a wasted cycle here; It adds the offset to the table index
    // separately. This is so that r3 is updated to the appropriate position
    // for the next 2 loads.
    //
    lsr     r2, r0, #(32 - 8)
    add     r2, r2, r2, lsl #1
    ldr     r3, atan2PU_table_6
    add     r3, r3, r2, lsl #2

    //
    // r0       ratio of inputs in UQ32
    // {r1,r2}
    // r3       Pointer into lookup table
    // r4       Loaded coefficient
    //
    ldr     r4, [r3]
    umull   r2, r1, r4, r0
    ldrd    r4, r5, [r3, #4]!
    sub     r4, r4, r1
    umull   r2, r1, r0, r4
    add     r0, r1, r5

    //
    // Divide by four to get to Q30.  Consider working this into coefficients
    // to save one cycle.
    //
    lsr     r0, r0, #2

    //
    // r0 : atanPU of input, within the first octant, UQ30.  [0,.5)
    // R12: Destination Octant >
    //      r12[31] = |Y|>|X|
    //      r12[30] =  X < 0
    //      r12[29] =  Y < 0
    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
equal_operands_reentry_point_6
    lsls    r12, r12, #1

    //
    //  if(|y|>|x|) r0 = 0.5 - r0
    //
    it      cs
        rsbcs   r0, r0, #0x20000000

    //
    //  if( x < 0 ) r0 = 1.0 - r0
    //
    it      mi
        rsbmi   r0, r0, #0x40000000

    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
    lsls    r12, r12, #1
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply by pi to return to radians from CPU.
    //
    ldr     r1, piq29_6
    smull   r1, r0, r1, r0

    //
    // Shift result to normalize from Q27.
    //
    asrs    r0, r0, #(27 - 6)
    adc     r0, r0, #0
    pop     {r4, r5}
    bx      lr

    //
    // If the operands are (0,0), the answer is defined to be zero.  This is
    // consistent with the standard C definition.
    //
operands_are_equal_6
    teq     r0, #0
    it      eq
        bxeq    lr

    //
    // If the operands are equal but nonzero, the result is one of the 45's
    // Skip the division etc and re-enter normal program flow just before
    // octant determination after setting the "result" to an eighth PU radian.
    //
    // Push r4 and r5 for consistency, even though we don't use them in this
    // execution path.
    //
    mov     r0, #0x10000000
    push    {r4, r5}
    b       equal_operands_reentry_point_6

    //
    // The literal pool.
    //
    alignrom 2
    data
piq29_6
    dcd     0x6487ed51         // pi in Q29
div_table_6
    dcd     div_table - 0x800
atan2PU_table_6
    dcd     atan2PU_table

//*****************************************************************************
//
// _IQ7atan2
//
//*****************************************************************************
    section CODE__IQ7atan2:CODE(2)
    thumb
    export  _IQ7atan2
_IQ7atan2
    //
    // Take absolute values of inputs and store sign information in r12.
    // r12[29] =  Y < 0
    // r12[30] =  X < 0
    // r12[31] = |Y|>|X|
    //
    ands    r12, r0, #0x80000000
    it      ne
        rsbne   r0, r0, #0
    lsls    r2, r1, #1
    it      cs
        rsbcs   r1, r1, #0
    rrx     r12, r12

    //
    // Place the larger of the two inputs in r1, the smaller in r0.
    // Remember this decision in R12.
    //
    cmp     r0, r1
    rrx     r12, r12
    beq     operands_are_equal_7
    ittt    hi
        movhi   r2, r0
        movhi   r0, r1
        movhi   r1, r2

    //
    // Divide r0 by r1 to find the ratio
    // Save state to stack.
    //
    push    {r4, r5}

    //
    // Normalize denominator to (1.0 0.5) in Q32
    //
    clz     r5, r1
    lsl     r1, r1, r5

    //
    //    r0 numerator GQ       r1 normalized denominator Q32
    //    r2 1/denominator Q31  r3 normalization n I
    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r1, #(32 - 10)
    ldr     r3, div_table_7
    ldr     r2, [r3, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // Dm = 2(Dm - Dm^2*Dnorm/2)
    // r2 = 2(r2 - r2^2*r1/2)
    // r1:Q32, r2:Q31
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sub     r3, r2, r3
    lsl     r2, r3, #1

    //
    // Newton Raphson Iteration  #2
    // 8-12 Cycles
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sbc     r2, r2, r3

    //
    // Multiply numerator by 1/denominator:
    // r2 is in Q29
    //
    umull   r1, r0, r0, r2

    //
    // Prepare the shift values.
    // Put the result in Q31.
    // Do not round, for fear of overflow.
    //
    add     r5, r5, #2
    rsb     r4, r5, #32
    lsr     r1, r1, r4
    lsl     r0, r0, r5
    add     r0, r0, r1

    //
    // r0 holds the calculated ratio of the inputs as UQ32.
    // r1 - r5 are available for use, r4 is saved on the stack.
    // r12 contains information on which octant the final result should be in.
    //
    // Use the top 8 bits of the ratio as a table index into the lookup table.
    // Multiply it by 3 because there are 3 coefficients per index value.
    //
    // There may be a wasted cycle here; It adds the offset to the table index
    // separately. This is so that r3 is updated to the appropriate position
    // for the next 2 loads.
    //
    lsr     r2, r0, #(32 - 8)
    add     r2, r2, r2, lsl #1
    ldr     r3, atan2PU_table_7
    add     r3, r3, r2, lsl #2

    //
    // r0       ratio of inputs in UQ32
    // {r1,r2}
    // r3       Pointer into lookup table
    // r4       Loaded coefficient
    //
    ldr     r4, [r3]
    umull   r2, r1, r4, r0
    ldrd    r4, r5, [r3, #4]!
    sub     r4, r4, r1
    umull   r2, r1, r0, r4
    add     r0, r1, r5

    //
    // Divide by four to get to Q30.  Consider working this into coefficients
    // to save one cycle.
    //
    lsr     r0, r0, #2

    //
    // r0 : atanPU of input, within the first octant, UQ30.  [0,.5)
    // R12: Destination Octant >
    //      r12[31] = |Y|>|X|
    //      r12[30] =  X < 0
    //      r12[29] =  Y < 0
    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
equal_operands_reentry_point_7
    lsls    r12, r12, #1

    //
    //  if(|y|>|x|) r0 = 0.5 - r0
    //
    it      cs
        rsbcs   r0, r0, #0x20000000

    //
    //  if( x < 0 ) r0 = 1.0 - r0
    //
    it      mi
        rsbmi   r0, r0, #0x40000000

    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
    lsls    r12, r12, #1
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply by pi to return to radians from CPU.
    //
    ldr     r1, piq29_7
    smull   r1, r0, r1, r0

    //
    // Shift result to normalize from Q27.
    //
    asrs    r0, r0, #(27 - 7)
    adc     r0, r0, #0
    pop     {r4, r5}
    bx      lr

    //
    // If the operands are (0,0), the answer is defined to be zero.  This is
    // consistent with the standard C definition.
    //
operands_are_equal_7
    teq     r0, #0
    it      eq
        bxeq    lr

    //
    // If the operands are equal but nonzero, the result is one of the 45's
    // Skip the division etc and re-enter normal program flow just before
    // octant determination after setting the "result" to an eighth PU radian.
    //
    // Push r4 and r5 for consistency, even though we don't use them in this
    // execution path.
    //
    mov     r0, #0x10000000
    push    {r4, r5}
    b       equal_operands_reentry_point_7

    //
    // The literal pool.
    //
    alignrom 2
    data
piq29_7
    dcd     0x6487ed51         // pi in Q29
div_table_7
    dcd     div_table - 0x800
atan2PU_table_7
    dcd     atan2PU_table

//*****************************************************************************
//
// _IQ8atan2
//
//*****************************************************************************
    section CODE__IQ8atan2:CODE(2)
    thumb
    export  _IQ8atan2
_IQ8atan2
    //
    // Take absolute values of inputs and store sign information in r12.
    // r12[29] =  Y < 0
    // r12[30] =  X < 0
    // r12[31] = |Y|>|X|
    //
    ands    r12, r0, #0x80000000
    it      ne
        rsbne   r0, r0, #0
    lsls    r2, r1, #1
    it      cs
        rsbcs   r1, r1, #0
    rrx     r12, r12

    //
    // Place the larger of the two inputs in r1, the smaller in r0.
    // Remember this decision in R12.
    //
    cmp     r0, r1
    rrx     r12, r12
    beq     operands_are_equal_8
    ittt    hi
        movhi   r2, r0
        movhi   r0, r1
        movhi   r1, r2

    //
    // Divide r0 by r1 to find the ratio
    // Save state to stack.
    //
    push    {r4, r5}

    //
    // Normalize denominator to (1.0 0.5) in Q32
    //
    clz     r5, r1
    lsl     r1, r1, r5

    //
    //    r0 numerator GQ       r1 normalized denominator Q32
    //    r2 1/denominator Q31  r3 normalization n I
    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r1, #(32 - 10)
    ldr     r3, div_table_8
    ldr     r2, [r3, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // Dm = 2(Dm - Dm^2*Dnorm/2)
    // r2 = 2(r2 - r2^2*r1/2)
    // r1:Q32, r2:Q31
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sub     r3, r2, r3
    lsl     r2, r3, #1

    //
    // Newton Raphson Iteration  #2
    // 8-12 Cycles
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sbc     r2, r2, r3

    //
    // Multiply numerator by 1/denominator:
    // r2 is in Q29
    //
    umull   r1, r0, r0, r2

    //
    // Prepare the shift values.
    // Put the result in Q31.
    // Do not round, for fear of overflow.
    //
    add     r5, r5, #2
    rsb     r4, r5, #32
    lsr     r1, r1, r4
    lsl     r0, r0, r5
    add     r0, r0, r1

    //
    // r0 holds the calculated ratio of the inputs as UQ32.
    // r1 - r5 are available for use, r4 is saved on the stack.
    // r12 contains information on which octant the final result should be in.
    //
    // Use the top 8 bits of the ratio as a table index into the lookup table.
    // Multiply it by 3 because there are 3 coefficients per index value.
    //
    // There may be a wasted cycle here; It adds the offset to the table index
    // separately. This is so that r3 is updated to the appropriate position
    // for the next 2 loads.
    //
    lsr     r2, r0, #(32 - 8)
    add     r2, r2, r2, lsl #1
    ldr     r3, atan2PU_table_8
    add     r3, r3, r2, lsl #2

    //
    // r0       ratio of inputs in UQ32
    // {r1,r2}
    // r3       Pointer into lookup table
    // r4       Loaded coefficient
    //
    ldr     r4, [r3]
    umull   r2, r1, r4, r0
    ldrd    r4, r5, [r3, #4]!
    sub     r4, r4, r1
    umull   r2, r1, r0, r4
    add     r0, r1, r5

    //
    // Divide by four to get to Q30.  Consider working this into coefficients
    // to save one cycle.
    //
    lsr     r0, r0, #2

    //
    // r0 : atanPU of input, within the first octant, UQ30.  [0,.5)
    // R12: Destination Octant >
    //      r12[31] = |Y|>|X|
    //      r12[30] =  X < 0
    //      r12[29] =  Y < 0
    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
equal_operands_reentry_point_8
    lsls    r12, r12, #1

    //
    //  if(|y|>|x|) r0 = 0.5 - r0
    //
    it      cs
        rsbcs   r0, r0, #0x20000000

    //
    //  if( x < 0 ) r0 = 1.0 - r0
    //
    it      mi
        rsbmi   r0, r0, #0x40000000

    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
    lsls    r12, r12, #1
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply by pi to return to radians from CPU.
    //
    ldr     r1, piq29_8
    smull   r1, r0, r1, r0

    //
    // Shift result to normalize from Q27.
    //
    asrs    r0, r0, #(27 - 8)
    adc     r0, r0, #0
    pop     {r4, r5}
    bx      lr

    //
    // If the operands are (0,0), the answer is defined to be zero.  This is
    // consistent with the standard C definition.
    //
operands_are_equal_8
    teq     r0, #0
    it      eq
        bxeq    lr

    //
    // If the operands are equal but nonzero, the result is one of the 45's
    // Skip the division etc and re-enter normal program flow just before
    // octant determination after setting the "result" to an eighth PU radian.
    //
    // Push r4 and r5 for consistency, even though we don't use them in this
    // execution path.
    //
    mov     r0, #0x10000000
    push    {r4, r5}
    b       equal_operands_reentry_point_8

    //
    // The literal pool.
    //
    alignrom 2
    data
piq29_8
    dcd     0x6487ed51         // pi in Q29
div_table_8
    dcd     div_table - 0x800
atan2PU_table_8
    dcd     atan2PU_table

//*****************************************************************************
//
// _IQ9atan2
//
//*****************************************************************************
    section CODE__IQ9atan2:CODE(2)
    thumb
    export  _IQ9atan2
_IQ9atan2
    //
    // Take absolute values of inputs and store sign information in r12.
    // r12[29] =  Y < 0
    // r12[30] =  X < 0
    // r12[31] = |Y|>|X|
    //
    ands    r12, r0, #0x80000000
    it      ne
        rsbne   r0, r0, #0
    lsls    r2, r1, #1
    it      cs
        rsbcs   r1, r1, #0
    rrx     r12, r12

    //
    // Place the larger of the two inputs in r1, the smaller in r0.
    // Remember this decision in R12.
    //
    cmp     r0, r1
    rrx     r12, r12
    beq     operands_are_equal_9
    ittt    hi
        movhi   r2, r0
        movhi   r0, r1
        movhi   r1, r2

    //
    // Divide r0 by r1 to find the ratio
    // Save state to stack.
    //
    push    {r4, r5}

    //
    // Normalize denominator to (1.0 0.5) in Q32
    //
    clz     r5, r1
    lsl     r1, r1, r5

    //
    //    r0 numerator GQ       r1 normalized denominator Q32
    //    r2 1/denominator Q31  r3 normalization n I
    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r1, #(32 - 10)
    ldr     r3, div_table_9
    ldr     r2, [r3, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // Dm = 2(Dm - Dm^2*Dnorm/2)
    // r2 = 2(r2 - r2^2*r1/2)
    // r1:Q32, r2:Q31
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sub     r3, r2, r3
    lsl     r2, r3, #1

    //
    // Newton Raphson Iteration  #2
    // 8-12 Cycles
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sbc     r2, r2, r3

    //
    // Multiply numerator by 1/denominator:
    // r2 is in Q29
    //
    umull   r1, r0, r0, r2

    //
    // Prepare the shift values.
    // Put the result in Q31.
    // Do not round, for fear of overflow.
    //
    add     r5, r5, #2
    rsb     r4, r5, #32
    lsr     r1, r1, r4
    lsl     r0, r0, r5
    add     r0, r0, r1

    //
    // r0 holds the calculated ratio of the inputs as UQ32.
    // r1 - r5 are available for use, r4 is saved on the stack.
    // r12 contains information on which octant the final result should be in.
    //
    // Use the top 8 bits of the ratio as a table index into the lookup table.
    // Multiply it by 3 because there are 3 coefficients per index value.
    //
    // There may be a wasted cycle here; It adds the offset to the table index
    // separately. This is so that r3 is updated to the appropriate position
    // for the next 2 loads.
    //
    lsr     r2, r0, #(32 - 8)
    add     r2, r2, r2, lsl #1
    ldr     r3, atan2PU_table_9
    add     r3, r3, r2, lsl #2

    //
    // r0       ratio of inputs in UQ32
    // {r1,r2}
    // r3       Pointer into lookup table
    // r4       Loaded coefficient
    //
    ldr     r4, [r3]
    umull   r2, r1, r4, r0
    ldrd    r4, r5, [r3, #4]!
    sub     r4, r4, r1
    umull   r2, r1, r0, r4
    add     r0, r1, r5

    //
    // Divide by four to get to Q30.  Consider working this into coefficients
    // to save one cycle.
    //
    lsr     r0, r0, #2

    //
    // r0 : atanPU of input, within the first octant, UQ30.  [0,.5)
    // R12: Destination Octant >
    //      r12[31] = |Y|>|X|
    //      r12[30] =  X < 0
    //      r12[29] =  Y < 0
    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
equal_operands_reentry_point_9
    lsls    r12, r12, #1

    //
    //  if(|y|>|x|) r0 = 0.5 - r0
    //
    it      cs
        rsbcs   r0, r0, #0x20000000

    //
    //  if( x < 0 ) r0 = 1.0 - r0
    //
    it      mi
        rsbmi   r0, r0, #0x40000000

    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
    lsls    r12, r12, #1
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply by pi to return to radians from CPU.
    //
    ldr     r1, piq29_9
    smull   r1, r0, r1, r0

    //
    // Shift result to normalize from Q27.
    //
    asrs    r0, r0, #(27 - 9)
    adc     r0, r0, #0
    pop     {r4, r5}
    bx      lr

    //
    // If the operands are (0,0), the answer is defined to be zero.  This is
    // consistent with the standard C definition.
    //
operands_are_equal_9
    teq     r0, #0
    it      eq
        bxeq    lr

    //
    // If the operands are equal but nonzero, the result is one of the 45's
    // Skip the division etc and re-enter normal program flow just before
    // octant determination after setting the "result" to an eighth PU radian.
    //
    // Push r4 and r5 for consistency, even though we don't use them in this
    // execution path.
    //
    mov     r0, #0x10000000
    push    {r4, r5}
    b       equal_operands_reentry_point_9

    //
    // The literal pool.
    //
    alignrom 2
    data
piq29_9
    dcd     0x6487ed51         // pi in Q29
div_table_9
    dcd     div_table - 0x800
atan2PU_table_9
    dcd     atan2PU_table

//*****************************************************************************
//
// _IQ10atan2
//
//*****************************************************************************
    section CODE__IQ10atan2:CODE(2)
    thumb
    export  _IQ10atan2
_IQ10atan2
    //
    // Take absolute values of inputs and store sign information in r12.
    // r12[29] =  Y < 0
    // r12[30] =  X < 0
    // r12[31] = |Y|>|X|
    //
    ands    r12, r0, #0x80000000
    it      ne
        rsbne   r0, r0, #0
    lsls    r2, r1, #1
    it      cs
        rsbcs   r1, r1, #0
    rrx     r12, r12

    //
    // Place the larger of the two inputs in r1, the smaller in r0.
    // Remember this decision in R12.
    //
    cmp     r0, r1
    rrx     r12, r12
    beq     operands_are_equal_10
    ittt    hi
        movhi   r2, r0
        movhi   r0, r1
        movhi   r1, r2

    //
    // Divide r0 by r1 to find the ratio
    // Save state to stack.
    //
    push    {r4, r5}

    //
    // Normalize denominator to (1.0 0.5) in Q32
    //
    clz     r5, r1
    lsl     r1, r1, r5

    //
    //    r0 numerator GQ       r1 normalized denominator Q32
    //    r2 1/denominator Q31  r3 normalization n I
    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r1, #(32 - 10)
    ldr     r3, div_table_10
    ldr     r2, [r3, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // Dm = 2(Dm - Dm^2*Dnorm/2)
    // r2 = 2(r2 - r2^2*r1/2)
    // r1:Q32, r2:Q31
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sub     r3, r2, r3
    lsl     r2, r3, #1

    //
    // Newton Raphson Iteration  #2
    // 8-12 Cycles
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sbc     r2, r2, r3

    //
    // Multiply numerator by 1/denominator:
    // r2 is in Q29
    //
    umull   r1, r0, r0, r2

    //
    // Prepare the shift values.
    // Put the result in Q31.
    // Do not round, for fear of overflow.
    //
    add     r5, r5, #2
    rsb     r4, r5, #32
    lsr     r1, r1, r4
    lsl     r0, r0, r5
    add     r0, r0, r1

    //
    // r0 holds the calculated ratio of the inputs as UQ32.
    // r1 - r5 are available for use, r4 is saved on the stack.
    // r12 contains information on which octant the final result should be in.
    //
    // Use the top 8 bits of the ratio as a table index into the lookup table.
    // Multiply it by 3 because there are 3 coefficients per index value.
    //
    // There may be a wasted cycle here; It adds the offset to the table index
    // separately. This is so that r3 is updated to the appropriate position
    // for the next 2 loads.
    //
    lsr     r2, r0, #(32 - 8)
    add     r2, r2, r2, lsl #1
    ldr     r3, atan2PU_table_10
    add     r3, r3, r2, lsl #2

    //
    // r0       ratio of inputs in UQ32
    // {r1,r2}
    // r3       Pointer into lookup table
    // r4       Loaded coefficient
    //
    ldr     r4, [r3]
    umull   r2, r1, r4, r0
    ldrd    r4, r5, [r3, #4]!
    sub     r4, r4, r1
    umull   r2, r1, r0, r4
    add     r0, r1, r5

    //
    // Divide by four to get to Q30.  Consider working this into coefficients
    // to save one cycle.
    //
    lsr     r0, r0, #2

    //
    // r0 : atanPU of input, within the first octant, UQ30.  [0,.5)
    // R12: Destination Octant >
    //      r12[31] = |Y|>|X|
    //      r12[30] =  X < 0
    //      r12[29] =  Y < 0
    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
equal_operands_reentry_point_10
    lsls    r12, r12, #1

    //
    //  if(|y|>|x|) r0 = 0.5 - r0
    //
    it      cs
        rsbcs   r0, r0, #0x20000000

    //
    //  if( x < 0 ) r0 = 1.0 - r0
    //
    it      mi
        rsbmi   r0, r0, #0x40000000

    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
    lsls    r12, r12, #1
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply by pi to return to radians from CPU.
    //
    ldr     r1, piq29_10
    smull   r1, r0, r1, r0

    //
    // Shift result to normalize from Q27.
    //
    asrs    r0, r0, #(27 - 10)
    adc     r0, r0, #0
    pop     {r4, r5}
    bx      lr

    //
    // If the operands are (0,0), the answer is defined to be zero.  This is
    // consistent with the standard C definition.
    //
operands_are_equal_10
    teq     r0, #0
    it      eq
        bxeq    lr

    //
    // If the operands are equal but nonzero, the result is one of the 45's
    // Skip the division etc and re-enter normal program flow just before
    // octant determination after setting the "result" to an eighth PU radian.
    //
    // Push r4 and r5 for consistency, even though we don't use them in this
    // execution path.
    //
    mov     r0, #0x10000000
    push    {r4, r5}
    b       equal_operands_reentry_point_10

    //
    // The literal pool.
    //
    alignrom 2
    data
piq29_10
    dcd     0x6487ed51         // pi in Q29
div_table_10
    dcd     div_table - 0x800
atan2PU_table_10
    dcd     atan2PU_table

//*****************************************************************************
//
// _IQ11atan2
//
//*****************************************************************************
    section CODE__IQ11atan2:CODE(2)
    thumb
    export  _IQ11atan2
_IQ11atan2
    //
    // Take absolute values of inputs and store sign information in r12.
    // r12[29] =  Y < 0
    // r12[30] =  X < 0
    // r12[31] = |Y|>|X|
    //
    ands    r12, r0, #0x80000000
    it      ne
        rsbne   r0, r0, #0
    lsls    r2, r1, #1
    it      cs
        rsbcs   r1, r1, #0
    rrx     r12, r12

    //
    // Place the larger of the two inputs in r1, the smaller in r0.
    // Remember this decision in R12.
    //
    cmp     r0, r1
    rrx     r12, r12
    beq     operands_are_equal_11
    ittt    hi
        movhi   r2, r0
        movhi   r0, r1
        movhi   r1, r2

    //
    // Divide r0 by r1 to find the ratio
    // Save state to stack.
    //
    push    {r4, r5}

    //
    // Normalize denominator to (1.0 0.5) in Q32
    //
    clz     r5, r1
    lsl     r1, r1, r5

    //
    //    r0 numerator GQ       r1 normalized denominator Q32
    //    r2 1/denominator Q31  r3 normalization n I
    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r1, #(32 - 10)
    ldr     r3, div_table_11
    ldr     r2, [r3, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // Dm = 2(Dm - Dm^2*Dnorm/2)
    // r2 = 2(r2 - r2^2*r1/2)
    // r1:Q32, r2:Q31
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sub     r3, r2, r3
    lsl     r2, r3, #1

    //
    // Newton Raphson Iteration  #2
    // 8-12 Cycles
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sbc     r2, r2, r3

    //
    // Multiply numerator by 1/denominator:
    // r2 is in Q29
    //
    umull   r1, r0, r0, r2

    //
    // Prepare the shift values.
    // Put the result in Q31.
    // Do not round, for fear of overflow.
    //
    add     r5, r5, #2
    rsb     r4, r5, #32
    lsr     r1, r1, r4
    lsl     r0, r0, r5
    add     r0, r0, r1

    //
    // r0 holds the calculated ratio of the inputs as UQ32.
    // r1 - r5 are available for use, r4 is saved on the stack.
    // r12 contains information on which octant the final result should be in.
    //
    // Use the top 8 bits of the ratio as a table index into the lookup table.
    // Multiply it by 3 because there are 3 coefficients per index value.
    //
    // There may be a wasted cycle here; It adds the offset to the table index
    // separately. This is so that r3 is updated to the appropriate position
    // for the next 2 loads.
    //
    lsr     r2, r0, #(32 - 8)
    add     r2, r2, r2, lsl #1
    ldr     r3, atan2PU_table_11
    add     r3, r3, r2, lsl #2

    //
    // r0       ratio of inputs in UQ32
    // {r1,r2}
    // r3       Pointer into lookup table
    // r4       Loaded coefficient
    //
    ldr     r4, [r3]
    umull   r2, r1, r4, r0
    ldrd    r4, r5, [r3, #4]!
    sub     r4, r4, r1
    umull   r2, r1, r0, r4
    add     r0, r1, r5

    //
    // Divide by four to get to Q30.  Consider working this into coefficients
    // to save one cycle.
    //
    lsr     r0, r0, #2

    //
    // r0 : atanPU of input, within the first octant, UQ30.  [0,.5)
    // R12: Destination Octant >
    //      r12[31] = |Y|>|X|
    //      r12[30] =  X < 0
    //      r12[29] =  Y < 0
    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
equal_operands_reentry_point_11
    lsls    r12, r12, #1

    //
    //  if(|y|>|x|) r0 = 0.5 - r0
    //
    it      cs
        rsbcs   r0, r0, #0x20000000

    //
    //  if( x < 0 ) r0 = 1.0 - r0
    //
    it      mi
        rsbmi   r0, r0, #0x40000000

    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
    lsls    r12, r12, #1
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply by pi to return to radians from CPU.
    //
    ldr     r1, piq29_11
    smull   r1, r0, r1, r0

    //
    // Shift result to normalize from Q27.
    //
    asrs    r0, r0, #(27 - 11)
    adc     r0, r0, #0
    pop     {r4, r5}
    bx      lr

    //
    // If the operands are (0,0), the answer is defined to be zero.  This is
    // consistent with the standard C definition.
    //
operands_are_equal_11
    teq     r0, #0
    it      eq
        bxeq    lr

    //
    // If the operands are equal but nonzero, the result is one of the 45's
    // Skip the division etc and re-enter normal program flow just before
    // octant determination after setting the "result" to an eighth PU radian.
    //
    // Push r4 and r5 for consistency, even though we don't use them in this
    // execution path.
    //
    mov     r0, #0x10000000
    push    {r4, r5}
    b       equal_operands_reentry_point_11

    //
    // The literal pool.
    //
    alignrom 2
    data
piq29_11
    dcd     0x6487ed51         // pi in Q29
div_table_11
    dcd     div_table - 0x800
atan2PU_table_11
    dcd     atan2PU_table

//*****************************************************************************
//
// _IQ12atan2
//
//*****************************************************************************
    section CODE__IQ12atan2:CODE(2)
    thumb
    export  _IQ12atan2
_IQ12atan2
    //
    // Take absolute values of inputs and store sign information in r12.
    // r12[29] =  Y < 0
    // r12[30] =  X < 0
    // r12[31] = |Y|>|X|
    //
    ands    r12, r0, #0x80000000
    it      ne
        rsbne   r0, r0, #0
    lsls    r2, r1, #1
    it      cs
        rsbcs   r1, r1, #0
    rrx     r12, r12

    //
    // Place the larger of the two inputs in r1, the smaller in r0.
    // Remember this decision in R12.
    //
    cmp     r0, r1
    rrx     r12, r12
    beq     operands_are_equal_12
    ittt    hi
        movhi   r2, r0
        movhi   r0, r1
        movhi   r1, r2

    //
    // Divide r0 by r1 to find the ratio
    // Save state to stack.
    //
    push    {r4, r5}

    //
    // Normalize denominator to (1.0 0.5) in Q32
    //
    clz     r5, r1
    lsl     r1, r1, r5

    //
    //    r0 numerator GQ       r1 normalized denominator Q32
    //    r2 1/denominator Q31  r3 normalization n I
    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r1, #(32 - 10)
    ldr     r3, div_table_12
    ldr     r2, [r3, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // Dm = 2(Dm - Dm^2*Dnorm/2)
    // r2 = 2(r2 - r2^2*r1/2)
    // r1:Q32, r2:Q31
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sub     r3, r2, r3
    lsl     r2, r3, #1

    //
    // Newton Raphson Iteration  #2
    // 8-12 Cycles
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sbc     r2, r2, r3

    //
    // Multiply numerator by 1/denominator:
    // r2 is in Q29
    //
    umull   r1, r0, r0, r2

    //
    // Prepare the shift values.
    // Put the result in Q31.
    // Do not round, for fear of overflow.
    //
    add     r5, r5, #2
    rsb     r4, r5, #32
    lsr     r1, r1, r4
    lsl     r0, r0, r5
    add     r0, r0, r1

    //
    // r0 holds the calculated ratio of the inputs as UQ32.
    // r1 - r5 are available for use, r4 is saved on the stack.
    // r12 contains information on which octant the final result should be in.
    //
    // Use the top 8 bits of the ratio as a table index into the lookup table.
    // Multiply it by 3 because there are 3 coefficients per index value.
    //
    // There may be a wasted cycle here; It adds the offset to the table index
    // separately. This is so that r3 is updated to the appropriate position
    // for the next 2 loads.
    //
    lsr     r2, r0, #(32 - 8)
    add     r2, r2, r2, lsl #1
    ldr     r3, atan2PU_table_12
    add     r3, r3, r2, lsl #2

    //
    // r0       ratio of inputs in UQ32
    // {r1,r2}
    // r3       Pointer into lookup table
    // r4       Loaded coefficient
    //
    ldr     r4, [r3]
    umull   r2, r1, r4, r0
    ldrd    r4, r5, [r3, #4]!
    sub     r4, r4, r1
    umull   r2, r1, r0, r4
    add     r0, r1, r5

    //
    // Divide by four to get to Q30.  Consider working this into coefficients
    // to save one cycle.
    //
    lsr     r0, r0, #2

    //
    // r0 : atanPU of input, within the first octant, UQ30.  [0,.5)
    // R12: Destination Octant >
    //      r12[31] = |Y|>|X|
    //      r12[30] =  X < 0
    //      r12[29] =  Y < 0
    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
equal_operands_reentry_point_12
    lsls    r12, r12, #1

    //
    //  if(|y|>|x|) r0 = 0.5 - r0
    //
    it      cs
        rsbcs   r0, r0, #0x20000000

    //
    //  if( x < 0 ) r0 = 1.0 - r0
    //
    it      mi
        rsbmi   r0, r0, #0x40000000

    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
    lsls    r12, r12, #1
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply by pi to return to radians from CPU.
    //
    ldr     r1, piq29_12
    smull   r1, r0, r1, r0

    //
    // Shift result to normalize from Q27.
    //
    asrs    r0, r0, #(27 - 12)
    adc     r0, r0, #0
    pop     {r4, r5}
    bx      lr

    //
    // If the operands are (0,0), the answer is defined to be zero.  This is
    // consistent with the standard C definition.
    //
operands_are_equal_12
    teq     r0, #0
    it      eq
        bxeq    lr

    //
    // If the operands are equal but nonzero, the result is one of the 45's
    // Skip the division etc and re-enter normal program flow just before
    // octant determination after setting the "result" to an eighth PU radian.
    //
    // Push r4 and r5 for consistency, even though we don't use them in this
    // execution path.
    //
    mov     r0, #0x10000000
    push    {r4, r5}
    b       equal_operands_reentry_point_12

    //
    // The literal pool.
    //
    alignrom 2
    data
piq29_12
    dcd     0x6487ed51         // pi in Q29
div_table_12
    dcd     div_table - 0x800
atan2PU_table_12
    dcd     atan2PU_table

//*****************************************************************************
//
// _IQ13atan2
//
//*****************************************************************************
    section CODE__IQ13atan2:CODE(2)
    thumb
    export  _IQ13atan2
_IQ13atan2
    //
    // Take absolute values of inputs and store sign information in r12.
    // r12[29] =  Y < 0
    // r12[30] =  X < 0
    // r12[31] = |Y|>|X|
    //
    ands    r12, r0, #0x80000000
    it      ne
        rsbne   r0, r0, #0
    lsls    r2, r1, #1
    it      cs
        rsbcs   r1, r1, #0
    rrx     r12, r12

    //
    // Place the larger of the two inputs in r1, the smaller in r0.
    // Remember this decision in R12.
    //
    cmp     r0, r1
    rrx     r12, r12
    beq     operands_are_equal_13
    ittt    hi
        movhi   r2, r0
        movhi   r0, r1
        movhi   r1, r2

    //
    // Divide r0 by r1 to find the ratio
    // Save state to stack.
    //
    push    {r4, r5}

    //
    // Normalize denominator to (1.0 0.5) in Q32
    //
    clz     r5, r1
    lsl     r1, r1, r5

    //
    //    r0 numerator GQ       r1 normalized denominator Q32
    //    r2 1/denominator Q31  r3 normalization n I
    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r1, #(32 - 10)
    ldr     r3, div_table_13
    ldr     r2, [r3, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // Dm = 2(Dm - Dm^2*Dnorm/2)
    // r2 = 2(r2 - r2^2*r1/2)
    // r1:Q32, r2:Q31
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sub     r3, r2, r3
    lsl     r2, r3, #1

    //
    // Newton Raphson Iteration  #2
    // 8-12 Cycles
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sbc     r2, r2, r3

    //
    // Multiply numerator by 1/denominator:
    // r2 is in Q29
    //
    umull   r1, r0, r0, r2

    //
    // Prepare the shift values.
    // Put the result in Q31.
    // Do not round, for fear of overflow.
    //
    add     r5, r5, #2
    rsb     r4, r5, #32
    lsr     r1, r1, r4
    lsl     r0, r0, r5
    add     r0, r0, r1

    //
    // r0 holds the calculated ratio of the inputs as UQ32.
    // r1 - r5 are available for use, r4 is saved on the stack.
    // r12 contains information on which octant the final result should be in.
    //
    // Use the top 8 bits of the ratio as a table index into the lookup table.
    // Multiply it by 3 because there are 3 coefficients per index value.
    //
    // There may be a wasted cycle here; It adds the offset to the table index
    // separately. This is so that r3 is updated to the appropriate position
    // for the next 2 loads.
    //
    lsr     r2, r0, #(32 - 8)
    add     r2, r2, r2, lsl #1
    ldr     r3, atan2PU_table_13
    add     r3, r3, r2, lsl #2

    //
    // r0       ratio of inputs in UQ32
    // {r1,r2}
    // r3       Pointer into lookup table
    // r4       Loaded coefficient
    //
    ldr     r4, [r3]
    umull   r2, r1, r4, r0
    ldrd    r4, r5, [r3, #4]!
    sub     r4, r4, r1
    umull   r2, r1, r0, r4
    add     r0, r1, r5

    //
    // Divide by four to get to Q30.  Consider working this into coefficients
    // to save one cycle.
    //
    lsr     r0, r0, #2

    //
    // r0 : atanPU of input, within the first octant, UQ30.  [0,.5)
    // R12: Destination Octant >
    //      r12[31] = |Y|>|X|
    //      r12[30] =  X < 0
    //      r12[29] =  Y < 0
    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
equal_operands_reentry_point_13
    lsls    r12, r12, #1

    //
    //  if(|y|>|x|) r0 = 0.5 - r0
    //
    it      cs
        rsbcs   r0, r0, #0x20000000

    //
    //  if( x < 0 ) r0 = 1.0 - r0
    //
    it      mi
        rsbmi   r0, r0, #0x40000000

    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
    lsls    r12, r12, #1
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply by pi to return to radians from CPU.
    //
    ldr     r1, piq29_13
    smull   r1, r0, r1, r0

    //
    // Shift result to normalize from Q27.
    //
    asrs    r0, r0, #(27 - 13)
    adc     r0, r0, #0
    pop     {r4, r5}
    bx      lr

    //
    // If the operands are (0,0), the answer is defined to be zero.  This is
    // consistent with the standard C definition.
    //
operands_are_equal_13
    teq     r0, #0
    it      eq
        bxeq    lr

    //
    // If the operands are equal but nonzero, the result is one of the 45's
    // Skip the division etc and re-enter normal program flow just before
    // octant determination after setting the "result" to an eighth PU radian.
    //
    // Push r4 and r5 for consistency, even though we don't use them in this
    // execution path.
    //
    mov     r0, #0x10000000
    push    {r4, r5}
    b       equal_operands_reentry_point_13

    //
    // The literal pool.
    //
    alignrom 2
    data
piq29_13
    dcd     0x6487ed51         // pi in Q29
div_table_13
    dcd     div_table - 0x800
atan2PU_table_13
    dcd     atan2PU_table

//*****************************************************************************
//
// _IQ14atan2
//
//*****************************************************************************
    section CODE__IQ14atan2:CODE(2)
    thumb
    export  _IQ14atan2
_IQ14atan2
    //
    // Take absolute values of inputs and store sign information in r12.
    // r12[29] =  Y < 0
    // r12[30] =  X < 0
    // r12[31] = |Y|>|X|
    //
    ands    r12, r0, #0x80000000
    it      ne
        rsbne   r0, r0, #0
    lsls    r2, r1, #1
    it      cs
        rsbcs   r1, r1, #0
    rrx     r12, r12

    //
    // Place the larger of the two inputs in r1, the smaller in r0.
    // Remember this decision in R12.
    //
    cmp     r0, r1
    rrx     r12, r12
    beq     operands_are_equal_14
    ittt    hi
        movhi   r2, r0
        movhi   r0, r1
        movhi   r1, r2

    //
    // Divide r0 by r1 to find the ratio
    // Save state to stack.
    //
    push    {r4, r5}

    //
    // Normalize denominator to (1.0 0.5) in Q32
    //
    clz     r5, r1
    lsl     r1, r1, r5

    //
    //    r0 numerator GQ       r1 normalized denominator Q32
    //    r2 1/denominator Q31  r3 normalization n I
    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r1, #(32 - 10)
    ldr     r3, div_table_14
    ldr     r2, [r3, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // Dm = 2(Dm - Dm^2*Dnorm/2)
    // r2 = 2(r2 - r2^2*r1/2)
    // r1:Q32, r2:Q31
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sub     r3, r2, r3
    lsl     r2, r3, #1

    //
    // Newton Raphson Iteration  #2
    // 8-12 Cycles
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sbc     r2, r2, r3

    //
    // Multiply numerator by 1/denominator:
    // r2 is in Q29
    //
    umull   r1, r0, r0, r2

    //
    // Prepare the shift values.
    // Put the result in Q31.
    // Do not round, for fear of overflow.
    //
    add     r5, r5, #2
    rsb     r4, r5, #32
    lsr     r1, r1, r4
    lsl     r0, r0, r5
    add     r0, r0, r1

    //
    // r0 holds the calculated ratio of the inputs as UQ32.
    // r1 - r5 are available for use, r4 is saved on the stack.
    // r12 contains information on which octant the final result should be in.
    //
    // Use the top 8 bits of the ratio as a table index into the lookup table.
    // Multiply it by 3 because there are 3 coefficients per index value.
    //
    // There may be a wasted cycle here; It adds the offset to the table index
    // separately. This is so that r3 is updated to the appropriate position
    // for the next 2 loads.
    //
    lsr     r2, r0, #(32 - 8)
    add     r2, r2, r2, lsl #1
    ldr     r3, atan2PU_table_14
    add     r3, r3, r2, lsl #2

    //
    // r0       ratio of inputs in UQ32
    // {r1,r2}
    // r3       Pointer into lookup table
    // r4       Loaded coefficient
    //
    ldr     r4, [r3]
    umull   r2, r1, r4, r0
    ldrd    r4, r5, [r3, #4]!
    sub     r4, r4, r1
    umull   r2, r1, r0, r4
    add     r0, r1, r5

    //
    // Divide by four to get to Q30.  Consider working this into coefficients
    // to save one cycle.
    //
    lsr     r0, r0, #2

    //
    // r0 : atanPU of input, within the first octant, UQ30.  [0,.5)
    // R12: Destination Octant >
    //      r12[31] = |Y|>|X|
    //      r12[30] =  X < 0
    //      r12[29] =  Y < 0
    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
equal_operands_reentry_point_14
    lsls    r12, r12, #1

    //
    //  if(|y|>|x|) r0 = 0.5 - r0
    //
    it      cs
        rsbcs   r0, r0, #0x20000000

    //
    //  if( x < 0 ) r0 = 1.0 - r0
    //
    it      mi
        rsbmi   r0, r0, #0x40000000

    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
    lsls    r12, r12, #1
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply by pi to return to radians from CPU.
    //
    ldr     r1, piq29_14
    smull   r1, r0, r1, r0

    //
    // Shift result to normalize from Q27.
    //
    asrs    r0, r0, #(27 - 14)
    adc     r0, r0, #0
    pop     {r4, r5}
    bx      lr

    //
    // If the operands are (0,0), the answer is defined to be zero.  This is
    // consistent with the standard C definition.
    //
operands_are_equal_14
    teq     r0, #0
    it      eq
        bxeq    lr

    //
    // If the operands are equal but nonzero, the result is one of the 45's
    // Skip the division etc and re-enter normal program flow just before
    // octant determination after setting the "result" to an eighth PU radian.
    //
    // Push r4 and r5 for consistency, even though we don't use them in this
    // execution path.
    //
    mov     r0, #0x10000000
    push    {r4, r5}
    b       equal_operands_reentry_point_14

    //
    // The literal pool.
    //
    alignrom 2
    data
piq29_14
    dcd     0x6487ed51         // pi in Q29
div_table_14
    dcd     div_table - 0x800
atan2PU_table_14
    dcd     atan2PU_table

//*****************************************************************************
//
// _IQ15atan2
//
//*****************************************************************************
    section CODE__IQ15atan2:CODE(2)
    thumb
    export  _IQ15atan2
_IQ15atan2
    //
    // Take absolute values of inputs and store sign information in r12.
    // r12[29] =  Y < 0
    // r12[30] =  X < 0
    // r12[31] = |Y|>|X|
    //
    ands    r12, r0, #0x80000000
    it      ne
        rsbne   r0, r0, #0
    lsls    r2, r1, #1
    it      cs
        rsbcs   r1, r1, #0
    rrx     r12, r12

    //
    // Place the larger of the two inputs in r1, the smaller in r0.
    // Remember this decision in R12.
    //
    cmp     r0, r1
    rrx     r12, r12
    beq     operands_are_equal_15
    ittt    hi
        movhi   r2, r0
        movhi   r0, r1
        movhi   r1, r2

    //
    // Divide r0 by r1 to find the ratio
    // Save state to stack.
    //
    push    {r4, r5}

    //
    // Normalize denominator to (1.0 0.5) in Q32
    //
    clz     r5, r1
    lsl     r1, r1, r5

    //
    //    r0 numerator GQ       r1 normalized denominator Q32
    //    r2 1/denominator Q31  r3 normalization n I
    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r1, #(32 - 10)
    ldr     r3, div_table_15
    ldr     r2, [r3, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // Dm = 2(Dm - Dm^2*Dnorm/2)
    // r2 = 2(r2 - r2^2*r1/2)
    // r1:Q32, r2:Q31
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sub     r3, r2, r3
    lsl     r2, r3, #1

    //
    // Newton Raphson Iteration  #2
    // 8-12 Cycles
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sbc     r2, r2, r3

    //
    // Multiply numerator by 1/denominator:
    // r2 is in Q29
    //
    umull   r1, r0, r0, r2

    //
    // Prepare the shift values.
    // Put the result in Q31.
    // Do not round, for fear of overflow.
    //
    add     r5, r5, #2
    rsb     r4, r5, #32
    lsr     r1, r1, r4
    lsl     r0, r0, r5
    add     r0, r0, r1

    //
    // r0 holds the calculated ratio of the inputs as UQ32.
    // r1 - r5 are available for use, r4 is saved on the stack.
    // r12 contains information on which octant the final result should be in.
    //
    // Use the top 8 bits of the ratio as a table index into the lookup table.
    // Multiply it by 3 because there are 3 coefficients per index value.
    //
    // There may be a wasted cycle here; It adds the offset to the table index
    // separately. This is so that r3 is updated to the appropriate position
    // for the next 2 loads.
    //
    lsr     r2, r0, #(32 - 8)
    add     r2, r2, r2, lsl #1
    ldr     r3, atan2PU_table_15
    add     r3, r3, r2, lsl #2

    //
    // r0       ratio of inputs in UQ32
    // {r1,r2}
    // r3       Pointer into lookup table
    // r4       Loaded coefficient
    //
    ldr     r4, [r3]
    umull   r2, r1, r4, r0
    ldrd    r4, r5, [r3, #4]!
    sub     r4, r4, r1
    umull   r2, r1, r0, r4
    add     r0, r1, r5

    //
    // Divide by four to get to Q30.  Consider working this into coefficients
    // to save one cycle.
    //
    lsr     r0, r0, #2

    //
    // r0 : atanPU of input, within the first octant, UQ30.  [0,.5)
    // R12: Destination Octant >
    //      r12[31] = |Y|>|X|
    //      r12[30] =  X < 0
    //      r12[29] =  Y < 0
    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
equal_operands_reentry_point_15
    lsls    r12, r12, #1

    //
    //  if(|y|>|x|) r0 = 0.5 - r0
    //
    it      cs
        rsbcs   r0, r0, #0x20000000

    //
    //  if( x < 0 ) r0 = 1.0 - r0
    //
    it      mi
        rsbmi   r0, r0, #0x40000000

    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
    lsls    r12, r12, #1
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply by pi to return to radians from CPU.
    //
    ldr     r1, piq29_15
    smull   r1, r0, r1, r0

    //
    // Shift result to normalize from Q27.
    //
    asrs    r0, r0, #(27 - 15)
    adc     r0, r0, #0
    pop     {r4, r5}
    bx      lr

    //
    // If the operands are (0,0), the answer is defined to be zero.  This is
    // consistent with the standard C definition.
    //
operands_are_equal_15
    teq     r0, #0
    it      eq
        bxeq    lr

    //
    // If the operands are equal but nonzero, the result is one of the 45's
    // Skip the division etc and re-enter normal program flow just before
    // octant determination after setting the "result" to an eighth PU radian.
    //
    // Push r4 and r5 for consistency, even though we don't use them in this
    // execution path.
    //
    mov     r0, #0x10000000
    push    {r4, r5}
    b       equal_operands_reentry_point_15

    //
    // The literal pool.
    //
    alignrom 2
    data
piq29_15
    dcd     0x6487ed51         // pi in Q29
div_table_15
    dcd     div_table - 0x800
atan2PU_table_15
    dcd     atan2PU_table

//*****************************************************************************
//
// _IQ16atan2
//
//*****************************************************************************
    section CODE__IQ16atan2:CODE(2)
    thumb
    export  _IQ16atan2
_IQ16atan2
    //
    // Take absolute values of inputs and store sign information in r12.
    // r12[29] =  Y < 0
    // r12[30] =  X < 0
    // r12[31] = |Y|>|X|
    //
    ands    r12, r0, #0x80000000
    it      ne
        rsbne   r0, r0, #0
    lsls    r2, r1, #1
    it      cs
        rsbcs   r1, r1, #0
    rrx     r12, r12

    //
    // Place the larger of the two inputs in r1, the smaller in r0.
    // Remember this decision in R12.
    //
    cmp     r0, r1
    rrx     r12, r12
    beq     operands_are_equal_16
    ittt    hi
        movhi   r2, r0
        movhi   r0, r1
        movhi   r1, r2

    //
    // Divide r0 by r1 to find the ratio
    // Save state to stack.
    //
    push    {r4, r5}

    //
    // Normalize denominator to (1.0 0.5) in Q32
    //
    clz     r5, r1
    lsl     r1, r1, r5

    //
    //    r0 numerator GQ       r1 normalized denominator Q32
    //    r2 1/denominator Q31  r3 normalization n I
    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r1, #(32 - 10)
    ldr     r3, div_table_16
    ldr     r2, [r3, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // Dm = 2(Dm - Dm^2*Dnorm/2)
    // r2 = 2(r2 - r2^2*r1/2)
    // r1:Q32, r2:Q31
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sub     r3, r2, r3
    lsl     r2, r3, #1

    //
    // Newton Raphson Iteration  #2
    // 8-12 Cycles
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sbc     r2, r2, r3

    //
    // Multiply numerator by 1/denominator:
    // r2 is in Q29
    //
    umull   r1, r0, r0, r2

    //
    // Prepare the shift values.
    // Put the result in Q31.
    // Do not round, for fear of overflow.
    //
    add     r5, r5, #2
    rsb     r4, r5, #32
    lsr     r1, r1, r4
    lsl     r0, r0, r5
    add     r0, r0, r1

    //
    // r0 holds the calculated ratio of the inputs as UQ32.
    // r1 - r5 are available for use, r4 is saved on the stack.
    // r12 contains information on which octant the final result should be in.
    //
    // Use the top 8 bits of the ratio as a table index into the lookup table.
    // Multiply it by 3 because there are 3 coefficients per index value.
    //
    // There may be a wasted cycle here; It adds the offset to the table index
    // separately. This is so that r3 is updated to the appropriate position
    // for the next 2 loads.
    //
    lsr     r2, r0, #(32 - 8)
    add     r2, r2, r2, lsl #1
    ldr     r3, atan2PU_table_16
    add     r3, r3, r2, lsl #2

    //
    // r0       ratio of inputs in UQ32
    // {r1,r2}
    // r3       Pointer into lookup table
    // r4       Loaded coefficient
    //
    ldr     r4, [r3]
    umull   r2, r1, r4, r0
    ldrd    r4, r5, [r3, #4]!
    sub     r4, r4, r1
    umull   r2, r1, r0, r4
    add     r0, r1, r5

    //
    // Divide by four to get to Q30.  Consider working this into coefficients
    // to save one cycle.
    //
    lsr     r0, r0, #2

    //
    // r0 : atanPU of input, within the first octant, UQ30.  [0,.5)
    // R12: Destination Octant >
    //      r12[31] = |Y|>|X|
    //      r12[30] =  X < 0
    //      r12[29] =  Y < 0
    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
equal_operands_reentry_point_16
    lsls    r12, r12, #1

    //
    //  if(|y|>|x|) r0 = 0.5 - r0
    //
    it      cs
        rsbcs   r0, r0, #0x20000000

    //
    //  if( x < 0 ) r0 = 1.0 - r0
    //
    it      mi
        rsbmi   r0, r0, #0x40000000

    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
    lsls    r12, r12, #1
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply by pi to return to radians from CPU.
    //
    ldr     r1, piq29_16
    smull   r1, r0, r1, r0

    //
    // Shift result to normalize from Q27.
    //
    asrs    r0, r0, #(27 - 16)
    adc     r0, r0, #0
    pop     {r4, r5}
    bx      lr

    //
    // If the operands are (0,0), the answer is defined to be zero.  This is
    // consistent with the standard C definition.
    //
operands_are_equal_16
    teq     r0, #0
    it      eq
        bxeq    lr

    //
    // If the operands are equal but nonzero, the result is one of the 45's
    // Skip the division etc and re-enter normal program flow just before
    // octant determination after setting the "result" to an eighth PU radian.
    //
    // Push r4 and r5 for consistency, even though we don't use them in this
    // execution path.
    //
    mov     r0, #0x10000000
    push    {r4, r5}
    b       equal_operands_reentry_point_16

    //
    // The literal pool.
    //
    alignrom 2
    data
piq29_16
    dcd     0x6487ed51         // pi in Q29
div_table_16
    dcd     div_table - 0x800
atan2PU_table_16
    dcd     atan2PU_table

//*****************************************************************************
//
// _IQ17atan2
//
//*****************************************************************************
    section CODE__IQ17atan2:CODE(2)
    thumb
    export  _IQ17atan2
_IQ17atan2
    //
    // Take absolute values of inputs and store sign information in r12.
    // r12[29] =  Y < 0
    // r12[30] =  X < 0
    // r12[31] = |Y|>|X|
    //
    ands    r12, r0, #0x80000000
    it      ne
        rsbne   r0, r0, #0
    lsls    r2, r1, #1
    it      cs
        rsbcs   r1, r1, #0
    rrx     r12, r12

    //
    // Place the larger of the two inputs in r1, the smaller in r0.
    // Remember this decision in R12.
    //
    cmp     r0, r1
    rrx     r12, r12
    beq     operands_are_equal_17
    ittt    hi
        movhi   r2, r0
        movhi   r0, r1
        movhi   r1, r2

    //
    // Divide r0 by r1 to find the ratio
    // Save state to stack.
    //
    push    {r4, r5}

    //
    // Normalize denominator to (1.0 0.5) in Q32
    //
    clz     r5, r1
    lsl     r1, r1, r5

    //
    //    r0 numerator GQ       r1 normalized denominator Q32
    //    r2 1/denominator Q31  r3 normalization n I
    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r1, #(32 - 10)
    ldr     r3, div_table_17
    ldr     r2, [r3, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // Dm = 2(Dm - Dm^2*Dnorm/2)
    // r2 = 2(r2 - r2^2*r1/2)
    // r1:Q32, r2:Q31
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sub     r3, r2, r3
    lsl     r2, r3, #1

    //
    // Newton Raphson Iteration  #2
    // 8-12 Cycles
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sbc     r2, r2, r3

    //
    // Multiply numerator by 1/denominator:
    // r2 is in Q29
    //
    umull   r1, r0, r0, r2

    //
    // Prepare the shift values.
    // Put the result in Q31.
    // Do not round, for fear of overflow.
    //
    add     r5, r5, #2
    rsb     r4, r5, #32
    lsr     r1, r1, r4
    lsl     r0, r0, r5
    add     r0, r0, r1

    //
    // r0 holds the calculated ratio of the inputs as UQ32.
    // r1 - r5 are available for use, r4 is saved on the stack.
    // r12 contains information on which octant the final result should be in.
    //
    // Use the top 8 bits of the ratio as a table index into the lookup table.
    // Multiply it by 3 because there are 3 coefficients per index value.
    //
    // There may be a wasted cycle here; It adds the offset to the table index
    // separately. This is so that r3 is updated to the appropriate position
    // for the next 2 loads.
    //
    lsr     r2, r0, #(32 - 8)
    add     r2, r2, r2, lsl #1
    ldr     r3, atan2PU_table_17
    add     r3, r3, r2, lsl #2

    //
    // r0       ratio of inputs in UQ32
    // {r1,r2}
    // r3       Pointer into lookup table
    // r4       Loaded coefficient
    //
    ldr     r4, [r3]
    umull   r2, r1, r4, r0
    ldrd    r4, r5, [r3, #4]!
    sub     r4, r4, r1
    umull   r2, r1, r0, r4
    add     r0, r1, r5

    //
    // Divide by four to get to Q30.  Consider working this into coefficients
    // to save one cycle.
    //
    lsr     r0, r0, #2

    //
    // r0 : atanPU of input, within the first octant, UQ30.  [0,.5)
    // R12: Destination Octant >
    //      r12[31] = |Y|>|X|
    //      r12[30] =  X < 0
    //      r12[29] =  Y < 0
    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
equal_operands_reentry_point_17
    lsls    r12, r12, #1

    //
    //  if(|y|>|x|) r0 = 0.5 - r0
    //
    it      cs
        rsbcs   r0, r0, #0x20000000

    //
    //  if( x < 0 ) r0 = 1.0 - r0
    //
    it      mi
        rsbmi   r0, r0, #0x40000000

    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
    lsls    r12, r12, #1
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply by pi to return to radians from CPU.
    //
    ldr     r1, piq29_17
    smull   r1, r0, r1, r0

    //
    // Shift result to normalize from Q27.
    //
    asrs    r0, r0, #(27 - 17)
    adc     r0, r0, #0
    pop     {r4, r5}
    bx      lr

    //
    // If the operands are (0,0), the answer is defined to be zero.  This is
    // consistent with the standard C definition.
    //
operands_are_equal_17
    teq     r0, #0
    it      eq
        bxeq    lr

    //
    // If the operands are equal but nonzero, the result is one of the 45's
    // Skip the division etc and re-enter normal program flow just before
    // octant determination after setting the "result" to an eighth PU radian.
    //
    // Push r4 and r5 for consistency, even though we don't use them in this
    // execution path.
    //
    mov     r0, #0x10000000
    push    {r4, r5}
    b       equal_operands_reentry_point_17

    //
    // The literal pool.
    //
    alignrom 2
    data
piq29_17
    dcd     0x6487ed51         // pi in Q29
div_table_17
    dcd     div_table - 0x800
atan2PU_table_17
    dcd     atan2PU_table

//*****************************************************************************
//
// _IQ18atan2
//
//*****************************************************************************
    section CODE__IQ18atan2:CODE(2)
    thumb
    export  _IQ18atan2
_IQ18atan2
    //
    // Take absolute values of inputs and store sign information in r12.
    // r12[29] =  Y < 0
    // r12[30] =  X < 0
    // r12[31] = |Y|>|X|
    //
    ands    r12, r0, #0x80000000
    it      ne
        rsbne   r0, r0, #0
    lsls    r2, r1, #1
    it      cs
        rsbcs   r1, r1, #0
    rrx     r12, r12

    //
    // Place the larger of the two inputs in r1, the smaller in r0.
    // Remember this decision in R12.
    //
    cmp     r0, r1
    rrx     r12, r12
    beq     operands_are_equal_18
    ittt    hi
        movhi   r2, r0
        movhi   r0, r1
        movhi   r1, r2

    //
    // Divide r0 by r1 to find the ratio
    // Save state to stack.
    //
    push    {r4, r5}

    //
    // Normalize denominator to (1.0 0.5) in Q32
    //
    clz     r5, r1
    lsl     r1, r1, r5

    //
    //    r0 numerator GQ       r1 normalized denominator Q32
    //    r2 1/denominator Q31  r3 normalization n I
    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r1, #(32 - 10)
    ldr     r3, div_table_18
    ldr     r2, [r3, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // Dm = 2(Dm - Dm^2*Dnorm/2)
    // r2 = 2(r2 - r2^2*r1/2)
    // r1:Q32, r2:Q31
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sub     r3, r2, r3
    lsl     r2, r3, #1

    //
    // Newton Raphson Iteration  #2
    // 8-12 Cycles
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sbc     r2, r2, r3

    //
    // Multiply numerator by 1/denominator:
    // r2 is in Q29
    //
    umull   r1, r0, r0, r2

    //
    // Prepare the shift values.
    // Put the result in Q31.
    // Do not round, for fear of overflow.
    //
    add     r5, r5, #2
    rsb     r4, r5, #32
    lsr     r1, r1, r4
    lsl     r0, r0, r5
    add     r0, r0, r1

    //
    // r0 holds the calculated ratio of the inputs as UQ32.
    // r1 - r5 are available for use, r4 is saved on the stack.
    // r12 contains information on which octant the final result should be in.
    //
    // Use the top 8 bits of the ratio as a table index into the lookup table.
    // Multiply it by 3 because there are 3 coefficients per index value.
    //
    // There may be a wasted cycle here; It adds the offset to the table index
    // separately. This is so that r3 is updated to the appropriate position
    // for the next 2 loads.
    //
    lsr     r2, r0, #(32 - 8)
    add     r2, r2, r2, lsl #1
    ldr     r3, atan2PU_table_18
    add     r3, r3, r2, lsl #2

    //
    // r0       ratio of inputs in UQ32
    // {r1,r2}
    // r3       Pointer into lookup table
    // r4       Loaded coefficient
    //
    ldr     r4, [r3]
    umull   r2, r1, r4, r0
    ldrd    r4, r5, [r3, #4]!
    sub     r4, r4, r1
    umull   r2, r1, r0, r4
    add     r0, r1, r5

    //
    // Divide by four to get to Q30.  Consider working this into coefficients
    // to save one cycle.
    //
    lsr     r0, r0, #2

    //
    // r0 : atanPU of input, within the first octant, UQ30.  [0,.5)
    // R12: Destination Octant >
    //      r12[31] = |Y|>|X|
    //      r12[30] =  X < 0
    //      r12[29] =  Y < 0
    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
equal_operands_reentry_point_18
    lsls    r12, r12, #1

    //
    //  if(|y|>|x|) r0 = 0.5 - r0
    //
    it      cs
        rsbcs   r0, r0, #0x20000000

    //
    //  if( x < 0 ) r0 = 1.0 - r0
    //
    it      mi
        rsbmi   r0, r0, #0x40000000

    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
    lsls    r12, r12, #1
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply by pi to return to radians from CPU.
    //
    ldr     r1, piq29_18
    smull   r1, r0, r1, r0

    //
    // Shift result to normalize from Q27.
    //
    asrs    r0, r0, #(27 - 18)
    adc     r0, r0, #0
    pop     {r4, r5}
    bx      lr

    //
    // If the operands are (0,0), the answer is defined to be zero.  This is
    // consistent with the standard C definition.
    //
operands_are_equal_18
    teq     r0, #0
    it      eq
        bxeq    lr

    //
    // If the operands are equal but nonzero, the result is one of the 45's
    // Skip the division etc and re-enter normal program flow just before
    // octant determination after setting the "result" to an eighth PU radian.
    //
    // Push r4 and r5 for consistency, even though we don't use them in this
    // execution path.
    //
    mov     r0, #0x10000000
    push    {r4, r5}
    b       equal_operands_reentry_point_18

    //
    // The literal pool.
    //
    alignrom 2
    data
piq29_18
    dcd     0x6487ed51         // pi in Q29
div_table_18
    dcd     div_table - 0x800
atan2PU_table_18
    dcd     atan2PU_table

//*****************************************************************************
//
// _IQ19atan2
//
//*****************************************************************************
    section CODE__IQ19atan2:CODE(2)
    thumb
    export  _IQ19atan2
_IQ19atan2
    //
    // Take absolute values of inputs and store sign information in r12.
    // r12[29] =  Y < 0
    // r12[30] =  X < 0
    // r12[31] = |Y|>|X|
    //
    ands    r12, r0, #0x80000000
    it      ne
        rsbne   r0, r0, #0
    lsls    r2, r1, #1
    it      cs
        rsbcs   r1, r1, #0
    rrx     r12, r12

    //
    // Place the larger of the two inputs in r1, the smaller in r0.
    // Remember this decision in R12.
    //
    cmp     r0, r1
    rrx     r12, r12
    beq     operands_are_equal_19
    ittt    hi
        movhi   r2, r0
        movhi   r0, r1
        movhi   r1, r2

    //
    // Divide r0 by r1 to find the ratio
    // Save state to stack.
    //
    push    {r4, r5}

    //
    // Normalize denominator to (1.0 0.5) in Q32
    //
    clz     r5, r1
    lsl     r1, r1, r5

    //
    //    r0 numerator GQ       r1 normalized denominator Q32
    //    r2 1/denominator Q31  r3 normalization n I
    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r1, #(32 - 10)
    ldr     r3, div_table_19
    ldr     r2, [r3, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // Dm = 2(Dm - Dm^2*Dnorm/2)
    // r2 = 2(r2 - r2^2*r1/2)
    // r1:Q32, r2:Q31
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sub     r3, r2, r3
    lsl     r2, r3, #1

    //
    // Newton Raphson Iteration  #2
    // 8-12 Cycles
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sbc     r2, r2, r3

    //
    // Multiply numerator by 1/denominator:
    // r2 is in Q29
    //
    umull   r1, r0, r0, r2

    //
    // Prepare the shift values.
    // Put the result in Q31.
    // Do not round, for fear of overflow.
    //
    add     r5, r5, #2
    rsb     r4, r5, #32
    lsr     r1, r1, r4
    lsl     r0, r0, r5
    add     r0, r0, r1

    //
    // r0 holds the calculated ratio of the inputs as UQ32.
    // r1 - r5 are available for use, r4 is saved on the stack.
    // r12 contains information on which octant the final result should be in.
    //
    // Use the top 8 bits of the ratio as a table index into the lookup table.
    // Multiply it by 3 because there are 3 coefficients per index value.
    //
    // There may be a wasted cycle here; It adds the offset to the table index
    // separately. This is so that r3 is updated to the appropriate position
    // for the next 2 loads.
    //
    lsr     r2, r0, #(32 - 8)
    add     r2, r2, r2, lsl #1
    ldr     r3, atan2PU_table_19
    add     r3, r3, r2, lsl #2

    //
    // r0       ratio of inputs in UQ32
    // {r1,r2}
    // r3       Pointer into lookup table
    // r4       Loaded coefficient
    //
    ldr     r4, [r3]
    umull   r2, r1, r4, r0
    ldrd    r4, r5, [r3, #4]!
    sub     r4, r4, r1
    umull   r2, r1, r0, r4
    add     r0, r1, r5

    //
    // Divide by four to get to Q30.  Consider working this into coefficients
    // to save one cycle.
    //
    lsr     r0, r0, #2

    //
    // r0 : atanPU of input, within the first octant, UQ30.  [0,.5)
    // R12: Destination Octant >
    //      r12[31] = |Y|>|X|
    //      r12[30] =  X < 0
    //      r12[29] =  Y < 0
    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
equal_operands_reentry_point_19
    lsls    r12, r12, #1

    //
    //  if(|y|>|x|) r0 = 0.5 - r0
    //
    it      cs
        rsbcs   r0, r0, #0x20000000

    //
    //  if( x < 0 ) r0 = 1.0 - r0
    //
    it      mi
        rsbmi   r0, r0, #0x40000000

    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
    lsls    r12, r12, #1
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply by pi to return to radians from CPU.
    //
    ldr     r1, piq29_19
    smull   r1, r0, r1, r0

    //
    // Shift result to normalize from Q27.
    //
    asrs    r0, r0, #(27 - 19)
    adc     r0, r0, #0
    pop     {r4, r5}
    bx      lr

    //
    // If the operands are (0,0), the answer is defined to be zero.  This is
    // consistent with the standard C definition.
    //
operands_are_equal_19
    teq     r0, #0
    it      eq
        bxeq    lr

    //
    // If the operands are equal but nonzero, the result is one of the 45's
    // Skip the division etc and re-enter normal program flow just before
    // octant determination after setting the "result" to an eighth PU radian.
    //
    // Push r4 and r5 for consistency, even though we don't use them in this
    // execution path.
    //
    mov     r0, #0x10000000
    push    {r4, r5}
    b       equal_operands_reentry_point_19

    //
    // The literal pool.
    //
    alignrom 2
    data
piq29_19
    dcd     0x6487ed51         // pi in Q29
div_table_19
    dcd     div_table - 0x800
atan2PU_table_19
    dcd     atan2PU_table

//*****************************************************************************
//
// _IQ20atan2
//
//*****************************************************************************
    section CODE__IQ20atan2:CODE(2)
    thumb
    export  _IQ20atan2
_IQ20atan2
    //
    // Take absolute values of inputs and store sign information in r12.
    // r12[29] =  Y < 0
    // r12[30] =  X < 0
    // r12[31] = |Y|>|X|
    //
    ands    r12, r0, #0x80000000
    it      ne
        rsbne   r0, r0, #0
    lsls    r2, r1, #1
    it      cs
        rsbcs   r1, r1, #0
    rrx     r12, r12

    //
    // Place the larger of the two inputs in r1, the smaller in r0.
    // Remember this decision in R12.
    //
    cmp     r0, r1
    rrx     r12, r12
    beq     operands_are_equal_20
    ittt    hi
        movhi   r2, r0
        movhi   r0, r1
        movhi   r1, r2

    //
    // Divide r0 by r1 to find the ratio
    // Save state to stack.
    //
    push    {r4, r5}

    //
    // Normalize denominator to (1.0 0.5) in Q32
    //
    clz     r5, r1
    lsl     r1, r1, r5

    //
    //    r0 numerator GQ       r1 normalized denominator Q32
    //    r2 1/denominator Q31  r3 normalization n I
    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r1, #(32 - 10)
    ldr     r3, div_table_20
    ldr     r2, [r3, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // Dm = 2(Dm - Dm^2*Dnorm/2)
    // r2 = 2(r2 - r2^2*r1/2)
    // r1:Q32, r2:Q31
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sub     r3, r2, r3
    lsl     r2, r3, #1

    //
    // Newton Raphson Iteration  #2
    // 8-12 Cycles
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sbc     r2, r2, r3

    //
    // Multiply numerator by 1/denominator:
    // r2 is in Q29
    //
    umull   r1, r0, r0, r2

    //
    // Prepare the shift values.
    // Put the result in Q31.
    // Do not round, for fear of overflow.
    //
    add     r5, r5, #2
    rsb     r4, r5, #32
    lsr     r1, r1, r4
    lsl     r0, r0, r5
    add     r0, r0, r1

    //
    // r0 holds the calculated ratio of the inputs as UQ32.
    // r1 - r5 are available for use, r4 is saved on the stack.
    // r12 contains information on which octant the final result should be in.
    //
    // Use the top 8 bits of the ratio as a table index into the lookup table.
    // Multiply it by 3 because there are 3 coefficients per index value.
    //
    // There may be a wasted cycle here; It adds the offset to the table index
    // separately. This is so that r3 is updated to the appropriate position
    // for the next 2 loads.
    //
    lsr     r2, r0, #(32 - 8)
    add     r2, r2, r2, lsl #1
    ldr     r3, atan2PU_table_20
    add     r3, r3, r2, lsl #2

    //
    // r0       ratio of inputs in UQ32
    // {r1,r2}
    // r3       Pointer into lookup table
    // r4       Loaded coefficient
    //
    ldr     r4, [r3]
    umull   r2, r1, r4, r0
    ldrd    r4, r5, [r3, #4]!
    sub     r4, r4, r1
    umull   r2, r1, r0, r4
    add     r0, r1, r5

    //
    // Divide by four to get to Q30.  Consider working this into coefficients
    // to save one cycle.
    //
    lsr     r0, r0, #2

    //
    // r0 : atanPU of input, within the first octant, UQ30.  [0,.5)
    // R12: Destination Octant >
    //      r12[31] = |Y|>|X|
    //      r12[30] =  X < 0
    //      r12[29] =  Y < 0
    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
equal_operands_reentry_point_20
    lsls    r12, r12, #1

    //
    //  if(|y|>|x|) r0 = 0.5 - r0
    //
    it      cs
        rsbcs   r0, r0, #0x20000000

    //
    //  if( x < 0 ) r0 = 1.0 - r0
    //
    it      mi
        rsbmi   r0, r0, #0x40000000

    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
    lsls    r12, r12, #1
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply by pi to return to radians from CPU.
    //
    ldr     r1, piq29_20
    smull   r1, r0, r1, r0

    //
    // Shift result to normalize from Q27.
    //
    asrs    r0, r0, #(27 - 20)
    adc     r0, r0, #0
    pop     {r4, r5}
    bx      lr

    //
    // If the operands are (0,0), the answer is defined to be zero.  This is
    // consistent with the standard C definition.
    //
operands_are_equal_20
    teq     r0, #0
    it      eq
        bxeq    lr

    //
    // If the operands are equal but nonzero, the result is one of the 45's
    // Skip the division etc and re-enter normal program flow just before
    // octant determination after setting the "result" to an eighth PU radian.
    //
    // Push r4 and r5 for consistency, even though we don't use them in this
    // execution path.
    //
    mov     r0, #0x10000000
    push    {r4, r5}
    b       equal_operands_reentry_point_20

    //
    // The literal pool.
    //
    alignrom 2
    data
piq29_20
    dcd     0x6487ed51         // pi in Q29
div_table_20
    dcd     div_table - 0x800
atan2PU_table_20
    dcd     atan2PU_table

//*****************************************************************************
//
// _IQ21atan2
//
//*****************************************************************************
    section CODE__IQ21atan2:CODE(2)
    thumb
    export  _IQ21atan2
_IQ21atan2
    //
    // Take absolute values of inputs and store sign information in r12.
    // r12[29] =  Y < 0
    // r12[30] =  X < 0
    // r12[31] = |Y|>|X|
    //
    ands    r12, r0, #0x80000000
    it      ne
        rsbne   r0, r0, #0
    lsls    r2, r1, #1
    it      cs
        rsbcs   r1, r1, #0
    rrx     r12, r12

    //
    // Place the larger of the two inputs in r1, the smaller in r0.
    // Remember this decision in R12.
    //
    cmp     r0, r1
    rrx     r12, r12
    beq     operands_are_equal_21
    ittt    hi
        movhi   r2, r0
        movhi   r0, r1
        movhi   r1, r2

    //
    // Divide r0 by r1 to find the ratio
    // Save state to stack.
    //
    push    {r4, r5}

    //
    // Normalize denominator to (1.0 0.5) in Q32
    //
    clz     r5, r1
    lsl     r1, r1, r5

    //
    //    r0 numerator GQ       r1 normalized denominator Q32
    //    r2 1/denominator Q31  r3 normalization n I
    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r1, #(32 - 10)
    ldr     r3, div_table_21
    ldr     r2, [r3, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // Dm = 2(Dm - Dm^2*Dnorm/2)
    // r2 = 2(r2 - r2^2*r1/2)
    // r1:Q32, r2:Q31
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sub     r3, r2, r3
    lsl     r2, r3, #1

    //
    // Newton Raphson Iteration  #2
    // 8-12 Cycles
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sbc     r2, r2, r3

    //
    // Multiply numerator by 1/denominator:
    // r2 is in Q29
    //
    umull   r1, r0, r0, r2

    //
    // Prepare the shift values.
    // Put the result in Q31.
    // Do not round, for fear of overflow.
    //
    add     r5, r5, #2
    rsb     r4, r5, #32
    lsr     r1, r1, r4
    lsl     r0, r0, r5
    add     r0, r0, r1

    //
    // r0 holds the calculated ratio of the inputs as UQ32.
    // r1 - r5 are available for use, r4 is saved on the stack.
    // r12 contains information on which octant the final result should be in.
    //
    // Use the top 8 bits of the ratio as a table index into the lookup table.
    // Multiply it by 3 because there are 3 coefficients per index value.
    //
    // There may be a wasted cycle here; It adds the offset to the table index
    // separately. This is so that r3 is updated to the appropriate position
    // for the next 2 loads.
    //
    lsr     r2, r0, #(32 - 8)
    add     r2, r2, r2, lsl #1
    ldr     r3, atan2PU_table_21
    add     r3, r3, r2, lsl #2

    //
    // r0       ratio of inputs in UQ32
    // {r1,r2}
    // r3       Pointer into lookup table
    // r4       Loaded coefficient
    //
    ldr     r4, [r3]
    umull   r2, r1, r4, r0
    ldrd    r4, r5, [r3, #4]!
    sub     r4, r4, r1
    umull   r2, r1, r0, r4
    add     r0, r1, r5

    //
    // Divide by four to get to Q30.  Consider working this into coefficients
    // to save one cycle.
    //
    lsr     r0, r0, #2

    //
    // r0 : atanPU of input, within the first octant, UQ30.  [0,.5)
    // R12: Destination Octant >
    //      r12[31] = |Y|>|X|
    //      r12[30] =  X < 0
    //      r12[29] =  Y < 0
    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
equal_operands_reentry_point_21
    lsls    r12, r12, #1

    //
    //  if(|y|>|x|) r0 = 0.5 - r0
    //
    it      cs
        rsbcs   r0, r0, #0x20000000

    //
    //  if( x < 0 ) r0 = 1.0 - r0
    //
    it      mi
        rsbmi   r0, r0, #0x40000000

    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
    lsls    r12, r12, #1
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply by pi to return to radians from CPU.
    //
    ldr     r1, piq29_21
    smull   r1, r0, r1, r0

    //
    // Shift result to normalize from Q27.
    //
    asrs    r0, r0, #(27 - 21)
    adc     r0, r0, #0
    pop     {r4, r5}
    bx      lr

    //
    // If the operands are (0,0), the answer is defined to be zero.  This is
    // consistent with the standard C definition.
    //
operands_are_equal_21
    teq     r0, #0
    it      eq
        bxeq    lr

    //
    // If the operands are equal but nonzero, the result is one of the 45's
    // Skip the division etc and re-enter normal program flow just before
    // octant determination after setting the "result" to an eighth PU radian.
    //
    // Push r4 and r5 for consistency, even though we don't use them in this
    // execution path.
    //
    mov     r0, #0x10000000
    push    {r4, r5}
    b       equal_operands_reentry_point_21

    //
    // The literal pool.
    //
    alignrom 2
    data
piq29_21
    dcd     0x6487ed51         // pi in Q29
div_table_21
    dcd     div_table - 0x800
atan2PU_table_21
    dcd     atan2PU_table

//*****************************************************************************
//
// _IQ22atan2
//
//*****************************************************************************
    section CODE__IQ22atan2:CODE(2)
    thumb
    export  _IQ22atan2
_IQ22atan2
    //
    // Take absolute values of inputs and store sign information in r12.
    // r12[29] =  Y < 0
    // r12[30] =  X < 0
    // r12[31] = |Y|>|X|
    //
    ands    r12, r0, #0x80000000
    it      ne
        rsbne   r0, r0, #0
    lsls    r2, r1, #1
    it      cs
        rsbcs   r1, r1, #0
    rrx     r12, r12

    //
    // Place the larger of the two inputs in r1, the smaller in r0.
    // Remember this decision in R12.
    //
    cmp     r0, r1
    rrx     r12, r12
    beq     operands_are_equal_22
    ittt    hi
        movhi   r2, r0
        movhi   r0, r1
        movhi   r1, r2

    //
    // Divide r0 by r1 to find the ratio
    // Save state to stack.
    //
    push    {r4, r5}

    //
    // Normalize denominator to (1.0 0.5) in Q32
    //
    clz     r5, r1
    lsl     r1, r1, r5

    //
    //    r0 numerator GQ       r1 normalized denominator Q32
    //    r2 1/denominator Q31  r3 normalization n I
    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r1, #(32 - 10)
    ldr     r3, div_table_22
    ldr     r2, [r3, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // Dm = 2(Dm - Dm^2*Dnorm/2)
    // r2 = 2(r2 - r2^2*r1/2)
    // r1:Q32, r2:Q31
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sub     r3, r2, r3
    lsl     r2, r3, #1

    //
    // Newton Raphson Iteration  #2
    // 8-12 Cycles
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sbc     r2, r2, r3

    //
    // Multiply numerator by 1/denominator:
    // r2 is in Q29
    //
    umull   r1, r0, r0, r2

    //
    // Prepare the shift values.
    // Put the result in Q31.
    // Do not round, for fear of overflow.
    //
    add     r5, r5, #2
    rsb     r4, r5, #32
    lsr     r1, r1, r4
    lsl     r0, r0, r5
    add     r0, r0, r1

    //
    // r0 holds the calculated ratio of the inputs as UQ32.
    // r1 - r5 are available for use, r4 is saved on the stack.
    // r12 contains information on which octant the final result should be in.
    //
    // Use the top 8 bits of the ratio as a table index into the lookup table.
    // Multiply it by 3 because there are 3 coefficients per index value.
    //
    // There may be a wasted cycle here; It adds the offset to the table index
    // separately. This is so that r3 is updated to the appropriate position
    // for the next 2 loads.
    //
    lsr     r2, r0, #(32 - 8)
    add     r2, r2, r2, lsl #1
    ldr     r3, atan2PU_table_22
    add     r3, r3, r2, lsl #2

    //
    // r0       ratio of inputs in UQ32
    // {r1,r2}
    // r3       Pointer into lookup table
    // r4       Loaded coefficient
    //
    ldr     r4, [r3]
    umull   r2, r1, r4, r0
    ldrd    r4, r5, [r3, #4]!
    sub     r4, r4, r1
    umull   r2, r1, r0, r4
    add     r0, r1, r5

    //
    // Divide by four to get to Q30.  Consider working this into coefficients
    // to save one cycle.
    //
    lsr     r0, r0, #2

    //
    // r0 : atanPU of input, within the first octant, UQ30.  [0,.5)
    // R12: Destination Octant >
    //      r12[31] = |Y|>|X|
    //      r12[30] =  X < 0
    //      r12[29] =  Y < 0
    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
equal_operands_reentry_point_22
    lsls    r12, r12, #1

    //
    //  if(|y|>|x|) r0 = 0.5 - r0
    //
    it      cs
        rsbcs   r0, r0, #0x20000000

    //
    //  if( x < 0 ) r0 = 1.0 - r0
    //
    it      mi
        rsbmi   r0, r0, #0x40000000

    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
    lsls    r12, r12, #1
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply by pi to return to radians from CPU.
    //
    ldr     r1, piq29_22
    smull   r1, r0, r1, r0

    //
    // Shift result to normalize from Q27.
    //
    asrs    r0, r0, #(27 - 22)
    adc     r0, r0, #0
    pop     {r4, r5}
    bx      lr

    //
    // If the operands are (0,0), the answer is defined to be zero.  This is
    // consistent with the standard C definition.
    //
operands_are_equal_22
    teq     r0, #0
    it      eq
        bxeq    lr

    //
    // If the operands are equal but nonzero, the result is one of the 45's
    // Skip the division etc and re-enter normal program flow just before
    // octant determination after setting the "result" to an eighth PU radian.
    //
    // Push r4 and r5 for consistency, even though we don't use them in this
    // execution path.
    //
    mov     r0, #0x10000000
    push    {r4, r5}
    b       equal_operands_reentry_point_22

    //
    // The literal pool.
    //
    alignrom 2
    data
piq29_22
    dcd     0x6487ed51         // pi in Q29
div_table_22
    dcd     div_table - 0x800
atan2PU_table_22
    dcd     atan2PU_table

//*****************************************************************************
//
// _IQ23atan2
//
//*****************************************************************************
    section CODE__IQ23atan2:CODE(2)
    thumb
    export  _IQ23atan2
_IQ23atan2
    //
    // Take absolute values of inputs and store sign information in r12.
    // r12[29] =  Y < 0
    // r12[30] =  X < 0
    // r12[31] = |Y|>|X|
    //
    ands    r12, r0, #0x80000000
    it      ne
        rsbne   r0, r0, #0
    lsls    r2, r1, #1
    it      cs
        rsbcs   r1, r1, #0
    rrx     r12, r12

    //
    // Place the larger of the two inputs in r1, the smaller in r0.
    // Remember this decision in R12.
    //
    cmp     r0, r1
    rrx     r12, r12
    beq     operands_are_equal_23
    ittt    hi
        movhi   r2, r0
        movhi   r0, r1
        movhi   r1, r2

    //
    // Divide r0 by r1 to find the ratio
    // Save state to stack.
    //
    push    {r4, r5}

    //
    // Normalize denominator to (1.0 0.5) in Q32
    //
    clz     r5, r1
    lsl     r1, r1, r5

    //
    //    r0 numerator GQ       r1 normalized denominator Q32
    //    r2 1/denominator Q31  r3 normalization n I
    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r1, #(32 - 10)
    ldr     r3, div_table_23
    ldr     r2, [r3, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // Dm = 2(Dm - Dm^2*Dnorm/2)
    // r2 = 2(r2 - r2^2*r1/2)
    // r1:Q32, r2:Q31
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sub     r3, r2, r3
    lsl     r2, r3, #1

    //
    // Newton Raphson Iteration  #2
    // 8-12 Cycles
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sbc     r2, r2, r3

    //
    // Multiply numerator by 1/denominator:
    // r2 is in Q29
    //
    umull   r1, r0, r0, r2

    //
    // Prepare the shift values.
    // Put the result in Q31.
    // Do not round, for fear of overflow.
    //
    add     r5, r5, #2
    rsb     r4, r5, #32
    lsr     r1, r1, r4
    lsl     r0, r0, r5
    add     r0, r0, r1

    //
    // r0 holds the calculated ratio of the inputs as UQ32.
    // r1 - r5 are available for use, r4 is saved on the stack.
    // r12 contains information on which octant the final result should be in.
    //
    // Use the top 8 bits of the ratio as a table index into the lookup table.
    // Multiply it by 3 because there are 3 coefficients per index value.
    //
    // There may be a wasted cycle here; It adds the offset to the table index
    // separately. This is so that r3 is updated to the appropriate position
    // for the next 2 loads.
    //
    lsr     r2, r0, #(32 - 8)
    add     r2, r2, r2, lsl #1
    ldr     r3, atan2PU_table_23
    add     r3, r3, r2, lsl #2

    //
    // r0       ratio of inputs in UQ32
    // {r1,r2}
    // r3       Pointer into lookup table
    // r4       Loaded coefficient
    //
    ldr     r4, [r3]
    umull   r2, r1, r4, r0
    ldrd    r4, r5, [r3, #4]!
    sub     r4, r4, r1
    umull   r2, r1, r0, r4
    add     r0, r1, r5

    //
    // Divide by four to get to Q30.  Consider working this into coefficients
    // to save one cycle.
    //
    lsr     r0, r0, #2

    //
    // r0 : atanPU of input, within the first octant, UQ30.  [0,.5)
    // R12: Destination Octant >
    //      r12[31] = |Y|>|X|
    //      r12[30] =  X < 0
    //      r12[29] =  Y < 0
    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
equal_operands_reentry_point_23
    lsls    r12, r12, #1

    //
    //  if(|y|>|x|) r0 = 0.5 - r0
    //
    it      cs
        rsbcs   r0, r0, #0x20000000

    //
    //  if( x < 0 ) r0 = 1.0 - r0
    //
    it      mi
        rsbmi   r0, r0, #0x40000000

    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
    lsls    r12, r12, #1
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply by pi to return to radians from CPU.
    //
    ldr     r1, piq29_23
    smull   r1, r0, r1, r0

    //
    // Shift result to normalize from Q27.
    //
    asrs    r0, r0, #(27 - 23)
    adc     r0, r0, #0
    pop     {r4, r5}
    bx      lr

    //
    // If the operands are (0,0), the answer is defined to be zero.  This is
    // consistent with the standard C definition.
    //
operands_are_equal_23
    teq     r0, #0
    it      eq
        bxeq    lr

    //
    // If the operands are equal but nonzero, the result is one of the 45's
    // Skip the division etc and re-enter normal program flow just before
    // octant determination after setting the "result" to an eighth PU radian.
    //
    // Push r4 and r5 for consistency, even though we don't use them in this
    // execution path.
    //
    mov     r0, #0x10000000
    push    {r4, r5}
    b       equal_operands_reentry_point_23

    //
    // The literal pool.
    //
    alignrom 2
    data
piq29_23
    dcd     0x6487ed51         // pi in Q29
div_table_23
    dcd     div_table - 0x800
atan2PU_table_23
    dcd     atan2PU_table

//*****************************************************************************
//
// _IQ24atan2
//
//*****************************************************************************
    section CODE__IQ24atan2:CODE(2)
    thumb
    export  _IQ24atan2
_IQ24atan2
    //
    // Take absolute values of inputs and store sign information in r12.
    // r12[29] =  Y < 0
    // r12[30] =  X < 0
    // r12[31] = |Y|>|X|
    //
    ands    r12, r0, #0x80000000
    it      ne
        rsbne   r0, r0, #0
    lsls    r2, r1, #1
    it      cs
        rsbcs   r1, r1, #0
    rrx     r12, r12

    //
    // Place the larger of the two inputs in r1, the smaller in r0.
    // Remember this decision in R12.
    //
    cmp     r0, r1
    rrx     r12, r12
    beq     operands_are_equal_24
    ittt    hi
        movhi   r2, r0
        movhi   r0, r1
        movhi   r1, r2

    //
    // Divide r0 by r1 to find the ratio
    // Save state to stack.
    //
    push    {r4, r5}

    //
    // Normalize denominator to (1.0 0.5) in Q32
    //
    clz     r5, r1
    lsl     r1, r1, r5

    //
    //    r0 numerator GQ       r1 normalized denominator Q32
    //    r2 1/denominator Q31  r3 normalization n I
    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r1, #(32 - 10)
    ldr     r3, div_table_24
    ldr     r2, [r3, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // Dm = 2(Dm - Dm^2*Dnorm/2)
    // r2 = 2(r2 - r2^2*r1/2)
    // r1:Q32, r2:Q31
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sub     r3, r2, r3
    lsl     r2, r3, #1

    //
    // Newton Raphson Iteration  #2
    // 8-12 Cycles
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sbc     r2, r2, r3

    //
    // Multiply numerator by 1/denominator:
    // r2 is in Q29
    //
    umull   r1, r0, r0, r2

    //
    // Prepare the shift values.
    // Put the result in Q31.
    // Do not round, for fear of overflow.
    //
    add     r5, r5, #2
    rsb     r4, r5, #32
    lsr     r1, r1, r4
    lsl     r0, r0, r5
    add     r0, r0, r1

    //
    // r0 holds the calculated ratio of the inputs as UQ32.
    // r1 - r5 are available for use, r4 is saved on the stack.
    // r12 contains information on which octant the final result should be in.
    //
    // Use the top 8 bits of the ratio as a table index into the lookup table.
    // Multiply it by 3 because there are 3 coefficients per index value.
    //
    // There may be a wasted cycle here; It adds the offset to the table index
    // separately. This is so that r3 is updated to the appropriate position
    // for the next 2 loads.
    //
    lsr     r2, r0, #(32 - 8)
    add     r2, r2, r2, lsl #1
    ldr     r3, atan2PU_table_24
    add     r3, r3, r2, lsl #2

    //
    // r0       ratio of inputs in UQ32
    // {r1,r2}
    // r3       Pointer into lookup table
    // r4       Loaded coefficient
    //
    ldr     r4, [r3]
    umull   r2, r1, r4, r0
    ldrd    r4, r5, [r3, #4]!
    sub     r4, r4, r1
    umull   r2, r1, r0, r4
    add     r0, r1, r5

    //
    // Divide by four to get to Q30.  Consider working this into coefficients
    // to save one cycle.
    //
    lsr     r0, r0, #2

    //
    // r0 : atanPU of input, within the first octant, UQ30.  [0,.5)
    // R12: Destination Octant >
    //      r12[31] = |Y|>|X|
    //      r12[30] =  X < 0
    //      r12[29] =  Y < 0
    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
equal_operands_reentry_point_24
    lsls    r12, r12, #1

    //
    //  if(|y|>|x|) r0 = 0.5 - r0
    //
    it      cs
        rsbcs   r0, r0, #0x20000000

    //
    //  if( x < 0 ) r0 = 1.0 - r0
    //
    it      mi
        rsbmi   r0, r0, #0x40000000

    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
    lsls    r12, r12, #1
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply by pi to return to radians from CPU.
    //
    ldr     r1, piq29_24
    smull   r1, r0, r1, r0

    //
    // Shift result to normalize from Q27.
    //
    asrs    r0, r0, #(27 - 24)
    adc     r0, r0, #0
    pop     {r4, r5}
    bx      lr

    //
    // If the operands are (0,0), the answer is defined to be zero.  This is
    // consistent with the standard C definition.
    //
operands_are_equal_24
    teq     r0, #0
    it      eq
        bxeq    lr

    //
    // If the operands are equal but nonzero, the result is one of the 45's
    // Skip the division etc and re-enter normal program flow just before
    // octant determination after setting the "result" to an eighth PU radian.
    //
    // Push r4 and r5 for consistency, even though we don't use them in this
    // execution path.
    //
    mov     r0, #0x10000000
    push    {r4, r5}
    b       equal_operands_reentry_point_24

    //
    // The literal pool.
    //
    alignrom 2
    data
piq29_24
    dcd     0x6487ed51         // pi in Q29
div_table_24
    dcd     div_table - 0x800
atan2PU_table_24
    dcd     atan2PU_table

//*****************************************************************************
//
// _IQ25atan2
//
//*****************************************************************************
    section CODE__IQ25atan2:CODE(2)
    thumb
    export  _IQ25atan2
_IQ25atan2
    //
    // Take absolute values of inputs and store sign information in r12.
    // r12[29] =  Y < 0
    // r12[30] =  X < 0
    // r12[31] = |Y|>|X|
    //
    ands    r12, r0, #0x80000000
    it      ne
        rsbne   r0, r0, #0
    lsls    r2, r1, #1
    it      cs
        rsbcs   r1, r1, #0
    rrx     r12, r12

    //
    // Place the larger of the two inputs in r1, the smaller in r0.
    // Remember this decision in R12.
    //
    cmp     r0, r1
    rrx     r12, r12
    beq     operands_are_equal_25
    ittt    hi
        movhi   r2, r0
        movhi   r0, r1
        movhi   r1, r2

    //
    // Divide r0 by r1 to find the ratio
    // Save state to stack.
    //
    push    {r4, r5}

    //
    // Normalize denominator to (1.0 0.5) in Q32
    //
    clz     r5, r1
    lsl     r1, r1, r5

    //
    //    r0 numerator GQ       r1 normalized denominator Q32
    //    r2 1/denominator Q31  r3 normalization n I
    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r1, #(32 - 10)
    ldr     r3, div_table_25
    ldr     r2, [r3, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // Dm = 2(Dm - Dm^2*Dnorm/2)
    // r2 = 2(r2 - r2^2*r1/2)
    // r1:Q32, r2:Q31
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sub     r3, r2, r3
    lsl     r2, r3, #1

    //
    // Newton Raphson Iteration  #2
    // 8-12 Cycles
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sbc     r2, r2, r3

    //
    // Multiply numerator by 1/denominator:
    // r2 is in Q29
    //
    umull   r1, r0, r0, r2

    //
    // Prepare the shift values.
    // Put the result in Q31.
    // Do not round, for fear of overflow.
    //
    add     r5, r5, #2
    rsb     r4, r5, #32
    lsr     r1, r1, r4
    lsl     r0, r0, r5
    add     r0, r0, r1

    //
    // r0 holds the calculated ratio of the inputs as UQ32.
    // r1 - r5 are available for use, r4 is saved on the stack.
    // r12 contains information on which octant the final result should be in.
    //
    // Use the top 8 bits of the ratio as a table index into the lookup table.
    // Multiply it by 3 because there are 3 coefficients per index value.
    //
    // There may be a wasted cycle here; It adds the offset to the table index
    // separately. This is so that r3 is updated to the appropriate position
    // for the next 2 loads.
    //
    lsr     r2, r0, #(32 - 8)
    add     r2, r2, r2, lsl #1
    ldr     r3, atan2PU_table_25
    add     r3, r3, r2, lsl #2

    //
    // r0       ratio of inputs in UQ32
    // {r1,r2}
    // r3       Pointer into lookup table
    // r4       Loaded coefficient
    //
    ldr     r4, [r3]
    umull   r2, r1, r4, r0
    ldrd    r4, r5, [r3, #4]!
    sub     r4, r4, r1
    umull   r2, r1, r0, r4
    add     r0, r1, r5

    //
    // Divide by four to get to Q30.  Consider working this into coefficients
    // to save one cycle.
    //
    lsr     r0, r0, #2

    //
    // r0 : atanPU of input, within the first octant, UQ30.  [0,.5)
    // R12: Destination Octant >
    //      r12[31] = |Y|>|X|
    //      r12[30] =  X < 0
    //      r12[29] =  Y < 0
    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
equal_operands_reentry_point_25
    lsls    r12, r12, #1

    //
    //  if(|y|>|x|) r0 = 0.5 - r0
    //
    it      cs
        rsbcs   r0, r0, #0x20000000

    //
    //  if( x < 0 ) r0 = 1.0 - r0
    //
    it      mi
        rsbmi   r0, r0, #0x40000000

    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
    lsls    r12, r12, #1
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply by pi to return to radians from CPU.
    //
    ldr     r1, piq29_25
    smull   r1, r0, r1, r0

    //
    // Shift result to normalize from Q27.
    //
    asrs    r0, r0, #(27 - 25)
    adc     r0, r0, #0
    pop     {r4, r5}
    bx      lr

    //
    // If the operands are (0,0), the answer is defined to be zero.  This is
    // consistent with the standard C definition.
    //
operands_are_equal_25
    teq     r0, #0
    it      eq
        bxeq    lr

    //
    // If the operands are equal but nonzero, the result is one of the 45's
    // Skip the division etc and re-enter normal program flow just before
    // octant determination after setting the "result" to an eighth PU radian.
    //
    // Push r4 and r5 for consistency, even though we don't use them in this
    // execution path.
    //
    mov     r0, #0x10000000
    push    {r4, r5}
    b       equal_operands_reentry_point_25

    //
    // The literal pool.
    //
    alignrom 2
    data
piq29_25
    dcd     0x6487ed51         // pi in Q29
div_table_25
    dcd     div_table - 0x800
atan2PU_table_25
    dcd     atan2PU_table

//*****************************************************************************
//
// _IQ26atan2
//
//*****************************************************************************
    section CODE__IQ26atan2:CODE(2)
    thumb
    export  _IQ26atan2
_IQ26atan2
    //
    // Take absolute values of inputs and store sign information in r12.
    // r12[29] =  Y < 0
    // r12[30] =  X < 0
    // r12[31] = |Y|>|X|
    //
    ands    r12, r0, #0x80000000
    it      ne
        rsbne   r0, r0, #0
    lsls    r2, r1, #1
    it      cs
        rsbcs   r1, r1, #0
    rrx     r12, r12

    //
    // Place the larger of the two inputs in r1, the smaller in r0.
    // Remember this decision in R12.
    //
    cmp     r0, r1
    rrx     r12, r12
    beq     operands_are_equal_26
    ittt    hi
        movhi   r2, r0
        movhi   r0, r1
        movhi   r1, r2

    //
    // Divide r0 by r1 to find the ratio
    // Save state to stack.
    //
    push    {r4, r5}

    //
    // Normalize denominator to (1.0 0.5) in Q32
    //
    clz     r5, r1
    lsl     r1, r1, r5

    //
    //    r0 numerator GQ       r1 normalized denominator Q32
    //    r2 1/denominator Q31  r3 normalization n I
    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r1, #(32 - 10)
    ldr     r3, div_table_26
    ldr     r2, [r3, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // Dm = 2(Dm - Dm^2*Dnorm/2)
    // r2 = 2(r2 - r2^2*r1/2)
    // r1:Q32, r2:Q31
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sub     r3, r2, r3
    lsl     r2, r3, #1

    //
    // Newton Raphson Iteration  #2
    // 8-12 Cycles
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sbc     r2, r2, r3

    //
    // Multiply numerator by 1/denominator:
    // r2 is in Q29
    //
    umull   r1, r0, r0, r2

    //
    // Prepare the shift values.
    // Put the result in Q31.
    // Do not round, for fear of overflow.
    //
    add     r5, r5, #2
    rsb     r4, r5, #32
    lsr     r1, r1, r4
    lsl     r0, r0, r5
    add     r0, r0, r1

    //
    // r0 holds the calculated ratio of the inputs as UQ32.
    // r1 - r5 are available for use, r4 is saved on the stack.
    // r12 contains information on which octant the final result should be in.
    //
    // Use the top 8 bits of the ratio as a table index into the lookup table.
    // Multiply it by 3 because there are 3 coefficients per index value.
    //
    // There may be a wasted cycle here; It adds the offset to the table index
    // separately. This is so that r3 is updated to the appropriate position
    // for the next 2 loads.
    //
    lsr     r2, r0, #(32 - 8)
    add     r2, r2, r2, lsl #1
    ldr     r3, atan2PU_table_26
    add     r3, r3, r2, lsl #2

    //
    // r0       ratio of inputs in UQ32
    // {r1,r2}
    // r3       Pointer into lookup table
    // r4       Loaded coefficient
    //
    ldr     r4, [r3]
    umull   r2, r1, r4, r0
    ldrd    r4, r5, [r3, #4]!
    sub     r4, r4, r1
    umull   r2, r1, r0, r4
    add     r0, r1, r5

    //
    // Divide by four to get to Q30.  Consider working this into coefficients
    // to save one cycle.
    //
    lsr     r0, r0, #2

    //
    // r0 : atanPU of input, within the first octant, UQ30.  [0,.5)
    // R12: Destination Octant >
    //      r12[31] = |Y|>|X|
    //      r12[30] =  X < 0
    //      r12[29] =  Y < 0
    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
equal_operands_reentry_point_26
    lsls    r12, r12, #1

    //
    //  if(|y|>|x|) r0 = 0.5 - r0
    //
    it      cs
        rsbcs   r0, r0, #0x20000000

    //
    //  if( x < 0 ) r0 = 1.0 - r0
    //
    it      mi
        rsbmi   r0, r0, #0x40000000

    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
    lsls    r12, r12, #1
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply by pi to return to radians from CPU.
    //
    ldr     r1, piq29_26
    smull   r1, r0, r1, r0

    //
    // Shift result to normalize from Q27.
    //
    asrs    r0, r0, #(27 - 26)
    adc     r0, r0, #0
    pop     {r4, r5}
    bx      lr

    //
    // If the operands are (0,0), the answer is defined to be zero.  This is
    // consistent with the standard C definition.
    //
operands_are_equal_26
    teq     r0, #0
    it      eq
        bxeq    lr

    //
    // If the operands are equal but nonzero, the result is one of the 45's
    // Skip the division etc and re-enter normal program flow just before
    // octant determination after setting the "result" to an eighth PU radian.
    //
    // Push r4 and r5 for consistency, even though we don't use them in this
    // execution path.
    //
    mov     r0, #0x10000000
    push    {r4, r5}
    b       equal_operands_reentry_point_26

    //
    // The literal pool.
    //
    alignrom 2
    data
piq29_26
    dcd     0x6487ed51         // pi in Q29
div_table_26
    dcd     div_table - 0x800
atan2PU_table_26
    dcd     atan2PU_table

//*****************************************************************************
//
// _IQ27atan2
//
//*****************************************************************************
    section CODE__IQ27atan2:CODE(2)
    thumb
    export  _IQ27atan2
_IQ27atan2
    //
    // Take absolute values of inputs and store sign information in r12.
    // r12[29] =  Y < 0
    // r12[30] =  X < 0
    // r12[31] = |Y|>|X|
    //
    ands    r12, r0, #0x80000000
    it      ne
        rsbne   r0, r0, #0
    lsls    r2, r1, #1
    it      cs
        rsbcs   r1, r1, #0
    rrx     r12, r12

    //
    // Place the larger of the two inputs in r1, the smaller in r0.
    // Remember this decision in R12.
    //
    cmp     r0, r1
    rrx     r12, r12
    beq     operands_are_equal_27
    ittt    hi
        movhi   r2, r0
        movhi   r0, r1
        movhi   r1, r2

    //
    // Divide r0 by r1 to find the ratio
    // Save state to stack.
    //
    push    {r4, r5}

    //
    // Normalize denominator to (1.0 0.5) in Q32
    //
    clz     r5, r1
    lsl     r1, r1, r5

    //
    //    r0 numerator GQ       r1 normalized denominator Q32
    //    r2 1/denominator Q31  r3 normalization n I
    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r1, #(32 - 10)
    ldr     r3, div_table_27
    ldr     r2, [r3, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // Dm = 2(Dm - Dm^2*Dnorm/2)
    // r2 = 2(r2 - r2^2*r1/2)
    // r1:Q32, r2:Q31
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sub     r3, r2, r3
    lsl     r2, r3, #1

    //
    // Newton Raphson Iteration  #2
    // 8-12 Cycles
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sbc     r2, r2, r3

    //
    // Multiply numerator by 1/denominator:
    // r2 is in Q29
    //
    umull   r1, r0, r0, r2

    //
    // Prepare the shift values.
    // Put the result in Q31.
    // Do not round, for fear of overflow.
    //
    add     r5, r5, #2
    rsb     r4, r5, #32
    lsr     r1, r1, r4
    lsl     r0, r0, r5
    add     r0, r0, r1

    //
    // r0 holds the calculated ratio of the inputs as UQ32.
    // r1 - r5 are available for use, r4 is saved on the stack.
    // r12 contains information on which octant the final result should be in.
    //
    // Use the top 8 bits of the ratio as a table index into the lookup table.
    // Multiply it by 3 because there are 3 coefficients per index value.
    //
    // There may be a wasted cycle here; It adds the offset to the table index
    // separately. This is so that r3 is updated to the appropriate position
    // for the next 2 loads.
    //
    lsr     r2, r0, #(32 - 8)
    add     r2, r2, r2, lsl #1
    ldr     r3, atan2PU_table_27
    add     r3, r3, r2, lsl #2

    //
    // r0       ratio of inputs in UQ32
    // {r1,r2}
    // r3       Pointer into lookup table
    // r4       Loaded coefficient
    //
    ldr     r4, [r3]
    umull   r2, r1, r4, r0
    ldrd    r4, r5, [r3, #4]!
    sub     r4, r4, r1
    umull   r2, r1, r0, r4
    add     r0, r1, r5

    //
    // Divide by four to get to Q30.  Consider working this into coefficients
    // to save one cycle.
    //
    lsr     r0, r0, #2

    //
    // r0 : atanPU of input, within the first octant, UQ30.  [0,.5)
    // R12: Destination Octant >
    //      r12[31] = |Y|>|X|
    //      r12[30] =  X < 0
    //      r12[29] =  Y < 0
    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
equal_operands_reentry_point_27
    lsls    r12, r12, #1

    //
    //  if(|y|>|x|) r0 = 0.5 - r0
    //
    it      cs
        rsbcs   r0, r0, #0x20000000

    //
    //  if( x < 0 ) r0 = 1.0 - r0
    //
    it      mi
        rsbmi   r0, r0, #0x40000000

    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
    lsls    r12, r12, #1
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply by pi to return to radians from CPU.
    //
    ldr     r1, piq29_27
    smull   r1, r0, r1, r0

    //
    // Shift result to normalize from Q27.
    //
    pop     {r4, r5}
    bx      lr

    //
    // If the operands are (0,0), the answer is defined to be zero.  This is
    // consistent with the standard C definition.
    //
operands_are_equal_27
    teq     r0, #0
    it      eq
        bxeq    lr

    //
    // If the operands are equal but nonzero, the result is one of the 45's
    // Skip the division etc and re-enter normal program flow just before
    // octant determination after setting the "result" to an eighth PU radian.
    //
    // Push r4 and r5 for consistency, even though we don't use them in this
    // execution path.
    //
    mov     r0, #0x10000000
    push    {r4, r5}
    b       equal_operands_reentry_point_27

    //
    // The literal pool.
    //
    alignrom 2
    data
piq29_27
    dcd     0x6487ed51         // pi in Q29
div_table_27
    dcd     div_table - 0x800
atan2PU_table_27
    dcd     atan2PU_table

//*****************************************************************************
//
// _IQ28atan2
//
//*****************************************************************************
    section CODE__IQ28atan2:CODE(2)
    thumb
    export  _IQ28atan2
_IQ28atan2
    //
    // Take absolute values of inputs and store sign information in r12.
    // r12[29] =  Y < 0
    // r12[30] =  X < 0
    // r12[31] = |Y|>|X|
    //
    ands    r12, r0, #0x80000000
    it      ne
        rsbne   r0, r0, #0
    lsls    r2, r1, #1
    it      cs
        rsbcs   r1, r1, #0
    rrx     r12, r12

    //
    // Place the larger of the two inputs in r1, the smaller in r0.
    // Remember this decision in R12.
    //
    cmp     r0, r1
    rrx     r12, r12
    beq     operands_are_equal_28
    ittt    hi
        movhi   r2, r0
        movhi   r0, r1
        movhi   r1, r2

    //
    // Divide r0 by r1 to find the ratio
    // Save state to stack.
    //
    push    {r4, r5}

    //
    // Normalize denominator to (1.0 0.5) in Q32
    //
    clz     r5, r1
    lsl     r1, r1, r5

    //
    //    r0 numerator GQ       r1 normalized denominator Q32
    //    r2 1/denominator Q31  r3 normalization n I
    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r1, #(32 - 10)
    ldr     r3, div_table_28
    ldr     r2, [r3, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // Dm = 2(Dm - Dm^2*Dnorm/2)
    // r2 = 2(r2 - r2^2*r1/2)
    // r1:Q32, r2:Q31
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sub     r3, r2, r3
    lsl     r2, r3, #1

    //
    // Newton Raphson Iteration  #2
    // 8-12 Cycles
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sbc     r2, r2, r3

    //
    // Multiply numerator by 1/denominator:
    // r2 is in Q29
    //
    umull   r1, r0, r0, r2

    //
    // Prepare the shift values.
    // Put the result in Q31.
    // Do not round, for fear of overflow.
    //
    add     r5, r5, #2
    rsb     r4, r5, #32
    lsr     r1, r1, r4
    lsl     r0, r0, r5
    add     r0, r0, r1

    //
    // r0 holds the calculated ratio of the inputs as UQ32.
    // r1 - r5 are available for use, r4 is saved on the stack.
    // r12 contains information on which octant the final result should be in.
    //
    // Use the top 8 bits of the ratio as a table index into the lookup table.
    // Multiply it by 3 because there are 3 coefficients per index value.
    //
    // There may be a wasted cycle here; It adds the offset to the table index
    // separately. This is so that r3 is updated to the appropriate position
    // for the next 2 loads.
    //
    lsr     r2, r0, #(32 - 8)
    add     r2, r2, r2, lsl #1
    ldr     r3, atan2PU_table_28
    add     r3, r3, r2, lsl #2

    //
    // r0       ratio of inputs in UQ32
    // {r1,r2}
    // r3       Pointer into lookup table
    // r4       Loaded coefficient
    //
    ldr     r4, [r3]
    umull   r2, r1, r4, r0
    ldrd    r4, r5, [r3, #4]!
    sub     r4, r4, r1
    umull   r2, r1, r0, r4
    add     r0, r1, r5

    //
    // Divide by four to get to Q30.  Consider working this into coefficients
    // to save one cycle.
    //
    lsr     r0, r0, #2

    //
    // r0 : atanPU of input, within the first octant, UQ30.  [0,.5)
    // R12: Destination Octant >
    //      r12[31] = |Y|>|X|
    //      r12[30] =  X < 0
    //      r12[29] =  Y < 0
    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
equal_operands_reentry_point_28
    lsls    r12, r12, #1

    //
    //  if(|y|>|x|) r0 = 0.5 - r0
    //
    it      cs
        rsbcs   r0, r0, #0x20000000

    //
    //  if( x < 0 ) r0 = 1.0 - r0
    //
    it      mi
        rsbmi   r0, r0, #0x40000000

    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
    lsls    r12, r12, #1
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply by pi to return to radians from CPU.
    //
    ldr     r1, piq29_28
    smull   r1, r0, r1, r0

    //
    // Shift result to normalize from Q27.
    //
    lsrs    r1, r1, #(32 - (28 - 27))
    adc     r0, r1, r0, lsl #(28 - 27)
    pop     {r4, r5}
    bx      lr

    //
    // If the operands are (0,0), the answer is defined to be zero.  This is
    // consistent with the standard C definition.
    //
operands_are_equal_28
    teq     r0, #0
    it      eq
        bxeq    lr

    //
    // If the operands are equal but nonzero, the result is one of the 45's
    // Skip the division etc and re-enter normal program flow just before
    // octant determination after setting the "result" to an eighth PU radian.
    //
    // Push r4 and r5 for consistency, even though we don't use them in this
    // execution path.
    //
    mov     r0, #0x10000000
    push    {r4, r5}
    b       equal_operands_reentry_point_28

    //
    // The literal pool.
    //
    alignrom 2
    data
piq29_28
    dcd     0x6487ed51         // pi in Q29
div_table_28
    dcd     div_table - 0x800
atan2PU_table_28
    dcd     atan2PU_table

//*****************************************************************************
//
// _IQ29atan2
//
//*****************************************************************************
    section CODE__IQ29atan2:CODE(2)
    thumb
    export  _IQ29atan2
_IQ29atan2
    //
    // Take absolute values of inputs and store sign information in r12.
    // r12[29] =  Y < 0
    // r12[30] =  X < 0
    // r12[31] = |Y|>|X|
    //
    ands    r12, r0, #0x80000000
    it      ne
        rsbne   r0, r0, #0
    lsls    r2, r1, #1
    it      cs
        rsbcs   r1, r1, #0
    rrx     r12, r12

    //
    // Place the larger of the two inputs in r1, the smaller in r0.
    // Remember this decision in R12.
    //
    cmp     r0, r1
    rrx     r12, r12
    beq     operands_are_equal_29
    ittt    hi
        movhi   r2, r0
        movhi   r0, r1
        movhi   r1, r2

    //
    // Divide r0 by r1 to find the ratio
    // Save state to stack.
    //
    push    {r4, r5}

    //
    // Normalize denominator to (1.0 0.5) in Q32
    //
    clz     r5, r1
    lsl     r1, r1, r5

    //
    //    r0 numerator GQ       r1 normalized denominator Q32
    //    r2 1/denominator Q31  r3 normalization n I
    //
    // Table Lookup for Initial Estimate
    // Uses  the top 9 actual bits as index
    // The top bit (#10) is ignored, because it is always one.  This is done
    // with the -0x800.  (0x200 is 10th bit, shift up two for 4 byte words).
    //
    lsr     r2, r1, #(32 - 10)
    ldr     r3, div_table_29
    ldr     r2, [r3, r2, lsl #2]

    //
    // Newton Raphson Iteration  #1
    // Dm = 2(Dm - Dm^2*Dnorm/2)
    // r2 = 2(r2 - r2^2*r1/2)
    // r1:Q32, r2:Q31
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sub     r3, r2, r3
    lsl     r2, r3, #1

    //
    // Newton Raphson Iteration  #2
    // 8-12 Cycles
    //
    umull   r4, r3, r2, r2
    umull   r4, r3, r3, r1
    sbc     r2, r2, r3

    //
    // Multiply numerator by 1/denominator:
    // r2 is in Q29
    //
    umull   r1, r0, r0, r2

    //
    // Prepare the shift values.
    // Put the result in Q31.
    // Do not round, for fear of overflow.
    //
    add     r5, r5, #2
    rsb     r4, r5, #32
    lsr     r1, r1, r4
    lsl     r0, r0, r5
    add     r0, r0, r1

    //
    // r0 holds the calculated ratio of the inputs as UQ32.
    // r1 - r5 are available for use, r4 is saved on the stack.
    // r12 contains information on which octant the final result should be in.
    //
    // Use the top 8 bits of the ratio as a table index into the lookup table.
    // Multiply it by 3 because there are 3 coefficients per index value.
    //
    // There may be a wasted cycle here; It adds the offset to the table index
    // separately. This is so that r3 is updated to the appropriate position
    // for the next 2 loads.
    //
    lsr     r2, r0, #(32 - 8)
    add     r2, r2, r2, lsl #1
    ldr     r3, atan2PU_table_29
    add     r3, r3, r2, lsl #2

    //
    // r0       ratio of inputs in UQ32
    // {r1,r2}
    // r3       Pointer into lookup table
    // r4       Loaded coefficient
    //
    ldr     r4, [r3]
    umull   r2, r1, r4, r0
    ldrd    r4, r5, [r3, #4]!
    sub     r4, r4, r1
    umull   r2, r1, r0, r4
    add     r0, r1, r5

    //
    // Divide by four to get to Q30.  Consider working this into coefficients
    // to save one cycle.
    //
    lsr     r0, r0, #2

    //
    // r0 : atanPU of input, within the first octant, UQ30.  [0,.5)
    // R12: Destination Octant >
    //      r12[31] = |Y|>|X|
    //      r12[30] =  X < 0
    //      r12[29] =  Y < 0
    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
equal_operands_reentry_point_29
    lsls    r12, r12, #1

    //
    //  if(|y|>|x|) r0 = 0.5 - r0
    //
    it      cs
        rsbcs   r0, r0, #0x20000000

    //
    //  if( x < 0 ) r0 = 1.0 - r0
    //
    it      mi
        rsbmi   r0, r0, #0x40000000

    //
    //  if( y < 0 ) r0 = 0.0 - r0
    //
    lsls    r12, r12, #1
    it      mi
        rsbmi   r0, r0, #0

    //
    // Multiply by pi to return to radians from CPU.
    //
    ldr     r1, piq29_29
    smull   r1, r0, r1, r0

    //
    // Shift result to normalize from Q27.
    //
    lsrs    r1, r1, #(32 - (29 - 27))
    adc     r0, r1, r0, lsl #(29 - 27)
    pop     {r4, r5}
    bx      lr

    //
    // If the operands are (0,0), the answer is defined to be zero.  This is
    // consistent with the standard C definition.
    //
operands_are_equal_29
    teq     r0, #0
    it      eq
        bxeq    lr

    //
    // If the operands are equal but nonzero, the result is one of the 45's
    // Skip the division etc and re-enter normal program flow just before
    // octant determination after setting the "result" to an eighth PU radian.
    //
    // Push r4 and r5 for consistency, even though we don't use them in this
    // execution path.
    //
    mov     r0, #0x10000000
    push    {r4, r5}
    b       equal_operands_reentry_point_29

    //
    // The literal pool.
    //
    alignrom 2
    data
piq29_29
    dcd     0x6487ed51         // pi in Q29
div_table_29
    dcd     div_table - 0x800
atan2PU_table_29
    dcd     atan2PU_table

    end
