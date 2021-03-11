// Date: 2020.11.10
// User: ID

#ifndef _TF_INTEGRATOR_H
#define _TF_INTEGRATOR_H

#include "itrans_func.h"


class CIntegrator : public ITransFunc{
    public:
        iq_t m_Ti;
    private:
        iq_t m_TsDivTi;
    
    public:
      CIntegrator(iq_t _Ts, iq_t _Ti,  iq_t _sat_pos, iq_t _sat_neg) : 
                    ITransFunc(_Ts, _sat_pos, _sat_neg),
                    m_Ti(_Ti)
      {
          config_set();
       }
        
              
      void Ti_set(iq_t _Ti){ m_Ti = _Ti;}
      virtual void config_set(){m_TsDivTi = IQdiv(m_Ts, m_Ti);}
      
      #pragma inline = forced
      iq_t out_est(iq_t _xk){
          m_yk += IQmpy(m_TsDivTi, _xk);
	return out_limit();
      }
      
};


#endif //_TF_INTEGRATOR_H


