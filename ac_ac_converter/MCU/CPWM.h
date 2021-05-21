// Date: 04.03.2021
// Creator: ID

#ifndef _CPWM_H
#define _CPWM_H

#include "IPheriphery.h"
#include "plib035_pwm.h"
#include "system_K1921VK035.h"

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
        PWM_0 = PWM0_BASE,
        PWM_1 = PWM1_BASE,        
        PWM_2 = PWM2_BASE,
    };
    
  private: 
    PWM_TypeDef* m_pwm;
    float m_freqInKHz;
    uint16_t m_freqInTicks;
    
  public:
    CPWM(ePWM _pwm){ 
        m_pwm = reinterpret_cast<PWM_TypeDef*>(_pwm);
    };
    
    void freq_set(float _freqKHz);
    
    #pragma inline = forced
    uint16_t freq_in_ticks_get()const{
        return m_freqInTicks;
    }
    
    
    #pragma inline = forced
    void out_enable(){
//        m_pwm->AQCTLA &= pwm::SET_STATES_A;
//        m_pwm->AQCTLA |= pwm::SET_STATES_A;
//        
//        m_pwm->AQCTLB &= pwm::SET_STATES_B;
//        m_pwm->AQCTLB |= pwm::SET_STATES_B;
         m_pwm->AQCTLA =    0x60;
         m_pwm->AQCTLB =    0x60;
         
    }
    void outA_enable(){
//        m_pwm->AQCTLA &= pwm::SET_STATES_A;
//        m_pwm->AQCTLA |= pwm::SET_STATES_A;
         m_pwm->AQCTLA =   0x60;
    }
    void outB_enable(){
//        m_pwm->AQCTLB &= pwm::SET_STATES_B;
//        m_pwm->AQCTLB |= pwm::SET_STATES_B;
         m_pwm->AQCTLB =    0x60;
    }
    
    #pragma inline = forced
    void out_disable(){
//      m_pwm->AQCTLA = 0;
//      m_pwm->AQCTLB = 0;
//      
//      m_pwm->AQCTLA |= pwm::CLR_STATES_A_OR_B;
//      m_pwm->AQCTLB |= pwm::CLR_STATES_A_OR_B;
        m_pwm->AQCTLA = 0x55;
	m_pwm->AQCTLB = 0xAA;
        
      
    }
    void outA_disable(){
//        m_pwm->AQCTLA = 0;
//        m_pwm->AQCTLA |= pwm::CLR_STATES_A_OR_B;
        m_pwm->AQCTLA = 0x55;
    }
    void outB_disable(){
//        m_pwm->AQCTLB = 0;
//        m_pwm->AQCTLB |= pwm::CLR_STATES_A_OR_B;
        m_pwm->AQCTLB = 0xAA;
    }
    
    
    
    
    #pragma inline = forced
    void cmp_set(uint16_t _cmp) const{
      m_pwm->CMPA_bit.CMPA = _cmp;
      m_pwm->CMPB_bit.CMPB = _cmp;
    }
    
    void TZ_enable(bool _irqEnable = false);
    void TZ_IT_reset();
    
};


#endif // _CPWM_H
