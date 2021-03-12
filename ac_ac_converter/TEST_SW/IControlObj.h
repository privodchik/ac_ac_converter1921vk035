// Date: 2020.12.10
// User: ID

#ifndef _ICONTROLOBJ_H
#define _ICONTROLOBJ_H

#include <cstdint>
#include "IPheriphery.h"

class IControlObj
{
  protected:
    IPheriphery* m_pPeriphery; 
	
  public:
    IControlObj(IPheriphery* _pPeriph = nullptr) : m_pPeriphery(_pPeriph){}
    virtual ~IControlObj(){}
			
    virtual void switch_on() = 0;
    virtual void switch_off() = 0;
};


#endif //_ICONTROLOBJ_H
