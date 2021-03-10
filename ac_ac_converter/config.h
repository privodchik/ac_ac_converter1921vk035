#ifndef CONFIG_H
#define CONFIG_H

//#include "IQmathLib.h"

#include <stdint.h>

#include "iqmath.h"



//-------------------------------------------------------------------
#define NAME_STR        "NPT-AC_AC-CONVERTOR"

//-------------------------------------------------------------------
#define POWER_STR       "10kW"

#define FREQ_KHZ 40.0

// --------------- Bus Voltages ------------------------------------------------
extern const iq_t UBUSPN_NOM;
extern const iq_t UBUSNN_NOM;

extern const iq_t UBUSPN_MIN;
extern const iq_t UBUSNN_MIN;

extern const iq_t UBUSPN_MAX;
extern const iq_t UBUSNN_MAX;

// -----------------------------------------------------------------------------





//struct CDeviceConfig{
//    static uint32_t pwmARR;
//    
//    static uint32_t pwm_arr_update(){
//        return pwmARR = SystemCoreClock/static_cast<uint32_t>(FREQ_KHZ*1000);
//    }
//    
//    static uint32_t pwm_arr_get(){
//        return pwm_arr_update();
//    }
//    
//};


#endif //CONFIG_H
