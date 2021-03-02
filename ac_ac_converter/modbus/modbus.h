/*
 * Copyright © 2001-2013 Stéphane Raimbault <stephane.raimbault@gmail.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

#ifndef MODBUS_H
#define MODBUS_H

#ifndef FALSE
#define FALSE 0
#endif

#ifndef TRUE
#define TRUE 1
#endif

#ifndef OFF
#define OFF 0
#endif

#ifndef ON
#define ON 1
#endif

/* Modbus function codes */
#define MODBUS_FC_READ_COILS                0x01
#define MODBUS_FC_READ_DISCRETE_INPUTS      0x02
#define MODBUS_FC_READ_HOLDING_REGISTERS    0x03
#define MODBUS_FC_READ_INPUT_REGISTERS      0x04
#define MODBUS_FC_WRITE_SINGLE_COIL         0x05
#define MODBUS_FC_WRITE_SINGLE_REGISTER     0x06
#define MODBUS_FC_READ_EXCEPTION_STATUS     0x07
#define MODBUS_FC_WRITE_MULTIPLE_COILS      0x0F
#define MODBUS_FC_WRITE_MULTIPLE_REGISTERS  0x10
#define MODBUS_FC_REPORT_SLAVE_ID           0x11
#define MODBUS_FC_MASK_WRITE_REGISTER       0x16
#define MODBUS_FC_WRITE_AND_READ_REGISTERS  0x17
#define MODBUS_FC_READ_FIFO_QUEUE           0x18

/* User defined function codes 65-72 */
#define MODBUS_FC_USER_ECHO                 67
#define MODBUS_FC_USER_LOADER               68
#define MODBUS_FC_USER_EEPROM               69
#define MODBUS_FC_USER_REG_META             70
#define MODBUS_FC_USER_SCOPE                71

/* User defined function codes 100-110 */


#define MODBUS_BROADCAST_ADDRESS    0

/* Modbus_Application_Protocol_V1_1b.pdf (chapter 6 section 3 page 15)
 * Quantity of Registers to read (2 bytes): 1 to 125 (0x7D)
 * (chapter 6 section 12 page 31)
 * Quantity of Registers to write (2 bytes) 1 to 123 (0x7B)
 * (chapter 6 section 17 page 38)
 * Quantity of Registers to write in R/W registers (2 bytes) 1 to 121 (0x79)
 */
#define MODBUS_MAX_READ_REGISTERS          125
#define MODBUS_MAX_WRITE_REGISTERS         123
#define MODBUS_MAX_WR_WRITE_REGISTERS      121
#define MODBUS_MAX_WR_READ_REGISTERS       125

/* The size of the MODBUS PDU is limited by the size constraint inherited from
 * the first MODBUS implementation on Serial Line network (max. RS485 ADU = 256
 * bytes). Therefore, MODBUS PDU for serial line communication = 256 - Server
 * address (1 byte) - CRC (2 bytes) = 253 bytes.
 *
 * Consequently:
 * - RS232 / RS485 ADU = 253 bytes + Server address (1 byte) + CRC (2 bytes) =
 *   256 bytes.
 * - TCP MODBUS ADU = 253 bytes + MBAP (7 bytes) = 260 bytes.
 */
#define MODBUS_MAX_PDU_LENGTH              253

/* Protocol exceptions */
enum {
    MODBUS_EXCEPTION_ILLEGAL_FUNCTION = 0x01,
    MODBUS_EXCEPTION_ILLEGAL_DATA_ADDRESS,
    MODBUS_EXCEPTION_ILLEGAL_DATA_VALUE,
    MODBUS_EXCEPTION_SLAVE_OR_SERVER_FAILURE,
    MODBUS_EXCEPTION_ACKNOWLEDGE,
    MODBUS_EXCEPTION_SLAVE_OR_SERVER_BUSY,
    MODBUS_EXCEPTION_NEGATIVE_ACKNOWLEDGE,
    MODBUS_EXCEPTION_MEMORY_PARITY,
    MODBUS_EXCEPTION_NOT_DEFINED,
    MODBUS_EXCEPTION_GATEWAY_PATH,
    MODBUS_EXCEPTION_GATEWAY_TARGET,
    MODBUS_EXCEPTION_MAX
};

/**
 * UTILS FUNCTIONS
 **/

#define MODBUS_GET_HIGH_BYTE(data) (((data) >> 8) & 0xFF)

#define MODBUS_GET_LOW_BYTE(data) ((data) & 0xFF)

#define MODBUS_GET_INT32_FROM_INT16(tab_int16, index) \
            ((tab_int16[(index)] << 16) + tab_int16[(index) + 1])

#define MODBUS_GET_INT16_FROM_INT8(tab_int8, index) \
            ((tab_int8[(index)] << 8) + tab_int8[(index) + 1])

#define MODBUS_GET_INT32_FROM_INT8(tab_int8, index) \
            (((uint32_t)tab_int8[(index)]<<24) + \
            ((uint32_t)tab_int8[(index)+1]<<16) + \
            ((uint32_t)tab_int8[(index)+2]<<8) + \
            (uint32_t)tab_int8[(index)+3])

#define MODBUS_SET_INT16_TO_INT8(tab_int8, index, value) \
    do { \
        tab_int8[(index)] = ((value) >> 8) & 0xFF;  \
        tab_int8[(index)+1] = (value) & 0xFF; \
    } while (0)
    
#define MODBUS_SET_INT32_TO_INT8(tab_int8, index, value) \
    do { \
        tab_int8[(index)]   = ((value) >> 24) & 0xFF;  \
        tab_int8[(index)+1] = ((value) >> 16) & 0xFF;  \
        tab_int8[(index)+2] = ((value) >> 8) & 0xFF;  \
        tab_int8[(index)+3] = (value) & 0xFF; \
    } while (0)

// note: float will be in big endian (MSB first)
// however TI C2000 and Intel x86 are little endian (LSB first)
#define MODBUS_SET_FLOAT32_TO_INT8(tab_int8, index, fvalue) \
            MODBUS_SET_INT32_TO_INT8(tab_int8, index, *((uint32_t*)&fvalue))

    
#endif  /* MODBUS_H */
