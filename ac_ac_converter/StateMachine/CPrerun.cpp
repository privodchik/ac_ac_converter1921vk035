// Date: 2020.11.26
// User: ID

#include "CPrerun.h"
#include "app_lgm.h"
#include "m2m.h"

void CPrerun::critical_protect(){
	app.pwmN.out_disable();
	app.pwmP.out_disable();

	IState::critical_protect();
}

void CPrerun::non_critical_protect(){
	IState::non_critical_protect();
}

void CPrerun::critical_operate(){
}

void CPrerun::operate(){
	IState::operate();
	task_operating(&pt_operating);
	
}

void CPrerun::reset(){
	IState::reset();
	PT_INIT(&pt_operating);
	timer_set(&tmr_delay, TIME_SEC(1.5));
}


void CPrerun::regulators_config(){
	
	app.iReg_N.reset();
	app.iReg_P.reset();
	
	app.iReg_N.config_set();
	app.iReg_P = app.iReg_N;
	
	app.uReg_N.reset();
	app.uReg_P.reset();
	
	app.uReg_N.config_set();
	app.uReg_P = app.uReg_N;
	
	
	st_run.m_Uref.reset();
	st_run.m_Uref.Ts_set(10); 	//msec
//	st_run.m_Uref.Tf_set(st_run.FILTER_TF); // msec
	st_run.m_Uref.Tf_set(st_run.m_filter_Tf); // msec
	st_run.m_Uref.sat_set((UBUS_NOM >> 1), 0);
	st_run.m_Uref.config_set();
//	st_run.m_Uref.out_set(app.sensUdcBusPos.m_real);
	
}

char CPrerun::task_operating(PT* pt){
	
	static TIMER tmr;
	
	PT_BEGIN(pt);
	
	regulators_config();

//	timer_set(&tmr, TIME_SEC(3)); // time while AVR voltage is steadied after start command
//	PT_YIELD_UNTIL(pt, timer_expired(&tmr));
	
	PT_YIELD(pt);
//	if(app.cmds.start && timer_expired(&tmr_delay) && (app.Udc_Bus < UBUS_MIN))
//		IState::state_set(IState::RUN);
//	else if (!app.cmds.start) IState::state_set(IState::READY);
//	
	
	CErrors _errors;
	for (int i = 0; i < 5; i++){
		_errors.m_errors[i] = CErrors::eError_t(m2m_vsi2conv.errors_avr_code[i]);
	}
	
	if (  app.cmds.start || 
							( is_start_from_vsi() and 
								(_errors.is_errors_in_range(CErrors::ERROR_GRID_U, CErrors::ERROR_GRID_IGBT) or
								 _errors.is_error(CErrors::ERROR_VSI_LINK_LOSS))
							)
					)
	{
		IState::state_set(IState::RUN);
	}
//	else if (!app.cmds.start && is_stop_from_vsi())
//		IState::state_set(IState::READY);
	
	
	return PT_EXITED;
	
	PT_END(pt);
}


