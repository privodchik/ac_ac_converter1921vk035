// Date: 2020.11.26
// User: ID

#ifndef _ISTATE_H
#define _ISTATE_H

//#include "IQmathLib.h"
#include "iqmath.h"
#include <cstdint>
#include "pt.h"
#include "CSysTick.h"
#include "timer.h"
#include "config.h"


#define FUN_ON false
#define FUN_OFF true

class CStateMachine; 

class IState
{
    public:
      enum eState{
            INIT = 0,
            CHARGE,
            READY,
            PRERUN,
            RUN,
            FAULT,
            DIAG
          };
    
    protected:
      const eState m_state;
      
    private:
      static CStateMachine* m_pStateMachine;
    
  public:
    static void state_machine_register(CStateMachine* _pStateMachine){
          m_pStateMachine = _pStateMachine;
    }
    const CStateMachine* state_machine_ptr_get() const{return m_pStateMachine;}
      

    public:
      IState(eState _state) : m_state(_state){}
      virtual ~ IState() = 0;
              
      virtual void critical_protect();
      virtual void non_critical_protect();
      
      virtual void critical_operate();	
      virtual void operate();
      
      eState state_name_get() const {return m_state;}
      
    public:
      virtual void reset();
      
    public:
      time_t m_stateTime;
      
      PT pt_stateInTime;
      PT_THREAD(task_time_of_state(PT*));
      
    protected:
      #pragma inline = forced
      bool is_time_expired(time_t _time_usec){return m_stateTime > _time_usec;}
    
};


#endif //_ISTATE_H

