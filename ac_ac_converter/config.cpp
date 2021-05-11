// Date: 04.03.2021
// Creator: ID

#include "config.h"

//uint32_t CDeviceConfig::pwmARR = SystemCoreClock/static_cast<uint32_t>(FREQ_KHZ*1000); 



// --------------- Bus Voltages ------------------------------------------------

const iq_t UBUS_NOM = IQ(460);
const iq_t UBUSPN_NOM = IQdiv2(UBUS_NOM);
const iq_t UBUSNN_NOM =  UBUSPN_NOM;

const iq_t UBUS_MIN = IQ(400);
const iq_t UBUSPN_MIN = IQdiv2(UBUS_MIN);
const iq_t UBUSNN_MIN =  UBUSPN_MIN;

const iq_t UBUS_MAX = IQ(500);
const iq_t UBUSPN_MAX = IQdiv2(UBUS_MAX);
const iq_t UBUSNN_MAX =  UBUSPN_MAX;

// -----------------------------------------------------------------------------


const iq_t IAC_NOM = IQ(60.0);

const iq_t IAC_AMP_NOM = IQmpy(IAC_NOM, IQ(1.41));
const iq_t IAC_AMP_MAX = IQmpy(IAC_AMP_NOM, IQ(1.1));



const iq_t VAC_NOM = IQdiv(IQ(127), IQ(1.41));

const iq_t VAC_AMP_NOM = IQmpy(VAC_NOM, IQ(1.41));
const iq_t VAC_AMP_MAX = IQmpy(VAC_AMP_NOM, IQ(1.3));


const iq_t CUR_TO_FUN = IQ(10.0);


