// Date: 2020.11.26
// User: ID

#include "CReady.h"

#include "CApp.h"
extern CApp app;


void CReady::critical_protect(){

	
    IState::critical_protect();	
}

void CReady::non_critical_protect(){
	IState::non_critical_protect();
}

void CReady::critical_operate(){
    IState::critical_operate();
}

void CReady::operate(){
	IState::operate();
        if (m_stateTime > TIME_SEC(5.0)) app.sm.state_set(&app.stInit);
}

void CReady::reset(){
	IState::reset();
	
}