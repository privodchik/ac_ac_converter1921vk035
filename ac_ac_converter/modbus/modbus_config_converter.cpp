
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
    app.stRun.regId_shadow.m_sat_pos;
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
        
        
    ,ModbusReg(SRAM_REG, RESERVED_, "GROUP=cmd") // Команды управления
    ,ModbusReg(SRAM_REG, INT16_RANGE(app.cmds.start, 0, 1), "start; gui=button") // запуск/останов двигателя    
        
        
        
   ,ModbusReg(SRAM_REG, RESERVED_, "GROUP=_conv_adc_scale")
   ,ModbusReg(FRAM_REG, FLOATIQ(app.sens_iFull.scale_get(), QG, Q14), "iFull[A/dig]")
   ,ModbusReg(FRAM_REG, FLOATIQ(app.sens_iLoad.scale_get(), QG, Q14), "iLoad[A/dig]")
   ,ModbusReg(FRAM_REG, FLOATIQ(app.sens_uBUS.scale_get(), QG, Q9), "uBus[V/dig]")
//   ,ModbusReg(FRAM_REG, FLOATIQ(app.sens_uBUSP_N.scale_get(), QG, Q9), "uBusPN[V/dig]")
//   ,ModbusReg(FRAM_REG, FLOATIQ(app.sens_uBUSN_N.scale_get(), QG, Q9), "uBusNN[V/dig]")
   ,ModbusReg(FRAM_REG, FLOATIQ(app.sens_uOut.scale_get(), QG, Q9), "uOut[V/dig]")
       
   ,ModbusReg(SRAM_REG, RESERVED_, "GROUP=_conv_adc")
   ,ModbusReg(SRAM_REG, FLOATIQ_RO(app.sens_iFull.read(), QG, Q5), "iFull[A]")
   ,ModbusReg(SRAM_REG, FLOATIQ_RO(app.sens_iLoad.read(), QG, Q5), "iLoad[A]")
   ,ModbusReg(SRAM_REG, FLOATIQ_RO(app.sens_uBUS.read(), QG, Q5), "uBus[V]")
//   ,ModbusReg(SRAM_REG, FLOATIQ_RO(app.sens_uBUSP_N.read(), QG, Q5), "uBusPN[V]")
//   ,ModbusReg(SRAM_REG, FLOATIQ_RO(app.sens_uBUSN_N.read(), QG, Q5), "uBusNN[V]")
   ,ModbusReg(SRAM_REG, FLOATIQ_RO(app.sens_uOut.read(), QG, Q5), "uOut[V]")
       
       
    ,ModbusReg(SRAM_REG, RESERVED_, "GROUP=_conv_adc_digit")
    ,ModbusReg(SRAM_REG, UINT16_RO(app.sens_uBUS.adc_val_get()), "uBus")
    ,ModbusReg(SRAM_REG, UINT16_RO(app.sens_uOut.adc_val_get()), "uOut")
    ,ModbusReg(SRAM_REG, UINT16_RO(app.sens_iFull.adc_val_get()), "iFull")
    ,ModbusReg(SRAM_REG, UINT16_RO(app.sens_iLoad.adc_val_get()), "iLoad")
       
    ,ModbusReg(SRAM_REG, RESERVED_, "GROUP=_regs") // Регуляторы тока
//    ,ModbusReg(SRAM_REG, FLOATIQ(app.stRun.regId_shadow.m_proportional_part, QG, Q11), "regId K")
//    ,ModbusReg(SRAM_REG, FLOATIQ(app.stRun.regId_shadow.m_integral_part.m_Ti, QG, Q11), "regId Ti[msec]")
//    ,ModbusReg(SRAM_REG, FLOATIQ(app.stRun.regId_shadow.m_sat_pos, QG, Q3), "regId Sat_pos")
//    ,ModbusReg(SRAM_REG, FLOATIQ(app.stRun.regId_shadow.m_sat_neg, QG, Q3), "regId Sat_neg")   
    ,ModbusReg(SRAM_REG, FLOATIQ(app.regId.m_proportional_part, QG, Q11), "regId K")
//    ,ModbusReg(SRAM_REG, FLOATIQ(app.regId.m_integral_part.m_Ti, QG, Q11), "regId Ti[sec]")
    ,ModbusReg(SRAM_REG, FLOATIQ_RANGE(app.regId.m_integral_part.m_Ti, QG, Q11, IQ(0.0005), IQ(1.0)), "regId Ti[sec]")    
    ,ModbusReg(SRAM_REG, FLOATIQ(app.regId.m_sat_pos, QG, Q3), "regId Sat_pos")
    ,ModbusReg(SRAM_REG, FLOATIQ(app.regId.m_sat_neg, QG, Q3), "regId Sat_neg")       
    ,ModbusReg(SRAM_REG, FLOATIQ(app.regId.out_ref_get(), QG, Q11), "regIdOut")    
        
    ,ModbusReg(SRAM_REG, RESERVED_, "") 
//    ,ModbusReg(SRAM_REG, FLOATIQ(app.stRun.regUd_shadow.m_proportional_part, QG, Q11), "regUd K")
//    ,ModbusReg(SRAM_REG, FLOATIQ(app.stRun.regUd_shadow.m_integral_part.m_Ti, QG, Q11), "regUd Ti[msec]")
//    ,ModbusReg(SRAM_REG, FLOATIQ(app.stRun.regUd_shadow.m_sat_pos, QG, Q3), "regUd Sat_pos")
//    ,ModbusReg(SRAM_REG, FLOATIQ(app.stRun.regUd_shadow.m_sat_neg, QG, Q3), "regUd Sat_neg")   
    ,ModbusReg(SRAM_REG, FLOATIQ(app.regUd.m_proportional_part, QG, Q11), "regUd K")
    ,ModbusReg(SRAM_REG, FLOATIQ(app.regUd.m_integral_part.m_Ti, QG, Q11), "regUd Ti[sec]")
//    ,ModbusReg(SRAM_REG, FLOATIQ_RANGE(app.regUd.m_integral_part.m_Ti, QG, Q11, IQ(0.0005), IQ(1.0)), "regUd Ti[sec]")    
    ,ModbusReg(SRAM_REG, FLOATIQ(app.regUd.m_sat_pos, QG, Q3), "regUd Sat_pos")
    ,ModbusReg(SRAM_REG, FLOATIQ(app.regUd.m_sat_neg, QG, Q3), "regUd Sat_neg")       
    ,ModbusReg(SRAM_REG, FLOATIQ(app.regUd.out_ref_get(), QG, Q6), "regUdOut")    
    ,ModbusReg(SRAM_REG, RESERVED_, "")         
//    ,ModbusReg(SRAM_REG, FLOATIQ(app.stRun.regUq_shadow.m_proportional_part, QG, Q11), "regUq K")
//    ,ModbusReg(SRAM_REG, FLOATIQ(app.stRun.regUq_shadow.m_integral_part.m_Ti, QG, Q11), "regUq Ti[msec]")
//    ,ModbusReg(SRAM_REG, FLOATIQ(app.stRun.regUq_shadow.m_sat_pos, QG, Q3), "regUq Sat_pos")
//    ,ModbusReg(SRAM_REG, FLOATIQ(app.stRun.regUq_shadow.m_sat_neg, QG, Q3), "regUq Sat_neg")    
    ,ModbusReg(SRAM_REG, FLOATIQ(app.regUq.m_proportional_part, QG, Q11), "regUq K")
    ,ModbusReg(SRAM_REG, FLOATIQ(app.regUq.m_integral_part.m_Ti, QG, Q11), "regUq Ti[sec]")
//    ,ModbusReg(SRAM_REG, FLOATIQ_RANGE(app.regUq.m_integral_part.m_Ti, QG, Q11, IQ(0.0005), IQ(1.0)), "regUq Ti[sec]")    
    ,ModbusReg(SRAM_REG, FLOATIQ(app.regUq.m_sat_pos, QG, Q3), "regUq Sat_pos")
    ,ModbusReg(SRAM_REG, FLOATIQ(app.regUq.m_sat_neg, QG, Q3), "regUq Sat_neg")        
    ,ModbusReg(SRAM_REG, FLOATIQ(app.regUq.out_ref_get(), QG, Q6), "regUqOut")   
        
    ,ModbusReg(SRAM_REG, RESERVED_, "")         
    ,ModbusReg(SRAM_REG, FLOATIQ(app.lpf.m_Tf, QG, Q11), "lpf Tf[sec]")    
        
    ,ModbusReg(SRAM_REG, RESERVED_, "GROUP=_diag")
    ,ModbusReg(SRAM_REG, INT16_RANGE(app.cmds.diag, 0, 1), "diag; gui=button") // диагностика
    ,ModbusReg(SRAM_REG, INT16_RANGE(app.cmds.rst, 0, 1), "reset; gui=button")
    ,ModbusReg(PROM_REG, FLOATIQ_RANGE(app.stDiag.m_pwm_duty,  QG, Q14,  IQ(0.0), IQ(1.0)), "duty[%]")  // скважность
    ,ModbusReg(SRAM_REG, UINT16_RANGE(app.cmds.pwm0_chA, 0, 1), "pwm0_chA")
    ,ModbusReg(SRAM_REG, UINT16_RANGE(app.cmds.pwm0_chB, 0, 1), "pwm0_chB")
    ,ModbusReg(SRAM_REG, UINT16_RANGE(app.cmds.pwm1_chA, 0, 1), "pwm1_chA")
    ,ModbusReg(SRAM_REG, UINT16_RANGE(app.cmds.pwm1_chB, 0, 1), "pwm1_chB")
    ,ModbusReg(SRAM_REG, UINT16_RANGE(app.cmds.km, 0, 1), "km")
    ,ModbusReg(SRAM_REG, UINT16_RANGE(app.cmds.fun, 0, 1), "fun")    
        
    ,ModbusReg(SRAM_REG, RESERVED_, "GROUP=_test")
    ,ModbusReg(FRAM_REG, UINT16_RANGE(simple_sin, 0, 1), "simpleSin_on")
    ,ModbusReg(SRAM_REG, FLOATIQ(app.stRun.m_virtGrid, QG, Q7), "Uref")      
    ,ModbusReg(SRAM_REG, FLOATIQ(app.stRun.m_currentAngle, QG, Q11), "angle")
    ,ModbusReg(SRAM_REG, FLOATIQ(app.stRun.m_ccr, QG, Q3), "ccr")
    ,ModbusReg(SRAM_REG, UINT16_RO(iCCRA), "ccrA")
    ,ModbusReg(SRAM_REG, UINT16_RO(iCCRB), "ccrB")
        
    ,ModbusReg(SRAM_REG, FLOATIQ(uRef_d_, QG, Q7), "Uref_d")
    ,ModbusReg(SRAM_REG, FLOATIQ(uRef_q_, QG, Q7), "Uref_q")
    ,ModbusReg(SRAM_REG, FLOATIQ(uOut_d_, QG, Q6), "Uout_d")    
    ,ModbusReg(SRAM_REG, FLOATIQ(uOut_q_, QG, Q6), "Uout_q") 
    ,ModbusReg(SRAM_REG, FLOATIQ(uOut_,  QG, Q6), "Uout_") 
        
    ,ModbusReg(SRAM_REG, UINT16_RANGE(FR, 50, 500), "freq")
    ,ModbusReg(SRAM_REG, UINT16_RANGE(AMP, 10, 180), "amp")
        
        
};



const MODBUS_REG * modbus_holding_regs = _modbus_holding_regs;
uint16_t modbus_holding_regs_count = (sizeof(_modbus_holding_regs) / sizeof(_modbus_holding_regs[0]));

