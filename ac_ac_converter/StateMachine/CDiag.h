// Date: 2020.11.26
// User: ID

#ifndef _CDIAG
#define _CDIAG

#include "IState.h"
#include "CIgbt.h"
#include "CKM.h"
#include "filter.h"
#include "piregulator.h"

#include "quantity_enum.h"

//#define TF_IS_FILTER
#define TF_IS_PIREG

#ifdef TF_IS_FILTER
#undef TF_IS_PIREG
#endif

#ifdef TF_IS_PIREG
#undef TF_IS_FILTER
#endif

class CDiag : public IState
{
	const int CONTROLS_QUANT;
	private:
		CIgbt m_igbtN1_hi;
		CIgbt m_igbtN1_lo;
		CIgbt m_igbtN2_hi;
		CIgbt m_igbtN2_lo;
		
		CIgbt m_igbtP1_hi;
		CIgbt m_igbtP1_lo;
		CIgbt m_igbtP2_hi;
		CIgbt m_igbtP2_lo;
	
		CKM		m_km;
	
		IControlObj* m_controls[q9];
	
	public:
		_iq m_pwm_duty; //per cent
	
	#ifdef TF_IS_FILTER
		CFilter
	#endif
	
	#ifdef TF_IS_PIREG
		CPIReg  
	#endif
		m_tf;
	
		uint16_t m_do_tf;
	
	public:
		CDiag();

		virtual void critical_protect();
		virtual void non_critical_protect();
		
		virtual void critical_operate();	
		virtual void operate();
		
	public:
		virtual void reset();

	private:
		PT pt_sw_config;
		PT_THREAD(task_sw_config(PT* pt));
	
		PT pt_do_tf;
		PT_THREAD(task_do_tf(PT* pt));
			
};

#endif //_CDIAG

