// Date: 2020.11.26
// User: ID

#ifndef _CDIAG
#define _CDIAG

#include "IState.h"
#include "CIgbt.h"
#include "CKM.h"
#include "iqmath.h"



class CDiag : public IState
{
    static const int CONTROLS_QUANT = 5;
    private:
      CIgbt m_pwm0_ChA;
      CIgbt m_pwm0_ChB;
      CIgbt m_pwm1_ChA;
      CIgbt m_pwm1_ChB;
      CKM   m_km{nullptr};
    
      IControlObj* m_controls[CONTROLS_QUANT];
    
    public:
      iq_t m_pwm_duty; //per cent
    
    public:
        CDiag();

        virtual void critical_protect();
        virtual void non_critical_protect();
        
        virtual void critical_operate();	
        virtual void operate();
        
  public:
        virtual void reset();

        PT pt_sw_config;
        PT_THREAD(task_sw_config(PT* pt));

};

#endif //_CDIAG

