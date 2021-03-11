// Date: 2020.11.26
// User: ID

#include "IState.h"

#include "CApp.h"
extern CApp app;

CStateMachine* IState::m_pStateMachine = nullptr;

                  
IState::~IState(){}

void IState::critical_protect(){
}

void IState::non_critical_protect(){
}

void IState::critical_operate(){
}

void IState::operate(){
    task_time_of_state(&pt_stateInTime);
}

void IState::reset(){
    PT_INIT(&pt_stateInTime);
}

char IState::task_time_of_state(PT* pt){
    static time_t _time;
    PT_BEGIN(pt);
    
    _time = CSysTick::sysTickTime_uSec;
    m_stateTime = TIME_SEC(0.0);
    
    PT_YIELD(pt);
      m_stateTime += CSysTick::sysTickTime_uSec < _time ? 
                     UINTMAX_MAX - _time + CSysTick::sysTickTime_uSec :
                     CSysTick::sysTickTime_uSec - _time;
      
      _time = CSysTick::sysTickTime_uSec;
    return PT_EXITED;
    
    PT_END(pt);
}
        
