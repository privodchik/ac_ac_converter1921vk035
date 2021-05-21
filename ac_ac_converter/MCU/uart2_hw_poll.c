#include "mcu.h"
#include "uart2_gpio.h"
#include "uart2_hw.h"
#include "fifo.h"
#include "plib035_uart.h"

//-------------------------------------------------------------------
static UART_OPTIONS uart2_opts = FIXED_BAUD(9600);
static FIFO(uint8_t,256) uart2_rx_fifo;
static FIFO(uint8_t,256) uart2_tx_fifo;
static uint_fast16_t uart2_error_flags = 0;
static int_fast8_t uart2_active = 0;

#if UART2_DEBUG
uint16_t uart2_rx_cnt = 0;
uint16_t uart2_tx_cnt = 0;
uint16_t uart2_rx_word = 0; // last rx word
uint16_t uart2_errors_cnt = 0;
#endif

//-------------------------------------------------------------------
void uart2_init(UART_OPTIONS *opt)
{
    if(opt) uart2_opts = opt[0];
    uart2_gpio_clk_init();
    uart2_restart(1); // reinit hw
    uart2_active = 1;
}

//-------------------------------------------------------------------
void uart2_deinit()
{
    uart2_active = 0;
    UART_DeInit(UART1);
}

//-------------------------------------------------------------------
void uart2_restart(int reinit_hw)
{
    UART_Init_TypeDef UART_InitStructure;
    uint32_t baud_rate;
   
    if(reinit_hw) 
    {
        UART_Cmd(UART1, DISABLE);
        UART_DeInit(UART1);
    }

    FIFO_INIT(uart2_rx_fifo);
    FIFO_INIT(uart2_tx_fifo);

    UART1->RSR = 0; //clear all flags
    uart2_error_flags = 0;

    if(reinit_hw) 
    {
        baud_rate = uart2_opts.baud_rate;
        if(baud_rate == 0) baud_rate = 9600;

        // Initialize UART_InitStructure
        UART_StructInit(&UART_InitStructure);
        UART_InitStructure.BaudRate = baud_rate;
        UART_InitStructure.DataWidth = UART_DataWidth_8;
        
        UART_InitStructure.StopBit = UART_StopBit_1;
        if(uart2_opts.stop_bits >= UART_STOP_2) UART_InitStructure.StopBit = UART_StopBit_2;

        UART_InitStructure.ParityBit = UART_ParityBit_Disable;
        if(uart2_opts.parity == UART_PARITY_ODD) UART_InitStructure.ParityBit = UART_ParityBit_Odd;
        if(uart2_opts.parity == UART_PARITY_EVEN) UART_InitStructure.ParityBit = UART_ParityBit_Even;

        UART_InitStructure.FIFO = ENABLE;
        
        UART_InitStructure.Rx = ENABLE;
        UART_InitStructure.Tx = ENABLE;

        UART_Init(UART1, &UART_InitStructure);
        UART_Cmd(UART1, ENABLE);
    }
}

//-------------------------------------------------------------------
int uart2_errors()
{
    // UART_Data_OE_Msk | UART_Data_BE_Msk | UART_Data_PE_Msk | UART_Data_FE_Msk
    return (0 != uart2_error_flags) ? 1 : 0;
}

//-------------------------------------------------------------------
int uart2_baud_rate_detected()
{
    return (0 != uart2_opts.baud_rate) ? 1 : 0;
}

//-------------------------------------------------------------------
uint32_t uart2_get_baud_rate()
{
    return uart2_opts.baud_rate;
}

//-------------------------------------------------------------------
uint8_t uart2_read_byte()
{
    uint8_t byte = 0;
    FIFO_GET(uart2_rx_fifo, byte);
    return byte;
}

//-------------------------------------------------------------------
int uart2_rx_ready()
{
    if(!FIFO_EMPTY(uart2_rx_fifo)) return 1;
    return 0;
}

//-------------------------------------------------------------------
void uart2_rx_drop()
{
    FIFO_INIT(uart2_rx_fifo);
}

//-------------------------------------------------------------------
void uart2_write_byte(uint8_t byte)
{
    FIFO_PUT(uart2_tx_fifo, byte);
}

//-------------------------------------------------------------------
int uart2_tx_ready()
{
    return FIFO_FULL(uart2_tx_fifo) ? 0 : 1;
}

//-------------------------------------------------------------------
uint_fast16_t uart2_tx_free()
{
    return FIFO_FREE(uart2_tx_fifo);
}

//-------------------------------------------------------------------
int uart2_tx_done()
{
    if(FIFO_EMPTY(uart2_tx_fifo))
        // check hardware also
        //return (UART_GetFlagStatus(MDR_UART2, UART_FLAG_BUSY) == RESET) ? 1 : 0;   
        return (UART1->FR & UART_Flag_Busy) ? 0 : 1;
    return 0;
}

//-------------------------------------------------------------------
void uart2_hw_task()
{
    volatile uint8_t byte;
    volatile uint16_t word;

    if(!uart2_active) return;

    // RX
    while(UART_FlagStatus(UART1, UART_Flag_RxFIFOEmpty) != SET)  
    {
        word = UART_RecieveData(UART1);
    #if UART2_DEBUG
        uart2_rx_word = word;
        uart2_rx_cnt++;
    #endif  
        //errors could be UART_Data_OE_Msk | UART_Data_BE_Msk | UART_Data_PE_Msk | UART_Data_FE_Msk
        if(word & 0xFF00) {
            uart2_error_flags |= ((word >> 8) & 0x00FF);
            // need to clear errors via ECR=0 ?
        #if UART2_DEBUG
            uart2_errors_cnt++;
        #endif    
        }
        if(!FIFO_FULL(uart2_rx_fifo)) {
            FIFO_PUT_FAST(uart2_rx_fifo, (uint8_t)(word & 0x00FF));
        } else {
            // don't wait for hardware overflow
//            uart2_error_flags |= (UART_Data_OE_Msk >> 8);
            uart2_error_flags |= UART_Error_Overflow;
        #if UART2_DEBUG
            uart2_errors_cnt++;
        #endif    
        }
    }
   
    // TX
    while(UART_FlagStatus(UART1, UART_Flag_TxFIFOFull) != SET)  
    {
        if(FIFO_EMPTY(uart2_tx_fifo))
            break;
        FIFO_GET(uart2_tx_fifo, byte);
    #if UART2_DEBUG
        uart2_tx_cnt++;
    #endif            
        UART_SendData(UART1, (uint16_t)byte);
    }
}

