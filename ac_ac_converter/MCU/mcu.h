// Date: 19.02.2021
// Creator: ID

#ifndef _MCU_H
#define _MCU_H

#include <cstdint>

class CMCU{
  public:
    enum class eSCR: uint8_t{
        CPE_pad = 0,
        POR,
        XI_OSC,
        PLL,
        PLLDIV,
        USB,
        INPUT_A0,
        INPUT_A8_OR_B3
    };
    
    enum class ePLL_REFSRC: uint8_t{
        XI_OSC = 0,
        INPUT_A0,
        USB
    };
    
  private:
    static uint32_t system_clock;
    
  public:
    explicit CMCU(uint32_t _system_clock){
        system_clock = _system_clock;
    }
    static void init();
    
    
  public:
    static uint32_t nowTimeMs; 
  private:
    static void systick_config();
};


#endif

