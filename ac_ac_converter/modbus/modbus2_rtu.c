#include "modbus.h"
#include "modbus2_rtu.h"
#include "modbus_crc16.h"
#include "gpio.h" // rs485_tx
#include "iqmath.h"
#include "time_defs.h"
#include "timer.h"
#include "pt.h"

//-------------------------------------------------------------------
#define MODBUS2_BUF_SIZE   (MODBUS_MAX_PDU_LENGTH + 3)

//-------------------------------------------------------------------
//defined in modbus_slave (or modbus_master [not implemented])
extern PT_THREAD(task_modbus_process_pdu(PT *pt, uint8_t *pdu, uint16_t *p_len, int16_t *p_status, int uart_number));

//-------------------------------------------------------------------
uint16_t modbus2_rx_cnt = 0;
uint16_t modbus2_rx_good_cnt = 0;
uint16_t modbus2_rx_local_cnt = 0;
uint16_t modbus2_rx_short_cnt = 0; // too short
uint16_t modbus2_rx_other_addr_cnt = 0;
uint16_t modbus2_rx_broadcast_cnt = 0;
uint16_t modbus2_rx_badcrc_cnt = 0;
uint16_t modbus2_rx_broken_cnt = 0;
uint16_t modbus2_rx_lost_cnt = 0;
uint16_t modbus2_tx_cnt = 0;

//-------------------------------------------------------------------
static int modbus2_rtu_uart_number = 0;

//-------------------------------------------------------------------
static uint8_t modbus2_packet1[MODBUS2_BUF_SIZE];
static uint8_t modbus2_packet2[MODBUS2_BUF_SIZE];

static uint8_t *modbus2_packet_rx = modbus2_packet1;
static uint16_t modbus2_packet_rx_len = 0;

static uint8_t *modbus2_packet_tx = modbus2_packet2;
static uint16_t modbus2_packet_tx_len = 0;

//-------------------------------------------------------------------
static int16_t modbus2_rx_idle = 0;
static int16_t modbus2_tx_idle = 0;
static int16_t modbus2_tx_request = 0;

static PT pt_modbus2_rtu_rx;
static PT pt_modbus2_rtu_tx;

//-------------------------------------------------------------------
static uint16_t modbus2_device_address = 0;

//-------------------------------------------------------------------
static time_t modbus2_t15 = TIME_SEC(0.0); // configured at runtime
static time_t modbus2_t35 = TIME_SEC(0.0); // configured at runtime
static uint32_t modbus2_baudrate = 0;
static int16_t modbus2_calc_timeouts(int uart_number);

static time_t modbus2_tx_timeout = TIME_MSEC(100.0); // detect tx stuck, calculated

//-------------------------------------------------------------------
void modbus2_rtu_init(int uart_number, uint16_t device_address, UART_OPTIONS *uart_opts)
{
    UART_OPTIONS opts;

    modbus2_rtu_set_address(device_address);

    modbus2_rtu_uart_number = uart_number;

    PT_INIT(&pt_modbus2_rtu_rx);
    PT_INIT(&pt_modbus2_rtu_tx);

    modbus2_t15 = TIME_SEC(0.0); // calculated later
    modbus2_t35 = TIME_SEC(0.0); // calculated later

    if(uart_opts == 0)
    {
        uart_opts = &opts;
        // setup uart options explicitly
        uart_opts->baud_rate = 19200;
        uart_opts->stop_bits = UART_STOP_1;
        uart_opts->parity = UART_PARITY_EVEN;
    }
    uart_init(uart_number, uart_opts);
    modbus2_calc_timeouts(uart_number);
}

//-------------------------------------------------------------------
void modbus2_rtu_set_address(uint16_t device_address)
{
    if(device_address != 0)
    {
        modbus2_device_address = (device_address & 0xFF);
    }
}
//-------------------------------------------------------------------
static int16_t modbus2_calc_timeouts(int uart_number)
{
    uint32_t baud_rate;
    baud_rate = uart_get_baud_rate(uart_number);
    if(baud_rate == modbus2_baudrate) return 1;
    if(baud_rate)
    {
        if(baud_rate >= 19200)
        {
            // at baud rate 19200 or higher use fixed timeout
            modbus2_t15 = TIME_MSEC(0.75);
            modbus2_t35 = TIME_MSEC(1.75);
        }
        else
        {
            // 1 start, 8 bits data, [1 parity], 1 stop = 10 [11] bits
            modbus2_t15 = TIME_SEC(16.5) / baud_rate; // 1.5 * 11.0
            modbus2_t35 = TIME_SEC(38.5) / baud_rate; // 3.5 * 11.0
        }
        modbus2_tx_timeout = modbus2_t15 * MODBUS_MAX_PDU_LENGTH;
        modbus2_baudrate = baud_rate;
        return 1;
    }
    return 0;
}

//-------------------------------------------------------------------
static PT_THREAD(task_modbus2_rtu_process_packet(PT *pt, uint8_t *data, uint16_t *p_len, int16_t *p_status, int uart_number))
{
    static uint16_t len;
    static uint16_t modbus_addr;
    static uint16_t crc;
    static PT pt_child;
    static int16_t status;

    PT_BEGIN(pt);

    len = *p_len;
    *p_status = 0;
    
    if (len < 4) { // addr[1] + func[1] + crc[2] = 4 bytes minimum
        modbus2_rx_short_cnt++;
        PT_EXIT(pt);
    }
    modbus_addr = data[0];
    if (modbus_addr != 0) {
    #ifdef MODBUS2_RTU_LOCAL_ADDRESS
        if (modbus_addr == MODBUS2_RTU_LOCAL_ADDRESS) {
            modbus2_rx_local_cnt++;
        } else
    #endif
        if (modbus_addr != modbus2_device_address) {
            modbus2_rx_other_addr_cnt++;
            PT_EXIT(pt);
        }
    } else {
        modbus2_rx_broadcast_cnt++;
    }
    
    crc = MODBUS_GET_INT16_FROM_INT8(data, len-2);
    if (crc != modbus_crc16((uint8_t*)data, len-2)) {
        modbus2_rx_badcrc_cnt++;
        PT_EXIT(pt);
    }

    if(data[1] == MODBUS_FC_USER_SCOPE) {
        // suppress scope requests on modbus2
        data[1] |= 0x80;
        data[2] = MODBUS_EXCEPTION_ILLEGAL_FUNCTION;
        len = 2;
        status = 1;
    }
    else {
        len -= 3; // address and CRC not included
        PT_SPAWN(pt, &pt_child, task_modbus_process_pdu(&pt_child, &data[1], &len, &status, uart_number));
    }

    if(status)
    {
        // note: we make reply packet even for broadcast (modbus_addr=0)
        // thus we indicate everything is correct
        // but the reply must not be sent
        if(len > 0)
        {
            len += 1; // address included
            data[0] = modbus_addr; // same as in request (may be broadcast)
            crc = modbus_crc16((uint8_t*)data, len);
            MODBUS_SET_INT16_TO_INT8(data, len, crc);
            len += 2; // crc included
            *p_len = len;
            modbus2_rx_good_cnt++;
            *p_status = 1;
            PT_EXIT(pt);
        }
    }

    // no response

    PT_END(pt);
}

//-------------------------------------------------------------------
int modbus2_rtu_send_pdu(uint16_t device_address, uint8_t *pdu, uint16_t len)
{
    uint16_t i;
    uint16_t crc;
    
    device_address &= 0xFF;
    if (device_address == 0)
        return 0;
    if ((len == 0) || (len > MODBUS_MAX_PDU_LENGTH))
        return 0;
    if(!modbus2_tx_idle || modbus2_tx_request)
        return 0;
    
    modbus2_packet_tx[0] = device_address;
    for(i=1; i<=len; i++)
        modbus2_packet_tx[i] = *pdu++;
    len += 1; // address included

    crc = modbus_crc16((uint8_t*)modbus2_packet_tx, len);
    MODBUS_SET_INT16_TO_INT8(modbus2_packet_tx, len, crc);
    len += 2; // crc included
        
    modbus2_packet_tx_len = len;
    modbus2_tx_request = 1;

    return 0;
}

//-------------------------------------------------------------------
static PT_THREAD(task_modbus2_rtu_rx(PT *pt, int uart_number))
{
    static TIMER tim1;
    static time_t t35;
    static int16_t inter_char_timeout_flag;
    static uint16_t modbus_addr;
    static uint8_t byte;
    static uint16_t modbus2_packet_rx_pos;
    static PT pt_child;
    static int16_t status;
    static uint8_t *p_packet;
    //static int16_t i;

    PT_BEGIN(pt);

    modbus2_rx_idle = 0;

    t35 = modbus2_t35;
    if(t35 == TIME_SEC(0.0)) t35 = TIME_SEC(1.75e-3); // failsafe

    // wait for data pause
    while(1) {
        timer_set(&tim1, t35);
        PT_YIELD_UNTIL(pt, timer_expired(&tim1) || uart_rx_ready(uart_number));
        if(uart_rx_ready(uart_number)) {
            // read out data
            while(uart_rx_ready(uart_number)) {
                uart_read_byte(uart_number);
            }
            continue;
        }
        break;
    }

    while(1) {

        modbus2_rx_idle = 1;

        PT_YIELD_UNTIL(pt, uart_rx_ready(uart_number) || uart_errors(uart_number));
        if(uart_errors(uart_number))
        {
            // protect against BRKDT and framing errors in first byte
            // however let TX transaction finish before resetting uart
            if(modbus2_tx_idle) {
                uart_restart(uart_number, 0); // 0 - don't reinit hw
            }
            continue;
        }

        modbus2_rx_idle = 0;
        modbus2_packet_rx_pos = 0;
        modbus2_packet_rx_len = 0;

        modbus2_calc_timeouts(uart_number);

        while(1) {
            if(!uart_rx_ready(uart_number)) {
                timer_set(&tim1, modbus2_t15);
                PT_WAIT_UNTIL(pt, uart_rx_ready(uart_number) || timer_expired(&tim1));
                if(!uart_rx_ready(uart_number)) {
                    // t1.5 pause detected
                    tim1.interval = modbus2_t35;
                    break;
                }
            }

            // receive request
            while(uart_rx_ready(uart_number))
            {
                byte = uart_read_byte(uart_number);
                if(modbus2_packet_rx_pos < MODBUS2_BUF_SIZE) {
                    // put incoming data into packet
                    modbus2_packet_rx[modbus2_packet_rx_pos++] = byte;
                }
            }
        }

        inter_char_timeout_flag = 0;

        while(1) {
            PT_WAIT_UNTIL(pt, uart_rx_ready(uart_number) || timer_expired(&tim1));
            if(uart_rx_ready(uart_number)) {
                while(uart_rx_ready(uart_number))
                {
                    // important to read out the data
                    byte = uart_read_byte(uart_number);
                }
                timer_set(&tim1, modbus2_t35); // timer restart
                inter_char_timeout_flag = 1;
                continue;
            }
            break; //t3.5 expired
        }

        // timeout means end of message, process input packet
        if(!modbus2_packet_rx_pos) continue; // no data

        modbus2_packet_rx_len = modbus2_packet_rx_pos;
        modbus2_rx_cnt++;

        if(inter_char_timeout_flag
           //|| uart_errors(uart_number) // parity error check is here
          )
        {
            modbus2_rx_broken_cnt++;
            continue;
        }

        PT_SPAWN(pt, &pt_child, task_modbus2_rtu_process_packet(&pt_child,
                                                                modbus2_packet_rx,
                                                                &modbus2_packet_rx_len,
                                                                &status,
                                                                uart_number));

        if(status)
        {
            modbus_addr = modbus2_packet_rx[0]; // & 0xFF;
            if(modbus_addr != 0) // broadcast will not get reply
            {
                timer_set(&tim1, modbus2_tx_timeout);
                PT_WAIT_UNTIL(pt, (modbus2_tx_idle && !modbus2_tx_request) || timer_expired(&tim1));

                if(modbus2_tx_idle && !modbus2_tx_request) {
                    // copy response to tx buffer and request tx
                    //for(i=0; i<modbus2_packet_rx_len; i++) modbus2_packet_tx[i] = modbus2_packet_rx[i];

                    // swap rx and tx packets (avoid copying)
                    p_packet = modbus2_packet_tx;
                    modbus2_packet_tx = modbus2_packet_rx;
                    modbus2_packet_rx = p_packet;

                    modbus2_packet_tx_len = modbus2_packet_rx_len;
                    modbus2_tx_request = 1;
                } else {
                    modbus2_rx_lost_cnt++; // lost because tx is busy for a long time
                }
            }
        }
    }

    PT_END(pt);
}

//-------------------------------------------------------------------
static PT_THREAD(task_modbus2_rtu_tx(PT *pt, int uart_number))
{
    static TIMER tim1;
    static uint16_t modbus2_packet_tx_pos;

    PT_BEGIN(pt);

    while(1) {

        modbus2_tx_idle = 1;
        PT_YIELD_UNTIL(pt, modbus2_tx_request);

        modbus2_tx_idle = 0;
        modbus2_packet_tx_pos = 0;

        gpio_rs485_tx(uart_number, ON);

        timer_set(&tim1, TIME_MSEC(0.5)); //modbus2_t15
        modbus2_calc_timeouts(uart_number);
        PT_WAIT_UNTIL(pt, timer_expired(&tim1));

        while(modbus2_packet_tx_pos < modbus2_packet_tx_len)
        {
            if(!uart_tx_ready(uart_number))
            {
                timer_set(&tim1, modbus2_tx_timeout);
                PT_WAIT_UNTIL(pt, uart_tx_ready(uart_number) || timer_expired(&tim1));
                if(!uart_tx_ready(uart_number))
                {
                    // hardware stuck
                    uart_restart(uart_number, 0); // 0 - don't reinit hw
                    break;
                }
            }
            uart_write_byte(uart_number, modbus2_packet_tx[modbus2_packet_tx_pos++]);
        }

        if(modbus2_packet_tx_pos >= modbus2_packet_tx_len)
        {
            timer_set(&tim1, modbus2_tx_timeout);
            PT_WAIT_UNTIL(pt, uart_tx_done(uart_number) || timer_expired(&tim1));
            if(timer_expired(&tim1) && !uart_tx_done(uart_number)) {
                // hardware stuck
                uart_restart(uart_number, 0); // 0 - don't reinit hw
            } else {
                // data physically sent out (including shift register)
                modbus2_tx_cnt++;
            }
        }

        timer_set(&tim1, modbus2_t35);
        PT_WAIT_UNTIL(pt, timer_elapsed(&tim1) >= TIME_MSEC(1.0));
        gpio_rs485_tx(uart_number, OFF);
        PT_WAIT_UNTIL(pt, timer_expired(&tim1));

        modbus2_tx_request = 0;
    }

    PT_END(pt);
}

//-------------------------------------------------------------------
void modbus2_rtu_task()
{
    task_modbus2_rtu_rx(&pt_modbus2_rtu_rx, modbus2_rtu_uart_number);
    task_modbus2_rtu_tx(&pt_modbus2_rtu_tx, modbus2_rtu_uart_number);

    if(modbus2_rx_idle && modbus2_tx_idle) {
        gpio_rs485_tx(modbus2_rtu_uart_number, OFF); // failsafe, be ready for RX
    }
}
