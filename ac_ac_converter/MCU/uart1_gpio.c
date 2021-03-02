#include "uart1_gpio.h"
#include "niietcm4_gpio.h"
#include "niietcm4_rcc.h"
#include "niietcm4_uart.h"

//-------------------------------------------------------------------
void uart1_gpio_clk_init()
{
    GPIO_Init_TypeDef GPIO_InitStruct;
    GPIO_StructInit(&GPIO_InitStruct);

#if UART1_PF10_PF11
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
    
#endif //UART1_PF10_PF11

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
    RCC_UARTClkSel(NT_UART3, RCC_UARTClk_SYSCLK);
    RCC_UARTClkDivConfig(NT_UART3, 0, ENABLE);
    RCC_UARTClkCmd(NT_UART3, ENABLE);
    RCC_PeriphRstCmd(RCC_PeriphRst_UART3, ENABLE);
    
    
    // UART Configuration
//    UART_Init_TypeDef UART_InitStruct;
//    UART_StructInit(&UART_InitStruct);
//    UART_InitStruct.UART_BaudRate = 115200;
//    UART_InitStruct.UART_ClkFreq = SystemCoreClock;
//    UART_InitStruct.UART_DataWidth = UART_DataWidth_8;
//    UART_InitStruct.UART_FIFOEn = ENABLE;
//    UART_InitStruct.UART_ParityBit = UART_ParityBit_Disable;
//    UART_InitStruct.UART_StopBit = UART_StopBit_1;
//
//    UART_Init(NT_UART2, &UART_InitStruct);
//    UART_Cmd(NT_UART2, ENABLE);
    
}
