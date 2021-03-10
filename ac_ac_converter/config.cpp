// Date: 04.03.2021
// Creator: ID

#include "config.h"

//uint32_t CDeviceConfig::pwmARR = SystemCoreClock/static_cast<uint32_t>(FREQ_KHZ*1000); 



// --------------- Bus Voltages ------------------------------------------------
const iq_t UBUSPN_NOM = IQ(350);
const iq_t UBUSNN_NOM =  UBUSPN_NOM;

const iq_t UBUSPN_MIN = IQ(250);
const iq_t UBUSNN_MIN =  UBUSPN_MIN;

const iq_t UBUSPN_MAX = IQ(390);
const iq_t UBUSNN_MAX =  UBUSPN_MAX;

// -----------------------------------------------------------------------------


