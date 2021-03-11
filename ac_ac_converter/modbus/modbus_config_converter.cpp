
#include "modbus_config_cb.h"
#include "modbus_config.h"

#include "CApp.h"
extern CApp app;


//-------------------------------------------------------------------
const char modbus_slave_id[] = NAME_STR " " POWER_STR
                               " v1.0" 
                               " build " __DATE__ " / " __TIME__;
uint16_t modbus_slave_id_len = countof(modbus_slave_id);

//-------------------------------------------------------------------


void f(){
    app.sm.state_name_get();
}

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
    ,ModbusReg(SRAM_REG, UINT16_RO(app.sm.state_name_get()), "state")      
        
   ,ModbusReg(SRAM_REG, RESERVED_, "GROUP=_conv_adc_scale")
   ,ModbusReg(FRAM_REG, FLOATIQ(app.sens_iFull.scale_get(), QG, Q14), "iFull[A/dig]")
   ,ModbusReg(FRAM_REG, FLOATIQ(app.sens_iLoad.scale_get(), QG, Q14), "iLoad[A/dig]")
   ,ModbusReg(FRAM_REG, FLOATIQ(app.sens_uBUSP_N.scale_get(), QG, Q9), "uBusPN[V/dig]")
   ,ModbusReg(FRAM_REG, FLOATIQ(app.sens_uBUSN_N.scale_get(), QG, Q9), "uBusNN[V/dig]")
   ,ModbusReg(FRAM_REG, FLOATIQ(app.sens_uOut.scale_get(), QG, Q9), "uOut[V/dig]")
       
   ,ModbusReg(SRAM_REG, RESERVED_, "GROUP=_conv_adc")
   ,ModbusReg(SRAM_REG, FLOATIQ_RO(app.sens_iFull.read(), QG, Q5), "iacN[A]")
   ,ModbusReg(SRAM_REG, FLOATIQ_RO(app.sens_iLoad.read(), QG, Q5), "iacP[A]")
   ,ModbusReg(SRAM_REG, FLOATIQ_RO(app.sens_uBUSP_N.read(), QG, Q5), "uBusPN[V]")
   ,ModbusReg(SRAM_REG, FLOATIQ_RO(app.sens_uBUSN_N.read(), QG, Q5), "uBusNN[V]")
   ,ModbusReg(SRAM_REG, FLOATIQ_RO(app.sens_uOut.read(), QG, Q5), "uOut[V]")
};




const MODBUS_REG * modbus_holding_regs = _modbus_holding_regs;
uint16_t modbus_holding_regs_count = (sizeof(_modbus_holding_regs) / sizeof(_modbus_holding_regs[0]));

