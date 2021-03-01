// Date: 2020.11.26
// User: ID

#include "IState.h"
#include "CApp.h"

IState* IState::m_ptr_current_state;
IState::eState IState::m_current_state;

PT IState::pt_link_error;

IState::~IState(){}

void IState::state_set(eState _state){
	
	m_current_state = _state;

	if (_state != m_ptr_current_state->m_state){
		m_ptr_current_state = states[_state];
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
}

void IState::reset(){
}
