// Date: 24.02.2021
// Created: ID


#ifndef _CAPP_H
#define _CAPP_H

#include "system_K1921VK01T.h"
#include "CPin.h"
#include "CLed.h"
#include "CADC.h"
#include "CUART.h"


extern const uint32_t SYSTEM_CLOCK;

class CApp{
    
  private:
    uint32_t counting = 0;
    CLed ledWORK;
    CADC adc{adc_modules, array_size(adc_modules)};
    CUart mbUart;
    
  public:
    CApp();
    
    void init();
    void run();
    
  private:
    void leds_init();
    void pwm_init();
    void adc_init();
    void uart_init();
    
    
    friend void SysTick_Handler(void);
    friend void PWM0_IRQHandler(void);
    friend void ADC_SEQ0_IRQHandler(void);
};


#endif //_CAPP_H
