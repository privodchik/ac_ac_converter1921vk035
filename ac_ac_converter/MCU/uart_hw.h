#ifndef UART_HW_H
#define UART_HW_H


#ifdef __cplusplus
extern "C" {
#endif

#include "stdint.h"
#include "config.h"

//-------------------------------------------------------------------
#define UART_NUM            2

#define UART1_ENABLED       0
#define UART2_ENABLED       1
#define UART3_ENABLED       0 // not present in hardware

//-------------------------------------------------------------------
#define UART_STOP_1         1
#define UART_STOP_2         2

#define UART_PARITY_NONE    0
#define UART_PARITY_ODD     1
#define UART_PARITY_EVEN    2

//-------------------------------------------------------------------
typedef struct _UART_OPTIONS
{
    uint32_t     baud_rate; // 0 is autobaud, not supported
    uint_fast8_t stop_bits;
    uint_fast8_t parity;
    
} UART_OPTIONS;

//-------------------------------------------------------------------
// Help macros for UART_OPTIONS structure initialization
//
// Example:
//    UART_OPTIONS opt = FIXED_BAUD(57600);
//    uart_init(2, &opt);

#define FIXED_BAUD(baud_rate) {baud_rate, UART_STOP_1, UART_PARITY_NONE}
//#define AUTO_BAUD() FIXED_BAUD(0) // not supported

//-------------------------------------------------------------------
// init and status
void uart_init(int uart_number, UART_OPTIONS *opt);
void uart_restart(int uart_number, int reinit_hw);
void uart_deinit(int uart_number);

int uart_errors(int uart_number); // includes "stuck"
int uart_baud_rate_detected(int uart_number);
uint32_t uart_get_baud_rate(int uart_number);

// receive
uint8_t uart_read_byte(int uart_number);
int uart_rx_ready(int uart_number);
void uart_rx_drop(int uart_number);

// transmit
void uart_write_byte(int uart_number, uint8_t byte);
int uart_tx_done(int uart_number);
int uart_tx_ready(int uart_number); 
uint_fast16_t uart_tx_free(int uart_number); 

// this task reads from hardware FIFO into software FIFO
// it executes fast, you may call it as often as possible
void uart_hw_task(void);


#ifdef __cplusplus
}
#endif

#endif //UART_HW_H
