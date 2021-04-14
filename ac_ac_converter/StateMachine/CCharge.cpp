// Date: 2020.11.26
// User: ID

#include "CCharge.h"

#include "CApp.h"
extern CApp app;

#define USE_DIAGNOSTIC

void CCharge::critical_protect(){
    IState::critical_protect();	
}

void CCharge::non_critical_protect(){
    IState::non_critical_protect();
}

void CCharge::critical_operate(){
    IState::critical_operate();
}

void CCharge::operate(){
    IState::operate();

#ifdef USE_DIAGNOSTIC	  
    if (m_stateTime > TIME_SEC(5.0)) app.sm.state_set(&app.stReady);
#else
    task_charge(&pt_charge);
#endif	        
}

void CCharge::reset(){
    IState::reset();
    PT_INIT(&pt_charge);
}


char CCharge::task_charge(PT* pt){
    static TIMER tmr;
    
    PT_BEGIN(pt);
    timer_set(&tmr, TIME_SEC(30));

    PT_YIELD(pt);

    if (!timer_expired(&tmr)){
            
//      if (    (app.sens_uBUSP_N.read() >= UBUSPN_MIN)
//          &&  (app.sens_uBUSN_N.read() >= UBUSNN_MIN)
//          )
      if (app.sens_uBUS.read() >= UBUS_MIN)  
      {
          app.sm.state_set(&app.stReady);
          return PT_ENDED;
      }
      return PT_EXITED;
    }
    
    app.errors.set(CErrors::ERROR_BUS_MIN);
    app.sm.state_set(&app.stFault);
    
    PT_END(pt);
}

