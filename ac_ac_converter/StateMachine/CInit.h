// Date: 2020.11.26
// User: ID

#ifndef _CINIT
#define _CINIT

#include "IState.h"

class CInit : public IState
{
	public:
		CInit() : IState(INIT){}
			
		virtual void critical_protect() override;
		virtual void non_critical_protect() override;
		
		virtual void critical_operate() override;	
		virtual void operate()override;
		
	public:
		virtual void reset();
                
//                time_t (CInit::*ptrFunc)() = &CInit::time_in_state_est;
	
	private:
		PT pt_wait;
		PT_THREAD(task_wait(PT* pt));
};

#endif //_CINIT

