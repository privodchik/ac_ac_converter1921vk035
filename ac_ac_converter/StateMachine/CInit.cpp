// Date: 2020.11.26
// User: ID

#include "CInit.h"
#include "CApp.h"


#include "CApp.h"
extern CApp app;

void CInit::critical_protect(){
	IState::critical_protect();	
}

void CInit::non_critical_protect(){
	IState::non_critical_protect();
}

void CInit::critical_operate(){
    IState::critical_operate();
}

void CInit::operate(){
	IState::operate();
        if (m_stateTime > TIME_SEC(1.0)) app.sm.state_set(&app.stCharge);
}

void CInit::reset(){
	IState::reset();
        app.errors.clr();
        app.pwm_A.TZ_IT_reset();
        app.pwm_B.TZ_IT_reset();
        
        __NVIC_ClearPendingIRQ(PWM0_TZ_IRQn);
        __NVIC_ClearPendingIRQ(PWM1_TZ_IRQn);
        
        __NVIC_EnableIRQ(PWM0_TZ_IRQn);
        __NVIC_EnableIRQ(PWM1_TZ_IRQn);
}

