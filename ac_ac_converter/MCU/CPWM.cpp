// Date: 04.03.2021
// Creator: ID

#include "CPWM.h"

#include "config.h"

namespace pwm{

    const uint32_t SW_ON = 2;
    const uint32_t SW_OFF = 1;
        
    const uint32_t SET_STATES_A = (SW_ON << 4)  | (SW_OFF << 6);
    const uint32_t SET_STATES_B = (SW_OFF << 4) | (SW_ON << 6); 
//    const uint32_t SET_STATES_A = 0x60;
//    const uint32_t SET_STATES_B = 0x60; 
    
    const uint32_t CLR_STATES_A_OR_B = SW_OFF | (SW_OFF << 2) 
                                       | (SW_OFF << 4) | (SW_OFF << 6);
}


void CPWM::freq_set(float _freqKHz){
      m_freqInKHz = _freqKHz;
      uint32_t _f = SystemCoreClock/static_cast<uint32_t>(FREQ_KHZ*1000);
      m_freqInTicks = static_cast<uint32_t>(_f);
}

void CPWM::TZ_enable(eTZChannel _channel, bool _irqEnable){
    PWM_TZ_ActionConfig(m_pwm, PWM_TZ_Action_ToZero, PWM_TZ_Action_ToZero);
    PWM_TZ_OneShotCmd(m_pwm, uint32_t(_channel), ENABLE);
    
    if (_irqEnable)
        PWM_TZ_ITCmd(m_pwm, PWM_TZ_ITSource_OneShot, ENABLE);
    TZ_reset();
}

void CPWM::TZ_reset(){
//    PWM_TZ_ITPendClear(m_pwm);
    PWM_TZ_ITStatusClear(m_pwm, PWM_TZ_ITStatus_All);
}

