#ifndef UART2_HW_H
#define UART2_HW_H

#include "stdint.h"
#include "config.h"
#include "uart_hw.h"

//-------------------------------------------------------------------
#define UART2_DEBUG     0 // counters and last received byte

//-------------------------------------------------------------------
#if UART2_DEBUG
extern uint16_t uart2_rx_cnt;
extern uint16_t uart2_tx_cnt;
extern uint16_t uart2_rx_word; // last rx word
extern uint16_t uart2_errors_cnt;
#endif

//-------------------------------------------------------------------
// init and status
void uart2_init(UART_OPTIONS *opt);
void uart2_restart(int reinit_hw);
void uart2_deinit(void);

int uart2_errors(void); // includes "stuck"
int uart2_baud_rate_detected(void);
uint32_t uart2_get_baud_rate(void);

// receive
uint8_t uart2_read_byte(void);
int uart2_rx_ready(void);
void uart2_rx_drop(void);

// transmit
void uart2_write_byte(uint8_t byte);
int uart2_tx_done(void);
int uart2_tx_ready(void); 
uint_fast16_t uart2_tx_free(void); 

void uart2_hw_task(void);

#endif //UART2_HW_H
