// Date: 24.02.2021
// Created: ID

#ifndef _CSYSTICK_H
#define _CSYSTICK_H

#include <ctime>
#include "IPheriphery.h"

class CSysTick : IPheriphery{
    
  public:
    static time_t sysTickTime_uSec;
    
};



#endif //_CSYSTICK_H
