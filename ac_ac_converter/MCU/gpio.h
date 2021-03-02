#ifndef GPIO_H
#define GPIO_H

// gpio public API (same for PC and dsp)

#ifdef __cplusplus
extern "C" {
#endif

//#include "mcu.h"
#include "iqmath.h"
//#include "pu.h"
#include "config.h"
#include "gpio_hw.h" // platform specific

//-------------------------------------------------------------------
#define GPIO_ON         1
#define GPIO_OFF        0

#define ACTIVE     1
#define INACTIVE   0

//-------------------------------------------------------------------
// servicing task
void gpio_init(void);
void gpio_task(void);
//void gpio_fast_task(time_t period);

//-------------------------------------------------------------------
// API
void gpio_rs485_tx(int uart_number, int16_t onoff);
void gpio_rs485_1_tx(int16_t onoff);
void gpio_rs485_2_tx(int16_t onoff);

//-------------------------------------------------------------------
// software status

extern int16_t rs485_1_tx_status;
extern int16_t rs485_2_tx_status;

#ifdef __cplusplus
} // extern "C"
#endif

#endif //GPIO_H
