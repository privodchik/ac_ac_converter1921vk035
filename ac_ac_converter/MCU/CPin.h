  // Date: 19.02.2021
  // Created: ID

#ifndef _CPIN_H
#define _CPIN_H

#include "IPheriphery.h"
#include "plib035_gpio.h"

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
        PORT_B
    };
    
  private:  
    static GPIO_TypeDef* mcuPortsArray[int(ePort::PORT_B) + 1];
    
    
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
        PUSH_PULL = GPIO_OUTMODE_PIN0_PP,
        OPEN_DRAIN = GPIO_OUTMODE_PIN0_OD,
        OPEN_SOURCE = GPIO_OUTMODE_PIN0_OS
    };
    
    enum class eInMode{
        SHMITT = GPIO_INMODE_PIN0_Schmitt,
        CMOS = GPIO_INMODE_PIN0_CMOS,
        DISABLE = GPIO_INMODE_PIN0_Disable
    };
    
    enum class ePullMode{
        DISABLE = GPIO_PULLMODE_PIN0_Disable,
        PU = GPIO_PULLMODE_PIN0_PU,
        PD = GPIO_PULLMODE_PIN0_PD
    };
    
    enum class eDriveMode{
        HIGH_FAST = GPIO_DRIVEMODE_PIN0_HF,
        HIGH_SLOW = GPIO_DRIVEMODE_PIN0_HS,
        LOW_FAST = GPIO_DRIVEMODE_PIN0_LF,
        LOW_SLOW = GPIO_DRIVEMODE_PIN0_LS   
    };
    
    
  private:
    ePort   m_portName;
    GPIO_TypeDef* m_port;
    ePin m_pin;
    
    GPIO_Init_TypeDef GPIO_InitStruct;
  
  public:
    CPin(ePort _port, ePin _pin);
//    CPin(const CPin& _pin);
//    CPin(CPin&& _pin);
//    ~CPin(){}
//    
//    CPin& operator=(const CPin& _pin);
//    CPin& operator=(CPin&& _pin);
    
    void port_set(ePort _port);
    GPIO_TypeDef* port_get(){return m_port;}
    ePort port_name_get(){return m_portName;}
    
    void write(bool _state);
    bool read();
    
    void pin_set(ePin);
    void mode_set(eMode);
    void direction_set(eDir);
    void out_mode(eOutMode);
    void in_mode(eInMode);
    void pull_mode(ePullMode);
    void drive_mode(eDriveMode);
    void config_set();
    
};


#pragma inline = forced
inline void CPin::pin_set(ePin _pinNo){
    GPIO_InitStruct.Pin = uint32_t(_pinNo);
}

#pragma inline = forced
inline void CPin::direction_set(eDir _dir){
      GPIO_InitStruct.Out = static_cast<FunctionalState>(_dir);
}

#pragma inline = forced
inline void CPin::mode_set(eMode _mode){
    GPIO_InitStruct.AltFunc = (_mode == eMode::ALT_FUNC ? ENABLE : DISABLE);
}

#pragma inline = forced
inline void CPin::out_mode(eOutMode _outMode){
    GPIO_InitStruct.OutMode = static_cast<GPIO_OutMode_TypeDef>(_outMode);
}

#pragma inline = forced
inline void CPin::in_mode(eInMode _inMode){
    GPIO_InitStruct.InMode = static_cast<GPIO_InMode_TypeDef>(_inMode);
}

#pragma inline = forced
inline void CPin::pull_mode(ePullMode _pullMode){
    GPIO_InitStruct.PullMode = static_cast<GPIO_PullMode_TypeDef>(_pullMode);
}

#pragma inline = forced
inline void CPin::drive_mode(eDriveMode _driveMode){
    GPIO_InitStruct.DriveMode = static_cast<GPIO_DriveMode_TypeDef>(_driveMode);
}


#pragma inline = forced
inline void CPin::write(bool _state){
    GPIO_WriteBit(m_port, uint32_t(m_pin), _state ? SET :  CLEAR);
}

#pragma inline = forced
inline bool CPin::read(){
    return static_cast<bool>
        ( GPIO_ReadBit(m_port, static_cast<uint32_t>(m_pin)) );
}

#endif //_CPIN_H
