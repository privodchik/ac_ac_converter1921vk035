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
	
	
//	if(app.cmds.start || (is_start_from_vsi() && !is_stop_from_vsi())){
//		IState::state_set(IState::PRERUN);
//	}
//	
//	if (app.cmds.rst){
//		IState::state_set(IState::INIT);
//		app.cmds.rst = 0;
//	}
	
}

void CReady::reset(){
	IState::reset();
	
}
