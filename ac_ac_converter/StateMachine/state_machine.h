// Date: 2020.11.26
// User: ID

#ifndef _STATE_MACHINE_H
#define _STATE_MACHINE_H

#include "IState.h"

class CStateMachine
{
  private:		
    
  private:
      IState* m_ptr_current_state;
		
  public:
    CStateMachine(IState* _pInitState) : m_ptr_current_state(_pInitState){}
    void state_set(IState::eState _state);
    
    void operate(){
        m_ptr_current_state->operate();
    }
    
    void critical_opertate(){
        m_ptr_current_state->critical_operate();
    }
};



#endif //_STATE_MACHINE_H
