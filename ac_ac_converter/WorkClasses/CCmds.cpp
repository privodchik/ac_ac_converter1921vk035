// Date: 2020.12.09
// User: ID


#include "CCmds.h"

CCmds::CCmds():
	PWM_CMDS_QUANT(eQ5),
	pwm0_chA(pwm[0]),
	pwm0_chB(pwm[1]),
	pwm1_chA(pwm[2]),
	pwm1_chB(pwm[3]),
	km(pwm[4])
{
	reset();
}

