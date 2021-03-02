#include "gpio.h"
#include "gpio_hw.h"
#include "pt.h"
#include "timer.h"
#include "config.h"

//------------------------------------------------------------------- 

int16_t rs485_1_tx_status = 0;
int16_t rs485_2_tx_status = 0;

//------------------------------------------------------------------- 
static PT pt_gpio;

static void gpio_update(void);

//------------------------------------------------------------------- 
void gpio_init(void)
{
    PT_INIT(&pt_gpio);

    // note: on dsp after reset all pins are input with pullup enabled

    // before output pins are configured as output 
    // we put them into predefined state

    RS485_1_TX_OFF;
    RS485_2_TX_OFF;
    
    gpio_hw_init();
    gpio_update();
}

//------------------------------------------------------------------- 
static void gpio_update(void)
{    
    
    if(rs485_1_tx_status != GPIO_OFF) RS485_1_TX_ON; else RS485_1_TX_OFF;
    if(rs485_2_tx_status != GPIO_OFF) RS485_2_TX_ON; else RS485_2_TX_OFF;
}

//-------------------------------------------------------------------
static PT_THREAD(task_gpio(PT *pt))
{
    static TIMER tim1;
    
    PT_BEGIN(pt);

    timer_set(&tim1, TIME_MSEC(10));
    
    while(1)
    {
        PT_YIELD_UNTIL(pt, timer_expired(&tim1));
        timer_advance(&tim1, tim1.interval);
        
        gpio_update();
    }

    PT_END(pt);
}

//-------------------------------------------------------------------
void gpio_task(void)
{
    task_gpio(&pt_gpio);
}

/*
//-------------------------------------------------------------------
void gpio_fast_task(time_t period)
{
}
*/

//-------------------------------------------------------------------
void gpio_rs485_tx(int uart_number, int16_t onoff)
{
    if(1 == uart_number) gpio_rs485_1_tx(onoff);
    else if(2 == uart_number) gpio_rs485_2_tx(onoff);
}

//-------------------------------------------------------------------
void gpio_rs485_1_tx(int16_t onoff)
{
    rs485_1_tx_status = onoff;
    if(rs485_1_tx_status != GPIO_OFF) RS485_1_TX_ON; else RS485_1_TX_OFF;
}

//-------------------------------------------------------------------
void gpio_rs485_2_tx(int16_t onoff)
{
    rs485_2_tx_status = onoff;
    if(rs485_2_tx_status != GPIO_OFF) RS485_2_TX_ON; else RS485_2_TX_OFF;
}

