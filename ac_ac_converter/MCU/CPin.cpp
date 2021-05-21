// Date: 19.02.2021
// Created: ID

#include "CPin.h"
#include <utility>

GPIO_TypeDef* CPin::mcuPortsArray[] = {
     GPIOA,
     GPIOB
};


CPin::CPin(ePort _port, ePin _pin) : m_pin(_pin), IPheriphery(){
    GPIO_StructInit(&GPIO_InitStruct);
    port_set(_port);
    pin_set(_pin);
    
}

//CPin::CPin(const CPin& _pin){
//    m_portName = _pin.m_portName;
//    m_port = _pin.m_portName;
//    m_pin = _pin.m_pin;
//    GPIO_InitStruct = _pin.GPIO_InitStruct;
//}
//
//CPin::CPin(CPin&& _pin){
//    m_portName = std::move(_pin.m_portName);
//    m_port = std::move(_pin.m_portName);
//    m_pin = std::move(_pin.m_pin);
//    GPIO_InitStruct = std::move(_pin.GPIO_InitStruct);
//}

void CPin::port_set(ePort _port){
    m_portName = _port;
    m_port = mcuPortsArray[int(_port)];
}

void CPin::config_set(){
    GPIO_Init(m_port, &GPIO_InitStruct);
}






