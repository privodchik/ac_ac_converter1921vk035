// Date: 2020.11.26
// User: ID

#include "CCharge.h"
#include "app_lgm.h"

//#define USE_DIAGNOSTIC

void CCharge::critical_protect(){
	app.pwmN.out_disable();
	app.pwmP.out_disable();
	
	IState::critical_protect();	
}

void CCharge::non_critical_protect(){
	IState::non_critical_protect();
}

void CCharge::critical_operate(){
}

void CCharge::operate(){
	IState::operate();
	task_charge(&pt_charge);
}

void CCharge::reset(){
	IState::reset();
	PT_INIT(&pt_charge);
}


char CCharge::task_charge(PT* pt){
	static TIMER tmr;
	
	PT_BEGIN(pt);
	timer_set(&tmr, TIME_SEC(30));
	app.km_charge.set(CPin::OFF);
	
	PT_YIELD(pt);

#ifndef USE_DIAGNOSTIC	
	if (!timer_expired(&tmr)){
		
		if (app.sensUdcNet.m_real >= UNET_MIN){
			app.km_charge.set(CPin::ON);
			IState::state_set(IState::READY);
			return PT_ENDED;
		}
		return PT_EXITED;
	}
	
	app.errors.set(CErrors::CHARGE_PRECHARGE);
	IState::state_set(IState::FAULT);
#else
	timer_set(&tmr, TIME_SEC(5));
	PT_WAIT_UNTIL(pt, timer_expired(&tmr));
	IState::state_set(IState::READY);
#endif
	
	PT_END(pt);
}

