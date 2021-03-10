// Date: 2020.11.26
// User: ID

#ifndef _STATE_MACHINE_H
#define _STATE_MACHINE_H

#include "IState.h"

class CStateMachine
{
    friend class IState;
  private:		
    
  private:
    IState* m_ptr_current_state;
		
  public:
    CStateMachine(IState* _pInitState)
    {
        m_ptr_current_state = _pInitState;
//        _pInitState->state_set(_pInitState->state_no_get());
//        m_ptr_current_state = _pInitState->state_current_ptr_get();
    }
    void state_set(IState::eState _state);
    IState::eState state_name_get(){return m_ptr_current_state->state_current_no_get();}
    
    void operate(){
        m_ptr_current_state->operate();
    }
    
    void critical_operate(){
        m_ptr_current_state->critical_operate();
    }
    
    
    
};



#endif //_STATE_MACHINE_H
