#include "uart2_gpio.h"
#include "niietcm4_gpio.h"
#include "niietcm4_rcc.h"
#include "niietcm4_uart.h"

//-------------------------------------------------------------------
void uart2_gpio_clk_init()
{
    GPIO_Init_TypeDef GPIO_InitStruct;
    GPIO_StructInit(&GPIO_InitStruct);

#if UART2_PF10_PF11
    GPIO_InitStruct.GPIO_Mode = GPIO_Mode_AltFunc;
    GPIO_InitStruct.GPIO_AltFunc = GPIO_AltFunc_1;
    GPIO_InitStruct.GPIO_OutMode = GPIO_OutMode_PP;
    GPIO_InitStruct.GPIO_Out = GPIO_Out_En;
    
    // Configure PORTF pins 10 (UART1_TX)
    GPIO_InitStruct.GPIO_Pin = GPIO_Pin_10;
    GPIO_Init(NT_GPIOF, &GPIO_InitStruct);
    
    // Configure PORTF pins 11 (UART1_RX)
    GPIO_InitStruct.GPIO_Pin = GPIO_Pin_11;
    GPIO_Init(NT_GPIOF, &GPIO_InitStruct);
#endif // UART2_PD0_PD1
    
#if UART2_PF0_PF1
//    RST_CLK_PCLKcmd(RST_CLK_PCLK_PORTF, ENABLE); // PF0/rx PF1/tx
//
//    // uart GPIO
//    PortInit.PORT_PULL_UP = PORT_PULL_UP_OFF;
//    PortInit.PORT_PULL_DOWN = PORT_PULL_DOWN_OFF;
//    PortInit.PORT_PD_SHM = PORT_PD_SHM_OFF;
//    PortInit.PORT_PD = PORT_PD_DRIVER;
//    PortInit.PORT_GFEN = PORT_GFEN_OFF;
//    PortInit.PORT_SPEED = PORT_SPEED_MAXFAST;
//    PortInit.PORT_MODE = PORT_MODE_DIGITAL;
//    PortInit.PORT_FUNC = PORT_FUNC_OVERRID;
//
//    // Configure PORTF pins 1 (UART2_TX) as output
//    PortInit.PORT_OE = PORT_OE_OUT;
//    PortInit.PORT_Pin = PORT_Pin_1;
//    PORT_Init(MDR_PORTF, &PortInit);
//    // Configure PORTF pins 0 (UART2_RX) as input
//    PortInit.PORT_OE = PORT_OE_IN;
//    PortInit.PORT_Pin = PORT_Pin_0;
//    PORT_Init(MDR_PORTF, &PortInit);
#endif // UART2_PF0_PF1

    // UART clock
    RCC_UARTClkSel(NT_UART2, RCC_UARTClk_SYSCLK);
//    RCC_UARTClkDivConfig(NT_UART2, 0, ENABLE); // Do not use if SysClk
    RCC_UARTClkCmd(NT_UART2, ENABLE);
    RCC_PeriphRstCmd(RCC_PeriphRst_UART2, ENABLE);
}
