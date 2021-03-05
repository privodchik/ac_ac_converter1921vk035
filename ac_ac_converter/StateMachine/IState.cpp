// Date: 2020.11.26
// User: ID

#include "IState.h"

#include "CApp.h"
extern CApp app;


IState* IState::m_ptr_current_state;
IState::eState IState::m_current_state;

const uint8_t IState::STATES_QUANTITY = IState::eState::DIAG + 1; 

IState** IState::m_pStatesArray;


IState::~IState(){}

void IState::state_set(eState _state){
	
	m_current_state = _state;

	if (_state != m_state){
		m_ptr_current_state = m_pStatesArray[_state];
		m_ptr_current_state->reset();
	}		
	
}

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
    
    _time = CSysTick::sysTickTimeMs;
    m_stateTime = TIME_SEC(0.0);
    
    PT_YIELD(pt);
      m_stateTime += CSysTick::sysTickTimeMs < _time ? 
                     UINTMAX_MAX - _time + CSysTick::sysTickTimeMs :
                     CSysTick::sysTickTimeMs - _time;
      
      _time = CSysTick::sysTickTimeMs;
    return PT_EXITED;
    
    PT_END(pt);
}
        
