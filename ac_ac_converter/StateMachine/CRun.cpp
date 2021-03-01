// Date: 2020.11.26
// User: ID

#include "CRun.h"
#include "app_lgm.h"
#include "aux_func.h"
#include "m2m.h"

#define USE_FRST_PWM
#define USE_SEC_PWM


void CRun::critical_protect(){
	IState::critical_protect();	
}

void CRun::non_critical_protect(){
	IState::non_critical_protect();
}

void CRun::critical_operate(){
	
	//                 --------
	//								|				 |
	//	Uref --->o--->|  RegU  |----> Iref
	//					 ^		|				 |
	//           |     --------
	//           |     
	//        	Ufb
	
	
	_iq _Uref = m_Uref.out_get();
	m_errorU_N = _Uref - app.sensUdcBusNeg.m_real; // error
	m_IrefN = app.uReg_N.out_est(m_errorU_N);   	// Iref_1 
//	m_IrefN = _IQ(5.0);   	// Iref_1 
	m_UyN = uint16_t(_IQint(app.iReg_N.out_est(m_IrefN - app.sensIdcN.m_real)));	
	
	m_errorU_P = _Uref - app.sensUdcBusPos.m_real; // error
	m_IrefP = app.uReg_P.out_est(m_errorU_P);	// Iref_2
//	m_IrefP = _IQ(5.0);	// Iref_2
	m_UyP = uint16_t(_IQint(app.iReg_P.out_est(m_IrefP - app.sensIdcP.m_real)));
	
	
	
	const uint16_t _arr = app.pwmN.get_property().arr >> 1;
	
	
	const uint16_t _offset = 0;
	const uint16_t _saturation = _arr - 40;
	
	
#if 1
	app.pwmN.address_get()->CCR1 	= 0;
	app.pwmN.address_get()->CCR11	= _arr;
	
	app.pwmN.address_get()->CCR2 = LIMIT(m_UyN + _offset, _saturation);
	app.pwmN.address_get()->CCR21 = _arr + LIMIT(m_UyN + _offset, _saturation);
	
	app.pwmP.address_get()->CCR1 	= 0;
	app.pwmP.address_get()->CCR11	= _arr;
	
	app.pwmP.address_get()->CCR2 = LIMIT(m_UyP + _offset, _saturation);
	app.pwmP.address_get()->CCR21 = _arr + LIMIT(m_UyP + _offset, _saturation);

#else
	app.pwmN.address_get()->CCR1 	= 0;
	app.pwmN.address_get()->CCR11	= m_UyN;
	
	app.pwmN.address_get()->CCR2 = _arr;
	app.pwmN.address_get()->CCR21 = _arr + m_UyN;
	
	app.pwmP.address_get()->CCR1 	= 0;
	app.pwmP.address_get()->CCR11	= m_UyP;
	
	app.pwmP.address_get()->CCR2 = _arr;
	app.pwmP.address_get()->CCR21 = _arr + m_UyP;
	
#endif
	
	#ifdef USE_FRST_PWM
	app.pwmP.out_enable();
//	app.pwmP.out_disable();
	#endif
	#ifdef USE_SEC_PWM
	app.pwmN.out_enable();
//	app.pwmN.out_disable();
	#endif
}

void CRun::operate(){
	IState::operate();
	task_u_ref_form(&pt_u_ref_formed);
	
//	if (!app.cmds.fManualStart && !app.cmds.start && is_stop_from_vsi()){
//		IState::state_set(IState::READY);
//	}
//	
	if (!app.cmds.start && is_stop_from_vsi()){
		IState::state_set(IState::READY);
	}
}

void CRun::reset(){
	IState::reset();	
	m_IrefN = m_IrefP = 0;
	m_UyN = m_UyP = 0;
	m_errorU_P = m_errorU_N = 0;
	
	PT_INIT(&pt_u_ref_formed);
}


char CRun::task_u_ref_form(PT* pt){
	static TIMER tmr;
	
	PT_BEGIN(pt);
	timer_set(&tmr, TIME_MSEC(10));
	
	while(1){
		PT_YIELD_UNTIL(pt, timer_expired(&tmr));
		timer_advance(&tmr, tmr.interval);
		
		m_Uref.out_est(UBUS_NOM >> 1);
			
	}
	
	PT_END(pt);
}

