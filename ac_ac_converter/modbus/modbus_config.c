// Date: 01.03.2021
// Creator: ID

#include "modbus_config.h"
#include "uart_hw.h"
#include "modbus_rtu.h"



uint16_t modbus1_slave_addr = 1;
iq0_t modbus1_uart_baudrate = IQ0(115200);
uint16_t modbus1_uart_stopbits = UART_STOP_1;
uint16_t modbus1_uart_parity = UART_PARITY_NONE;

uint16_t modbus1_password = 1981; // regs access


//-------------------------------------------------------------------
void modbus1_init(void)
{
    //UART_OPTIONS uart_opts = FIXED_BAUD(19200);
    //UART_OPTIONS uart_opts = FIXED_BAUD(57600);
    UART_OPTIONS uart_opts = FIXED_BAUD(115200);
    //UART_OPTIONS uart_opts = FIXED_BAUD(230400);
    //UART_OPTIONS uart_opts = FIXED_BAUD(460800);

    uart_opts.baud_rate = (uint32_t)modbus1_uart_baudrate;
    uart_opts.stop_bits = modbus1_uart_stopbits;
    uart_opts.parity = modbus1_uart_parity;

    //modbus_rtu_init(1, modbus1_slave_addr, &uart_opts);
    modbus_rtu_init(2, modbus1_slave_addr, &uart_opts);
    //modbus_rtu_init(3, modbus1_slave_addr, &uart_opts);
}

//-------------------------------------------------------------------
void modbus2_init(void)
{
//    //UART_OPTIONS uart_opts = FIXED_BAUD(19200);
//    //UART_OPTIONS uart_opts = FIXED_BAUD(57600);
//    UART_OPTIONS uart_opts = FIXED_BAUD(115200);
//    //UART_OPTIONS uart_opts = FIXED_BAUD(230400);
//    //UART_OPTIONS uart_opts = FIXED_BAUD(460800);
//
//    uart_opts.baud_rate = (uint32_t)modbus1_uart_baudrate;
//    uart_opts.stop_bits = modbus1_uart_stopbits;
//    uart_opts.parity = modbus1_uart_parity;
//
//    modbus2_rtu_init(1, modbus1_slave_addr, &uart_opts);
//    //modbus2_rtu_init(2, modbus1_slave_addr, &uart_opts);
//    //modbus2_rtu_init(3, modbus1_slave_addr, &uart_opts);
}