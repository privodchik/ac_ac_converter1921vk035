// Date: 2020.11.26
// User: ID

#include "CFault.h"

#include "CApp.h"
extern CApp app;

void CFault::critical_protect(){
	app.pwm_A.out_disable();
	app.pwm_B.out_disable();
	
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
                app.sm.state_set(&app.stInit);
	}
}

void CFault::reset(){
	app.pwm_A.out_disable();
	app.pwm_B.out_disable();
}
