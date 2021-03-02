#ifndef MODBUS_CRC16_H
#define MODBUS_CRC16_H

#ifdef __cplusplus
extern "C" {
#endif

#include "stdint_ext.h"

//-------------------------------------------------------------------
// buffer based function
uint16_t modbus_crc16(uint8_t *buffer, uint16_t buffer_length);

// byte based function
uint16_t modbus_crc16_begin(void);
uint16_t modbus_crc16_next(uint16_t crc16, uint8_t byte);

#ifdef __cplusplus
}
#endif

#endif // MODBUS_CRC16_H
