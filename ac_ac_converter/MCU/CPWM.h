// Date: 04.03.2021
// Creator: ID

#ifndef _CPWM_H
#define _CPWM_H

#include "IPheriphery.h"
#include "niietcm4_pwm.h"
#include "system_K1921VK01T.h"

namespace pwm{
    extern const uint32_t SW_ON;
    extern const uint32_t SW_OFF;
        
    extern const uint32_t SET_STATES_A;
    extern const uint32_t SET_STATES_B; 
    extern const uint32_t CLR_STATES_A_OR_B;
}

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
    
    
    #pragma inline = forced
    void out_enable(){
        m_pwm->AQCTLA &= pwm::SET_STATES_A;
        m_pwm->AQCTLA |= pwm::SET_STATES_A;
        
        m_pwm->AQCTLB &= pwm::SET_STATES_B;
        m_pwm->AQCTLB |= pwm::SET_STATES_B;
    }
    void outA_enable(){
        m_pwm->AQCTLA &= pwm::SET_STATES_A;
        m_pwm->AQCTLA |= pwm::SET_STATES_A;
    }
    void outB_enable(){
        m_pwm->AQCTLB &= pwm::SET_STATES_B;
        m_pwm->AQCTLB |= pwm::SET_STATES_B;
    }
    
    #pragma inline = forced
    void out_disable(){
      m_pwm->AQCTLA = 0;
      m_pwm->AQCTLB = 0;
      
      m_pwm->AQCTLA |= pwm::CLR_STATES_A_OR_B;
      m_pwm->AQCTLB |= pwm::CLR_STATES_A_OR_B;
    }
    void outA_disable(){
        m_pwm->AQCTLA = 0;
        m_pwm->AQCTLA |= pwm::CLR_STATES_A_OR_B;
    }
    void outB_disable(){
        m_pwm->AQCTLB = 0;
        m_pwm->AQCTLB |= pwm::CLR_STATES_A_OR_B;
    }
    
    
    
    
    #pragma inline = forced
    void cmp_set(uint16_t _cmp) const{
      m_pwm->CMPA_bit.CMPA = _cmp;
      m_pwm->CMPB_bit.CMPB = _cmp;
    }
    
};


#endif // _CPWM_H
