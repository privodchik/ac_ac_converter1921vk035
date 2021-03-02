#include "uart_hw.h"

#if UART1_ENABLED
    #include "uart1_hw.h"
#endif
#if UART2_ENABLED
    #include "uart2_hw.h"
#endif
#if UART3_ENABLED
    #include "uart3_hw.h"
#endif

//-------------------------------------------------------------------
void uart_init(int uart_number, UART_OPTIONS *opt)
{
#if UART1_ENABLED
    if(uart_number == 1) uart1_init(opt); else
#endif        
#if UART2_ENABLED
    if(uart_number == 2) uart2_init(opt); else
#endif        
#if UART3_ENABLED
    if(uart_number == 3) uart3_init(opt); else
#endif
    {}
}

//-------------------------------------------------------------------
void uart_deinit(int uart_number)
{
#if UART1_ENABLED
    if(uart_number == 1) uart1_deinit(); else
#endif        
#if UART2_ENABLED
    if(uart_number == 2) uart2_deinit(); else
#endif        
#if UART3_ENABLED
    if(uart_number == 3) uart3_deinit(); else
#endif
    {}
}

//-------------------------------------------------------------------
void uart_restart(int uart_number, int reinit_hw)
{
#if UART1_ENABLED
    if(uart_number == 1) uart1_restart(reinit_hw); else
#endif        
#if UART2_ENABLED
    if(uart_number == 2) uart2_restart(reinit_hw); else
#endif        
#if UART3_ENABLED
    if(uart_number == 3) uart3_restart(reinit_hw); else
#endif
    {}
}

//-------------------------------------------------------------------
int uart_errors(int uart_number)
{
#if UART1_ENABLED
    if(uart_number == 1) return uart1_errors(); else
#endif        
#if UART2_ENABLED
    if(uart_number == 2) return uart2_errors(); else
#endif        
#if UART3_ENABLED
    if(uart_number == 3) return uart3_errors(); else
#endif
    return 0;
}

//-------------------------------------------------------------------
int uart_baud_rate_detected(int uart_number)
{
#if UART1_ENABLED
    if(uart_number == 1) return uart1_baud_rate_detected(); else
#endif        
#if UART2_ENABLED
    if(uart_number == 2) return uart2_baud_rate_detected(); else
#endif        
#if UART3_ENABLED
    if(uart_number == 3) return uart3_baud_rate_detected(); else
#endif
    return 0;
}

//-------------------------------------------------------------------
uint32_t uart_get_baud_rate(int uart_number)
{
#if UART1_ENABLED
    if(uart_number == 1) return uart1_get_baud_rate(); else
#endif        
#if UART2_ENABLED
    if(uart_number == 2) return uart2_get_baud_rate(); else
#endif        
#if UART3_ENABLED
    if(uart_number == 3) return uart3_get_baud_rate(); else
#endif
    return 0;
}

//-------------------------------------------------------------------
uint8_t uart_read_byte(int uart_number)
{
#if UART1_ENABLED
    if(uart_number == 1) return uart1_read_byte(); else
#endif        
#if UART2_ENABLED
    if(uart_number == 2) return uart2_read_byte(); else
#endif        
#if UART3_ENABLED
    if(uart_number == 3) return uart3_read_byte(); else
#endif
    return 0;
}

//-------------------------------------------------------------------
int uart_rx_ready(int uart_number)
{
#if UART1_ENABLED
    if(uart_number == 1) return uart1_rx_ready(); else
#endif        
#if UART2_ENABLED
    if(uart_number == 2) return uart2_rx_ready(); else
#endif        
#if UART3_ENABLED
    if(uart_number == 3) return uart3_rx_ready(); else
#endif
    return 0;
}

//-------------------------------------------------------------------
void uart_rx_drop(int uart_number)
{
#if UART1_ENABLED
    if(uart_number == 1) uart1_rx_drop(); else
#endif        
#if UART2_ENABLED
    if(uart_number == 2) uart2_rx_drop(); else
#endif        
#if UART3_ENABLED
    if(uart_number == 3) uart3_rx_drop(); else
#endif
    return;
}

//-------------------------------------------------------------------
void uart_write_byte(int uart_number, uint8_t byte)
{
#if UART1_ENABLED
    if(uart_number == 1) uart1_write_byte(byte); else
#endif        
#if UART2_ENABLED
    if(uart_number == 2) uart2_write_byte(byte); else
#endif        
#if UART3_ENABLED
    if(uart_number == 3) uart3_write_byte(byte); else
#endif
    {}
}

//-------------------------------------------------------------------
int uart_tx_ready(int uart_number)
{
#if UART1_ENABLED
    if(uart_number == 1) return uart1_tx_ready(); else
#endif        
#if UART2_ENABLED
    if(uart_number == 2) return uart2_tx_ready(); else
#endif        
#if UART3_ENABLED
    if(uart_number == 3) return uart3_tx_ready(); else
#endif
    return 0;
}

//-------------------------------------------------------------------
uint_fast16_t uart_tx_free(int uart_number)
{
#if UART1_ENABLED
    if(uart_number == 1) return uart1_tx_free(); else
#endif        
#if UART2_ENABLED
    if(uart_number == 2) return uart2_tx_free(); else
#endif        
#if UART3_ENABLED
    if(uart_number == 3) return uart3_tx_free(); else
#endif
    return 0;
}

//-------------------------------------------------------------------
int uart_tx_done(int uart_number)
{
#if UART1_ENABLED
    if(uart_number == 1) return uart1_tx_done(); else
#endif        
#if UART2_ENABLED
    if(uart_number == 2) return uart2_tx_done(); else
#endif        
#if UART3_ENABLED
    if(uart_number == 3) return uart3_tx_done(); else
#endif
    return 0;
}

//-------------------------------------------------------------------
void uart_hw_task()
{
#if UART1_ENABLED
    uart1_hw_task();
#endif        
#if UART2_ENABLED
    uart2_hw_task();
#endif        
#if UART3_ENABLED
    uart3_hw_task();
#endif
}
