// Date: 2020.11.26
// User: ID

#include "CDiag.h"
#include "app_lgm.h"

CDiag::CDiag() : IState(DIAG), CONTROLS_QUANT(q9){
	
	
	m_igbtN1_hi.define((uint32_t*)CIgbt::TIMER1_CH1);
	m_igbtN1_hi.position_set(CIgbt::HI);
	m_igbtN1_lo = m_igbtN1_hi;
	m_igbtN1_lo.position_set(CIgbt::LO);
	
	m_igbtN2_hi.define((uint32_t*)CIgbt::TIMER1_CH2);
	m_igbtN2_hi.position_set(CIgbt::HI);
	m_igbtN2_lo = m_igbtN2_hi;
	m_igbtN2_lo.position_set(CIgbt::LO);
	
	m_igbtP1_hi.define((uint32_t*)CIgbt::TIMER2_CH1);
	m_igbtP1_hi.position_set(CIgbt::HI);
	m_igbtP1_lo = m_igbtP1_hi;
	m_igbtP1_lo.position_set(CIgbt::LO);
	
	m_igbtP2_hi.define((uint32_t*)CIgbt::TIMER2_CH2);
	m_igbtP2_hi.position_set(CIgbt::HI);
	m_igbtP2_lo = m_igbtP2_hi;
	m_igbtP2_lo.position_set(CIgbt::LO);
	
	m_km.define((uint32_t*)&app.km_charge);
	
	m_controls[0] = &m_igbtN1_hi;
	m_controls[1] = &m_igbtN1_lo;
	m_controls[2] = &m_igbtN2_hi;
	m_controls[3] = &m_igbtN2_lo;
	m_controls[4] = &m_igbtP1_hi;
	m_controls[5] = &m_igbtP1_lo;
	m_controls[6] = &m_igbtP2_hi;
	m_controls[7] = &m_igbtP2_lo;
	m_controls[8] = &m_km;
	
	m_pwm_duty = _IQ(0.1);
	
	
}

void CDiag::critical_protect(){
}

void CDiag::non_critical_protect(){
}

void CDiag::critical_operate(){
}

void CDiag::operate(){
	static 	_iq m_pwm_duty_old;
	IState::operate();
		
	if (m_pwm_duty != m_pwm_duty_old){
		m_pwm_duty_old = m_pwm_duty;
		uint16_t  _arrDiv2 = app.pwmN.arr_get()>>1;
		uint16_t _ccr1 = _IQmpyI32int(m_pwm_duty, _arrDiv2);
		MDR_TIMER_TypeDef* _mdr_tmr = app.pwmN.address_get();
		
		for (int i = 0; i < 2; i++){
				_mdr_tmr->CCR1 = _mdr_tmr->CCR3 = 0;
				_mdr_tmr->CCR11 = _mdr_tmr->CCR31 = _arrDiv2;
			
				_mdr_tmr->CCR2 = _mdr_tmr->CCR4 = _ccr1;
				_mdr_tmr->CCR21 = _mdr_tmr->CCR41 = _ccr1 + _arrDiv2;
			
				_mdr_tmr = app.pwmP.address_get();
		}
		
	}
	
	for (int i = 0; i < CONTROLS_QUANT; i++){
		app.cmds.pwm[i] ? m_controls[i]->switch_on() : m_controls[i]->switch_off();
	}
	
	if (app.cmds.rst){
//		for (int i = 0; i < CONTROLS_QUANT; i++) m_controls[i]->switch_off();
		app.cmds.diag = 0;
//		app.cmds.rst = 0;
//		
//		m_pwm_duty = _IQ(0.5);
		IState::state_set(IState::INIT);
		reset();
	}
	
	
	task_do_tf(&pt_do_tf);
}

void CDiag::reset(){
	IState::reset();
	PT_INIT(&pt_sw_config);
	PT_INIT(&pt_do_tf);
	
	for (int i = 0; i < CONTROLS_QUANT; i++) m_controls[i]->switch_off();
//	app.cmds.diag = 0;
	
	for (int i = 0; i < 8; i++) app.cmds.pwm[i] = 0;
	
	app.cmds.rst = 0;
	
	m_pwm_duty = _IQ(0.1);
	
	m_do_tf = 0;
	m_tf.reset();
	
}


char CDiag::task_sw_config(PT* pt){
	PT_BEGIN(pt);
	
	PT_YIELD(pt);
	for (int i = 0; i < CONTROLS_QUANT; i++) m_controls[i]->switch_off();
	return PT_EXITED;
	
	PT_END(pt);
}

char CDiag::task_do_tf(PT* pt){
	static TIMER tmr;
	
	if (!m_do_tf) {PT_INIT(pt); return PT_ENDED;};
	
	PT_BEGIN(pt);
	m_tf.Ts_set(1); 
	
	#ifdef TF_IS_FILTER
	m_tf.Tf_set(100.0);
	#endif
	
	#ifdef TF_IS_PIREG
	m_tf.K_set(_IQ(1.0));
	m_tf.Ti_set(1000);
	#endif
	m_tf.sat_set(_IQ(10), -_IQ(10));
	m_tf.config_set();
	
	PT_YIELD_UNTIL(pt, m_do_tf);
	
	timer_set(&tmr, TIME_MSEC(1));
	
	while(1){
		PT_WAIT_UNTIL(pt, timer_expired(&tmr));
		timer_advance(&tmr, tmr.interval);
		
		m_tf.out_est(_IQ(1.0));
		
	}
	
	PT_END(pt);
}

