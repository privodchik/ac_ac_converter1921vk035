// Date: 2020.05.19
// User: ID

#ifndef _ILED_H
#define _ILED_H

#include <cstdint>
#include "IPheriphery.h"
#include "CPin.h"

#include "pt.h"
#include "timer.h"

class ILed
{
    protected:
      
      bool m_state;
      CPin m_pin{CPin::ePort::PORT_A, CPin::ePin::Pin_0};
      
    
    private:
      ILed(bool _state, CPin& _pin) : m_state(_state), m_pin(_pin)
      {}

    public:
      explicit ILed();
      explicit ILed(const CPin& _pin);
      virtual ~ILed() = 0;
      
      #pragma inline = forced
      void define_pin(const CPin& _pin){m_pin = _pin;}
      
      #pragma inline = forced
      void set(){m_pin.write(true); m_state = true;}
      
      #pragma inline = forced
      void clear(){m_pin.write(false); m_state = false;}
      
      #pragma inline = forced
      bool state_get(){return m_state;}
      
    
    private:
      PT pt_blink;
      PT_THREAD(task_blinking(PT* pt, time_t _time));
      TIMER m_tmr;
      
    public:
      // the function must be executed in background thread 
      void blinking_task(int _time){
          task_blinking(&pt_blink, _time);
      }
      
      
      
};

//#pragma inline = forced
//inline void ILed::define_pin(const CPin& _pin){m_pin = _pin;}

#endif

