// Date: 2020.11.26
// User: ID

#ifndef _CCHARGE
#define _CCHARGE

#include "IState.h"


class CCharge : public IState
{
	public:
		CCharge() : IState(CHARGE){}
			
		virtual void critical_protect();
		virtual void non_critical_protect();
		
		virtual void critical_operate();	
		virtual void operate();
		
	public:
		virtual void reset();
	
	private:
		PT pt_charge;
		PT_THREAD(task_charge(PT* pt));
		
};

#endif //_CCHARGE

