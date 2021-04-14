  // Date: 05.03.2021
  // Creator: ID


#ifndef _CSENSI_H
#define _CSENSI_H

#include "ISens.h"

class CSensI : public ISens
{
    public:
      
      // if current sensor has 1:2000, do use sensTC = 2.0
      // resistors in kOhm
      constexpr CSensI(float Rsingle, 
                       float Rhi, 
                       float Rlo,
                       float Roffset,
                       float sensTC,
                       iq_t  realOffset,
                       bool  inversion = false): ISens(){
          m_RealOffsetDelta = realOffset;
          m_inversion = inversion;
          m_kD2A = isens_trans_coef_est(Roffset, Rsingle , Rhi, Rlo, sensTC);
          m_adcOffset = adc_offset_est(Roffset, Rsingle , Rhi, Rlo);
      }
      
    private:
      
      #define Uref (1.4)
      #define kADC (4095.0/Uref)                                               
      
      constexpr iq_t isens_trans_coef_est( float Roffset,
                                           float Rsingle,
                                           float Rhi,
                                           float Rlo,
                                           float sensTC){
        return IQ(
                  sensTC/kADC * 
                  ((Rsingle+Rhi) * (Roffset+Rlo) + Roffset*Rlo)/
                  (Rsingle*Roffset*Rlo)
                  );
      }
      
      #undef kADC                                               
      #undef Uref
};

#endif //_CSENSI_H
