// Date: 2021.05.07
// Creator: ID

#include "CRMS.h"


CRMS::CRMS(iq_t _Ts, iq_t _freq): m_freq(_freq){
    m_integrator.Ts_set(_Ts);
    m_integrator.config_set();
}

void CRMS::Ts_set(iq_t _Ts){
    m_integrator.Ts_set(_Ts);
    m_integrator.config_set();
}


void CRMS::out_est(iq_t _in){
    m_currentValue = IQsqrt(IQmpy(m_freq, m_integrator.out_est(IQmpy(_in, _in))));
}

void CRMS::out_reset(){
    m_integrator.reset();
}

