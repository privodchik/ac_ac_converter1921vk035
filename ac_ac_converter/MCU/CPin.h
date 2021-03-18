  // Date: 19.02.2021
  // Created: ID

#ifndef _CPIN_H
#define _CPIN_H

#include "IPheriphery.h"
#include "niietcm4_gpio.h"

class CPin : public IPheriphery
{
  public:
    enum class ePin : uint32_t{
        Pin_0 = GPIO_Pin_0,
        Pin_1 = GPIO_Pin_1,
        Pin_2 = GPIO_Pin_2,
        Pin_3 = GPIO_Pin_3,
        Pin_4 = GPIO_Pin_4,
        Pin_5 = GPIO_Pin_5,
        Pin_6 = GPIO_Pin_6,
        Pin_7 = GPIO_Pin_7,
        Pin_8 = GPIO_Pin_8,
        Pin_9 = GPIO_Pin_9,
        Pin_10 = GPIO_Pin_10,
        Pin_11 = GPIO_Pin_11,
        Pin_12 = GPIO_Pin_12,
        Pin_13 = GPIO_Pin_13,
        Pin_14 = GPIO_Pin_14,
        Pin_15 = GPIO_Pin_15
    };
    
    enum class ePort{
        PORT_A = 0,
        PORT_B,
        PORT_C,
        PORT_D,
        PORT_E,
        PORT_F,
        PORT_G,
        PORT_H
    };
    
  private:  
    static NT_GPIO_TypeDef* mcuPortsArray[int(ePort::PORT_H) + 1];
    
    
  public:
    enum class eAltFunc{
        ALTFUNC_1 = 0,
        ALTFUNC_2,
        ALTFUNC_3
    };
    
    enum class eDir{
        IN = 0,
        OUT
    };
    
    enum class eMode{
        IO = 0,
        ALT_FUNC
    };
    
    enum class eOutMode{
        PUSH_PULL = 0,
        OPEN_DRAIN
    };
    
    
  private:
    ePort   m_portName;
    NT_GPIO_TypeDef* m_port;
    ePin m_pin;
    
    GPIO_Init_TypeDef GPIO_InitStruct;
  
  public:
    CPin(ePort _port, ePin _pin);
    
    void port_set(ePort _port);
    NT_GPIO_TypeDef* port_get(){return m_port;}
    ePort port_name_get(){return m_portName;}
    
    void write(bool _state);
    bool read();
    
    void pin_set(ePin);
    void alt_func_set(eAltFunc);
    void direction_set(eDir);
    void mode_set(eMode);
    void out_allow(eState);
    void out_mode(eOutMode);
    void pullUp_set(eState);
    void config_set();
    
};


inline void CPin::pin_set(ePin _pinNo){
    GPIO_InitStruct.GPIO_Pin = uint32_t(_pinNo);
}

inline void CPin::alt_func_set(eAltFunc _func){
    GPIO_InitStruct.GPIO_AltFunc = static_cast<GPIO_AltFunc_TypeDef>(_func);
}

inline void CPin::direction_set(eDir _dir){
      GPIO_InitStruct.GPIO_Dir = static_cast<GPIO_Dir_TypeDef>(_dir);
}

inline void CPin::mode_set(eMode _mode){
      GPIO_InitStruct.GPIO_Mode = static_cast<GPIO_Mode_TypeDef>(_mode);
}

inline void CPin::out_allow(eState _state){
      GPIO_InitStruct.GPIO_Out = static_cast<GPIO_Out_TypeDef>(_state);
}

inline void CPin::out_mode(eOutMode _outMode){
    GPIO_InitStruct.GPIO_OutMode = static_cast<GPIO_OutMode_TypeDef>(_outMode);
}

inline void CPin::pullUp_set(eState _state){
    GPIO_InitStruct.GPIO_PullUp = static_cast<GPIO_PullUp_TypeDef>(_state);
}


#pragma inline = forced
inline void CPin::write(bool _state){
    GPIO_WriteBit(m_port, uint32_t(m_pin), _state ? Bit_SET :  Bit_CLEAR);
}

#pragma inline = forced
inline bool CPin::read(){
    return static_cast<bool>
        ( GPIO_ReadBit(m_port, static_cast<uint32_t>(m_pin)) );
}

#endif //_CPIN_H
