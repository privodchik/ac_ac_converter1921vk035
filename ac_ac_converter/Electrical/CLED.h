// Date: 2020.02.25
// User: ID

#ifndef _CLED_H
#define _CLED_H

#include "ILed.h"

class CLed : public ILed 
{
  public:
    CLed();
    CLed(const CPin& _pin);
    ~CLed(){}
    
};


#endif
