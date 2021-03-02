//#include "mcu.h"
#include "modbus_scope.h"
#include "modbus_regs.h"
#include "modbus_crc16.h"
#include "modbus.h"
#include "uart_hw.h"
#include "gpio.h"
#include "atomic.h"
#include "time_defs.h"
#include "timer.h"
#include "fifo.h" // from uart

#if MODBUS_SCOPE_ENANBLED

// chunk time tuned for 3kW to support single channel 10kHz
// continuous streaming via 460800/230400 uart-uart
//#define SCOPE_CHUNK_TIME    TIME_MSEC(90.0)
//#define SCOPE_CHUNK_TIME    TIME_MSEC(80.0)
#define SCOPE_CHUNK_TIME    TIME_MSEC(70.0)

#define SCOPE_CHUNK_BYTES    4000

//-------------------------------------------------------------------
extern uint16_t _modbus_device_address;
extern time_t _modbus_t35;
extern int _modbus_is_idle(void);

//-------------------------------------------------------------------
time_t modbus_scope_period = TIME_SEC(0.0);

uint16_t modbus_scope_session = 1;
uint16_t modbus_scope_running = 0;
uint16_t modbus_scope_fifo_level = 0;
uint16_t modbus_scope_downsample = 1;

uint16_t modbus_scope_test_signal = 0;
uint16_t modbus_scope_overflow_cnt = 0;

uint16_t modbus_scope_ch[32];
uint16_t modbus_scope_num_ch = 0;
uint16_t modbus_scope_max_num_ch = countof(modbus_scope_ch);

#define SCOPE_ST_INIT       0
#define SCOPE_ST_IDLE       1
#define SCOPE_ST_PREAMBLE   2
#define SCOPE_ST_SAMPLES    3
#define SCOPE_ST_CRC        4
#define SCOPE_ST_WAIT_TX    5
#define SCOPE_ST_WAIT35     6

static int16_t scope_state = SCOPE_ST_INIT;

static time_t scope_tx_timeout = TIME_MSEC(200.0); // detect tx stuck

//-------------------------------------------------------------------
static uint16_t scope_clock = 0;
static uint16_t scope_overflow_flag = 0;
static uint16_t scope_downsample_counter = 0;

static uint16_t scope_ch_counter = 0;
static uint16_t scope_bytes_counter = 0;

//-------------------------------------------------------------------
static FIFO(uint16_t,2048) scope_fifo;
static uint16_t fifo_clock = 0;

static uint16_t scope_crc16;

//-------------------------------------------------------------------
void modbus_scope_init()
{
    modbus_scope_running = 0;
    FIFO_INIT(scope_fifo);
    fifo_clock = 0;
    scope_overflow_flag = 0;
    scope_state = SCOPE_ST_IDLE;
}

//-------------------------------------------------------------------
int modbus_scope_is_idle(void)
{
    if(scope_state == SCOPE_ST_IDLE) return 1;
    if(scope_state == SCOPE_ST_INIT) return 1;
    return 0;
}

//-------------------------------------------------------------------
static int16_t scope_should_begin(TIMER *tim)
{
    uint16_t should_begin = 0;
    if(FIFO_BUSY(scope_fifo) >= (FIFO_SIZE(scope_fifo)>>1)) // 50% FIFO fill triggers tx
    {
        should_begin = 1;
    }
    else
    if(timer_expired(tim)) // did't send for some time
    {
        if(FIFO_BUSY(scope_fifo) >= modbus_scope_num_ch) // at least 1 sample
            should_begin = 1;
    }
    return should_begin;
}

//-------------------------------------------------------------------
static int16_t last_scope_fifo_drained = 0;

static int16_t scope_fifo_drained(int uart_number)
{
    if(FIFO_EMPTY(scope_fifo) && uart_tx_done(uart_number))
    {
        // finish transaction to not violate modbus spec
        // at sample boundary or when not running
        if((scope_ch_counter == 0) || (0 == modbus_scope_running))
        {
            last_scope_fifo_drained = 1;
            return 1;
        }
    }

    last_scope_fifo_drained = 0;
    return 0;
}

//-------------------------------------------------------------------
PT_THREAD(task_modbus_scope_tx(PT *pt, int uart_number))
{
    static TIMER tim1;
    static TIMER tim_chunk;
    static uint16_t word;
    static uint8_t byte, msb, lsb;
    static int16_t scope_stuck;
    static int16_t scope_finish;
    static USE_ATOMIC_BLOCK;

    PT_BEGIN(pt);

    PT_WAIT_UNTIL(pt, _modbus_device_address != 0);

    while(1) {

        scope_state = SCOPE_ST_IDLE;
        scope_overflow_flag = 0; // releases FIFO filling after overflow
        scope_stuck = 0;

        timer_set(&tim_chunk, SCOPE_CHUNK_TIME);

        // begin transaction only when running >= 2
        // but keep writing samples into fifo while running >= 1
        PT_YIELD_UNTIL(pt, (modbus_scope_running >= 2)
                        && (_modbus_is_idle())
                        && scope_should_begin(&tim_chunk)
                );

        ATOMIC_BLOCK_BEGIN;
        {
            modbus_scope_running -= 1;
        }
        ATOMIC_BLOCK_END;

        timer_set(&tim_chunk, SCOPE_CHUNK_TIME);

        scope_state = SCOPE_ST_PREAMBLE;
        gpio_rs485_tx(uart_number, ON);

        if(uart_tx_free(uart_number) < 8)
        {
            timer_set(&tim1, scope_tx_timeout);
            PT_WAIT_UNTIL(pt, (uart_tx_free(uart_number) >= 8) || timer_expired(&tim1));
            if(timer_expired(&tim1) && (uart_tx_free(uart_number) < 8))
            {
                // hardware stuck
                modbus_scope_running = 0;
                uart_restart(uart_number, 0); // 0 - don't touch baudrate
                continue; // goes to idle
            }
        }

        scope_crc16 = modbus_crc16_begin();
        
        byte = _modbus_device_address & 0x00FF;
        scope_crc16 = modbus_crc16_next(scope_crc16, byte);
        uart_write_byte(uart_number, byte);

        byte = MODBUS_FC_USER_SCOPE;
        scope_crc16 = modbus_crc16_next(scope_crc16, byte);
        uart_write_byte(uart_number, byte);

        byte = 2; // scope data
        scope_crc16 = modbus_crc16_next(scope_crc16, byte);
        uart_write_byte(uart_number, byte);
        
        byte = modbus_scope_session & 0x00FF;
        scope_crc16 = modbus_crc16_next(scope_crc16, byte);
        uart_write_byte(uart_number, byte);
            
        ATOMIC_BLOCK_BEGIN;
        {
            word = scope_clock - fifo_clock;
        }
        ATOMIC_BLOCK_END;

        msb = (word >> 8) & 0x00FF;
        lsb = word & 0x00FF;

        byte = msb;
        scope_crc16 = modbus_crc16_next(scope_crc16, byte);
        uart_write_byte(uart_number, byte);

        byte = lsb;
        scope_crc16 = modbus_crc16_next(scope_crc16, byte);
        uart_write_byte(uart_number, byte);
            
        byte = modbus_scope_downsample;
        scope_crc16 = modbus_crc16_next(scope_crc16, byte);
        uart_write_byte(uart_number, byte);

        byte = modbus_scope_running;
        scope_crc16 = modbus_crc16_next(scope_crc16, byte);
        uart_write_byte(uart_number, byte);
            
        scope_bytes_counter = 8; // addr+71+2+session[1]+ovfl[2]+downs[1]+running[1]
        scope_ch_counter = 0;

        scope_state = SCOPE_ST_SAMPLES;

        while(1) {

            scope_finish = 0;
            timer_set(&tim1, scope_tx_timeout);
            PT_YIELD_UNTIL(pt, scope_fifo_drained(uart_number)
                            || (!FIFO_EMPTY(scope_fifo) && (uart_tx_free(uart_number) >= 2))
                            || timer_expired(&tim1)
                            || (timer_elapsed(&tim_chunk) >= TIME_MSEC(300.0))
                    );

            if(last_scope_fifo_drained) {
                // finish transaction due to empty FIFO
                break;
            }

            if(timer_elapsed(&tim_chunk) >= TIME_MSEC(300.0)) {
                if((scope_ch_counter == 0) || (0 == modbus_scope_running)) {
                    // at sample boundary or not running
                    //finish transaction by timeout and stop scope
                    break;
                }
            }

            if(timer_expired(&tim1)) {
                // hardware stuck
                modbus_scope_running = 0;
                uart_restart(uart_number, 0); // 0 - don't touch baudrate
                scope_stuck = 1;
                break; // will go to idle
            }

            // this loop may take CPU for a long time, consider inserting YIELD
            while(!FIFO_EMPTY(scope_fifo) && (uart_tx_free(uart_number) >= 2))
            {
                FIFO_GET(scope_fifo, word);

                msb = ((word>>8) & 0x00FF);
                lsb = (word & 0x00FF);

                byte = msb;
                scope_crc16 = modbus_crc16_next(scope_crc16, byte);
                uart_write_byte(uart_number, byte);

                byte = lsb;
                scope_crc16 = modbus_crc16_next(scope_crc16, byte);
                uart_write_byte(uart_number, byte);

                scope_bytes_counter += 2;

                scope_ch_counter++;
                if(scope_ch_counter >= modbus_scope_num_ch)
                {
                    scope_ch_counter = 0;
                    ATOMIC_BLOCK_BEGIN;
                    {
                        fifo_clock -= modbus_scope_downsample;
                    }
                    ATOMIC_BLOCK_END;

                    // only end transaction at sample boundary (all channels served)
                    if(    (timer_expired(&tim_chunk) && !scope_overflow_flag) // long sending time without overflow
                        || (FIFO_EMPTY(scope_fifo) && scope_overflow_flag) // drained out after overflow
                        || (!modbus_scope_running) // turned off
                        || (scope_bytes_counter > SCOPE_CHUNK_BYTES) // enough data sent
                        )
                    {
                        scope_finish = 1;
                        break;
                    }
                }
            }

            if(scope_finish) {
                break;
            }
        }

        if(scope_stuck) {
            continue; //goes to idle
        }

        scope_state = SCOPE_ST_CRC;

        if(uart_tx_free(uart_number) < 6)
        {
            timer_set(&tim1, scope_tx_timeout);
            PT_WAIT_UNTIL(pt, (uart_tx_free(uart_number) >= 6) || timer_expired(&tim1));
            if(timer_expired(&tim1) && (uart_tx_free(uart_number) < 6))
            {
                // hardware stuck
                modbus_scope_running = 0;
                uart_restart(uart_number, 0); // 0 - don't touch baudrate
                continue; // goes to idle
            }
        }

        // end signature
        byte = 0xBE;
        scope_crc16 = modbus_crc16_next(scope_crc16, byte);
        uart_write_byte(uart_number, byte);

        byte = 0xEF;
        scope_crc16 = modbus_crc16_next(scope_crc16, byte);
        uart_write_byte(uart_number, byte);
            
        // bytes count
        word = scope_bytes_counter;
        msb = (word >> 8) & 0x00FF;
        lsb = word & 0x00FF;

        byte = msb;
        scope_crc16 = modbus_crc16_next(scope_crc16, byte);
        uart_write_byte(uart_number, byte);

        byte = lsb;
        scope_crc16 = modbus_crc16_next(scope_crc16, byte);
        uart_write_byte(uart_number, byte);
        
        // CRC
        byte = ((scope_crc16>>8) & 0x00FF);
        uart_write_byte(uart_number, byte);

        byte = (scope_crc16 & 0x00FF);
        uart_write_byte(uart_number, byte);
            
        scope_state = SCOPE_ST_WAIT_TX;
        timer_set(&tim1, scope_tx_timeout);
        PT_WAIT_UNTIL(pt, uart_tx_done(uart_number) || timer_expired(&tim1));
        if(timer_expired(&tim1) && !uart_tx_done(uart_number))
        {
            // hardware stuck 
            modbus_scope_running = 0;
            uart_restart(uart_number, 0); // 0 - don't touch baudrate
            continue; // goes to idle
        }

        // reply physically sent out (shift register is empty)
        scope_state = SCOPE_ST_WAIT35;
        gpio_rs485_tx(uart_number, OFF);
        timer_set(&tim1, _modbus_t35);
        PT_WAIT_UNTIL(pt, timer_expired(&tim1));
    }

    PT_END(pt);
}

//-------------------------------------------------------------------
//#pragma CODE_SECTION(modbus_scope_tick, "ramfuncs");
void modbus_scope_tick(time_t period) // typically called from ISR
{
    uint16_t i;
    uint16_t sample;

    modbus_scope_period = period;
    modbus_scope_test_signal++; // overflow is ok

    if(modbus_scope_running >= 1) // put samples while running >= 1
    {
        if(scope_downsample_counter == 0)
        {
            scope_clock += modbus_scope_downsample;

            //if(FIFO_EMPTY(scope_fifo)) 
            //    if(scope_state == SCOPE_ST_IDLE)
            //        fifo_start_clock = scope_clock;
            
            // Note: when fifo overflow happens we stop filling it
            // and wait till it is completely drained out into uart.
            // Then we continue filling the fifo from empty state.
            // We indicate the number of lost samples by providing 
            // fifo start clock at the beginning of each packet
            if(FIFO_FREE(scope_fifo) >= modbus_scope_num_ch)
            {
                if(!scope_overflow_flag) {
                    for(i=0; i<modbus_scope_num_ch; i++)
                    {
                        sample = modbus_read_reg(modbus_scope_ch[i]);
                        //sample = 4403 + i; //0x1133 for debug
                        FIFO_PUT_FAST(scope_fifo, sample);
                    }
                    fifo_clock += modbus_scope_downsample;
                    modbus_scope_fifo_level = FIFO_BUSY(scope_fifo);
                } else {
                    if(modbus_scope_running == 1) {
                        modbus_scope_running = 0; // stop scope
                    }
                }
            }
            else
            {
                scope_overflow_flag = 1;
                modbus_scope_overflow_cnt++;
                if(modbus_scope_running == 1) {
                    modbus_scope_running = 0; // stop scope
                }
            }
        }
    }
    else
    {
        FIFO_INIT(scope_fifo);
        fifo_clock = 0;
        scope_clock++;
        modbus_scope_fifo_level = 0;
        scope_overflow_flag = 0;
    }

    scope_downsample_counter++;
    if(scope_downsample_counter >= modbus_scope_downsample)
    {
        scope_downsample_counter = 0;
    }
}

#else //MODBUS_SCOPE_ENANBLED

//-------------------------------------------------------------------
uint16_t modbus_scope_running = 0;

//-------------------------------------------------------------------
int modbus_scope_is_idle()
{
    return 1;
}

//-------------------------------------------------------------------
void modbus_scope_tick(time_t period)
{
}

#endif //MODBUS_SCOPE_ENANBLED

