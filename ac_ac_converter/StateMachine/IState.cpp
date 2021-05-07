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

    if (app.sm.state_name_get() == IState::FAULT) return;
    
    if (ABS(app.sens_uBUS.read()) > UBUS_MAX){
        app.errors.set(CErrors::eError_t::ERROR_BUS_MAX);
        app.sm.state_set(&app.stFault);
    }
    
    if (ABS(app.sens_uOut.read()) > VAC_AMP_MAX){
        app.errors.set(CErrors::eError_t::ERROR_CONVERTER_VMAX);
        app.sm.state_set(&app.stFault);
    }
    
    if (ABS(app.sens_iFull.read()) > IAC_AMP_MAX){
        app.errors.set(CErrors::eError_t::ERROR_CONVERTER_IMAX);
        app.sm.state_set(&app.stFault);
    }
}

void IState::critical_operate(){
    

}

void IState::operate(){
    task_time_of_state(&pt_stateInTime);
    if (app.sm.state_name_get() != IState::eState::RUN){
        if (app.cmds.diag) app.sm.state_set(&app.stDiag);
    }
    
    if (app.sens_iFull.read() > IQ(15)){
        app.cmds.fun = 1;
    }
    
    if (app.cmds.fun){
        app.fun.write(FUN_ON);
    }
    else{
        app.fun.write(FUN_OFF);
    }
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
        
