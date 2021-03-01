// Date: 2020.11.26
// User: ID

#ifndef _CFAULT
#define _CFAULT

#include "IState.h"

class CFault : public IState
{
	public:
		CFault() : IState(FAULT){}
			
		virtual void critical_protect();
		virtual void non_critical_protect();
		
		virtual void critical_operate();	
		virtual void operate();
		
	public:
		virtual void reset();			
};

#endif //_CFAULT

