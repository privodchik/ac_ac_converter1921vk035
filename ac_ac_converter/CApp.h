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

#include "user_constants.h"

#include "CSensI.h"
#include "CSensU.h"

#include "CInit.h"
#include "CReady.h"
#include "CRun.h"
#include "CCharge.h"
#include "CDiag.h"
#include "CFault.h"
#include "state_machine.h"

#include "CErrors.h"

#include "piregulator.h"

#include "CCmds.h"



extern uint16_t iCCRA;
extern uint16_t iCCRB;



extern const uint32_t SYSTEM_CLOCK;

extern const int ERRORS_BUFFER_SIZE;
extern CErrors::eError_t errorBuffer[5]; 

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
    CSensI sens_iFull{0.047, 59.0, 20.0, 10.0, 1.0, IQ(-29.5)};
    //CSensI sens_iFull{0.047, 59.0, 20.0, 10.0, 1.0, IQ(0.0), true}; // inversion result
    CSensI sens_iLoad{0.047, 59.0, 20.0, 10.0, 1.0, IQ(-30.0)};
    
//    CSensU sens_uBUSP_N{0.360, 20.0, 20.0, 10.0, 150.0, 2.5, IQ(-18.0)};
//    CSensU sens_uBUSN_N{0.360, 20.0, 20.0, 10.0, 150.0, 2.5, IQ(0.0)};
    
    CSensU sens_uBUS{0.470, 59.0, 20.0, 10.0, 75.0, 2.5, IQ(0)};
    CSensU sens_uOut{0.360, 59.0, 20.0, 10.0, 75.0/2.0, 2.5, IQ(0)};
    
    static const int NUM_SENSORS = 4;
    ISens* sensors[NUM_SENSORS];
    
    //------------State Machine-------------------------------------------------
    CInit       stInit;
    CRun        stRun;
    CReady      stReady;
    CCharge     stCharge;
    CDiag       stDiag;
    CFault      stFault;
    CStateMachine sm{&stInit};
    
    //--------------------------------------------------------------------------
    
    //------------Errors -------------------------------------------------------
    CErrors errors{errorBuffer, array_size(errorBuffer)};
    
    //--------------------------------------------------------------------------
    
    //------------Regulators ---------------------------------------------------
    
    CPIReg regUd{IQ(0.000025), IQ(10.0), IQ(0.01), IQ(200), -IQ(200)};
    CPIReg regUq{IQ(0.000025), IQ(10.0), IQ(0.01), IQ(200), -IQ(200)};
    
    CPIReg regId{IQ(0.000025), IQ(10.0), IQ(0.002), IQ(1.0), -IQ(1.0)};
    //--------------------------------------------------------------------------
    //------------Commands -----------------------------------------------------
    CCmds cmds;
    
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
    void sens_init();
    
    friend void SysTick_Handler(void);
    friend void PWM0_IRQHandler(void);
    friend void ADC_SEQ0_IRQHandler(void);
    friend void PWM0_TZ_IRQHandler(void);    
    friend void PWM1_TZ_IRQHandler(void);    
};


#endif //_CAPP_H
