//*****************************************************************************
//
// IQint.S - Return integer portion of fixed point number.
//
// Copyright (c) 2010 Texas Instruments Incorporated.  All rights reserved.
// TI Information - Selective Disclosure
//
//*****************************************************************************

//*****************************************************************************
//
// Function:   _IQNint
//
//*****************************************************************************
//
// C Usage:    extern long _IQint(long A);   // no round or sat
//
//-----------------------------------------------------------------------------
//
// On Entry:   r0    = A in IQ format
//
// Regs Used:  r0
//
// On Exit:    r0    = integer portion of A stored as "long"
//
// Q range:    30 to 1
//
//-----------------------------------------------------------------------------
//
// Algorithm:  The integer portion of the IQ number is calculated
//             as follows:
//
//                integer = A >> q_value;
//			
//-----------------------------------------------------------------------------
//
// Benchmark:
//
// Cycles = 13 (includes LCR/LRETR)
//
//*****************************************************************************

//*****************************************************************************
//
// _IQ1int
//
//*****************************************************************************
    section CODE__IQ1int:CODE(2)
    thumb
    export  _IQ1int
_IQ1int
    //
    // Shift first operand by Q and update sign flags
    //
    asrs    r0, r0, #1

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
// _IQ2int
//
//*****************************************************************************
    section CODE__IQ2int:CODE(2)
    thumb
    export  _IQ2int
_IQ2int
    //
    // Shift first operand by Q and update sign flags
    //
    asrs    r0, r0, #2

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
// _IQ3int
//
//*****************************************************************************
    section CODE__IQ3int:CODE(2)
    thumb
    export  _IQ3int
_IQ3int
    //
    // Shift first operand by Q and update sign flags
    //
    asrs    r0, r0, #3

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
// _IQ4int
//
//*****************************************************************************
    section CODE__IQ4int:CODE(2)
    thumb
    export  _IQ4int
_IQ4int
    //
    // Shift first operand by Q and update sign flags
    //
    asrs    r0, r0, #4

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
// _IQ5int
//
//*****************************************************************************
    section CODE__IQ5int:CODE(2)
    thumb
    export  _IQ5int
_IQ5int
    //
    // Shift first operand by Q and update sign flags
    //
    asrs    r0, r0, #5

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
// _IQ6int
//
//*****************************************************************************
    section CODE__IQ6int:CODE(2)
    thumb
    export  _IQ6int
_IQ6int
    //
    // Shift first operand by Q and update sign flags
    //
    asrs    r0, r0, #6

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
// _IQ7int
//
//*****************************************************************************
    section CODE__IQ7int:CODE(2)
    thumb
    export  _IQ7int
_IQ7int
    //
    // Shift first operand by Q and update sign flags
    //
    asrs    r0, r0, #7

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
// _IQ8int
//
//*****************************************************************************
    section CODE__IQ8int:CODE(2)
    thumb
    export  _IQ8int
_IQ8int
    //
    // Shift first operand by Q and update sign flags
    //
    asrs    r0, r0, #8

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
// _IQ9int
//
//*****************************************************************************
    section CODE__IQ9int:CODE(2)
    thumb
    export  _IQ9int
_IQ9int
    //
    // Shift first operand by Q and update sign flags
    //
    asrs    r0, r0, #9

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
// _IQ10int
//
//*****************************************************************************
    section CODE__IQ10int:CODE(2)
    thumb
    export  _IQ10int
_IQ10int
    //
    // Shift first operand by Q and update sign flags
    //
    asrs    r0, r0, #10

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
// _IQ11int
//
//*****************************************************************************
    section CODE__IQ11int:CODE(2)
    thumb
    export  _IQ11int
_IQ11int
    //
    // Shift first operand by Q and update sign flags
    //
    asrs    r0, r0, #11

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
// _IQ12int
//
//*****************************************************************************
    section CODE__IQ12int:CODE(2)
    thumb
    export  _IQ12int
_IQ12int
    //
    // Shift first operand by Q and update sign flags
    //
    asrs    r0, r0, #12

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
// _IQ13int
//
//*****************************************************************************
    section CODE__IQ13int:CODE(2)
    thumb
    export  _IQ13int
_IQ13int
    //
    // Shift first operand by Q and update sign flags
    //
    asrs    r0, r0, #13

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
// _IQ14int
//
//*****************************************************************************
    section CODE__IQ14int:CODE(2)
    thumb
    export  _IQ14int
_IQ14int
    //
    // Shift first operand by Q and update sign flags
    //
    asrs    r0, r0, #14

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
// _IQ15int
//
//*****************************************************************************
    section CODE__IQ15int:CODE(2)
    thumb
    export  _IQ15int
_IQ15int
    //
    // Shift first operand by Q and update sign flags
    //
    asrs    r0, r0, #15

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
// _IQ16int
//
//*****************************************************************************
    section CODE__IQ16int:CODE(2)
    thumb
    export  _IQ16int
_IQ16int
    //
    // Shift first operand by Q and update sign flags
    //
    asrs    r0, r0, #16

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
// _IQ17int
//
//*****************************************************************************
    section CODE__IQ17int:CODE(2)
    thumb
    export  _IQ17int
_IQ17int
    //
    // Shift first operand by Q and update sign flags
    //
    asrs    r0, r0, #17

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
// _IQ18int
//
//*****************************************************************************
    section CODE__IQ18int:CODE(2)
    thumb
    export  _IQ18int
_IQ18int
    //
    // Shift first operand by Q and update sign flags
    //
    asrs    r0, r0, #18

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
// _IQ19int
//
//*****************************************************************************
    section CODE__IQ19int:CODE(2)
    thumb
    export  _IQ19int
_IQ19int
    //
    // Shift first operand by Q and update sign flags
    //
    asrs    r0, r0, #19

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
// _IQ20int
//
//*****************************************************************************
    section CODE__IQ20int:CODE(2)
    thumb
    export  _IQ20int
_IQ20int
    //
    // Shift first operand by Q and update sign flags
    //
    asrs    r0, r0, #20

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
// _IQ21int
//
//*****************************************************************************
    section CODE__IQ21int:CODE(2)
    thumb
    export  _IQ21int
_IQ21int
    //
    // Shift first operand by Q and update sign flags
    //
    asrs    r0, r0, #21

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
// _IQ22int
//
//*****************************************************************************
    section CODE__IQ22int:CODE(2)
    thumb
    export  _IQ22int
_IQ22int
    //
    // Shift first operand by Q and update sign flags
    //
    asrs    r0, r0, #22

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
// _IQ23int
//
//*****************************************************************************
    section CODE__IQ23int:CODE(2)
    thumb
    export  _IQ23int
_IQ23int
    //
    // Shift first operand by Q and update sign flags
    //
    asrs    r0, r0, #23

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
// _IQ24int
//
//*****************************************************************************
    section CODE__IQ24int:CODE(2)
    thumb
    export  _IQ24int
_IQ24int
    //
    // Shift first operand by Q and update sign flags
    //
    asrs    r0, r0, #24

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
// _IQ25int
//
//*****************************************************************************
    section CODE__IQ25int:CODE(2)
    thumb
    export  _IQ25int
_IQ25int
    //
    // Shift first operand by Q and update sign flags
    //
    asrs    r0, r0, #25

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
// _IQ26int
//
//*****************************************************************************
    section CODE__IQ26int:CODE(2)
    thumb
    export  _IQ26int
_IQ26int
    //
    // Shift first operand by Q and update sign flags
    //
    asrs    r0, r0, #26

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
// _IQ27int
//
//*****************************************************************************
    section CODE__IQ27int:CODE(2)
    thumb
    export  _IQ27int
_IQ27int
    //
    // Shift first operand by Q and update sign flags
    //
    asrs    r0, r0, #27

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
// _IQ28int
//
//*****************************************************************************
    section CODE__IQ28int:CODE(2)
    thumb
    export  _IQ28int
_IQ28int
    //
    // Shift first operand by Q and update sign flags
    //
    asrs    r0, r0, #28

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
// _IQ29int
//
//*****************************************************************************
    section CODE__IQ29int:CODE(2)
    thumb
    export  _IQ29int
_IQ29int
    //
    // Shift first operand by Q and update sign flags
    //
    asrs    r0, r0, #29

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
// _IQ30int
//
//*****************************************************************************
    section CODE__IQ30int:CODE(2)
    thumb
    export  _IQ30int
_IQ30int
    //
    // Shift first operand by Q and update sign flags
    //
    asrs    r0, r0, #30

    //
    // Return to the caller.
    //
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

    end
