// Date: 2020.12.09
// User: ID


#ifndef _CCMDS_H
#define _CCMDS_H

#include <cstdint>
#include "aux_utility.h"

class CCmds{
    public:
      const int PWM_CMDS_QUANT;
    
    public:
      uint16_t start;
      uint16_t rst;
      uint16_t diag;

      uint16_t pwm[eQ5];
      uint16_t& pwm0_chA;
      uint16_t& pwm0_chB;
      uint16_t& pwm1_chA;
      uint16_t& pwm1_chB;
      uint16_t& km;
    
    public:
      CCmds();

      void reset(){
        start =
        rst =
        diag = 0;
        
        for (int i = 0; i < PWM_CMDS_QUANT; i++) pwm[i] = 0;
      }
};


#endif //_CCMDS_H

