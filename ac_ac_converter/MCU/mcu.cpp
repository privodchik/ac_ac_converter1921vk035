// Date: 19.02.2021
// Creator: ID

#include "mcu.h"

#include "K1921VK01T.h"
#include "system_K1921VK01T.h"
#include "aux_utility.h"
#include "atomic.h"


uint32_t CMCU::system_clock = 100e6;

uint32_t CMCU::nowTimeMs = 0;
  
void CMCU::init(){

//#define  __CONFIG_VECTOR_TABLE
    __disable_irq();
//    //SCB->VTOR = 0x20000000;
//    SCB->VTOR = 0x00000000;
//    NT_BOOTFLASH->T_ACC = 6; 
//#define  __CONFIG_CLOCK
//
//    NT_COMMON_REG->SYS_CLK_bit.SEL_SRC = uint32_t(eSCR::PLLDIV);
//    NT_COMMON_REG->PLL_CTRL_bit.REFSEL =  uint32_t(ePLL_REFSRC::XI_OSC);
//    NT_COMMON_REG->PLL_CTRL_bit.PLL_DIV = 0;
//    NT_COMMON_REG->PLL_OD = 1 ; 
//    NT_COMMON_REG->PLL_NR = 2 ; // NR = PLL_NR+2 (PLL_NR: 0..31)
//    NT_COMMON_REG->PLL_NF = 200; // NF = PLL_NF+2 (PLL_NF: 0..255)
//    while (NT_COMMON_REG->SYS_CLK_bit.CURR_SRC != uint32_t(CMCU::eSCR::PLLDIV)) {}
    
    ClkInit();
    SystemCoreClockUpdate();
    systick_config();

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


//#include "CApp.h"
//extern CApp app;
//
//
//void SysTick_Handler(void)
//{
////    app.ledWORK.state_get() ? app.ledWORK.clear() : app.ledWORK.set();
//    
//    USE_ATOMIC_BLOCK;
//    ATOMIC_BLOCK_BEGIN;
//    {
//        if(SysTick->CTRL & SysTick_CTRL_COUNTFLAG_Msk) {
//            
//            
////            CMCU::nowTimeMs++;
//        }
//    }
//    ATOMIC_BLOCK_END;
//}


