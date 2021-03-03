
#include "modbus_config_cb.h"
#include "modbus_config.h"


//-------------------------------------------------------------------
const char modbus_slave_id[] = NAME_STR " " POWER_STR
                               " v1.0" 
                               " build " __DATE__ " / " __TIME__;
uint16_t modbus_slave_id_len = countof(modbus_slave_id);

//-------------------------------------------------------------------
const MODBUS_REG _modbus_holding_regs[] =
{
     ModbusReg(SRAM_REG, RESERVED_, "GROUP=modbus") // Настройки Modbus
    ,ModbusReg(EROM_REG, UINT16_RANGE(modbus1_slave_addr, 1, 254), "addr")
    // Адрес устройства на шине Modbus
    ,ModbusReg(EROM_REG, FLOATIQ_RANGE(modbus1_uart_baudrate, Q0, -Q5, IQ0(9600.0), IQ0(921600.0)), "baudrate")
    // Скорость обмена на шине Modbus.
    // Обновление после записи в EEPROM и перезапуска системы.
    ,ModbusReg(EROM_REG, UINT16_RANGE(modbus1_uart_stopbits, 1, 2), "stopbits")
    // Число стоповых битов.
    // Обновление после записи в EEPROM и перезапуска системы.
    ,ModbusReg(EROM_REG, UINT16_RANGE(modbus1_uart_parity, 0, 2), "parity")
    // Проверка четности: 0 - без проверки, 1 - нечетная, 2 - четная.
    // Обновление после записи в EEPROM и перезапуска системы.
    ,ModbusReg(SRAM_REG, RESERVED_, "") 
        
    ,ModbusReg(SRAM_REG, RESERVED_, "GROUP=system") // Общее состояние и команды системы
    ,ModbusReg(PROM_REG, UINT16_CB(modbus1_password, NULL, NULL), "password") // пароль на системные команды
    ,ModbusReg(SRAM_REG, UINT16_RO(modbus_regs_mode), "access_mode") // режим доступа к регистрам modbus:
        // 0 - пользовательский, 1 - инженерный, 	 2 - заводской      
		
};


const MODBUS_REG * modbus_holding_regs = _modbus_holding_regs;
uint16_t modbus_holding_regs_count = (sizeof(_modbus_holding_regs) / sizeof(_modbus_holding_regs[0]));

