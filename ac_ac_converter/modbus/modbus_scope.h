#ifndef MODBUS_SCOPE_H
#define MODBUS_SCOPE_H

#ifdef __cplusplus
extern "C" {
#endif

#include "stdint_ext.h"
#include "iqmath.h"
#include "time_defs.h"
#include "pt.h"

#define MODBUS_SCOPE_ENANBLED       1

#if MODBUS_SCOPE_ENANBLED

//-------------------------------------------------------------------
extern time_t modbus_scope_period;

extern uint16_t modbus_scope_session;
extern uint16_t modbus_scope_running;
extern uint16_t modbus_scope_fifo_level;
extern uint16_t modbus_scope_downsample;
extern uint16_t modbus_scope_overflow_cnt;
extern uint16_t modbus_scope_test_signal;

extern uint16_t modbus_scope_ch[];
extern uint16_t modbus_scope_num_ch;
extern uint16_t modbus_scope_max_num_ch;

//-------------------------------------------------------------------
void modbus_scope_init(void);
void modbus_scope_tick(time_t period);
int modbus_scope_is_idle(void);
PT_THREAD(task_modbus_scope_tx(PT *pt, int uart_number));

#else

int modbus_scope_is_idle(void);
void modbus_scope_tick(time_t period);

extern uint16_t modbus_scope_running;

#endif //MODBUS_SCOPE_ENANBLED

#ifdef __cplusplus
}
#endif

#endif //MODBUS_SCOPE_H
