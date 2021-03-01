#ifndef CLOCK_HW_H
#define CLOCK_HW_H

#ifdef __cplusplus
extern "C" {
#endif

#include "stdint.h"
#include "iqmath.h"
#include "time_defs.h"

//-------------------------------------------------------------------
// API
void clock_hw_init(void);
void clock_hw_deinit(void);
time_t clock_hw_time(void);
uint32_t clock_hw_time_us(void);

// platform specific
uint32_t clock_hw_time_ms(void);
uint32_t clock_hw_time_ticks(void);

// IRQ handler
void SysTick_Handler(void);
        
#ifdef __cplusplus
} //extern "C"
#endif

#endif /* CLOCK_HW_H */
