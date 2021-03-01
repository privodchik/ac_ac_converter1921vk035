// Date: 01.03.2021
// Creator: ID

#ifndef _CUART_H
#define _CUART_H

#include "IPheriphery.h"

class CUart : public IPheriphery{
  public:
    enum class eBaud: uint32_t{
        BAUD_9600 = 9600,
        BAUD_115200 = 115200,
        BAUD_230400 = 230400,
        BAUD_460800 = 460800,
        BAUD_921600 = 921600
    };
    
    enum class eParity: uint8_t{
        NONE = 0,
        ODD,
        EVEN
    };
    
    
    
  private:
    eBaud m_baud = eBaud::BAUD_115200;
    
  public:
    CUart(){}
    
    void baud_set(eBaud _baud){m_baud = _baud;}
    
};

#endif //_CUART_H
