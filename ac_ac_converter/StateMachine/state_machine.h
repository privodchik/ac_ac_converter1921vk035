// Date: 2020.11.26
// User: ID

#ifndef _STATE_MACHINE_H
#define _STATE_MACHINE_H

#include "IState.h"

class CStateMachine
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
		
  private:		
//      const IState* states[]
			
  private:
      eState m_current_state;
      IState* m_ptr_current_state;
				
		
  public:
      CStateMachine(){}
      void state_set(eState _state);
};

#endif //_STATE_MACHINE_H
