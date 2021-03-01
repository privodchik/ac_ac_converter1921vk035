// Date: 19.02.2021
// Created: ID

#ifndef _I_PHERIPHERY
#define _I_PHERIPHERY

#include <cstdint>

class IPheriphery{
  public: 
    enum class eState : uint8_t
    {
        OFF = 0,
        ON
    };
};

#endif //_I_PHERIPHERY
