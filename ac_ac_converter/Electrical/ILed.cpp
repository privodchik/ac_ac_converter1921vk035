// Date: 2020.05.19
// User: ID

#include "ILed.h"


ILed::ILed(): m_state(false){}

ILed::ILed(const CPin& _pin):  ILed() {
    m_pin = _pin;
}

ILed::~ILed(){}

char ILed::task_blinking(PT* pt, time_t _time){
    
    PT_BEGIN(pt);
    timer_set(&m_tmr, TIME_USEC(_time));
    
    while (true){
      PT_YIELD_UNTIL(pt, timer_expired(&m_tmr));
      timer_advance(&m_tmr, m_tmr.interval);
      
      state_get() ? clear() : set();
    }
    
    PT_END(pt);
}







