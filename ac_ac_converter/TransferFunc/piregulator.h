// Date: 2020.11.26
// User: ID

#ifndef _PIREGULATOR_H
#define _PIREGULATOR_H

#include "itrans_func.h"
#include "integrator.h"


class CPIReg : public ITransFunc
{
    private:	
            iq_t         m_proportional_part;
            CIntegrator  m_integral_part;
    
    public:
            CPIReg(iq_t _Ts, iq_t _Kp, iq_t _Ti, iq_t _sat_pos, iq_t _sat_neg) :
              ITransFunc(_Ts, _sat_pos, _sat_neg), 
              m_proportional_part(_Kp),
              m_integral_part(_Ts, _Ti, _sat_pos, _sat_neg)
              {}
            
            #pragma inline = forced  
            void K_set(iq_t _K){m_proportional_part = _K;}
            
            #pragma inline = forced  
            void Ti_set(iq_t _Ti){m_integral_part.Ti_set(_Ti);}
            
            virtual void Ts_set(iq_t _Ts) override{
                    m_Ts = _Ts;
                    m_integral_part.Ts_set(_Ts);
            } 
            virtual void sat_set(iq_t _sat_pos, iq_t _sat_neg){
                    ITransFunc::sat_set(_sat_pos, _sat_neg);
                    m_integral_part.sat_set(_sat_pos, _sat_neg);
            }
            virtual void config_set(){
                m_integral_part.config_set();
            }
            
            #pragma inline = forced  
            iq_t out_est(iq_t _xk){
                m_yk = IQmpy(m_proportional_part, _xk) + m_integral_part.out_est(_xk);
                return out_limit();
            }
            
            virtual void reset(){ITransFunc::reset(); m_integral_part.reset();}			
};



#endif //_PIREGULATOR_H

