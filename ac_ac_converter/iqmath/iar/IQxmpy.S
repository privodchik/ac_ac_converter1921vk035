//*****************************************************************************
//
// IQxmpy.S - Fixed point multiply with arbitrary shift
//
// Copyright (c) 2010 Texas Instruments Incorporated.  All rights reserved.
// TI Information - Selective Disclosure
//
//*****************************************************************************

//*****************************************************************************
//
// Function:   __IQxmpy
//
//*****************************************************************************
//
// C Usage:    extern long __IQxmpy(long A, long B, long S);
//
//-----------------------------------------------------------------------------
//
// On Entry:   r0     = A in IQ format
//             r1     = B in IQ format
//             r2     = -32 < S < 64
//
// Regs Used:  r0, r1, r2
//
// On Exit:    r0     = A * B shifted by S in IQ format
//
//-----------------------------------------------------------------------------
//
// Algorithm:  The __IQxmpy operation generates a 64-bit result (virtually a
//             128-bit result with 32 bits of zeros before and after the 64-bit
//             multiplication result).  The appropriate 32-bit subset of this
//             result is then extracted.  By selecting the appropriate shift,
//             arbitrary Q value numbers can be multiplied together and the
//             result provided in a third Q value.  For example, multiplying a
//             Q27 by a Q24 produces:
//
//                          I5Q27 * I8Q24 => I13Q51
//
//             By using a shift of 3, the upper three bits of this result are
//             ignored and the result is a I10Q22, meaning the result of the
//             multiply has been provided in Q22 format.
//
//             The result is neither rounded nor saturated.
//
//##### INTERNAL BEGIN #####
//-----------------------------------------------------------------------------
// Benchmark:
//
// Cycles = ??
//
//##### INTERNAL END #####
//*****************************************************************************

//*****************************************************************************
//
// __IQxmpy
//
//*****************************************************************************
    section CODE___IQxmpy:CODE(2)
    thumb
    export  __IQxmpy
__IQxmpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // If the shift value is negative, the upper N bits of the 64-bit result
    // are returned as the lower N bits of the 32-bit result.
    //
    cmp     r2, #0
    bge     __positive
        negs    r2, r2
        asr     r0, r1, r2
        bx      lr

    //
    // If the shift value is greater than 32, the lower N bits of the 64-bit
    // result are returned as the upper N bits of the 32-bit result.
    //
__positive
    cmp     r2, #32
    blt     __small_shift
        sub     r2, r2, #32
        lsl     r0, r0, r2
        bx      lr

    //
    // The shift value is between 0 and 32, so 32-bits from the middle of the
    // 64-bit result is required.
    //
__small_shift
    lsl     r1, r1, r2
    rsb     r2, r2, #32
    lsr     r0, r0, r2
    orr     r0, r0, r1

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

    end
