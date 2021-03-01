//*****************************************************************************
//
// IQrmpy.S - Fixed point multiply with rounding (no saturation)
//
// Copyright (c) 2010 Texas Instruments Incorporated.  All rights reserved.
// TI Information - Selective Disclosure
//
//*****************************************************************************

//*****************************************************************************
//
// Function:   _IQNrmpy
//
//*****************************************************************************
//
// C Usage:    extern long _IQNrmpy(long M, long X); // with rounding only
//
//-----------------------------------------------------------------------------
//
// On Entry:   r0     = A in IQ format
//             r1     = B in IQ format
//
// Regs Used:  r0, r1
//
// On Exit:    r0     = A*B stored as IQ
//
// Q range:    30 to 1
//
//-----------------------------------------------------------------------------
//
// Algorithm:  The integer portion of the IQ*I32 number is calculated
//             as follows:
//
//                result = (A*B >> q_value)+result[-1];
//
//-----------------------------------------------------------------------------
//
// Benchmark:
//
// Cycles = 5-9 cycles, not counting call
//
//*****************************************************************************

//*****************************************************************************
//
// _IQ1rmpy
//
//*****************************************************************************
    section CODE__IQ1rmpy:CODE(2)
    thumb
    export  _IQ1rmpy
_IQ1rmpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    // Also, update Carry flag to indicate whether or not to round
    //
    lsrs    r0, r0, #1

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    // Add the carry flag in to round
    //
    adc     r0, r0, r1, lsl #(32 - 1)

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
// _IQ2rmpy
//
//*****************************************************************************
    section CODE__IQ2rmpy:CODE(2)
    thumb
    export  _IQ2rmpy
_IQ2rmpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    // Also, update Carry flag to indicate whether or not to round
    //
    lsrs    r0, r0, #2

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    // Add the carry flag in to round
    //
    adc     r0, r0, r1, lsl #(32 - 2)

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
// _IQ3rmpy
//
//*****************************************************************************
    section CODE__IQ3rmpy:CODE(2)
    thumb
    export  _IQ3rmpy
_IQ3rmpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    // Also, update Carry flag to indicate whether or not to round
    //
    lsrs    r0, r0, #3

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    // Add the carry flag in to round
    //
    adc     r0, r0, r1, lsl #(32 - 3)

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
// _IQ4rmpy
//
//*****************************************************************************
    section CODE__IQ4rmpy:CODE(2)
    thumb
    export  _IQ4rmpy
_IQ4rmpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    // Also, update Carry flag to indicate whether or not to round
    //
    lsrs    r0, r0, #4

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    // Add the carry flag in to round
    //
    adc     r0, r0, r1, lsl #(32 - 4)

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
// _IQ5rmpy
//
//*****************************************************************************
    section CODE__IQ5rmpy:CODE(2)
    thumb
    export  _IQ5rmpy
_IQ5rmpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    // Also, update Carry flag to indicate whether or not to round
    //
    lsrs    r0, r0, #5

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    // Add the carry flag in to round
    //
    adc     r0, r0, r1, lsl #(32 - 5)

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
// _IQ6rmpy
//
//*****************************************************************************
    section CODE__IQ6rmpy:CODE(2)
    thumb
    export  _IQ6rmpy
_IQ6rmpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    // Also, update Carry flag to indicate whether or not to round
    //
    lsrs    r0, r0, #6

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    // Add the carry flag in to round
    //
    adc     r0, r0, r1, lsl #(32 - 6)

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
// _IQ7rmpy
//
//*****************************************************************************
    section CODE__IQ7rmpy:CODE(2)
    thumb
    export  _IQ7rmpy
_IQ7rmpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    // Also, update Carry flag to indicate whether or not to round
    //
    lsrs    r0, r0, #7

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    // Add the carry flag in to round
    //
    adc     r0, r0, r1, lsl #(32 - 7)

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
// _IQ8rmpy
//
//*****************************************************************************
    section CODE__IQ8rmpy:CODE(2)
    thumb
    export  _IQ8rmpy
_IQ8rmpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    // Also, update Carry flag to indicate whether or not to round
    //
    lsrs    r0, r0, #8

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    // Add the carry flag in to round
    //
    adc     r0, r0, r1, lsl #(32 - 8)

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
// _IQ9rmpy
//
//*****************************************************************************
    section CODE__IQ9rmpy:CODE(2)
    thumb
    export  _IQ9rmpy
_IQ9rmpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    // Also, update Carry flag to indicate whether or not to round
    //
    lsrs    r0, r0, #9

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    // Add the carry flag in to round
    //
    adc     r0, r0, r1, lsl #(32 - 9)

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
// _IQ10rmpy
//
//*****************************************************************************
    section CODE__IQ10rmpy:CODE(2)
    thumb
    export  _IQ10rmpy
_IQ10rmpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    // Also, update Carry flag to indicate whether or not to round
    //
    lsrs    r0, r0, #10

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    // Add the carry flag in to round
    //
    adc     r0, r0, r1, lsl #(32 - 10)

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
// _IQ11rmpy
//
//*****************************************************************************
    section CODE__IQ11rmpy:CODE(2)
    thumb
    export  _IQ11rmpy
_IQ11rmpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    // Also, update Carry flag to indicate whether or not to round
    //
    lsrs    r0, r0, #11

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    // Add the carry flag in to round
    //
    adc     r0, r0, r1, lsl #(32 - 11)

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
// _IQ12rmpy
//
//*****************************************************************************
    section CODE__IQ12rmpy:CODE(2)
    thumb
    export  _IQ12rmpy
_IQ12rmpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    // Also, update Carry flag to indicate whether or not to round
    //
    lsrs    r0, r0, #12

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    // Add the carry flag in to round
    //
    adc     r0, r0, r1, lsl #(32 - 12)

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
// _IQ13rmpy
//
//*****************************************************************************
    section CODE__IQ13rmpy:CODE(2)
    thumb
    export  _IQ13rmpy
_IQ13rmpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    // Also, update Carry flag to indicate whether or not to round
    //
    lsrs    r0, r0, #13

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    // Add the carry flag in to round
    //
    adc     r0, r0, r1, lsl #(32 - 13)

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
// _IQ14rmpy
//
//*****************************************************************************
    section CODE__IQ14rmpy:CODE(2)
    thumb
    export  _IQ14rmpy
_IQ14rmpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    // Also, update Carry flag to indicate whether or not to round
    //
    lsrs    r0, r0, #14

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    // Add the carry flag in to round
    //
    adc     r0, r0, r1, lsl #(32 - 14)

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
// _IQ15rmpy
//
//*****************************************************************************
    section CODE__IQ15rmpy:CODE(2)
    thumb
    export  _IQ15rmpy
_IQ15rmpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    // Also, update Carry flag to indicate whether or not to round
    //
    lsrs    r0, r0, #15

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    // Add the carry flag in to round
    //
    adc     r0, r0, r1, lsl #(32 - 15)

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
// _IQ16rmpy
//
//*****************************************************************************
    section CODE__IQ16rmpy:CODE(2)
    thumb
    export  _IQ16rmpy
_IQ16rmpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    // Also, update Carry flag to indicate whether or not to round
    //
    lsrs    r0, r0, #16

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    // Add the carry flag in to round
    //
    adc     r0, r0, r1, lsl #(32 - 16)

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
// _IQ17rmpy
//
//*****************************************************************************
    section CODE__IQ17rmpy:CODE(2)
    thumb
    export  _IQ17rmpy
_IQ17rmpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    // Also, update Carry flag to indicate whether or not to round
    //
    lsrs    r0, r0, #17

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    // Add the carry flag in to round
    //
    adc     r0, r0, r1, lsl #(32 - 17)

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
// _IQ18rmpy
//
//*****************************************************************************
    section CODE__IQ18rmpy:CODE(2)
    thumb
    export  _IQ18rmpy
_IQ18rmpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    // Also, update Carry flag to indicate whether or not to round
    //
    lsrs    r0, r0, #18

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    // Add the carry flag in to round
    //
    adc     r0, r0, r1, lsl #(32 - 18)

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
// _IQ19rmpy
//
//*****************************************************************************
    section CODE__IQ19rmpy:CODE(2)
    thumb
    export  _IQ19rmpy
_IQ19rmpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    // Also, update Carry flag to indicate whether or not to round
    //
    lsrs    r0, r0, #19

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    // Add the carry flag in to round
    //
    adc     r0, r0, r1, lsl #(32 - 19)

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
// _IQ20rmpy
//
//*****************************************************************************
    section CODE__IQ20rmpy:CODE(2)
    thumb
    export  _IQ20rmpy
_IQ20rmpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    // Also, update Carry flag to indicate whether or not to round
    //
    lsrs    r0, r0, #20

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    // Add the carry flag in to round
    //
    adc     r0, r0, r1, lsl #(32 - 20)

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
// _IQ21rmpy
//
//*****************************************************************************
    section CODE__IQ21rmpy:CODE(2)
    thumb
    export  _IQ21rmpy
_IQ21rmpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    // Also, update Carry flag to indicate whether or not to round
    //
    lsrs    r0, r0, #21

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    // Add the carry flag in to round
    //
    adc     r0, r0, r1, lsl #(32 - 21)

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
// _IQ22rmpy
//
//*****************************************************************************
    section CODE__IQ22rmpy:CODE(2)
    thumb
    export  _IQ22rmpy
_IQ22rmpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    // Also, update Carry flag to indicate whether or not to round
    //
    lsrs    r0, r0, #22

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    // Add the carry flag in to round
    //
    adc     r0, r0, r1, lsl #(32 - 22)

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
// _IQ23rmpy
//
//*****************************************************************************
    section CODE__IQ23rmpy:CODE(2)
    thumb
    export  _IQ23rmpy
_IQ23rmpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    // Also, update Carry flag to indicate whether or not to round
    //
    lsrs    r0, r0, #23

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    // Add the carry flag in to round
    //
    adc     r0, r0, r1, lsl #(32 - 23)

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
// _IQ24rmpy
//
//*****************************************************************************
    section CODE__IQ24rmpy:CODE(2)
    thumb
    export  _IQ24rmpy
_IQ24rmpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    // Also, update Carry flag to indicate whether or not to round
    //
    lsrs    r0, r0, #24

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    // Add the carry flag in to round
    //
    adc     r0, r0, r1, lsl #(32 - 24)

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
// _IQ25rmpy
//
//*****************************************************************************
    section CODE__IQ25rmpy:CODE(2)
    thumb
    export  _IQ25rmpy
_IQ25rmpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    // Also, update Carry flag to indicate whether or not to round
    //
    lsrs    r0, r0, #25

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    // Add the carry flag in to round
    //
    adc     r0, r0, r1, lsl #(32 - 25)

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
// _IQ26rmpy
//
//*****************************************************************************
    section CODE__IQ26rmpy:CODE(2)
    thumb
    export  _IQ26rmpy
_IQ26rmpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    // Also, update Carry flag to indicate whether or not to round
    //
    lsrs    r0, r0, #26

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    // Add the carry flag in to round
    //
    adc     r0, r0, r1, lsl #(32 - 26)

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
// _IQ27rmpy
//
//*****************************************************************************
    section CODE__IQ27rmpy:CODE(2)
    thumb
    export  _IQ27rmpy
_IQ27rmpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    // Also, update Carry flag to indicate whether or not to round
    //
    lsrs    r0, r0, #27

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    // Add the carry flag in to round
    //
    adc     r0, r0, r1, lsl #(32 - 27)

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
// _IQ28rmpy
//
//*****************************************************************************
    section CODE__IQ28rmpy:CODE(2)
    thumb
    export  _IQ28rmpy
_IQ28rmpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    // Also, update Carry flag to indicate whether or not to round
    //
    lsrs    r0, r0, #28

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    // Add the carry flag in to round
    //
    adc     r0, r0, r1, lsl #(32 - 28)

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
// _IQ29rmpy
//
//*****************************************************************************
    section CODE__IQ29rmpy:CODE(2)
    thumb
    export  _IQ29rmpy
_IQ29rmpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    // Also, update Carry flag to indicate whether or not to round
    //
    lsrs    r0, r0, #29

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    // Add the carry flag in to round
    //
    adc     r0, r0, r1, lsl #(32 - 29)

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
// _IQ30rmpy
//
//*****************************************************************************
    section CODE__IQ30rmpy:CODE(2)
    thumb
    export  _IQ30rmpy
_IQ30rmpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    // Also, update Carry flag to indicate whether or not to round
    //
    lsrs    r0, r0, #30

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    // Add the carry flag in to round
    //
    adc     r0, r0, r1, lsl #(32 - 30)

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

    end
