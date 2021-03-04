// Date: 04.03.2021
// Creator: ID

#ifndef _CPWM_H
#define _CPWM_H

#include "IPheriphery.h"
#include "niietcm4_pwm.h"


class CPWM : public IPheriphery{
    
  public:
    enum class ePWM : uint32_t {
        PWM_0 = NT_PWM0_BASE,
        PWM_1 = NT_PWM1_BASE,        
        PWM_2 = NT_PWM2_BASE,
        PWM_3 = NT_PWM3_BASE,
        PWM_4 = NT_PWM4_BASE,
        PWM_5 = NT_PWM5_BASE,
        PWM_6 = NT_PWM6_BASE,
        PWM_7 = NT_PWM7_BASE
    };
    
  private: 
    NT_PWM_TypeDef* m_pwm;
    float m_freqInKHz;
    uint16_t m_freqInTicks;
    
  public:
    CPWM(ePWM _pwm){ 
        m_pwm = reinterpret_cast<NT_PWM_TypeDef*>(_pwm);
    };
    
    void freq_set(float _freqKHz);
    
    uint16_t freq_in_ticks_get()const{
        return m_freqInTicks;
    }
    
    void out_enable();
    void out_disable();
    
    void cmp_set(uint16_t _cmp) const;
    
};


#endif // _CPWM_H
