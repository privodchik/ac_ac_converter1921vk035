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
#include "CSensI.h"
#include "CSensU.h"

#include "CInit.h"
#include "CReady.h"

#include "state_machine.h"



extern const uint32_t SYSTEM_CLOCK;

class CApp{
    
  public:
    uint32_t counting = 0;
    CLed ledWORK;
    CADC adc{adc_modules, array_size(adc_modules)};
    CUart mbUart;
    
    //----------- PWM-----------------------------------------------------------
    CPWM pwm_A{CPWM::ePWM::PWM_0};
    CPWM pwm_B{CPWM::ePWM::PWM_1};
    
    //------------Sensors-------------------------------------------------------
    CSensI sens_iFull{0.017, 59.0, 20.0, 10.0, 2.0, IQ(0.0)};
    //CSensI sens_iFull{0.017, 59.0, 20.0, 10.0, 2.0, IQ(0.0), true}; // inversion result
    CSensI sens_iLoad{0.017, 59.0, 20.0, 10.0, 2.0, IQ(0.0)};
    
    CSensU sens_uBUSP_N{0.017, 59.0, 20.0, 10.0, 150.0, 2.5, IQ(0.0)};
    CSensU sens_uBUSN_N{0.017, 59.0, 20.0, 10.0, 150.0, 2.5, IQ(0.0)};
    CSensU sens_uOut{0.017, 59.0, 20.0, 10.0, 150.0, 2.0, IQ(0.0)};
    
    static const int NUM_SENSORS = 5;
    ISens* sensors[NUM_SENSORS];
    
    //------------State Machine-------------------------------------------------
    CInit       stInit;
    CReady      stReady;
    
    static const int numStates = 7;
    IState* states[numStates];
    
    CStateMachine sm{&stInit};
    
    //--------------------------------------------------------------------------    
    
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
