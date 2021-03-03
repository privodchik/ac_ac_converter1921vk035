//*****************************************************************************
//
// IQmpy.S - Fixed point multiply
//
// Copyright (c) 2010 Texas Instruments Incorporated.  All rights reserved.
// TI Information - Selective Disclosure
//
//*****************************************************************************

//*****************************************************************************
//
// Function:   _IQNmpy
//
//*****************************************************************************
//
// C Usage:    extern long _IQmpy(long M, long X);   // no round or sat
//
//-----------------------------------------------------------------------------
//
// On Entry:   r0     = M in IQ format
//             r1     = X in IQ format
//
// Regs Used:  r0, r1
//
// On Exit:    r0     = M * X in IQ format
//
// Q range:    30 to 1
//
//-----------------------------------------------------------------------------
//
// Algorithm:  The IQmpy operation generates a 64-bit result. The 64-bit
//             number must then be scaled back to a 32-bit value with the
//             same Q value as the original inputs. For example: if Q = 27,
//             then the multiplication of two I5Q27 numbers results in the
//             following 64-bit value:
//
//                          I5Q27 * I5Q27 = I10Q54
//
//             The value is then scaled back to an I5Q27 value as follows:
//
//                          I5Q27 = I10Q54 >> Q
//
//             For some of the operations, the value is either rounded or
//             saturated (or both) to its maximum value before scaling.
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
// _IQ1mpy
//
//*****************************************************************************
    section CODE__IQ1mpy:CODE(2)
    thumb
    export  _IQ1mpy
_IQ1mpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    //
    lsr     r0, r0, #1

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    //
    add     r0, r0, r1, lsl #(32 - 1)

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
// _IQ2mpy
//
//*****************************************************************************
    section CODE__IQ2mpy:CODE(2)
    thumb
    export  _IQ2mpy
_IQ2mpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    //
    lsr     r0, r0, #2

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    //
    add     r0, r0, r1, lsl #(32 - 2)

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
// _IQ3mpy
//
//*****************************************************************************
    section CODE__IQ3mpy:CODE(2)
    thumb
    export  _IQ3mpy
_IQ3mpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    //
    lsr     r0, r0, #3

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    //
    add     r0, r0, r1, lsl #(32 - 3)

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
// _IQ4mpy
//
//*****************************************************************************
    section CODE__IQ4mpy:CODE(2)
    thumb
    export  _IQ4mpy
_IQ4mpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    //
    lsr     r0, r0, #4

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    //
    add     r0, r0, r1, lsl #(32 - 4)

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
// _IQ5mpy
//
//*****************************************************************************
    section CODE__IQ5mpy:CODE(2)
    thumb
    export  _IQ5mpy
_IQ5mpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    //
    lsr     r0, r0, #5

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    //
    add     r0, r0, r1, lsl #(32 - 5)

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
// _IQ6mpy
//
//*****************************************************************************
    section CODE__IQ6mpy:CODE(2)
    thumb
    export  _IQ6mpy
_IQ6mpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    //
    lsr     r0, r0, #6

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    //
    add     r0, r0, r1, lsl #(32 - 6)

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
// _IQ7mpy
//
//*****************************************************************************
    section CODE__IQ7mpy:CODE(2)
    thumb
    export  _IQ7mpy
_IQ7mpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    //
    lsr     r0, r0, #7

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    //
    add     r0, r0, r1, lsl #(32 - 7)

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
// _IQ8mpy
//
//*****************************************************************************
    section CODE__IQ8mpy:CODE(2)
    thumb
    export  _IQ8mpy
_IQ8mpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    //
    lsr     r0, r0, #8

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    //
    add     r0, r0, r1, lsl #(32 - 8)

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
// _IQ9mpy
//
//*****************************************************************************
    section CODE__IQ9mpy:CODE(2)
    thumb
    export  _IQ9mpy
_IQ9mpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    //
    lsr     r0, r0, #9

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    //
    add     r0, r0, r1, lsl #(32 - 9)

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
// _IQ10mpy
//
//*****************************************************************************
    section CODE__IQ10mpy:CODE(2)
    thumb
    export  _IQ10mpy
_IQ10mpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    //
    lsr     r0, r0, #10

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    //
    add     r0, r0, r1, lsl #(32 - 10)

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
// _IQ11mpy
//
//*****************************************************************************
    section CODE__IQ11mpy:CODE(2)
    thumb
    export  _IQ11mpy
_IQ11mpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    //
    lsr     r0, r0, #11

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    //
    add     r0, r0, r1, lsl #(32 - 11)

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
// _IQ12mpy
//
//*****************************************************************************
    section CODE__IQ12mpy:CODE(2)
    thumb
    export  _IQ12mpy
_IQ12mpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    //
    lsr     r0, r0, #12

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    //
    add     r0, r0, r1, lsl #(32 - 12)

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
// _IQ13mpy
//
//*****************************************************************************
    section CODE__IQ13mpy:CODE(2)
    thumb
    export  _IQ13mpy
_IQ13mpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    //
    lsr     r0, r0, #13

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    //
    add     r0, r0, r1, lsl #(32 - 13)

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
// _IQ14mpy
//
//*****************************************************************************
    section CODE__IQ14mpy:CODE(2)
    thumb
    export  _IQ14mpy
_IQ14mpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    //
    lsr     r0, r0, #14

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    //
    add     r0, r0, r1, lsl #(32 - 14)

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
// _IQ15mpy
//
//*****************************************************************************
    section CODE__IQ15mpy:CODE(2)
    thumb
    export  _IQ15mpy
_IQ15mpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    //
    lsr     r0, r0, #15

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    //
    add     r0, r0, r1, lsl #(32 - 15)

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
// _IQ16mpy
//
//*****************************************************************************
    section CODE__IQ16mpy:CODE(2)
    thumb
    export  _IQ16mpy
_IQ16mpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    //
    lsr     r0, r0, #16

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    //
    add     r0, r0, r1, lsl #(32 - 16)

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
// _IQ17mpy
//
//*****************************************************************************
    section CODE__IQ17mpy:CODE(2)
    thumb
    export  _IQ17mpy
_IQ17mpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    //
    lsr     r0, r0, #17

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    //
    add     r0, r0, r1, lsl #(32 - 17)

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
// _IQ18mpy
//
//*****************************************************************************
    section CODE__IQ18mpy:CODE(2)
    thumb
    export  _IQ18mpy
_IQ18mpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    //
    lsr     r0, r0, #18

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    //
    add     r0, r0, r1, lsl #(32 - 18)

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
// _IQ19mpy
//
//*****************************************************************************
    section CODE__IQ19mpy:CODE(2)
    thumb
    export  _IQ19mpy
_IQ19mpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    //
    lsr     r0, r0, #19

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    //
    add     r0, r0, r1, lsl #(32 - 19)

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
// _IQ20mpy
//
//*****************************************************************************
    section CODE__IQ20mpy:CODE(2)
    thumb
    export  _IQ20mpy
_IQ20mpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    //
    lsr     r0, r0, #20

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    //
    add     r0, r0, r1, lsl #(32 - 20)

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
// _IQ21mpy
//
//*****************************************************************************
    section CODE__IQ21mpy:CODE(2)
    thumb
    export  _IQ21mpy
_IQ21mpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    //
    lsr     r0, r0, #21

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    //
    add     r0, r0, r1, lsl #(32 - 21)

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
// _IQ22mpy
//
//*****************************************************************************
    section CODE__IQ22mpy:CODE(2)
    thumb
    export  _IQ22mpy
_IQ22mpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    //
    lsr     r0, r0, #22

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    //
    add     r0, r0, r1, lsl #(32 - 22)

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
// _IQ23mpy
//
//*****************************************************************************
    section CODE__IQ23mpy:CODE(2)
    thumb
    export  _IQ23mpy
_IQ23mpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    //
    lsr     r0, r0, #23

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    //
    add     r0, r0, r1, lsl #(32 - 23)

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
// _IQ24mpy
//
//*****************************************************************************
    section CODE__IQ24mpy:CODE(2)
    thumb
    export  _IQ24mpy
_IQ24mpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    //
    lsr     r0, r0, #24

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    //
    add     r0, r0, r1, lsl #(32 - 24)

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
// _IQ25mpy
//
//*****************************************************************************
    section CODE__IQ25mpy:CODE(2)
    thumb
    export  _IQ25mpy
_IQ25mpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    //
    lsr     r0, r0, #25

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    //
    add     r0, r0, r1, lsl #(32 - 25)

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
// _IQ26mpy
//
//*****************************************************************************
    section CODE__IQ26mpy:CODE(2)
    thumb
    export  _IQ26mpy
_IQ26mpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    //
    lsr     r0, r0, #26

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    //
    add     r0, r0, r1, lsl #(32 - 26)

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
// _IQ27mpy
//
//*****************************************************************************
    section CODE__IQ27mpy:CODE(2)
    thumb
    export  _IQ27mpy
_IQ27mpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    //
    lsr     r0, r0, #27

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    //
    add     r0, r0, r1, lsl #(32 - 27)

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
// _IQ28mpy
//
//*****************************************************************************
    section CODE__IQ28mpy:CODE(2)
    thumb
    export  _IQ28mpy
_IQ28mpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    //
    lsr     r0, r0, #28

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    //
    add     r0, r0, r1, lsl #(32 - 28)

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
// _IQ29mpy
//
//*****************************************************************************
    section CODE__IQ29mpy:CODE(2)
    thumb
    export  _IQ29mpy
_IQ29mpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    //
    lsr     r0, r0, #29

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    //
    add     r0, r0, r1, lsl #(32 - 29)

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
// _IQ30mpy
//
//*****************************************************************************
    section CODE__IQ30mpy:CODE(2)
    thumb
    export  _IQ30mpy
_IQ30mpy
    //
    // Perform a 32x32-> 64 bit signed multiply
    //
    smull   r0, r1, r0, r1

    //
    // Shift the lower 32 bits of the result down by Q
    //
    lsr     r0, r0, #30

    //
    // Shift the upper 32 by ~Q
    // Add the upper and lower bits together
    //
    add     r0, r0, r1, lsl #(32 - 30)

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

    end
