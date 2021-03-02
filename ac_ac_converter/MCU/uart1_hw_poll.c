#include "mcu.h"
#include "uart1_gpio.h"
#include "uart1_hw.h"
#include "fifo.h"
#include "niietcm4_uart.h"

//-------------------------------------------------------------------
static UART_OPTIONS uart1_opts = FIXED_BAUD(9600);
static FIFO(uint8_t,256) uart1_rx_fifo;
static FIFO(uint8_t,256) uart1_tx_fifo;
static uint_fast16_t uart1_error_flags = 0;
static int_fast8_t uart1_active = 0;

#if UART1_DEBUG
uint16_t uart1_rx_cnt = 0;
uint16_t uart1_tx_cnt = 0;
uint16_t uart1_rx_word = 0; // last rx word
uint16_t uart1_errors_cnt = 0;
#endif

//-------------------------------------------------------------------
void uart1_init(UART_OPTIONS *opt)
{
    if(opt) uart1_opts = opt[0];
    uart1_gpio_clk_init();
    uart1_restart(1); // reinit hw
    uart1_active = 1;
}

//-------------------------------------------------------------------
void uart1_deinit()
{
    uart1_active = 0;
    UART_DeInit(NT_UART3);
}

//-------------------------------------------------------------------
void uart1_restart(int reinit_hw)
{
    UART_Init_TypeDef UART_InitStructure;
    uint32_t baud_rate;
   
    if(reinit_hw) 
    {
        UART_Cmd(NT_UART3, DISABLE);
        UART_DeInit(NT_UART3);
    }

    FIFO_INIT(uart1_rx_fifo);
    FIFO_INIT(uart1_tx_fifo);

    NT_UART3->RSR_ECR = 0; //clear all flags
    uart1_error_flags = 0;

     if(reinit_hw) 
    {
        baud_rate = uart1_opts.baud_rate;
        if(baud_rate == 0) baud_rate = 9600;

        // Initialize UART_InitStructure
        UART_InitStructure.UART_BaudRate = baud_rate;
        UART_InitStructure.UART_DataWidth = UART_DataWidth_8;
        
        UART_InitStructure.UART_StopBit = UART_StopBit_1;
        if(uart1_opts.stop_bits >= UART_STOP_2) UART_InitStructure.UART_StopBit = UART_StopBit_2;

        UART_InitStructure.UART_ParityBit = UART_ParityBit_Disable;
        if(uart1_opts.parity == UART_PARITY_ODD) UART_InitStructure.UART_ParityBit = UART_ParityBit_Odd;
        if(uart1_opts.parity == UART_PARITY_EVEN) UART_InitStructure.UART_ParityBit = UART_ParityBit_Even;

        UART_InitStructure.UART_FIFOEn = ENABLE;
        
        UART_InitStructure.UART_RxEn = ENABLE;
        UART_InitStructure.UART_TxEn = ENABLE;

        UART_Init(NT_UART3, &UART_InitStructure);
        UART_Cmd(NT_UART3, ENABLE);
    }
}

//-------------------------------------------------------------------
int uart1_errors()
{
    // UART_Data_OE_Msk | UART_Data_BE_Msk | UART_Data_PE_Msk | UART_Data_FE_Msk
    return (0 != uart1_error_flags) ? 1 : 0;
}

//-------------------------------------------------------------------
int uart1_baud_rate_detected()
{
    return (0 != uart1_opts.baud_rate) ? 1 : 0;
}

//-------------------------------------------------------------------
uint32_t uart1_get_baud_rate()
{
    return uart1_opts.baud_rate;
}

//-------------------------------------------------------------------
uint8_t uart1_read_byte()
{
    uint8_t byte = 0;
    FIFO_GET(uart1_rx_fifo, byte);
    return byte;
}

//-------------------------------------------------------------------
int uart1_rx_ready()
{
    if(!FIFO_EMPTY(uart1_rx_fifo)) return 1;
    return 0;
}

//-------------------------------------------------------------------
void uart1_rx_drop()
{
    FIFO_INIT(uart1_rx_fifo);
}

//-------------------------------------------------------------------
void uart1_write_byte(uint8_t byte)
{
    FIFO_PUT(uart1_tx_fifo, byte);
}

//-------------------------------------------------------------------
int uart1_tx_ready()
{
    return FIFO_FULL(uart1_tx_fifo) ? 0 : 1;
}

//-------------------------------------------------------------------
uint_fast16_t uart1_tx_free()
{
    return FIFO_FREE(uart1_tx_fifo);
}

//-------------------------------------------------------------------
int uart1_tx_done()
{
    if(FIFO_EMPTY(uart1_tx_fifo))
        // check hardware also
        //return (UART_GetFlagStatus(MDR_UART1, UART_FLAG_BUSY) == RESET) ? 1 : 0;   
        return (NT_UART1->FR & UART_Flag_Busy) ? 0 : 1;
    return 0;
}

//-------------------------------------------------------------------
extern uint16_t mdr_rst_clk_per_uart1_en;
extern uint16_t mdr_rst_clk_uartclk_uart1_en;
extern uint16_t mdr_rst_clk_uartclk_uart1_brg;

extern uint16_t mdr_uart1_cr_uart1_en;
extern uint16_t mdr_uart1_cr_txe;
extern uint16_t mdr_uart1_cr_rxe;

extern uint16_t mdr_uart1_fr_busy;
extern uint16_t mdr_uart1_fr_rxfe;
extern uint16_t mdr_uart1_fr_txff;
extern uint16_t mdr_uart1_fr_rxff;
extern uint16_t mdr_uart1_fr_txfe;

extern uint16_t mdr_uart1_gpio_rx_func;
extern uint16_t mdr_uart1_gpio_tx_func;
extern uint16_t mdr_uart1_gpio_rx_oe;
extern uint16_t mdr_uart1_gpio_tx_oe;
extern uint16_t mdr_uart1_gpio_rx_analog;
extern uint16_t mdr_uart1_gpio_tx_analog;
extern uint16_t mdr_uart1_gpio_rx_pd;
extern uint16_t mdr_uart1_gpio_tx_pd;
extern uint16_t mdr_uart1_gpio_rx_pwr;
extern uint16_t mdr_uart1_gpio_tx_pwr;	

extern uint16_t mdr_uart1_ibrd;
extern uint16_t mdr_uart1_fbrd;
extern uint16_t mdr_uart1_lcr_h;
	


void uart1_hw_task()
{
    volatile uint8_t byte;
    volatile uint16_t word;
	
    if(!uart1_active) return;

    // RX
    while(UART_FlagStatus(NT_UART1, UART_Flag_RxFIFOEmpty) != Flag_SET)  
    {
				
        word = UART_RecieveData(NT_UART1);
    #if UART1_DEBUG
        uart1_rx_word = word;
        uart1_rx_cnt++;
    #endif  
        //errors could be UART_Data_OE_Msk | UART_Data_BE_Msk | UART_Data_PE_Msk | UART_Data_FE_Msk
        if(word & 0xFF00) {
            uart1_error_flags |= ((word >> 8) & 0x00FF);
            // need to clear errors via ECR=0 ?
        #if UART1_DEBUG
            uart1_errors_cnt++;
        #endif    
        }
        if(!FIFO_FULL(uart1_rx_fifo)) {
            FIFO_PUT_FAST(uart1_rx_fifo, (uint8_t)(word & 0x00FF));
        } else {
            // don't wait for hardware overflow
//            uart1_error_flags |= (UART_Data_OE_Msk >> 8);
              uart1_error_flags |= UART_Error_Overflow;
        #if UART1_DEBUG
            uart1_errors_cnt++;
        #endif    
        }
    }
   
    // TX
    while(UART_FlagStatus(NT_UART1, UART_Flag_TxFIFOFull) != Flag_SET)  
    {
			
        if(FIFO_EMPTY(uart1_tx_fifo))
            break;
        FIFO_GET(uart1_tx_fifo, byte);
    #if UART1_DEBUG
        uart1_tx_cnt++;
    #endif            
        UART_SendData(NT_UART1, (uint16_t)byte);
    }
}

