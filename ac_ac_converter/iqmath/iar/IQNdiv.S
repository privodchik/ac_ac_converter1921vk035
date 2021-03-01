//*****************************************************************************
//
// IQdiv.S - Fixed-point divide.
//
// Copyright (c) 2010 Texas Instruments Incorporated.  All rights reserved.
// TI Information - Selective Disclosure
//
//*****************************************************************************

//*****************************************************************************
//
// Function:   _IQNdiv
//
//*****************************************************************************
//
// C Usage:    extern long _IQNdiv(long Num, long Den);
//
//-----------------------------------------------------------------------------
//
// On Entry:   r0     = Numerator in IQ format
//             r1     = Denominator in IQ format
//
// Regs Used:  r0-r6
//
// On Exit:    r0     = Num/Den result in IQ format
//                    = 0x7FFFFFFF if +ve overflow
//                    = 0x80000000 if -ve overflow
//                    = 0x7FFFFFFF if Den == 0
//
// Q range:    30 to 1
//
//-----------------------------------------------------------------------------
//
// Algorithm:  The procedure for calculating Y = N/D is as follows:
//
//  Step 0)   Handle exceptions - divide by zero, overflow.
//  Step 1)   Put operands in unsigned notation
//  Step 2)   Shift numerator / remainder to fill MSB
//            Shift partial answer to match
//  Step 3)   32x32 bit divide.
//            Add quotient to partial answer
//            Find remainder
//  Step 4)   Repeat until Q shifts have been accomplished.
//  Step 5)   Put result back into signed notation
//
//##### INTERNAL BEGIN #####
//-----------------------------------------------------------------------------
//
// Benchmark:  ??
//
//##### INTERNAL END #####
//*****************************************************************************

//*****************************************************************************
//
// _IQ1div
//
//*****************************************************************************
    section CODE__IQ1div:CODE(2)
    thumb
    export  _IQ1div
_IQ1div
    //
    // Test for divide by zero.  Bail with positive overflow if so.
    //
    teq     r1, #0
    itt     eq
        mvneq   r0, #0x80000000
        bxeq    lr

    //
    // Save scratch registers
    //
    push    {r4, lr}

    // Save sign of result to lr
    //
    mov     lr, #1
    teq     r0, r1
        it      mi
        movmi   lr, #0

    //
    // Put operands into unsigned notation
    //
    cmp     r0, #0
        it      mi
        rsbmi   r0, r0, #0
    cmp     r1, #0
        it      mi
        rsbmi   r1, r1, #0
    //
    //
    // First Division
    // The first divide instruction is special, it includes some
    // of the register re-arranging and does overflow checking.
    //
    // Check how many bits can be handled in this first division
    // If all Q bits can be produced, bail early to divfinished
    //
    clz     r4, r0
    cmp     r4, #1
        it      ge
        movge   r4, #1
    lsl     r2, r0, r4
    rsb     r12, r4, #1

    //
    // r0 contains numerator, dirty
    // r1 contains denominator
    // r2 contains normalized numerator
    // r3 is dirty
    // r4 contains shiftable zeros, dirty
    // r12 contains the number of additional shifts required
    // lr contains sign flag.
    //
    // Perform the first division.
    //
    udiv    r0, r2, r1

    //
    // Check for overflow.
    // If overflow occurs, return 0x7F... or 0x80.. based on lr (sign flag).
    // Note that this assumes that the magnitude of the number is found on the
    // first shift.  This assumption has been empirically proven for
    // for all 10 bit numbers.
    //
    clz     r3, r0
    cmp     r12, r3
        itt     ge
        rsbge   r0, lr, #0x80000000
        popge   {r4, pc}

    //
    // Find the remainder and put it in r2 for future operations.
    //
    mls     r2, r1, r0, r2

    //
    // Determine how much to shift by.  This is the minimum of
    // the number of leading zeros and the number of shifts left
    // If this is the final divide, jump to the tail.
    //
    clz     r4, r2
    cmp     r4, r12
    bge     divfinished1

    //
    // Middle Divisions
    // This loop holds all the divisions other than the head and tail
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = #shifts this iteration    r12 = remaining shifts needed
    //
    // Prepare for the divide by normalizing remainder.
    //
divmore1
        sub     r12, r12, r4
        lsl     r2, r2, r4
        lsl     r0, r0, r4

        //
        // Perform the divide
        // We already know that an additional step is required, so do the
        // remainder calculation as well.
        //
        udiv    r3, r2, r1
        mls     r2, r1, r3, r2
        add     r0, r3, r0

        //
        // Divide finished, update shift counters for next divide.
        // re-loop if more operations are needed.
        //
        clz     r4, r2
        cmp     r4, r12
    ble   divmore1

    //
    // Final Divide (Tail Divide)
    // Performs the last divide in the sequence, restores scratch registers,
    // adjusts sign bit.
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = dirty                     r12 = remaining shifts needed
    //
divfinished1
    lsl     r2, r2, r12
    lsl     r0, r0, r12
    udiv    r3, r2, r1
    add     r0, r3, r0
    teq     lr, #0
        it      eq
        rsbeq   r0, r0, #0
    pop     {r4, pc}

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ2div
//
//*****************************************************************************
    section CODE__IQ2div:CODE(2)
    thumb
    export  _IQ2div
_IQ2div
    //
    // Test for divide by zero.  Bail with positive overflow if so.
    //
    teq     r1, #0
    itt     eq
        mvneq   r0, #0x80000000
        bxeq    lr

    //
    // Save scratch registers
    //
    push    {r4, lr}

    // Save sign of result to lr
    //
    mov     lr, #1
    teq     r0, r1
        it      mi
        movmi   lr, #0

    //
    // Put operands into unsigned notation
    //
    cmp     r0, #0
        it      mi
        rsbmi   r0, r0, #0
    cmp     r1, #0
        it      mi
        rsbmi   r1, r1, #0
    //
    //
    // First Division
    // The first divide instruction is special, it includes some
    // of the register re-arranging and does overflow checking.
    //
    // Check how many bits can be handled in this first division
    // If all Q bits can be produced, bail early to divfinished
    //
    clz     r4, r0
    cmp     r4, #2
        it      ge
        movge   r4, #2
    lsl     r2, r0, r4
    rsb     r12, r4, #2

    //
    // r0 contains numerator, dirty
    // r1 contains denominator
    // r2 contains normalized numerator
    // r3 is dirty
    // r4 contains shiftable zeros, dirty
    // r12 contains the number of additional shifts required
    // lr contains sign flag.
    //
    // Perform the first division.
    //
    udiv    r0, r2, r1

    //
    // Check for overflow.
    // If overflow occurs, return 0x7F... or 0x80.. based on lr (sign flag).
    // Note that this assumes that the magnitude of the number is found on the
    // first shift.  This assumption has been empirically proven for
    // for all 10 bit numbers.
    //
    clz     r3, r0
    cmp     r12, r3
        itt     ge
        rsbge   r0, lr, #0x80000000
        popge   {r4, pc}

    //
    // Find the remainder and put it in r2 for future operations.
    //
    mls     r2, r1, r0, r2

    //
    // Determine how much to shift by.  This is the minimum of
    // the number of leading zeros and the number of shifts left
    // If this is the final divide, jump to the tail.
    //
    clz     r4, r2
    cmp     r4, r12
    bge     divfinished2

    //
    // Middle Divisions
    // This loop holds all the divisions other than the head and tail
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = #shifts this iteration    r12 = remaining shifts needed
    //
    // Prepare for the divide by normalizing remainder.
    //
divmore2
        sub     r12, r12, r4
        lsl     r2, r2, r4
        lsl     r0, r0, r4

        //
        // Perform the divide
        // We already know that an additional step is required, so do the
        // remainder calculation as well.
        //
        udiv    r3, r2, r1
        mls     r2, r1, r3, r2
        add     r0, r3, r0

        //
        // Divide finished, update shift counters for next divide.
        // re-loop if more operations are needed.
        //
        clz     r4, r2
        cmp     r4, r12
    ble   divmore2

    //
    // Final Divide (Tail Divide)
    // Performs the last divide in the sequence, restores scratch registers,
    // adjusts sign bit.
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = dirty                     r12 = remaining shifts needed
    //
divfinished2
    lsl     r2, r2, r12
    lsl     r0, r0, r12
    udiv    r3, r2, r1
    add     r0, r3, r0
    teq     lr, #0
        it      eq
        rsbeq   r0, r0, #0
    pop     {r4, pc}

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ3div
//
//*****************************************************************************
    section CODE__IQ3div:CODE(2)
    thumb
    export  _IQ3div
_IQ3div
    //
    // Test for divide by zero.  Bail with positive overflow if so.
    //
    teq     r1, #0
    itt     eq
        mvneq   r0, #0x80000000
        bxeq    lr

    //
    // Save scratch registers
    //
    push    {r4, lr}

    // Save sign of result to lr
    //
    mov     lr, #1
    teq     r0, r1
        it      mi
        movmi   lr, #0

    //
    // Put operands into unsigned notation
    //
    cmp     r0, #0
        it      mi
        rsbmi   r0, r0, #0
    cmp     r1, #0
        it      mi
        rsbmi   r1, r1, #0
    //
    //
    // First Division
    // The first divide instruction is special, it includes some
    // of the register re-arranging and does overflow checking.
    //
    // Check how many bits can be handled in this first division
    // If all Q bits can be produced, bail early to divfinished
    //
    clz     r4, r0
    cmp     r4, #3
        it      ge
        movge   r4, #3
    lsl     r2, r0, r4
    rsb     r12, r4, #3

    //
    // r0 contains numerator, dirty
    // r1 contains denominator
    // r2 contains normalized numerator
    // r3 is dirty
    // r4 contains shiftable zeros, dirty
    // r12 contains the number of additional shifts required
    // lr contains sign flag.
    //
    // Perform the first division.
    //
    udiv    r0, r2, r1

    //
    // Check for overflow.
    // If overflow occurs, return 0x7F... or 0x80.. based on lr (sign flag).
    // Note that this assumes that the magnitude of the number is found on the
    // first shift.  This assumption has been empirically proven for
    // for all 10 bit numbers.
    //
    clz     r3, r0
    cmp     r12, r3
        itt     ge
        rsbge   r0, lr, #0x80000000
        popge   {r4, pc}

    //
    // Find the remainder and put it in r2 for future operations.
    //
    mls     r2, r1, r0, r2

    //
    // Determine how much to shift by.  This is the minimum of
    // the number of leading zeros and the number of shifts left
    // If this is the final divide, jump to the tail.
    //
    clz     r4, r2
    cmp     r4, r12
    bge     divfinished3

    //
    // Middle Divisions
    // This loop holds all the divisions other than the head and tail
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = #shifts this iteration    r12 = remaining shifts needed
    //
    // Prepare for the divide by normalizing remainder.
    //
divmore3
        sub     r12, r12, r4
        lsl     r2, r2, r4
        lsl     r0, r0, r4

        //
        // Perform the divide
        // We already know that an additional step is required, so do the
        // remainder calculation as well.
        //
        udiv    r3, r2, r1
        mls     r2, r1, r3, r2
        add     r0, r3, r0

        //
        // Divide finished, update shift counters for next divide.
        // re-loop if more operations are needed.
        //
        clz     r4, r2
        cmp     r4, r12
    ble   divmore3

    //
    // Final Divide (Tail Divide)
    // Performs the last divide in the sequence, restores scratch registers,
    // adjusts sign bit.
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = dirty                     r12 = remaining shifts needed
    //
divfinished3
    lsl     r2, r2, r12
    lsl     r0, r0, r12
    udiv    r3, r2, r1
    add     r0, r3, r0
    teq     lr, #0
        it      eq
        rsbeq   r0, r0, #0
    pop     {r4, pc}

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ4div
//
//*****************************************************************************
    section CODE__IQ4div:CODE(2)
    thumb
    export  _IQ4div
_IQ4div
    //
    // Test for divide by zero.  Bail with positive overflow if so.
    //
    teq     r1, #0
    itt     eq
        mvneq   r0, #0x80000000
        bxeq    lr

    //
    // Save scratch registers
    //
    push    {r4, lr}

    // Save sign of result to lr
    //
    mov     lr, #1
    teq     r0, r1
        it      mi
        movmi   lr, #0

    //
    // Put operands into unsigned notation
    //
    cmp     r0, #0
        it      mi
        rsbmi   r0, r0, #0
    cmp     r1, #0
        it      mi
        rsbmi   r1, r1, #0
    //
    //
    // First Division
    // The first divide instruction is special, it includes some
    // of the register re-arranging and does overflow checking.
    //
    // Check how many bits can be handled in this first division
    // If all Q bits can be produced, bail early to divfinished
    //
    clz     r4, r0
    cmp     r4, #4
        it      ge
        movge   r4, #4
    lsl     r2, r0, r4
    rsb     r12, r4, #4

    //
    // r0 contains numerator, dirty
    // r1 contains denominator
    // r2 contains normalized numerator
    // r3 is dirty
    // r4 contains shiftable zeros, dirty
    // r12 contains the number of additional shifts required
    // lr contains sign flag.
    //
    // Perform the first division.
    //
    udiv    r0, r2, r1

    //
    // Check for overflow.
    // If overflow occurs, return 0x7F... or 0x80.. based on lr (sign flag).
    // Note that this assumes that the magnitude of the number is found on the
    // first shift.  This assumption has been empirically proven for
    // for all 10 bit numbers.
    //
    clz     r3, r0
    cmp     r12, r3
        itt     ge
        rsbge   r0, lr, #0x80000000
        popge   {r4, pc}

    //
    // Find the remainder and put it in r2 for future operations.
    //
    mls     r2, r1, r0, r2

    //
    // Determine how much to shift by.  This is the minimum of
    // the number of leading zeros and the number of shifts left
    // If this is the final divide, jump to the tail.
    //
    clz     r4, r2
    cmp     r4, r12
    bge     divfinished4

    //
    // Middle Divisions
    // This loop holds all the divisions other than the head and tail
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = #shifts this iteration    r12 = remaining shifts needed
    //
    // Prepare for the divide by normalizing remainder.
    //
divmore4
        sub     r12, r12, r4
        lsl     r2, r2, r4
        lsl     r0, r0, r4

        //
        // Perform the divide
        // We already know that an additional step is required, so do the
        // remainder calculation as well.
        //
        udiv    r3, r2, r1
        mls     r2, r1, r3, r2
        add     r0, r3, r0

        //
        // Divide finished, update shift counters for next divide.
        // re-loop if more operations are needed.
        //
        clz     r4, r2
        cmp     r4, r12
    ble   divmore4

    //
    // Final Divide (Tail Divide)
    // Performs the last divide in the sequence, restores scratch registers,
    // adjusts sign bit.
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = dirty                     r12 = remaining shifts needed
    //
divfinished4
    lsl     r2, r2, r12
    lsl     r0, r0, r12
    udiv    r3, r2, r1
    add     r0, r3, r0
    teq     lr, #0
        it      eq
        rsbeq   r0, r0, #0
    pop     {r4, pc}

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ5div
//
//*****************************************************************************
    section CODE__IQ5div:CODE(2)
    thumb
    export  _IQ5div
_IQ5div
    //
    // Test for divide by zero.  Bail with positive overflow if so.
    //
    teq     r1, #0
    itt     eq
        mvneq   r0, #0x80000000
        bxeq    lr

    //
    // Save scratch registers
    //
    push    {r4, lr}

    // Save sign of result to lr
    //
    mov     lr, #1
    teq     r0, r1
        it      mi
        movmi   lr, #0

    //
    // Put operands into unsigned notation
    //
    cmp     r0, #0
        it      mi
        rsbmi   r0, r0, #0
    cmp     r1, #0
        it      mi
        rsbmi   r1, r1, #0
    //
    //
    // First Division
    // The first divide instruction is special, it includes some
    // of the register re-arranging and does overflow checking.
    //
    // Check how many bits can be handled in this first division
    // If all Q bits can be produced, bail early to divfinished
    //
    clz     r4, r0
    cmp     r4, #5
        it      ge
        movge   r4, #5
    lsl     r2, r0, r4
    rsb     r12, r4, #5

    //
    // r0 contains numerator, dirty
    // r1 contains denominator
    // r2 contains normalized numerator
    // r3 is dirty
    // r4 contains shiftable zeros, dirty
    // r12 contains the number of additional shifts required
    // lr contains sign flag.
    //
    // Perform the first division.
    //
    udiv    r0, r2, r1

    //
    // Check for overflow.
    // If overflow occurs, return 0x7F... or 0x80.. based on lr (sign flag).
    // Note that this assumes that the magnitude of the number is found on the
    // first shift.  This assumption has been empirically proven for
    // for all 10 bit numbers.
    //
    clz     r3, r0
    cmp     r12, r3
        itt     ge
        rsbge   r0, lr, #0x80000000
        popge   {r4, pc}

    //
    // Find the remainder and put it in r2 for future operations.
    //
    mls     r2, r1, r0, r2

    //
    // Determine how much to shift by.  This is the minimum of
    // the number of leading zeros and the number of shifts left
    // If this is the final divide, jump to the tail.
    //
    clz     r4, r2
    cmp     r4, r12
    bge     divfinished5

    //
    // Middle Divisions
    // This loop holds all the divisions other than the head and tail
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = #shifts this iteration    r12 = remaining shifts needed
    //
    // Prepare for the divide by normalizing remainder.
    //
divmore5
        sub     r12, r12, r4
        lsl     r2, r2, r4
        lsl     r0, r0, r4

        //
        // Perform the divide
        // We already know that an additional step is required, so do the
        // remainder calculation as well.
        //
        udiv    r3, r2, r1
        mls     r2, r1, r3, r2
        add     r0, r3, r0

        //
        // Divide finished, update shift counters for next divide.
        // re-loop if more operations are needed.
        //
        clz     r4, r2
        cmp     r4, r12
    ble   divmore5

    //
    // Final Divide (Tail Divide)
    // Performs the last divide in the sequence, restores scratch registers,
    // adjusts sign bit.
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = dirty                     r12 = remaining shifts needed
    //
divfinished5
    lsl     r2, r2, r12
    lsl     r0, r0, r12
    udiv    r3, r2, r1
    add     r0, r3, r0
    teq     lr, #0
        it      eq
        rsbeq   r0, r0, #0
    pop     {r4, pc}

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ6div
//
//*****************************************************************************
    section CODE__IQ6div:CODE(2)
    thumb
    export  _IQ6div
_IQ6div
    //
    // Test for divide by zero.  Bail with positive overflow if so.
    //
    teq     r1, #0
    itt     eq
        mvneq   r0, #0x80000000
        bxeq    lr

    //
    // Save scratch registers
    //
    push    {r4, lr}

    // Save sign of result to lr
    //
    mov     lr, #1
    teq     r0, r1
        it      mi
        movmi   lr, #0

    //
    // Put operands into unsigned notation
    //
    cmp     r0, #0
        it      mi
        rsbmi   r0, r0, #0
    cmp     r1, #0
        it      mi
        rsbmi   r1, r1, #0
    //
    //
    // First Division
    // The first divide instruction is special, it includes some
    // of the register re-arranging and does overflow checking.
    //
    // Check how many bits can be handled in this first division
    // If all Q bits can be produced, bail early to divfinished
    //
    clz     r4, r0
    cmp     r4, #6
        it      ge
        movge   r4, #6
    lsl     r2, r0, r4
    rsb     r12, r4, #6

    //
    // r0 contains numerator, dirty
    // r1 contains denominator
    // r2 contains normalized numerator
    // r3 is dirty
    // r4 contains shiftable zeros, dirty
    // r12 contains the number of additional shifts required
    // lr contains sign flag.
    //
    // Perform the first division.
    //
    udiv    r0, r2, r1

    //
    // Check for overflow.
    // If overflow occurs, return 0x7F... or 0x80.. based on lr (sign flag).
    // Note that this assumes that the magnitude of the number is found on the
    // first shift.  This assumption has been empirically proven for
    // for all 10 bit numbers.
    //
    clz     r3, r0
    cmp     r12, r3
        itt     ge
        rsbge   r0, lr, #0x80000000
        popge   {r4, pc}

    //
    // Find the remainder and put it in r2 for future operations.
    //
    mls     r2, r1, r0, r2

    //
    // Determine how much to shift by.  This is the minimum of
    // the number of leading zeros and the number of shifts left
    // If this is the final divide, jump to the tail.
    //
    clz     r4, r2
    cmp     r4, r12
    bge     divfinished6

    //
    // Middle Divisions
    // This loop holds all the divisions other than the head and tail
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = #shifts this iteration    r12 = remaining shifts needed
    //
    // Prepare for the divide by normalizing remainder.
    //
divmore6
        sub     r12, r12, r4
        lsl     r2, r2, r4
        lsl     r0, r0, r4

        //
        // Perform the divide
        // We already know that an additional step is required, so do the
        // remainder calculation as well.
        //
        udiv    r3, r2, r1
        mls     r2, r1, r3, r2
        add     r0, r3, r0

        //
        // Divide finished, update shift counters for next divide.
        // re-loop if more operations are needed.
        //
        clz     r4, r2
        cmp     r4, r12
    ble   divmore6

    //
    // Final Divide (Tail Divide)
    // Performs the last divide in the sequence, restores scratch registers,
    // adjusts sign bit.
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = dirty                     r12 = remaining shifts needed
    //
divfinished6
    lsl     r2, r2, r12
    lsl     r0, r0, r12
    udiv    r3, r2, r1
    add     r0, r3, r0
    teq     lr, #0
        it      eq
        rsbeq   r0, r0, #0
    pop     {r4, pc}

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ7div
//
//*****************************************************************************
    section CODE__IQ7div:CODE(2)
    thumb
    export  _IQ7div
_IQ7div
    //
    // Test for divide by zero.  Bail with positive overflow if so.
    //
    teq     r1, #0
    itt     eq
        mvneq   r0, #0x80000000
        bxeq    lr

    //
    // Save scratch registers
    //
    push    {r4, lr}

    // Save sign of result to lr
    //
    mov     lr, #1
    teq     r0, r1
        it      mi
        movmi   lr, #0

    //
    // Put operands into unsigned notation
    //
    cmp     r0, #0
        it      mi
        rsbmi   r0, r0, #0
    cmp     r1, #0
        it      mi
        rsbmi   r1, r1, #0
    //
    //
    // First Division
    // The first divide instruction is special, it includes some
    // of the register re-arranging and does overflow checking.
    //
    // Check how many bits can be handled in this first division
    // If all Q bits can be produced, bail early to divfinished
    //
    clz     r4, r0
    cmp     r4, #7
        it      ge
        movge   r4, #7
    lsl     r2, r0, r4
    rsb     r12, r4, #7

    //
    // r0 contains numerator, dirty
    // r1 contains denominator
    // r2 contains normalized numerator
    // r3 is dirty
    // r4 contains shiftable zeros, dirty
    // r12 contains the number of additional shifts required
    // lr contains sign flag.
    //
    // Perform the first division.
    //
    udiv    r0, r2, r1

    //
    // Check for overflow.
    // If overflow occurs, return 0x7F... or 0x80.. based on lr (sign flag).
    // Note that this assumes that the magnitude of the number is found on the
    // first shift.  This assumption has been empirically proven for
    // for all 10 bit numbers.
    //
    clz     r3, r0
    cmp     r12, r3
        itt     ge
        rsbge   r0, lr, #0x80000000
        popge   {r4, pc}

    //
    // Find the remainder and put it in r2 for future operations.
    //
    mls     r2, r1, r0, r2

    //
    // Determine how much to shift by.  This is the minimum of
    // the number of leading zeros and the number of shifts left
    // If this is the final divide, jump to the tail.
    //
    clz     r4, r2
    cmp     r4, r12
    bge     divfinished7

    //
    // Middle Divisions
    // This loop holds all the divisions other than the head and tail
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = #shifts this iteration    r12 = remaining shifts needed
    //
    // Prepare for the divide by normalizing remainder.
    //
divmore7
        sub     r12, r12, r4
        lsl     r2, r2, r4
        lsl     r0, r0, r4

        //
        // Perform the divide
        // We already know that an additional step is required, so do the
        // remainder calculation as well.
        //
        udiv    r3, r2, r1
        mls     r2, r1, r3, r2
        add     r0, r3, r0

        //
        // Divide finished, update shift counters for next divide.
        // re-loop if more operations are needed.
        //
        clz     r4, r2
        cmp     r4, r12
    ble   divmore7

    //
    // Final Divide (Tail Divide)
    // Performs the last divide in the sequence, restores scratch registers,
    // adjusts sign bit.
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = dirty                     r12 = remaining shifts needed
    //
divfinished7
    lsl     r2, r2, r12
    lsl     r0, r0, r12
    udiv    r3, r2, r1
    add     r0, r3, r0
    teq     lr, #0
        it      eq
        rsbeq   r0, r0, #0
    pop     {r4, pc}

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ8div
//
//*****************************************************************************
    section CODE__IQ8div:CODE(2)
    thumb
    export  _IQ8div
_IQ8div
    //
    // Test for divide by zero.  Bail with positive overflow if so.
    //
    teq     r1, #0
    itt     eq
        mvneq   r0, #0x80000000
        bxeq    lr

    //
    // Save scratch registers
    //
    push    {r4, lr}

    // Save sign of result to lr
    //
    mov     lr, #1
    teq     r0, r1
        it      mi
        movmi   lr, #0

    //
    // Put operands into unsigned notation
    //
    cmp     r0, #0
        it      mi
        rsbmi   r0, r0, #0
    cmp     r1, #0
        it      mi
        rsbmi   r1, r1, #0
    //
    //
    // First Division
    // The first divide instruction is special, it includes some
    // of the register re-arranging and does overflow checking.
    //
    // Check how many bits can be handled in this first division
    // If all Q bits can be produced, bail early to divfinished
    //
    clz     r4, r0
    cmp     r4, #8
        it      ge
        movge   r4, #8
    lsl     r2, r0, r4
    rsb     r12, r4, #8

    //
    // r0 contains numerator, dirty
    // r1 contains denominator
    // r2 contains normalized numerator
    // r3 is dirty
    // r4 contains shiftable zeros, dirty
    // r12 contains the number of additional shifts required
    // lr contains sign flag.
    //
    // Perform the first division.
    //
    udiv    r0, r2, r1

    //
    // Check for overflow.
    // If overflow occurs, return 0x7F... or 0x80.. based on lr (sign flag).
    // Note that this assumes that the magnitude of the number is found on the
    // first shift.  This assumption has been empirically proven for
    // for all 10 bit numbers.
    //
    clz     r3, r0
    cmp     r12, r3
        itt     ge
        rsbge   r0, lr, #0x80000000
        popge   {r4, pc}

    //
    // Find the remainder and put it in r2 for future operations.
    //
    mls     r2, r1, r0, r2

    //
    // Determine how much to shift by.  This is the minimum of
    // the number of leading zeros and the number of shifts left
    // If this is the final divide, jump to the tail.
    //
    clz     r4, r2
    cmp     r4, r12
    bge     divfinished8

    //
    // Middle Divisions
    // This loop holds all the divisions other than the head and tail
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = #shifts this iteration    r12 = remaining shifts needed
    //
    // Prepare for the divide by normalizing remainder.
    //
divmore8
        sub     r12, r12, r4
        lsl     r2, r2, r4
        lsl     r0, r0, r4

        //
        // Perform the divide
        // We already know that an additional step is required, so do the
        // remainder calculation as well.
        //
        udiv    r3, r2, r1
        mls     r2, r1, r3, r2
        add     r0, r3, r0

        //
        // Divide finished, update shift counters for next divide.
        // re-loop if more operations are needed.
        //
        clz     r4, r2
        cmp     r4, r12
    ble   divmore8

    //
    // Final Divide (Tail Divide)
    // Performs the last divide in the sequence, restores scratch registers,
    // adjusts sign bit.
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = dirty                     r12 = remaining shifts needed
    //
divfinished8
    lsl     r2, r2, r12
    lsl     r0, r0, r12
    udiv    r3, r2, r1
    add     r0, r3, r0
    teq     lr, #0
        it      eq
        rsbeq   r0, r0, #0
    pop     {r4, pc}

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ9div
//
//*****************************************************************************
    section CODE__IQ9div:CODE(2)
    thumb
    export  _IQ9div
_IQ9div
    //
    // Test for divide by zero.  Bail with positive overflow if so.
    //
    teq     r1, #0
    itt     eq
        mvneq   r0, #0x80000000
        bxeq    lr

    //
    // Save scratch registers
    //
    push    {r4, lr}

    // Save sign of result to lr
    //
    mov     lr, #1
    teq     r0, r1
        it      mi
        movmi   lr, #0

    //
    // Put operands into unsigned notation
    //
    cmp     r0, #0
        it      mi
        rsbmi   r0, r0, #0
    cmp     r1, #0
        it      mi
        rsbmi   r1, r1, #0
    //
    //
    // First Division
    // The first divide instruction is special, it includes some
    // of the register re-arranging and does overflow checking.
    //
    // Check how many bits can be handled in this first division
    // If all Q bits can be produced, bail early to divfinished
    //
    clz     r4, r0
    cmp     r4, #9
        it      ge
        movge   r4, #9
    lsl     r2, r0, r4
    rsb     r12, r4, #9

    //
    // r0 contains numerator, dirty
    // r1 contains denominator
    // r2 contains normalized numerator
    // r3 is dirty
    // r4 contains shiftable zeros, dirty
    // r12 contains the number of additional shifts required
    // lr contains sign flag.
    //
    // Perform the first division.
    //
    udiv    r0, r2, r1

    //
    // Check for overflow.
    // If overflow occurs, return 0x7F... or 0x80.. based on lr (sign flag).
    // Note that this assumes that the magnitude of the number is found on the
    // first shift.  This assumption has been empirically proven for
    // for all 10 bit numbers.
    //
    clz     r3, r0
    cmp     r12, r3
        itt     ge
        rsbge   r0, lr, #0x80000000
        popge   {r4, pc}

    //
    // Find the remainder and put it in r2 for future operations.
    //
    mls     r2, r1, r0, r2

    //
    // Determine how much to shift by.  This is the minimum of
    // the number of leading zeros and the number of shifts left
    // If this is the final divide, jump to the tail.
    //
    clz     r4, r2
    cmp     r4, r12
    bge     divfinished9

    //
    // Middle Divisions
    // This loop holds all the divisions other than the head and tail
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = #shifts this iteration    r12 = remaining shifts needed
    //
    // Prepare for the divide by normalizing remainder.
    //
divmore9
        sub     r12, r12, r4
        lsl     r2, r2, r4
        lsl     r0, r0, r4

        //
        // Perform the divide
        // We already know that an additional step is required, so do the
        // remainder calculation as well.
        //
        udiv    r3, r2, r1
        mls     r2, r1, r3, r2
        add     r0, r3, r0

        //
        // Divide finished, update shift counters for next divide.
        // re-loop if more operations are needed.
        //
        clz     r4, r2
        cmp     r4, r12
    ble   divmore9

    //
    // Final Divide (Tail Divide)
    // Performs the last divide in the sequence, restores scratch registers,
    // adjusts sign bit.
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = dirty                     r12 = remaining shifts needed
    //
divfinished9
    lsl     r2, r2, r12
    lsl     r0, r0, r12
    udiv    r3, r2, r1
    add     r0, r3, r0
    teq     lr, #0
        it      eq
        rsbeq   r0, r0, #0
    pop     {r4, pc}

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ10div
//
//*****************************************************************************
    section CODE__IQ10div:CODE(2)
    thumb
    export  _IQ10div
_IQ10div
    //
    // Test for divide by zero.  Bail with positive overflow if so.
    //
    teq     r1, #0
    itt     eq
        mvneq   r0, #0x80000000
        bxeq    lr

    //
    // Save scratch registers
    //
    push    {r4, lr}

    // Save sign of result to lr
    //
    mov     lr, #1
    teq     r0, r1
        it      mi
        movmi   lr, #0

    //
    // Put operands into unsigned notation
    //
    cmp     r0, #0
        it      mi
        rsbmi   r0, r0, #0
    cmp     r1, #0
        it      mi
        rsbmi   r1, r1, #0
    //
    //
    // First Division
    // The first divide instruction is special, it includes some
    // of the register re-arranging and does overflow checking.
    //
    // Check how many bits can be handled in this first division
    // If all Q bits can be produced, bail early to divfinished
    //
    clz     r4, r0
    cmp     r4, #10
        it      ge
        movge   r4, #10
    lsl     r2, r0, r4
    rsb     r12, r4, #10

    //
    // r0 contains numerator, dirty
    // r1 contains denominator
    // r2 contains normalized numerator
    // r3 is dirty
    // r4 contains shiftable zeros, dirty
    // r12 contains the number of additional shifts required
    // lr contains sign flag.
    //
    // Perform the first division.
    //
    udiv    r0, r2, r1

    //
    // Check for overflow.
    // If overflow occurs, return 0x7F... or 0x80.. based on lr (sign flag).
    // Note that this assumes that the magnitude of the number is found on the
    // first shift.  This assumption has been empirically proven for
    // for all 10 bit numbers.
    //
    clz     r3, r0
    cmp     r12, r3
        itt     ge
        rsbge   r0, lr, #0x80000000
        popge   {r4, pc}

    //
    // Find the remainder and put it in r2 for future operations.
    //
    mls     r2, r1, r0, r2

    //
    // Determine how much to shift by.  This is the minimum of
    // the number of leading zeros and the number of shifts left
    // If this is the final divide, jump to the tail.
    //
    clz     r4, r2
    cmp     r4, r12
    bge     divfinished10

    //
    // Middle Divisions
    // This loop holds all the divisions other than the head and tail
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = #shifts this iteration    r12 = remaining shifts needed
    //
    // Prepare for the divide by normalizing remainder.
    //
divmore10
        sub     r12, r12, r4
        lsl     r2, r2, r4
        lsl     r0, r0, r4

        //
        // Perform the divide
        // We already know that an additional step is required, so do the
        // remainder calculation as well.
        //
        udiv    r3, r2, r1
        mls     r2, r1, r3, r2
        add     r0, r3, r0

        //
        // Divide finished, update shift counters for next divide.
        // re-loop if more operations are needed.
        //
        clz     r4, r2
        cmp     r4, r12
    ble   divmore10

    //
    // Final Divide (Tail Divide)
    // Performs the last divide in the sequence, restores scratch registers,
    // adjusts sign bit.
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = dirty                     r12 = remaining shifts needed
    //
divfinished10
    lsl     r2, r2, r12
    lsl     r0, r0, r12
    udiv    r3, r2, r1
    add     r0, r3, r0
    teq     lr, #0
        it      eq
        rsbeq   r0, r0, #0
    pop     {r4, pc}

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ11div
//
//*****************************************************************************
    section CODE__IQ11div:CODE(2)
    thumb
    export  _IQ11div
_IQ11div
    //
    // Test for divide by zero.  Bail with positive overflow if so.
    //
    teq     r1, #0
    itt     eq
        mvneq   r0, #0x80000000
        bxeq    lr

    //
    // Save scratch registers
    //
    push    {r4, lr}

    // Save sign of result to lr
    //
    mov     lr, #1
    teq     r0, r1
        it      mi
        movmi   lr, #0

    //
    // Put operands into unsigned notation
    //
    cmp     r0, #0
        it      mi
        rsbmi   r0, r0, #0
    cmp     r1, #0
        it      mi
        rsbmi   r1, r1, #0
    //
    //
    // First Division
    // The first divide instruction is special, it includes some
    // of the register re-arranging and does overflow checking.
    //
    // Check how many bits can be handled in this first division
    // If all Q bits can be produced, bail early to divfinished
    //
    clz     r4, r0
    cmp     r4, #11
        it      ge
        movge   r4, #11
    lsl     r2, r0, r4
    rsb     r12, r4, #11

    //
    // r0 contains numerator, dirty
    // r1 contains denominator
    // r2 contains normalized numerator
    // r3 is dirty
    // r4 contains shiftable zeros, dirty
    // r12 contains the number of additional shifts required
    // lr contains sign flag.
    //
    // Perform the first division.
    //
    udiv    r0, r2, r1

    //
    // Check for overflow.
    // If overflow occurs, return 0x7F... or 0x80.. based on lr (sign flag).
    // Note that this assumes that the magnitude of the number is found on the
    // first shift.  This assumption has been empirically proven for
    // for all 10 bit numbers.
    //
    clz     r3, r0
    cmp     r12, r3
        itt     ge
        rsbge   r0, lr, #0x80000000
        popge   {r4, pc}

    //
    // Find the remainder and put it in r2 for future operations.
    //
    mls     r2, r1, r0, r2

    //
    // Determine how much to shift by.  This is the minimum of
    // the number of leading zeros and the number of shifts left
    // If this is the final divide, jump to the tail.
    //
    clz     r4, r2
    cmp     r4, r12
    bge     divfinished11

    //
    // Middle Divisions
    // This loop holds all the divisions other than the head and tail
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = #shifts this iteration    r12 = remaining shifts needed
    //
    // Prepare for the divide by normalizing remainder.
    //
divmore11
        sub     r12, r12, r4
        lsl     r2, r2, r4
        lsl     r0, r0, r4

        //
        // Perform the divide
        // We already know that an additional step is required, so do the
        // remainder calculation as well.
        //
        udiv    r3, r2, r1
        mls     r2, r1, r3, r2
        add     r0, r3, r0

        //
        // Divide finished, update shift counters for next divide.
        // re-loop if more operations are needed.
        //
        clz     r4, r2
        cmp     r4, r12
    ble   divmore11

    //
    // Final Divide (Tail Divide)
    // Performs the last divide in the sequence, restores scratch registers,
    // adjusts sign bit.
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = dirty                     r12 = remaining shifts needed
    //
divfinished11
    lsl     r2, r2, r12
    lsl     r0, r0, r12
    udiv    r3, r2, r1
    add     r0, r3, r0
    teq     lr, #0
        it      eq
        rsbeq   r0, r0, #0
    pop     {r4, pc}

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ12div
//
//*****************************************************************************
    section CODE__IQ12div:CODE(2)
    thumb
    export  _IQ12div
_IQ12div
    //
    // Test for divide by zero.  Bail with positive overflow if so.
    //
    teq     r1, #0
    itt     eq
        mvneq   r0, #0x80000000
        bxeq    lr

    //
    // Save scratch registers
    //
    push    {r4, lr}

    // Save sign of result to lr
    //
    mov     lr, #1
    teq     r0, r1
        it      mi
        movmi   lr, #0

    //
    // Put operands into unsigned notation
    //
    cmp     r0, #0
        it      mi
        rsbmi   r0, r0, #0
    cmp     r1, #0
        it      mi
        rsbmi   r1, r1, #0
    //
    //
    // First Division
    // The first divide instruction is special, it includes some
    // of the register re-arranging and does overflow checking.
    //
    // Check how many bits can be handled in this first division
    // If all Q bits can be produced, bail early to divfinished
    //
    clz     r4, r0
    cmp     r4, #12
        it      ge
        movge   r4, #12
    lsl     r2, r0, r4
    rsb     r12, r4, #12

    //
    // r0 contains numerator, dirty
    // r1 contains denominator
    // r2 contains normalized numerator
    // r3 is dirty
    // r4 contains shiftable zeros, dirty
    // r12 contains the number of additional shifts required
    // lr contains sign flag.
    //
    // Perform the first division.
    //
    udiv    r0, r2, r1

    //
    // Check for overflow.
    // If overflow occurs, return 0x7F... or 0x80.. based on lr (sign flag).
    // Note that this assumes that the magnitude of the number is found on the
    // first shift.  This assumption has been empirically proven for
    // for all 10 bit numbers.
    //
    clz     r3, r0
    cmp     r12, r3
        itt     ge
        rsbge   r0, lr, #0x80000000
        popge   {r4, pc}

    //
    // Find the remainder and put it in r2 for future operations.
    //
    mls     r2, r1, r0, r2

    //
    // Determine how much to shift by.  This is the minimum of
    // the number of leading zeros and the number of shifts left
    // If this is the final divide, jump to the tail.
    //
    clz     r4, r2
    cmp     r4, r12
    bge     divfinished12

    //
    // Middle Divisions
    // This loop holds all the divisions other than the head and tail
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = #shifts this iteration    r12 = remaining shifts needed
    //
    // Prepare for the divide by normalizing remainder.
    //
divmore12
        sub     r12, r12, r4
        lsl     r2, r2, r4
        lsl     r0, r0, r4

        //
        // Perform the divide
        // We already know that an additional step is required, so do the
        // remainder calculation as well.
        //
        udiv    r3, r2, r1
        mls     r2, r1, r3, r2
        add     r0, r3, r0

        //
        // Divide finished, update shift counters for next divide.
        // re-loop if more operations are needed.
        //
        clz     r4, r2
        cmp     r4, r12
    ble   divmore12

    //
    // Final Divide (Tail Divide)
    // Performs the last divide in the sequence, restores scratch registers,
    // adjusts sign bit.
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = dirty                     r12 = remaining shifts needed
    //
divfinished12
    lsl     r2, r2, r12
    lsl     r0, r0, r12
    udiv    r3, r2, r1
    add     r0, r3, r0
    teq     lr, #0
        it      eq
        rsbeq   r0, r0, #0
    pop     {r4, pc}

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ13div
//
//*****************************************************************************
    section CODE__IQ13div:CODE(2)
    thumb
    export  _IQ13div
_IQ13div
    //
    // Test for divide by zero.  Bail with positive overflow if so.
    //
    teq     r1, #0
    itt     eq
        mvneq   r0, #0x80000000
        bxeq    lr

    //
    // Save scratch registers
    //
    push    {r4, lr}

    // Save sign of result to lr
    //
    mov     lr, #1
    teq     r0, r1
        it      mi
        movmi   lr, #0

    //
    // Put operands into unsigned notation
    //
    cmp     r0, #0
        it      mi
        rsbmi   r0, r0, #0
    cmp     r1, #0
        it      mi
        rsbmi   r1, r1, #0
    //
    //
    // First Division
    // The first divide instruction is special, it includes some
    // of the register re-arranging and does overflow checking.
    //
    // Check how many bits can be handled in this first division
    // If all Q bits can be produced, bail early to divfinished
    //
    clz     r4, r0
    cmp     r4, #13
        it      ge
        movge   r4, #13
    lsl     r2, r0, r4
    rsb     r12, r4, #13

    //
    // r0 contains numerator, dirty
    // r1 contains denominator
    // r2 contains normalized numerator
    // r3 is dirty
    // r4 contains shiftable zeros, dirty
    // r12 contains the number of additional shifts required
    // lr contains sign flag.
    //
    // Perform the first division.
    //
    udiv    r0, r2, r1

    //
    // Check for overflow.
    // If overflow occurs, return 0x7F... or 0x80.. based on lr (sign flag).
    // Note that this assumes that the magnitude of the number is found on the
    // first shift.  This assumption has been empirically proven for
    // for all 10 bit numbers.
    //
    clz     r3, r0
    cmp     r12, r3
        itt     ge
        rsbge   r0, lr, #0x80000000
        popge   {r4, pc}

    //
    // Find the remainder and put it in r2 for future operations.
    //
    mls     r2, r1, r0, r2

    //
    // Determine how much to shift by.  This is the minimum of
    // the number of leading zeros and the number of shifts left
    // If this is the final divide, jump to the tail.
    //
    clz     r4, r2
    cmp     r4, r12
    bge     divfinished13

    //
    // Middle Divisions
    // This loop holds all the divisions other than the head and tail
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = #shifts this iteration    r12 = remaining shifts needed
    //
    // Prepare for the divide by normalizing remainder.
    //
divmore13
        sub     r12, r12, r4
        lsl     r2, r2, r4
        lsl     r0, r0, r4

        //
        // Perform the divide
        // We already know that an additional step is required, so do the
        // remainder calculation as well.
        //
        udiv    r3, r2, r1
        mls     r2, r1, r3, r2
        add     r0, r3, r0

        //
        // Divide finished, update shift counters for next divide.
        // re-loop if more operations are needed.
        //
        clz     r4, r2
        cmp     r4, r12
    ble   divmore13

    //
    // Final Divide (Tail Divide)
    // Performs the last divide in the sequence, restores scratch registers,
    // adjusts sign bit.
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = dirty                     r12 = remaining shifts needed
    //
divfinished13
    lsl     r2, r2, r12
    lsl     r0, r0, r12
    udiv    r3, r2, r1
    add     r0, r3, r0
    teq     lr, #0
        it      eq
        rsbeq   r0, r0, #0
    pop     {r4, pc}

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ14div
//
//*****************************************************************************
    section CODE__IQ14div:CODE(2)
    thumb
    export  _IQ14div
_IQ14div
    //
    // Test for divide by zero.  Bail with positive overflow if so.
    //
    teq     r1, #0
    itt     eq
        mvneq   r0, #0x80000000
        bxeq    lr

    //
    // Save scratch registers
    //
    push    {r4, lr}

    // Save sign of result to lr
    //
    mov     lr, #1
    teq     r0, r1
        it      mi
        movmi   lr, #0

    //
    // Put operands into unsigned notation
    //
    cmp     r0, #0
        it      mi
        rsbmi   r0, r0, #0
    cmp     r1, #0
        it      mi
        rsbmi   r1, r1, #0
    //
    //
    // First Division
    // The first divide instruction is special, it includes some
    // of the register re-arranging and does overflow checking.
    //
    // Check how many bits can be handled in this first division
    // If all Q bits can be produced, bail early to divfinished
    //
    clz     r4, r0
    cmp     r4, #14
        it      ge
        movge   r4, #14
    lsl     r2, r0, r4
    rsb     r12, r4, #14

    //
    // r0 contains numerator, dirty
    // r1 contains denominator
    // r2 contains normalized numerator
    // r3 is dirty
    // r4 contains shiftable zeros, dirty
    // r12 contains the number of additional shifts required
    // lr contains sign flag.
    //
    // Perform the first division.
    //
    udiv    r0, r2, r1

    //
    // Check for overflow.
    // If overflow occurs, return 0x7F... or 0x80.. based on lr (sign flag).
    // Note that this assumes that the magnitude of the number is found on the
    // first shift.  This assumption has been empirically proven for
    // for all 10 bit numbers.
    //
    clz     r3, r0
    cmp     r12, r3
        itt     ge
        rsbge   r0, lr, #0x80000000
        popge   {r4, pc}

    //
    // Find the remainder and put it in r2 for future operations.
    //
    mls     r2, r1, r0, r2

    //
    // Determine how much to shift by.  This is the minimum of
    // the number of leading zeros and the number of shifts left
    // If this is the final divide, jump to the tail.
    //
    clz     r4, r2
    cmp     r4, r12
    bge     divfinished14

    //
    // Middle Divisions
    // This loop holds all the divisions other than the head and tail
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = #shifts this iteration    r12 = remaining shifts needed
    //
    // Prepare for the divide by normalizing remainder.
    //
divmore14
        sub     r12, r12, r4
        lsl     r2, r2, r4
        lsl     r0, r0, r4

        //
        // Perform the divide
        // We already know that an additional step is required, so do the
        // remainder calculation as well.
        //
        udiv    r3, r2, r1
        mls     r2, r1, r3, r2
        add     r0, r3, r0

        //
        // Divide finished, update shift counters for next divide.
        // re-loop if more operations are needed.
        //
        clz     r4, r2
        cmp     r4, r12
    ble   divmore14

    //
    // Final Divide (Tail Divide)
    // Performs the last divide in the sequence, restores scratch registers,
    // adjusts sign bit.
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = dirty                     r12 = remaining shifts needed
    //
divfinished14
    lsl     r2, r2, r12
    lsl     r0, r0, r12
    udiv    r3, r2, r1
    add     r0, r3, r0
    teq     lr, #0
        it      eq
        rsbeq   r0, r0, #0
    pop     {r4, pc}

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ15div
//
//*****************************************************************************
    section CODE__IQ15div:CODE(2)
    thumb
    export  _IQ15div
_IQ15div
    //
    // Test for divide by zero.  Bail with positive overflow if so.
    //
    teq     r1, #0
    itt     eq
        mvneq   r0, #0x80000000
        bxeq    lr

    //
    // Save scratch registers
    //
    push    {r4, lr}

    // Save sign of result to lr
    //
    mov     lr, #1
    teq     r0, r1
        it      mi
        movmi   lr, #0

    //
    // Put operands into unsigned notation
    //
    cmp     r0, #0
        it      mi
        rsbmi   r0, r0, #0
    cmp     r1, #0
        it      mi
        rsbmi   r1, r1, #0
    //
    //
    // First Division
    // The first divide instruction is special, it includes some
    // of the register re-arranging and does overflow checking.
    //
    // Check how many bits can be handled in this first division
    // If all Q bits can be produced, bail early to divfinished
    //
    clz     r4, r0
    cmp     r4, #15
        it      ge
        movge   r4, #15
    lsl     r2, r0, r4
    rsb     r12, r4, #15

    //
    // r0 contains numerator, dirty
    // r1 contains denominator
    // r2 contains normalized numerator
    // r3 is dirty
    // r4 contains shiftable zeros, dirty
    // r12 contains the number of additional shifts required
    // lr contains sign flag.
    //
    // Perform the first division.
    //
    udiv    r0, r2, r1

    //
    // Check for overflow.
    // If overflow occurs, return 0x7F... or 0x80.. based on lr (sign flag).
    // Note that this assumes that the magnitude of the number is found on the
    // first shift.  This assumption has been empirically proven for
    // for all 10 bit numbers.
    //
    clz     r3, r0
    cmp     r12, r3
        itt     ge
        rsbge   r0, lr, #0x80000000
        popge   {r4, pc}

    //
    // Find the remainder and put it in r2 for future operations.
    //
    mls     r2, r1, r0, r2

    //
    // Determine how much to shift by.  This is the minimum of
    // the number of leading zeros and the number of shifts left
    // If this is the final divide, jump to the tail.
    //
    clz     r4, r2
    cmp     r4, r12
    bge     divfinished15

    //
    // Middle Divisions
    // This loop holds all the divisions other than the head and tail
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = #shifts this iteration    r12 = remaining shifts needed
    //
    // Prepare for the divide by normalizing remainder.
    //
divmore15
        sub     r12, r12, r4
        lsl     r2, r2, r4
        lsl     r0, r0, r4

        //
        // Perform the divide
        // We already know that an additional step is required, so do the
        // remainder calculation as well.
        //
        udiv    r3, r2, r1
        mls     r2, r1, r3, r2
        add     r0, r3, r0

        //
        // Divide finished, update shift counters for next divide.
        // re-loop if more operations are needed.
        //
        clz     r4, r2
        cmp     r4, r12
    ble   divmore15

    //
    // Final Divide (Tail Divide)
    // Performs the last divide in the sequence, restores scratch registers,
    // adjusts sign bit.
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = dirty                     r12 = remaining shifts needed
    //
divfinished15
    lsl     r2, r2, r12
    lsl     r0, r0, r12
    udiv    r3, r2, r1
    add     r0, r3, r0
    teq     lr, #0
        it      eq
        rsbeq   r0, r0, #0
    pop     {r4, pc}

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ16div
//
//*****************************************************************************
    section CODE__IQ16div:CODE(2)
    thumb
    export  _IQ16div
_IQ16div
    //
    // Test for divide by zero.  Bail with positive overflow if so.
    //
    teq     r1, #0
    itt     eq
        mvneq   r0, #0x80000000
        bxeq    lr

    //
    // Save scratch registers
    //
    push    {r4, lr}

    // Save sign of result to lr
    //
    mov     lr, #1
    teq     r0, r1
        it      mi
        movmi   lr, #0

    //
    // Put operands into unsigned notation
    //
    cmp     r0, #0
        it      mi
        rsbmi   r0, r0, #0
    cmp     r1, #0
        it      mi
        rsbmi   r1, r1, #0
    //
    //
    // First Division
    // The first divide instruction is special, it includes some
    // of the register re-arranging and does overflow checking.
    //
    // Check how many bits can be handled in this first division
    // If all Q bits can be produced, bail early to divfinished
    //
    clz     r4, r0
    cmp     r4, #16
        it      ge
        movge   r4, #16
    lsl     r2, r0, r4
    rsb     r12, r4, #16

    //
    // r0 contains numerator, dirty
    // r1 contains denominator
    // r2 contains normalized numerator
    // r3 is dirty
    // r4 contains shiftable zeros, dirty
    // r12 contains the number of additional shifts required
    // lr contains sign flag.
    //
    // Perform the first division.
    //
    udiv    r0, r2, r1

    //
    // Check for overflow.
    // If overflow occurs, return 0x7F... or 0x80.. based on lr (sign flag).
    // Note that this assumes that the magnitude of the number is found on the
    // first shift.  This assumption has been empirically proven for
    // for all 10 bit numbers.
    //
    clz     r3, r0
    cmp     r12, r3
        itt     ge
        rsbge   r0, lr, #0x80000000
        popge   {r4, pc}

    //
    // Find the remainder and put it in r2 for future operations.
    //
    mls     r2, r1, r0, r2

    //
    // Determine how much to shift by.  This is the minimum of
    // the number of leading zeros and the number of shifts left
    // If this is the final divide, jump to the tail.
    //
    clz     r4, r2
    cmp     r4, r12
    bge     divfinished16

    //
    // Middle Divisions
    // This loop holds all the divisions other than the head and tail
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = #shifts this iteration    r12 = remaining shifts needed
    //
    // Prepare for the divide by normalizing remainder.
    //
divmore16
        sub     r12, r12, r4
        lsl     r2, r2, r4
        lsl     r0, r0, r4

        //
        // Perform the divide
        // We already know that an additional step is required, so do the
        // remainder calculation as well.
        //
        udiv    r3, r2, r1
        mls     r2, r1, r3, r2
        add     r0, r3, r0

        //
        // Divide finished, update shift counters for next divide.
        // re-loop if more operations are needed.
        //
        clz     r4, r2
        cmp     r4, r12
    ble   divmore16

    //
    // Final Divide (Tail Divide)
    // Performs the last divide in the sequence, restores scratch registers,
    // adjusts sign bit.
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = dirty                     r12 = remaining shifts needed
    //
divfinished16
    lsl     r2, r2, r12
    lsl     r0, r0, r12
    udiv    r3, r2, r1
    add     r0, r3, r0
    teq     lr, #0
        it      eq
        rsbeq   r0, r0, #0
    pop     {r4, pc}

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ17div
//
//*****************************************************************************
    section CODE__IQ17div:CODE(2)
    thumb
    export  _IQ17div
_IQ17div
    //
    // Test for divide by zero.  Bail with positive overflow if so.
    //
    teq     r1, #0
    itt     eq
        mvneq   r0, #0x80000000
        bxeq    lr

    //
    // Save scratch registers
    //
    push    {r4, lr}

    // Save sign of result to lr
    //
    mov     lr, #1
    teq     r0, r1
        it      mi
        movmi   lr, #0

    //
    // Put operands into unsigned notation
    //
    cmp     r0, #0
        it      mi
        rsbmi   r0, r0, #0
    cmp     r1, #0
        it      mi
        rsbmi   r1, r1, #0
    //
    //
    // First Division
    // The first divide instruction is special, it includes some
    // of the register re-arranging and does overflow checking.
    //
    // Check how many bits can be handled in this first division
    // If all Q bits can be produced, bail early to divfinished
    //
    clz     r4, r0
    cmp     r4, #17
        it      ge
        movge   r4, #17
    lsl     r2, r0, r4
    rsb     r12, r4, #17

    //
    // r0 contains numerator, dirty
    // r1 contains denominator
    // r2 contains normalized numerator
    // r3 is dirty
    // r4 contains shiftable zeros, dirty
    // r12 contains the number of additional shifts required
    // lr contains sign flag.
    //
    // Perform the first division.
    //
    udiv    r0, r2, r1

    //
    // Check for overflow.
    // If overflow occurs, return 0x7F... or 0x80.. based on lr (sign flag).
    // Note that this assumes that the magnitude of the number is found on the
    // first shift.  This assumption has been empirically proven for
    // for all 10 bit numbers.
    //
    clz     r3, r0
    cmp     r12, r3
        itt     ge
        rsbge   r0, lr, #0x80000000
        popge   {r4, pc}

    //
    // Find the remainder and put it in r2 for future operations.
    //
    mls     r2, r1, r0, r2

    //
    // Determine how much to shift by.  This is the minimum of
    // the number of leading zeros and the number of shifts left
    // If this is the final divide, jump to the tail.
    //
    clz     r4, r2
    cmp     r4, r12
    bge     divfinished17

    //
    // Middle Divisions
    // This loop holds all the divisions other than the head and tail
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = #shifts this iteration    r12 = remaining shifts needed
    //
    // Prepare for the divide by normalizing remainder.
    //
divmore17
        sub     r12, r12, r4
        lsl     r2, r2, r4
        lsl     r0, r0, r4

        //
        // Perform the divide
        // We already know that an additional step is required, so do the
        // remainder calculation as well.
        //
        udiv    r3, r2, r1
        mls     r2, r1, r3, r2
        add     r0, r3, r0

        //
        // Divide finished, update shift counters for next divide.
        // re-loop if more operations are needed.
        //
        clz     r4, r2
        cmp     r4, r12
    ble   divmore17

    //
    // Final Divide (Tail Divide)
    // Performs the last divide in the sequence, restores scratch registers,
    // adjusts sign bit.
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = dirty                     r12 = remaining shifts needed
    //
divfinished17
    lsl     r2, r2, r12
    lsl     r0, r0, r12
    udiv    r3, r2, r1
    add     r0, r3, r0
    teq     lr, #0
        it      eq
        rsbeq   r0, r0, #0
    pop     {r4, pc}

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ18div
//
//*****************************************************************************
    section CODE__IQ18div:CODE(2)
    thumb
    export  _IQ18div
_IQ18div
    //
    // Test for divide by zero.  Bail with positive overflow if so.
    //
    teq     r1, #0
    itt     eq
        mvneq   r0, #0x80000000
        bxeq    lr

    //
    // Save scratch registers
    //
    push    {r4, lr}

    // Save sign of result to lr
    //
    mov     lr, #1
    teq     r0, r1
        it      mi
        movmi   lr, #0

    //
    // Put operands into unsigned notation
    //
    cmp     r0, #0
        it      mi
        rsbmi   r0, r0, #0
    cmp     r1, #0
        it      mi
        rsbmi   r1, r1, #0
    //
    //
    // First Division
    // The first divide instruction is special, it includes some
    // of the register re-arranging and does overflow checking.
    //
    // Check how many bits can be handled in this first division
    // If all Q bits can be produced, bail early to divfinished
    //
    clz     r4, r0
    cmp     r4, #18
        it      ge
        movge   r4, #18
    lsl     r2, r0, r4
    rsb     r12, r4, #18

    //
    // r0 contains numerator, dirty
    // r1 contains denominator
    // r2 contains normalized numerator
    // r3 is dirty
    // r4 contains shiftable zeros, dirty
    // r12 contains the number of additional shifts required
    // lr contains sign flag.
    //
    // Perform the first division.
    //
    udiv    r0, r2, r1

    //
    // Check for overflow.
    // If overflow occurs, return 0x7F... or 0x80.. based on lr (sign flag).
    // Note that this assumes that the magnitude of the number is found on the
    // first shift.  This assumption has been empirically proven for
    // for all 10 bit numbers.
    //
    clz     r3, r0
    cmp     r12, r3
        itt     ge
        rsbge   r0, lr, #0x80000000
        popge   {r4, pc}

    //
    // Find the remainder and put it in r2 for future operations.
    //
    mls     r2, r1, r0, r2

    //
    // Determine how much to shift by.  This is the minimum of
    // the number of leading zeros and the number of shifts left
    // If this is the final divide, jump to the tail.
    //
    clz     r4, r2
    cmp     r4, r12
    bge     divfinished18

    //
    // Middle Divisions
    // This loop holds all the divisions other than the head and tail
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = #shifts this iteration    r12 = remaining shifts needed
    //
    // Prepare for the divide by normalizing remainder.
    //
divmore18
        sub     r12, r12, r4
        lsl     r2, r2, r4
        lsl     r0, r0, r4

        //
        // Perform the divide
        // We already know that an additional step is required, so do the
        // remainder calculation as well.
        //
        udiv    r3, r2, r1
        mls     r2, r1, r3, r2
        add     r0, r3, r0

        //
        // Divide finished, update shift counters for next divide.
        // re-loop if more operations are needed.
        //
        clz     r4, r2
        cmp     r4, r12
    ble   divmore18

    //
    // Final Divide (Tail Divide)
    // Performs the last divide in the sequence, restores scratch registers,
    // adjusts sign bit.
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = dirty                     r12 = remaining shifts needed
    //
divfinished18
    lsl     r2, r2, r12
    lsl     r0, r0, r12
    udiv    r3, r2, r1
    add     r0, r3, r0
    teq     lr, #0
        it      eq
        rsbeq   r0, r0, #0
    pop     {r4, pc}

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ19div
//
//*****************************************************************************
    section CODE__IQ19div:CODE(2)
    thumb
    export  _IQ19div
_IQ19div
    //
    // Test for divide by zero.  Bail with positive overflow if so.
    //
    teq     r1, #0
    itt     eq
        mvneq   r0, #0x80000000
        bxeq    lr

    //
    // Save scratch registers
    //
    push    {r4, lr}

    // Save sign of result to lr
    //
    mov     lr, #1
    teq     r0, r1
        it      mi
        movmi   lr, #0

    //
    // Put operands into unsigned notation
    //
    cmp     r0, #0
        it      mi
        rsbmi   r0, r0, #0
    cmp     r1, #0
        it      mi
        rsbmi   r1, r1, #0
    //
    //
    // First Division
    // The first divide instruction is special, it includes some
    // of the register re-arranging and does overflow checking.
    //
    // Check how many bits can be handled in this first division
    // If all Q bits can be produced, bail early to divfinished
    //
    clz     r4, r0
    cmp     r4, #19
        it      ge
        movge   r4, #19
    lsl     r2, r0, r4
    rsb     r12, r4, #19

    //
    // r0 contains numerator, dirty
    // r1 contains denominator
    // r2 contains normalized numerator
    // r3 is dirty
    // r4 contains shiftable zeros, dirty
    // r12 contains the number of additional shifts required
    // lr contains sign flag.
    //
    // Perform the first division.
    //
    udiv    r0, r2, r1

    //
    // Check for overflow.
    // If overflow occurs, return 0x7F... or 0x80.. based on lr (sign flag).
    // Note that this assumes that the magnitude of the number is found on the
    // first shift.  This assumption has been empirically proven for
    // for all 10 bit numbers.
    //
    clz     r3, r0
    cmp     r12, r3
        itt     ge
        rsbge   r0, lr, #0x80000000
        popge   {r4, pc}

    //
    // Find the remainder and put it in r2 for future operations.
    //
    mls     r2, r1, r0, r2

    //
    // Determine how much to shift by.  This is the minimum of
    // the number of leading zeros and the number of shifts left
    // If this is the final divide, jump to the tail.
    //
    clz     r4, r2
    cmp     r4, r12
    bge     divfinished19

    //
    // Middle Divisions
    // This loop holds all the divisions other than the head and tail
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = #shifts this iteration    r12 = remaining shifts needed
    //
    // Prepare for the divide by normalizing remainder.
    //
divmore19
        sub     r12, r12, r4
        lsl     r2, r2, r4
        lsl     r0, r0, r4

        //
        // Perform the divide
        // We already know that an additional step is required, so do the
        // remainder calculation as well.
        //
        udiv    r3, r2, r1
        mls     r2, r1, r3, r2
        add     r0, r3, r0

        //
        // Divide finished, update shift counters for next divide.
        // re-loop if more operations are needed.
        //
        clz     r4, r2
        cmp     r4, r12
    ble   divmore19

    //
    // Final Divide (Tail Divide)
    // Performs the last divide in the sequence, restores scratch registers,
    // adjusts sign bit.
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = dirty                     r12 = remaining shifts needed
    //
divfinished19
    lsl     r2, r2, r12
    lsl     r0, r0, r12
    udiv    r3, r2, r1
    add     r0, r3, r0
    teq     lr, #0
        it      eq
        rsbeq   r0, r0, #0
    pop     {r4, pc}

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ20div
//
//*****************************************************************************
    section CODE__IQ20div:CODE(2)
    thumb
    export  _IQ20div
_IQ20div
    //
    // Test for divide by zero.  Bail with positive overflow if so.
    //
    teq     r1, #0
    itt     eq
        mvneq   r0, #0x80000000
        bxeq    lr

    //
    // Save scratch registers
    //
    push    {r4, lr}

    // Save sign of result to lr
    //
    mov     lr, #1
    teq     r0, r1
        it      mi
        movmi   lr, #0

    //
    // Put operands into unsigned notation
    //
    cmp     r0, #0
        it      mi
        rsbmi   r0, r0, #0
    cmp     r1, #0
        it      mi
        rsbmi   r1, r1, #0
    //
    //
    // First Division
    // The first divide instruction is special, it includes some
    // of the register re-arranging and does overflow checking.
    //
    // Check how many bits can be handled in this first division
    // If all Q bits can be produced, bail early to divfinished
    //
    clz     r4, r0
    cmp     r4, #20
        it      ge
        movge   r4, #20
    lsl     r2, r0, r4
    rsb     r12, r4, #20

    //
    // r0 contains numerator, dirty
    // r1 contains denominator
    // r2 contains normalized numerator
    // r3 is dirty
    // r4 contains shiftable zeros, dirty
    // r12 contains the number of additional shifts required
    // lr contains sign flag.
    //
    // Perform the first division.
    //
    udiv    r0, r2, r1

    //
    // Check for overflow.
    // If overflow occurs, return 0x7F... or 0x80.. based on lr (sign flag).
    // Note that this assumes that the magnitude of the number is found on the
    // first shift.  This assumption has been empirically proven for
    // for all 10 bit numbers.
    //
    clz     r3, r0
    cmp     r12, r3
        itt     ge
        rsbge   r0, lr, #0x80000000
        popge   {r4, pc}

    //
    // Find the remainder and put it in r2 for future operations.
    //
    mls     r2, r1, r0, r2

    //
    // Determine how much to shift by.  This is the minimum of
    // the number of leading zeros and the number of shifts left
    // If this is the final divide, jump to the tail.
    //
    clz     r4, r2
    cmp     r4, r12
    bge     divfinished20

    //
    // Middle Divisions
    // This loop holds all the divisions other than the head and tail
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = #shifts this iteration    r12 = remaining shifts needed
    //
    // Prepare for the divide by normalizing remainder.
    //
divmore20
        sub     r12, r12, r4
        lsl     r2, r2, r4
        lsl     r0, r0, r4

        //
        // Perform the divide
        // We already know that an additional step is required, so do the
        // remainder calculation as well.
        //
        udiv    r3, r2, r1
        mls     r2, r1, r3, r2
        add     r0, r3, r0

        //
        // Divide finished, update shift counters for next divide.
        // re-loop if more operations are needed.
        //
        clz     r4, r2
        cmp     r4, r12
    ble   divmore20

    //
    // Final Divide (Tail Divide)
    // Performs the last divide in the sequence, restores scratch registers,
    // adjusts sign bit.
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = dirty                     r12 = remaining shifts needed
    //
divfinished20
    lsl     r2, r2, r12
    lsl     r0, r0, r12
    udiv    r3, r2, r1
    add     r0, r3, r0
    teq     lr, #0
        it      eq
        rsbeq   r0, r0, #0
    pop     {r4, pc}

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ21div
//
//*****************************************************************************
    section CODE__IQ21div:CODE(2)
    thumb
    export  _IQ21div
_IQ21div
    //
    // Test for divide by zero.  Bail with positive overflow if so.
    //
    teq     r1, #0
    itt     eq
        mvneq   r0, #0x80000000
        bxeq    lr

    //
    // Save scratch registers
    //
    push    {r4, lr}

    // Save sign of result to lr
    //
    mov     lr, #1
    teq     r0, r1
        it      mi
        movmi   lr, #0

    //
    // Put operands into unsigned notation
    //
    cmp     r0, #0
        it      mi
        rsbmi   r0, r0, #0
    cmp     r1, #0
        it      mi
        rsbmi   r1, r1, #0
    //
    //
    // First Division
    // The first divide instruction is special, it includes some
    // of the register re-arranging and does overflow checking.
    //
    // Check how many bits can be handled in this first division
    // If all Q bits can be produced, bail early to divfinished
    //
    clz     r4, r0
    cmp     r4, #21
        it      ge
        movge   r4, #21
    lsl     r2, r0, r4
    rsb     r12, r4, #21

    //
    // r0 contains numerator, dirty
    // r1 contains denominator
    // r2 contains normalized numerator
    // r3 is dirty
    // r4 contains shiftable zeros, dirty
    // r12 contains the number of additional shifts required
    // lr contains sign flag.
    //
    // Perform the first division.
    //
    udiv    r0, r2, r1

    //
    // Check for overflow.
    // If overflow occurs, return 0x7F... or 0x80.. based on lr (sign flag).
    // Note that this assumes that the magnitude of the number is found on the
    // first shift.  This assumption has been empirically proven for
    // for all 10 bit numbers.
    //
    clz     r3, r0
    cmp     r12, r3
        itt     ge
        rsbge   r0, lr, #0x80000000
        popge   {r4, pc}

    //
    // Find the remainder and put it in r2 for future operations.
    //
    mls     r2, r1, r0, r2

    //
    // Determine how much to shift by.  This is the minimum of
    // the number of leading zeros and the number of shifts left
    // If this is the final divide, jump to the tail.
    //
    clz     r4, r2
    cmp     r4, r12
    bge     divfinished21

    //
    // Middle Divisions
    // This loop holds all the divisions other than the head and tail
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = #shifts this iteration    r12 = remaining shifts needed
    //
    // Prepare for the divide by normalizing remainder.
    //
divmore21
        sub     r12, r12, r4
        lsl     r2, r2, r4
        lsl     r0, r0, r4

        //
        // Perform the divide
        // We already know that an additional step is required, so do the
        // remainder calculation as well.
        //
        udiv    r3, r2, r1
        mls     r2, r1, r3, r2
        add     r0, r3, r0

        //
        // Divide finished, update shift counters for next divide.
        // re-loop if more operations are needed.
        //
        clz     r4, r2
        cmp     r4, r12
    ble   divmore21

    //
    // Final Divide (Tail Divide)
    // Performs the last divide in the sequence, restores scratch registers,
    // adjusts sign bit.
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = dirty                     r12 = remaining shifts needed
    //
divfinished21
    lsl     r2, r2, r12
    lsl     r0, r0, r12
    udiv    r3, r2, r1
    add     r0, r3, r0
    teq     lr, #0
        it      eq
        rsbeq   r0, r0, #0
    pop     {r4, pc}

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ22div
//
//*****************************************************************************
    section CODE__IQ22div:CODE(2)
    thumb
    export  _IQ22div
_IQ22div
    //
    // Test for divide by zero.  Bail with positive overflow if so.
    //
    teq     r1, #0
    itt     eq
        mvneq   r0, #0x80000000
        bxeq    lr

    //
    // Save scratch registers
    //
    push    {r4, lr}

    // Save sign of result to lr
    //
    mov     lr, #1
    teq     r0, r1
        it      mi
        movmi   lr, #0

    //
    // Put operands into unsigned notation
    //
    cmp     r0, #0
        it      mi
        rsbmi   r0, r0, #0
    cmp     r1, #0
        it      mi
        rsbmi   r1, r1, #0
    //
    //
    // First Division
    // The first divide instruction is special, it includes some
    // of the register re-arranging and does overflow checking.
    //
    // Check how many bits can be handled in this first division
    // If all Q bits can be produced, bail early to divfinished
    //
    clz     r4, r0
    cmp     r4, #22
        it      ge
        movge   r4, #22
    lsl     r2, r0, r4
    rsb     r12, r4, #22

    //
    // r0 contains numerator, dirty
    // r1 contains denominator
    // r2 contains normalized numerator
    // r3 is dirty
    // r4 contains shiftable zeros, dirty
    // r12 contains the number of additional shifts required
    // lr contains sign flag.
    //
    // Perform the first division.
    //
    udiv    r0, r2, r1

    //
    // Check for overflow.
    // If overflow occurs, return 0x7F... or 0x80.. based on lr (sign flag).
    // Note that this assumes that the magnitude of the number is found on the
    // first shift.  This assumption has been empirically proven for
    // for all 10 bit numbers.
    //
    clz     r3, r0
    cmp     r12, r3
        itt     ge
        rsbge   r0, lr, #0x80000000
        popge   {r4, pc}

    //
    // Find the remainder and put it in r2 for future operations.
    //
    mls     r2, r1, r0, r2

    //
    // Determine how much to shift by.  This is the minimum of
    // the number of leading zeros and the number of shifts left
    // If this is the final divide, jump to the tail.
    //
    clz     r4, r2
    cmp     r4, r12
    bge     divfinished22

    //
    // Middle Divisions
    // This loop holds all the divisions other than the head and tail
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = #shifts this iteration    r12 = remaining shifts needed
    //
    // Prepare for the divide by normalizing remainder.
    //
divmore22
        sub     r12, r12, r4
        lsl     r2, r2, r4
        lsl     r0, r0, r4

        //
        // Perform the divide
        // We already know that an additional step is required, so do the
        // remainder calculation as well.
        //
        udiv    r3, r2, r1
        mls     r2, r1, r3, r2
        add     r0, r3, r0

        //
        // Divide finished, update shift counters for next divide.
        // re-loop if more operations are needed.
        //
        clz     r4, r2
        cmp     r4, r12
    ble   divmore22

    //
    // Final Divide (Tail Divide)
    // Performs the last divide in the sequence, restores scratch registers,
    // adjusts sign bit.
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = dirty                     r12 = remaining shifts needed
    //
divfinished22
    lsl     r2, r2, r12
    lsl     r0, r0, r12
    udiv    r3, r2, r1
    add     r0, r3, r0
    teq     lr, #0
        it      eq
        rsbeq   r0, r0, #0
    pop     {r4, pc}

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ23div
//
//*****************************************************************************
    section CODE__IQ23div:CODE(2)
    thumb
    export  _IQ23div
_IQ23div
    //
    // Test for divide by zero.  Bail with positive overflow if so.
    //
    teq     r1, #0
    itt     eq
        mvneq   r0, #0x80000000
        bxeq    lr

    //
    // Save scratch registers
    //
    push    {r4, lr}

    // Save sign of result to lr
    //
    mov     lr, #1
    teq     r0, r1
        it      mi
        movmi   lr, #0

    //
    // Put operands into unsigned notation
    //
    cmp     r0, #0
        it      mi
        rsbmi   r0, r0, #0
    cmp     r1, #0
        it      mi
        rsbmi   r1, r1, #0
    //
    //
    // First Division
    // The first divide instruction is special, it includes some
    // of the register re-arranging and does overflow checking.
    //
    // Check how many bits can be handled in this first division
    // If all Q bits can be produced, bail early to divfinished
    //
    clz     r4, r0
    cmp     r4, #23
        it      ge
        movge   r4, #23
    lsl     r2, r0, r4
    rsb     r12, r4, #23

    //
    // r0 contains numerator, dirty
    // r1 contains denominator
    // r2 contains normalized numerator
    // r3 is dirty
    // r4 contains shiftable zeros, dirty
    // r12 contains the number of additional shifts required
    // lr contains sign flag.
    //
    // Perform the first division.
    //
    udiv    r0, r2, r1

    //
    // Check for overflow.
    // If overflow occurs, return 0x7F... or 0x80.. based on lr (sign flag).
    // Note that this assumes that the magnitude of the number is found on the
    // first shift.  This assumption has been empirically proven for
    // for all 10 bit numbers.
    //
    clz     r3, r0
    cmp     r12, r3
        itt     ge
        rsbge   r0, lr, #0x80000000
        popge   {r4, pc}

    //
    // Find the remainder and put it in r2 for future operations.
    //
    mls     r2, r1, r0, r2

    //
    // Determine how much to shift by.  This is the minimum of
    // the number of leading zeros and the number of shifts left
    // If this is the final divide, jump to the tail.
    //
    clz     r4, r2
    cmp     r4, r12
    bge     divfinished23

    //
    // Middle Divisions
    // This loop holds all the divisions other than the head and tail
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = #shifts this iteration    r12 = remaining shifts needed
    //
    // Prepare for the divide by normalizing remainder.
    //
divmore23
        sub     r12, r12, r4
        lsl     r2, r2, r4
        lsl     r0, r0, r4

        //
        // Perform the divide
        // We already know that an additional step is required, so do the
        // remainder calculation as well.
        //
        udiv    r3, r2, r1
        mls     r2, r1, r3, r2
        add     r0, r3, r0

        //
        // Divide finished, update shift counters for next divide.
        // re-loop if more operations are needed.
        //
        clz     r4, r2
        cmp     r4, r12
    ble   divmore23

    //
    // Final Divide (Tail Divide)
    // Performs the last divide in the sequence, restores scratch registers,
    // adjusts sign bit.
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = dirty                     r12 = remaining shifts needed
    //
divfinished23
    lsl     r2, r2, r12
    lsl     r0, r0, r12
    udiv    r3, r2, r1
    add     r0, r3, r0
    teq     lr, #0
        it      eq
        rsbeq   r0, r0, #0
    pop     {r4, pc}

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ24div
//
//*****************************************************************************
    section CODE__IQ24div:CODE(2)
    thumb
    export  _IQ24div
_IQ24div
    //
    // Test for divide by zero.  Bail with positive overflow if so.
    //
    teq     r1, #0
    itt     eq
        mvneq   r0, #0x80000000
        bxeq    lr

    //
    // Save scratch registers
    //
    push    {r4, lr}

    // Save sign of result to lr
    //
    mov     lr, #1
    teq     r0, r1
        it      mi
        movmi   lr, #0

    //
    // Put operands into unsigned notation
    //
    cmp     r0, #0
        it      mi
        rsbmi   r0, r0, #0
    cmp     r1, #0
        it      mi
        rsbmi   r1, r1, #0
    //
    //
    // First Division
    // The first divide instruction is special, it includes some
    // of the register re-arranging and does overflow checking.
    //
    // Check how many bits can be handled in this first division
    // If all Q bits can be produced, bail early to divfinished
    //
    clz     r4, r0
    cmp     r4, #24
        it      ge
        movge   r4, #24
    lsl     r2, r0, r4
    rsb     r12, r4, #24

    //
    // r0 contains numerator, dirty
    // r1 contains denominator
    // r2 contains normalized numerator
    // r3 is dirty
    // r4 contains shiftable zeros, dirty
    // r12 contains the number of additional shifts required
    // lr contains sign flag.
    //
    // Perform the first division.
    //
    udiv    r0, r2, r1

    //
    // Check for overflow.
    // If overflow occurs, return 0x7F... or 0x80.. based on lr (sign flag).
    // Note that this assumes that the magnitude of the number is found on the
    // first shift.  This assumption has been empirically proven for
    // for all 10 bit numbers.
    //
    clz     r3, r0
    cmp     r12, r3
        itt     ge
        rsbge   r0, lr, #0x80000000
        popge   {r4, pc}

    //
    // Find the remainder and put it in r2 for future operations.
    //
    mls     r2, r1, r0, r2

    //
    // Determine how much to shift by.  This is the minimum of
    // the number of leading zeros and the number of shifts left
    // If this is the final divide, jump to the tail.
    //
    clz     r4, r2
    cmp     r4, r12
    bge     divfinished24

    //
    // Middle Divisions
    // This loop holds all the divisions other than the head and tail
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = #shifts this iteration    r12 = remaining shifts needed
    //
    // Prepare for the divide by normalizing remainder.
    //
divmore24
        sub     r12, r12, r4
        lsl     r2, r2, r4
        lsl     r0, r0, r4

        //
        // Perform the divide
        // We already know that an additional step is required, so do the
        // remainder calculation as well.
        //
        udiv    r3, r2, r1
        mls     r2, r1, r3, r2
        add     r0, r3, r0

        //
        // Divide finished, update shift counters for next divide.
        // re-loop if more operations are needed.
        //
        clz     r4, r2
        cmp     r4, r12
    ble   divmore24

    //
    // Final Divide (Tail Divide)
    // Performs the last divide in the sequence, restores scratch registers,
    // adjusts sign bit.
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = dirty                     r12 = remaining shifts needed
    //
divfinished24
    lsl     r2, r2, r12
    lsl     r0, r0, r12
    udiv    r3, r2, r1
    add     r0, r3, r0
    teq     lr, #0
        it      eq
        rsbeq   r0, r0, #0
    pop     {r4, pc}

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ25div
//
//*****************************************************************************
    section CODE__IQ25div:CODE(2)
    thumb
    export  _IQ25div
_IQ25div
    //
    // Test for divide by zero.  Bail with positive overflow if so.
    //
    teq     r1, #0
    itt     eq
        mvneq   r0, #0x80000000
        bxeq    lr

    //
    // Save scratch registers
    //
    push    {r4, lr}

    // Save sign of result to lr
    //
    mov     lr, #1
    teq     r0, r1
        it      mi
        movmi   lr, #0

    //
    // Put operands into unsigned notation
    //
    cmp     r0, #0
        it      mi
        rsbmi   r0, r0, #0
    cmp     r1, #0
        it      mi
        rsbmi   r1, r1, #0
    //
    //
    // First Division
    // The first divide instruction is special, it includes some
    // of the register re-arranging and does overflow checking.
    //
    // Check how many bits can be handled in this first division
    // If all Q bits can be produced, bail early to divfinished
    //
    clz     r4, r0
    cmp     r4, #25
        it      ge
        movge   r4, #25
    lsl     r2, r0, r4
    rsb     r12, r4, #25

    //
    // r0 contains numerator, dirty
    // r1 contains denominator
    // r2 contains normalized numerator
    // r3 is dirty
    // r4 contains shiftable zeros, dirty
    // r12 contains the number of additional shifts required
    // lr contains sign flag.
    //
    // Perform the first division.
    //
    udiv    r0, r2, r1

    //
    // Check for overflow.
    // If overflow occurs, return 0x7F... or 0x80.. based on lr (sign flag).
    // Note that this assumes that the magnitude of the number is found on the
    // first shift.  This assumption has been empirically proven for
    // for all 10 bit numbers.
    //
    clz     r3, r0
    cmp     r12, r3
        itt     ge
        rsbge   r0, lr, #0x80000000
        popge   {r4, pc}

    //
    // Find the remainder and put it in r2 for future operations.
    //
    mls     r2, r1, r0, r2

    //
    // Determine how much to shift by.  This is the minimum of
    // the number of leading zeros and the number of shifts left
    // If this is the final divide, jump to the tail.
    //
    clz     r4, r2
    cmp     r4, r12
    bge     divfinished25

    //
    // Middle Divisions
    // This loop holds all the divisions other than the head and tail
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = #shifts this iteration    r12 = remaining shifts needed
    //
    // Prepare for the divide by normalizing remainder.
    //
divmore25
        sub     r12, r12, r4
        lsl     r2, r2, r4
        lsl     r0, r0, r4

        //
        // Perform the divide
        // We already know that an additional step is required, so do the
        // remainder calculation as well.
        //
        udiv    r3, r2, r1
        mls     r2, r1, r3, r2
        add     r0, r3, r0

        //
        // Divide finished, update shift counters for next divide.
        // re-loop if more operations are needed.
        //
        clz     r4, r2
        cmp     r4, r12
    ble   divmore25

    //
    // Final Divide (Tail Divide)
    // Performs the last divide in the sequence, restores scratch registers,
    // adjusts sign bit.
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = dirty                     r12 = remaining shifts needed
    //
divfinished25
    lsl     r2, r2, r12
    lsl     r0, r0, r12
    udiv    r3, r2, r1
    add     r0, r3, r0
    teq     lr, #0
        it      eq
        rsbeq   r0, r0, #0
    pop     {r4, pc}

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ26div
//
//*****************************************************************************
    section CODE__IQ26div:CODE(2)
    thumb
    export  _IQ26div
_IQ26div
    //
    // Test for divide by zero.  Bail with positive overflow if so.
    //
    teq     r1, #0
    itt     eq
        mvneq   r0, #0x80000000
        bxeq    lr

    //
    // Save scratch registers
    //
    push    {r4, lr}

    // Save sign of result to lr
    //
    mov     lr, #1
    teq     r0, r1
        it      mi
        movmi   lr, #0

    //
    // Put operands into unsigned notation
    //
    cmp     r0, #0
        it      mi
        rsbmi   r0, r0, #0
    cmp     r1, #0
        it      mi
        rsbmi   r1, r1, #0
    //
    //
    // First Division
    // The first divide instruction is special, it includes some
    // of the register re-arranging and does overflow checking.
    //
    // Check how many bits can be handled in this first division
    // If all Q bits can be produced, bail early to divfinished
    //
    clz     r4, r0
    cmp     r4, #26
        it      ge
        movge   r4, #26
    lsl     r2, r0, r4
    rsb     r12, r4, #26

    //
    // r0 contains numerator, dirty
    // r1 contains denominator
    // r2 contains normalized numerator
    // r3 is dirty
    // r4 contains shiftable zeros, dirty
    // r12 contains the number of additional shifts required
    // lr contains sign flag.
    //
    // Perform the first division.
    //
    udiv    r0, r2, r1

    //
    // Check for overflow.
    // If overflow occurs, return 0x7F... or 0x80.. based on lr (sign flag).
    // Note that this assumes that the magnitude of the number is found on the
    // first shift.  This assumption has been empirically proven for
    // for all 10 bit numbers.
    //
    clz     r3, r0
    cmp     r12, r3
        itt     ge
        rsbge   r0, lr, #0x80000000
        popge   {r4, pc}

    //
    // Find the remainder and put it in r2 for future operations.
    //
    mls     r2, r1, r0, r2

    //
    // Determine how much to shift by.  This is the minimum of
    // the number of leading zeros and the number of shifts left
    // If this is the final divide, jump to the tail.
    //
    clz     r4, r2
    cmp     r4, r12
    bge     divfinished26

    //
    // Middle Divisions
    // This loop holds all the divisions other than the head and tail
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = #shifts this iteration    r12 = remaining shifts needed
    //
    // Prepare for the divide by normalizing remainder.
    //
divmore26
        sub     r12, r12, r4
        lsl     r2, r2, r4
        lsl     r0, r0, r4

        //
        // Perform the divide
        // We already know that an additional step is required, so do the
        // remainder calculation as well.
        //
        udiv    r3, r2, r1
        mls     r2, r1, r3, r2
        add     r0, r3, r0

        //
        // Divide finished, update shift counters for next divide.
        // re-loop if more operations are needed.
        //
        clz     r4, r2
        cmp     r4, r12
    ble   divmore26

    //
    // Final Divide (Tail Divide)
    // Performs the last divide in the sequence, restores scratch registers,
    // adjusts sign bit.
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = dirty                     r12 = remaining shifts needed
    //
divfinished26
    lsl     r2, r2, r12
    lsl     r0, r0, r12
    udiv    r3, r2, r1
    add     r0, r3, r0
    teq     lr, #0
        it      eq
        rsbeq   r0, r0, #0
    pop     {r4, pc}

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ27div
//
//*****************************************************************************
    section CODE__IQ27div:CODE(2)
    thumb
    export  _IQ27div
_IQ27div
    //
    // Test for divide by zero.  Bail with positive overflow if so.
    //
    teq     r1, #0
    itt     eq
        mvneq   r0, #0x80000000
        bxeq    lr

    //
    // Save scratch registers
    //
    push    {r4, lr}

    // Save sign of result to lr
    //
    mov     lr, #1
    teq     r0, r1
        it      mi
        movmi   lr, #0

    //
    // Put operands into unsigned notation
    //
    cmp     r0, #0
        it      mi
        rsbmi   r0, r0, #0
    cmp     r1, #0
        it      mi
        rsbmi   r1, r1, #0
    //
    //
    // First Division
    // The first divide instruction is special, it includes some
    // of the register re-arranging and does overflow checking.
    //
    // Check how many bits can be handled in this first division
    // If all Q bits can be produced, bail early to divfinished
    //
    clz     r4, r0
    cmp     r4, #27
        it      ge
        movge   r4, #27
    lsl     r2, r0, r4
    rsb     r12, r4, #27

    //
    // r0 contains numerator, dirty
    // r1 contains denominator
    // r2 contains normalized numerator
    // r3 is dirty
    // r4 contains shiftable zeros, dirty
    // r12 contains the number of additional shifts required
    // lr contains sign flag.
    //
    // Perform the first division.
    //
    udiv    r0, r2, r1

    //
    // Check for overflow.
    // If overflow occurs, return 0x7F... or 0x80.. based on lr (sign flag).
    // Note that this assumes that the magnitude of the number is found on the
    // first shift.  This assumption has been empirically proven for
    // for all 10 bit numbers.
    //
    clz     r3, r0
    cmp     r12, r3
        itt     ge
        rsbge   r0, lr, #0x80000000
        popge   {r4, pc}

    //
    // Find the remainder and put it in r2 for future operations.
    //
    mls     r2, r1, r0, r2

    //
    // Determine how much to shift by.  This is the minimum of
    // the number of leading zeros and the number of shifts left
    // If this is the final divide, jump to the tail.
    //
    clz     r4, r2
    cmp     r4, r12
    bge     divfinished27

    //
    // Middle Divisions
    // This loop holds all the divisions other than the head and tail
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = #shifts this iteration    r12 = remaining shifts needed
    //
    // Prepare for the divide by normalizing remainder.
    //
divmore27
        sub     r12, r12, r4
        lsl     r2, r2, r4
        lsl     r0, r0, r4

        //
        // Perform the divide
        // We already know that an additional step is required, so do the
        // remainder calculation as well.
        //
        udiv    r3, r2, r1
        mls     r2, r1, r3, r2
        add     r0, r3, r0

        //
        // Divide finished, update shift counters for next divide.
        // re-loop if more operations are needed.
        //
        clz     r4, r2
        cmp     r4, r12
    ble   divmore27

    //
    // Final Divide (Tail Divide)
    // Performs the last divide in the sequence, restores scratch registers,
    // adjusts sign bit.
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = dirty                     r12 = remaining shifts needed
    //
divfinished27
    lsl     r2, r2, r12
    lsl     r0, r0, r12
    udiv    r3, r2, r1
    add     r0, r3, r0
    teq     lr, #0
        it      eq
        rsbeq   r0, r0, #0
    pop     {r4, pc}

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ28div
//
//*****************************************************************************
    section CODE__IQ28div:CODE(2)
    thumb
    export  _IQ28div
_IQ28div
    //
    // Test for divide by zero.  Bail with positive overflow if so.
    //
    teq     r1, #0
    itt     eq
        mvneq   r0, #0x80000000
        bxeq    lr

    //
    // Save scratch registers
    //
    push    {r4, lr}

    // Save sign of result to lr
    //
    mov     lr, #1
    teq     r0, r1
        it      mi
        movmi   lr, #0

    //
    // Put operands into unsigned notation
    //
    cmp     r0, #0
        it      mi
        rsbmi   r0, r0, #0
    cmp     r1, #0
        it      mi
        rsbmi   r1, r1, #0
    //
    //
    // First Division
    // The first divide instruction is special, it includes some
    // of the register re-arranging and does overflow checking.
    //
    // Check how many bits can be handled in this first division
    // If all Q bits can be produced, bail early to divfinished
    //
    clz     r4, r0
    cmp     r4, #28
        it      ge
        movge   r4, #28
    lsl     r2, r0, r4
    rsb     r12, r4, #28

    //
    // r0 contains numerator, dirty
    // r1 contains denominator
    // r2 contains normalized numerator
    // r3 is dirty
    // r4 contains shiftable zeros, dirty
    // r12 contains the number of additional shifts required
    // lr contains sign flag.
    //
    // Perform the first division.
    //
    udiv    r0, r2, r1

    //
    // Check for overflow.
    // If overflow occurs, return 0x7F... or 0x80.. based on lr (sign flag).
    // Note that this assumes that the magnitude of the number is found on the
    // first shift.  This assumption has been empirically proven for
    // for all 10 bit numbers.
    //
    clz     r3, r0
    cmp     r12, r3
        itt     ge
        rsbge   r0, lr, #0x80000000
        popge   {r4, pc}

    //
    // Find the remainder and put it in r2 for future operations.
    //
    mls     r2, r1, r0, r2

    //
    // Determine how much to shift by.  This is the minimum of
    // the number of leading zeros and the number of shifts left
    // If this is the final divide, jump to the tail.
    //
    clz     r4, r2
    cmp     r4, r12
    bge     divfinished28

    //
    // Middle Divisions
    // This loop holds all the divisions other than the head and tail
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = #shifts this iteration    r12 = remaining shifts needed
    //
    // Prepare for the divide by normalizing remainder.
    //
divmore28
        sub     r12, r12, r4
        lsl     r2, r2, r4
        lsl     r0, r0, r4

        //
        // Perform the divide
        // We already know that an additional step is required, so do the
        // remainder calculation as well.
        //
        udiv    r3, r2, r1
        mls     r2, r1, r3, r2
        add     r0, r3, r0

        //
        // Divide finished, update shift counters for next divide.
        // re-loop if more operations are needed.
        //
        clz     r4, r2
        cmp     r4, r12
    ble   divmore28

    //
    // Final Divide (Tail Divide)
    // Performs the last divide in the sequence, restores scratch registers,
    // adjusts sign bit.
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = dirty                     r12 = remaining shifts needed
    //
divfinished28
    lsl     r2, r2, r12
    lsl     r0, r0, r12
    udiv    r3, r2, r1
    add     r0, r3, r0
    teq     lr, #0
        it      eq
        rsbeq   r0, r0, #0
    pop     {r4, pc}

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ29div
//
//*****************************************************************************
    section CODE__IQ29div:CODE(2)
    thumb
    export  _IQ29div
_IQ29div
    //
    // Test for divide by zero.  Bail with positive overflow if so.
    //
    teq     r1, #0
    itt     eq
        mvneq   r0, #0x80000000
        bxeq    lr

    //
    // Save scratch registers
    //
    push    {r4, lr}

    // Save sign of result to lr
    //
    mov     lr, #1
    teq     r0, r1
        it      mi
        movmi   lr, #0

    //
    // Put operands into unsigned notation
    //
    cmp     r0, #0
        it      mi
        rsbmi   r0, r0, #0
    cmp     r1, #0
        it      mi
        rsbmi   r1, r1, #0
    //
    //
    // First Division
    // The first divide instruction is special, it includes some
    // of the register re-arranging and does overflow checking.
    //
    // Check how many bits can be handled in this first division
    // If all Q bits can be produced, bail early to divfinished
    //
    clz     r4, r0
    cmp     r4, #29
        it      ge
        movge   r4, #29
    lsl     r2, r0, r4
    rsb     r12, r4, #29

    //
    // r0 contains numerator, dirty
    // r1 contains denominator
    // r2 contains normalized numerator
    // r3 is dirty
    // r4 contains shiftable zeros, dirty
    // r12 contains the number of additional shifts required
    // lr contains sign flag.
    //
    // Perform the first division.
    //
    udiv    r0, r2, r1

    //
    // Check for overflow.
    // If overflow occurs, return 0x7F... or 0x80.. based on lr (sign flag).
    // Note that this assumes that the magnitude of the number is found on the
    // first shift.  This assumption has been empirically proven for
    // for all 10 bit numbers.
    //
    clz     r3, r0
    cmp     r12, r3
        itt     ge
        rsbge   r0, lr, #0x80000000
        popge   {r4, pc}

    //
    // Find the remainder and put it in r2 for future operations.
    //
    mls     r2, r1, r0, r2

    //
    // Determine how much to shift by.  This is the minimum of
    // the number of leading zeros and the number of shifts left
    // If this is the final divide, jump to the tail.
    //
    clz     r4, r2
    cmp     r4, r12
    bge     divfinished29

    //
    // Middle Divisions
    // This loop holds all the divisions other than the head and tail
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = #shifts this iteration    r12 = remaining shifts needed
    //
    // Prepare for the divide by normalizing remainder.
    //
divmore29
        sub     r12, r12, r4
        lsl     r2, r2, r4
        lsl     r0, r0, r4

        //
        // Perform the divide
        // We already know that an additional step is required, so do the
        // remainder calculation as well.
        //
        udiv    r3, r2, r1
        mls     r2, r1, r3, r2
        add     r0, r3, r0

        //
        // Divide finished, update shift counters for next divide.
        // re-loop if more operations are needed.
        //
        clz     r4, r2
        cmp     r4, r12
    ble   divmore29

    //
    // Final Divide (Tail Divide)
    // Performs the last divide in the sequence, restores scratch registers,
    // adjusts sign bit.
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = dirty                     r12 = remaining shifts needed
    //
divfinished29
    lsl     r2, r2, r12
    lsl     r0, r0, r12
    udiv    r3, r2, r1
    add     r0, r3, r0
    teq     lr, #0
        it      eq
        rsbeq   r0, r0, #0
    pop     {r4, pc}

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

//*****************************************************************************
//
// _IQ30div
//
//*****************************************************************************
    section CODE__IQ30div:CODE(2)
    thumb
    export  _IQ30div
_IQ30div
    //
    // Test for divide by zero.  Bail with positive overflow if so.
    //
    teq     r1, #0
    itt     eq
        mvneq   r0, #0x80000000
        bxeq    lr

    //
    // Save scratch registers
    //
    push    {r4, lr}

    // Save sign of result to lr
    //
    mov     lr, #1
    teq     r0, r1
        it      mi
        movmi   lr, #0

    //
    // Put operands into unsigned notation
    //
    cmp     r0, #0
        it      mi
        rsbmi   r0, r0, #0
    cmp     r1, #0
        it      mi
        rsbmi   r1, r1, #0
    //
    //
    // First Division
    // The first divide instruction is special, it includes some
    // of the register re-arranging and does overflow checking.
    //
    // Check how many bits can be handled in this first division
    // If all Q bits can be produced, bail early to divfinished
    //
    clz     r4, r0
    cmp     r4, #30
        it      ge
        movge   r4, #30
    lsl     r2, r0, r4
    rsb     r12, r4, #30

    //
    // r0 contains numerator, dirty
    // r1 contains denominator
    // r2 contains normalized numerator
    // r3 is dirty
    // r4 contains shiftable zeros, dirty
    // r12 contains the number of additional shifts required
    // lr contains sign flag.
    //
    // Perform the first division.
    //
    udiv    r0, r2, r1

    //
    // Check for overflow.
    // If overflow occurs, return 0x7F... or 0x80.. based on lr (sign flag).
    // Note that this assumes that the magnitude of the number is found on the
    // first shift.  This assumption has been empirically proven for
    // for all 10 bit numbers.
    //
    clz     r3, r0
    cmp     r12, r3
        itt     ge
        rsbge   r0, lr, #0x80000000
        popge   {r4, pc}

    //
    // Find the remainder and put it in r2 for future operations.
    //
    mls     r2, r1, r0, r2

    //
    // Determine how much to shift by.  This is the minimum of
    // the number of leading zeros and the number of shifts left
    // If this is the final divide, jump to the tail.
    //
    clz     r4, r2
    cmp     r4, r12
    bge     divfinished30

    //
    // Middle Divisions
    // This loop holds all the divisions other than the head and tail
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = #shifts this iteration    r12 = remaining shifts needed
    //
    // Prepare for the divide by normalizing remainder.
    //
divmore30
        sub     r12, r12, r4
        lsl     r2, r2, r4
        lsl     r0, r0, r4

        //
        // Perform the divide
        // We already know that an additional step is required, so do the
        // remainder calculation as well.
        //
        udiv    r3, r2, r1
        mls     r2, r1, r3, r2
        add     r0, r3, r0

        //
        // Divide finished, update shift counters for next divide.
        // re-loop if more operations are needed.
        //
        clz     r4, r2
        cmp     r4, r12
    ble   divmore30

    //
    // Final Divide (Tail Divide)
    // Performs the last divide in the sequence, restores scratch registers,
    // adjusts sign bit.
    //
    // Assumptions:
    // r0 = partial answer            r1 = denominator
    // r2 = remainder, unshifted      r3 = dirty
    // r4 = dirty                     r12 = remaining shifts needed
    //
divfinished30
    lsl     r2, r2, r12
    lsl     r0, r0, r12
    udiv    r3, r2, r1
    add     r0, r3, r0
    teq     lr, #0
        it      eq
        rsbeq   r0, r0, #0
    pop     {r4, pc}

    //
    // Make sure that the end of the section is word aligned.
    //
    alignrom 2

    end
