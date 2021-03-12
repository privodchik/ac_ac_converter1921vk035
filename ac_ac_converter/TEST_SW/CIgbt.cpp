// Date: 2020.12.10
// User: ID

#include "CIgbt.h"

void CIgbt::switch_on(){
    if (m_channel == eChannel::A)
        (static_cast<CPWM*>(m_pPeriphery))->outA_enable();
    else if (m_channel == eChannel::B)
        (static_cast<CPWM*>(m_pPeriphery))->outB_enable();
}

void CIgbt::switch_off(){
    if (m_channel == eChannel::A)
        (static_cast<CPWM*>(m_pPeriphery))->outA_disable();
    else if (m_channel == eChannel::B)
        (static_cast<CPWM*>(m_pPeriphery))->outB_disable();
}


void CIgbt::duty_set(iq_t _duty){
    if (_duty >= IQ(1.0)) _duty = IQ(0.95);
    else if (_duty <= IQ(0.0)) _duty = IQ(0.05);
    
    
    uint16_t _freq = (static_cast<CPWM*>(m_pPeriphery))->freq_in_ticks_get()>>1;
    
    (static_cast<CPWM*>(m_pPeriphery))->cmp_set(IQmpy(_duty, IQ(_freq)));
}






