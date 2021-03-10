// Date: 2020.11.26
// User: ID

#ifndef _PROP_GULATOR_H
#define _PROP_GULATOR_H

#include "itrans_func.h"

class CPReg : public ITransFunc
{
	public:
    _iq m_K;
	
	public:
		CPReg() : ITransFunc(), m_K(0){}
		void K_set(_iq _K){m_K = _K;}
		/*virtual*/ _iq out_est(_iq _xk); 
};               


#endif //_PIREGULATOR_H

