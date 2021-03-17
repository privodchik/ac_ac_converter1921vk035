// Date: 2020.11.26
// User: ID

#include "CRun.h"

#include "CApp.h"
extern CApp app;


void CRun::critical_protect(){
	IState::critical_protect();	
}

void CRun::non_critical_protect(){
	IState::non_critical_protect();
}

void CRun::critical_operate(){
}	

void CRun::operate(){
    IState::operate();
    if(!app.cmds.start) app.sm.state_set(&app.stReady);
}

void CRun::reset(){
        m_isRegsInit = false;
	IState::reset();
        m_currentAngle = 0;
        init_regulators();
        
        m_virtGrid = 0;
}

void CRun::init_regulators(){
    regUd_shadow.reset();
    regUq_shadow.reset();
    regId_shadow.reset();
    
    regUd_shadow.config_set();
    regUq_shadow.config_set();
    regId_shadow.config_set();
    
    app.regUd = regUd_shadow;
    app.regUq = regUq_shadow;
    app.regId = regId_shadow;
    
    m_isRegsInit = true;
}
