// Date: 19.02.2021
// Created: ID

#include "CPin.h"

NT_GPIO_TypeDef* CPin::mcuPortsArray[] = {
     NT_GPIOA,
     NT_GPIOB,
     NT_GPIOC,
     NT_GPIOD,
     NT_GPIOE,
     NT_GPIOF,
     NT_GPIOG,
     NT_GPIOH
};


CPin::CPin(ePort _port, ePin _pin) : m_pin(_pin), IPheriphery(){
    GPIO_StructInit(&GPIO_InitStruct);
    port_set(_port);
    pin_set(_pin);
    
}


void CPin::port_set(ePort _port){
    m_portName = _port;
    m_port = mcuPortsArray[int(_port)];
}

void CPin::write(bool _state){
    GPIO_WriteBit(m_port, uint32_t(m_pin), _state ? Bit_SET :  Bit_CLEAR);
}

bool CPin::read(){
    return static_cast<bool>
        ( GPIO_ReadBit(m_port, static_cast<uint32_t>(m_pin)) );
}

void CPin::config_set(){
    GPIO_Init(m_port, &GPIO_InitStruct);
}






