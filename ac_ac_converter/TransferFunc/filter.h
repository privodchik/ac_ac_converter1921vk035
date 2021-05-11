// Date: 2020.11.26
// User: ID

#ifndef _FILTER_H
#define _FILTER_H

#include "itrans_func.h"

class CFilter : public ITransFunc
{
  public:
      iq_t m_Tf;
  private:
      iq_t m_k1;
      iq_t m_k2;
    
    public:
      CFilter(iq_t _Ts, iq_t _Tf, iq_t _sat_pos, iq_t _sat_neg) 
          : ITransFunc(_Ts, _sat_pos, _sat_neg),
          m_Tf(_Tf)
      {
        config_set();
      }
              
      void Tf_set(iq_t _Tf){m_Tf = _Tf;}	
      
      virtual void config_set(){
            m_k1 = IQdiv(m_Ts, m_Ts + m_Tf);
            m_k2 = IQdiv(m_Tf, m_Ts + m_Tf);
      }
            
      #pragma inline = forced
      iq_t out_est(iq_t _xk){
        m_yk = IQmpy(m_k1, _xk)  + IQmpy(m_k2, m_yk);
        return out_limit();
      }
};

#endif
