// Date: 01.03.2021
// Creator: ID

#ifndef _MODBUS_CONFIG_H
#define _MODBUS_CONFIG_H

#ifdef __cplusplus
extern "C"{
#endif


#include "iqmath.h"

extern uint16_t modbus1_slave_addr;   
extern iq0_t modbus1_uart_baudrate;
extern uint16_t modbus1_uart_stopbits;
extern uint16_t modbus1_uart_parity;


extern uint16_t modbus1_password;
    
void modbus1_init(void);
void modbus2_init(void);
    

#ifdef __cplusplus
}
#endif //__cplusplus

#endif

