// Date: 2020.12.10
// User: ID

#ifndef _CIGBT_H
#define _CIGBT_H

#include "IControlObj.h"
#include "plib035_pwm.h"
#include "K1921VK035.h"
#include "CPWM.h"
#include "iqmath.h"

class CIgbt : public IControlObj
{
  public:
    enum class eChannel{A = 0, B};
  
  private:
    eChannel m_channel;
  public:
    CIgbt(){}
    CIgbt(IPheriphery* _pPeriph, eChannel _ch) : IControlObj(_pPeriph),
                                                 m_channel(_ch)
    {}
    virtual void switch_on();
    virtual void switch_off();
    
    void duty_set(iq_t _duty);
};



#endif //_CIGBT_H

