// Date: 2020.11.26
// User: ID

#include "CFault.h"
#include "app_lgm.h"

void CFault::critical_protect(){
	app.pwmN.out_disable();
	app.pwmP.out_disable();
	
	IState::critical_protect();	
}

void CFault::non_critical_protect(){
	IState::non_critical_protect();
}

void CFault::critical_operate(){
}

void CFault::operate(){
	IState::operate();
	app.cmds.start = 0;
	if (app.cmds.rst){
		app.cmds.rst = 0;
		IState::state_set(IState::INIT);
	}
}

void CFault::reset(){
	app.pwmN.out_disable();
	app.pwmP.out_disable();
}
