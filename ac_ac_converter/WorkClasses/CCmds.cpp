// Date: 2020.12.09
// User: ID


#include "CCmds.h"

CCmds::CCmds():
	PWM_CMDS_QUANT(eQ5),
	pwmA_hi(pwm[0]),
	pwmA_lo(pwm[1]),
	pwmB_hi(pwm[2]),
	pwmB_lo(pwm[3]),
	km(pwm[4])
{
	reset();
}

