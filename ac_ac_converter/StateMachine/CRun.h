// Date: 2020.11.26
// User: ID

#ifndef _CRUN
#define _CRUN

#include "IState.h"
#include "iqmath.h"
#include "user_constants.h"

#include "piregulator.h"


class CRun : public IState
{
  private:
    iq_t m_currentAngle = 0;
    iq_t m_delWt;
    
  public: 
    // The regulators are needed to copy parameters to main app.regXx
    CPIReg regUd_shadow{IQ(0.000025), IQ(10.0), IQ(0.01), IQ(200.0), IQ(-200.0)};
    CPIReg regUq_shadow{IQ(0.000025), IQ(10.0), IQ(0.01), IQ(200.0), IQ(-200.0)};
    CPIReg regId_shadow{IQ(0.000025), IQ(10.0), IQ(0.002), IQ(1.0), IQ(-1.0)};
    
    bool m_isRegsInit = false;
    
    
  public:
    CRun() : IState(RUN){}
            
    virtual void critical_protect() override;
    virtual void non_critical_protect() override;
    
    virtual void critical_operate() override;	
    virtual void operate() override;
    
    
          
  public:
    virtual void reset() override;
    
  private:
    void init_regulators();
      
  public:
    iq_t angle_est(iq_t _W, iq_t _Ts);
    
    iq_t m_virtGrid = 0; 
};

#pragma inline = forced
inline iq_t CRun::angle_est(iq_t _W, iq_t _Ts){
    iq_t _delWt = IQmpy(_W, _Ts);
    m_currentAngle += _delWt;
    
    if (m_currentAngle > utl::_PI) m_currentAngle -= utl::_2PI;
    else if (m_currentAngle < - utl::_PI) m_currentAngle += utl::_2PI;
    
    return m_currentAngle;    
}




#endif //_CRUN

