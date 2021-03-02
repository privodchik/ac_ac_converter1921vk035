// only include this file once into modbus config
#ifndef MODBUS_CONFIG_CB_H
#define MODBUS_CONFIG_CB_H

#include "mcu.h"
#include "config.h"
//#include "convertor_adc.h"
//#include "convertor_pwm.h"
//#include "motor_sm.h"
#include "modbus_regs.h"
#include "modbus_scope.h"
#include "uart_hw.h"
//#include "errors.h"
//#include "pu.h"
#include "gpio.h"
#include "modbus_eeprom.h"

//-------------------------------------------------------------------
iq0_t rcb_uart1_get_baud_rate(iq0_t *x) { return (iq0_t)uart_get_baud_rate(1); }
iq0_t rcb_uart2_get_baud_rate(iq0_t *x) { return (iq0_t)uart_get_baud_rate(2); }

//-------------------------------------------------------------------
static uint16_t password_update(uint16_t *value)
{
    modbus_regs_enter_password(*value);
    return *value;
}

//-------------------------------------------------------------------
uint16_t rcb_uart1_errors(uint16_t *x)
{
    *x = uart_errors(1);
    return *x;
}

//-------------------------------------------------------------------
uint16_t rcb_uart2_errors(uint16_t *x)
{
    *x = uart_errors(2);
    return *x;
}

#if MOTOR_ENABLE
//-------------------------------------------------------------------
uint16_t convertor_pwm_read_fault(uint16_t *x)
{
    *x = convertor_pwm_check_fault();
    return *x;
}

//-------------------------------------------------------------------
static uint16_t x_pwm_update = 0;
static uint16_t cmd_pwm_update(uint16_t *value)
{
    // don't update PWM on running motor
    if(*value && motor_is_stopped()) {
        convertor_pwm_calc_params();
    }
    *value = 0;
    return *value;
}

#endif // MOTOR_ENABLE

#endif // MODBUS_CONFIG_CB_H


