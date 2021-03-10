// Date: 2020.11.10
// User: ID


#ifndef _ITRANSFUNC_H
#define _ITRANSFUNC_H

#include "iqmath.h"

class ITransFunc{
    protected:
            iq_t m_Ts;
            iq_t m_yk;
    
    public:
            iq_t m_sat_pos;
            iq_t m_sat_neg;
            
    public:
      ITransFunc(iq_t _Ts, iq_t _sat_pos, iq_t _sat_neg) : 
                                                m_Ts(_Ts),
                                                m_sat_pos(_sat_pos),
                                                m_sat_neg(_sat_neg),
                                                m_yk(0){}
    
            virtual void Ts_set(iq_t _Ts){ m_Ts = _Ts > 0 ? _Ts : IQ(0.0001); }
            
//		virtual iq_t out_est(iq_t _xk) = 0; // It is not virtual, it invokes in critical part
            
            iq_t out_get(){ return m_yk; }
            iq_t& out_ref_get(){ return m_yk; }
            
            void out_set(iq_t _yk){ m_yk = _yk;}
            
            virtual void sat_set(iq_t _sat_pos, iq_t _sat_neg){
                    m_sat_pos = _sat_pos;
                    m_sat_neg = _sat_neg;
            }
            
            virtual void config_set(){}
                    
            virtual void reset(){out_set(0);}
            
    protected:
            #pragma inline = forced
            iq_t out_limit(){return m_yk = (m_yk > m_sat_pos) ? m_sat_pos : 
                                                                                                     ( (m_yk < m_sat_neg) ? m_sat_neg : m_yk);}
            
    public:
};


#endif //_ITRANSFUNC_H
