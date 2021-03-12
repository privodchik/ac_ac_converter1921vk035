// Date: 2020.12.10
// User: ID

#ifndef _CKM_H
#define _CKM_H

#include "IControlObj.h"
#include "CPin.h"

class CKM : public IControlObj
{
  public:
    CKM(IPheriphery* _pPeriph) : IControlObj(_pPeriph){}
    virtual void switch_on();
    virtual void switch_off();
	
};



#endif //_CKM_H

