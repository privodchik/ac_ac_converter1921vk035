#ifndef MODBUS_REGS_ALIAS_H
#define MODBUS_REGS_ALIAS_H

#ifdef __cplusplus
extern "C" {
#endif

//-------------------------------------------------------------------
#define MODBUS_REGS_ALIAS_ENABLE    0

//-------------------------------------------------------------------
#if MODBUS_REGS_ALIAS_ENABLE

#include "stdint_ext.h"
#include "iqmath.h"

//-------------------------------------------------------------------
typedef struct _MODBUS_REG_ALIAS
{
    uint16_t alias_addr;
    uint16_t orig_addr;
    const char *group_name;
    const char *reg_name;
    
} MODBUS_REG_ALIAS;

//-------------------------------------------------------------------
#define ModbusRegAlias(alias_addr, orig_addr) {alias_addr, orig_addr, 0, 0}
#define ModbusRegNamedAlias(alias_addr, group_name, reg_name) {alias_addr, 0, group_name, reg_name}

// alias functions for modbus_slave
//-------------------------------------------------------------------
void modbus_regs_alias_init(void);
int16_t modbus_regs_alias_address_check(uint16_t alias_addr);
uint16_t modbus_regs_alias_holding_address(uint16_t alias_addr);
uint16_t modbus_regs_alias_input_address(uint16_t alias_addr);
uint16_t modbus_regs_alias_eeprom_address(uint16_t alias_addr);

// registry tables for modbus_slave
//-------------------------------------------------------------------
extern MODBUS_REG_ALIAS * modbus_holding_regs_alias; // see modbus_config_alias.c
extern uint16_t modbus_holding_regs_alias_count;

extern MODBUS_REG_ALIAS * modbus_input_regs_alias; // see modbus_config_alias.c
extern uint16_t modbus_input_regs_alias_count;

extern MODBUS_REG_ALIAS * modbus_eeprom_regs_alias; // see modbus_config_alias.c
extern uint16_t modbus_eeprom_regs_alias_count;

#endif // MODBUS_REGS_ALIAS_ENABLE

#ifdef __cplusplus
}
#endif


#endif // MODBUS_REGS_ALIAS_H
