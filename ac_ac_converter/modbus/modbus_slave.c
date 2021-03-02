#include <math.h> // pow
//#include "mcu.h"
#include "modbus.h"
#include "modbus_rtu.h"
#include "modbus_regs.h"
#include "modbus_regs_alias.h"
#include "modbus_eeprom.h"
#include "modbus_scope.h"
#include "pt.h"

extern void jump_to_bootloader(void);
extern void system_reset(void);

/* Build the exception response */
//-------------------------------------------------------------------
static int16_t response_exception(uint8_t *pdu, uint8_t exception_code)
{
    pdu[0] |= 0x80; // error flag in function code
    pdu[1] = exception_code;
    return 2;
}

//-------------------------------------------------------------------
static int16_t address_check(uint16_t addr) {
    if(addr < modbus_holding_regs_count) {
        return 1;
    }
    return 0;
}

//-------------------------------------------------------------------
static int16_t address_check_ext(uint16_t addr) {
    if(addr < modbus_holding_regs_count) {
        return 1;
    }
#if MODBUS_REGS_ALIAS_ENABLE
    if(modbus_regs_alias_address_check(addr)) {
        return 1;
    }
#endif
    return 0;
}

//-------------------------------------------------------------------
static int16_t address_check_range(uint16_t start_addr, uint16_t count) {
    if(address_check(start_addr)) {
        if(address_check(start_addr + count - 1)) {
            return 1;
        }
    }
    return 0;
}

//-------------------------------------------------------------------
static int16_t address_check_range_ext(uint16_t start_addr, uint16_t count) {
    if(address_check_ext(start_addr)) {
        if(address_check_ext(start_addr + count - 1)) {
            return 1;
        }
    }
    return 0;
}

// core modbus slave functionality
//-------------------------------------------------------------------
PT_THREAD(task_modbus_process_pdu(PT *pt, uint8_t *pdu, uint16_t *p_len, int16_t *p_status, int uart_number))
{
    static uint16_t len;
    static uint8_t modbus_fc;
    static uint16_t reg_addr;
    static uint16_t reg_addr_orig;
    static uint16_t reg_count;
    static uint16_t read_addr;
    static uint16_t read_count;
    static uint16_t write_addr;
    static uint16_t write_count;
    static uint16_t reg_value;
    static uint16_t and_mask, or_mask;
    static uint16_t value;
    static uint8_t meta_request;
#if MODBUS_SCOPE_ENANBLED
    static uint8_t scope_request;
#endif    
    static uint16_t pos;
    static uint16_t len_pos;
    static uint16_t N;
    static uint16_t rsp_len; // response length
    //static int16_t eeprom_status;
#if MODBUS_SCOPE_ENANBLED
    static iq_t xiq;
#endif    
    static float xf;
#if IQMATH_INT32
    static float xscale;
    static int8_t qbits;
#endif    
    static const MODBUS_REG *reg;
    static const char *str;
    static int ok;
    //static PT pt_child;
    static UART_OPTIONS uart_opts;
    static int16_t eeprom_read_all_requested = 0;
    static int16_t eeprom_write_all_requested = 0;
    static int16_t eeprom_erase_all_requested = 0;
    static int16_t modbus_slave_lock = 0;

    PT_BEGIN(pt);

    PT_WAIT_WHILE(pt, modbus_slave_lock);

    modbus_slave_lock = 1;

    *p_status = 0;
    rsp_len = 0; // also indicates no error (response) yet
    len = *p_len;
    
    if (len < 1) { // func[1] = 1 byte minimum
        modbus_slave_lock = 0;
        PT_EXIT(pt);
    }
        
    modbus_fc = pdu[0];

    if ((modbus_fc == MODBUS_FC_READ_HOLDING_REGISTERS) 
        || (modbus_fc == MODBUS_FC_READ_INPUT_REGISTERS) )
    {
        if (len < 5) // func[1] + addr[2] + count[2] = 5 bytes minimum
        {
            rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_VALUE);
        }
        else
        {
            reg_addr = MODBUS_GET_INT16_FROM_INT8(pdu, 1);
            reg_count = MODBUS_GET_INT16_FROM_INT8(pdu, 3);

            if ((reg_count < 1) || (reg_count > MODBUS_MAX_READ_REGISTERS)) {
                rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_VALUE);
            } else if (!address_check_range_ext(reg_addr, reg_count)) {
                rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_ADDRESS);
            } else {
                rsp_len = 1; // function code remains unchanged
                pdu[rsp_len++] = reg_count << 1; // number of bytes
                while (reg_count) 
                {
                    reg_count--;
                #if MODBUS_REGS_ALIAS_ENABLE
                    if(reg_addr < modbus_holding_regs_count) {
                        reg_addr_orig = reg_addr;
                    } else {
                        if(modbus_fc == MODBUS_FC_READ_INPUT_REGISTERS) {
                            reg_addr_orig = modbus_regs_alias_input_address(reg_addr);
                        } else {
                            reg_addr_orig = modbus_regs_alias_holding_address(reg_addr);
                        }
                    }
                #else
                    reg_addr_orig = reg_addr;
                #endif
                    value = modbus_read_reg(reg_addr_orig);
                    reg_addr++;
                    MODBUS_SET_INT16_TO_INT8(pdu, rsp_len, value);
                    rsp_len += 2;
                }
            }
        }
    }
    else
    if (modbus_fc == MODBUS_FC_WRITE_SINGLE_REGISTER)
    {
        if (len < 5) // func[1] + addr[2] + value[2] = 5 bytes
        {
            rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_VALUE);
        }
        else
        {
            reg_addr = MODBUS_GET_INT16_FROM_INT8(pdu, 1);
            reg_value = MODBUS_GET_INT16_FROM_INT8(pdu, 3);

            if (!address_check_ext(reg_addr)) {
                rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_ADDRESS);
            } else {
            #if MODBUS_REGS_ALIAS_ENABLE
                if(reg_addr < modbus_holding_regs_count) {
                    reg_addr_orig = reg_addr;
                } else {
                    reg_addr_orig = modbus_regs_alias_holding_address(reg_addr);
                }
            #else
                reg_addr_orig = reg_addr;
            #endif
                if(modbus_write_reg(reg_addr_orig, reg_value)) {
                    PT_WAIT_WHILE(pt, modbus_eeprom_write_delayed_status() == EEPROM_BUSY);
                    rsp_len = len; // pdu remains unchanged
                } else {
                    rsp_len = response_exception(pdu, MODBUS_EXCEPTION_SLAVE_OR_SERVER_FAILURE);
                }
            }
        }
    }
    else
    if (modbus_fc == MODBUS_FC_WRITE_MULTIPLE_REGISTERS)
    {
        if (len < 6) // func[1] + addr[2] + count[2] + N[1] + value[0+] = 6+ bytes
        {
            rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_VALUE);
        }
        else
        {
            reg_addr = MODBUS_GET_INT16_FROM_INT8(pdu, 1);
            reg_count = MODBUS_GET_INT16_FROM_INT8(pdu, 3);
            N = pdu[5];

            if ((reg_count < 1) || (reg_count > MODBUS_MAX_WRITE_REGISTERS)) {
                rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_VALUE);
            } else if (!address_check_range_ext(reg_addr, reg_count)) {
                rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_ADDRESS);
            } else if ((reg_count<<1) != N) { // check N
                rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_VALUE);
            } else if (len != (reg_count<<1)+6) { // check total packet len
                rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_VALUE);
            }
            else
            {
                pos = 6;
                ok = 1;
                while (reg_count) 
                {
                    reg_count--;
                    reg_value = MODBUS_GET_INT16_FROM_INT8(pdu, pos);
                    pos += 2;
                #if MODBUS_REGS_ALIAS_ENABLE
                    if(reg_addr < modbus_holding_regs_count) {
                        reg_addr_orig = reg_addr;
                    } else {
                        reg_addr_orig = modbus_regs_alias_holding_address(reg_addr);
                    }
                #else
                    reg_addr_orig = reg_addr;
                #endif
                    if(modbus_write_reg(reg_addr_orig, reg_value)) {
                        PT_WAIT_WHILE(pt, modbus_eeprom_write_delayed_status() == EEPROM_BUSY);
                    } else {
                        ok = 0;
                    }
                    reg_addr++;
                }
                if(ok) {
                    rsp_len = 5; // pdu truncated to func[1] + addr[2] + count[2] (unchanged)
                } else {
                    rsp_len = response_exception(pdu, MODBUS_EXCEPTION_SLAVE_OR_SERVER_FAILURE);
                }
            }
        }
    }
    else
    if (modbus_fc == MODBUS_FC_MASK_WRITE_REGISTER)
    {
        if (len < 7) // func[1] + addr[2] + and_mask[2] + or_mask[2] = 7 bytes
        {
            rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_VALUE);
        }
        else
        {
            reg_addr = MODBUS_GET_INT16_FROM_INT8(pdu, 1);
            and_mask = MODBUS_GET_INT16_FROM_INT8(pdu, 3);
            or_mask = MODBUS_GET_INT16_FROM_INT8(pdu, 5);

            if (!address_check_ext(reg_addr)) {
                rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_ADDRESS);
            } else {
            #if MODBUS_REGS_ALIAS_ENABLE
                if(reg_addr < modbus_holding_regs_count) {
                    reg_addr_orig = reg_addr;
                } else {
                    reg_addr_orig = modbus_regs_alias_holding_address(reg_addr);
                }
            #else
                reg_addr_orig = reg_addr;
            #endif
                value = modbus_read_reg(reg_addr_orig);
                reg_value = (value & and_mask) | (or_mask & (~and_mask));
                if(modbus_write_reg(reg_addr_orig, reg_value)) {
                    PT_WAIT_WHILE(pt, modbus_eeprom_write_delayed_status() == EEPROM_BUSY);
                    rsp_len = len; // pdu remains unchanged
                } else {
                    rsp_len = response_exception(pdu, MODBUS_EXCEPTION_SLAVE_OR_SERVER_FAILURE);
                }
            }
        }
    }
    else
    if (modbus_fc == MODBUS_FC_WRITE_AND_READ_REGISTERS)
    {
        if (len < 10) // func[1] + read_addr[2] + read_count[2] 
                      // write_addr[2] + write_count[2] + N[1] + value[0+] = 10+ bytes
        {
            rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_VALUE);
        }
        else
        {
            read_addr = MODBUS_GET_INT16_FROM_INT8(pdu, 1);
            read_count = MODBUS_GET_INT16_FROM_INT8(pdu, 3);
            write_addr = MODBUS_GET_INT16_FROM_INT8(pdu, 5);
            write_count = MODBUS_GET_INT16_FROM_INT8(pdu, 7);
            N = pdu[9];

            // write operation
            reg_addr = write_addr;
            reg_count = write_count;
            if ((reg_count < 1) || (reg_count > MODBUS_MAX_WRITE_REGISTERS)) {
                rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_VALUE);
            } else if (!address_check_range_ext(reg_addr, reg_count)) {
                rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_ADDRESS);
            } else if ((reg_count<<1) != N) { // check N
                rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_VALUE);
            } else if (len != (reg_count<<1)+10) { // check total packet len
                rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_VALUE);
            }
            else
            {
                pos = 10;
                ok = 1;
                while (reg_count) 
                {
                    reg_count--;
                    reg_value = MODBUS_GET_INT16_FROM_INT8(pdu, pos);
                    pos += 2;
                #if MODBUS_REGS_ALIAS_ENABLE
                    if(reg_addr < modbus_holding_regs_count) {
                        reg_addr_orig = reg_addr;
                    } else {
                        reg_addr_orig = modbus_regs_alias_holding_address(reg_addr);
                    }
                #else
                    reg_addr_orig = reg_addr;
                #endif
                    if(modbus_write_reg(reg_addr_orig, reg_value)) {
                        PT_WAIT_WHILE(pt, modbus_eeprom_write_delayed_status() == EEPROM_BUSY);
                    } else {
                        ok = 0;
                    }
                    reg_addr++;
                }
                if(!ok) {
                    rsp_len = response_exception(pdu, MODBUS_EXCEPTION_SLAVE_OR_SERVER_FAILURE);
                }
            }
            
            if(0 == rsp_len) // no error in write operation
            {
                // read operation
                reg_addr = read_addr;
                reg_count = read_count;
                if ((reg_count < 1) || (reg_count > MODBUS_MAX_READ_REGISTERS)) {
                    rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_VALUE);
                } else if (!address_check_range_ext(reg_addr, reg_count)) {
                    rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_ADDRESS);
                } else {
                    rsp_len = 1; // function code remains unchanged
                    pdu[rsp_len++] = reg_count << 1; // number of bytes
                    while (reg_count) 
                    {
                        reg_count--;
                    #if MODBUS_REGS_ALIAS_ENABLE
                        if(reg_addr < modbus_holding_regs_count) {
                            reg_addr_orig = reg_addr;
                        } else {
                            reg_addr_orig = modbus_regs_alias_holding_address(reg_addr);
                        }
                    #else
                        reg_addr_orig = reg_addr;
                    #endif
                        value = modbus_read_reg(reg_addr_orig);
                        reg_addr++;
                        MODBUS_SET_INT16_TO_INT8(pdu, rsp_len, value);
                        rsp_len += 2;
                    }
                }
            }
        }
    }
    else
    if (modbus_fc == MODBUS_FC_REPORT_SLAVE_ID)
    {
        // slave id
        rsp_len = 1; // function code remains unchanged
        pdu[rsp_len++] = modbus_slave_id_len; // number of bytes (preliminary)
        pos = 0;
        // copy ID, remove last zeros if any
        while((pos < modbus_slave_id_len) && (modbus_slave_id[pos] != 0)) 
        {
            pdu[rsp_len++] = modbus_slave_id[pos++];
        }
        pdu[1] = pos; // number of bytes (actual)
        // run status
        pdu[rsp_len++] = 0xFF; // 0xFF - ON, 0x00 - OFF
    }
    else
    if (modbus_fc == MODBUS_FC_USER_ECHO)
    {
        // user defined extension
        // echo back received packet as is
        // note: the echo is sent only when CRC was correct
        rsp_len = len;
    }
    else
    if (modbus_fc == MODBUS_FC_USER_LOADER)
    {
        // loader support
        if(len == 5 && pdu[1] == 'b' && pdu[2] == 'o' && pdu[3] == 'o' && pdu[4] == 't') // jump to bootloader
        {
            rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_FUNCTION);
            // note: if the below function works, it will not return
            // and the response will never be sent
            jump_to_bootloader();
        }
        else
        if(len == 4 && pdu[1] == 'r' && pdu[2] == 's' && pdu[3] == 't') // reset
        {
            rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_FUNCTION);
            // note: if the below function works, it will not return
            // and the response will never be sent
            system_reset();
        }
        else
        if(len == 11 && pdu[1] == 'b' && pdu[2] == 'a' && pdu[3] == 'u' && pdu[4] == 'd') // change uart baudrate
        {
            uart_opts.baud_rate = MODBUS_GET_INT32_FROM_INT8(pdu, 5);
            uart_opts.parity = pdu[9] & 0x03;
            uart_opts.stop_bits = pdu[10] & 0x03;
            if(uart_opts.stop_bits < 1) uart_opts.stop_bits = 1;
            if(uart_opts.stop_bits > 2) uart_opts.stop_bits = 2;
            // switch uart baud rate
            uart_init(uart_number, &uart_opts);
            // don't send any response
        }
    }
    else
    if (modbus_fc == MODBUS_FC_USER_EEPROM)
    {
        // EEPROM configuration
        if(len == 4 && pdu[1] == 'c' && pdu[2] == 'r' && pdu[3] == 'f')
        {
            // read configuration from EEPROM
            //eeprom_status = modbus_eeprom_read_all();
            //PT_SPAWN(pt, &pt_child, modbus_eeprom_read_all_nb(&pt_child, &eeprom_status));
            //str = eeprom_status_str(eeprom_status);
            if(!eeprom_read_all_requested) {
                modbus_eeprom_read_all_request = 1;
                eeprom_read_all_requested = 1;
                str = "BUSY";
            } else {
                if(modbus_eeprom_read_all_request) {
                    str = "BUSY";
                } else {
                    str = eeprom_status_str(modbus_eeprom_read_all_status);
                    eeprom_read_all_requested = 0;
                }
            }
            rsp_len = len; // request remains unchanged
            pdu[rsp_len++] = 0; // number of bytes (preliminary)
            // copy str without last zero, failsafe length limit
            pos = 0;
            while((pos < 20) && (str[pos] != 0)) 
            {
                pdu[rsp_len++] = str[pos++];
            }
            pdu[len] = pos; // number of bytes (actually)
        }
        else
        if(len == 4 && pdu[1] == 'c' && pdu[2] == 'w' && pdu[3] == 'f')
        {
            // write configuration to EEPROM
            //eeprom_status = modbus_eeprom_write_all();
            //PT_SPAWN(pt, &pt_child, modbus_eeprom_write_all_nb(&pt_child, &eeprom_status));
            //str = eeprom_status_str(eeprom_status);
            if(!eeprom_write_all_requested) {
                modbus_eeprom_write_all_request = 1;
                eeprom_write_all_requested = 1;
                str = "BUSY";
            } else {
                if(modbus_eeprom_write_all_request) {
                    str = "BUSY";
                } else {
                    str = eeprom_status_str(modbus_eeprom_write_all_status);
                    eeprom_write_all_requested = 0;
                }
            }
            rsp_len = len; // request remains unchanged
            pdu[rsp_len++] = 0; // number of bytes (preliminary)
            // copy str without last zero, failsafe length limit
            pos = 0;
            while((pos < 20) && (str[pos] != 0)) 
            {
                pdu[rsp_len++] = str[pos++];
            }
            pdu[len] = pos; // number of bytes (actually)
        }
        else
        if(len == 4 && pdu[1] == 'c' && pdu[2] == 'e' && pdu[3] == 'f' )
        {
            // erase configuration in EEPROM
            //eeprom_status = modbus_eeprom_erase_all();
            //PT_SPAWN(pt, &pt_child, modbus_eeprom_erase_all_nb(&pt_child, &eeprom_status));
            //str = eeprom_status_str(eeprom_status);
            if(!eeprom_erase_all_requested) {
                modbus_eeprom_erase_all_request = 1;
                eeprom_erase_all_requested = 1;
                str = "BUSY";
            } else {
                if(modbus_eeprom_erase_all_request) {
                    str = "BUSY";
                } else {
                    str = eeprom_status_str(modbus_eeprom_erase_all_status);
                    eeprom_erase_all_requested = 0;
                }
            }
            rsp_len = len; // request remains unchanged
            pdu[rsp_len++] = 0; // number of bytes (preliminary)
            // copy str without last zero, failsafe length limit
            pos = 0;
            while((pos < 20) && (str[pos] != 0)) 
            {
                pdu[rsp_len++] = str[pos++];
            }
            pdu[len] = pos; // number of bytes (actually)
        }
    }
    else
    if (modbus_fc == MODBUS_FC_USER_REG_META)
    {
        // register meta information
        if (len != 6) // func[1] + addr[2] + count[2] + request[1] 
        {
            rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_VALUE);
        }
        else
        {
            reg_addr = MODBUS_GET_INT16_FROM_INT8(pdu, 1);
            reg_count = MODBUS_GET_INT16_FROM_INT8(pdu, 3);
            meta_request = pdu[5];
            
            if ((reg_count < 1) || (reg_count > MODBUS_MAX_READ_REGISTERS)) {
                rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_VALUE);
            } else if (!address_check_range(reg_addr, reg_count)) { // not ext !
                rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_ADDRESS);
            } else {
                if(meta_request == 1) // register strings
                {
                    rsp_len = len; // request remains unchanged
                    while(reg_count--) 
                    {
                        if(rsp_len >= MODBUS_MAX_PDU_LENGTH) {
                            // pdu buffer full
                            //rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_VALUE);
                            break;
                        }
                        
                        // out of bounds should never happen here thanks to above checks
                        reg = &(modbus_holding_regs[reg_addr]);
                        str = reg->str;
                        if(str == NULL)
                        {
                            pdu[rsp_len++] = 0; // number of bytes (empty string)
                        }
                        else
                        {
                            len_pos = rsp_len;
                            pdu[rsp_len++] = 0; // number of bytes (preliminary)
                            // copy str, no ending zero, failsafe length limit
                            ok = 1;
                            pos = 0;
                            while((pos < 240) && (str[pos] != 0))
                            {
                                if(rsp_len >= MODBUS_MAX_PDU_LENGTH) {
                                    // pdu buffer full
                                    ok = 0;
                                    break;
                                }
                                pdu[rsp_len++] = str[pos++];
                            }
                            if(!ok) {
                                // pdu buffer full
                                //rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_VALUE);
                                rsp_len = len_pos;
                                break;
                            }
                            pdu[len_pos] = pos; // number of bytes (actual)                
                        }

                        reg_addr++;
                    }
                }
                else
                if(meta_request == 2) // read_type, write_type
                {
                    rsp_len = len; // request remains unchanged
                    
                    while(reg_count--) 
                    {
                        if(rsp_len+2 > MODBUS_MAX_PDU_LENGTH) {
                            // pdu buffer full
                            //rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_VALUE);
                            break;
                        }
                        
                        // out of bounds should never happen here thanks to above checks
                        reg = &(modbus_holding_regs[reg_addr]);
                        
                        if(reg->read.ptr.raw || reg->read.fptr.raw)
                            pdu[rsp_len++] = reg->read.type;
                        else
                            pdu[rsp_len++] = READ_NO;
                        if(reg->write.ptr.raw || reg->write.fptr.raw) {
                            if(
                                  ((reg->type & FACTORY_FLAG) && (modbus_regs_mode < MODBUS_REGS_MODE_FACTORY))
                               || ((reg->type & ENGINEER_FLAG) && (modbus_regs_mode < MODBUS_REGS_MODE_ENGINEER))
                              )
                                pdu[rsp_len++] = WRITE_NO; // factory/engineer register looks read only if no access rights
                            else
                                pdu[rsp_len++] = reg->write.type;
                        } else
                            pdu[rsp_len++] = WRITE_NO;

                        reg_addr++;
                    }
                }
                else
                if(meta_request == 3) // read / write scale for floats
                {
                    rsp_len = len; // request remains unchanged
                    
                    while(reg_count--) 
                    {
                        if(rsp_len >= MODBUS_MAX_PDU_LENGTH) {
                            // pdu buffer full
                            //rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_VALUE);
                            break;
                        }
                        
                        // out of bounds should never happen here thanks to above checks
                        reg = &(modbus_holding_regs[reg_addr]);

                        if((reg->read.type == READ_FLOATIQ) 
                        || ((reg->write.type & WRITE_MASK) == WRITE_FLOATIQ))
                        {
                            if(rsp_len+9 > MODBUS_MAX_PDU_LENGTH) {
                                // pdu buffer full
                                //rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_VALUE);
                                break;
                            }

                            pdu[rsp_len++] = 1; // valid scales
                    
                            xf = 1.0;
                            if(reg->read.type == READ_FLOATIQ) {
                            #if IQMATH_FLOAT32
                                xf = reg->read.fiq.scale;
                            #endif
                            #if IQMATH_INT32
                                qbits = reg->read.fiq.i16q;
                                if(qbits > 0)
                                    xf = (float)((int32_t)1<<qbits);
                                else if(qbits < 0)
                                    xf = (float)((int32_t)1<<(16+qbits)) * (float)1.5258789e-05;
                            #endif
                            }
                            MODBUS_SET_FLOAT32_TO_INT8(pdu, rsp_len, xf);
                            rsp_len += 4;

                            xf = 1.0;
                            if((reg->write.type & WRITE_MASK) == WRITE_FLOATIQ) {
                            #if IQMATH_FLOAT32
                                xf = reg->write.fiq.scale;
                            #endif
                            #if IQMATH_INT32
                                qbits = reg->write.fiq.i16q;
                                if(qbits > 0)
                                    xf = (float)((int32_t)1<<(16-qbits)) * (float)1.5258789e-05;
                                else if(qbits < 0)
                                    xf = (float)((int32_t)1<<(-qbits));
                            #endif
                            }
                            MODBUS_SET_FLOAT32_TO_INT8(pdu, rsp_len, xf);
                            rsp_len += 4;
                        }
                        else
                        {
                            pdu[rsp_len++] = 0; // no scales (non-float value)
                        }

                        reg_addr++;
                    }
                }
                else
                if(meta_request == 4) // min / max for write limited
                {
                    rsp_len = len; // request remains unchanged
                    
                    while(reg_count--) 
                    {
                        if(rsp_len >= MODBUS_MAX_PDU_LENGTH) {
                            // pdu buffer full
                            //rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_VALUE);
                            break;
                        }
                        
                        // out of bounds should never happen here thanks to above checks
                        reg = &(modbus_holding_regs[reg_addr]);

                        if(reg->write.type & WRITE_LIM)
                        {                    
                            if(WRITE_UINT16 == (reg->write.type & WRITE_MASK))
                            {
                                if(rsp_len+5 > MODBUS_MAX_PDU_LENGTH) {
                                    // pdu buffer full
                                    //rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_VALUE);
                                    break;
                                }
                                pdu[rsp_len++] = WRITE_UINT16; // min max is uint16
                                MODBUS_SET_INT16_TO_INT8(pdu, rsp_len, reg->write.u16.min);
                                rsp_len += 2;
                                MODBUS_SET_INT16_TO_INT8(pdu, rsp_len, reg->write.u16.max);
                                rsp_len += 2;
                            }
                            else 
                            if(WRITE_INT16 == (reg->write.type & WRITE_MASK))
                            {
                                if(rsp_len+5 > MODBUS_MAX_PDU_LENGTH) {
                                    // pdu buffer full
                                    //rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_VALUE);
                                    break;
                                }
                                pdu[rsp_len++] = WRITE_INT16; // min max is int16_t
                                MODBUS_SET_INT16_TO_INT8(pdu, rsp_len, reg->write.i16.min);
                                rsp_len += 2;
                                MODBUS_SET_INT16_TO_INT8(pdu, rsp_len, reg->write.i16.max);
                                rsp_len += 2;
                            }
                            else
                            if(WRITE_FLOATIQ == (reg->write.type & WRITE_MASK))
                            {
                                if(rsp_len+9 > MODBUS_MAX_PDU_LENGTH) {
                                    // pdu buffer full
                                    //rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_VALUE);
                                    break;
                                }
                                pdu[rsp_len++] = WRITE_FLOATIQ;
                                // pretend min max is iq_t, convert to float
                                xf = IQ2FLOAT(reg->write.fiq.min);
                            #if IQMATH_INT32
                                if(reg->write.fiq.i32q != QG) {
                                    // convert from iq_t to actual iqNN_t
                                    qbits = reg->write.fiq.i32q - QG;
                                    xscale = powf((float)2.0, (float)-qbits);
                                    //if(qbits > 0) xscale = (float)((int32_t)1<<(16-qbits)) * 1.5258789e-05;
                                    //else xscale = (float)((int32_t)1<<(-qbits));
                                    xf *= xscale;
                                }                                    
                            #endif
                                MODBUS_SET_FLOAT32_TO_INT8(pdu, rsp_len, xf);
                                rsp_len += 4;
                                xf = IQ2FLOAT(reg->write.fiq.max);
                            #if IQMATH_INT32
                                if(reg->write.fiq.i32q != QG) {
                                    // convert from iq_t to actual iqNN_t
                                    xf *= xscale;
                                }                                    
                            #endif
                                MODBUS_SET_FLOAT32_TO_INT8(pdu, rsp_len, xf);
                                rsp_len += 4;
                            }
                            else
                            {
                                // other register types don't have min / max
                                pdu[rsp_len++] = 0;
                                break;
                            }
                        }
                        else
                        {
                            // only write limited registers have min / max
                            pdu[rsp_len++] = 0;
                        }
                        reg_addr++;
                    }
                }
                else
                if(meta_request == 5) // get total number of registers
                {
                    // addr, count are ignored
                    rsp_len = len; // request length remains unchanged
                    MODBUS_SET_INT16_TO_INT8(pdu, 3, modbus_holding_regs_count);
                }
                else
                {
                    rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_VALUE);
                }
            }
        }
    }
#if MODBUS_SCOPE_ENANBLED        
    else
    if (modbus_fc == MODBUS_FC_USER_SCOPE)
    {
        // func[1] + stop[1]=0
        // func[1] + keep_running[1]=5 (also means start, no response is sent back)
        // func[1] + setup_ch[1]=3 + Nch[1] + ch[N]
        // func[1] + setup_sampling[1]=4 + downsample[1], responds base sample period
        if (len < 2) 
        {
            rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_VALUE);
        }
        else
        {
            rsp_len = 0; //0 indicates no error
            scope_request = pdu[1];
            if(scope_request == 0) // turn off
            {
                if(len == 2)
                {
                    modbus_scope_running = 0;
                    rsp_len = 2;
                }
                else
                    rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_VALUE);
            }
            else
            if(scope_request == 5) // keep running
            {
                if(len == 4)
                {
                    // no response will be sent
                    modbus_scope_session = pdu[2];
                    modbus_scope_running = pdu[3];
                }                    
                else
                    rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_VALUE);
            }
            else
            if(scope_request == 3) // setup channels
            {
                if(len >= 3)
                {
                    modbus_scope_num_ch = 0; // failsafe
                    reg_count = (uint16_t)pdu[2]; // Nch
                    if(reg_count > modbus_scope_max_num_ch)
                        rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_VALUE);

                    if(!rsp_len) // no error
                    {
                        if(len == 3 + reg_count * 2)
                        {
                            for(pos = 0; pos < reg_count; pos++)
                            {
                                reg_addr = (uint16_t)MODBUS_GET_INT16_FROM_INT8(pdu, 3+pos*2); // Nbytes
                                if (reg_addr >= modbus_holding_regs_count) {
                                    rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_ADDRESS);
                                    break;
                                }
                                modbus_scope_ch[pos] = reg_addr;
                            }
                            if(!rsp_len) // no error
                            {
                                modbus_scope_num_ch = reg_count;
                            }                            
                        }
                        else
                            rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_VALUE);
                    }
                }
                else
                    rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_VALUE);

                if(!rsp_len) // no error
                {
                    rsp_len = 3; // send request without channels
                    //rsp_len = len; // send request as is
                }
            }
            else
            if(scope_request == 4) // setup sampling
            {
                if(len == 3)
                {
                    value = pdu[2]; // downsample
                    if(value <= 0) value = 1;
                    modbus_scope_downsample = value;

                    rsp_len = 3; // send back with sample period information
                    xiq = time2IQms(modbus_scope_period);
                    // TO DO: get rid of floating point (requires protocol change)
                    xf = IQ2FLOAT(xiq)*(float)1e-3;
                    MODBUS_SET_FLOAT32_TO_INT8(pdu, rsp_len, xf);
                    rsp_len += 4;
                }
                else
                    rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_VALUE);
            }
            else
                rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_DATA_VALUE);
                //rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_FUNCTION);
        }
    }
#endif // MODBUS_SCOPE_ENANBLED        
    else
    {
        rsp_len = response_exception(pdu, MODBUS_EXCEPTION_ILLEGAL_FUNCTION);
    }

    *p_len = rsp_len;
    if (rsp_len > 0) {
        *p_status = 1;
    }

    modbus_slave_lock = 0;
    PT_END(pt);
}
