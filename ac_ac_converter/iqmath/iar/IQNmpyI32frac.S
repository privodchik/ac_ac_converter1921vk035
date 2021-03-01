//*****************************************************************************
//
// IQmpyI32frac.S - Find fractional portion of multiplying IQ by I32
//
// Copyright (c) 2010 Texas Instruments Incorporated.  All rights reserved.
// TI Information - Selective Disclosure
//
//*****************************************************************************

//*****************************************************************************
//
// Function:   _IQNmpyI32frac
//
//*****************************************************************************
//
// C Usage:    extern long _IQmpyI32frac(long A, long B); // no round or sat
//
//-----------------------------------------------------------------------------
//
// On Entry:   r0     = A in IQ format
//             r1     = B in 32-bit integer (long) format
//
// Regs Used:
//
// On Exit:    r0   = fractional portion of A*B stored as IQ
//
// Q range:    30 to 1
//
//-----------------------------------------------------------------------------
//
// Algorithm:  The fractional portion of the IQ*I32 number is calculated
//             as follows:
//
//    1) Multiply in 32x32->32 mode, and store the sign of the result
//    2) Strip off bits past Q.  For positive results, we are done.
//    3) For negative results, check if there is a fractional portion.
//    4) If there is, subtract one.
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
// _IQ1mpyI32frac
//
//*****************************************************************************
    section CODE__IQ1mpyI32frac:CODE(2)
    thumb
    export  _IQ1mpyI32frac
_IQ1mpyI32frac
    //
    // Perform the multiply in 32x32 -> 32 mode.
    // This will over flow, but we do not need the upper 32 bits.
    // Also, the sign of the result is stored in the flags.
    //
    muls    r0, r1, r0

    //
    // Store the sign of the final result in r2.
    // The case of -.0 is handled as +.0 : Otherwise, it would be come -1.0
    //
    ite     mi
        mvnmi   r2, #0x00000000
        movpl   r2, #0x00000000
    lsls    r1, r0, #(32 - 1)
    it      eq
        moveq   r2, #0x00000000

    //
    // Overwrite the Integer bits with the sign information in r2.
    //
    bfi     r0, r2, #1, #(32 - 1)

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ2mpyI32frac
//
//*****************************************************************************
    section CODE__IQ2mpyI32frac:CODE(2)
    thumb
    export  _IQ2mpyI32frac
_IQ2mpyI32frac
    //
    // Perform the multiply in 32x32 -> 32 mode.
    // This will over flow, but we do not need the upper 32 bits.
    // Also, the sign of the result is stored in the flags.
    //
    muls    r0, r1, r0

    //
    // Store the sign of the final result in r2.
    // The case of -.0 is handled as +.0 : Otherwise, it would be come -1.0
    //
    ite     mi
        mvnmi   r2, #0x00000000
        movpl   r2, #0x00000000
    lsls    r1, r0, #(32 - 2)
    it      eq
        moveq   r2, #0x00000000

    //
    // Overwrite the Integer bits with the sign information in r2.
    //
    bfi     r0, r2, #2, #(32 - 2)

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ3mpyI32frac
//
//*****************************************************************************
    section CODE__IQ3mpyI32frac:CODE(2)
    thumb
    export  _IQ3mpyI32frac
_IQ3mpyI32frac
    //
    // Perform the multiply in 32x32 -> 32 mode.
    // This will over flow, but we do not need the upper 32 bits.
    // Also, the sign of the result is stored in the flags.
    //
    muls    r0, r1, r0

    //
    // Store the sign of the final result in r2.
    // The case of -.0 is handled as +.0 : Otherwise, it would be come -1.0
    //
    ite     mi
        mvnmi   r2, #0x00000000
        movpl   r2, #0x00000000
    lsls    r1, r0, #(32 - 3)
    it      eq
        moveq   r2, #0x00000000

    //
    // Overwrite the Integer bits with the sign information in r2.
    //
    bfi     r0, r2, #3, #(32 - 3)

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ4mpyI32frac
//
//*****************************************************************************
    section CODE__IQ4mpyI32frac:CODE(2)
    thumb
    export  _IQ4mpyI32frac
_IQ4mpyI32frac
    //
    // Perform the multiply in 32x32 -> 32 mode.
    // This will over flow, but we do not need the upper 32 bits.
    // Also, the sign of the result is stored in the flags.
    //
    muls    r0, r1, r0

    //
    // Store the sign of the final result in r2.
    // The case of -.0 is handled as +.0 : Otherwise, it would be come -1.0
    //
    ite     mi
        mvnmi   r2, #0x00000000
        movpl   r2, #0x00000000
    lsls    r1, r0, #(32 - 4)
    it      eq
        moveq   r2, #0x00000000

    //
    // Overwrite the Integer bits with the sign information in r2.
    //
    bfi     r0, r2, #4, #(32 - 4)

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ5mpyI32frac
//
//*****************************************************************************
    section CODE__IQ5mpyI32frac:CODE(2)
    thumb
    export  _IQ5mpyI32frac
_IQ5mpyI32frac
    //
    // Perform the multiply in 32x32 -> 32 mode.
    // This will over flow, but we do not need the upper 32 bits.
    // Also, the sign of the result is stored in the flags.
    //
    muls    r0, r1, r0

    //
    // Store the sign of the final result in r2.
    // The case of -.0 is handled as +.0 : Otherwise, it would be come -1.0
    //
    ite     mi
        mvnmi   r2, #0x00000000
        movpl   r2, #0x00000000
    lsls    r1, r0, #(32 - 5)
    it      eq
        moveq   r2, #0x00000000

    //
    // Overwrite the Integer bits with the sign information in r2.
    //
    bfi     r0, r2, #5, #(32 - 5)

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ6mpyI32frac
//
//*****************************************************************************
    section CODE__IQ6mpyI32frac:CODE(2)
    thumb
    export  _IQ6mpyI32frac
_IQ6mpyI32frac
    //
    // Perform the multiply in 32x32 -> 32 mode.
    // This will over flow, but we do not need the upper 32 bits.
    // Also, the sign of the result is stored in the flags.
    //
    muls    r0, r1, r0

    //
    // Store the sign of the final result in r2.
    // The case of -.0 is handled as +.0 : Otherwise, it would be come -1.0
    //
    ite     mi
        mvnmi   r2, #0x00000000
        movpl   r2, #0x00000000
    lsls    r1, r0, #(32 - 6)
    it      eq
        moveq   r2, #0x00000000

    //
    // Overwrite the Integer bits with the sign information in r2.
    //
    bfi     r0, r2, #6, #(32 - 6)

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ7mpyI32frac
//
//*****************************************************************************
    section CODE__IQ7mpyI32frac:CODE(2)
    thumb
    export  _IQ7mpyI32frac
_IQ7mpyI32frac
    //
    // Perform the multiply in 32x32 -> 32 mode.
    // This will over flow, but we do not need the upper 32 bits.
    // Also, the sign of the result is stored in the flags.
    //
    muls    r0, r1, r0

    //
    // Store the sign of the final result in r2.
    // The case of -.0 is handled as +.0 : Otherwise, it would be come -1.0
    //
    ite     mi
        mvnmi   r2, #0x00000000
        movpl   r2, #0x00000000
    lsls    r1, r0, #(32 - 7)
    it      eq
        moveq   r2, #0x00000000

    //
    // Overwrite the Integer bits with the sign information in r2.
    //
    bfi     r0, r2, #7, #(32 - 7)

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ8mpyI32frac
//
//*****************************************************************************
    section CODE__IQ8mpyI32frac:CODE(2)
    thumb
    export  _IQ8mpyI32frac
_IQ8mpyI32frac
    //
    // Perform the multiply in 32x32 -> 32 mode.
    // This will over flow, but we do not need the upper 32 bits.
    // Also, the sign of the result is stored in the flags.
    //
    muls    r0, r1, r0

    //
    // Store the sign of the final result in r2.
    // The case of -.0 is handled as +.0 : Otherwise, it would be come -1.0
    //
    ite     mi
        mvnmi   r2, #0x00000000
        movpl   r2, #0x00000000
    lsls    r1, r0, #(32 - 8)
    it      eq
        moveq   r2, #0x00000000

    //
    // Overwrite the Integer bits with the sign information in r2.
    //
    bfi     r0, r2, #8, #(32 - 8)

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ9mpyI32frac
//
//*****************************************************************************
    section CODE__IQ9mpyI32frac:CODE(2)
    thumb
    export  _IQ9mpyI32frac
_IQ9mpyI32frac
    //
    // Perform the multiply in 32x32 -> 32 mode.
    // This will over flow, but we do not need the upper 32 bits.
    // Also, the sign of the result is stored in the flags.
    //
    muls    r0, r1, r0

    //
    // Store the sign of the final result in r2.
    // The case of -.0 is handled as +.0 : Otherwise, it would be come -1.0
    //
    ite     mi
        mvnmi   r2, #0x00000000
        movpl   r2, #0x00000000
    lsls    r1, r0, #(32 - 9)
    it      eq
        moveq   r2, #0x00000000

    //
    // Overwrite the Integer bits with the sign information in r2.
    //
    bfi     r0, r2, #9, #(32 - 9)

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ10mpyI32frac
//
//*****************************************************************************
    section CODE__IQ10mpyI32frac:CODE(2)
    thumb
    export  _IQ10mpyI32frac
_IQ10mpyI32frac
    //
    // Perform the multiply in 32x32 -> 32 mode.
    // This will over flow, but we do not need the upper 32 bits.
    // Also, the sign of the result is stored in the flags.
    //
    muls    r0, r1, r0

    //
    // Store the sign of the final result in r2.
    // The case of -.0 is handled as +.0 : Otherwise, it would be come -1.0
    //
    ite     mi
        mvnmi   r2, #0x00000000
        movpl   r2, #0x00000000
    lsls    r1, r0, #(32 - 10)
    it      eq
        moveq   r2, #0x00000000

    //
    // Overwrite the Integer bits with the sign information in r2.
    //
    bfi     r0, r2, #10, #(32 - 10)

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ11mpyI32frac
//
//*****************************************************************************
    section CODE__IQ11mpyI32frac:CODE(2)
    thumb
    export  _IQ11mpyI32frac
_IQ11mpyI32frac
    //
    // Perform the multiply in 32x32 -> 32 mode.
    // This will over flow, but we do not need the upper 32 bits.
    // Also, the sign of the result is stored in the flags.
    //
    muls    r0, r1, r0

    //
    // Store the sign of the final result in r2.
    // The case of -.0 is handled as +.0 : Otherwise, it would be come -1.0
    //
    ite     mi
        mvnmi   r2, #0x00000000
        movpl   r2, #0x00000000
    lsls    r1, r0, #(32 - 11)
    it      eq
        moveq   r2, #0x00000000

    //
    // Overwrite the Integer bits with the sign information in r2.
    //
    bfi     r0, r2, #11, #(32 - 11)

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ12mpyI32frac
//
//*****************************************************************************
    section CODE__IQ12mpyI32frac:CODE(2)
    thumb
    export  _IQ12mpyI32frac
_IQ12mpyI32frac
    //
    // Perform the multiply in 32x32 -> 32 mode.
    // This will over flow, but we do not need the upper 32 bits.
    // Also, the sign of the result is stored in the flags.
    //
    muls    r0, r1, r0

    //
    // Store the sign of the final result in r2.
    // The case of -.0 is handled as +.0 : Otherwise, it would be come -1.0
    //
    ite     mi
        mvnmi   r2, #0x00000000
        movpl   r2, #0x00000000
    lsls    r1, r0, #(32 - 12)
    it      eq
        moveq   r2, #0x00000000

    //
    // Overwrite the Integer bits with the sign information in r2.
    //
    bfi     r0, r2, #12, #(32 - 12)

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ13mpyI32frac
//
//*****************************************************************************
    section CODE__IQ13mpyI32frac:CODE(2)
    thumb
    export  _IQ13mpyI32frac
_IQ13mpyI32frac
    //
    // Perform the multiply in 32x32 -> 32 mode.
    // This will over flow, but we do not need the upper 32 bits.
    // Also, the sign of the result is stored in the flags.
    //
    muls    r0, r1, r0

    //
    // Store the sign of the final result in r2.
    // The case of -.0 is handled as +.0 : Otherwise, it would be come -1.0
    //
    ite     mi
        mvnmi   r2, #0x00000000
        movpl   r2, #0x00000000
    lsls    r1, r0, #(32 - 13)
    it      eq
        moveq   r2, #0x00000000

    //
    // Overwrite the Integer bits with the sign information in r2.
    //
    bfi     r0, r2, #13, #(32 - 13)

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ14mpyI32frac
//
//*****************************************************************************
    section CODE__IQ14mpyI32frac:CODE(2)
    thumb
    export  _IQ14mpyI32frac
_IQ14mpyI32frac
    //
    // Perform the multiply in 32x32 -> 32 mode.
    // This will over flow, but we do not need the upper 32 bits.
    // Also, the sign of the result is stored in the flags.
    //
    muls    r0, r1, r0

    //
    // Store the sign of the final result in r2.
    // The case of -.0 is handled as +.0 : Otherwise, it would be come -1.0
    //
    ite     mi
        mvnmi   r2, #0x00000000
        movpl   r2, #0x00000000
    lsls    r1, r0, #(32 - 14)
    it      eq
        moveq   r2, #0x00000000

    //
    // Overwrite the Integer bits with the sign information in r2.
    //
    bfi     r0, r2, #14, #(32 - 14)

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ15mpyI32frac
//
//*****************************************************************************
    section CODE__IQ15mpyI32frac:CODE(2)
    thumb
    export  _IQ15mpyI32frac
_IQ15mpyI32frac
    //
    // Perform the multiply in 32x32 -> 32 mode.
    // This will over flow, but we do not need the upper 32 bits.
    // Also, the sign of the result is stored in the flags.
    //
    muls    r0, r1, r0

    //
    // Store the sign of the final result in r2.
    // The case of -.0 is handled as +.0 : Otherwise, it would be come -1.0
    //
    ite     mi
        mvnmi   r2, #0x00000000
        movpl   r2, #0x00000000
    lsls    r1, r0, #(32 - 15)
    it      eq
        moveq   r2, #0x00000000

    //
    // Overwrite the Integer bits with the sign information in r2.
    //
    bfi     r0, r2, #15, #(32 - 15)

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ16mpyI32frac
//
//*****************************************************************************
    section CODE__IQ16mpyI32frac:CODE(2)
    thumb
    export  _IQ16mpyI32frac
_IQ16mpyI32frac
    //
    // Perform the multiply in 32x32 -> 32 mode.
    // This will over flow, but we do not need the upper 32 bits.
    // Also, the sign of the result is stored in the flags.
    //
    muls    r0, r1, r0

    //
    // Store the sign of the final result in r2.
    // The case of -.0 is handled as +.0 : Otherwise, it would be come -1.0
    //
    ite     mi
        mvnmi   r2, #0x00000000
        movpl   r2, #0x00000000
    lsls    r1, r0, #(32 - 16)
    it      eq
        moveq   r2, #0x00000000

    //
    // Overwrite the Integer bits with the sign information in r2.
    //
    bfi     r0, r2, #16, #(32 - 16)

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ17mpyI32frac
//
//*****************************************************************************
    section CODE__IQ17mpyI32frac:CODE(2)
    thumb
    export  _IQ17mpyI32frac
_IQ17mpyI32frac
    //
    // Perform the multiply in 32x32 -> 32 mode.
    // This will over flow, but we do not need the upper 32 bits.
    // Also, the sign of the result is stored in the flags.
    //
    muls    r0, r1, r0

    //
    // Store the sign of the final result in r2.
    // The case of -.0 is handled as +.0 : Otherwise, it would be come -1.0
    //
    ite     mi
        mvnmi   r2, #0x00000000
        movpl   r2, #0x00000000
    lsls    r1, r0, #(32 - 17)
    it      eq
        moveq   r2, #0x00000000

    //
    // Overwrite the Integer bits with the sign information in r2.
    //
    bfi     r0, r2, #17, #(32 - 17)

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ18mpyI32frac
//
//*****************************************************************************
    section CODE__IQ18mpyI32frac:CODE(2)
    thumb
    export  _IQ18mpyI32frac
_IQ18mpyI32frac
    //
    // Perform the multiply in 32x32 -> 32 mode.
    // This will over flow, but we do not need the upper 32 bits.
    // Also, the sign of the result is stored in the flags.
    //
    muls    r0, r1, r0

    //
    // Store the sign of the final result in r2.
    // The case of -.0 is handled as +.0 : Otherwise, it would be come -1.0
    //
    ite     mi
        mvnmi   r2, #0x00000000
        movpl   r2, #0x00000000
    lsls    r1, r0, #(32 - 18)
    it      eq
        moveq   r2, #0x00000000

    //
    // Overwrite the Integer bits with the sign information in r2.
    //
    bfi     r0, r2, #18, #(32 - 18)

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ19mpyI32frac
//
//*****************************************************************************
    section CODE__IQ19mpyI32frac:CODE(2)
    thumb
    export  _IQ19mpyI32frac
_IQ19mpyI32frac
    //
    // Perform the multiply in 32x32 -> 32 mode.
    // This will over flow, but we do not need the upper 32 bits.
    // Also, the sign of the result is stored in the flags.
    //
    muls    r0, r1, r0

    //
    // Store the sign of the final result in r2.
    // The case of -.0 is handled as +.0 : Otherwise, it would be come -1.0
    //
    ite     mi
        mvnmi   r2, #0x00000000
        movpl   r2, #0x00000000
    lsls    r1, r0, #(32 - 19)
    it      eq
        moveq   r2, #0x00000000

    //
    // Overwrite the Integer bits with the sign information in r2.
    //
    bfi     r0, r2, #19, #(32 - 19)

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ20mpyI32frac
//
//*****************************************************************************
    section CODE__IQ20mpyI32frac:CODE(2)
    thumb
    export  _IQ20mpyI32frac
_IQ20mpyI32frac
    //
    // Perform the multiply in 32x32 -> 32 mode.
    // This will over flow, but we do not need the upper 32 bits.
    // Also, the sign of the result is stored in the flags.
    //
    muls    r0, r1, r0

    //
    // Store the sign of the final result in r2.
    // The case of -.0 is handled as +.0 : Otherwise, it would be come -1.0
    //
    ite     mi
        mvnmi   r2, #0x00000000
        movpl   r2, #0x00000000
    lsls    r1, r0, #(32 - 20)
    it      eq
        moveq   r2, #0x00000000

    //
    // Overwrite the Integer bits with the sign information in r2.
    //
    bfi     r0, r2, #20, #(32 - 20)

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ21mpyI32frac
//
//*****************************************************************************
    section CODE__IQ21mpyI32frac:CODE(2)
    thumb
    export  _IQ21mpyI32frac
_IQ21mpyI32frac
    //
    // Perform the multiply in 32x32 -> 32 mode.
    // This will over flow, but we do not need the upper 32 bits.
    // Also, the sign of the result is stored in the flags.
    //
    muls    r0, r1, r0

    //
    // Store the sign of the final result in r2.
    // The case of -.0 is handled as +.0 : Otherwise, it would be come -1.0
    //
    ite     mi
        mvnmi   r2, #0x00000000
        movpl   r2, #0x00000000
    lsls    r1, r0, #(32 - 21)
    it      eq
        moveq   r2, #0x00000000

    //
    // Overwrite the Integer bits with the sign information in r2.
    //
    bfi     r0, r2, #21, #(32 - 21)

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ22mpyI32frac
//
//*****************************************************************************
    section CODE__IQ22mpyI32frac:CODE(2)
    thumb
    export  _IQ22mpyI32frac
_IQ22mpyI32frac
    //
    // Perform the multiply in 32x32 -> 32 mode.
    // This will over flow, but we do not need the upper 32 bits.
    // Also, the sign of the result is stored in the flags.
    //
    muls    r0, r1, r0

    //
    // Store the sign of the final result in r2.
    // The case of -.0 is handled as +.0 : Otherwise, it would be come -1.0
    //
    ite     mi
        mvnmi   r2, #0x00000000
        movpl   r2, #0x00000000
    lsls    r1, r0, #(32 - 22)
    it      eq
        moveq   r2, #0x00000000

    //
    // Overwrite the Integer bits with the sign information in r2.
    //
    bfi     r0, r2, #22, #(32 - 22)

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ23mpyI32frac
//
//*****************************************************************************
    section CODE__IQ23mpyI32frac:CODE(2)
    thumb
    export  _IQ23mpyI32frac
_IQ23mpyI32frac
    //
    // Perform the multiply in 32x32 -> 32 mode.
    // This will over flow, but we do not need the upper 32 bits.
    // Also, the sign of the result is stored in the flags.
    //
    muls    r0, r1, r0

    //
    // Store the sign of the final result in r2.
    // The case of -.0 is handled as +.0 : Otherwise, it would be come -1.0
    //
    ite     mi
        mvnmi   r2, #0x00000000
        movpl   r2, #0x00000000
    lsls    r1, r0, #(32 - 23)
    it      eq
        moveq   r2, #0x00000000

    //
    // Overwrite the Integer bits with the sign information in r2.
    //
    bfi     r0, r2, #23, #(32 - 23)

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ24mpyI32frac
//
//*****************************************************************************
    section CODE__IQ24mpyI32frac:CODE(2)
    thumb
    export  _IQ24mpyI32frac
_IQ24mpyI32frac
    //
    // Perform the multiply in 32x32 -> 32 mode.
    // This will over flow, but we do not need the upper 32 bits.
    // Also, the sign of the result is stored in the flags.
    //
    muls    r0, r1, r0

    //
    // Store the sign of the final result in r2.
    // The case of -.0 is handled as +.0 : Otherwise, it would be come -1.0
    //
    ite     mi
        mvnmi   r2, #0x00000000
        movpl   r2, #0x00000000
    lsls    r1, r0, #(32 - 24)
    it      eq
        moveq   r2, #0x00000000

    //
    // Overwrite the Integer bits with the sign information in r2.
    //
    bfi     r0, r2, #24, #(32 - 24)

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ25mpyI32frac
//
//*****************************************************************************
    section CODE__IQ25mpyI32frac:CODE(2)
    thumb
    export  _IQ25mpyI32frac
_IQ25mpyI32frac
    //
    // Perform the multiply in 32x32 -> 32 mode.
    // This will over flow, but we do not need the upper 32 bits.
    // Also, the sign of the result is stored in the flags.
    //
    muls    r0, r1, r0

    //
    // Store the sign of the final result in r2.
    // The case of -.0 is handled as +.0 : Otherwise, it would be come -1.0
    //
    ite     mi
        mvnmi   r2, #0x00000000
        movpl   r2, #0x00000000
    lsls    r1, r0, #(32 - 25)
    it      eq
        moveq   r2, #0x00000000

    //
    // Overwrite the Integer bits with the sign information in r2.
    //
    bfi     r0, r2, #25, #(32 - 25)

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ26mpyI32frac
//
//*****************************************************************************
    section CODE__IQ26mpyI32frac:CODE(2)
    thumb
    export  _IQ26mpyI32frac
_IQ26mpyI32frac
    //
    // Perform the multiply in 32x32 -> 32 mode.
    // This will over flow, but we do not need the upper 32 bits.
    // Also, the sign of the result is stored in the flags.
    //
    muls    r0, r1, r0

    //
    // Store the sign of the final result in r2.
    // The case of -.0 is handled as +.0 : Otherwise, it would be come -1.0
    //
    ite     mi
        mvnmi   r2, #0x00000000
        movpl   r2, #0x00000000
    lsls    r1, r0, #(32 - 26)
    it      eq
        moveq   r2, #0x00000000

    //
    // Overwrite the Integer bits with the sign information in r2.
    //
    bfi     r0, r2, #26, #(32 - 26)

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ27mpyI32frac
//
//*****************************************************************************
    section CODE__IQ27mpyI32frac:CODE(2)
    thumb
    export  _IQ27mpyI32frac
_IQ27mpyI32frac
    //
    // Perform the multiply in 32x32 -> 32 mode.
    // This will over flow, but we do not need the upper 32 bits.
    // Also, the sign of the result is stored in the flags.
    //
    muls    r0, r1, r0

    //
    // Store the sign of the final result in r2.
    // The case of -.0 is handled as +.0 : Otherwise, it would be come -1.0
    //
    ite     mi
        mvnmi   r2, #0x00000000
        movpl   r2, #0x00000000
    lsls    r1, r0, #(32 - 27)
    it      eq
        moveq   r2, #0x00000000

    //
    // Overwrite the Integer bits with the sign information in r2.
    //
    bfi     r0, r2, #27, #(32 - 27)

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ28mpyI32frac
//
//*****************************************************************************
    section CODE__IQ28mpyI32frac:CODE(2)
    thumb
    export  _IQ28mpyI32frac
_IQ28mpyI32frac
    //
    // Perform the multiply in 32x32 -> 32 mode.
    // This will over flow, but we do not need the upper 32 bits.
    // Also, the sign of the result is stored in the flags.
    //
    muls    r0, r1, r0

    //
    // Store the sign of the final result in r2.
    // The case of -.0 is handled as +.0 : Otherwise, it would be come -1.0
    //
    ite     mi
        mvnmi   r2, #0x00000000
        movpl   r2, #0x00000000
    lsls    r1, r0, #(32 - 28)
    it      eq
        moveq   r2, #0x00000000

    //
    // Overwrite the Integer bits with the sign information in r2.
    //
    bfi     r0, r2, #28, #(32 - 28)

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ29mpyI32frac
//
//*****************************************************************************
    section CODE__IQ29mpyI32frac:CODE(2)
    thumb
    export  _IQ29mpyI32frac
_IQ29mpyI32frac
    //
    // Perform the multiply in 32x32 -> 32 mode.
    // This will over flow, but we do not need the upper 32 bits.
    // Also, the sign of the result is stored in the flags.
    //
    muls    r0, r1, r0

    //
    // Store the sign of the final result in r2.
    // The case of -.0 is handled as +.0 : Otherwise, it would be come -1.0
    //
    ite     mi
        mvnmi   r2, #0x00000000
        movpl   r2, #0x00000000
    lsls    r1, r0, #(32 - 29)
    it      eq
        moveq   r2, #0x00000000

    //
    // Overwrite the Integer bits with the sign information in r2.
    //
    bfi     r0, r2, #29, #(32 - 29)

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ30mpyI32frac
//
//*****************************************************************************
    section CODE__IQ30mpyI32frac:CODE(2)
    thumb
    export  _IQ30mpyI32frac
_IQ30mpyI32frac
    //
    // Perform the multiply in 32x32 -> 32 mode.
    // This will over flow, but we do not need the upper 32 bits.
    // Also, the sign of the result is stored in the flags.
    //
    muls    r0, r1, r0

    //
    // Store the sign of the final result in r2.
    // The case of -.0 is handled as +.0 : Otherwise, it would be come -1.0
    //
    ite     mi
        mvnmi   r2, #0x00000000
        movpl   r2, #0x00000000
    lsls    r1, r0, #(32 - 30)
    it      eq
        moveq   r2, #0x00000000

    //
    // Overwrite the Integer bits with the sign information in r2.
    //
    bfi     r0, r2, #30, #(32 - 30)

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

    end
