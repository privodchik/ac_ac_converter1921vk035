#ifndef UART1_HW_H
#define UART1_HW_H

#ifdef __cplusplus
extern "C" {
#endif

#include "stdint.h"
#include "config.h"
#include "uart_hw.h"

//-------------------------------------------------------------------
#define UART1_DEBUG     0 // counters and last received byte

//-------------------------------------------------------------------
#if UART1_DEBUG
extern uint16_t uart1_rx_cnt;
extern uint16_t uart1_tx_cnt;
extern uint16_t uart1_rx_word; // last rx word
extern uint16_t uart1_errors_cnt;
#endif

//-------------------------------------------------------------------
// init and status
void uart1_init(UART_OPTIONS *opt);
void uart1_restart(int reinit_hw);
void uart1_deinit(void);

int uart1_errors(void); // includes "stuck"
int uart1_baud_rate_detected(void);
uint32_t uart1_get_baud_rate(void);

// receive
uint8_t uart1_read_byte(void);
int uart1_rx_ready(void);
void uart1_rx_drop(void);

// transmit
void uart1_write_byte(uint8_t byte);
int uart1_tx_done(void);
int uart1_tx_ready(void); 
uint_fast16_t uart1_tx_free(void); 

void uart1_hw_task(void);

#ifdef __cplusplus
}
#endif

#endif //UART1_HW_H
