// Date: 2020.11.26
// User: ID

#include "prop_reg.h"

_iq CPReg::out_est(_iq _xk){
	m_yk = _IQmpy(_xk, m_K);
	return out_limit();
}

