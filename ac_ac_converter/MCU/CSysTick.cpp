// Date: 24.02.2021
// Created: ID

#include "CSysTick.h"
#include "K1921VK01T.h"
#include "system_K1921VK01T.h"
#include "atomic.h"

time_t CSysTick::sysTickTime_uSec = 0;





//#include "CApp.h"
//extern CApp app;

void SysTick_Handler(void)
{
//    app.ledWORK.state_get() ? app.ledWORK.clear() : app.ledWORK.set();
    
    USE_ATOMIC_BLOCK;
    ATOMIC_BLOCK_BEGIN;
    {
        if(SysTick->CTRL & SysTick_CTRL_COUNTFLAG_Msk) {
            CSysTick::sysTickTime_uSec += 1000;
        }
    }
    ATOMIC_BLOCK_END;
}


