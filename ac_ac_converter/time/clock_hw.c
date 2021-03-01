#include "mcu.h"
#include "clock_hw.h"
#include "atomic.h"
#include "iqmath.h"

// HW clock is based on CPU SysTick timer
uint32_t clock_hw_tick_ms = 0;

static uint32_t ms2ticks = 0;
static iq30_t ticks2us = 0;

//-------------------------------------------------------------------
void clock_hw_init()
{
    uint32_t saved_pri;
    
    ms2ticks = SystemCoreClock / 1000;
    ticks2us = IQ30div(1000000, SystemCoreClock);
    
    saved_pri = NVIC_GetPriority(SysTick_IRQn);
    SysTick_Config(ms2ticks); // modifies SysTick_IRQn priority
    NVIC_SetPriority(SysTick_IRQn, saved_pri);
}

//-------------------------------------------------------------------
void clock_hw_deinit()
{
}

//-------------------------------------------------------------------
time_t clock_hw_time()
{
    return TIME_USEC(clock_hw_time_us());
}

//-------------------------------------------------------------------
uint32_t clock_hw_time_us()
{
    uint32_t hw_counter;
    uint32_t delta_ticks;
    uint32_t usec;
    uint32_t ticks_ms;
    USE_ATOMIC_BLOCK;
    
    usec = 0;

    // note: don't return from atomic block
    ATOMIC_BLOCK_BEGIN; // isrs disabled
    {
        ticks_ms = clock_hw_tick_ms;
        hw_counter = SysTick->VAL;
        // check timer roll over
        if(SysTick->CTRL & SysTick_CTRL_COUNTFLAG_Msk) {
            hw_counter = SysTick->VAL;
            usec = 1000;
            clock_hw_tick_ms++;
        }
    }
    ATOMIC_BLOCK_END;
    
    delta_ticks = ms2ticks - hw_counter;
    usec += IQ30mpy(delta_ticks, ticks2us);
    usec += ticks_ms*1000;
    
    return usec;
}

// platform specific
//-------------------------------------------------------------------
uint32_t clock_hw_time_ticks()
{
    USE_ATOMIC_BLOCK;

    uint32_t hw_counter;
    uint32_t delta_ticks;
    uint32_t ticks;
    uint32_t ticks_ms;
    
    ticks = 0;

    // note: don't return from atomic block
    ATOMIC_BLOCK_BEGIN; // isrs disabled
    {
        ticks_ms = clock_hw_tick_ms;
        hw_counter = SysTick->VAL;
        // check timer roll over
        if(SysTick->CTRL & SysTick_CTRL_COUNTFLAG_Msk) {
            hw_counter = SysTick->VAL;
            ticks = ms2ticks;
            clock_hw_tick_ms++;
        }
    }
    ATOMIC_BLOCK_END;
    
    delta_ticks = ms2ticks - hw_counter;
    ticks += delta_ticks;
    ticks += ticks_ms * ms2ticks;

    return ticks;
}

// platform specific
//-------------------------------------------------------------------
uint32_t clock_hw_time_ms()
{
    return clock_hw_tick_ms;
}

// IRQ handler
//-------------------------------------------------------------------
void SysTick_Handler(void)
{
    USE_ATOMIC_BLOCK;
    ATOMIC_BLOCK_BEGIN;
    {
        if(SysTick->CTRL & SysTick_CTRL_COUNTFLAG_Msk) {
            clock_hw_tick_ms++;
        }
    }
    ATOMIC_BLOCK_END;
}

