//*****************************************************************************
//
// IQtoF.S - Convert IQ to Single Precision Float
//
// Copyright (c) 2010 Texas Instruments Incorporated.  All rights reserved.
// TI Information - Selective Disclosure
//
//*****************************************************************************

//*****************************************************************************
//
// Function:   _IQNtoF
//
//*****************************************************************************
//
// C Usage:    extern float _IQtoF(long A);   // no round or sat
//
//-----------------------------------------------------------------------------
//
// On Entry:   ACC    = A in IQ format
//
// Regs Used:  XT, P
//
// On Exit:    ACC    = IEEE 754 floating-point equivalent of A
//
// Q range:    30 to 1
//
//-----------------------------------------------------------------------------
//
// Algorithm:  This operation converts an IQ number to the equivalent
//             IEEE 754 Single-Precision floating-point format. This
//             format is shown below:
//
//              31  30        23 22                                 0
//             +-----------------------------------------------------+
//             | s |      e     |                 f                  |
//             +-----------------------------------------------------+
//
//             Value = (-1)^s * 2^(e-127) * 1.f
//
//             where: e = 1 to 254, f = 0.000000000 to ~1.0
//                    e = 0, f = 0, s = 0, Value = 0.0
//                    e = 0 and f != 0 case cannot occur in IQmath
//                    e = 255 case cannot occur in IQmath
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
// _IQ1toF
//
//*****************************************************************************
    section CODE__IQ1toF:CODE(2)
    thumb
    export  _IQ1toF
_IQ1toF
    //
    // The only special case to cover is if the operand is zero.
    // In this case, we simply return - r0 is already appropriately set.
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
    //    +127 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(127 + 31 - 1)

    //
    // Prepare normalized mantissa.
    //
    lsl     r0, r0, r3
    lsr     r0, r0, #8

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r0, r2, #23, #8

    //
    // OR Sign bit back into result.
    //
    orr     r0, r1, r0

    //
    // Return to the caller.
    //
r0isZero1
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ2toF
//
//*****************************************************************************
    section CODE__IQ2toF:CODE(2)
    thumb
    export  _IQ2toF
_IQ2toF
    //
    // The only special case to cover is if the operand is zero.
    // In this case, we simply return - r0 is already appropriately set.
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
    //    +127 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(127 + 31 - 2)

    //
    // Prepare normalized mantissa.
    //
    lsl     r0, r0, r3
    lsr     r0, r0, #8

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r0, r2, #23, #8

    //
    // OR Sign bit back into result.
    //
    orr     r0, r1, r0

    //
    // Return to the caller.
    //
r0isZero2
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ3toF
//
//*****************************************************************************
    section CODE__IQ3toF:CODE(2)
    thumb
    export  _IQ3toF
_IQ3toF
    //
    // The only special case to cover is if the operand is zero.
    // In this case, we simply return - r0 is already appropriately set.
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
    //    +127 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(127 + 31 - 3)

    //
    // Prepare normalized mantissa.
    //
    lsl     r0, r0, r3
    lsr     r0, r0, #8

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r0, r2, #23, #8

    //
    // OR Sign bit back into result.
    //
    orr     r0, r1, r0

    //
    // Return to the caller.
    //
r0isZero3
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ4toF
//
//*****************************************************************************
    section CODE__IQ4toF:CODE(2)
    thumb
    export  _IQ4toF
_IQ4toF
    //
    // The only special case to cover is if the operand is zero.
    // In this case, we simply return - r0 is already appropriately set.
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
    //    +127 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(127 + 31 - 4)

    //
    // Prepare normalized mantissa.
    //
    lsl     r0, r0, r3
    lsr     r0, r0, #8

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r0, r2, #23, #8

    //
    // OR Sign bit back into result.
    //
    orr     r0, r1, r0

    //
    // Return to the caller.
    //
r0isZero4
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ5toF
//
//*****************************************************************************
    section CODE__IQ5toF:CODE(2)
    thumb
    export  _IQ5toF
_IQ5toF
    //
    // The only special case to cover is if the operand is zero.
    // In this case, we simply return - r0 is already appropriately set.
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
    //    +127 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(127 + 31 - 5)

    //
    // Prepare normalized mantissa.
    //
    lsl     r0, r0, r3
    lsr     r0, r0, #8

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r0, r2, #23, #8

    //
    // OR Sign bit back into result.
    //
    orr     r0, r1, r0

    //
    // Return to the caller.
    //
r0isZero5
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ6toF
//
//*****************************************************************************
    section CODE__IQ6toF:CODE(2)
    thumb
    export  _IQ6toF
_IQ6toF
    //
    // The only special case to cover is if the operand is zero.
    // In this case, we simply return - r0 is already appropriately set.
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
    //    +127 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(127 + 31 - 6)

    //
    // Prepare normalized mantissa.
    //
    lsl     r0, r0, r3
    lsr     r0, r0, #8

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r0, r2, #23, #8

    //
    // OR Sign bit back into result.
    //
    orr     r0, r1, r0

    //
    // Return to the caller.
    //
r0isZero6
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ7toF
//
//*****************************************************************************
    section CODE__IQ7toF:CODE(2)
    thumb
    export  _IQ7toF
_IQ7toF
    //
    // The only special case to cover is if the operand is zero.
    // In this case, we simply return - r0 is already appropriately set.
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
    //    +127 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(127 + 31 - 7)

    //
    // Prepare normalized mantissa.
    //
    lsl     r0, r0, r3
    lsr     r0, r0, #8

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r0, r2, #23, #8

    //
    // OR Sign bit back into result.
    //
    orr     r0, r1, r0

    //
    // Return to the caller.
    //
r0isZero7
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ8toF
//
//*****************************************************************************
    section CODE__IQ8toF:CODE(2)
    thumb
    export  _IQ8toF
_IQ8toF
    //
    // The only special case to cover is if the operand is zero.
    // In this case, we simply return - r0 is already appropriately set.
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
    //    +127 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(127 + 31 - 8)

    //
    // Prepare normalized mantissa.
    //
    lsl     r0, r0, r3
    lsr     r0, r0, #8

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r0, r2, #23, #8

    //
    // OR Sign bit back into result.
    //
    orr     r0, r1, r0

    //
    // Return to the caller.
    //
r0isZero8
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ9toF
//
//*****************************************************************************
    section CODE__IQ9toF:CODE(2)
    thumb
    export  _IQ9toF
_IQ9toF
    //
    // The only special case to cover is if the operand is zero.
    // In this case, we simply return - r0 is already appropriately set.
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
    //    +127 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(127 + 31 - 9)

    //
    // Prepare normalized mantissa.
    //
    lsl     r0, r0, r3
    lsr     r0, r0, #8

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r0, r2, #23, #8

    //
    // OR Sign bit back into result.
    //
    orr     r0, r1, r0

    //
    // Return to the caller.
    //
r0isZero9
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ10toF
//
//*****************************************************************************
    section CODE__IQ10toF:CODE(2)
    thumb
    export  _IQ10toF
_IQ10toF
    //
    // The only special case to cover is if the operand is zero.
    // In this case, we simply return - r0 is already appropriately set.
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
    //    +127 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(127 + 31 - 10)

    //
    // Prepare normalized mantissa.
    //
    lsl     r0, r0, r3
    lsr     r0, r0, #8

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r0, r2, #23, #8

    //
    // OR Sign bit back into result.
    //
    orr     r0, r1, r0

    //
    // Return to the caller.
    //
r0isZero10
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ11toF
//
//*****************************************************************************
    section CODE__IQ11toF:CODE(2)
    thumb
    export  _IQ11toF
_IQ11toF
    //
    // The only special case to cover is if the operand is zero.
    // In this case, we simply return - r0 is already appropriately set.
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
    //    +127 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(127 + 31 - 11)

    //
    // Prepare normalized mantissa.
    //
    lsl     r0, r0, r3
    lsr     r0, r0, #8

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r0, r2, #23, #8

    //
    // OR Sign bit back into result.
    //
    orr     r0, r1, r0

    //
    // Return to the caller.
    //
r0isZero11
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ12toF
//
//*****************************************************************************
    section CODE__IQ12toF:CODE(2)
    thumb
    export  _IQ12toF
_IQ12toF
    //
    // The only special case to cover is if the operand is zero.
    // In this case, we simply return - r0 is already appropriately set.
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
    //    +127 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(127 + 31 - 12)

    //
    // Prepare normalized mantissa.
    //
    lsl     r0, r0, r3
    lsr     r0, r0, #8

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r0, r2, #23, #8

    //
    // OR Sign bit back into result.
    //
    orr     r0, r1, r0

    //
    // Return to the caller.
    //
r0isZero12
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ13toF
//
//*****************************************************************************
    section CODE__IQ13toF:CODE(2)
    thumb
    export  _IQ13toF
_IQ13toF
    //
    // The only special case to cover is if the operand is zero.
    // In this case, we simply return - r0 is already appropriately set.
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
    //    +127 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(127 + 31 - 13)

    //
    // Prepare normalized mantissa.
    //
    lsl     r0, r0, r3
    lsr     r0, r0, #8

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r0, r2, #23, #8

    //
    // OR Sign bit back into result.
    //
    orr     r0, r1, r0

    //
    // Return to the caller.
    //
r0isZero13
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ14toF
//
//*****************************************************************************
    section CODE__IQ14toF:CODE(2)
    thumb
    export  _IQ14toF
_IQ14toF
    //
    // The only special case to cover is if the operand is zero.
    // In this case, we simply return - r0 is already appropriately set.
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
    //    +127 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(127 + 31 - 14)

    //
    // Prepare normalized mantissa.
    //
    lsl     r0, r0, r3
    lsr     r0, r0, #8

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r0, r2, #23, #8

    //
    // OR Sign bit back into result.
    //
    orr     r0, r1, r0

    //
    // Return to the caller.
    //
r0isZero14
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ15toF
//
//*****************************************************************************
    section CODE__IQ15toF:CODE(2)
    thumb
    export  _IQ15toF
_IQ15toF
    //
    // The only special case to cover is if the operand is zero.
    // In this case, we simply return - r0 is already appropriately set.
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
    //    +127 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(127 + 31 - 15)

    //
    // Prepare normalized mantissa.
    //
    lsl     r0, r0, r3
    lsr     r0, r0, #8

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r0, r2, #23, #8

    //
    // OR Sign bit back into result.
    //
    orr     r0, r1, r0

    //
    // Return to the caller.
    //
r0isZero15
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ16toF
//
//*****************************************************************************
    section CODE__IQ16toF:CODE(2)
    thumb
    export  _IQ16toF
_IQ16toF
    //
    // The only special case to cover is if the operand is zero.
    // In this case, we simply return - r0 is already appropriately set.
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
    //    +127 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(127 + 31 - 16)

    //
    // Prepare normalized mantissa.
    //
    lsl     r0, r0, r3
    lsr     r0, r0, #8

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r0, r2, #23, #8

    //
    // OR Sign bit back into result.
    //
    orr     r0, r1, r0

    //
    // Return to the caller.
    //
r0isZero16
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ17toF
//
//*****************************************************************************
    section CODE__IQ17toF:CODE(2)
    thumb
    export  _IQ17toF
_IQ17toF
    //
    // The only special case to cover is if the operand is zero.
    // In this case, we simply return - r0 is already appropriately set.
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
    //    +127 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(127 + 31 - 17)

    //
    // Prepare normalized mantissa.
    //
    lsl     r0, r0, r3
    lsr     r0, r0, #8

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r0, r2, #23, #8

    //
    // OR Sign bit back into result.
    //
    orr     r0, r1, r0

    //
    // Return to the caller.
    //
r0isZero17
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ18toF
//
//*****************************************************************************
    section CODE__IQ18toF:CODE(2)
    thumb
    export  _IQ18toF
_IQ18toF
    //
    // The only special case to cover is if the operand is zero.
    // In this case, we simply return - r0 is already appropriately set.
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
    //    +127 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(127 + 31 - 18)

    //
    // Prepare normalized mantissa.
    //
    lsl     r0, r0, r3
    lsr     r0, r0, #8

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r0, r2, #23, #8

    //
    // OR Sign bit back into result.
    //
    orr     r0, r1, r0

    //
    // Return to the caller.
    //
r0isZero18
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ19toF
//
//*****************************************************************************
    section CODE__IQ19toF:CODE(2)
    thumb
    export  _IQ19toF
_IQ19toF
    //
    // The only special case to cover is if the operand is zero.
    // In this case, we simply return - r0 is already appropriately set.
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
    //    +127 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(127 + 31 - 19)

    //
    // Prepare normalized mantissa.
    //
    lsl     r0, r0, r3
    lsr     r0, r0, #8

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r0, r2, #23, #8

    //
    // OR Sign bit back into result.
    //
    orr     r0, r1, r0

    //
    // Return to the caller.
    //
r0isZero19
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ20toF
//
//*****************************************************************************
    section CODE__IQ20toF:CODE(2)
    thumb
    export  _IQ20toF
_IQ20toF
    //
    // The only special case to cover is if the operand is zero.
    // In this case, we simply return - r0 is already appropriately set.
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
    //    +127 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(127 + 31 - 20)

    //
    // Prepare normalized mantissa.
    //
    lsl     r0, r0, r3
    lsr     r0, r0, #8

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r0, r2, #23, #8

    //
    // OR Sign bit back into result.
    //
    orr     r0, r1, r0

    //
    // Return to the caller.
    //
r0isZero20
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ21toF
//
//*****************************************************************************
    section CODE__IQ21toF:CODE(2)
    thumb
    export  _IQ21toF
_IQ21toF
    //
    // The only special case to cover is if the operand is zero.
    // In this case, we simply return - r0 is already appropriately set.
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
    //    +127 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(127 + 31 - 21)

    //
    // Prepare normalized mantissa.
    //
    lsl     r0, r0, r3
    lsr     r0, r0, #8

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r0, r2, #23, #8

    //
    // OR Sign bit back into result.
    //
    orr     r0, r1, r0

    //
    // Return to the caller.
    //
r0isZero21
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ22toF
//
//*****************************************************************************
    section CODE__IQ22toF:CODE(2)
    thumb
    export  _IQ22toF
_IQ22toF
    //
    // The only special case to cover is if the operand is zero.
    // In this case, we simply return - r0 is already appropriately set.
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
    //    +127 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(127 + 31 - 22)

    //
    // Prepare normalized mantissa.
    //
    lsl     r0, r0, r3
    lsr     r0, r0, #8

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r0, r2, #23, #8

    //
    // OR Sign bit back into result.
    //
    orr     r0, r1, r0

    //
    // Return to the caller.
    //
r0isZero22
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ23toF
//
//*****************************************************************************
    section CODE__IQ23toF:CODE(2)
    thumb
    export  _IQ23toF
_IQ23toF
    //
    // The only special case to cover is if the operand is zero.
    // In this case, we simply return - r0 is already appropriately set.
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
    //    +127 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(127 + 31 - 23)

    //
    // Prepare normalized mantissa.
    //
    lsl     r0, r0, r3
    lsr     r0, r0, #8

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r0, r2, #23, #8

    //
    // OR Sign bit back into result.
    //
    orr     r0, r1, r0

    //
    // Return to the caller.
    //
r0isZero23
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ24toF
//
//*****************************************************************************
    section CODE__IQ24toF:CODE(2)
    thumb
    export  _IQ24toF
_IQ24toF
    //
    // The only special case to cover is if the operand is zero.
    // In this case, we simply return - r0 is already appropriately set.
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
    //    +127 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(127 + 31 - 24)

    //
    // Prepare normalized mantissa.
    //
    lsl     r0, r0, r3
    lsr     r0, r0, #8

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r0, r2, #23, #8

    //
    // OR Sign bit back into result.
    //
    orr     r0, r1, r0

    //
    // Return to the caller.
    //
r0isZero24
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ25toF
//
//*****************************************************************************
    section CODE__IQ25toF:CODE(2)
    thumb
    export  _IQ25toF
_IQ25toF
    //
    // The only special case to cover is if the operand is zero.
    // In this case, we simply return - r0 is already appropriately set.
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
    //    +127 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(127 + 31 - 25)

    //
    // Prepare normalized mantissa.
    //
    lsl     r0, r0, r3
    lsr     r0, r0, #8

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r0, r2, #23, #8

    //
    // OR Sign bit back into result.
    //
    orr     r0, r1, r0

    //
    // Return to the caller.
    //
r0isZero25
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ26toF
//
//*****************************************************************************
    section CODE__IQ26toF:CODE(2)
    thumb
    export  _IQ26toF
_IQ26toF
    //
    // The only special case to cover is if the operand is zero.
    // In this case, we simply return - r0 is already appropriately set.
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
    //    +127 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(127 + 31 - 26)

    //
    // Prepare normalized mantissa.
    //
    lsl     r0, r0, r3
    lsr     r0, r0, #8

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r0, r2, #23, #8

    //
    // OR Sign bit back into result.
    //
    orr     r0, r1, r0

    //
    // Return to the caller.
    //
r0isZero26
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ27toF
//
//*****************************************************************************
    section CODE__IQ27toF:CODE(2)
    thumb
    export  _IQ27toF
_IQ27toF
    //
    // The only special case to cover is if the operand is zero.
    // In this case, we simply return - r0 is already appropriately set.
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
    //    +127 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(127 + 31 - 27)

    //
    // Prepare normalized mantissa.
    //
    lsl     r0, r0, r3
    lsr     r0, r0, #8

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r0, r2, #23, #8

    //
    // OR Sign bit back into result.
    //
    orr     r0, r1, r0

    //
    // Return to the caller.
    //
r0isZero27
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ28toF
//
//*****************************************************************************
    section CODE__IQ28toF:CODE(2)
    thumb
    export  _IQ28toF
_IQ28toF
    //
    // The only special case to cover is if the operand is zero.
    // In this case, we simply return - r0 is already appropriately set.
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
    //    +127 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(127 + 31 - 28)

    //
    // Prepare normalized mantissa.
    //
    lsl     r0, r0, r3
    lsr     r0, r0, #8

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r0, r2, #23, #8

    //
    // OR Sign bit back into result.
    //
    orr     r0, r1, r0

    //
    // Return to the caller.
    //
r0isZero28
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ29toF
//
//*****************************************************************************
    section CODE__IQ29toF:CODE(2)
    thumb
    export  _IQ29toF
_IQ29toF
    //
    // The only special case to cover is if the operand is zero.
    // In this case, we simply return - r0 is already appropriately set.
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
    //    +127 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(127 + 31 - 29)

    //
    // Prepare normalized mantissa.
    //
    lsl     r0, r0, r3
    lsr     r0, r0, #8

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r0, r2, #23, #8

    //
    // OR Sign bit back into result.
    //
    orr     r0, r1, r0

    //
    // Return to the caller.
    //
r0isZero29
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ30toF
//
//*****************************************************************************
    section CODE__IQ30toF:CODE(2)
    thumb
    export  _IQ30toF
_IQ30toF
    //
    // The only special case to cover is if the operand is zero.
    // In this case, we simply return - r0 is already appropriately set.
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
    //    +127 per the definition from IEEE 754
    //    +31-Q to compensate hidden shift from IQ
    //    -r3 = the number of leading zeros
    //
    clz     r3, r0
    rsb     r2, r3, #(127 + 31 - 30)

    //
    // Prepare normalized mantissa.
    //
    lsl     r0, r0, r3
    lsr     r0, r0, #8

    //
    // Insert exponent bits.
    // This over-writes the extraneous leading 1 in bit 23
    //
    bfi     r0, r2, #23, #8

    //
    // OR Sign bit back into result.
    //
    orr     r0, r1, r0

    //
    // Return to the caller.
    //
r0isZero30
    bx      lr

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

    end
