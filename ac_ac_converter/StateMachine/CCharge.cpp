// Date: 2020.11.26
// User: ID

#include "CCharge.h"

#include "CApp.h"
extern CApp app;

#define USE_DIAGNOSTIC

void CCharge::critical_protect(){
	IState::critical_protect();	
}

void CCharge::non_critical_protect(){
	IState::non_critical_protect();
}

void CCharge::critical_operate(){
    IState::critical_operate();
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

	PT_YIELD(pt);

#ifndef USE_DIAGNOSTIC	
	if (!timer_expired(&tmr)){
		
		if (    (app.sens_uBUSP_N.read() >= UBUSPN_MIN)
                    &&  (app.sens_uBUSN_N.read() >= UBUSNN_MIN)
                    )
                {
                    IState::state_set(IState::eState::READY);
			return PT_ENDED;
		}
		return PT_EXITED;
	}
        
	app.errors.set(CErrors::ERROR_BUS_MIN);
	IState::state_set(IState::eState::FAULT);
#else
	timer_set(&tmr, TIME_SEC(5));
	PT_WAIT_UNTIL(pt, timer_expired(&tmr));
	IState::state_set(IState::READY);
#endif
	
	PT_END(pt);
}

