//*****************************************************************************
//
// IQcos.S - Fixed point calculation of cos in radians
//
// Copyright (c) 2010 Texas Instruments Incorporated.  All rights reserved.
// TI Information - Selective Disclosure
//
//*****************************************************************************

//*****************************************************************************
//
// Function:   _IQNcos
//
//*****************************************************************************
//
// C Usage:    extern long _IQNcos(long U);
//
//-----------------------------------------------------------------------------
//
// On Entry:   r0    = U in IQ format
//
//
// Regs Used:  r0-r3, r12
//
// On Exit:    r0    = cos(U)
//
//
// Q range:    29 to 1
//      NOTE:   This will actually generate 30 to 1, but 30 is not officially
//              "on the list". C2000's documentation states that it is only 
//              1-29, but has header entries for 30 as well.  In any case, Q30
//              generates up to 4 counts of error, but is otherwise usable.
//
//-----------------------------------------------------------------------------
//
// Algorithm:  The procedure for calculating "Y = cos(U)" is as follows:
//
//      Step 1)  Normalize U to be within Quadrant I
//
//      Step 2)  Use upper 9 bits to lookup sin(index) and cos(index).
//
//      Step 3)  Use Taylor series to estimate cos(index+remainder).
//               Up to 6 terms used, dependendent on Q
//
//      Note:   Index == 0 is handled as a special case.  It is a linear 
//              approximation with a slope just less than pi.  Value was 
//              chosen to minimize maximal error : +/-2 counts in Q30.
//
//##### INTERNAL BEGIN #####
//-----------------------------------------------------------------------------
// Future Work:
//
//   It may be possible to fold this function in with the PU implementation. 
//   The differences are only at the head of the function, and are listed 
//   below:
//      Load and multiply by 1/pi
//      The left shift to truncate is 64 bits instead of 32-bits.
//   Making the 64-bit left shift "fallable" may be difficult. Best guess would
//   be to change the macro definition to _IQsin(_iq x,0);.  This would allow
//   us to always use the add instruction without fear of what might be in r1.
//
//   As currently implemented, the residual is initialized to zero.  
//   A quick improvement would be to skip the initialization and fold it into 
//   the following add or rsb instruction.  This would be dependendant on Q. 
//   A better option may be to initialize it to 1/(2*n!)*{sin,cos}(index).
//   This might allow us to fake out an entire order of the expansion as a 
//   pseudo constant, and save us a few multiplies.  Optimal value not yet 
//   calculated, it would have to be done similarly to the index == 0 
//   optimization.
//
//   Consider returning to a full-wave implementation (instead of quarter-wave)
//   This would require signed math (2-3 cycle penalty per multiply, for SMULL
//   vs UMULL, plus additional shifting/ rounding), but would eliminate 
//   the expensive setup / tear down of the function.  Would also eliminate
//   special case handling.  If this path is chosen, center-align the Taylor-
//   series.
//
//   This implementation is "tuneable", in that it is relatively easy to 
//   choose how many terms in the expansion are active for each Q.  They are
//   currently chosen such that we hit +/-1 count of accuracy for all Q: it is
//   expensive to do better due to fixed point rounding. If desired, these 
//   choices can be revisited later with speed in mind.
//
//##### INTERNAL END #####
//-----------------------------------------------------------------------------
//
// Benchmark:
//
//        Q <= 30       : 78 Cycles
//        Q <= 29       : 71 Cycles
//   9 <= Q <= 20       : 59 Cycles
//   1 <= Q <=  8       : 31 Cycles
//
//  These are all worst case: Quadrant 3.  Others are 1-4 quicker.
//
//*****************************************************************************

//*****************************************************************************
//
// The sin/cos table is used.
//
//*****************************************************************************
    import  sincos_table

//*****************************************************************************
//
// _IQ1cos
//
//*****************************************************************************
    section CODE__IQ1cos:CODE(2)
    thumb
    export  _IQ1cos
_IQ1cos
    //
    // Convert from radians to radians per unit by dividing by pi
    // This is done by multiplying by 1/pi in Q32
    //
    ldr     r1, invpiq32_1
    smull   r1, r0, r1, r0

    //
    // Load the table pointer into memory early, since we have more than
    // enough registers to handle it.
    //
    ldr     r3, sincos_table_1

    //
    // Put the input into Q31.
    // Since this is in Per Unit radians, we only care about the 1s digit
    // to determine sign of the result.  Higher bits are useless.
    //
    lsl     r0, r0, #(31 - 1)
    add     r0, r0, r1, lsr #(1 + 1)
    add     r0, r0, #0x40000000

    //
    // If the fractional portion is greater than 0.5, subtract it from 1.0
    // This is because sin(x) = sin(1-x) in per unit radians, and we only store
    // the [0,.5) in the table.
    //
    lsls    r1, r0, #2
    it      cs
        rsbcs   r0, r0, #0x80000000

    //
    // Remove the sign bit and store it in the carry flag
    //
    lsls    r0, r0, #1

    //
    // Lookup the value from the table.
    //
    ubfx    r1, r0, #(32 - 10), #10
    ldr     r0, [r3, r1, lsl #2]

    //
    // Sign compensate, shift down for Q and round.
    //
    lsr     r0, r0, #1
    it      cs
        rsbcs   r0, r0, #0
    asrs    r0, r0, #(31 - 1)
    adc     r0, r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
sincos_table_1
    dcd     sincos_table
invpiq32_1
    dcd     0x517cc1b7         // 1/pi in Q32

//*****************************************************************************
//
// _IQ2cos
//
//*****************************************************************************
    section CODE__IQ2cos:CODE(2)
    thumb
    export  _IQ2cos
_IQ2cos
    //
    // Convert from radians to radians per unit by dividing by pi
    // This is done by multiplying by 1/pi in Q32
    //
    ldr     r1, invpiq32_2
    smull   r1, r0, r1, r0

    //
    // Load the table pointer into memory early, since we have more than
    // enough registers to handle it.
    //
    ldr     r3, sincos_table_2

    //
    // Put the input into Q31.
    // Since this is in Per Unit radians, we only care about the 1s digit
    // to determine sign of the result.  Higher bits are useless.
    //
    lsl     r0, r0, #(31 - 2)
    add     r0, r0, r1, lsr #(2 + 1)
    add     r0, r0, #0x40000000

    //
    // If the fractional portion is greater than 0.5, subtract it from 1.0
    // This is because sin(x) = sin(1-x) in per unit radians, and we only store
    // the [0,.5) in the table.
    //
    lsls    r1, r0, #2
    it      cs
        rsbcs   r0, r0, #0x80000000

    //
    // Remove the sign bit and store it in the carry flag
    //
    lsls    r0, r0, #1

    //
    // Lookup the value from the table.
    //
    ubfx    r1, r0, #(32 - 10), #10
    ldr     r0, [r3, r1, lsl #2]

    //
    // Sign compensate, shift down for Q and round.
    //
    lsr     r0, r0, #1
    it      cs
        rsbcs   r0, r0, #0
    asrs    r0, r0, #(31 - 2)
    adc     r0, r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
sincos_table_2
    dcd     sincos_table
invpiq32_2
    dcd     0x517cc1b7         // 1/pi in Q32

//*****************************************************************************
//
// _IQ3cos
//
//*****************************************************************************
    section CODE__IQ3cos:CODE(2)
    thumb
    export  _IQ3cos
_IQ3cos
    //
    // Convert from radians to radians per unit by dividing by pi
    // This is done by multiplying by 1/pi in Q32
    //
    ldr     r1, invpiq32_3
    smull   r1, r0, r1, r0

    //
    // Load the table pointer into memory early, since we have more than
    // enough registers to handle it.
    //
    ldr     r3, sincos_table_3

    //
    // Put the input into Q31.
    // Since this is in Per Unit radians, we only care about the 1s digit
    // to determine sign of the result.  Higher bits are useless.
    //
    lsl     r0, r0, #(31 - 3)
    add     r0, r0, r1, lsr #(3 + 1)
    add     r0, r0, #0x40000000

    //
    // If the fractional portion is greater than 0.5, subtract it from 1.0
    // This is because sin(x) = sin(1-x) in per unit radians, and we only store
    // the [0,.5) in the table.
    //
    lsls    r1, r0, #2
    it      cs
        rsbcs   r0, r0, #0x80000000

    //
    // Remove the sign bit and store it in the carry flag
    //
    lsls    r0, r0, #1

    //
    // Lookup the value from the table.
    //
    ubfx    r1, r0, #(32 - 10), #10
    ldr     r0, [r3, r1, lsl #2]

    //
    // Sign compensate, shift down for Q and round.
    //
    lsr     r0, r0, #1
    it      cs
        rsbcs   r0, r0, #0
    asrs    r0, r0, #(31 - 3)
    adc     r0, r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
sincos_table_3
    dcd     sincos_table
invpiq32_3
    dcd     0x517cc1b7         // 1/pi in Q32

//*****************************************************************************
//
// _IQ4cos
//
//*****************************************************************************
    section CODE__IQ4cos:CODE(2)
    thumb
    export  _IQ4cos
_IQ4cos
    //
    // Convert from radians to radians per unit by dividing by pi
    // This is done by multiplying by 1/pi in Q32
    //
    ldr     r1, invpiq32_4
    smull   r1, r0, r1, r0

    //
    // Load the table pointer into memory early, since we have more than
    // enough registers to handle it.
    //
    ldr     r3, sincos_table_4

    //
    // Put the input into Q31.
    // Since this is in Per Unit radians, we only care about the 1s digit
    // to determine sign of the result.  Higher bits are useless.
    //
    lsl     r0, r0, #(31 - 4)
    add     r0, r0, r1, lsr #(4 + 1)
    add     r0, r0, #0x40000000

    //
    // If the fractional portion is greater than 0.5, subtract it from 1.0
    // This is because sin(x) = sin(1-x) in per unit radians, and we only store
    // the [0,.5) in the table.
    //
    lsls    r1, r0, #2
    it      cs
        rsbcs   r0, r0, #0x80000000

    //
    // Remove the sign bit and store it in the carry flag
    //
    lsls    r0, r0, #1

    //
    // Lookup the value from the table.
    //
    ubfx    r1, r0, #(32 - 10), #10
    ldr     r0, [r3, r1, lsl #2]

    //
    // Sign compensate, shift down for Q and round.
    //
    lsr     r0, r0, #1
    it      cs
        rsbcs   r0, r0, #0
    asrs    r0, r0, #(31 - 4)
    adc     r0, r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
sincos_table_4
    dcd     sincos_table
invpiq32_4
    dcd     0x517cc1b7         // 1/pi in Q32

//*****************************************************************************
//
// _IQ5cos
//
//*****************************************************************************
    section CODE__IQ5cos:CODE(2)
    thumb
    export  _IQ5cos
_IQ5cos
    //
    // Convert from radians to radians per unit by dividing by pi
    // This is done by multiplying by 1/pi in Q32
    //
    ldr     r1, invpiq32_5
    smull   r1, r0, r1, r0

    //
    // Load the table pointer into memory early, since we have more than
    // enough registers to handle it.
    //
    ldr     r3, sincos_table_5

    //
    // Put the input into Q31.
    // Since this is in Per Unit radians, we only care about the 1s digit
    // to determine sign of the result.  Higher bits are useless.
    //
    lsl     r0, r0, #(31 - 5)
    add     r0, r0, r1, lsr #(5 + 1)
    add     r0, r0, #0x40000000

    //
    // If the fractional portion is greater than 0.5, subtract it from 1.0
    // This is because sin(x) = sin(1-x) in per unit radians, and we only store
    // the [0,.5) in the table.
    //
    lsls    r1, r0, #2
    it      cs
        rsbcs   r0, r0, #0x80000000

    //
    // Remove the sign bit and store it in the carry flag
    //
    lsls    r0, r0, #1

    //
    // Lookup the value from the table.
    //
    ubfx    r1, r0, #(32 - 10), #10
    ldr     r0, [r3, r1, lsl #2]

    //
    // Sign compensate, shift down for Q and round.
    //
    lsr     r0, r0, #1
    it      cs
        rsbcs   r0, r0, #0
    asrs    r0, r0, #(31 - 5)
    adc     r0, r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
sincos_table_5
    dcd     sincos_table
invpiq32_5
    dcd     0x517cc1b7         // 1/pi in Q32

//*****************************************************************************
//
// _IQ6cos
//
//*****************************************************************************
    section CODE__IQ6cos:CODE(2)
    thumb
    export  _IQ6cos
_IQ6cos
    //
    // Convert from radians to radians per unit by dividing by pi
    // This is done by multiplying by 1/pi in Q32
    //
    ldr     r1, invpiq32_6
    smull   r1, r0, r1, r0

    //
    // Load the table pointer into memory early, since we have more than
    // enough registers to handle it.
    //
    ldr     r3, sincos_table_6

    //
    // Put the input into Q31.
    // Since this is in Per Unit radians, we only care about the 1s digit
    // to determine sign of the result.  Higher bits are useless.
    //
    lsl     r0, r0, #(31 - 6)
    add     r0, r0, r1, lsr #(6 + 1)
    add     r0, r0, #0x40000000

    //
    // If the fractional portion is greater than 0.5, subtract it from 1.0
    // This is because sin(x) = sin(1-x) in per unit radians, and we only store
    // the [0,.5) in the table.
    //
    lsls    r1, r0, #2
    it      cs
        rsbcs   r0, r0, #0x80000000

    //
    // Remove the sign bit and store it in the carry flag
    //
    lsls    r0, r0, #1

    //
    // Lookup the value from the table.
    //
    ubfx    r1, r0, #(32 - 10), #10
    ldr     r0, [r3, r1, lsl #2]

    //
    // Sign compensate, shift down for Q and round.
    //
    lsr     r0, r0, #1
    it      cs
        rsbcs   r0, r0, #0
    asrs    r0, r0, #(31 - 6)
    adc     r0, r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
sincos_table_6
    dcd     sincos_table
invpiq32_6
    dcd     0x517cc1b7         // 1/pi in Q32

//*****************************************************************************
//
// _IQ7cos
//
//*****************************************************************************
    section CODE__IQ7cos:CODE(2)
    thumb
    export  _IQ7cos
_IQ7cos
    //
    // Convert from radians to radians per unit by dividing by pi
    // This is done by multiplying by 1/pi in Q32
    //
    ldr     r1, invpiq32_7
    smull   r1, r0, r1, r0

    //
    // Load the table pointer into memory early, since we have more than
    // enough registers to handle it.
    //
    ldr     r3, sincos_table_7

    //
    // Put the input into Q31.
    // Since this is in Per Unit radians, we only care about the 1s digit
    // to determine sign of the result.  Higher bits are useless.
    //
    lsl     r0, r0, #(31 - 7)
    add     r0, r0, r1, lsr #(7 + 1)
    add     r0, r0, #0x40000000

    //
    // If the fractional portion is greater than 0.5, subtract it from 1.0
    // This is because sin(x) = sin(1-x) in per unit radians, and we only store
    // the [0,.5) in the table.
    //
    lsls    r1, r0, #2
    it      cs
        rsbcs   r0, r0, #0x80000000

    //
    // Remove the sign bit and store it in the carry flag
    //
    lsls    r0, r0, #1

    //
    // Lookup the value from the table.
    //
    ubfx    r1, r0, #(32 - 10), #10
    ldr     r0, [r3, r1, lsl #2]

    //
    // Sign compensate, shift down for Q and round.
    //
    lsr     r0, r0, #1
    it      cs
        rsbcs   r0, r0, #0
    asrs    r0, r0, #(31 - 7)
    adc     r0, r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
sincos_table_7
    dcd     sincos_table
invpiq32_7
    dcd     0x517cc1b7         // 1/pi in Q32

//*****************************************************************************
//
// _IQ8cos
//
//*****************************************************************************
    section CODE__IQ8cos:CODE(2)
    thumb
    export  _IQ8cos
_IQ8cos
    //
    // Convert from radians to radians per unit by dividing by pi
    // This is done by multiplying by 1/pi in Q32
    //
    ldr     r1, invpiq32_8
    smull   r1, r0, r1, r0

    //
    // Load the table pointer into memory early, since we have more than
    // enough registers to handle it.
    //
    ldr     r3, sincos_table_8

    //
    // Put the input into Q31.
    // Since this is in Per Unit radians, we only care about the 1s digit
    // to determine sign of the result.  Higher bits are useless.
    //
    lsl     r0, r0, #(31 - 8)
    add     r0, r0, r1, lsr #(8 + 1)
    add     r0, r0, #0x40000000

    //
    // If the fractional portion is greater than 0.5, subtract it from 1.0
    // This is because sin(x) = sin(1-x) in per unit radians, and we only store
    // the [0,.5) in the table.
    //
    lsls    r1, r0, #2
    it      cs
        rsbcs   r0, r0, #0x80000000

    //
    // Remove the sign bit and store it in the carry flag
    //
    lsls    r0, r0, #1

    //
    // Lookup the value from the table.
    //
    ubfx    r1, r0, #(32 - 10), #10
    ldr     r0, [r3, r1, lsl #2]

    //
    // Sign compensate, shift down for Q and round.
    //
    lsr     r0, r0, #1
    it      cs
        rsbcs   r0, r0, #0
    asrs    r0, r0, #(31 - 8)
    adc     r0, r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
sincos_table_8
    dcd     sincos_table
invpiq32_8
    dcd     0x517cc1b7         // 1/pi in Q32

//*****************************************************************************
//
// _IQ9cos
//
//*****************************************************************************
    section CODE__IQ9cos:CODE(2)
    thumb
    export  _IQ9cos
_IQ9cos
    //
    // Convert from radians to radians per unit by dividing by pi
    // This is done by multiplying by 1/pi in Q32
    //
    ldr     r1, invpiq32_9
    smull   r1, r0, r1, r0

    //
    // Put the input into Q31.
    // Since this is in Per Unit radians, we only care about the 1s digit
    // to determine sign of the result.  Higher bits are useless.
    // This is equivalent to sin(x) = sin(x+2*n) in per unit radians.
    //
    lsl     r0, r0, #(31 - 9)
    add     r0, r0, r1, lsr #(9 + 1)
    add     r0, r0, #0x40000000

    //
    // If the fractional portion is greater than 0.5, subtract it from 1.0
    // This is equivalent to sin(x) = sin(1-x) in per unit radians.
    // r0 becomes UQ32 representation of input constrained to 1st Quadrant PU:
    // [0,.5)
    //
    lsls    r1, r0, #2
    it      cs
        rsbcs   r0, r0, #0x80000000
    lsls    r0, r0, #1

    //
    // Use the top 9 fractional bits as an index into the look up table.
    // Pull sine and cosine of the index.
    // Jump out if we're close enough to 0 to do a fully odd approximation.
    //
    ldr     r12, sincos_table_9
    ubfx    r1, r0, #(31 - 9), #10
    cbz     r1, cosindex0_9
    ldr     r2, [r12, r1, lsl #2]
    rsb     r1, r1, #512
    ldr     r3, [r12, r1, lsl #2]

    //
    // Put delta x in r1.
    // This is (x-index)*pi/2  in Q32
    // Consider replacing lsl/lsr combo with UBFX:
    // 1 cycle faster, but slightly less accurate delta x.
    //
    lsl     r1, r0, #(9 + 1)
    ldr     r12, piq30_9
    umull   r12, r1, r1, r12
    lsr     r1, r1, #(9 - 1)
    mov     r0, #0

    //
    // Calculates the taylor series expansion of sin(x)
    // Interval is 0:90 degrees.
    // Preconditions:
    // r0 = 0x00000000
    // r1 = remainder (x-index) in Q32 Radians
    // r2 = sin(index) in Q32
    // r3 = cos(index) in Q32
    // r12 is available as scratch space
    // ASPR contains sign flag as MI=flip sign.
    //
    // Calculate 2nd term of taylor series expansion.
    // This performs y = remainder/2*(sin(index)+y)
    // 5-7 cycles
    //
    add     r0, r2, r0
    umull   r12, r0, r0, r1
    lsr     r0, r0, #1

    //
    // Calculate 1st term of taylor series expansion.
    // This performs y = remainder/1*(cos(index)-y)
    // 4-6 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1

    //
    // Calculate 0th term of taylor series expansion.
    // This performs y = (sin(index)+y)
    //
    add     r0, r2, r0

    //
    // Compensate for sign flag in r5
    //
    lsr     r0, r0, #1
    it      cs
        rsbcs   r0, r0, #0
    asrs    r0, r0, #(31 - 9)
    adc     r0, r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // This branch handles the case very close to 0.
    // It uses the sin(x)=x approximation, but the constant is fudged down
    // a bit from pi to minimize the maximum error to +/-2 counts at Q30
    //
cosindex0_9
    ldr     r12, piq30_compensated_9
    umull   r12, r0, r0, r12
    lsr     r0, r0, #(30 - 9)
    it      cs
        rsbcs   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
sincos_table_9
    dcd     sincos_table
piq30_9
    dcd     0xc90fdaa2         // pi in Q30
piq30_compensated_9
    dcd     0xc90fcd37         // slightly less than pi in Q30
invpiq32_9
    dcd     0x517cc1b7         // 1/pi in Q32

//*****************************************************************************
//
// _IQ10cos
//
//*****************************************************************************
    section CODE__IQ10cos:CODE(2)
    thumb
    export  _IQ10cos
_IQ10cos
    //
    // Convert from radians to radians per unit by dividing by pi
    // This is done by multiplying by 1/pi in Q32
    //
    ldr     r1, invpiq32_10
    smull   r1, r0, r1, r0

    //
    // Put the input into Q31.
    // Since this is in Per Unit radians, we only care about the 1s digit
    // to determine sign of the result.  Higher bits are useless.
    // This is equivalent to sin(x) = sin(x+2*n) in per unit radians.
    //
    lsl     r0, r0, #(31 - 10)
    add     r0, r0, r1, lsr #(10 + 1)
    add     r0, r0, #0x40000000

    //
    // If the fractional portion is greater than 0.5, subtract it from 1.0
    // This is equivalent to sin(x) = sin(1-x) in per unit radians.
    // r0 becomes UQ32 representation of input constrained to 1st Quadrant PU:
    // [0,.5)
    //
    lsls    r1, r0, #2
    it      cs
        rsbcs   r0, r0, #0x80000000
    lsls    r0, r0, #1

    //
    // Use the top 9 fractional bits as an index into the look up table.
    // Pull sine and cosine of the index.
    // Jump out if we're close enough to 0 to do a fully odd approximation.
    //
    ldr     r12, sincos_table_10
    ubfx    r1, r0, #(31 - 9), #10
    cbz     r1, cosindex0_10
    ldr     r2, [r12, r1, lsl #2]
    rsb     r1, r1, #512
    ldr     r3, [r12, r1, lsl #2]

    //
    // Put delta x in r1.
    // This is (x-index)*pi/2  in Q32
    // Consider replacing lsl/lsr combo with UBFX:
    // 1 cycle faster, but slightly less accurate delta x.
    //
    lsl     r1, r0, #(9 + 1)
    ldr     r12, piq30_10
    umull   r12, r1, r1, r12
    lsr     r1, r1, #(9 - 1)
    mov     r0, #0

    //
    // Calculates the taylor series expansion of sin(x)
    // Interval is 0:90 degrees.
    // Preconditions:
    // r0 = 0x00000000
    // r1 = remainder (x-index) in Q32 Radians
    // r2 = sin(index) in Q32
    // r3 = cos(index) in Q32
    // r12 is available as scratch space
    // ASPR contains sign flag as MI=flip sign.
    //
    // Calculate 2nd term of taylor series expansion.
    // This performs y = remainder/2*(sin(index)+y)
    // 5-7 cycles
    //
    add     r0, r2, r0
    umull   r12, r0, r0, r1
    lsr     r0, r0, #1

    //
    // Calculate 1st term of taylor series expansion.
    // This performs y = remainder/1*(cos(index)-y)
    // 4-6 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1

    //
    // Calculate 0th term of taylor series expansion.
    // This performs y = (sin(index)+y)
    //
    add     r0, r2, r0

    //
    // Compensate for sign flag in r5
    //
    lsr     r0, r0, #1
    it      cs
        rsbcs   r0, r0, #0
    asrs    r0, r0, #(31 - 10)
    adc     r0, r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // This branch handles the case very close to 0.
    // It uses the sin(x)=x approximation, but the constant is fudged down
    // a bit from pi to minimize the maximum error to +/-2 counts at Q30
    //
cosindex0_10
    ldr     r12, piq30_compensated_10
    umull   r12, r0, r0, r12
    lsr     r0, r0, #(30 - 10)
    it      cs
        rsbcs   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
sincos_table_10
    dcd     sincos_table
piq30_10
    dcd     0xc90fdaa2         // pi in Q30
piq30_compensated_10
    dcd     0xc90fcd37         // slightly less than pi in Q30
invpiq32_10
    dcd     0x517cc1b7         // 1/pi in Q32

//*****************************************************************************
//
// _IQ11cos
//
//*****************************************************************************
    section CODE__IQ11cos:CODE(2)
    thumb
    export  _IQ11cos
_IQ11cos
    //
    // Convert from radians to radians per unit by dividing by pi
    // This is done by multiplying by 1/pi in Q32
    //
    ldr     r1, invpiq32_11
    smull   r1, r0, r1, r0

    //
    // Put the input into Q31.
    // Since this is in Per Unit radians, we only care about the 1s digit
    // to determine sign of the result.  Higher bits are useless.
    // This is equivalent to sin(x) = sin(x+2*n) in per unit radians.
    //
    lsl     r0, r0, #(31 - 11)
    add     r0, r0, r1, lsr #(11 + 1)
    add     r0, r0, #0x40000000

    //
    // If the fractional portion is greater than 0.5, subtract it from 1.0
    // This is equivalent to sin(x) = sin(1-x) in per unit radians.
    // r0 becomes UQ32 representation of input constrained to 1st Quadrant PU:
    // [0,.5)
    //
    lsls    r1, r0, #2
    it      cs
        rsbcs   r0, r0, #0x80000000
    lsls    r0, r0, #1

    //
    // Use the top 9 fractional bits as an index into the look up table.
    // Pull sine and cosine of the index.
    // Jump out if we're close enough to 0 to do a fully odd approximation.
    //
    ldr     r12, sincos_table_11
    ubfx    r1, r0, #(31 - 9), #10
    cbz     r1, cosindex0_11
    ldr     r2, [r12, r1, lsl #2]
    rsb     r1, r1, #512
    ldr     r3, [r12, r1, lsl #2]

    //
    // Put delta x in r1.
    // This is (x-index)*pi/2  in Q32
    // Consider replacing lsl/lsr combo with UBFX:
    // 1 cycle faster, but slightly less accurate delta x.
    //
    lsl     r1, r0, #(9 + 1)
    ldr     r12, piq30_11
    umull   r12, r1, r1, r12
    lsr     r1, r1, #(9 - 1)
    mov     r0, #0

    //
    // Calculates the taylor series expansion of sin(x)
    // Interval is 0:90 degrees.
    // Preconditions:
    // r0 = 0x00000000
    // r1 = remainder (x-index) in Q32 Radians
    // r2 = sin(index) in Q32
    // r3 = cos(index) in Q32
    // r12 is available as scratch space
    // ASPR contains sign flag as MI=flip sign.
    //
    // Calculate 2nd term of taylor series expansion.
    // This performs y = remainder/2*(sin(index)+y)
    // 5-7 cycles
    //
    add     r0, r2, r0
    umull   r12, r0, r0, r1
    lsr     r0, r0, #1

    //
    // Calculate 1st term of taylor series expansion.
    // This performs y = remainder/1*(cos(index)-y)
    // 4-6 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1

    //
    // Calculate 0th term of taylor series expansion.
    // This performs y = (sin(index)+y)
    //
    add     r0, r2, r0

    //
    // Compensate for sign flag in r5
    //
    lsr     r0, r0, #1
    it      cs
        rsbcs   r0, r0, #0
    asrs    r0, r0, #(31 - 11)
    adc     r0, r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // This branch handles the case very close to 0.
    // It uses the sin(x)=x approximation, but the constant is fudged down
    // a bit from pi to minimize the maximum error to +/-2 counts at Q30
    //
cosindex0_11
    ldr     r12, piq30_compensated_11
    umull   r12, r0, r0, r12
    lsr     r0, r0, #(30 - 11)
    it      cs
        rsbcs   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
sincos_table_11
    dcd     sincos_table
piq30_11
    dcd     0xc90fdaa2         // pi in Q30
piq30_compensated_11
    dcd     0xc90fcd37         // slightly less than pi in Q30
invpiq32_11
    dcd     0x517cc1b7         // 1/pi in Q32

//*****************************************************************************
//
// _IQ12cos
//
//*****************************************************************************
    section CODE__IQ12cos:CODE(2)
    thumb
    export  _IQ12cos
_IQ12cos
    //
    // Convert from radians to radians per unit by dividing by pi
    // This is done by multiplying by 1/pi in Q32
    //
    ldr     r1, invpiq32_12
    smull   r1, r0, r1, r0

    //
    // Put the input into Q31.
    // Since this is in Per Unit radians, we only care about the 1s digit
    // to determine sign of the result.  Higher bits are useless.
    // This is equivalent to sin(x) = sin(x+2*n) in per unit radians.
    //
    lsl     r0, r0, #(31 - 12)
    add     r0, r0, r1, lsr #(12 + 1)
    add     r0, r0, #0x40000000

    //
    // If the fractional portion is greater than 0.5, subtract it from 1.0
    // This is equivalent to sin(x) = sin(1-x) in per unit radians.
    // r0 becomes UQ32 representation of input constrained to 1st Quadrant PU:
    // [0,.5)
    //
    lsls    r1, r0, #2
    it      cs
        rsbcs   r0, r0, #0x80000000
    lsls    r0, r0, #1

    //
    // Use the top 9 fractional bits as an index into the look up table.
    // Pull sine and cosine of the index.
    // Jump out if we're close enough to 0 to do a fully odd approximation.
    //
    ldr     r12, sincos_table_12
    ubfx    r1, r0, #(31 - 9), #10
    cbz     r1, cosindex0_12
    ldr     r2, [r12, r1, lsl #2]
    rsb     r1, r1, #512
    ldr     r3, [r12, r1, lsl #2]

    //
    // Put delta x in r1.
    // This is (x-index)*pi/2  in Q32
    // Consider replacing lsl/lsr combo with UBFX:
    // 1 cycle faster, but slightly less accurate delta x.
    //
    lsl     r1, r0, #(9 + 1)
    ldr     r12, piq30_12
    umull   r12, r1, r1, r12
    lsr     r1, r1, #(9 - 1)
    mov     r0, #0

    //
    // Calculates the taylor series expansion of sin(x)
    // Interval is 0:90 degrees.
    // Preconditions:
    // r0 = 0x00000000
    // r1 = remainder (x-index) in Q32 Radians
    // r2 = sin(index) in Q32
    // r3 = cos(index) in Q32
    // r12 is available as scratch space
    // ASPR contains sign flag as MI=flip sign.
    //
    // Calculate 2nd term of taylor series expansion.
    // This performs y = remainder/2*(sin(index)+y)
    // 5-7 cycles
    //
    add     r0, r2, r0
    umull   r12, r0, r0, r1
    lsr     r0, r0, #1

    //
    // Calculate 1st term of taylor series expansion.
    // This performs y = remainder/1*(cos(index)-y)
    // 4-6 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1

    //
    // Calculate 0th term of taylor series expansion.
    // This performs y = (sin(index)+y)
    //
    add     r0, r2, r0

    //
    // Compensate for sign flag in r5
    //
    lsr     r0, r0, #1
    it      cs
        rsbcs   r0, r0, #0
    asrs    r0, r0, #(31 - 12)
    adc     r0, r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // This branch handles the case very close to 0.
    // It uses the sin(x)=x approximation, but the constant is fudged down
    // a bit from pi to minimize the maximum error to +/-2 counts at Q30
    //
cosindex0_12
    ldr     r12, piq30_compensated_12
    umull   r12, r0, r0, r12
    lsr     r0, r0, #(30 - 12)
    it      cs
        rsbcs   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
sincos_table_12
    dcd     sincos_table
piq30_12
    dcd     0xc90fdaa2         // pi in Q30
piq30_compensated_12
    dcd     0xc90fcd37         // slightly less than pi in Q30
invpiq32_12
    dcd     0x517cc1b7         // 1/pi in Q32

//*****************************************************************************
//
// _IQ13cos
//
//*****************************************************************************
    section CODE__IQ13cos:CODE(2)
    thumb
    export  _IQ13cos
_IQ13cos
    //
    // Convert from radians to radians per unit by dividing by pi
    // This is done by multiplying by 1/pi in Q32
    //
    ldr     r1, invpiq32_13
    smull   r1, r0, r1, r0

    //
    // Put the input into Q31.
    // Since this is in Per Unit radians, we only care about the 1s digit
    // to determine sign of the result.  Higher bits are useless.
    // This is equivalent to sin(x) = sin(x+2*n) in per unit radians.
    //
    lsl     r0, r0, #(31 - 13)
    add     r0, r0, r1, lsr #(13 + 1)
    add     r0, r0, #0x40000000

    //
    // If the fractional portion is greater than 0.5, subtract it from 1.0
    // This is equivalent to sin(x) = sin(1-x) in per unit radians.
    // r0 becomes UQ32 representation of input constrained to 1st Quadrant PU:
    // [0,.5)
    //
    lsls    r1, r0, #2
    it      cs
        rsbcs   r0, r0, #0x80000000
    lsls    r0, r0, #1

    //
    // Use the top 9 fractional bits as an index into the look up table.
    // Pull sine and cosine of the index.
    // Jump out if we're close enough to 0 to do a fully odd approximation.
    //
    ldr     r12, sincos_table_13
    ubfx    r1, r0, #(31 - 9), #10
    cbz     r1, cosindex0_13
    ldr     r2, [r12, r1, lsl #2]
    rsb     r1, r1, #512
    ldr     r3, [r12, r1, lsl #2]

    //
    // Put delta x in r1.
    // This is (x-index)*pi/2  in Q32
    // Consider replacing lsl/lsr combo with UBFX:
    // 1 cycle faster, but slightly less accurate delta x.
    //
    lsl     r1, r0, #(9 + 1)
    ldr     r12, piq30_13
    umull   r12, r1, r1, r12
    lsr     r1, r1, #(9 - 1)
    mov     r0, #0

    //
    // Calculates the taylor series expansion of sin(x)
    // Interval is 0:90 degrees.
    // Preconditions:
    // r0 = 0x00000000
    // r1 = remainder (x-index) in Q32 Radians
    // r2 = sin(index) in Q32
    // r3 = cos(index) in Q32
    // r12 is available as scratch space
    // ASPR contains sign flag as MI=flip sign.
    //
    // Calculate 2nd term of taylor series expansion.
    // This performs y = remainder/2*(sin(index)+y)
    // 5-7 cycles
    //
    add     r0, r2, r0
    umull   r12, r0, r0, r1
    lsr     r0, r0, #1

    //
    // Calculate 1st term of taylor series expansion.
    // This performs y = remainder/1*(cos(index)-y)
    // 4-6 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1

    //
    // Calculate 0th term of taylor series expansion.
    // This performs y = (sin(index)+y)
    //
    add     r0, r2, r0

    //
    // Compensate for sign flag in r5
    //
    lsr     r0, r0, #1
    it      cs
        rsbcs   r0, r0, #0
    asrs    r0, r0, #(31 - 13)
    adc     r0, r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // This branch handles the case very close to 0.
    // It uses the sin(x)=x approximation, but the constant is fudged down
    // a bit from pi to minimize the maximum error to +/-2 counts at Q30
    //
cosindex0_13
    ldr     r12, piq30_compensated_13
    umull   r12, r0, r0, r12
    lsr     r0, r0, #(30 - 13)
    it      cs
        rsbcs   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
sincos_table_13
    dcd     sincos_table
piq30_13
    dcd     0xc90fdaa2         // pi in Q30
piq30_compensated_13
    dcd     0xc90fcd37         // slightly less than pi in Q30
invpiq32_13
    dcd     0x517cc1b7         // 1/pi in Q32

//*****************************************************************************
//
// _IQ14cos
//
//*****************************************************************************
    section CODE__IQ14cos:CODE(2)
    thumb
    export  _IQ14cos
_IQ14cos
    //
    // Convert from radians to radians per unit by dividing by pi
    // This is done by multiplying by 1/pi in Q32
    //
    ldr     r1, invpiq32_14
    smull   r1, r0, r1, r0

    //
    // Put the input into Q31.
    // Since this is in Per Unit radians, we only care about the 1s digit
    // to determine sign of the result.  Higher bits are useless.
    // This is equivalent to sin(x) = sin(x+2*n) in per unit radians.
    //
    lsl     r0, r0, #(31 - 14)
    add     r0, r0, r1, lsr #(14 + 1)
    add     r0, r0, #0x40000000

    //
    // If the fractional portion is greater than 0.5, subtract it from 1.0
    // This is equivalent to sin(x) = sin(1-x) in per unit radians.
    // r0 becomes UQ32 representation of input constrained to 1st Quadrant PU:
    // [0,.5)
    //
    lsls    r1, r0, #2
    it      cs
        rsbcs   r0, r0, #0x80000000
    lsls    r0, r0, #1

    //
    // Use the top 9 fractional bits as an index into the look up table.
    // Pull sine and cosine of the index.
    // Jump out if we're close enough to 0 to do a fully odd approximation.
    //
    ldr     r12, sincos_table_14
    ubfx    r1, r0, #(31 - 9), #10
    cbz     r1, cosindex0_14
    ldr     r2, [r12, r1, lsl #2]
    rsb     r1, r1, #512
    ldr     r3, [r12, r1, lsl #2]

    //
    // Put delta x in r1.
    // This is (x-index)*pi/2  in Q32
    // Consider replacing lsl/lsr combo with UBFX:
    // 1 cycle faster, but slightly less accurate delta x.
    //
    lsl     r1, r0, #(9 + 1)
    ldr     r12, piq30_14
    umull   r12, r1, r1, r12
    lsr     r1, r1, #(9 - 1)
    mov     r0, #0

    //
    // Calculates the taylor series expansion of sin(x)
    // Interval is 0:90 degrees.
    // Preconditions:
    // r0 = 0x00000000
    // r1 = remainder (x-index) in Q32 Radians
    // r2 = sin(index) in Q32
    // r3 = cos(index) in Q32
    // r12 is available as scratch space
    // ASPR contains sign flag as MI=flip sign.
    //
    // Calculate 2nd term of taylor series expansion.
    // This performs y = remainder/2*(sin(index)+y)
    // 5-7 cycles
    //
    add     r0, r2, r0
    umull   r12, r0, r0, r1
    lsr     r0, r0, #1

    //
    // Calculate 1st term of taylor series expansion.
    // This performs y = remainder/1*(cos(index)-y)
    // 4-6 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1

    //
    // Calculate 0th term of taylor series expansion.
    // This performs y = (sin(index)+y)
    //
    add     r0, r2, r0

    //
    // Compensate for sign flag in r5
    //
    lsr     r0, r0, #1
    it      cs
        rsbcs   r0, r0, #0
    asrs    r0, r0, #(31 - 14)
    adc     r0, r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // This branch handles the case very close to 0.
    // It uses the sin(x)=x approximation, but the constant is fudged down
    // a bit from pi to minimize the maximum error to +/-2 counts at Q30
    //
cosindex0_14
    ldr     r12, piq30_compensated_14
    umull   r12, r0, r0, r12
    lsr     r0, r0, #(30 - 14)
    it      cs
        rsbcs   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
sincos_table_14
    dcd     sincos_table
piq30_14
    dcd     0xc90fdaa2         // pi in Q30
piq30_compensated_14
    dcd     0xc90fcd37         // slightly less than pi in Q30
invpiq32_14
    dcd     0x517cc1b7         // 1/pi in Q32

//*****************************************************************************
//
// _IQ15cos
//
//*****************************************************************************
    section CODE__IQ15cos:CODE(2)
    thumb
    export  _IQ15cos
_IQ15cos
    //
    // Convert from radians to radians per unit by dividing by pi
    // This is done by multiplying by 1/pi in Q32
    //
    ldr     r1, invpiq32_15
    smull   r1, r0, r1, r0

    //
    // Put the input into Q31.
    // Since this is in Per Unit radians, we only care about the 1s digit
    // to determine sign of the result.  Higher bits are useless.
    // This is equivalent to sin(x) = sin(x+2*n) in per unit radians.
    //
    lsl     r0, r0, #(31 - 15)
    add     r0, r0, r1, lsr #(15 + 1)
    add     r0, r0, #0x40000000

    //
    // If the fractional portion is greater than 0.5, subtract it from 1.0
    // This is equivalent to sin(x) = sin(1-x) in per unit radians.
    // r0 becomes UQ32 representation of input constrained to 1st Quadrant PU:
    // [0,.5)
    //
    lsls    r1, r0, #2
    it      cs
        rsbcs   r0, r0, #0x80000000
    lsls    r0, r0, #1

    //
    // Use the top 9 fractional bits as an index into the look up table.
    // Pull sine and cosine of the index.
    // Jump out if we're close enough to 0 to do a fully odd approximation.
    //
    ldr     r12, sincos_table_15
    ubfx    r1, r0, #(31 - 9), #10
    cbz     r1, cosindex0_15
    ldr     r2, [r12, r1, lsl #2]
    rsb     r1, r1, #512
    ldr     r3, [r12, r1, lsl #2]

    //
    // Put delta x in r1.
    // This is (x-index)*pi/2  in Q32
    // Consider replacing lsl/lsr combo with UBFX:
    // 1 cycle faster, but slightly less accurate delta x.
    //
    lsl     r1, r0, #(9 + 1)
    ldr     r12, piq30_15
    umull   r12, r1, r1, r12
    lsr     r1, r1, #(9 - 1)
    mov     r0, #0

    //
    // Calculates the taylor series expansion of sin(x)
    // Interval is 0:90 degrees.
    // Preconditions:
    // r0 = 0x00000000
    // r1 = remainder (x-index) in Q32 Radians
    // r2 = sin(index) in Q32
    // r3 = cos(index) in Q32
    // r12 is available as scratch space
    // ASPR contains sign flag as MI=flip sign.
    //
    // Calculate 2nd term of taylor series expansion.
    // This performs y = remainder/2*(sin(index)+y)
    // 5-7 cycles
    //
    add     r0, r2, r0
    umull   r12, r0, r0, r1
    lsr     r0, r0, #1

    //
    // Calculate 1st term of taylor series expansion.
    // This performs y = remainder/1*(cos(index)-y)
    // 4-6 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1

    //
    // Calculate 0th term of taylor series expansion.
    // This performs y = (sin(index)+y)
    //
    add     r0, r2, r0

    //
    // Compensate for sign flag in r5
    //
    lsr     r0, r0, #1
    it      cs
        rsbcs   r0, r0, #0
    asrs    r0, r0, #(31 - 15)
    adc     r0, r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // This branch handles the case very close to 0.
    // It uses the sin(x)=x approximation, but the constant is fudged down
    // a bit from pi to minimize the maximum error to +/-2 counts at Q30
    //
cosindex0_15
    ldr     r12, piq30_compensated_15
    umull   r12, r0, r0, r12
    lsr     r0, r0, #(30 - 15)
    it      cs
        rsbcs   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
sincos_table_15
    dcd     sincos_table
piq30_15
    dcd     0xc90fdaa2         // pi in Q30
piq30_compensated_15
    dcd     0xc90fcd37         // slightly less than pi in Q30
invpiq32_15
    dcd     0x517cc1b7         // 1/pi in Q32

//*****************************************************************************
//
// _IQ16cos
//
//*****************************************************************************
    section CODE__IQ16cos:CODE(2)
    thumb
    export  _IQ16cos
_IQ16cos
    //
    // Convert from radians to radians per unit by dividing by pi
    // This is done by multiplying by 1/pi in Q32
    //
    ldr     r1, invpiq32_16
    smull   r1, r0, r1, r0

    //
    // Put the input into Q31.
    // Since this is in Per Unit radians, we only care about the 1s digit
    // to determine sign of the result.  Higher bits are useless.
    // This is equivalent to sin(x) = sin(x+2*n) in per unit radians.
    //
    lsl     r0, r0, #(31 - 16)
    add     r0, r0, r1, lsr #(16 + 1)
    add     r0, r0, #0x40000000

    //
    // If the fractional portion is greater than 0.5, subtract it from 1.0
    // This is equivalent to sin(x) = sin(1-x) in per unit radians.
    // r0 becomes UQ32 representation of input constrained to 1st Quadrant PU:
    // [0,.5)
    //
    lsls    r1, r0, #2
    it      cs
        rsbcs   r0, r0, #0x80000000
    lsls    r0, r0, #1

    //
    // Use the top 9 fractional bits as an index into the look up table.
    // Pull sine and cosine of the index.
    // Jump out if we're close enough to 0 to do a fully odd approximation.
    //
    ldr     r12, sincos_table_16
    ubfx    r1, r0, #(31 - 9), #10
    cbz     r1, cosindex0_16
    ldr     r2, [r12, r1, lsl #2]
    rsb     r1, r1, #512
    ldr     r3, [r12, r1, lsl #2]

    //
    // Put delta x in r1.
    // This is (x-index)*pi/2  in Q32
    // Consider replacing lsl/lsr combo with UBFX:
    // 1 cycle faster, but slightly less accurate delta x.
    //
    lsl     r1, r0, #(9 + 1)
    ldr     r12, piq30_16
    umull   r12, r1, r1, r12
    lsr     r1, r1, #(9 - 1)
    mov     r0, #0

    //
    // Calculates the taylor series expansion of sin(x)
    // Interval is 0:90 degrees.
    // Preconditions:
    // r0 = 0x00000000
    // r1 = remainder (x-index) in Q32 Radians
    // r2 = sin(index) in Q32
    // r3 = cos(index) in Q32
    // r12 is available as scratch space
    // ASPR contains sign flag as MI=flip sign.
    //
    // Calculate 2nd term of taylor series expansion.
    // This performs y = remainder/2*(sin(index)+y)
    // 5-7 cycles
    //
    add     r0, r2, r0
    umull   r12, r0, r0, r1
    lsr     r0, r0, #1

    //
    // Calculate 1st term of taylor series expansion.
    // This performs y = remainder/1*(cos(index)-y)
    // 4-6 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1

    //
    // Calculate 0th term of taylor series expansion.
    // This performs y = (sin(index)+y)
    //
    add     r0, r2, r0

    //
    // Compensate for sign flag in r5
    //
    lsr     r0, r0, #1
    it      cs
        rsbcs   r0, r0, #0
    asrs    r0, r0, #(31 - 16)
    adc     r0, r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // This branch handles the case very close to 0.
    // It uses the sin(x)=x approximation, but the constant is fudged down
    // a bit from pi to minimize the maximum error to +/-2 counts at Q30
    //
cosindex0_16
    ldr     r12, piq30_compensated_16
    umull   r12, r0, r0, r12
    lsr     r0, r0, #(30 - 16)
    it      cs
        rsbcs   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
sincos_table_16
    dcd     sincos_table
piq30_16
    dcd     0xc90fdaa2         // pi in Q30
piq30_compensated_16
    dcd     0xc90fcd37         // slightly less than pi in Q30
invpiq32_16
    dcd     0x517cc1b7         // 1/pi in Q32

//*****************************************************************************
//
// _IQ17cos
//
//*****************************************************************************
    section CODE__IQ17cos:CODE(2)
    thumb
    export  _IQ17cos
_IQ17cos
    //
    // Convert from radians to radians per unit by dividing by pi
    // This is done by multiplying by 1/pi in Q32
    //
    ldr     r1, invpiq32_17
    smull   r1, r0, r1, r0

    //
    // Put the input into Q31.
    // Since this is in Per Unit radians, we only care about the 1s digit
    // to determine sign of the result.  Higher bits are useless.
    // This is equivalent to sin(x) = sin(x+2*n) in per unit radians.
    //
    lsl     r0, r0, #(31 - 17)
    add     r0, r0, r1, lsr #(17 + 1)
    add     r0, r0, #0x40000000

    //
    // If the fractional portion is greater than 0.5, subtract it from 1.0
    // This is equivalent to sin(x) = sin(1-x) in per unit radians.
    // r0 becomes UQ32 representation of input constrained to 1st Quadrant PU:
    // [0,.5)
    //
    lsls    r1, r0, #2
    it      cs
        rsbcs   r0, r0, #0x80000000
    lsls    r0, r0, #1

    //
    // Use the top 9 fractional bits as an index into the look up table.
    // Pull sine and cosine of the index.
    // Jump out if we're close enough to 0 to do a fully odd approximation.
    //
    ldr     r12, sincos_table_17
    ubfx    r1, r0, #(31 - 9), #10
    cbz     r1, cosindex0_17
    ldr     r2, [r12, r1, lsl #2]
    rsb     r1, r1, #512
    ldr     r3, [r12, r1, lsl #2]

    //
    // Put delta x in r1.
    // This is (x-index)*pi/2  in Q32
    // Consider replacing lsl/lsr combo with UBFX:
    // 1 cycle faster, but slightly less accurate delta x.
    //
    lsl     r1, r0, #(9 + 1)
    ldr     r12, piq30_17
    umull   r12, r1, r1, r12
    lsr     r1, r1, #(9 - 1)
    mov     r0, #0

    //
    // Calculates the taylor series expansion of sin(x)
    // Interval is 0:90 degrees.
    // Preconditions:
    // r0 = 0x00000000
    // r1 = remainder (x-index) in Q32 Radians
    // r2 = sin(index) in Q32
    // r3 = cos(index) in Q32
    // r12 is available as scratch space
    // ASPR contains sign flag as MI=flip sign.
    //
    // Calculate 2nd term of taylor series expansion.
    // This performs y = remainder/2*(sin(index)+y)
    // 5-7 cycles
    //
    add     r0, r2, r0
    umull   r12, r0, r0, r1
    lsr     r0, r0, #1

    //
    // Calculate 1st term of taylor series expansion.
    // This performs y = remainder/1*(cos(index)-y)
    // 4-6 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1

    //
    // Calculate 0th term of taylor series expansion.
    // This performs y = (sin(index)+y)
    //
    add     r0, r2, r0

    //
    // Compensate for sign flag in r5
    //
    lsr     r0, r0, #1
    it      cs
        rsbcs   r0, r0, #0
    asrs    r0, r0, #(31 - 17)
    adc     r0, r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // This branch handles the case very close to 0.
    // It uses the sin(x)=x approximation, but the constant is fudged down
    // a bit from pi to minimize the maximum error to +/-2 counts at Q30
    //
cosindex0_17
    ldr     r12, piq30_compensated_17
    umull   r12, r0, r0, r12
    lsr     r0, r0, #(30 - 17)
    it      cs
        rsbcs   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
sincos_table_17
    dcd     sincos_table
piq30_17
    dcd     0xc90fdaa2         // pi in Q30
piq30_compensated_17
    dcd     0xc90fcd37         // slightly less than pi in Q30
invpiq32_17
    dcd     0x517cc1b7         // 1/pi in Q32

//*****************************************************************************
//
// _IQ18cos
//
//*****************************************************************************
    section CODE__IQ18cos:CODE(2)
    thumb
    export  _IQ18cos
_IQ18cos
    //
    // Convert from radians to radians per unit by dividing by pi
    // This is done by multiplying by 1/pi in Q32
    //
    ldr     r1, invpiq32_18
    smull   r1, r0, r1, r0

    //
    // Put the input into Q31.
    // Since this is in Per Unit radians, we only care about the 1s digit
    // to determine sign of the result.  Higher bits are useless.
    // This is equivalent to sin(x) = sin(x+2*n) in per unit radians.
    //
    lsl     r0, r0, #(31 - 18)
    add     r0, r0, r1, lsr #(18 + 1)
    add     r0, r0, #0x40000000

    //
    // If the fractional portion is greater than 0.5, subtract it from 1.0
    // This is equivalent to sin(x) = sin(1-x) in per unit radians.
    // r0 becomes UQ32 representation of input constrained to 1st Quadrant PU:
    // [0,.5)
    //
    lsls    r1, r0, #2
    it      cs
        rsbcs   r0, r0, #0x80000000
    lsls    r0, r0, #1

    //
    // Use the top 9 fractional bits as an index into the look up table.
    // Pull sine and cosine of the index.
    // Jump out if we're close enough to 0 to do a fully odd approximation.
    //
    ldr     r12, sincos_table_18
    ubfx    r1, r0, #(31 - 9), #10
    cbz     r1, cosindex0_18
    ldr     r2, [r12, r1, lsl #2]
    rsb     r1, r1, #512
    ldr     r3, [r12, r1, lsl #2]

    //
    // Put delta x in r1.
    // This is (x-index)*pi/2  in Q32
    // Consider replacing lsl/lsr combo with UBFX:
    // 1 cycle faster, but slightly less accurate delta x.
    //
    lsl     r1, r0, #(9 + 1)
    ldr     r12, piq30_18
    umull   r12, r1, r1, r12
    lsr     r1, r1, #(9 - 1)
    mov     r0, #0

    //
    // Calculates the taylor series expansion of sin(x)
    // Interval is 0:90 degrees.
    // Preconditions:
    // r0 = 0x00000000
    // r1 = remainder (x-index) in Q32 Radians
    // r2 = sin(index) in Q32
    // r3 = cos(index) in Q32
    // r12 is available as scratch space
    // ASPR contains sign flag as MI=flip sign.
    //
    // Calculate 2nd term of taylor series expansion.
    // This performs y = remainder/2*(sin(index)+y)
    // 5-7 cycles
    //
    add     r0, r2, r0
    umull   r12, r0, r0, r1
    lsr     r0, r0, #1

    //
    // Calculate 1st term of taylor series expansion.
    // This performs y = remainder/1*(cos(index)-y)
    // 4-6 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1

    //
    // Calculate 0th term of taylor series expansion.
    // This performs y = (sin(index)+y)
    //
    add     r0, r2, r0

    //
    // Compensate for sign flag in r5
    //
    lsr     r0, r0, #1
    it      cs
        rsbcs   r0, r0, #0
    asrs    r0, r0, #(31 - 18)
    adc     r0, r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // This branch handles the case very close to 0.
    // It uses the sin(x)=x approximation, but the constant is fudged down
    // a bit from pi to minimize the maximum error to +/-2 counts at Q30
    //
cosindex0_18
    ldr     r12, piq30_compensated_18
    umull   r12, r0, r0, r12
    lsr     r0, r0, #(30 - 18)
    it      cs
        rsbcs   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
sincos_table_18
    dcd     sincos_table
piq30_18
    dcd     0xc90fdaa2         // pi in Q30
piq30_compensated_18
    dcd     0xc90fcd37         // slightly less than pi in Q30
invpiq32_18
    dcd     0x517cc1b7         // 1/pi in Q32

//*****************************************************************************
//
// _IQ19cos
//
//*****************************************************************************
    section CODE__IQ19cos:CODE(2)
    thumb
    export  _IQ19cos
_IQ19cos
    //
    // Convert from radians to radians per unit by dividing by pi
    // This is done by multiplying by 1/pi in Q32
    //
    ldr     r1, invpiq32_19
    smull   r1, r0, r1, r0

    //
    // Put the input into Q31.
    // Since this is in Per Unit radians, we only care about the 1s digit
    // to determine sign of the result.  Higher bits are useless.
    // This is equivalent to sin(x) = sin(x+2*n) in per unit radians.
    //
    lsl     r0, r0, #(31 - 19)
    add     r0, r0, r1, lsr #(19 + 1)
    add     r0, r0, #0x40000000

    //
    // If the fractional portion is greater than 0.5, subtract it from 1.0
    // This is equivalent to sin(x) = sin(1-x) in per unit radians.
    // r0 becomes UQ32 representation of input constrained to 1st Quadrant PU:
    // [0,.5)
    //
    lsls    r1, r0, #2
    it      cs
        rsbcs   r0, r0, #0x80000000
    lsls    r0, r0, #1

    //
    // Use the top 9 fractional bits as an index into the look up table.
    // Pull sine and cosine of the index.
    // Jump out if we're close enough to 0 to do a fully odd approximation.
    //
    ldr     r12, sincos_table_19
    ubfx    r1, r0, #(31 - 9), #10
    cbz     r1, cosindex0_19
    ldr     r2, [r12, r1, lsl #2]
    rsb     r1, r1, #512
    ldr     r3, [r12, r1, lsl #2]

    //
    // Put delta x in r1.
    // This is (x-index)*pi/2  in Q32
    // Consider replacing lsl/lsr combo with UBFX:
    // 1 cycle faster, but slightly less accurate delta x.
    //
    lsl     r1, r0, #(9 + 1)
    ldr     r12, piq30_19
    umull   r12, r1, r1, r12
    lsr     r1, r1, #(9 - 1)
    mov     r0, #0

    //
    // Calculates the taylor series expansion of sin(x)
    // Interval is 0:90 degrees.
    // Preconditions:
    // r0 = 0x00000000
    // r1 = remainder (x-index) in Q32 Radians
    // r2 = sin(index) in Q32
    // r3 = cos(index) in Q32
    // r12 is available as scratch space
    // ASPR contains sign flag as MI=flip sign.
    //
    // Calculate 2nd term of taylor series expansion.
    // This performs y = remainder/2*(sin(index)+y)
    // 5-7 cycles
    //
    add     r0, r2, r0
    umull   r12, r0, r0, r1
    lsr     r0, r0, #1

    //
    // Calculate 1st term of taylor series expansion.
    // This performs y = remainder/1*(cos(index)-y)
    // 4-6 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1

    //
    // Calculate 0th term of taylor series expansion.
    // This performs y = (sin(index)+y)
    //
    add     r0, r2, r0

    //
    // Compensate for sign flag in r5
    //
    lsr     r0, r0, #1
    it      cs
        rsbcs   r0, r0, #0
    asrs    r0, r0, #(31 - 19)
    adc     r0, r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // This branch handles the case very close to 0.
    // It uses the sin(x)=x approximation, but the constant is fudged down
    // a bit from pi to minimize the maximum error to +/-2 counts at Q30
    //
cosindex0_19
    ldr     r12, piq30_compensated_19
    umull   r12, r0, r0, r12
    lsr     r0, r0, #(30 - 19)
    it      cs
        rsbcs   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
sincos_table_19
    dcd     sincos_table
piq30_19
    dcd     0xc90fdaa2         // pi in Q30
piq30_compensated_19
    dcd     0xc90fcd37         // slightly less than pi in Q30
invpiq32_19
    dcd     0x517cc1b7         // 1/pi in Q32

//*****************************************************************************
//
// _IQ20cos
//
//*****************************************************************************
    section CODE__IQ20cos:CODE(2)
    thumb
    export  _IQ20cos
_IQ20cos
    //
    // Convert from radians to radians per unit by dividing by pi
    // This is done by multiplying by 1/pi in Q32
    //
    ldr     r1, invpiq32_20
    smull   r1, r0, r1, r0

    //
    // Put the input into Q31.
    // Since this is in Per Unit radians, we only care about the 1s digit
    // to determine sign of the result.  Higher bits are useless.
    // This is equivalent to sin(x) = sin(x+2*n) in per unit radians.
    //
    lsl     r0, r0, #(31 - 20)
    add     r0, r0, r1, lsr #(20 + 1)
    add     r0, r0, #0x40000000

    //
    // If the fractional portion is greater than 0.5, subtract it from 1.0
    // This is equivalent to sin(x) = sin(1-x) in per unit radians.
    // r0 becomes UQ32 representation of input constrained to 1st Quadrant PU:
    // [0,.5)
    //
    lsls    r1, r0, #2
    it      cs
        rsbcs   r0, r0, #0x80000000
    lsls    r0, r0, #1

    //
    // Use the top 9 fractional bits as an index into the look up table.
    // Pull sine and cosine of the index.
    // Jump out if we're close enough to 0 to do a fully odd approximation.
    //
    ldr     r12, sincos_table_20
    ubfx    r1, r0, #(31 - 9), #10
    cbz     r1, cosindex0_20
    ldr     r2, [r12, r1, lsl #2]
    rsb     r1, r1, #512
    ldr     r3, [r12, r1, lsl #2]

    //
    // Put delta x in r1.
    // This is (x-index)*pi/2  in Q32
    // Consider replacing lsl/lsr combo with UBFX:
    // 1 cycle faster, but slightly less accurate delta x.
    //
    lsl     r1, r0, #(9 + 1)
    ldr     r12, piq30_20
    umull   r12, r1, r1, r12
    lsr     r1, r1, #(9 - 1)
    mov     r0, #0

    //
    // Calculates the taylor series expansion of sin(x)
    // Interval is 0:90 degrees.
    // Preconditions:
    // r0 = 0x00000000
    // r1 = remainder (x-index) in Q32 Radians
    // r2 = sin(index) in Q32
    // r3 = cos(index) in Q32
    // r12 is available as scratch space
    // ASPR contains sign flag as MI=flip sign.
    //
    // Calculate 2nd term of taylor series expansion.
    // This performs y = remainder/2*(sin(index)+y)
    // 5-7 cycles
    //
    add     r0, r2, r0
    umull   r12, r0, r0, r1
    lsr     r0, r0, #1

    //
    // Calculate 1st term of taylor series expansion.
    // This performs y = remainder/1*(cos(index)-y)
    // 4-6 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1

    //
    // Calculate 0th term of taylor series expansion.
    // This performs y = (sin(index)+y)
    //
    add     r0, r2, r0

    //
    // Compensate for sign flag in r5
    //
    lsr     r0, r0, #1
    it      cs
        rsbcs   r0, r0, #0
    asrs    r0, r0, #(31 - 20)
    adc     r0, r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // This branch handles the case very close to 0.
    // It uses the sin(x)=x approximation, but the constant is fudged down
    // a bit from pi to minimize the maximum error to +/-2 counts at Q30
    //
cosindex0_20
    ldr     r12, piq30_compensated_20
    umull   r12, r0, r0, r12
    lsr     r0, r0, #(30 - 20)
    it      cs
        rsbcs   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
sincos_table_20
    dcd     sincos_table
piq30_20
    dcd     0xc90fdaa2         // pi in Q30
piq30_compensated_20
    dcd     0xc90fcd37         // slightly less than pi in Q30
invpiq32_20
    dcd     0x517cc1b7         // 1/pi in Q32

//*****************************************************************************
//
// _IQ21cos
//
//*****************************************************************************
    section CODE__IQ21cos:CODE(2)
    thumb
    export  _IQ21cos
_IQ21cos
    //
    // Convert from radians to radians per unit by dividing by pi
    // This is done by multiplying by 1/pi in Q32
    //
    ldr     r1, invpiq32_21
    smull   r1, r0, r1, r0

    //
    // Put the input into Q31.
    // Since this is in Per Unit radians, we only care about the 1s digit
    // to determine sign of the result.  Higher bits are useless.
    // This is equivalent to sin(x) = sin(x+2*n) in per unit radians.
    //
    lsl     r0, r0, #(31 - 21)
    add     r0, r0, r1, lsr #(21 + 1)
    add     r0, r0, #0x40000000

    //
    // If the fractional portion is greater than 0.5, subtract it from 1.0
    // This is equivalent to sin(x) = sin(1-x) in per unit radians.
    // r0 becomes UQ32 representation of input constrained to 1st Quadrant PU:
    // [0,.5)
    //
    lsls    r1, r0, #2
    it      cs
        rsbcs   r0, r0, #0x80000000
    lsls    r0, r0, #1

    //
    // Use the top 9 fractional bits as an index into the look up table.
    // Pull sine and cosine of the index.
    // Jump out if we're close enough to 0 to do a fully odd approximation.
    //
    ldr     r12, sincos_table_21
    ubfx    r1, r0, #(31 - 9), #10
    cbz     r1, cosindex0_21
    ldr     r2, [r12, r1, lsl #2]
    rsb     r1, r1, #512
    ldr     r3, [r12, r1, lsl #2]

    //
    // Put delta x in r1.
    // This is (x-index)*pi/2  in Q32
    // Consider replacing lsl/lsr combo with UBFX:
    // 1 cycle faster, but slightly less accurate delta x.
    //
    lsl     r1, r0, #(9 + 1)
    ldr     r12, piq30_21
    umull   r12, r1, r1, r12
    lsr     r1, r1, #(9 - 1)
    mov     r0, #0

    //
    // Calculates the taylor series expansion of sin(x)
    // Interval is 0:90 degrees.
    // Preconditions:
    // r0 = 0x00000000
    // r1 = remainder (x-index) in Q32 Radians
    // r2 = sin(index) in Q32
    // r3 = cos(index) in Q32
    // r12 is available as scratch space
    // ASPR contains sign flag as MI=flip sign.
    //
    // Calculate 5th term of taylor series expansion.
    // This performs y = remainder/5*(cos(index)-y)
    // 8-12 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1
    mov     r12, #0x33333333    // 2**32/5
    umull   r12, r0, r12, r0

    //
    // Calculate 4th term of taylor series expansion.
    // This performs y = remainder/4*(sin(index)+y)
    // 5-7 cycles
    //
    add     r0, r2, r0
    umull   r12, r0, r0, r1
    lsr     r0, r0, #2

    //
    // Calculate 3rd term of taylor series expansion.
    // This performs y = remainder/3*(cos(index)-y)
    // 9-13 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1
    mov     r12, #0x55555555    // 2**32/3
    umull   r12, r0, r12, r0

    //
    // Calculate 2nd term of taylor series expansion.
    // This performs y = remainder/2*(sin(index)+y)
    // 5-7 cycles
    //
    add     r0, r2, r0
    umull   r12, r0, r0, r1
    lsr     r0, r0, #1

    //
    // Calculate 1st term of taylor series expansion.
    // This performs y = remainder/1*(cos(index)-y)
    // 4-6 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1

    //
    // Calculate 0th term of taylor series expansion.
    // This performs y = (sin(index)+y)
    //
    add     r0, r2, r0

    //
    // Compensate for sign flag in r5
    //
    lsr     r0, r0, #1
    it      cs
        rsbcs   r0, r0, #0
    asrs    r0, r0, #(31 - 21)
    adc     r0, r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // This branch handles the case very close to 0.
    // It uses the sin(x)=x approximation, but the constant is fudged down
    // a bit from pi to minimize the maximum error to +/-2 counts at Q30
    //
cosindex0_21
    ldr     r12, piq30_compensated_21
    umull   r12, r0, r0, r12
    lsr     r0, r0, #(30 - 21)
    it      cs
        rsbcs   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
sincos_table_21
    dcd     sincos_table
piq30_21
    dcd     0xc90fdaa2         // pi in Q30
piq30_compensated_21
    dcd     0xc90fcd37         // slightly less than pi in Q30
invpiq32_21
    dcd     0x517cc1b7         // 1/pi in Q32

//*****************************************************************************
//
// _IQ22cos
//
//*****************************************************************************
    section CODE__IQ22cos:CODE(2)
    thumb
    export  _IQ22cos
_IQ22cos
    //
    // Convert from radians to radians per unit by dividing by pi
    // This is done by multiplying by 1/pi in Q32
    //
    ldr     r1, invpiq32_22
    smull   r1, r0, r1, r0

    //
    // Put the input into Q31.
    // Since this is in Per Unit radians, we only care about the 1s digit
    // to determine sign of the result.  Higher bits are useless.
    // This is equivalent to sin(x) = sin(x+2*n) in per unit radians.
    //
    lsl     r0, r0, #(31 - 22)
    add     r0, r0, r1, lsr #(22 + 1)
    add     r0, r0, #0x40000000

    //
    // If the fractional portion is greater than 0.5, subtract it from 1.0
    // This is equivalent to sin(x) = sin(1-x) in per unit radians.
    // r0 becomes UQ32 representation of input constrained to 1st Quadrant PU:
    // [0,.5)
    //
    lsls    r1, r0, #2
    it      cs
        rsbcs   r0, r0, #0x80000000
    lsls    r0, r0, #1

    //
    // Use the top 9 fractional bits as an index into the look up table.
    // Pull sine and cosine of the index.
    // Jump out if we're close enough to 0 to do a fully odd approximation.
    //
    ldr     r12, sincos_table_22
    ubfx    r1, r0, #(31 - 9), #10
    cbz     r1, cosindex0_22
    ldr     r2, [r12, r1, lsl #2]
    rsb     r1, r1, #512
    ldr     r3, [r12, r1, lsl #2]

    //
    // Put delta x in r1.
    // This is (x-index)*pi/2  in Q32
    // Consider replacing lsl/lsr combo with UBFX:
    // 1 cycle faster, but slightly less accurate delta x.
    //
    lsl     r1, r0, #(9 + 1)
    ldr     r12, piq30_22
    umull   r12, r1, r1, r12
    lsr     r1, r1, #(9 - 1)
    mov     r0, #0

    //
    // Calculates the taylor series expansion of sin(x)
    // Interval is 0:90 degrees.
    // Preconditions:
    // r0 = 0x00000000
    // r1 = remainder (x-index) in Q32 Radians
    // r2 = sin(index) in Q32
    // r3 = cos(index) in Q32
    // r12 is available as scratch space
    // ASPR contains sign flag as MI=flip sign.
    //
    // Calculate 5th term of taylor series expansion.
    // This performs y = remainder/5*(cos(index)-y)
    // 8-12 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1
    mov     r12, #0x33333333    // 2**32/5
    umull   r12, r0, r12, r0

    //
    // Calculate 4th term of taylor series expansion.
    // This performs y = remainder/4*(sin(index)+y)
    // 5-7 cycles
    //
    add     r0, r2, r0
    umull   r12, r0, r0, r1
    lsr     r0, r0, #2

    //
    // Calculate 3rd term of taylor series expansion.
    // This performs y = remainder/3*(cos(index)-y)
    // 9-13 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1
    mov     r12, #0x55555555    // 2**32/3
    umull   r12, r0, r12, r0

    //
    // Calculate 2nd term of taylor series expansion.
    // This performs y = remainder/2*(sin(index)+y)
    // 5-7 cycles
    //
    add     r0, r2, r0
    umull   r12, r0, r0, r1
    lsr     r0, r0, #1

    //
    // Calculate 1st term of taylor series expansion.
    // This performs y = remainder/1*(cos(index)-y)
    // 4-6 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1

    //
    // Calculate 0th term of taylor series expansion.
    // This performs y = (sin(index)+y)
    //
    add     r0, r2, r0

    //
    // Compensate for sign flag in r5
    //
    lsr     r0, r0, #1
    it      cs
        rsbcs   r0, r0, #0
    asrs    r0, r0, #(31 - 22)
    adc     r0, r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // This branch handles the case very close to 0.
    // It uses the sin(x)=x approximation, but the constant is fudged down
    // a bit from pi to minimize the maximum error to +/-2 counts at Q30
    //
cosindex0_22
    ldr     r12, piq30_compensated_22
    umull   r12, r0, r0, r12
    lsr     r0, r0, #(30 - 22)
    it      cs
        rsbcs   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
sincos_table_22
    dcd     sincos_table
piq30_22
    dcd     0xc90fdaa2         // pi in Q30
piq30_compensated_22
    dcd     0xc90fcd37         // slightly less than pi in Q30
invpiq32_22
    dcd     0x517cc1b7         // 1/pi in Q32

//*****************************************************************************
//
// _IQ23cos
//
//*****************************************************************************
    section CODE__IQ23cos:CODE(2)
    thumb
    export  _IQ23cos
_IQ23cos
    //
    // Convert from radians to radians per unit by dividing by pi
    // This is done by multiplying by 1/pi in Q32
    //
    ldr     r1, invpiq32_23
    smull   r1, r0, r1, r0

    //
    // Put the input into Q31.
    // Since this is in Per Unit radians, we only care about the 1s digit
    // to determine sign of the result.  Higher bits are useless.
    // This is equivalent to sin(x) = sin(x+2*n) in per unit radians.
    //
    lsl     r0, r0, #(31 - 23)
    add     r0, r0, r1, lsr #(23 + 1)
    add     r0, r0, #0x40000000

    //
    // If the fractional portion is greater than 0.5, subtract it from 1.0
    // This is equivalent to sin(x) = sin(1-x) in per unit radians.
    // r0 becomes UQ32 representation of input constrained to 1st Quadrant PU:
    // [0,.5)
    //
    lsls    r1, r0, #2
    it      cs
        rsbcs   r0, r0, #0x80000000
    lsls    r0, r0, #1

    //
    // Use the top 9 fractional bits as an index into the look up table.
    // Pull sine and cosine of the index.
    // Jump out if we're close enough to 0 to do a fully odd approximation.
    //
    ldr     r12, sincos_table_23
    ubfx    r1, r0, #(31 - 9), #10
    cbz     r1, cosindex0_23
    ldr     r2, [r12, r1, lsl #2]
    rsb     r1, r1, #512
    ldr     r3, [r12, r1, lsl #2]

    //
    // Put delta x in r1.
    // This is (x-index)*pi/2  in Q32
    // Consider replacing lsl/lsr combo with UBFX:
    // 1 cycle faster, but slightly less accurate delta x.
    //
    lsl     r1, r0, #(9 + 1)
    ldr     r12, piq30_23
    umull   r12, r1, r1, r12
    lsr     r1, r1, #(9 - 1)
    mov     r0, #0

    //
    // Calculates the taylor series expansion of sin(x)
    // Interval is 0:90 degrees.
    // Preconditions:
    // r0 = 0x00000000
    // r1 = remainder (x-index) in Q32 Radians
    // r2 = sin(index) in Q32
    // r3 = cos(index) in Q32
    // r12 is available as scratch space
    // ASPR contains sign flag as MI=flip sign.
    //
    // Calculate 5th term of taylor series expansion.
    // This performs y = remainder/5*(cos(index)-y)
    // 8-12 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1
    mov     r12, #0x33333333    // 2**32/5
    umull   r12, r0, r12, r0

    //
    // Calculate 4th term of taylor series expansion.
    // This performs y = remainder/4*(sin(index)+y)
    // 5-7 cycles
    //
    add     r0, r2, r0
    umull   r12, r0, r0, r1
    lsr     r0, r0, #2

    //
    // Calculate 3rd term of taylor series expansion.
    // This performs y = remainder/3*(cos(index)-y)
    // 9-13 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1
    mov     r12, #0x55555555    // 2**32/3
    umull   r12, r0, r12, r0

    //
    // Calculate 2nd term of taylor series expansion.
    // This performs y = remainder/2*(sin(index)+y)
    // 5-7 cycles
    //
    add     r0, r2, r0
    umull   r12, r0, r0, r1
    lsr     r0, r0, #1

    //
    // Calculate 1st term of taylor series expansion.
    // This performs y = remainder/1*(cos(index)-y)
    // 4-6 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1

    //
    // Calculate 0th term of taylor series expansion.
    // This performs y = (sin(index)+y)
    //
    add     r0, r2, r0

    //
    // Compensate for sign flag in r5
    //
    lsr     r0, r0, #1
    it      cs
        rsbcs   r0, r0, #0
    asrs    r0, r0, #(31 - 23)
    adc     r0, r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // This branch handles the case very close to 0.
    // It uses the sin(x)=x approximation, but the constant is fudged down
    // a bit from pi to minimize the maximum error to +/-2 counts at Q30
    //
cosindex0_23
    ldr     r12, piq30_compensated_23
    umull   r12, r0, r0, r12
    lsr     r0, r0, #(30 - 23)
    it      cs
        rsbcs   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
sincos_table_23
    dcd     sincos_table
piq30_23
    dcd     0xc90fdaa2         // pi in Q30
piq30_compensated_23
    dcd     0xc90fcd37         // slightly less than pi in Q30
invpiq32_23
    dcd     0x517cc1b7         // 1/pi in Q32

//*****************************************************************************
//
// _IQ24cos
//
//*****************************************************************************
    section CODE__IQ24cos:CODE(2)
    thumb
    export  _IQ24cos
_IQ24cos
    //
    // Convert from radians to radians per unit by dividing by pi
    // This is done by multiplying by 1/pi in Q32
    //
    ldr     r1, invpiq32_24
    smull   r1, r0, r1, r0

    //
    // Put the input into Q31.
    // Since this is in Per Unit radians, we only care about the 1s digit
    // to determine sign of the result.  Higher bits are useless.
    // This is equivalent to sin(x) = sin(x+2*n) in per unit radians.
    //
    lsl     r0, r0, #(31 - 24)
    add     r0, r0, r1, lsr #(24 + 1)
    add     r0, r0, #0x40000000

    //
    // If the fractional portion is greater than 0.5, subtract it from 1.0
    // This is equivalent to sin(x) = sin(1-x) in per unit radians.
    // r0 becomes UQ32 representation of input constrained to 1st Quadrant PU:
    // [0,.5)
    //
    lsls    r1, r0, #2
    it      cs
        rsbcs   r0, r0, #0x80000000
    lsls    r0, r0, #1

    //
    // Use the top 9 fractional bits as an index into the look up table.
    // Pull sine and cosine of the index.
    // Jump out if we're close enough to 0 to do a fully odd approximation.
    //
    ldr     r12, sincos_table_24
    ubfx    r1, r0, #(31 - 9), #10
    cbz     r1, cosindex0_24
    ldr     r2, [r12, r1, lsl #2]
    rsb     r1, r1, #512
    ldr     r3, [r12, r1, lsl #2]

    //
    // Put delta x in r1.
    // This is (x-index)*pi/2  in Q32
    // Consider replacing lsl/lsr combo with UBFX:
    // 1 cycle faster, but slightly less accurate delta x.
    //
    lsl     r1, r0, #(9 + 1)
    ldr     r12, piq30_24
    umull   r12, r1, r1, r12
    lsr     r1, r1, #(9 - 1)
    mov     r0, #0

    //
    // Calculates the taylor series expansion of sin(x)
    // Interval is 0:90 degrees.
    // Preconditions:
    // r0 = 0x00000000
    // r1 = remainder (x-index) in Q32 Radians
    // r2 = sin(index) in Q32
    // r3 = cos(index) in Q32
    // r12 is available as scratch space
    // ASPR contains sign flag as MI=flip sign.
    //
    // Calculate 5th term of taylor series expansion.
    // This performs y = remainder/5*(cos(index)-y)
    // 8-12 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1
    mov     r12, #0x33333333    // 2**32/5
    umull   r12, r0, r12, r0

    //
    // Calculate 4th term of taylor series expansion.
    // This performs y = remainder/4*(sin(index)+y)
    // 5-7 cycles
    //
    add     r0, r2, r0
    umull   r12, r0, r0, r1
    lsr     r0, r0, #2

    //
    // Calculate 3rd term of taylor series expansion.
    // This performs y = remainder/3*(cos(index)-y)
    // 9-13 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1
    mov     r12, #0x55555555    // 2**32/3
    umull   r12, r0, r12, r0

    //
    // Calculate 2nd term of taylor series expansion.
    // This performs y = remainder/2*(sin(index)+y)
    // 5-7 cycles
    //
    add     r0, r2, r0
    umull   r12, r0, r0, r1
    lsr     r0, r0, #1

    //
    // Calculate 1st term of taylor series expansion.
    // This performs y = remainder/1*(cos(index)-y)
    // 4-6 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1

    //
    // Calculate 0th term of taylor series expansion.
    // This performs y = (sin(index)+y)
    //
    add     r0, r2, r0

    //
    // Compensate for sign flag in r5
    //
    lsr     r0, r0, #1
    it      cs
        rsbcs   r0, r0, #0
    asrs    r0, r0, #(31 - 24)
    adc     r0, r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // This branch handles the case very close to 0.
    // It uses the sin(x)=x approximation, but the constant is fudged down
    // a bit from pi to minimize the maximum error to +/-2 counts at Q30
    //
cosindex0_24
    ldr     r12, piq30_compensated_24
    umull   r12, r0, r0, r12
    lsr     r0, r0, #(30 - 24)
    it      cs
        rsbcs   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
sincos_table_24
    dcd     sincos_table
piq30_24
    dcd     0xc90fdaa2         // pi in Q30
piq30_compensated_24
    dcd     0xc90fcd37         // slightly less than pi in Q30
invpiq32_24
    dcd     0x517cc1b7         // 1/pi in Q32

//*****************************************************************************
//
// _IQ25cos
//
//*****************************************************************************
    section CODE__IQ25cos:CODE(2)
    thumb
    export  _IQ25cos
_IQ25cos
    //
    // Convert from radians to radians per unit by dividing by pi
    // This is done by multiplying by 1/pi in Q32
    //
    ldr     r1, invpiq32_25
    smull   r1, r0, r1, r0

    //
    // Put the input into Q31.
    // Since this is in Per Unit radians, we only care about the 1s digit
    // to determine sign of the result.  Higher bits are useless.
    // This is equivalent to sin(x) = sin(x+2*n) in per unit radians.
    //
    lsl     r0, r0, #(31 - 25)
    add     r0, r0, r1, lsr #(25 + 1)
    add     r0, r0, #0x40000000

    //
    // If the fractional portion is greater than 0.5, subtract it from 1.0
    // This is equivalent to sin(x) = sin(1-x) in per unit radians.
    // r0 becomes UQ32 representation of input constrained to 1st Quadrant PU:
    // [0,.5)
    //
    lsls    r1, r0, #2
    it      cs
        rsbcs   r0, r0, #0x80000000
    lsls    r0, r0, #1

    //
    // Use the top 9 fractional bits as an index into the look up table.
    // Pull sine and cosine of the index.
    // Jump out if we're close enough to 0 to do a fully odd approximation.
    //
    ldr     r12, sincos_table_25
    ubfx    r1, r0, #(31 - 9), #10
    cbz     r1, cosindex0_25
    ldr     r2, [r12, r1, lsl #2]
    rsb     r1, r1, #512
    ldr     r3, [r12, r1, lsl #2]

    //
    // Put delta x in r1.
    // This is (x-index)*pi/2  in Q32
    // Consider replacing lsl/lsr combo with UBFX:
    // 1 cycle faster, but slightly less accurate delta x.
    //
    lsl     r1, r0, #(9 + 1)
    ldr     r12, piq30_25
    umull   r12, r1, r1, r12
    lsr     r1, r1, #(9 - 1)
    mov     r0, #0

    //
    // Calculates the taylor series expansion of sin(x)
    // Interval is 0:90 degrees.
    // Preconditions:
    // r0 = 0x00000000
    // r1 = remainder (x-index) in Q32 Radians
    // r2 = sin(index) in Q32
    // r3 = cos(index) in Q32
    // r12 is available as scratch space
    // ASPR contains sign flag as MI=flip sign.
    //
    // Calculate 5th term of taylor series expansion.
    // This performs y = remainder/5*(cos(index)-y)
    // 8-12 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1
    mov     r12, #0x33333333    // 2**32/5
    umull   r12, r0, r12, r0

    //
    // Calculate 4th term of taylor series expansion.
    // This performs y = remainder/4*(sin(index)+y)
    // 5-7 cycles
    //
    add     r0, r2, r0
    umull   r12, r0, r0, r1
    lsr     r0, r0, #2

    //
    // Calculate 3rd term of taylor series expansion.
    // This performs y = remainder/3*(cos(index)-y)
    // 9-13 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1
    mov     r12, #0x55555555    // 2**32/3
    umull   r12, r0, r12, r0

    //
    // Calculate 2nd term of taylor series expansion.
    // This performs y = remainder/2*(sin(index)+y)
    // 5-7 cycles
    //
    add     r0, r2, r0
    umull   r12, r0, r0, r1
    lsr     r0, r0, #1

    //
    // Calculate 1st term of taylor series expansion.
    // This performs y = remainder/1*(cos(index)-y)
    // 4-6 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1

    //
    // Calculate 0th term of taylor series expansion.
    // This performs y = (sin(index)+y)
    //
    add     r0, r2, r0

    //
    // Compensate for sign flag in r5
    //
    lsr     r0, r0, #1
    it      cs
        rsbcs   r0, r0, #0
    asrs    r0, r0, #(31 - 25)
    adc     r0, r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // This branch handles the case very close to 0.
    // It uses the sin(x)=x approximation, but the constant is fudged down
    // a bit from pi to minimize the maximum error to +/-2 counts at Q30
    //
cosindex0_25
    ldr     r12, piq30_compensated_25
    umull   r12, r0, r0, r12
    lsr     r0, r0, #(30 - 25)
    it      cs
        rsbcs   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
sincos_table_25
    dcd     sincos_table
piq30_25
    dcd     0xc90fdaa2         // pi in Q30
piq30_compensated_25
    dcd     0xc90fcd37         // slightly less than pi in Q30
invpiq32_25
    dcd     0x517cc1b7         // 1/pi in Q32

//*****************************************************************************
//
// _IQ26cos
//
//*****************************************************************************
    section CODE__IQ26cos:CODE(2)
    thumb
    export  _IQ26cos
_IQ26cos
    //
    // Convert from radians to radians per unit by dividing by pi
    // This is done by multiplying by 1/pi in Q32
    //
    ldr     r1, invpiq32_26
    smull   r1, r0, r1, r0

    //
    // Put the input into Q31.
    // Since this is in Per Unit radians, we only care about the 1s digit
    // to determine sign of the result.  Higher bits are useless.
    // This is equivalent to sin(x) = sin(x+2*n) in per unit radians.
    //
    lsl     r0, r0, #(31 - 26)
    add     r0, r0, r1, lsr #(26 + 1)
    add     r0, r0, #0x40000000

    //
    // If the fractional portion is greater than 0.5, subtract it from 1.0
    // This is equivalent to sin(x) = sin(1-x) in per unit radians.
    // r0 becomes UQ32 representation of input constrained to 1st Quadrant PU:
    // [0,.5)
    //
    lsls    r1, r0, #2
    it      cs
        rsbcs   r0, r0, #0x80000000
    lsls    r0, r0, #1

    //
    // Use the top 9 fractional bits as an index into the look up table.
    // Pull sine and cosine of the index.
    // Jump out if we're close enough to 0 to do a fully odd approximation.
    //
    ldr     r12, sincos_table_26
    ubfx    r1, r0, #(31 - 9), #10
    cbz     r1, cosindex0_26
    ldr     r2, [r12, r1, lsl #2]
    rsb     r1, r1, #512
    ldr     r3, [r12, r1, lsl #2]

    //
    // Put delta x in r1.
    // This is (x-index)*pi/2  in Q32
    // Consider replacing lsl/lsr combo with UBFX:
    // 1 cycle faster, but slightly less accurate delta x.
    //
    lsl     r1, r0, #(9 + 1)
    ldr     r12, piq30_26
    umull   r12, r1, r1, r12
    lsr     r1, r1, #(9 - 1)
    mov     r0, #0

    //
    // Calculates the taylor series expansion of sin(x)
    // Interval is 0:90 degrees.
    // Preconditions:
    // r0 = 0x00000000
    // r1 = remainder (x-index) in Q32 Radians
    // r2 = sin(index) in Q32
    // r3 = cos(index) in Q32
    // r12 is available as scratch space
    // ASPR contains sign flag as MI=flip sign.
    //
    // Calculate 5th term of taylor series expansion.
    // This performs y = remainder/5*(cos(index)-y)
    // 8-12 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1
    mov     r12, #0x33333333    // 2**32/5
    umull   r12, r0, r12, r0

    //
    // Calculate 4th term of taylor series expansion.
    // This performs y = remainder/4*(sin(index)+y)
    // 5-7 cycles
    //
    add     r0, r2, r0
    umull   r12, r0, r0, r1
    lsr     r0, r0, #2

    //
    // Calculate 3rd term of taylor series expansion.
    // This performs y = remainder/3*(cos(index)-y)
    // 9-13 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1
    mov     r12, #0x55555555    // 2**32/3
    umull   r12, r0, r12, r0

    //
    // Calculate 2nd term of taylor series expansion.
    // This performs y = remainder/2*(sin(index)+y)
    // 5-7 cycles
    //
    add     r0, r2, r0
    umull   r12, r0, r0, r1
    lsr     r0, r0, #1

    //
    // Calculate 1st term of taylor series expansion.
    // This performs y = remainder/1*(cos(index)-y)
    // 4-6 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1

    //
    // Calculate 0th term of taylor series expansion.
    // This performs y = (sin(index)+y)
    //
    add     r0, r2, r0

    //
    // Compensate for sign flag in r5
    //
    lsr     r0, r0, #1
    it      cs
        rsbcs   r0, r0, #0
    asrs    r0, r0, #(31 - 26)
    adc     r0, r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // This branch handles the case very close to 0.
    // It uses the sin(x)=x approximation, but the constant is fudged down
    // a bit from pi to minimize the maximum error to +/-2 counts at Q30
    //
cosindex0_26
    ldr     r12, piq30_compensated_26
    umull   r12, r0, r0, r12
    lsr     r0, r0, #(30 - 26)
    it      cs
        rsbcs   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
sincos_table_26
    dcd     sincos_table
piq30_26
    dcd     0xc90fdaa2         // pi in Q30
piq30_compensated_26
    dcd     0xc90fcd37         // slightly less than pi in Q30
invpiq32_26
    dcd     0x517cc1b7         // 1/pi in Q32

//*****************************************************************************
//
// _IQ27cos
//
//*****************************************************************************
    section CODE__IQ27cos:CODE(2)
    thumb
    export  _IQ27cos
_IQ27cos
    //
    // Convert from radians to radians per unit by dividing by pi
    // This is done by multiplying by 1/pi in Q32
    //
    ldr     r1, invpiq32_27
    smull   r1, r0, r1, r0

    //
    // Put the input into Q31.
    // Since this is in Per Unit radians, we only care about the 1s digit
    // to determine sign of the result.  Higher bits are useless.
    // This is equivalent to sin(x) = sin(x+2*n) in per unit radians.
    //
    lsl     r0, r0, #(31 - 27)
    add     r0, r0, r1, lsr #(27 + 1)
    add     r0, r0, #0x40000000

    //
    // If the fractional portion is greater than 0.5, subtract it from 1.0
    // This is equivalent to sin(x) = sin(1-x) in per unit radians.
    // r0 becomes UQ32 representation of input constrained to 1st Quadrant PU:
    // [0,.5)
    //
    lsls    r1, r0, #2
    it      cs
        rsbcs   r0, r0, #0x80000000
    lsls    r0, r0, #1

    //
    // Use the top 9 fractional bits as an index into the look up table.
    // Pull sine and cosine of the index.
    // Jump out if we're close enough to 0 to do a fully odd approximation.
    //
    ldr     r12, sincos_table_27
    ubfx    r1, r0, #(31 - 9), #10
    cbz     r1, cosindex0_27
    ldr     r2, [r12, r1, lsl #2]
    rsb     r1, r1, #512
    ldr     r3, [r12, r1, lsl #2]

    //
    // Put delta x in r1.
    // This is (x-index)*pi/2  in Q32
    // Consider replacing lsl/lsr combo with UBFX:
    // 1 cycle faster, but slightly less accurate delta x.
    //
    lsl     r1, r0, #(9 + 1)
    ldr     r12, piq30_27
    umull   r12, r1, r1, r12
    lsr     r1, r1, #(9 - 1)
    mov     r0, #0

    //
    // Calculates the taylor series expansion of sin(x)
    // Interval is 0:90 degrees.
    // Preconditions:
    // r0 = 0x00000000
    // r1 = remainder (x-index) in Q32 Radians
    // r2 = sin(index) in Q32
    // r3 = cos(index) in Q32
    // r12 is available as scratch space
    // ASPR contains sign flag as MI=flip sign.
    //
    // Calculate 5th term of taylor series expansion.
    // This performs y = remainder/5*(cos(index)-y)
    // 8-12 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1
    mov     r12, #0x33333333    // 2**32/5
    umull   r12, r0, r12, r0

    //
    // Calculate 4th term of taylor series expansion.
    // This performs y = remainder/4*(sin(index)+y)
    // 5-7 cycles
    //
    add     r0, r2, r0
    umull   r12, r0, r0, r1
    lsr     r0, r0, #2

    //
    // Calculate 3rd term of taylor series expansion.
    // This performs y = remainder/3*(cos(index)-y)
    // 9-13 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1
    mov     r12, #0x55555555    // 2**32/3
    umull   r12, r0, r12, r0

    //
    // Calculate 2nd term of taylor series expansion.
    // This performs y = remainder/2*(sin(index)+y)
    // 5-7 cycles
    //
    add     r0, r2, r0
    umull   r12, r0, r0, r1
    lsr     r0, r0, #1

    //
    // Calculate 1st term of taylor series expansion.
    // This performs y = remainder/1*(cos(index)-y)
    // 4-6 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1

    //
    // Calculate 0th term of taylor series expansion.
    // This performs y = (sin(index)+y)
    //
    add     r0, r2, r0

    //
    // Compensate for sign flag in r5
    //
    lsr     r0, r0, #1
    it      cs
        rsbcs   r0, r0, #0
    asrs    r0, r0, #(31 - 27)
    adc     r0, r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // This branch handles the case very close to 0.
    // It uses the sin(x)=x approximation, but the constant is fudged down
    // a bit from pi to minimize the maximum error to +/-2 counts at Q30
    //
cosindex0_27
    ldr     r12, piq30_compensated_27
    umull   r12, r0, r0, r12
    lsr     r0, r0, #(30 - 27)
    it      cs
        rsbcs   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
sincos_table_27
    dcd     sincos_table
piq30_27
    dcd     0xc90fdaa2         // pi in Q30
piq30_compensated_27
    dcd     0xc90fcd37         // slightly less than pi in Q30
invpiq32_27
    dcd     0x517cc1b7         // 1/pi in Q32

//*****************************************************************************
//
// _IQ28cos
//
//*****************************************************************************
    section CODE__IQ28cos:CODE(2)
    thumb
    export  _IQ28cos
_IQ28cos
    //
    // Convert from radians to radians per unit by dividing by pi
    // This is done by multiplying by 1/pi in Q32
    //
    ldr     r1, invpiq32_28
    smull   r1, r0, r1, r0

    //
    // Put the input into Q31.
    // Since this is in Per Unit radians, we only care about the 1s digit
    // to determine sign of the result.  Higher bits are useless.
    // This is equivalent to sin(x) = sin(x+2*n) in per unit radians.
    //
    lsl     r0, r0, #(31 - 28)
    add     r0, r0, r1, lsr #(28 + 1)
    add     r0, r0, #0x40000000

    //
    // If the fractional portion is greater than 0.5, subtract it from 1.0
    // This is equivalent to sin(x) = sin(1-x) in per unit radians.
    // r0 becomes UQ32 representation of input constrained to 1st Quadrant PU:
    // [0,.5)
    //
    lsls    r1, r0, #2
    it      cs
        rsbcs   r0, r0, #0x80000000
    lsls    r0, r0, #1

    //
    // Use the top 9 fractional bits as an index into the look up table.
    // Pull sine and cosine of the index.
    // Jump out if we're close enough to 0 to do a fully odd approximation.
    //
    ldr     r12, sincos_table_28
    ubfx    r1, r0, #(31 - 9), #10
    cbz     r1, cosindex0_28
    ldr     r2, [r12, r1, lsl #2]
    rsb     r1, r1, #512
    ldr     r3, [r12, r1, lsl #2]

    //
    // Put delta x in r1.
    // This is (x-index)*pi/2  in Q32
    // Consider replacing lsl/lsr combo with UBFX:
    // 1 cycle faster, but slightly less accurate delta x.
    //
    lsl     r1, r0, #(9 + 1)
    ldr     r12, piq30_28
    umull   r12, r1, r1, r12
    lsr     r1, r1, #(9 - 1)
    mov     r0, #0

    //
    // Calculates the taylor series expansion of sin(x)
    // Interval is 0:90 degrees.
    // Preconditions:
    // r0 = 0x00000000
    // r1 = remainder (x-index) in Q32 Radians
    // r2 = sin(index) in Q32
    // r3 = cos(index) in Q32
    // r12 is available as scratch space
    // ASPR contains sign flag as MI=flip sign.
    //
    // Calculate 5th term of taylor series expansion.
    // This performs y = remainder/5*(cos(index)-y)
    // 8-12 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1
    mov     r12, #0x33333333    // 2**32/5
    umull   r12, r0, r12, r0

    //
    // Calculate 4th term of taylor series expansion.
    // This performs y = remainder/4*(sin(index)+y)
    // 5-7 cycles
    //
    add     r0, r2, r0
    umull   r12, r0, r0, r1
    lsr     r0, r0, #2

    //
    // Calculate 3rd term of taylor series expansion.
    // This performs y = remainder/3*(cos(index)-y)
    // 9-13 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1
    mov     r12, #0x55555555    // 2**32/3
    umull   r12, r0, r12, r0

    //
    // Calculate 2nd term of taylor series expansion.
    // This performs y = remainder/2*(sin(index)+y)
    // 5-7 cycles
    //
    add     r0, r2, r0
    umull   r12, r0, r0, r1
    lsr     r0, r0, #1

    //
    // Calculate 1st term of taylor series expansion.
    // This performs y = remainder/1*(cos(index)-y)
    // 4-6 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1

    //
    // Calculate 0th term of taylor series expansion.
    // This performs y = (sin(index)+y)
    //
    add     r0, r2, r0

    //
    // Compensate for sign flag in r5
    //
    lsr     r0, r0, #1
    it      cs
        rsbcs   r0, r0, #0
    asrs    r0, r0, #(31 - 28)
    adc     r0, r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // This branch handles the case very close to 0.
    // It uses the sin(x)=x approximation, but the constant is fudged down
    // a bit from pi to minimize the maximum error to +/-2 counts at Q30
    //
cosindex0_28
    ldr     r12, piq30_compensated_28
    umull   r12, r0, r0, r12
    lsr     r0, r0, #(30 - 28)
    it      cs
        rsbcs   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
sincos_table_28
    dcd     sincos_table
piq30_28
    dcd     0xc90fdaa2         // pi in Q30
piq30_compensated_28
    dcd     0xc90fcd37         // slightly less than pi in Q30
invpiq32_28
    dcd     0x517cc1b7         // 1/pi in Q32

//*****************************************************************************
//
// _IQ29cos
//
//*****************************************************************************
    section CODE__IQ29cos:CODE(2)
    thumb
    export  _IQ29cos
_IQ29cos
    //
    // Convert from radians to radians per unit by dividing by pi
    // This is done by multiplying by 1/pi in Q32
    //
    ldr     r1, invpiq32_29
    smull   r1, r0, r1, r0

    //
    // Put the input into Q31.
    // Since this is in Per Unit radians, we only care about the 1s digit
    // to determine sign of the result.  Higher bits are useless.
    // This is equivalent to sin(x) = sin(x+2*n) in per unit radians.
    //
    lsl     r0, r0, #(31 - 29)
    add     r0, r0, r1, lsr #(29 + 1)
    add     r0, r0, #0x40000000

    //
    // If the fractional portion is greater than 0.5, subtract it from 1.0
    // This is equivalent to sin(x) = sin(1-x) in per unit radians.
    // r0 becomes UQ32 representation of input constrained to 1st Quadrant PU:
    // [0,.5)
    //
    lsls    r1, r0, #2
    it      cs
        rsbcs   r0, r0, #0x80000000
    lsls    r0, r0, #1

    //
    // Use the top 9 fractional bits as an index into the look up table.
    // Pull sine and cosine of the index.
    // Jump out if we're close enough to 0 to do a fully odd approximation.
    //
    ldr     r12, sincos_table_29
    ubfx    r1, r0, #(31 - 9), #10
    cbz     r1, cosindex0_29
    ldr     r2, [r12, r1, lsl #2]
    rsb     r1, r1, #512
    ldr     r3, [r12, r1, lsl #2]

    //
    // Put delta x in r1.
    // This is (x-index)*pi/2  in Q32
    // Consider replacing lsl/lsr combo with UBFX:
    // 1 cycle faster, but slightly less accurate delta x.
    //
    lsl     r1, r0, #(9 + 1)
    ldr     r12, piq30_29
    umull   r12, r1, r1, r12
    lsr     r1, r1, #(9 - 1)
    mov     r0, #0

    //
    // Calculates the taylor series expansion of sin(x)
    // Interval is 0:90 degrees.
    // Preconditions:
    // r0 = 0x00000000
    // r1 = remainder (x-index) in Q32 Radians
    // r2 = sin(index) in Q32
    // r3 = cos(index) in Q32
    // r12 is available as scratch space
    // ASPR contains sign flag as MI=flip sign.
    //
    // Calculate 6th term of taylor series expansion.
    // This performs y = remainder/6*(sin(index)+y)
    // 5-7 cycles
    //
    add     r0, r2, r0
    umull   r12, r0, r0, r1
    ldr     r12, max629       // 2**32/6
    umull   r12, r0, r0, r12
    
    //
    // Calculate 5th term of taylor series expansion.
    // This performs y = remainder/5*(cos(index)-y)
    // 8-12 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1
    mov     r12, #0x33333333    // 2**32/5
    umull   r12, r0, r12, r0

    //
    // Calculate 4th term of taylor series expansion.
    // This performs y = remainder/4*(sin(index)+y)
    // 5-7 cycles
    //
    add     r0, r2, r0
    umull   r12, r0, r0, r1
    lsr     r0, r0, #2

    //
    // Calculate 3rd term of taylor series expansion.
    // This performs y = remainder/3*(cos(index)-y)
    // 9-13 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1
    mov     r12, #0x55555555    // 2**32/3
    umull   r12, r0, r12, r0

    //
    // Calculate 2nd term of taylor series expansion.
    // This performs y = remainder/2*(sin(index)+y)
    // 5-7 cycles
    //
    add     r0, r2, r0
    umull   r12, r0, r0, r1
    lsr     r0, r0, #1

    //
    // Calculate 1st term of taylor series expansion.
    // This performs y = remainder/1*(cos(index)-y)
    // 4-6 cycles
    //
    sub     r0, r3, r0
    umull   r12, r0, r0, r1

    //
    // Calculate 0th term of taylor series expansion.
    // This performs y = (sin(index)+y)
    //
    add     r0, r2, r0

    //
    // Compensate for sign flag in r5
    //
    lsr     r0, r0, #1
    it      cs
        rsbcs   r0, r0, #0
    asrs    r0, r0, #(31 - 29)
    adc     r0, r0, #0

    //
    // Return to the caller.
    //
    bx      lr

    //
    // This branch handles the case very close to 0.
    // It uses the sin(x)=x approximation, but the constant is fudged down
    // a bit from pi to minimize the maximum error to +/-2 counts at Q30
    //
cosindex0_29
    ldr     r12, piq30_compensated_29
    umull   r12, r0, r0, r12
    lsr     r0, r0, #(30 - 29)
    it      cs
        rsbcs   r0, r0, #0
    bx      lr

    //
    // The literal pool.
    //
    alignrom 2
    data
sincos_table_29
    dcd     sincos_table
piq30_29
    dcd     0xc90fdaa2         // pi in Q30
piq30_compensated_29
    dcd     0xc90fcd37         // slightly less than pi in Q30
invpiq32_29
    dcd     0x517cc1b7         // 1/pi in Q32
max629
    dcd     0x2aaaaaaa         // 2**32/6

    end
