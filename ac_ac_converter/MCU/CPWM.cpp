// Date: 04.03.2021
// Creator: ID

#include "CPWM.h"

#include "config.h"

void CPWM::out_enable(){
}

void CPWM::out_disable(){
}

void CPWM::freq_set(float _freqKHz){
    m_freqInKHz = _freqKHz;
    uint32_t _f = SystemCoreClock/static_cast<uint32_t>(FREQ_KHZ*1000);
    m_freqInTicks = static_cast<uint32_t>(_f);
}

void CPWM::cmp_set(uint16_t _cmp) const{
    PWM_CMP_SetA(m_pwm, _cmp);
    PWM_CMP_SetB(m_pwm, _cmp);
}



