//*****************************************************************************
//
// IQfrac.S - Return fractional portion of fixed point number.
//
// Copyright (c) 2010 Texas Instruments Incorporated.  All rights reserved.
// TI Information - Selective Disclosure
//
//*****************************************************************************

//*****************************************************************************
//
// Function:   _IQNfrac
//
//*****************************************************************************
//
// C Usage:    extern long _IQfrac(long A);   // no round or sat
//
//-----------------------------------------------------------------------------
//
// On Entry:   r0    = A in IQ format
//
// Regs Used:  r0
//
// On Exit:    r0    = fractional portion of A stored as IQ
//
// Q range:    30 to 1
//
//-----------------------------------------------------------------------------
//
// Algorithm:  The fractional portion of the IQ number is calculated
//             as follows:
//
//                frac = A - ((A >> q_value) << q_value);
//
//##### INTERNAL BEGIN #####
//-----------------------------------------------------------------------------
//
// Benchmark:
//
// Cycles = ??
//
//##### INTERNAL END #####
//*****************************************************************************

//*****************************************************************************
//
// _IQ1frac
//
//*****************************************************************************
    section CODE__IQ1frac:CODE(2)
    thumb
    export  _IQ1frac
_IQ1frac
    //
    // Copy A into r1, shifted by Q (integer portion only)
    //
    lsr     r1, r0, #1

    //
    // Subtract integer portion renormalized to get fraction
    //
    sub     r0, r0, r1, lsl #1

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
// _IQ2frac
//
//*****************************************************************************
    section CODE__IQ2frac:CODE(2)
    thumb
    export  _IQ2frac
_IQ2frac
    //
    // Copy A into r1, shifted by Q (integer portion only)
    //
    lsr     r1, r0, #2

    //
    // Subtract integer portion renormalized to get fraction
    //
    sub     r0, r0, r1, lsl #2

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
// _IQ3frac
//
//*****************************************************************************
    section CODE__IQ3frac:CODE(2)
    thumb
    export  _IQ3frac
_IQ3frac
    //
    // Copy A into r1, shifted by Q (integer portion only)
    //
    lsr     r1, r0, #3

    //
    // Subtract integer portion renormalized to get fraction
    //
    sub     r0, r0, r1, lsl #3

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
// _IQ4frac
//
//*****************************************************************************
    section CODE__IQ4frac:CODE(2)
    thumb
    export  _IQ4frac
_IQ4frac
    //
    // Copy A into r1, shifted by Q (integer portion only)
    //
    lsr     r1, r0, #4

    //
    // Subtract integer portion renormalized to get fraction
    //
    sub     r0, r0, r1, lsl #4

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
// _IQ5frac
//
//*****************************************************************************
    section CODE__IQ5frac:CODE(2)
    thumb
    export  _IQ5frac
_IQ5frac
    //
    // Copy A into r1, shifted by Q (integer portion only)
    //
    lsr     r1, r0, #5

    //
    // Subtract integer portion renormalized to get fraction
    //
    sub     r0, r0, r1, lsl #5

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
// _IQ6frac
//
//*****************************************************************************
    section CODE__IQ6frac:CODE(2)
    thumb
    export  _IQ6frac
_IQ6frac
    //
    // Copy A into r1, shifted by Q (integer portion only)
    //
    lsr     r1, r0, #6

    //
    // Subtract integer portion renormalized to get fraction
    //
    sub     r0, r0, r1, lsl #6

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
// _IQ7frac
//
//*****************************************************************************
    section CODE__IQ7frac:CODE(2)
    thumb
    export  _IQ7frac
_IQ7frac
    //
    // Copy A into r1, shifted by Q (integer portion only)
    //
    lsr     r1, r0, #7

    //
    // Subtract integer portion renormalized to get fraction
    //
    sub     r0, r0, r1, lsl #7

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
// _IQ8frac
//
//*****************************************************************************
    section CODE__IQ8frac:CODE(2)
    thumb
    export  _IQ8frac
_IQ8frac
    //
    // Copy A into r1, shifted by Q (integer portion only)
    //
    lsr     r1, r0, #8

    //
    // Subtract integer portion renormalized to get fraction
    //
    sub     r0, r0, r1, lsl #8

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
// _IQ9frac
//
//*****************************************************************************
    section CODE__IQ9frac:CODE(2)
    thumb
    export  _IQ9frac
_IQ9frac
    //
    // Copy A into r1, shifted by Q (integer portion only)
    //
    lsr     r1, r0, #9

    //
    // Subtract integer portion renormalized to get fraction
    //
    sub     r0, r0, r1, lsl #9

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
// _IQ10frac
//
//*****************************************************************************
    section CODE__IQ10frac:CODE(2)
    thumb
    export  _IQ10frac
_IQ10frac
    //
    // Copy A into r1, shifted by Q (integer portion only)
    //
    lsr     r1, r0, #10

    //
    // Subtract integer portion renormalized to get fraction
    //
    sub     r0, r0, r1, lsl #10

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
// _IQ11frac
//
//*****************************************************************************
    section CODE__IQ11frac:CODE(2)
    thumb
    export  _IQ11frac
_IQ11frac
    //
    // Copy A into r1, shifted by Q (integer portion only)
    //
    lsr     r1, r0, #11

    //
    // Subtract integer portion renormalized to get fraction
    //
    sub     r0, r0, r1, lsl #11

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
// _IQ12frac
//
//*****************************************************************************
    section CODE__IQ12frac:CODE(2)
    thumb
    export  _IQ12frac
_IQ12frac
    //
    // Copy A into r1, shifted by Q (integer portion only)
    //
    lsr     r1, r0, #12

    //
    // Subtract integer portion renormalized to get fraction
    //
    sub     r0, r0, r1, lsl #12

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
// _IQ13frac
//
//*****************************************************************************
    section CODE__IQ13frac:CODE(2)
    thumb
    export  _IQ13frac
_IQ13frac
    //
    // Copy A into r1, shifted by Q (integer portion only)
    //
    lsr     r1, r0, #13

    //
    // Subtract integer portion renormalized to get fraction
    //
    sub     r0, r0, r1, lsl #13

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
// _IQ14frac
//
//*****************************************************************************
    section CODE__IQ14frac:CODE(2)
    thumb
    export  _IQ14frac
_IQ14frac
    //
    // Copy A into r1, shifted by Q (integer portion only)
    //
    lsr     r1, r0, #14

    //
    // Subtract integer portion renormalized to get fraction
    //
    sub     r0, r0, r1, lsl #14

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
// _IQ15frac
//
//*****************************************************************************
    section CODE__IQ15frac:CODE(2)
    thumb
    export  _IQ15frac
_IQ15frac
    //
    // Copy A into r1, shifted by Q (integer portion only)
    //
    lsr     r1, r0, #15

    //
    // Subtract integer portion renormalized to get fraction
    //
    sub     r0, r0, r1, lsl #15

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
// _IQ16frac
//
//*****************************************************************************
    section CODE__IQ16frac:CODE(2)
    thumb
    export  _IQ16frac
_IQ16frac
    //
    // Copy A into r1, shifted by Q (integer portion only)
    //
    lsr     r1, r0, #16

    //
    // Subtract integer portion renormalized to get fraction
    //
    sub     r0, r0, r1, lsl #16

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
// _IQ17frac
//
//*****************************************************************************
    section CODE__IQ17frac:CODE(2)
    thumb
    export  _IQ17frac
_IQ17frac
    //
    // Copy A into r1, shifted by Q (integer portion only)
    //
    lsr     r1, r0, #17

    //
    // Subtract integer portion renormalized to get fraction
    //
    sub     r0, r0, r1, lsl #17

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
// _IQ18frac
//
//*****************************************************************************
    section CODE__IQ18frac:CODE(2)
    thumb
    export  _IQ18frac
_IQ18frac
    //
    // Copy A into r1, shifted by Q (integer portion only)
    //
    lsr     r1, r0, #18

    //
    // Subtract integer portion renormalized to get fraction
    //
    sub     r0, r0, r1, lsl #18

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
// _IQ19frac
//
//*****************************************************************************
    section CODE__IQ19frac:CODE(2)
    thumb
    export  _IQ19frac
_IQ19frac
    //
    // Copy A into r1, shifted by Q (integer portion only)
    //
    lsr     r1, r0, #19

    //
    // Subtract integer portion renormalized to get fraction
    //
    sub     r0, r0, r1, lsl #19

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
// _IQ20frac
//
//*****************************************************************************
    section CODE__IQ20frac:CODE(2)
    thumb
    export  _IQ20frac
_IQ20frac
    //
    // Copy A into r1, shifted by Q (integer portion only)
    //
    lsr     r1, r0, #20

    //
    // Subtract integer portion renormalized to get fraction
    //
    sub     r0, r0, r1, lsl #20

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
// _IQ21frac
//
//*****************************************************************************
    section CODE__IQ21frac:CODE(2)
    thumb
    export  _IQ21frac
_IQ21frac
    //
    // Copy A into r1, shifted by Q (integer portion only)
    //
    lsr     r1, r0, #21

    //
    // Subtract integer portion renormalized to get fraction
    //
    sub     r0, r0, r1, lsl #21

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
// _IQ22frac
//
//*****************************************************************************
    section CODE__IQ22frac:CODE(2)
    thumb
    export  _IQ22frac
_IQ22frac
    //
    // Copy A into r1, shifted by Q (integer portion only)
    //
    lsr     r1, r0, #22

    //
    // Subtract integer portion renormalized to get fraction
    //
    sub     r0, r0, r1, lsl #22

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
// _IQ23frac
//
//*****************************************************************************
    section CODE__IQ23frac:CODE(2)
    thumb
    export  _IQ23frac
_IQ23frac
    //
    // Copy A into r1, shifted by Q (integer portion only)
    //
    lsr     r1, r0, #23

    //
    // Subtract integer portion renormalized to get fraction
    //
    sub     r0, r0, r1, lsl #23

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
// _IQ24frac
//
//*****************************************************************************
    section CODE__IQ24frac:CODE(2)
    thumb
    export  _IQ24frac
_IQ24frac
    //
    // Copy A into r1, shifted by Q (integer portion only)
    //
    lsr     r1, r0, #24

    //
    // Subtract integer portion renormalized to get fraction
    //
    sub     r0, r0, r1, lsl #24

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
// _IQ25frac
//
//*****************************************************************************
    section CODE__IQ25frac:CODE(2)
    thumb
    export  _IQ25frac
_IQ25frac
    //
    // Copy A into r1, shifted by Q (integer portion only)
    //
    lsr     r1, r0, #25

    //
    // Subtract integer portion renormalized to get fraction
    //
    sub     r0, r0, r1, lsl #25

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
// _IQ26frac
//
//*****************************************************************************
    section CODE__IQ26frac:CODE(2)
    thumb
    export  _IQ26frac
_IQ26frac
    //
    // Copy A into r1, shifted by Q (integer portion only)
    //
    lsr     r1, r0, #26

    //
    // Subtract integer portion renormalized to get fraction
    //
    sub     r0, r0, r1, lsl #26

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
// _IQ27frac
//
//*****************************************************************************
    section CODE__IQ27frac:CODE(2)
    thumb
    export  _IQ27frac
_IQ27frac
    //
    // Copy A into r1, shifted by Q (integer portion only)
    //
    lsr     r1, r0, #27

    //
    // Subtract integer portion renormalized to get fraction
    //
    sub     r0, r0, r1, lsl #27

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
// _IQ28frac
//
//*****************************************************************************
    section CODE__IQ28frac:CODE(2)
    thumb
    export  _IQ28frac
_IQ28frac
    //
    // Copy A into r1, shifted by Q (integer portion only)
    //
    lsr     r1, r0, #28

    //
    // Subtract integer portion renormalized to get fraction
    //
    sub     r0, r0, r1, lsl #28

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
// _IQ29frac
//
//*****************************************************************************
    section CODE__IQ29frac:CODE(2)
    thumb
    export  _IQ29frac
_IQ29frac
    //
    // Copy A into r1, shifted by Q (integer portion only)
    //
    lsr     r1, r0, #29

    //
    // Subtract integer portion renormalized to get fraction
    //
    sub     r0, r0, r1, lsl #29

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
// _IQ30frac
//
//*****************************************************************************
    section CODE__IQ30frac:CODE(2)
    thumb
    export  _IQ30frac
_IQ30frac
    //
    // Copy A into r1, shifted by Q (integer portion only)
    //
    lsr     r1, r0, #30

    //
    // Subtract integer portion renormalized to get fraction
    //
    sub     r0, r0, r1, lsl #30

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

    end
