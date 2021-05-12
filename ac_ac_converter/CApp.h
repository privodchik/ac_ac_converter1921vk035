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
#include "filter.h"

#include "CCmds.h"

#include "CRMS.h"


extern uint16_t FR;
extern uint16_t AMP;

extern uint16_t iCCRA;
extern uint16_t iCCRB;



//extern iq_t test_var;

extern iq_t uRef_d_;
extern iq_t uRef_q_;

extern iq_t uOut_d_;
extern iq_t uOut_q_;
extern iq_t uOut_;

extern uint16_t simple_sin;


extern const uint32_t SYSTEM_CLOCK;

extern const int ERRORS_BUFFER_SIZE;
extern CErrors::eError_t errorBuffer[5]; 

class CApp{
    
  public:
    uint32_t counting = 0;
    CLed ledWORK;
    CLed ledADC;
    
    CPin fun{CPin::ePort::PORT_F, CPin::ePin::Pin_7};
    bool autoStartFun = true;
    
    CADC adc{adc_modules, array_size(adc_modules)};
    CUart mbUart;
    
    //----------- PWM-----------------------------------------------------------
    CPWM pwm_A{CPWM::ePWM::PWM_0};
    CPWM pwm_B{CPWM::ePWM::PWM_1};
    
    //------------Sensors-------------------------------------------------------
    CSensI sens_iFull{0.047, 59.0, 20.0, 10.0, 1.0, IQ(0)};
    //CSensI sens_iFull{0.047, 59.0, 20.0, 10.0, 1.0, IQ(0.0), true}; // inversion result
    CSensI sens_iLoad{0.047, 59.0, 20.0, 10.0, 1.0, IQ(0)};
    
//    CSensU sens_uBUSP_N{0.360, 20.0, 20.0, 10.0, 150.0, 2.5, IQ(-18.0)};
//    CSensU sens_uBUSN_N{0.360, 20.0, 20.0, 10.0, 150.0, 2.5, IQ(0.0)};
    
    CSensU sens_uBUS{0.470, 59.0, 20.0, 10.0, 75.0, 2.5, IQ(0)};
    CSensU sens_uOut{0.470, 59.0, 20.0, 10.0, 75.0/2.0, 2.5, IQ(0)};
    
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
    
    CPIReg regUd{IQ(1.0/(FREQ_KHZ*1000)), IQ(2.0*0.1), IQ(0.01*10), IQ(200), -IQ(200)};
    CPIReg regUq{IQ(1.0/(FREQ_KHZ*1000)), IQ(1.0*0.1), IQ(0.01*10), IQ(200), -IQ(200)};
    
    CPIReg regId{IQ(1.0/(FREQ_KHZ*1000)), IQ(4.5/350.0), IQ(0.0005*350), IQ(1.0), -IQ(1.0)};
    
    CFilter lpf{IQ(1.0/(FREQ_KHZ*1000)), IQ(0.1), IQ(1000.0), -IQ(1000.0)};
    //--------------------------------------------------------------------------
    //------------Commands -----------------------------------------------------
    CCmds cmds;
    
    //--------------------------------------------------------------------------

    //------------RMS ----------------------------------------------------------
    CRMS iInvRms{IQ(1.0/(FREQ_KHZ*1000)), IQ(400.0)};
    CFilter iInvRmsLpf{IQ(1.0/(FREQ_KHZ*1000)), IQ(0.1), IQ(1000.0), -IQ(1000.0)};
    //--------------------------------------------------------------------------
    
    
    
    
    
  public:
    CApp();
    
    void init();
    void run();
    void isr(time_t _period);
    
  private:
    void leds_init();
    void fun_init();
    void pwm_init();
    void adc_init();
    void uart_init();
    void state_machine_init();
    void sens_init();
    
    void rms_est(time_t _periodUSEC);
  private:
    PT_THREAD(task_rms(time_t _periodUSEC, PT* pt));
    
  public:  
    
    friend void SysTick_Handler(void);
    friend void PWM0_IRQHandler(void);
    friend void ADC_SEQ0_IRQHandler(void);
    friend void PWM0_TZ_IRQHandler(void);    
    friend void PWM1_TZ_IRQHandler(void);    
};


#endif //_CAPP_H
