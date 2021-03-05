  // Date: 05.03.2021
  // Creator: ID


#ifndef _ISENS_H
#define _ISENS_H

#include "iqmath.h"


// resistances in kOhm 
#define Uref (3.3)
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
    uint16_t    m_adcOffset = 0;
    iq_t        m_realVal = 0;
    iq_t        m_RealOffsetDelta = 0;
    bool        m_inversion = false;
    
  public:
    constexpr ISens(){}
    virtual ~ISens() = 0;
    const iq_t& read()const;
    void adc_val_set(uint16_t _adcVal);
    void offset_set(iq_t _realOffset){m_RealOffsetDelta = _realOffset;}
    void inversion(bool _isInv){m_inversion = _isInv;}
    
    const iq_t& scale_get()const{return m_kD2A;}
};


inline const iq_t& ISens::read() const{
    return m_realVal;
}

#endif //_ISENS_H
