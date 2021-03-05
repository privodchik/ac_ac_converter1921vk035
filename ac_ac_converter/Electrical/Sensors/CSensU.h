  // Date: 05.03.2021
  // Creator: ID


#ifndef _CSENSU_H
#define _CSENSU_H

#include "ISens.h"

class CSensU : public ISens
{
    public:
      // if voltage sensor has 2500:1000, do use sensTC = 2.5
      // resistors in kOhm
      constexpr CSensU(float Rsingle, 
                       float Rhi, 
                       float Rlo,
                       float Roffset,
                       float Rdat,
                       float sensTC,
                       iq_t  realOffset,
                       bool  inversion = false): ISens(){
          m_RealOffsetDelta = realOffset;   
          m_inversion = inversion;
          m_kD2A = isens_trans_coef_est(Roffset, Rsingle , Rhi, Rlo, Rdat, sensTC);
          m_adcOffset = adc_offset_est(Roffset, Rsingle , Rhi, Rlo);
      }
      
    private:
      constexpr iq_t isens_trans_coef_est( float Roffset,
                                           float Rsingle,
                                           float Rhi,
                                           float Rlo,
                                           float Rdat,
                                           float sensTC){
        #define Uref (3.3)
        #define kADC (4095.0/Uref)                                               
        
        return IQ(
                  2.0*Rdat * 
                  ( (Rsingle+Rhi) * (Roffset+Rlo) + Roffset*Rlo )/
                  ( Rsingle*Rlo*Roffset*sensTC*kADC )
                  );
        
        #undef kADC                                               
        #undef Uref
      }
};

#endif //_CSENSU_H
