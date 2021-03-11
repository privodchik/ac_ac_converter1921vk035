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
    IState*             m_ptrCurrentState;
    IState::eState      m_CurrentStateName;
		
  public:
    CStateMachine(IState* _pInitState)
    {
        m_ptrCurrentState = _pInitState;
        m_CurrentStateName = m_ptrCurrentState->state_name_get();
        m_ptrCurrentState->reset();
    }

    void state_set(IState* _state){
        m_ptrCurrentState = _state;

        if (m_CurrentStateName != _state->state_name_get()){
            m_CurrentStateName = m_ptrCurrentState->state_name_get();
            m_ptrCurrentState->reset();
        }
    }
     
    #pragma inline = forced
    const IState* state_get() const{return m_ptrCurrentState;}
    #pragma inline = forced
    const IState::eState& state_name_get() const {return m_CurrentStateName;}
    
    void operate(){
        m_ptrCurrentState->operate();
    }
    
    void critical_operate(){
        m_ptrCurrentState->critical_operate();
    }
    
    
    
};



#endif //_STATE_MACHINE_H
