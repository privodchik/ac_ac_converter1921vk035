// Date: 2020.11.26
// User: ID

#include "CRun.h"


void CRun::critical_protect(){
	IState::critical_protect();	
}

void CRun::non_critical_protect(){
	IState::non_critical_protect();
}

void CRun::critical_operate(){
}	

void CRun::operate(){
	IState::operate();
}

void CRun::reset(){
	IState::reset();
        m_currentAngle = 0;
}
