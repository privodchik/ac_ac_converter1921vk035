//*****************************************************************************
//
// IQtoD.S - Convert IQ to Double Precision Float
//
// Copyright (c) 2010 Texas Instruments Incorporated.  All rights reserved.
// TI Information - Selective Disclosure
//
//*****************************************************************************

//*****************************************************************************
//
// Function:   _IQNtoD
//
//*****************************************************************************
//
// C Usage:    extern double _IQtoD(long A);   // no round or sat
//
//-----------------------------------------------------------------------------
//
// On Entry:   ACC    = A in IQ format
//
// Regs Used:  XT, P
//
// On Exit:    {r0,r1} = IEEE 754 double precision floating-point
//                       equivalent of A
//
// Q range:    30 to 1
//
//-----------------------------------------------------------------------------
//
// Algorithm:  This operation converts an IQ number to the equivalent
//             IEEE 754 Double-Precision floating-point format. This
//             format is shown below:
//
//              63  62            52 51                            32
//              31  30            20 19                             0
//             +-----------------------------------------------------+
//      r1     | s |      e         |             f                  |
//             +-----------------------------------------------------+
//
//              31                                                  0
//             +-----------------------------------------------------+
//      r0     |                          f                          |
//             +-----------------------------------------------------+
//
//             Value = (-1)^s * 2^(e-1023) * 1.f
//
//             where: e = 1 to 2046, f = 0.000000000 to ~1.0
//                    e = 0, f = 0, s = 0, Value = 0.0
//                    e = 0 and f != 0 case cannot occur in IQmath
//                    e = 2047 case cannot occur in IQmath
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
// _IQ1toD
//
//*****************************************************************************
    section CODE__IQ1toD:CODE(2)
    thumb
    export  _IQ1toD
_IQ1toD
    //
    // The only special case to cover is if the operand is zero. All other
    // special cases can not be reached from IQmath, as they are unable to be
    // represented.
    //
    cbz     r0, r0isZero1

    //
    // Prepare working register r1 with sign
    // Take absolute value of input
    //
    ands    r1, r0, #0x80000000
        it      mi
        rsbmi   r0, r0, #0

    //
    // Prepare exponent portion in r3
    // This is calculated as follows:
    //    +1023 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(31 - 1)
    add     r2, r2, #1023

    //
    // Prepare normalized mantissa.
    //
    lsl     r12, r0, r3
    lsl     r0, r12, #21
    lsr     r12, r12, #11

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r12, r2, #20, #11

    //
    // OR Sign bit back into result.
    //
    orr     r1, r1, r12

    //
    // Return
    //
    bx      lr

    //
    // If the input is 0, the resulting response is {0,0}.  Since r0 is already
    // correct, only r1 needs to be modified.
    //
r0isZero1
    mov     r1, #0
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ2toD
//
//*****************************************************************************
    section CODE__IQ2toD:CODE(2)
    thumb
    export  _IQ2toD
_IQ2toD
    //
    // The only special case to cover is if the operand is zero. All other
    // special cases can not be reached from IQmath, as they are unable to be
    // represented.
    //
    cbz     r0, r0isZero2

    //
    // Prepare working register r1 with sign
    // Take absolute value of input
    //
    ands    r1, r0, #0x80000000
        it      mi
        rsbmi   r0, r0, #0

    //
    // Prepare exponent portion in r3
    // This is calculated as follows:
    //    +1023 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(31 - 2)
    add     r2, r2, #1023

    //
    // Prepare normalized mantissa.
    //
    lsl     r12, r0, r3
    lsl     r0, r12, #21
    lsr     r12, r12, #11

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r12, r2, #20, #11

    //
    // OR Sign bit back into result.
    //
    orr     r1, r1, r12

    //
    // Return
    //
    bx      lr

    //
    // If the input is 0, the resulting response is {0,0}.  Since r0 is already
    // correct, only r1 needs to be modified.
    //
r0isZero2
    mov     r1, #0
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ3toD
//
//*****************************************************************************
    section CODE__IQ3toD:CODE(2)
    thumb
    export  _IQ3toD
_IQ3toD
    //
    // The only special case to cover is if the operand is zero. All other
    // special cases can not be reached from IQmath, as they are unable to be
    // represented.
    //
    cbz     r0, r0isZero3

    //
    // Prepare working register r1 with sign
    // Take absolute value of input
    //
    ands    r1, r0, #0x80000000
        it      mi
        rsbmi   r0, r0, #0

    //
    // Prepare exponent portion in r3
    // This is calculated as follows:
    //    +1023 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(31 - 3)
    add     r2, r2, #1023

    //
    // Prepare normalized mantissa.
    //
    lsl     r12, r0, r3
    lsl     r0, r12, #21
    lsr     r12, r12, #11

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r12, r2, #20, #11

    //
    // OR Sign bit back into result.
    //
    orr     r1, r1, r12

    //
    // Return
    //
    bx      lr

    //
    // If the input is 0, the resulting response is {0,0}.  Since r0 is already
    // correct, only r1 needs to be modified.
    //
r0isZero3
    mov     r1, #0
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ4toD
//
//*****************************************************************************
    section CODE__IQ4toD:CODE(2)
    thumb
    export  _IQ4toD
_IQ4toD
    //
    // The only special case to cover is if the operand is zero. All other
    // special cases can not be reached from IQmath, as they are unable to be
    // represented.
    //
    cbz     r0, r0isZero4

    //
    // Prepare working register r1 with sign
    // Take absolute value of input
    //
    ands    r1, r0, #0x80000000
        it      mi
        rsbmi   r0, r0, #0

    //
    // Prepare exponent portion in r3
    // This is calculated as follows:
    //    +1023 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(31 - 4)
    add     r2, r2, #1023

    //
    // Prepare normalized mantissa.
    //
    lsl     r12, r0, r3
    lsl     r0, r12, #21
    lsr     r12, r12, #11

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r12, r2, #20, #11

    //
    // OR Sign bit back into result.
    //
    orr     r1, r1, r12

    //
    // Return
    //
    bx      lr

    //
    // If the input is 0, the resulting response is {0,0}.  Since r0 is already
    // correct, only r1 needs to be modified.
    //
r0isZero4
    mov     r1, #0
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ5toD
//
//*****************************************************************************
    section CODE__IQ5toD:CODE(2)
    thumb
    export  _IQ5toD
_IQ5toD
    //
    // The only special case to cover is if the operand is zero. All other
    // special cases can not be reached from IQmath, as they are unable to be
    // represented.
    //
    cbz     r0, r0isZero5

    //
    // Prepare working register r1 with sign
    // Take absolute value of input
    //
    ands    r1, r0, #0x80000000
        it      mi
        rsbmi   r0, r0, #0

    //
    // Prepare exponent portion in r3
    // This is calculated as follows:
    //    +1023 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(31 - 5)
    add     r2, r2, #1023

    //
    // Prepare normalized mantissa.
    //
    lsl     r12, r0, r3
    lsl     r0, r12, #21
    lsr     r12, r12, #11

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r12, r2, #20, #11

    //
    // OR Sign bit back into result.
    //
    orr     r1, r1, r12

    //
    // Return
    //
    bx      lr

    //
    // If the input is 0, the resulting response is {0,0}.  Since r0 is already
    // correct, only r1 needs to be modified.
    //
r0isZero5
    mov     r1, #0
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ6toD
//
//*****************************************************************************
    section CODE__IQ6toD:CODE(2)
    thumb
    export  _IQ6toD
_IQ6toD
    //
    // The only special case to cover is if the operand is zero. All other
    // special cases can not be reached from IQmath, as they are unable to be
    // represented.
    //
    cbz     r0, r0isZero6

    //
    // Prepare working register r1 with sign
    // Take absolute value of input
    //
    ands    r1, r0, #0x80000000
        it      mi
        rsbmi   r0, r0, #0

    //
    // Prepare exponent portion in r3
    // This is calculated as follows:
    //    +1023 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(31 - 6)
    add     r2, r2, #1023

    //
    // Prepare normalized mantissa.
    //
    lsl     r12, r0, r3
    lsl     r0, r12, #21
    lsr     r12, r12, #11

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r12, r2, #20, #11

    //
    // OR Sign bit back into result.
    //
    orr     r1, r1, r12

    //
    // Return
    //
    bx      lr

    //
    // If the input is 0, the resulting response is {0,0}.  Since r0 is already
    // correct, only r1 needs to be modified.
    //
r0isZero6
    mov     r1, #0
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ7toD
//
//*****************************************************************************
    section CODE__IQ7toD:CODE(2)
    thumb
    export  _IQ7toD
_IQ7toD
    //
    // The only special case to cover is if the operand is zero. All other
    // special cases can not be reached from IQmath, as they are unable to be
    // represented.
    //
    cbz     r0, r0isZero7

    //
    // Prepare working register r1 with sign
    // Take absolute value of input
    //
    ands    r1, r0, #0x80000000
        it      mi
        rsbmi   r0, r0, #0

    //
    // Prepare exponent portion in r3
    // This is calculated as follows:
    //    +1023 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(31 - 7)
    add     r2, r2, #1023

    //
    // Prepare normalized mantissa.
    //
    lsl     r12, r0, r3
    lsl     r0, r12, #21
    lsr     r12, r12, #11

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r12, r2, #20, #11

    //
    // OR Sign bit back into result.
    //
    orr     r1, r1, r12

    //
    // Return
    //
    bx      lr

    //
    // If the input is 0, the resulting response is {0,0}.  Since r0 is already
    // correct, only r1 needs to be modified.
    //
r0isZero7
    mov     r1, #0
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ8toD
//
//*****************************************************************************
    section CODE__IQ8toD:CODE(2)
    thumb
    export  _IQ8toD
_IQ8toD
    //
    // The only special case to cover is if the operand is zero. All other
    // special cases can not be reached from IQmath, as they are unable to be
    // represented.
    //
    cbz     r0, r0isZero8

    //
    // Prepare working register r1 with sign
    // Take absolute value of input
    //
    ands    r1, r0, #0x80000000
        it      mi
        rsbmi   r0, r0, #0

    //
    // Prepare exponent portion in r3
    // This is calculated as follows:
    //    +1023 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(31 - 8)
    add     r2, r2, #1023

    //
    // Prepare normalized mantissa.
    //
    lsl     r12, r0, r3
    lsl     r0, r12, #21
    lsr     r12, r12, #11

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r12, r2, #20, #11

    //
    // OR Sign bit back into result.
    //
    orr     r1, r1, r12

    //
    // Return
    //
    bx      lr

    //
    // If the input is 0, the resulting response is {0,0}.  Since r0 is already
    // correct, only r1 needs to be modified.
    //
r0isZero8
    mov     r1, #0
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ9toD
//
//*****************************************************************************
    section CODE__IQ9toD:CODE(2)
    thumb
    export  _IQ9toD
_IQ9toD
    //
    // The only special case to cover is if the operand is zero. All other
    // special cases can not be reached from IQmath, as they are unable to be
    // represented.
    //
    cbz     r0, r0isZero9

    //
    // Prepare working register r1 with sign
    // Take absolute value of input
    //
    ands    r1, r0, #0x80000000
        it      mi
        rsbmi   r0, r0, #0

    //
    // Prepare exponent portion in r3
    // This is calculated as follows:
    //    +1023 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(31 - 9)
    add     r2, r2, #1023

    //
    // Prepare normalized mantissa.
    //
    lsl     r12, r0, r3
    lsl     r0, r12, #21
    lsr     r12, r12, #11

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r12, r2, #20, #11

    //
    // OR Sign bit back into result.
    //
    orr     r1, r1, r12

    //
    // Return
    //
    bx      lr

    //
    // If the input is 0, the resulting response is {0,0}.  Since r0 is already
    // correct, only r1 needs to be modified.
    //
r0isZero9
    mov     r1, #0
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ10toD
//
//*****************************************************************************
    section CODE__IQ10toD:CODE(2)
    thumb
    export  _IQ10toD
_IQ10toD
    //
    // The only special case to cover is if the operand is zero. All other
    // special cases can not be reached from IQmath, as they are unable to be
    // represented.
    //
    cbz     r0, r0isZero10

    //
    // Prepare working register r1 with sign
    // Take absolute value of input
    //
    ands    r1, r0, #0x80000000
        it      mi
        rsbmi   r0, r0, #0

    //
    // Prepare exponent portion in r3
    // This is calculated as follows:
    //    +1023 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(31 - 10)
    add     r2, r2, #1023

    //
    // Prepare normalized mantissa.
    //
    lsl     r12, r0, r3
    lsl     r0, r12, #21
    lsr     r12, r12, #11

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r12, r2, #20, #11

    //
    // OR Sign bit back into result.
    //
    orr     r1, r1, r12

    //
    // Return
    //
    bx      lr

    //
    // If the input is 0, the resulting response is {0,0}.  Since r0 is already
    // correct, only r1 needs to be modified.
    //
r0isZero10
    mov     r1, #0
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ11toD
//
//*****************************************************************************
    section CODE__IQ11toD:CODE(2)
    thumb
    export  _IQ11toD
_IQ11toD
    //
    // The only special case to cover is if the operand is zero. All other
    // special cases can not be reached from IQmath, as they are unable to be
    // represented.
    //
    cbz     r0, r0isZero11

    //
    // Prepare working register r1 with sign
    // Take absolute value of input
    //
    ands    r1, r0, #0x80000000
        it      mi
        rsbmi   r0, r0, #0

    //
    // Prepare exponent portion in r3
    // This is calculated as follows:
    //    +1023 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(31 - 11)
    add     r2, r2, #1023

    //
    // Prepare normalized mantissa.
    //
    lsl     r12, r0, r3
    lsl     r0, r12, #21
    lsr     r12, r12, #11

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r12, r2, #20, #11

    //
    // OR Sign bit back into result.
    //
    orr     r1, r1, r12

    //
    // Return
    //
    bx      lr

    //
    // If the input is 0, the resulting response is {0,0}.  Since r0 is already
    // correct, only r1 needs to be modified.
    //
r0isZero11
    mov     r1, #0
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ12toD
//
//*****************************************************************************
    section CODE__IQ12toD:CODE(2)
    thumb
    export  _IQ12toD
_IQ12toD
    //
    // The only special case to cover is if the operand is zero. All other
    // special cases can not be reached from IQmath, as they are unable to be
    // represented.
    //
    cbz     r0, r0isZero12

    //
    // Prepare working register r1 with sign
    // Take absolute value of input
    //
    ands    r1, r0, #0x80000000
        it      mi
        rsbmi   r0, r0, #0

    //
    // Prepare exponent portion in r3
    // This is calculated as follows:
    //    +1023 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(31 - 12)
    add     r2, r2, #1023

    //
    // Prepare normalized mantissa.
    //
    lsl     r12, r0, r3
    lsl     r0, r12, #21
    lsr     r12, r12, #11

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r12, r2, #20, #11

    //
    // OR Sign bit back into result.
    //
    orr     r1, r1, r12

    //
    // Return
    //
    bx      lr

    //
    // If the input is 0, the resulting response is {0,0}.  Since r0 is already
    // correct, only r1 needs to be modified.
    //
r0isZero12
    mov     r1, #0
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ13toD
//
//*****************************************************************************
    section CODE__IQ13toD:CODE(2)
    thumb
    export  _IQ13toD
_IQ13toD
    //
    // The only special case to cover is if the operand is zero. All other
    // special cases can not be reached from IQmath, as they are unable to be
    // represented.
    //
    cbz     r0, r0isZero13

    //
    // Prepare working register r1 with sign
    // Take absolute value of input
    //
    ands    r1, r0, #0x80000000
        it      mi
        rsbmi   r0, r0, #0

    //
    // Prepare exponent portion in r3
    // This is calculated as follows:
    //    +1023 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(31 - 13)
    add     r2, r2, #1023

    //
    // Prepare normalized mantissa.
    //
    lsl     r12, r0, r3
    lsl     r0, r12, #21
    lsr     r12, r12, #11

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r12, r2, #20, #11

    //
    // OR Sign bit back into result.
    //
    orr     r1, r1, r12

    //
    // Return
    //
    bx      lr

    //
    // If the input is 0, the resulting response is {0,0}.  Since r0 is already
    // correct, only r1 needs to be modified.
    //
r0isZero13
    mov     r1, #0
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ14toD
//
//*****************************************************************************
    section CODE__IQ14toD:CODE(2)
    thumb
    export  _IQ14toD
_IQ14toD
    //
    // The only special case to cover is if the operand is zero. All other
    // special cases can not be reached from IQmath, as they are unable to be
    // represented.
    //
    cbz     r0, r0isZero14

    //
    // Prepare working register r1 with sign
    // Take absolute value of input
    //
    ands    r1, r0, #0x80000000
        it      mi
        rsbmi   r0, r0, #0

    //
    // Prepare exponent portion in r3
    // This is calculated as follows:
    //    +1023 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(31 - 14)
    add     r2, r2, #1023

    //
    // Prepare normalized mantissa.
    //
    lsl     r12, r0, r3
    lsl     r0, r12, #21
    lsr     r12, r12, #11

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r12, r2, #20, #11

    //
    // OR Sign bit back into result.
    //
    orr     r1, r1, r12

    //
    // Return
    //
    bx      lr

    //
    // If the input is 0, the resulting response is {0,0}.  Since r0 is already
    // correct, only r1 needs to be modified.
    //
r0isZero14
    mov     r1, #0
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ15toD
//
//*****************************************************************************
    section CODE__IQ15toD:CODE(2)
    thumb
    export  _IQ15toD
_IQ15toD
    //
    // The only special case to cover is if the operand is zero. All other
    // special cases can not be reached from IQmath, as they are unable to be
    // represented.
    //
    cbz     r0, r0isZero15

    //
    // Prepare working register r1 with sign
    // Take absolute value of input
    //
    ands    r1, r0, #0x80000000
        it      mi
        rsbmi   r0, r0, #0

    //
    // Prepare exponent portion in r3
    // This is calculated as follows:
    //    +1023 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(31 - 15)
    add     r2, r2, #1023

    //
    // Prepare normalized mantissa.
    //
    lsl     r12, r0, r3
    lsl     r0, r12, #21
    lsr     r12, r12, #11

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r12, r2, #20, #11

    //
    // OR Sign bit back into result.
    //
    orr     r1, r1, r12

    //
    // Return
    //
    bx      lr

    //
    // If the input is 0, the resulting response is {0,0}.  Since r0 is already
    // correct, only r1 needs to be modified.
    //
r0isZero15
    mov     r1, #0
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ16toD
//
//*****************************************************************************
    section CODE__IQ16toD:CODE(2)
    thumb
    export  _IQ16toD
_IQ16toD
    //
    // The only special case to cover is if the operand is zero. All other
    // special cases can not be reached from IQmath, as they are unable to be
    // represented.
    //
    cbz     r0, r0isZero16

    //
    // Prepare working register r1 with sign
    // Take absolute value of input
    //
    ands    r1, r0, #0x80000000
        it      mi
        rsbmi   r0, r0, #0

    //
    // Prepare exponent portion in r3
    // This is calculated as follows:
    //    +1023 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(31 - 16)
    add     r2, r2, #1023

    //
    // Prepare normalized mantissa.
    //
    lsl     r12, r0, r3
    lsl     r0, r12, #21
    lsr     r12, r12, #11

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r12, r2, #20, #11

    //
    // OR Sign bit back into result.
    //
    orr     r1, r1, r12

    //
    // Return
    //
    bx      lr

    //
    // If the input is 0, the resulting response is {0,0}.  Since r0 is already
    // correct, only r1 needs to be modified.
    //
r0isZero16
    mov     r1, #0
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ17toD
//
//*****************************************************************************
    section CODE__IQ17toD:CODE(2)
    thumb
    export  _IQ17toD
_IQ17toD
    //
    // The only special case to cover is if the operand is zero. All other
    // special cases can not be reached from IQmath, as they are unable to be
    // represented.
    //
    cbz     r0, r0isZero17

    //
    // Prepare working register r1 with sign
    // Take absolute value of input
    //
    ands    r1, r0, #0x80000000
        it      mi
        rsbmi   r0, r0, #0

    //
    // Prepare exponent portion in r3
    // This is calculated as follows:
    //    +1023 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(31 - 17)
    add     r2, r2, #1023

    //
    // Prepare normalized mantissa.
    //
    lsl     r12, r0, r3
    lsl     r0, r12, #21
    lsr     r12, r12, #11

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r12, r2, #20, #11

    //
    // OR Sign bit back into result.
    //
    orr     r1, r1, r12

    //
    // Return
    //
    bx      lr

    //
    // If the input is 0, the resulting response is {0,0}.  Since r0 is already
    // correct, only r1 needs to be modified.
    //
r0isZero17
    mov     r1, #0
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ18toD
//
//*****************************************************************************
    section CODE__IQ18toD:CODE(2)
    thumb
    export  _IQ18toD
_IQ18toD
    //
    // The only special case to cover is if the operand is zero. All other
    // special cases can not be reached from IQmath, as they are unable to be
    // represented.
    //
    cbz     r0, r0isZero18

    //
    // Prepare working register r1 with sign
    // Take absolute value of input
    //
    ands    r1, r0, #0x80000000
        it      mi
        rsbmi   r0, r0, #0

    //
    // Prepare exponent portion in r3
    // This is calculated as follows:
    //    +1023 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(31 - 18)
    add     r2, r2, #1023

    //
    // Prepare normalized mantissa.
    //
    lsl     r12, r0, r3
    lsl     r0, r12, #21
    lsr     r12, r12, #11

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r12, r2, #20, #11

    //
    // OR Sign bit back into result.
    //
    orr     r1, r1, r12

    //
    // Return
    //
    bx      lr

    //
    // If the input is 0, the resulting response is {0,0}.  Since r0 is already
    // correct, only r1 needs to be modified.
    //
r0isZero18
    mov     r1, #0
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ19toD
//
//*****************************************************************************
    section CODE__IQ19toD:CODE(2)
    thumb
    export  _IQ19toD
_IQ19toD
    //
    // The only special case to cover is if the operand is zero. All other
    // special cases can not be reached from IQmath, as they are unable to be
    // represented.
    //
    cbz     r0, r0isZero19

    //
    // Prepare working register r1 with sign
    // Take absolute value of input
    //
    ands    r1, r0, #0x80000000
        it      mi
        rsbmi   r0, r0, #0

    //
    // Prepare exponent portion in r3
    // This is calculated as follows:
    //    +1023 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(31 - 19)
    add     r2, r2, #1023

    //
    // Prepare normalized mantissa.
    //
    lsl     r12, r0, r3
    lsl     r0, r12, #21
    lsr     r12, r12, #11

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r12, r2, #20, #11

    //
    // OR Sign bit back into result.
    //
    orr     r1, r1, r12

    //
    // Return
    //
    bx      lr

    //
    // If the input is 0, the resulting response is {0,0}.  Since r0 is already
    // correct, only r1 needs to be modified.
    //
r0isZero19
    mov     r1, #0
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ20toD
//
//*****************************************************************************
    section CODE__IQ20toD:CODE(2)
    thumb
    export  _IQ20toD
_IQ20toD
    //
    // The only special case to cover is if the operand is zero. All other
    // special cases can not be reached from IQmath, as they are unable to be
    // represented.
    //
    cbz     r0, r0isZero20

    //
    // Prepare working register r1 with sign
    // Take absolute value of input
    //
    ands    r1, r0, #0x80000000
        it      mi
        rsbmi   r0, r0, #0

    //
    // Prepare exponent portion in r3
    // This is calculated as follows:
    //    +1023 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(31 - 20)
    add     r2, r2, #1023

    //
    // Prepare normalized mantissa.
    //
    lsl     r12, r0, r3
    lsl     r0, r12, #21
    lsr     r12, r12, #11

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r12, r2, #20, #11

    //
    // OR Sign bit back into result.
    //
    orr     r1, r1, r12

    //
    // Return
    //
    bx      lr

    //
    // If the input is 0, the resulting response is {0,0}.  Since r0 is already
    // correct, only r1 needs to be modified.
    //
r0isZero20
    mov     r1, #0
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ21toD
//
//*****************************************************************************
    section CODE__IQ21toD:CODE(2)
    thumb
    export  _IQ21toD
_IQ21toD
    //
    // The only special case to cover is if the operand is zero. All other
    // special cases can not be reached from IQmath, as they are unable to be
    // represented.
    //
    cbz     r0, r0isZero21

    //
    // Prepare working register r1 with sign
    // Take absolute value of input
    //
    ands    r1, r0, #0x80000000
        it      mi
        rsbmi   r0, r0, #0

    //
    // Prepare exponent portion in r3
    // This is calculated as follows:
    //    +1023 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(31 - 21)
    add     r2, r2, #1023

    //
    // Prepare normalized mantissa.
    //
    lsl     r12, r0, r3
    lsl     r0, r12, #21
    lsr     r12, r12, #11

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r12, r2, #20, #11

    //
    // OR Sign bit back into result.
    //
    orr     r1, r1, r12

    //
    // Return
    //
    bx      lr

    //
    // If the input is 0, the resulting response is {0,0}.  Since r0 is already
    // correct, only r1 needs to be modified.
    //
r0isZero21
    mov     r1, #0
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ22toD
//
//*****************************************************************************
    section CODE__IQ22toD:CODE(2)
    thumb
    export  _IQ22toD
_IQ22toD
    //
    // The only special case to cover is if the operand is zero. All other
    // special cases can not be reached from IQmath, as they are unable to be
    // represented.
    //
    cbz     r0, r0isZero22

    //
    // Prepare working register r1 with sign
    // Take absolute value of input
    //
    ands    r1, r0, #0x80000000
        it      mi
        rsbmi   r0, r0, #0

    //
    // Prepare exponent portion in r3
    // This is calculated as follows:
    //    +1023 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(31 - 22)
    add     r2, r2, #1023

    //
    // Prepare normalized mantissa.
    //
    lsl     r12, r0, r3
    lsl     r0, r12, #21
    lsr     r12, r12, #11

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r12, r2, #20, #11

    //
    // OR Sign bit back into result.
    //
    orr     r1, r1, r12

    //
    // Return
    //
    bx      lr

    //
    // If the input is 0, the resulting response is {0,0}.  Since r0 is already
    // correct, only r1 needs to be modified.
    //
r0isZero22
    mov     r1, #0
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ23toD
//
//*****************************************************************************
    section CODE__IQ23toD:CODE(2)
    thumb
    export  _IQ23toD
_IQ23toD
    //
    // The only special case to cover is if the operand is zero. All other
    // special cases can not be reached from IQmath, as they are unable to be
    // represented.
    //
    cbz     r0, r0isZero23

    //
    // Prepare working register r1 with sign
    // Take absolute value of input
    //
    ands    r1, r0, #0x80000000
        it      mi
        rsbmi   r0, r0, #0

    //
    // Prepare exponent portion in r3
    // This is calculated as follows:
    //    +1023 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(31 - 23)
    add     r2, r2, #1023

    //
    // Prepare normalized mantissa.
    //
    lsl     r12, r0, r3
    lsl     r0, r12, #21
    lsr     r12, r12, #11

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r12, r2, #20, #11

    //
    // OR Sign bit back into result.
    //
    orr     r1, r1, r12

    //
    // Return
    //
    bx      lr

    //
    // If the input is 0, the resulting response is {0,0}.  Since r0 is already
    // correct, only r1 needs to be modified.
    //
r0isZero23
    mov     r1, #0
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ24toD
//
//*****************************************************************************
    section CODE__IQ24toD:CODE(2)
    thumb
    export  _IQ24toD
_IQ24toD
    //
    // The only special case to cover is if the operand is zero. All other
    // special cases can not be reached from IQmath, as they are unable to be
    // represented.
    //
    cbz     r0, r0isZero24

    //
    // Prepare working register r1 with sign
    // Take absolute value of input
    //
    ands    r1, r0, #0x80000000
        it      mi
        rsbmi   r0, r0, #0

    //
    // Prepare exponent portion in r3
    // This is calculated as follows:
    //    +1023 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(31 - 24)
    add     r2, r2, #1023

    //
    // Prepare normalized mantissa.
    //
    lsl     r12, r0, r3
    lsl     r0, r12, #21
    lsr     r12, r12, #11

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r12, r2, #20, #11

    //
    // OR Sign bit back into result.
    //
    orr     r1, r1, r12

    //
    // Return
    //
    bx      lr

    //
    // If the input is 0, the resulting response is {0,0}.  Since r0 is already
    // correct, only r1 needs to be modified.
    //
r0isZero24
    mov     r1, #0
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ25toD
//
//*****************************************************************************
    section CODE__IQ25toD:CODE(2)
    thumb
    export  _IQ25toD
_IQ25toD
    //
    // The only special case to cover is if the operand is zero. All other
    // special cases can not be reached from IQmath, as they are unable to be
    // represented.
    //
    cbz     r0, r0isZero25

    //
    // Prepare working register r1 with sign
    // Take absolute value of input
    //
    ands    r1, r0, #0x80000000
        it      mi
        rsbmi   r0, r0, #0

    //
    // Prepare exponent portion in r3
    // This is calculated as follows:
    //    +1023 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(31 - 25)
    add     r2, r2, #1023

    //
    // Prepare normalized mantissa.
    //
    lsl     r12, r0, r3
    lsl     r0, r12, #21
    lsr     r12, r12, #11

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r12, r2, #20, #11

    //
    // OR Sign bit back into result.
    //
    orr     r1, r1, r12

    //
    // Return
    //
    bx      lr

    //
    // If the input is 0, the resulting response is {0,0}.  Since r0 is already
    // correct, only r1 needs to be modified.
    //
r0isZero25
    mov     r1, #0
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ26toD
//
//*****************************************************************************
    section CODE__IQ26toD:CODE(2)
    thumb
    export  _IQ26toD
_IQ26toD
    //
    // The only special case to cover is if the operand is zero. All other
    // special cases can not be reached from IQmath, as they are unable to be
    // represented.
    //
    cbz     r0, r0isZero26

    //
    // Prepare working register r1 with sign
    // Take absolute value of input
    //
    ands    r1, r0, #0x80000000
        it      mi
        rsbmi   r0, r0, #0

    //
    // Prepare exponent portion in r3
    // This is calculated as follows:
    //    +1023 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(31 - 26)
    add     r2, r2, #1023

    //
    // Prepare normalized mantissa.
    //
    lsl     r12, r0, r3
    lsl     r0, r12, #21
    lsr     r12, r12, #11

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r12, r2, #20, #11

    //
    // OR Sign bit back into result.
    //
    orr     r1, r1, r12

    //
    // Return
    //
    bx      lr

    //
    // If the input is 0, the resulting response is {0,0}.  Since r0 is already
    // correct, only r1 needs to be modified.
    //
r0isZero26
    mov     r1, #0
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ27toD
//
//*****************************************************************************
    section CODE__IQ27toD:CODE(2)
    thumb
    export  _IQ27toD
_IQ27toD
    //
    // The only special case to cover is if the operand is zero. All other
    // special cases can not be reached from IQmath, as they are unable to be
    // represented.
    //
    cbz     r0, r0isZero27

    //
    // Prepare working register r1 with sign
    // Take absolute value of input
    //
    ands    r1, r0, #0x80000000
        it      mi
        rsbmi   r0, r0, #0

    //
    // Prepare exponent portion in r3
    // This is calculated as follows:
    //    +1023 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(31 - 27)
    add     r2, r2, #1023

    //
    // Prepare normalized mantissa.
    //
    lsl     r12, r0, r3
    lsl     r0, r12, #21
    lsr     r12, r12, #11

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r12, r2, #20, #11

    //
    // OR Sign bit back into result.
    //
    orr     r1, r1, r12

    //
    // Return
    //
    bx      lr

    //
    // If the input is 0, the resulting response is {0,0}.  Since r0 is already
    // correct, only r1 needs to be modified.
    //
r0isZero27
    mov     r1, #0
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ28toD
//
//*****************************************************************************
    section CODE__IQ28toD:CODE(2)
    thumb
    export  _IQ28toD
_IQ28toD
    //
    // The only special case to cover is if the operand is zero. All other
    // special cases can not be reached from IQmath, as they are unable to be
    // represented.
    //
    cbz     r0, r0isZero28

    //
    // Prepare working register r1 with sign
    // Take absolute value of input
    //
    ands    r1, r0, #0x80000000
        it      mi
        rsbmi   r0, r0, #0

    //
    // Prepare exponent portion in r3
    // This is calculated as follows:
    //    +1023 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(31 - 28)
    add     r2, r2, #1023

    //
    // Prepare normalized mantissa.
    //
    lsl     r12, r0, r3
    lsl     r0, r12, #21
    lsr     r12, r12, #11

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r12, r2, #20, #11

    //
    // OR Sign bit back into result.
    //
    orr     r1, r1, r12

    //
    // Return
    //
    bx      lr

    //
    // If the input is 0, the resulting response is {0,0}.  Since r0 is already
    // correct, only r1 needs to be modified.
    //
r0isZero28
    mov     r1, #0
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ29toD
//
//*****************************************************************************
    section CODE__IQ29toD:CODE(2)
    thumb
    export  _IQ29toD
_IQ29toD
    //
    // The only special case to cover is if the operand is zero. All other
    // special cases can not be reached from IQmath, as they are unable to be
    // represented.
    //
    cbz     r0, r0isZero29

    //
    // Prepare working register r1 with sign
    // Take absolute value of input
    //
    ands    r1, r0, #0x80000000
        it      mi
        rsbmi   r0, r0, #0

    //
    // Prepare exponent portion in r3
    // This is calculated as follows:
    //    +1023 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(31 - 29)
    add     r2, r2, #1023

    //
    // Prepare normalized mantissa.
    //
    lsl     r12, r0, r3
    lsl     r0, r12, #21
    lsr     r12, r12, #11

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r12, r2, #20, #11

    //
    // OR Sign bit back into result.
    //
    orr     r1, r1, r12

    //
    // Return
    //
    bx      lr

    //
    // If the input is 0, the resulting response is {0,0}.  Since r0 is already
    // correct, only r1 needs to be modified.
    //
r0isZero29
    mov     r1, #0
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ30toD
//
//*****************************************************************************
    section CODE__IQ30toD:CODE(2)
    thumb
    export  _IQ30toD
_IQ30toD
    //
    // The only special case to cover is if the operand is zero. All other
    // special cases can not be reached from IQmath, as they are unable to be
    // represented.
    //
    cbz     r0, r0isZero30

    //
    // Prepare working register r1 with sign
    // Take absolute value of input
    //
    ands    r1, r0, #0x80000000
        it      mi
        rsbmi   r0, r0, #0

    //
    // Prepare exponent portion in r3
    // This is calculated as follows:
    //    +1023 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(31 - 30)
    add     r2, r2, #1023

    //
    // Prepare normalized mantissa.
    //
    lsl     r12, r0, r3
    lsl     r0, r12, #21
    lsr     r12, r12, #11

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r12, r2, #20, #11

    //
    // OR Sign bit back into result.
    //
    orr     r1, r1, r12

    //
    // Return
    //
    bx      lr

    //
    // If the input is 0, the resulting response is {0,0}.  Since r0 is already
    // correct, only r1 needs to be modified.
    //
r0isZero30
    mov     r1, #0
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

    end
