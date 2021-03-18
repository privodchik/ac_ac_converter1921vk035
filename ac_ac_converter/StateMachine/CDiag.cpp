// Date: 2020.11.26
// User: ID

#include "CDiag.h"

#include "CApp.h"
extern CApp app;

CDiag::CDiag() : IState(DIAG),
    m_pwm0_ChA(CIgbt(&app.pwm_A, CIgbt::eChannel::A)),
    m_pwm0_ChB(CIgbt(&app.pwm_A, CIgbt::eChannel::B)),
    m_pwm1_ChA(CIgbt(&app.pwm_B, CIgbt::eChannel::A)),
    m_pwm1_ChB(CIgbt(&app.pwm_B, CIgbt::eChannel::B)) 
{

    m_controls[0] = &m_pwm0_ChA;
    m_controls[1] = &m_pwm0_ChB;
    m_controls[2] = &m_pwm1_ChA;
    m_controls[3] = &m_pwm1_ChB;
    m_controls[4] = &m_km;

    m_pwm_duty = IQ(0.1);
	
}

void CDiag::critical_protect(){
}

void CDiag::non_critical_protect(){
}

void CDiag::critical_operate(){
}

void CDiag::operate(){
	static 	iq_t m_pwm_duty_old;
	IState::operate();
		
	if (m_pwm_duty != m_pwm_duty_old){
          m_pwm_duty_old = m_pwm_duty;
          m_pwm0_ChA.duty_set(m_pwm_duty);
          m_pwm1_ChA.duty_set(m_pwm_duty);
	}
	
	for (int i = 0; i < CONTROLS_QUANT; i++){
          app.cmds.pwm[i] ? m_controls[i]->switch_on() : m_controls[i]->switch_off();
	}
	
	if (app.cmds.rst){
          for (int i = 0; i < CONTROLS_QUANT; i++) m_controls[i]->switch_off();
          app.cmds.diag = 0;
          app.cmds.rst = 0;
          app.sm.state_set(&app.stInit);
	}
	
}

void CDiag::reset(){
	IState::reset();
	for (int i = 0; i < CONTROLS_QUANT; i++) m_controls[i]->switch_off();
	for (int i = 0; i < 8; i++) app.cmds.pwm[i] = 0;
	app.cmds.rst = 0;
//	m_pwm_duty = IQ(0.1);
        __NVIC_DisableIRQ(PWM0_TZ_IRQn);
        __NVIC_DisableIRQ(PWM1_TZ_IRQn);
}


char CDiag::task_sw_config(PT* pt){
	PT_BEGIN(pt);
	
	PT_YIELD(pt);
	for (int i = 0; i < CONTROLS_QUANT; i++) m_controls[i]->switch_off();
	return PT_EXITED;
	
	PT_END(pt);
}

