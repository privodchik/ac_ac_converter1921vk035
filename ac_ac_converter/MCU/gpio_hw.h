#ifndef GPIO_HW_H
#define GPIO_HW_H

#ifdef __cplusplus
extern "C" {
#endif

// gpio for dsp platform 

#include "config.h"
#include "niietcm4_gpio.h"

//-------------------------------------------------------------------
void gpio_hw_init(void);
void gpio_hw_deinit(void);

//-------------------------------------------------------------------
// use SPL API
//#define GPIO_HIGH(port, bit)  PORT_SetBits(port, bit)
//#define GPIO_LOW(port, bit)   PORT_ResetBits(port, bit)

// use registers directly
#define GPIO_HIGH(port, bit)    port->DATAOUT |= bit
#define GPIO_LOW(port, bit)     port->DATAOUT &= ~bit

// Leds and GPIO mapping to functionality
//-------------------------------------------------------------------


    #define RS485_1_TX_ON   GPIO_HIGH(NT_GPIOF, GPIO_Pin_9)
    #define RS485_1_TX_OFF  GPIO_LOW(NT_GPIOF, GPIO_Pin_9)

    #define RS485_2_TX_ON   GPIO_HIGH(NT_GPIOF, GPIO_Pin_8)
    #define RS485_2_TX_OFF  GPIO_LOW(NT_GPIOF, GPIO_Pin_8)


#ifdef __cplusplus
}
#endif

#endif //GPIO_HW_H

