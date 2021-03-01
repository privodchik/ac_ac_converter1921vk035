// Date: 2020.11.26
// User: ID

#ifndef _ISTATE_H
#define _ISTATE_H

#include "IQmathLib.h"
#include <cstdint>
#include "pt.h"

class IState
{
	public:
		enum eState{
				INIT = 0,
				CHARGE,
				READY,
				PRERUN,
				RUN,
				FAULT,
				DIAG
			};
	
	protected:
		const eState m_state;
		static IState* m_ptr_current_state;
	
	public:
		static eState m_current_state;
	
	public:
		IState(eState _state) : m_state(_state){}
		virtual ~ IState() = 0;
			
		virtual void critical_protect();
		virtual void non_critical_protect();
		
		virtual void critical_operate();	
		virtual void operate();
		
		static void state_set(eState _state);
		static IState* state_ptr_get() {return m_ptr_current_state;}
		eState state_no_get(){return m_state;}
			
	public:
		virtual void reset();
	
	protected:
		static PT pt_link_error;
		static PT_THREAD(task_link_error(PT* pt));
	
	
};


#endif //_ISTATE_H

