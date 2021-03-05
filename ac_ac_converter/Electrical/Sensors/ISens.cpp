// Date: 05.03.2021
// Creator: ID

#include "ISens.h"





ISens::~ISens(){}

void ISens::adc_val_set(uint16_t _adcVal){
    iq_t _realVal = m_kD2A * (_adcVal - m_adcOffset);
    _realVal -= m_RealOffsetDelta;
    m_realVal = m_inversion ?  -_realVal : _realVal;
}
