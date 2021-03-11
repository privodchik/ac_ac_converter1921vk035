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
        if(app.cmds.start) app.sm.state_set(&app.stRun);                                             
}

void CReady::reset(){
	IState::reset();
	
}