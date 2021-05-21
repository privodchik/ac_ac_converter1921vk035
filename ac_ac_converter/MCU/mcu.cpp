// Date: 19.02.2021
// Creator: ID

#include "mcu.h"

#include "K1921VK035.h"
#include "system_K1921VK035.h"
#include "aux_utility.h"
#include "atomic.h"


uint32_t CMCU::system_clock = 100e6;

uint32_t CMCU::nowTimeMs = 0;
  
void CMCU::init(){
    __disable_irq();
    ClkInit();
    SystemCoreClockUpdate();
    systick_config();

    FPUInit();
    
    __enable_irq();
    
}


void CMCU::systick_config(){
    uint32_t saved_pri;
    
    uint32_t ms2ticks = system_clock / 1000U;

    saved_pri = NVIC_GetPriority(SysTick_IRQn);
    SysTick_Config(ms2ticks); // modifies SysTick_IRQn priority
    NVIC_SetPriority(SysTick_IRQn, saved_pri);
    __NVIC_EnableIRQ(SysTick_IRQn);
}

