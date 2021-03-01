// Date: 2020.11.26
// User: ID

#ifndef _CRUN
#define _CRUN

#include "IState.h"
#include "filter.h"
#include "CPreRun.h"
#include "config.h"


class CRun : public IState
{
	public:
		_iq m_IrefN;
		_iq m_IrefP;
	
		uint16_t m_UyN;
		uint16_t m_UyP;
	
		_iq m_errorU_P;
		_iq m_errorU_N;
		
		CFilter m_Uref;
	
	public:
		uint16_t m_filter_Tf; 
	
	private:
		const int FILTER_TF;
	
	public:
		CRun() : IState(RUN), m_filter_Tf(TFILTER), FILTER_TF(TFILTER){}
			
		virtual void critical_protect();
		virtual void non_critical_protect();
		
		virtual void critical_operate();	
		virtual void operate();
		
	public:
		virtual void reset();		
		
	private:
		PT pt_u_ref_formed;
		PT_THREAD(task_u_ref_form(PT* pt));
	
	friend class CPrerun;
};

#endif //_CRUN

