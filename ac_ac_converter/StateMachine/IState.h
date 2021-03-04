// Date: 2020.11.26
// User: ID

#ifndef _ISTATE_H
#define _ISTATE_H

//#include "IQmathLib.h"
#include "iqmath_int32_mcu.h"
#include <cstdint>
#include "pt.h"
#include "CSysTick.h"
#include "timer.h"

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

      static eState m_current_state;
      static IState* m_ptr_current_state;
      
      static const uint8_t STATES_QUANTITY;  
    
    public:
      IState(eState _state) : m_state(_state){}
      virtual ~ IState() = 0;
              
      virtual void critical_protect();
      virtual void non_critical_protect();
      
      virtual void critical_operate();	
      virtual void operate();
      
      void state_set(eState _state);
      static IState* state_current_ptr_get() {return m_ptr_current_state;}
      static eState state_current_no_get(){return m_current_state;}
      
      
    private:  
      static IState** m_pStatesArray;
    public:
      static void states_array_register(IState** _pStatesArray){
          m_pStatesArray = _pStatesArray;
      }
                    
    public:
      virtual void reset();
      
    public:
      time_t m_stateTime;
      
      PT pt_stateInTime;
      PT_THREAD(task_time_of_state(PT*));
      
    
    
};


#endif //_ISTATE_H

