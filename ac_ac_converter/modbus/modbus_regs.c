#include "modbus_regs.h"
//#include "eeprom.h"
#include "config.h"

#ifndef limit
    #define limit(x, min, max) (((x)<(min))?(min):(((x)>(max))?(max):(x)))
#endif

//-------------------------------------------------------------------
//uint16_t modbus_regs_mode = MODBUS_REGS_MODE_USER; // for operation
uint16_t modbus_regs_mode = MODBUS_REGS_MODE_ENGINEER; // for production shipment
//uint16_t modbus_regs_mode = MODBUS_REGS_MODE_FACTORY; // for development and testing

//-------------------------------------------------------------------
//uint16_t modbus_regs_current_address = 0;

//-------------------------------------------------------------------
#if IQMATH_INT32

static int32_t ssat_var_min[32] = {
-1, -2, -4, -8, -16, -32, -64, -128, -256, -512,
-1024, -2048, -4096, -8192, -16384, -32768, -65536, -131072, -262144, -524288,
-1048576, -2097152, -4194304, -8388608, -16777216, -33554432, -67108864, -134217728, -268435456, -536870912,
-1073741824, -2147483648 };

static int32_t ssat_var_max[32] = {
0, 1, 3, 7, 15, 31, 63, 127, 255, 511,
1023, 2047, 4095, 8191, 16383, 32767, 65535, 131071, 262143, 524287,
1048575, 2097151, 4194303, 8388607, 16777215, 33554431, 67108863, 134217727, 268435455, 536870911,
1073741823, 2147483647 };

//-------------------------------------------------------------------
static int32_t ssat_var(int32_t x, int8_t bit)
{
    int32_t upper, lower;
    bit -= 1;
    if(bit <= 0) return 0;
    if(bit >= 32) return x;
    upper = ssat_var_max[bit];
    lower = ssat_var_min[bit];
    if(x > upper) x = upper;
    else if(x < lower) x = lower;
    return x;
}
#endif

//CortexM3+
//#define ssat16(x)   __ssat(xi32, 16)

// TMS320F28335
#define ssat16(x)  limit(x, -32768, 32767)

//-------------------------------------------------------------------
// user may change mode by entering the correct password
uint16_t modbus_regs_enter_password(uint16_t passwd)
{
    if(passwd == 1981) modbus_regs_mode = MODBUS_REGS_MODE_FACTORY;
    else if(passwd == 1717) modbus_regs_mode = MODBUS_REGS_MODE_ENGINEER;
    else modbus_regs_mode = MODBUS_REGS_MODE_USER;
    return modbus_regs_mode;
}

//-------------------------------------------------------------------
uint16_t modbus_read_reg(uint16_t reg_addr)
{
    const MODBUS_REG *reg;
    uint16_t xu16 = 0;
    int16_t xi16 = 0;
    int32_t xi32;
    iq_t xfiq = IQ(0);
    uint16_t *pu16;
    int16_t *pi16;
    iq_t *pfiq;
#if IQMATH_INT32
    int8_t shift;
    iq_t round;
#endif

    if(reg_addr >= modbus_holding_regs_count)
        return 0;

    reg = &(modbus_holding_regs[reg_addr]);
    //modbus_regs_current_address = reg_addr;
    
    if(reg->type & SRAM_FLAG)
    {
        if((NULL == reg->read.ptr.raw) && (NULL == reg->read.fptr.raw))
            return 0;

        switch(reg->read.type)
        {
            case READ_UINT16:
                pu16 = reg->read.ptr.u16;
                if(NULL == pu16) pu16 = &xu16;
                if(NULL != reg->read.fptr.u16_call)
                {
                    // pre read callback
                    reg->read.fptr.u16_call(pu16);
                }
                return *pu16;
            case READ_INT16:
                pi16 = reg->read.ptr.i16;
                if(NULL == pi16) pi16 = &xi16;
                if(NULL != reg->read.fptr.i16_call)
                {
                    // pre read callback
                    reg->read.fptr.i16_call(pi16);
                }
                return (uint16_t)(*pi16);
            case READ_FLOATIQ:
                pfiq = reg->read.ptr.fiq;
                if(NULL == pfiq) pfiq = &xfiq;
                if(NULL != reg->read.fptr.fiq_call)
                {
                    // pre read callback
                    reg->read.fptr.fiq_call(pfiq);
                }
                xfiq = *pfiq;
            #if IQMATH_FLOAT32
                if(xfiq < (float)0.0)
                    xi32 = (int32_t)(xfiq * reg->read.fiq.scale - (float)0.5);
                else
                    xi32 = (int32_t)(xfiq * reg->read.fiq.scale + (float)0.5);
            #endif
            #if IQMATH_INT32
                shift = reg->read.fiq.i32q - reg->read.fiq.i16q;
                round = IQlsh_signed(1, shift-1); // 0.5 lsb for rounding before shifting
                xi32 = IQrsh_signed(xfiq + round, shift);
            #endif
                return (uint16_t)ssat16(xi32); //16-bits signed saturation
            case READ_RAW32LO:
                return reg->read.ptr.u16[0];
            case READ_RAW32HI:
                return reg->read.ptr.u16[1];
            default:
                break;
        }
    }   
    return 0;
}

//-------------------------------------------------------------------
int modbus_write_reg(uint16_t reg_addr, uint16_t x)
{
    const MODBUS_REG *reg;
    uint16_t xu16;
    int16_t xi16;
    iq_t xfiq;
    uint16_t *pu16;
    int16_t *pi16;
    iq_t *pfiq;
    int written = 0;
#if IQMATH_INT32
    int32_t xi32;
    int8_t shift;
#endif    
    
    if(reg_addr >= modbus_holding_regs_count)
        return 0;
    
    reg = &(modbus_holding_regs[reg_addr]);
    //modbus_regs_current_address = reg_addr;

    if(reg->type & SRAM_FLAG)
    {
        if((WRITE_NO == reg->write.type) && (READ_NO == reg->read.type))
            return 1; // writing to reserved register is ok and has no effect

        if(reg->type & FACTORY_FLAG)
            if(modbus_regs_mode < MODBUS_REGS_MODE_FACTORY)
                return 1; // writing to factory register requires access, otherwise is ok and has no effect
        
        if(reg->type & ENGINEER_FLAG)
            if(modbus_regs_mode < MODBUS_REGS_MODE_ENGINEER)
                return 1; // writing to engineer register requires access, otherwise is ok and has no effect
            
        if((NULL == reg->write.ptr.raw) && (NULL == reg->write.fptr.raw))
            return 0;

        switch(reg->write.type & WRITE_MASK)
        {
            case WRITE_UINT16:
                xu16 = x;
                if(reg->write.type & WRITE_LIM)
                    xu16 = limit(xu16, reg->write.u16.min, reg->write.u16.max);
                pu16 = reg->write.ptr.u16;
                if(NULL == pu16) pu16 = &xu16;
                *pu16 = xu16;
                if(NULL != reg->write.fptr.u16_call)
                {
                    // post write callback
                    reg->write.fptr.u16_call(pu16);
                }
                written = 1;
                break;
            case WRITE_INT16:
                xi16 = (int16_t)x;
                if(reg->write.type & WRITE_LIM)
                    xi16 = limit(xi16, reg->write.i16.min, reg->write.i16.max);
                pi16 = reg->write.ptr.i16;
                if(NULL == pi16) pi16 = &xi16;
                *pi16 = xi16;
                if(NULL != reg->write.fptr.i16_call)
                {
                    // post write callback
                    reg->write.fptr.i16_call(pi16);
                }
                written = 1;
                break;
            case WRITE_FLOATIQ:
            #if IQMATH_FLOAT32
                xfiq = (iq_t)((int16_t)x)*reg->write.fiq.scale;
            #endif
            #if IQMATH_INT32
                shift = reg->write.fiq.i32q - reg->write.fiq.i16q;
                xi32 = (int32_t)((int16_t)x);
                //xi32 = __ssat(xi32, (32 - shift)); // doesn't work: compiler expects const shift
                xi32 = ssat_var(xi32, (32 - shift)); // limited integer range of iq_t
                xfiq = IQlsh_signed(xi32, shift);
            #endif
                if(reg->write.type & WRITE_LIM)
                    xfiq = limit(xfiq, reg->write.fiq.min, reg->write.fiq.max);
                pfiq = reg->write.ptr.fiq;
                if(NULL == pfiq) pfiq = &xfiq;
                *pfiq = xfiq;
                if(NULL != reg->write.fptr.fiq_call)
                {
                    // post write callback
                    reg->write.fptr.fiq_call(pfiq);
                }
                written = 1;
                break;
            case WRITE_RAW32LO:
                reg->write.ptr.u16[0] = x;
                written = 1;
                break;
            case WRITE_RAW32HI:
                reg->write.ptr.u16[1] = x;
                written = 1;
                break;
            default:
                break;
        }
    }   

    return written;
}
