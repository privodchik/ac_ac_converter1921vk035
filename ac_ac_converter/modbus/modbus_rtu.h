#ifndef MODBUS_RTU_H
#define MODBUS_RTU_H


#ifdef __cplusplus
extern "C" {
#endif

#include "stdint_ext.h"
#include "uart_hw.h"
#include "config.h"

//#define MODBUS_RTU_LOCAL_ADDRESS    0xFF
#undef MODBUS_RTU_LOCAL_ADDRESS

// Note: modbus RTU will call this function when receiving packet
//   int16 modbus_process_pdu(uint8_t *pdu, Uint16 *p_len)
// This function is defined in modbus_slave (or modbus_master [not done])

//-------------------------------------------------------------------
extern uint16_t modbus_rx_cnt;
extern uint16_t modbus_rx_good_cnt;
extern uint16_t modbus_rx_local_cnt;
extern uint16_t modbus_rx_short_cnt; // too short
extern uint16_t modbus_rx_other_addr_cnt;
extern uint16_t modbus_rx_broadcast_cnt;
extern uint16_t modbus_rx_badcrc_cnt;
extern uint16_t modbus_rx_broken_cnt;
extern uint16_t modbus_rx_lost_cnt;
extern uint16_t modbus_tx_cnt;

extern uint16_t _modbus_device_address;

//-------------------------------------------------------------------
void modbus_rtu_init(int uart_number, uint16_t device_address, UART_OPTIONS *uart_opts);
void modbus_rtu_set_address(uint16_t device_address);
void modbus_rtu_task(void);
int modbus_rtu_send_pdu(uint16_t device_address, uint8_t *pdu, uint16_t len);

#ifdef __cplusplus
}
#endif

#endif // MODBUS_RTU_H
