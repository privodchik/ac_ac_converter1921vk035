#ifndef UART1_GPIO_H
#define UART1_GPIO_H

#ifdef __cplusplus
extern "C" {
#endif

//-------------------------------------------------------------------
// UART1 pins, use one of options
#define UART1_PB12_PB13   1
#define UART1_PB6_PB5   0

//-------------------------------------------------------------------
void uart1_gpio_clk_init(void);
	
#ifdef __cplusplus
}
#endif	//extern "C" {

#endif //UART1_GPIO_H
