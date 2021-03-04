// Date: 24.02.2021
// Created: ID


#ifndef _CAPP_H
#define _CAPP_H

#include "system_K1921VK01T.h"
#include "CPin.h"
#include "CLed.h"
#include "CADC.h"
#include "CUART.h"
#include "CPWM.h"


#include "CInit.h"
#include "CReady.h"

#include "state_machine.h"



extern const uint32_t SYSTEM_CLOCK;

class CApp{
    
  private:
    uint32_t counting = 0;
    CLed ledWORK;
    CADC adc{adc_modules, array_size(adc_modules)};
    CUart mbUart;
    CPWM pwm_A{CPWM::ePWM::PWM_0};
    CPWM pwm_B{CPWM::ePWM::PWM_1};
    
    CInit       stInit;
    CReady      stReady;
    
    static const int numStates = 7;
    IState* states[numStates];
    
    CStateMachine sm{&stInit};
    
    
  public:
    CApp();
    
    void init();
    void run();
    void isr(time_t _period);
    
  private:
    void leds_init();
    void pwm_init();
    void adc_init();
    void uart_init();
    void state_machine_init();
    
    
    friend void SysTick_Handler(void);
    friend void PWM0_IRQHandler(void);
    friend void ADC_SEQ0_IRQHandler(void);
    
};


#endif //_CAPP_H
