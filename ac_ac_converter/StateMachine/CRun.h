// Date: 2020.11.26
// User: ID

#ifndef _CRUN
#define _CRUN

#include "IState.h"
#include "iqmath.h"
#include "user_constants.h"


class CRun : public IState
{
  private:
    iq_t m_currentAngle = 0;
    iq_t m_delWt;
    
  public:
    CRun() : IState(RUN){}
            
    virtual void critical_protect() override;
    virtual void non_critical_protect() override;
    
    virtual void critical_operate() override;	
    virtual void operate() override;
          
  public:
    virtual void reset() override;
      
  public:
    iq_t angle_est(iq_t _Ts);
};

#pragma inline = forced
inline iq_t CRun::angle_est(iq_t _Ts){
    iq_t _delWt = IQmpy(utl::W, _Ts);
    m_currentAngle += _delWt;
    
    if (m_currentAngle > utl::_2PI) m_currentAngle = 0;
    return m_currentAngle;    
}




#endif //_CRUN

