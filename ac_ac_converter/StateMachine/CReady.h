// Date: 2020.11.26
// User: ID

#ifndef _CREADY
#define _CREADY

#include "IState.h"


class CReady : public IState
{
  public:
    CReady() : IState(READY){}
            
    virtual void critical_protect();
    virtual void non_critical_protect();
    
    virtual void critical_operate();	
    virtual void operate();
          
  public:
    virtual void reset();
    
  

	
};

#endif //_CREADY

