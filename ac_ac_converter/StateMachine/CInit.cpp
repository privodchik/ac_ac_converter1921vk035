// Date: 2020.11.26
// User: ID

#include "CInit.h"
#include "CApp.h"


void CInit::critical_protect(){
	IState::critical_protect();	
}

void CInit::non_critical_protect(){
	IState::non_critical_protect();
}

void CInit::critical_operate(){
}

void CInit::operate(){
	IState::operate();
	task_wait(&pt_wait);
}

void CInit::reset(){
	IState::reset();
}


char CInit::task_wait(PT* pt){
	static TIMER tmr;
	
	PT_BEGIN(pt);
	timer_set(&tmr, TIME_SEC(5));
	
	PT_YIELD_UNTIL(pt, timer_expired(&tmr));
        IState::state_set(IState::CHARGE);
	
	PT_END(pt);
}

