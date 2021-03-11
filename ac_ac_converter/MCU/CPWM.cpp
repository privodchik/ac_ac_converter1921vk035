// Date: 04.03.2021
// Creator: ID

#include "CPWM.h"

#include "config.h"



void CPWM::freq_set(float _freqKHz){
    m_freqInKHz = _freqKHz;
    uint32_t _f = SystemCoreClock/static_cast<uint32_t>(FREQ_KHZ*1000);
    m_freqInTicks = static_cast<uint32_t>(_f);
    
    
    
}


