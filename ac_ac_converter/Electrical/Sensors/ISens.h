  // Date: 05.03.2021
  // Creator: ID


#ifndef _ISENS_H
#define _ISENS_H

#include "iqmath.h"
#include "system_K1921VK01T.h"

// resistances in kOhm 
#define Uref (1.4)
#define kADC (4095.0/Uref)   

constexpr uint16_t adc_offset_est(float Roffset,
                                        float Rsingle,
                                        float Rhi,
                                        float Rlo)
{
    return static_cast<uint16_t>(
                                   Uref*Rlo*kADC *    
                                   (Rsingle+Rhi) /
                                   ( Roffset*(Rhi+Rlo+Rsingle) + 
                                     Rlo*(Rsingle+Rhi)
                                   )
                                 );
}
#undef Uref
#undef kADC




class ISens{
  
  protected:
    iq_t        m_kD2A = 0;
    int16_t     m_adcOffset = 0;
    iq_t        m_realVal = 0;
    iq_t        m_RealOffsetDelta = 0;
    bool        m_inversion = false;
    uint16_t    m_adcVal = 0;
    
  public:
    constexpr ISens(){}
    virtual ~ISens() = 0;
    #pragma inline = forced
    const iq_t& read()const{return m_realVal;}
    
    void adc_val_set(uint16_t _adcVal);
    inline const uint16_t& adc_val_get()const{return m_adcVal;}
    
    #pragma inline = forced    
    void real_val_set(uint16_t _realVal){m_realVal = _realVal;}
    
    void offset_set(iq_t _realOffset){m_RealOffsetDelta = _realOffset;}
    void inversion(bool _isInv){m_inversion = _isInv;}
    
    #pragma inline = forced
    const iq_t& scale_get()const{return m_kD2A;}
    
    void correct_coef_set(float _correct){
          m_kD2A = IQmpy(m_kD2A, IQ(_correct));
    }
    
    
    friend void ADC_SEQ0_IRQHandler(void);
};


//#pragma inline = forced
inline void ISens::adc_val_set(uint16_t _adcVal){
    m_adcVal = _adcVal;
    iq_t _realVal = m_kD2A * (int(_adcVal) - m_adcOffset);
    _realVal -= m_RealOffsetDelta;
    m_realVal = m_inversion ?  -_realVal : _realVal;
}





#endif //_ISENS_H
