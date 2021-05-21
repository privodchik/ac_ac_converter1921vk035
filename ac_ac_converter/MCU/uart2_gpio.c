#include "uart2_gpio.h"
#include "plib035_gpio.h"
#include "plib035_rcu.h"
#include "plib035_uart.h"

//-------------------------------------------------------------------
void uart2_gpio_clk_init()
{
    GPIO_Init_TypeDef GPIO_InitStruct;
    GPIO_StructInit(&GPIO_InitStruct);

    GPIO_InitStruct.Digital = ENABLE;
    GPIO_InitStruct.Out = ENABLE;
    GPIO_InitStruct.AltFunc = ENABLE;
    
    // Configure PORTB pins 8 (UART1_TX)
    GPIO_InitStruct.Pin = GPIO_Pin_8;
    GPIO_Init(GPIOB, &GPIO_InitStruct);
    
    // Configure PORTB pins 9 (UART1_RX)
    GPIO_InitStruct.Pin = GPIO_Pin_9;
    GPIO_Init(GPIOB, &GPIO_InitStruct);

    // UART clock
//    RCC_UARTClkSel(UART1, RCC_UARTClk_SYSCLK);
////    RCC_UARTClkDivConfig(UART2, 0, ENABLE); // Do not use if SysClk
    RCU_UARTClkConfig(UART1_Num, RCU_PeriphClk_OSEClk, 0, ENABLE);
    RCU_UARTClkCmd(UART1_Num, ENABLE);
    RCU_UARTRstCmd(UART1_Num, ENABLE);
    
    
}
