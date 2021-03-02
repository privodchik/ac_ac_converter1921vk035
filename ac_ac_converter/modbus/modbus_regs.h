#ifndef MODBUS_REGS_H
#define MODBUS_REGS_H

#ifdef __cplusplus
extern "C" {
#endif


#include "stdint_ext.h"
#include "iqmath.h"

//-------------------------------------------------------------------
#define LOBYTE(word) ((word)&0xFF)
#define HIBYTE(word) (((word)>>8)&0xFF)
#define MAKEWORD(low, high) (((low)&0xFF)|(((high)&0xFF)<<8))

#define SET_MASK(byte,mask) byte |= (mask)
#define CLR_MASK(byte,mask) byte &= (~(mask))
#define TEST_MASK(byte,mask) (((byte) & (mask)) != 0)

#define ADDR_(value)   ((void*)(&value))

#ifndef countof
    #define countof(x)  (sizeof(x)/sizeof(x[0]))
#endif

#ifndef NULL
    #define NULL 0
#endif

//-------------------------------------------------------------------
#define SRAM_FLAG           1
#define PROM_FLAG           2
#define ENGINEER_FLAG       4
#define FACTORY_FLAG        8

//-------------------------------------------------------------------
#define SRAM_REG            (SRAM_FLAG)
#define ERAM_REG            (SRAM_FLAG|ENGINEER_FLAG)
#define FRAM_REG            (SRAM_FLAG|FACTORY_FLAG)

#define PROM_REG            (SRAM_FLAG|PROM_FLAG)
#define EROM_REG            (SRAM_FLAG|PROM_FLAG|ENGINEER_FLAG)
#define FROM_REG            (SRAM_FLAG|PROM_FLAG|FACTORY_FLAG)

//-------------------------------------------------------------------
#define READ_NO             0
#define READ_UINT16         1
#define READ_INT16          2
#define READ_FLOATIQ        3
#define READ_RAW32LO        4
#define READ_RAW32HI        5

#define WRITE_LIM           0x0080
#define WRITE_MASK          0x007F // to get type without lim

#define WRITE_NO            0
#define WRITE_UINT16        1
#define WRITE_INT16         2
#define WRITE_FLOATIQ       3
#define WRITE_RAW32LO       4
#define WRITE_RAW32HI       5
#define WRITE_UINT16_LIM    (WRITE_UINT16 | WRITE_LIM)
#define WRITE_INT16_LIM     (WRITE_INT16 | WRITE_LIM)
#define WRITE_FLOATIQ_LIM   (WRITE_FLOATIQ | WRITE_LIM)

// read / write via functions (side effects support)
//-------------------------------------------------------------------
typedef void(MODBUS_READ_U16)(uint16_t *value);
typedef void(MODBUS_READ_I16)(int16_t *value);
typedef void(MODBUS_READ_FIQ)(iq_t *value);
typedef void(MODBUS_WRITE_U16)(uint16_t *value);
typedef void(MODBUS_WRITE_I16)(int16_t *value);
typedef void(MODBUS_WRITE_FIQ)(iq_t *value);

//-------------------------------------------------------------------
typedef struct _MODBUS_REG
{
    uint16_t type; // SRAM, etc
    const char *str; //string with "name" or "key=value;" pairs

    // register read config
    struct
    {
        uint16_t type;
        union
        {
            void * const raw;
            uint16_t * const u16;
            int16_t * const i16;
            iq_t * const fiq;
        } ptr;
        union
        {
            void * const raw; // to avoid compiler warning
            MODBUS_READ_U16 * const u16_call;
            MODBUS_READ_I16 * const i16_call;
            MODBUS_READ_FIQ * const fiq_call;
        } fptr;
        struct
        {
        #if IQMATH_FLOAT32
            iq_t scale;
        #endif
        #if IQMATH_INT32
            int8_t i32q;
            int8_t i16q;
        #endif
        } fiq;
    } read;

    // register write config
    struct
    {
        uint16_t type;
        union 
        {
            void * const raw;
            uint16_t * const u16;
            int16_t * const i16;
            iq_t * const fiq;
        } ptr;
        union
        {
            void * const raw; // to avoid compiler warning
            MODBUS_WRITE_U16 * const u16_call;
            MODBUS_WRITE_I16 * const i16_call;
            MODBUS_WRITE_FIQ * const fiq_call;
        } fptr;
        struct
        {
            uint16_t min;
            uint16_t max;
        } u16;
        struct
        {
            int16_t min;
            int16_t max;
        } i16;
        struct
        {
        #if IQMATH_FLOAT32
            iq_t scale;
        #endif
        #if IQMATH_INT32
            int8_t i32q;
            int8_t i16q;
        #endif            
            iq_t min;
            iq_t max;
        } fiq;
    } write;
    
} MODBUS_REG;

//-------------------------------------------------------------------
#define ModbusReg(type, definition, str) {type, str, definition}

// definition may be:

#define RESERVED_    \
            {READ_NO, NULL, NULL}, \
            {WRITE_NO, NULL, NULL}

// standard read-write
#define UINT16(x) \
            {READ_UINT16, (uint16_t*)ADDR_(x), NULL}, \
            {WRITE_UINT16, (uint16_t*)ADDR_(x), NULL}

#define INT16(x) \
            {READ_INT16, (int16_t*)ADDR_(x), NULL}, \
            {WRITE_INT16, (int16_t*)ADDR_(x), NULL}

#if IQMATH_FLOAT32
    #define FLOATIQ(x, i32q, i16q) \
                {READ_FLOATIQ, (iq_t*)ADDR_(x), NULL, {IQlsh_signed(1, i16q)} }, \
                {WRITE_FLOATIQ, (iq_t*)ADDR_(x), NULL, {0,0}, {0,0}, {IQrsh_signed(1, i16q)} }
    #define FLOAT32(x, scale) \
                {READ_FLOATIQ, (float*)ADDR_(x), NULL, {(float)(scale)} }, \
                {WRITE_FLOATIQ, (float*)ADDR_(x), NULL, {0,0}, {0,0}, {(1.0/(float)(scale))} }
#endif
#if IQMATH_INT32
    #define FLOATIQ(x, i32q, i16q) \
                {READ_FLOATIQ, (iq_t*)ADDR_(x), NULL, {i32q, i16q} }, \
                {WRITE_FLOATIQ, (iq_t*)ADDR_(x), NULL, {0,0}, {0,0}, {i32q, i16q} }
#endif

#define RAW32LO(x) \
            {READ_RAW32LO, ADDR_(x), NULL}, \
            {WRITE_RAW32LO, ADDR_(x), NULL}

#define RAW32HI(x) \
            {READ_RAW32HI, ADDR_(x), NULL}, \
            {WRITE_RAW32HI, ADDR_(x), NULL}

// read-write with function callback
#define UINT16_CB(x, read_cb, write_cb) \
            {READ_UINT16, (uint16_t*)ADDR_(x), read_cb}, \
            {WRITE_UINT16, (uint16_t*)ADDR_(x), write_cb}

#define INT16_CB(x, read_cb, write_cb) \
            {READ_INT16, (int16_t*)ADDR_(x), read_cb}, \
            {WRITE_INT16, (int16_t*)ADDR_(x), write_cb}

#if IQMATH_FLOAT32
    #define FLOATIQ_CB(x, i32q, i16q, read_cb, write_cb) \
                {READ_FLOATIQ, (iq_t*)ADDR_(x), read_cb, {IQlsh_signed(1, i16q)} }, \
                {WRITE_FLOATIQ, (iq_t*)ADDR_(x), write_cb, {0,0}, {0,0}, {IQrsh_signed(1, i16q)} }
    #define FLOAT32_CB(x, scale, read_cb, write_cb) \
                {READ_FLOATIQ, (float*)ADDR_(x), read_cb, {(float)(scale)} }, \
                {WRITE_FLOATIQ, (float*)ADDR_(x), write_cb, {0,0}, {0,0}, {(1.0/(float)(scale))} }
#endif
#if IQMATH_INT32
    #define FLOATIQ_CB(x, i32q, i16q, read_cb, write_cb) \
                {READ_FLOATIQ, (iq_t*)ADDR_(x), read_cb, {i32q, i16q} }, \
                {WRITE_FLOATIQ, (iq_t*)ADDR_(x), write_cb, {0,0}, {0,0}, {i32q, i16q} }
#endif

// standard read, write with min...max limit
#define UINT16_RANGE(x, xmin, xmax) \
            {READ_UINT16, (uint16_t*)ADDR_(x), NULL}, \
            {WRITE_UINT16_LIM, (uint16_t*)ADDR_(x), NULL, {(xmin),(xmax)} }

#define INT16_RANGE(x, xmin, xmax) \
            {READ_INT16, (int16_t*)ADDR_(x), NULL}, \
            {WRITE_INT16_LIM, (int16_t*)ADDR_(x), NULL, {0,0}, {(xmin),(xmax)} }

#if IQMATH_FLOAT32
    #define FLOATIQ_RANGE(x, i32q, i16q, xmin, xmax) \
                {READ_FLOATIQ, (iq_t*)ADDR_(x), NULL, {IQlsh_signed(1,i16q)} }, \
                {WRITE_FLOATIQ_LIM, (iq_t*)ADDR_(x), NULL, {0,0}, {0,0}, {IQrsh_signed(1,i16q),xmin,xmax} }
    #define FLOAT32_RANGE(x, scale, xmin, xmax) \
                {READ_FLOATIQ, (float*)ADDR_(x), NULL, {(float)(scale)} }, \
                {WRITE_FLOATIQ_LIM, (float*)ADDR_(x), NULL, {0,0}, {0,0}, {(1.0/(float)(scale)),(xmin),(xmax)} }
#endif
#if IQMATH_INT32
    #define FLOATIQ_RANGE(x, i32q, i16q, xmin, xmax) \
                {READ_FLOATIQ, (iq_t*)ADDR_(x), NULL, {i32q, i16q} }, \
                {WRITE_FLOATIQ_LIM, (iq_t*)ADDR_(x), NULL, {0,0}, {0,0}, {i32q,i16q,xmin,xmax} }
#endif

// read with callback, write with min...max limit and callback
#define UINT16_RANGE_CB(x, xmin, xmax, read_cb, write_cb) \
            {READ_UINT16, (uint16_t*)ADDR_(x), read_cb}, \
            {WRITE_UINT16_LIM, (uint16_t*)ADDR_(x), write_cb, {(xmin),(xmax)} }

#define INT16_RANGE_CB(x, xmin, xmax, read_cb, write_cb) \
            {READ_INT16, (int16_t*)ADDR_(x), read_cb}, \
            {WRITE_INT16_LIM, (int16_t*)ADDR_(x), write_cb, {0,0}, {xmin,xmax} }

#if IQMATH_FLOAT32
    #define FLOATIQ_RANGE_CB(x, i32q, i16q, xmin, xmax, read_cb, write_cb) \
                {READ_FLOATIQ, (iq_t*)ADDR_(x), read_cb, {IQlsh_signed(1, i16q)} }, \
                {WRITE_FLOATIQ_LIM, (iq_t*)ADDR_(x), write_cb, {0,0}, {0,0}, {IQrsh_signed(1,i16q),xmin,xmax} }
    #define FLOAT32_RANGE_CB(x, scale, xmin, xmax, read_cb, write_cb) \
                {READ_FLOATIQ, (float*)ADDR_(x), read_cb, {(float)(scale)} }, \
                {WRITE_FLOATIQ_LIM, (float*)ADDR_(x), write_cb, {0,0}, {0,0}, {(1.0/(float)(scale)),(xmin),(xmax)} }
#endif
#if IQMATH_INT32
    #define FLOATIQ_RANGE_CB(x, i32q, i16q, xmin, xmax, read_cb, write_cb) \
                {READ_FLOATIQ, (iq_t*)ADDR_(x), read_cb, {i32q,i16q} }, \
                {WRITE_FLOATIQ_LIM, (iq_t*)ADDR_(x), write_cb, {0,0}, {0,0}, {i32q,i16q,xmin,xmax} }
#endif

// read-only version                      
#define UINT16_RO(x) \
            {READ_UINT16, (uint16_t*)ADDR_(x), NULL}, \
            {WRITE_NO, NULL, NULL}

#define INT16_RO(x) \
            {READ_INT16, (int16_t*)ADDR_(x), NULL}, \
            {WRITE_NO, NULL, NULL}

#if IQMATH_FLOAT32
    #define FLOATIQ_RO(x, i32q, i16q) \
                {READ_FLOATIQ, (iq_t*)ADDR_(x), NULL, {IQlsh_signed(1, i16q)} }, \
                {WRITE_NO, NULL, NULL}
    #define FLOAT32_RO(x, scale) \
                {READ_FLOATIQ, (float*)ADDR_(x), NULL, {(float)(scale)} }, \
                {WRITE_NO, NULL, NULL}
#endif
#if IQMATH_INT32
    #define FLOATIQ_RO(x, i32q, i16q) \
                {READ_FLOATIQ, (iq_t*)ADDR_(x), NULL, {i32q, i16q} }, \
                {WRITE_NO, NULL, NULL}
#endif

#define RAW32LO_RO(x) \
            {READ_RAW32LO, ADDR_(x), NULL}, \
            {WRITE_NO, NULL, NULL}

#define RAW32HI_RO(x) \
            {READ_RAW32HI, ADDR_(x), NULL}, \
            {WRITE_NO, NULL, NULL}

// read-only with read callback
#define UINT16_RO_CB(x, read_cb) \
            {READ_UINT16, (uint16_t*)ADDR_(x), read_cb}, \
            {WRITE_NO, NULL, NULL}

#define INT16_RO_CB(x, read_cb) \
            {READ_INT16, (int16_t*)ADDR_(x), read_cb}, \
            {WRITE_NO, NULL, NULL}

#if IQMATH_FLOAT32
    #define FLOATIQ_RO_CB(x, i32q, i16q, read_cb) \
                {READ_FLOATIQ, (iq_t*)ADDR_(x), read_cb, {IQlsh_signed(1, i16q)} }, \
                {WRITE_NO, NULL, NULL}
    #define FLOAT32_RO_CB(x, scale, read_cb) \
                {READ_FLOATIQ, (float*)ADDR_(x), read_cb, {(float)(scale)} }, \
                {WRITE_NO, NULL, NULL}
#endif
#if IQMATH_INT32
    #define FLOATIQ_RO_CB(x, i32q, i16q, read_cb) \
                {READ_FLOATIQ, (iq_t*)ADDR_(x), read_cb, {i32q, i16q} }, \
                {WRITE_NO, NULL, NULL}
#endif

// read-only function based without variable
#define UINT16_RO_FUNC(read_cb) \
            {READ_UINT16, NULL, read_cb}, \
            {WRITE_NO, NULL, NULL}

#define INT16_RO_FUNC(read_cb) \
            {READ_INT16, NULL, read_cb}, \
            {WRITE_NO, NULL, NULL}

#if IQMATH_FLOAT32
    #define FLOATIQ_RO_FUNC(read_cb, i32q, i16q) \
                {READ_FLOATIQ, NULL, read_cb, {IQlsh_signed(1, i16q)} }, \
                {WRITE_NO, NULL, NULL}
    #define FLOAT32_RO_FUNC(read_cb, scale) \
                {READ_FLOATIQ, NULL, read_cb, {(float)(scale)} }, \
                {WRITE_NO, NULL, NULL}
#endif
#if IQMATH_INT32
    #define FLOATIQ_RO_FUNC(read_cb, i32q, i16q) \
                {READ_FLOATIQ, NULL, read_cb, {i32q, i16q} }, \
                {WRITE_NO, NULL, NULL}
#endif

// read-write function based without variable
#define UINT16_FUNC(read_cb, write_cb) \
            {READ_UINT16, NULL, read_cb}, \
            {WRITE_UINT16, NULL, write_cb}

#define INT16_FUNC(read_cb, write_cb) \
            {READ_INT16, NULL, read_cb}, \
            {WRITE_INT16, NULL, write_cb}

#if IQMATH_FLOAT32
    #define FLOATIQ_FUNC(read_cb, write_cb, i32q, i16q) \
                {READ_FLOATIQ, NULL, read_cb, {IQlsh_signed(1, i16q)} }, \
                {WRITE_FLOATIQ, NULL, write_cb, {0,0}, {0,0}, {IQrsh_signed(1, i16q)} }
    #define FLOAT32_FUNC(read_cb, write_cb, scale) \
                {READ_FLOATIQ, NULL, read_cb, {(float)(scale)} }, \
                {WRITE_FLOATIQ, NULL, write_cb, {0,0}, {0,0}, {(1.0/(float)(scale))} }
#endif
#if IQMATH_INT32
    #define FLOATIQ_FUNC(read_cb, write_cb, i32q, i16q) \
                {READ_FLOATIQ, NULL, read_cb, {i32q, i16q} }, \
                {WRITE_FLOATIQ, NULL, write_cb, {0,0}, {0,0}, {i32q, i16q} }
#endif

// functions for modbus_slave
//-------------------------------------------------------------------
uint16_t modbus_read_reg(uint16_t reg_addr);
int modbus_write_reg(uint16_t reg_addr, uint16_t x); // returns status

// registry tables for modbus_slave
//-------------------------------------------------------------------
extern const MODBUS_REG * modbus_holding_regs; // see modbus_config.c
extern uint16_t modbus_holding_regs_count;

extern const char modbus_slave_id[];
extern uint16_t modbus_slave_id_len;

// regs access control
#define MODBUS_REGS_MODE_USER       0
#define MODBUS_REGS_MODE_ENGINEER   1
#define MODBUS_REGS_MODE_FACTORY    2

extern uint16_t modbus_regs_mode;

//extern uint16_t modbus_regs_current_address;

// user may change mode by entering the correct password
extern uint16_t modbus_regs_enter_password(uint16_t passwd);


#ifdef __cplusplus
}
#endif

#endif // MODBUS_REGS_H

