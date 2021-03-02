#include "mcu.h"
#include "eeprom.h" // error codes
#include "eeprom_dummy.h"
//#include "gpio.h"
//#include "const.h" // count(x)
#include "pt.h"
#include "timer.h"
#include "watchdog.h"
#include "config.h"

//-------------------------------------------------------------------
#ifndef NULL
#define NULL 0
#endif

//-------------------------------------------------------------------
int16_t eeprom_status = EEPROM_NEED_INIT;
uint16_t eeprom_errors = 0;

//-------------------------------------------------------------------
static int16_t eeprom_lock = 0;

// API
//-------------------------------------------------------------------
int16_t eeprom_init()
{
    eeprom_lock = 0;

    // consider eeprom not found
    eeprom_errors++;
    eeprom_status = EEPROM_NOT_FOUND;

    return eeprom_status;
}

//-------------------------------------------------------------------
static PT_THREAD(eeprom_ready_task(PT *pt, int16_t *status))
{
    PT_BEGIN(pt);
    eeprom_status = *status = EEPROM_NOT_FOUND;
    PT_END(pt);
}

// physical read
//-------------------------------------------------------------------
static PT_THREAD(eeprom_read_task(PT *pt, uint16_t address, uint8_t *buf, uint16_t len, int16_t *status))
{
    PT_BEGIN(pt);
    eeprom_status = *status = EEPROM_NOT_FOUND;
    PT_END(pt);
}

// physical write
//-------------------------------------------------------------------
static PT_THREAD(eeprom_write_task(PT *pt, uint16_t address, uint8_t *buf, uint16_t len, int16_t *status))
{
    PT_BEGIN(pt);
    eeprom_status = *status = EEPROM_NOT_FOUND;
    PT_END(pt);
}

// full chip erase by writing 0xFFFF
//-------------------------------------------------------------------
static PT_THREAD(eeprom_erase_all_task(PT *pt, int16_t *status))
{
    PT_BEGIN(pt);
    eeprom_status = *status = EEPROM_NOT_FOUND;
    PT_END(pt);
}

//-------------------------------------------------------------------
static int16_t eeprom_try_lock()
{
    if(!eeprom_lock) {
        eeprom_lock = 1;
        return 1;
    }
    return 0;
}

// non blocking API functions with lock
//-------------------------------------------------------------------
PT_THREAD(eeprom_ready_nb(PT *pt, int16_t *status))
{
    static PT pt_child;
    PT_BEGIN(pt);
    PT_WAIT_UNTIL(pt, eeprom_try_lock());
    PT_SPAWN(pt, &pt_child, eeprom_ready_task(&pt_child, status));
    eeprom_lock = 0;
    PT_END(pt);
}

//-------------------------------------------------------------------
PT_THREAD(eeprom_read_nb(PT *pt, uint16_t address, uint8_t *buf, uint16_t len, int16_t *status))
{
    static PT pt_child;
    PT_BEGIN(pt);
    PT_WAIT_UNTIL(pt, eeprom_try_lock());
    PT_SPAWN(pt, &pt_child, eeprom_read_task(&pt_child, address, buf, len, status));
    eeprom_lock = 0;
    PT_END(pt);
}

//-------------------------------------------------------------------
PT_THREAD(eeprom_write_nb(PT *pt, uint16_t address, uint8_t *buf, uint16_t len, int16_t *status))
{
    static PT pt_child;
    PT_BEGIN(pt);
    PT_WAIT_UNTIL(pt, eeprom_try_lock());
    PT_SPAWN(pt, &pt_child, eeprom_write_task(&pt_child, address, buf, len, status));
    eeprom_lock = 0;
    PT_END(pt);
}

//-------------------------------------------------------------------
PT_THREAD(eeprom_erase_all_nb(PT *pt, int16_t *status))
{
    static PT pt_child;
    PT_BEGIN(pt);
    PT_WAIT_UNTIL(pt, eeprom_try_lock());
    PT_SPAWN(pt, &pt_child, eeprom_erase_all_task(&pt_child, status));
    eeprom_lock = 0;
    PT_END(pt);
}

//-------------------------------------------------------------------
int16_t eeprom_ready()
{
    PT pt_child;
    int16_t status;
    PT_INIT(&pt_child);
    while(eeprom_ready_nb(&pt_child, &status) < PT_EXITED) {
        wdog_feed();
    }
    return status;
}

//-------------------------------------------------------------------
int16_t eeprom_read(uint16_t address, uint8_t *buf, uint16_t len)
{
    PT pt_child;
    int16_t status;
    PT_INIT(&pt_child);
    while(eeprom_read_nb(&pt_child, address, buf, len, &status) < PT_EXITED) {
        wdog_feed();
    }
    return status;
}

//-------------------------------------------------------------------
int16_t eeprom_write(uint16_t address, uint8_t *buf, uint16_t len)
{
    PT pt_child;
    int16_t status;
    PT_INIT(&pt_child);
    while(eeprom_write_nb(&pt_child, address, buf, len, &status) < PT_EXITED) {
        wdog_feed();
    }
    return status;
}

//-------------------------------------------------------------------
int16_t eeprom_erase_all()
{
    PT pt_child;
    int16_t status;
    PT_INIT(&pt_child);
    while(eeprom_erase_all_nb(&pt_child, &status) < PT_EXITED) {
        wdog_feed();
    }
    return status;
}
