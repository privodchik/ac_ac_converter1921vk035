// Date: 2020.11.26
// User: ID

#ifndef _CPRERUN
#define _CPRERUN

#include "IState.h"
#include "timer.h"

class CPrerun : public IState
{
	public:
		CPrerun() : IState(PRERUN){}
			
		virtual void critical_protect();
		virtual void non_critical_protect();
		
		virtual void critical_operate();	
		virtual void operate();
		
	public:
		virtual void reset();
	
	private:
		void regulators_config();
	
		PT pt_operating;
		PT_THREAD(task_operating(PT* pt));
	
	private:
		TIMER tmr_delay;
	
};

#endif //_CPRERUN

