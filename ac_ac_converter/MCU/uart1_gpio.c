#include "uart1_gpio.h"
#include "plib035_gpio.h"
#include "plib035_rcu.h"
#include "plib035_uart.h"

//-------------------------------------------------------------------
void uart1_gpio_clk_init()
{
    GPIO_Init_TypeDef GPIO_InitStruct;
    GPIO_StructInit(&GPIO_InitStruct);

#if UART1_PB10_PB11
    GPIO_Init_TypeDef GPIO_InitStruct;
    GPIO_StructInit(&GPIO_InitStruct);

    GPIO_InitStruct.Digital = ENABLE;
    GPIO_InitStruct.Out = ENABLE;
    GPIO_InitStruct.AltFunc = ENABLE;
    
    // Configure PORTB pins 10 (UART0_TX)
    GPIO_InitStruct.Pin = GPIO_Pin_10;
    GPIO_Init(GPIOB, &GPIO_InitStruct);
    
    // Configure PORTB pins 11 (UART0_RX)
    GPIO_InitStruct.Pin = GPIO_Pin_11;
    GPIO_Init(GPIOB, &GPIO_InitStruct);

    // UART clock
    RCU_UARTClkConfig(UART0_Num, RCU_PeriphClk_OSEClk, 0, ENABLE);
    RCU_UARTClkCmd(UART0_Num, ENABLE);
    RCU_UARTRstCmd(UART0_Num, ENABLE);
    
#endif //UART1_PB10_PB11

#if UART1_PB6_PB5
    RST_CLK_PCLKcmd(RST_CLK_PCLK_PORTB, ENABLE); // PB6/rx PB5/tx

    // uart GPIO
    PortInit.PORT_PULL_UP = PORT_PULL_UP_OFF;
    PortInit.PORT_PULL_DOWN = PORT_PULL_DOWN_OFF;
    PortInit.PORT_PD_SHM = PORT_PD_SHM_OFF;
    PortInit.PORT_PD = PORT_PD_DRIVER;
    PortInit.PORT_GFEN = PORT_GFEN_OFF;
    PortInit.PORT_SPEED = PORT_SPEED_MAXFAST;
    PortInit.PORT_MODE = PORT_MODE_DIGITAL;
    PortInit.PORT_FUNC = PORT_FUNC_ALTER;

    // Configure PORTB pins 5 (UART1_TX) as output
    PortInit.PORT_OE = PORT_OE_OUT;
    PortInit.PORT_Pin = PORT_Pin_5;
    PORT_Init(MDR_PORTB, &PortInit);
    // Configure PORTB pins 6 (UART1_RX) as input
    PortInit.PORT_OE = PORT_OE_IN;
    PortInit.PORT_Pin = PORT_Pin_6;
    PORT_Init(MDR_PORTB, &PortInit);
#endif // UART1_PB6_PB5
    
    // UART clock
//    RCC_UARTClkSel(NT_UART3, RCC_UARTClk_SYSCLK);
//    RCC_UARTClkDivConfig(NT_UART3, 0, ENABLE);
//    RCC_UARTClkCmd(NT_UART3, ENABLE);
//    RCC_PeriphRstCmd(RCC_PeriphRst_UART3, ENABLE);
}
