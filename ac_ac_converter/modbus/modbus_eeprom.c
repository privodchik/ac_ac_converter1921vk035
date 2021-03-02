#include "stdint_ext.h"
#include "eeprom.h"
#include "modbus_regs.h"
#include "modbus_eeprom.h"
//#include "const.h" // count(x)
#include "config.h"
#include "pt.h"
#include "timer.h"
#include "watchdog.h"

//-------------------------------------------------------------------
#define USE_ADDR_TRANSLATION     0   // must use for small eeprom
                                     // still good for medium size eeprom

//-------------------------------------------------------------------
#define EMPTY_ADDR       0xFFFF
#define EMPTY_VALUE      0xFFFF

//-------------------------------------------------------------------
int16_t modbus_eeprom_read_all_request = 0;
int16_t modbus_eeprom_write_all_request = 0;
int16_t modbus_eeprom_erase_all_request = 0;
int16_t modbus_eeprom_erase_all_polite_request = 0;

int16_t modbus_eeprom_read_all_status = 0;
int16_t modbus_eeprom_write_all_status = 0;
int16_t modbus_eeprom_erase_all_status = 0;
int16_t modbus_eeprom_erase_all_polite_status = 0;

int16_t modbus_eeprom_status = 0;

int16_t modbus_eeprom_need_erase = 0;

static PT pt_modbus_eeprom;

static int16_t write_delayed_status = EEPROM_OK;
static uint16_t write_delayed_enabled = 1;
static uint16_t write_delayed_pending = 0;
static uint16_t write_delayed_reg16_addr;
static uint16_t write_delayed_value;
static uint16_t write_delayed_lost_cnt = 0;

//-------------------------------------------------------------------
#if USE_ADDR_TRANSLATION

static uint16_t addr_tbl[(EEPROM_SIZE_BYTES-EEPROM_RESERVED_BYTES)/4]; // the table is sorted
static int16_t addr_tbl_count = 0;

static int16_t addr_translation_init(void) {
    uint16_t reg_addr;
    const MODBUS_REG *reg;
    uint16_t i;
    for(i=0; i<count(addr_tbl); i++) addr_tbl[i] = 0xFFFF;
    addr_tbl_count = 0;
    for(reg_addr=0; reg_addr<modbus_holding_regs_count; reg_addr++)
    {
        reg = &modbus_holding_regs[reg_addr];
        if(reg->type & PROM_FLAG)
        {
            if(addr_tbl_count >= count(addr_tbl)) {
                addr_tbl_count = -1;
                return EEPROM_FULL;
            }
            addr_tbl[addr_tbl_count] = reg_addr;
            addr_tbl_count++;
        }
    }
    return EEPROM_OK;
}
#endif //USE_ADDR_TRANSLATION

//-------------------------------------------------------------------
static int16_t reg16_addr_to_eeprom_addr(uint16_t reg16_addr, uint16_t *eeprom_addr)
{
#if USE_ADDR_TRANSLATION
#if 0
    uint16_t i;
    if(addr_tbl_count > 0) {
        // direct table search (slow)
        for(i=0; i<(uint16_t)addr_tbl_count; i++) {
            if(addr_tbl[i] == reg16_addr) {
                *eeprom_addr = (i<<2);
                return 1;
            }
        }
    }
#else
    uint16_t i, i1, i2;
    if(addr_tbl_count > 0) {
        //optimized search in sorted table
        i1 = 0;
        i2 = (uint16_t)addr_tbl_count;
        while(1) {
            i = i1 + ((i2 - i1) >> 1);
            if(reg16_addr == addr_tbl[i]) {
                *eeprom_addr = (i<<2);
                return 1;
            } else
            if(i2 - i1 < 2) {
                break; // not found
            }
            if(reg16_addr > addr_tbl[i]) {
                i1 = i;
            } else
            //if(reg16_addr < addr_tbl[i])
            {
                i2 = i;
            }
        }
    }
#endif
    *eeprom_addr = 0xFFFF;
    return 0;
#else
    *eeprom_addr = (reg16_addr << 2);
    return 1;
#endif
}

//-------------------------------------------------------------------
int16_t modbus_eeprom_init()
{
    PT_INIT(&pt_modbus_eeprom);
    modbus_eeprom_need_erase = 0;
#if USE_ADDR_TRANSLATION
    int16_t status;
    status = addr_translation_init();
    if(status != EEPROM_OK) return status;
#endif
    return eeprom_init();
}

//-------------------------------------------------------------------
PT_THREAD(modbus_eeprom_read_nb(PT *pt, uint16_t reg16_addr, uint16_t *pvalue, int16_t *status))
{
    static PT pt_child;
    static uint8_t buf[4];
    static uint16_t eeprom_addr;
    static uint16_t addr;
    static uint16_t value;

    PT_BEGIN(pt);

    if(!reg16_addr_to_eeprom_addr(reg16_addr, &eeprom_addr)) {
        *status = EEPROM_WRONG_ADDRESS;
        PT_EXIT(pt);
    }

    PT_SPAWN(pt, &pt_child, eeprom_read_nb(&pt_child, eeprom_addr, buf, 4, status));

    if(*status != EEPROM_OK) {
        PT_EXIT(pt);
    }

    addr  = ((buf[0] << 8) & 0xFF00) | (buf[1] & 0x00FF);
    value = ((buf[2] << 8) & 0xFF00) | (buf[3] & 0x00FF);

    if((addr == EMPTY_ADDR) && (value == EMPTY_VALUE)) {
        *pvalue = EMPTY_VALUE;
        *status = EEPROM_EMPTY;
        PT_EXIT(pt);
    }

    if(addr != reg16_addr) {
        *pvalue = EMPTY_VALUE;
        *status = EEPROM_NEED_ERASE;
        modbus_eeprom_need_erase = 1;
        PT_EXIT(pt);
    }

    *pvalue = value;
    *status = EEPROM_OK;

    PT_END(pt);
}

//-------------------------------------------------------------------
PT_THREAD(modbus_eeprom_write_nb(PT *pt, uint16_t reg16_addr, uint16_t value, int16_t *status))
{
    static PT pt_child;
    static uint8_t buf[4];
    static uint16_t eeprom_addr;
    static int16_t read_status;
    static uint16_t read_value;

    PT_BEGIN(pt);

    // don't write same value (this is faster to check than to write)
    PT_SPAWN(pt, &pt_child, modbus_eeprom_read_nb(&pt_child, reg16_addr, &read_value, &read_status));
    if(read_status == EEPROM_OK) {
        if(read_value == value) {
            *status = EEPROM_OK;
            PT_EXIT(pt);
        }
    }

    if(!reg16_addr_to_eeprom_addr(reg16_addr, &eeprom_addr)) {
        *status = EEPROM_WRONG_ADDRESS;
        PT_EXIT(pt);
    }

    buf[0] = (reg16_addr >> 8) & 0x00FF; // MSB
    buf[1] = reg16_addr & 0x00FF; // LSB
    buf[2] = (value >> 8) & 0x00FF; // MSB
    buf[3] = value & 0x00FF; // LSB

    PT_SPAWN(pt, &pt_child, eeprom_write_nb(&pt_child, eeprom_addr, buf, 4, status));

    if(*status != EEPROM_OK) {
        PT_EXIT(pt);
    }

    // double check by reading
    PT_SPAWN(pt, &pt_child, modbus_eeprom_read_nb(&pt_child, reg16_addr, &read_value, &read_status));

    if(read_status != EEPROM_OK) {
        *status = read_status;
        PT_EXIT(pt);
    }

    if(read_value != value) {
        *status = EEPROM_ERROR;
        PT_EXIT(pt);
    }

    *status = EEPROM_OK;

    PT_END(pt);
}

//-------------------------------------------------------------------
PT_THREAD(modbus_eeprom_erase_nb(PT *pt, uint16_t reg16_addr, int16_t *status))
{
    static PT pt_child;
    static uint8_t buf[4];
    static uint16_t eeprom_addr;
    static int16_t read_status;
    static uint16_t read_value;

    PT_BEGIN(pt);

    // don't erase empty register (this is faster to check than to erase)
    PT_SPAWN(pt, &pt_child, modbus_eeprom_read_nb(&pt_child, reg16_addr, &read_value, &read_status));
    if(read_status == EEPROM_EMPTY) {
        *status = EEPROM_OK;
        PT_EXIT(pt);
    }

    if(!reg16_addr_to_eeprom_addr(reg16_addr, &eeprom_addr)) {
        *status = EEPROM_WRONG_ADDRESS;
        PT_EXIT(pt);
    }

    buf[0] = 0xFF;
    buf[1] = 0xFF;
    buf[2] = 0xFF;
    buf[3] = 0xFF;

    PT_SPAWN(pt, &pt_child, eeprom_write_nb(&pt_child, eeprom_addr, buf, 4, status));

    if(*status != EEPROM_OK) {
        PT_EXIT(pt);
    }

    // double check by reading
    PT_SPAWN(pt, &pt_child, modbus_eeprom_read_nb(&pt_child, reg16_addr, &read_value, &read_status));

    if(read_status != EEPROM_EMPTY) {
        if(read_status != EEPROM_OK) *status = read_status;
        else *status = EEPROM_ERROR;
        PT_EXIT(pt);
    }

    *status = EEPROM_OK;

    PT_END(pt);
}

//-------------------------------------------------------------------
PT_THREAD(modbus_eeprom_read_all_nb(PT *pt, int16_t *status))
{
    static PT pt_child;
    static uint16_t reg_addr;
    static int16_t read_status;
    static uint16_t value;
    static int16_t read_cnt;
    static const MODBUS_REG *reg;
    static int16_t modbus_regs_mode_saved;

    PT_BEGIN(pt);

    // prepare for modbus_write_reg
    modbus_regs_mode_saved = modbus_regs_mode;
    modbus_regs_mode = MODBUS_REGS_MODE_FACTORY;

    read_cnt = 0;
    for(reg_addr=0; reg_addr<modbus_holding_regs_count; reg_addr++)
    {
        reg = &modbus_holding_regs[reg_addr];
        if(reg->type & PROM_FLAG)
        {
            PT_SPAWN(pt, &pt_child, modbus_eeprom_read_nb(&pt_child, reg_addr, &value, &read_status));
            if(EEPROM_OK == read_status)
            {
                read_cnt++;
                modbus_eeprom_write_delayed_disable();
                modbus_write_reg(reg_addr, value); // callback may call eeprom write delayed
                modbus_eeprom_write_delayed_enable();
                // modbus_write_reg into password may have changed modbus_regs_mode
                // restore back to factory
                modbus_regs_mode = MODBUS_REGS_MODE_FACTORY;
                continue; // this is ok
            }
            if(EEPROM_EMPTY == read_status) {
                continue; // this is ok
            }

            modbus_regs_mode = modbus_regs_mode_saved;
            *status = read_status;
            PT_EXIT(pt);
        }
    }

    modbus_regs_mode = modbus_regs_mode_saved;

    if(read_cnt > 0) *status = EEPROM_OK;
    else *status = EEPROM_EMPTY;

    PT_END(pt);
}

#if USE_ADDR_TRANSLATION
//-------------------------------------------------------------------
static PT_THREAD(modbus_eeprom_write_page_nb(PT *pt, uint16_t eeprom_addr, uint8_t *page, uint16_t nbytes, int16_t *status))
{
    static PT pt_child;
    static uint8_t page_check[EEPROM_PAGE_BYTES];
    static uint16_t i;

    PT_BEGIN(pt);

    PT_SPAWN(pt, &pt_child, eeprom_write_nb(&pt_child, eeprom_addr, page, nbytes, status));

    if(*status != EEPROM_OK) {
        PT_EXIT(pt);
    }

    // double check by reading
    PT_SPAWN(pt, &pt_child, eeprom_read_nb(&pt_child, eeprom_addr, page_check, nbytes, status));

    if(*status != EEPROM_OK) {
        PT_EXIT(pt);
    }

    for(i=0; i<nbytes; i++) {
        if(page_check[i] != page[i]) {
            *status = EEPROM_ERROR;
            PT_EXIT(pt);
        }
    }

    *status = EEPROM_OK;

    PT_END(pt);
}
#endif //USE_ADDR_TRANSLATION

//-------------------------------------------------------------------
PT_THREAD(modbus_eeprom_write_all_nb(PT *pt, int16_t *status))
{
    static PT pt_child;
    static uint16_t reg_addr;
    static uint16_t value;
    static const MODBUS_REG *reg;
#if USE_ADDR_TRANSLATION
    static int16_t i;
    static uint8_t page[EEPROM_PAGE_BYTES];
    static uint16_t eeprom_addr;
    static uint16_t page_number;
    static uint16_t page_pos;
#else
    static int16_t write_status;
#endif

    PT_BEGIN(pt);

#if USE_ADDR_TRANSLATION
    // optimized version
    if(addr_tbl_count <= 0) {
        *status = EEPROM_ERROR;
        PT_EXIT(pt);
    }

    page_number = 0;
    page_pos = 0;
    for(i=0; i<addr_tbl_count; i++) {
        reg_addr = addr_tbl[i];
        reg = &modbus_holding_regs[reg_addr];
        if(reg->type & PROM_FLAG)
        {
            value = modbus_read_reg(reg_addr);
            page[page_pos++] = (reg_addr >> 8) & 0x00FF; // MSB
            page[page_pos++] = reg_addr & 0x00FF; // LSB
            page[page_pos++] = (value >> 8) & 0x00FF; // MSB
            page[page_pos++] = value & 0x00FF; // LSB
            if(page_pos >= EEPROM_PAGE_BYTES) { // full page
                // write
                eeprom_addr = page_number * EEPROM_PAGE_BYTES;
                PT_SPAWN(pt, &pt_child, modbus_eeprom_write_page_nb(&pt_child, eeprom_addr, page, page_pos, status));
                if(*status != EEPROM_OK) {
                    PT_EXIT(pt);
                }
                // begin new page
                page_number++;
                page_pos = 0;
            }
        }
    }
    if(page_pos > 0) {
        // write last page
        eeprom_addr = page_number * EEPROM_PAGE_BYTES;
        PT_SPAWN(pt, &pt_child, modbus_eeprom_write_page_nb(&pt_child, eeprom_addr, page, page_pos, status));
        if(*status != EEPROM_OK) {
            PT_EXIT(pt);
        }
    }

#else
    for(reg_addr=0; reg_addr<modbus_holding_regs_count; reg_addr++)
    {
        reg = &modbus_holding_regs[reg_addr];
        if(reg->type & PROM_FLAG)
        {
            value = modbus_read_reg(reg_addr);
            PT_SPAWN(pt, &pt_child, modbus_eeprom_write_nb(&pt_child, reg_addr, value, &write_status));
            if(EEPROM_OK != write_status) {
                *status = write_status;
                PT_EXIT(pt);
            }
        }
    }
#endif

    *status = EEPROM_OK;

    PT_END(pt);
}

//-------------------------------------------------------------------
PT_THREAD(modbus_eeprom_erase_all_nb(PT *pt, int16_t *status))
{
    static PT pt_child;
#if USE_ADDR_TRANSLATION
    static int16_t i, j;
    static uint8_t page[EEPROM_PAGE_BYTES];
    static uint16_t eeprom_addr;
    static uint16_t page_number;
    static uint16_t page_pos;
#endif

    PT_BEGIN(pt);

#if USE_ADDR_TRANSLATION
    // optimized version
    if(addr_tbl_count <= 0) {
        *status = EEPROM_ERROR;
        PT_EXIT(pt);
    }

    page_number = 0;
    page_pos = 0;
    for(i=0; i<addr_tbl_count; i++) {
        page_pos += 4;
        if(page_pos >= EEPROM_PAGE_BYTES) { // full page
            // write
            eeprom_addr = page_number * EEPROM_PAGE_BYTES;
            if(eeprom_addr + page_pos > EEPROM_SIZE_BYTES - EEPROM_RESERVED_BYTES) {
                page_pos = EEPROM_SIZE_BYTES - EEPROM_RESERVED_BYTES - eeprom_addr;
            }
            if(page_pos > 0) {
                for(j=0; j<page_pos; j++) page[j] = 0xFF;
                PT_SPAWN(pt, &pt_child, modbus_eeprom_write_page_nb(&pt_child, eeprom_addr, page, page_pos, status));
                if(*status != EEPROM_OK) {
                    PT_EXIT(pt);
                }
            }
            // begin new page
            page_number++;
            page_pos = 0;
        }
    }
    if(page_pos > 0) { // last page
        // write
        eeprom_addr = page_number * EEPROM_PAGE_BYTES;
        if(eeprom_addr + page_pos > EEPROM_SIZE_BYTES - EEPROM_RESERVED_BYTES) {
            page_pos = EEPROM_SIZE_BYTES - EEPROM_RESERVED_BYTES - eeprom_addr;
        }
        if(page_pos > 0) {
            for(j=0; j<page_pos; j++) page[j] = 0xFF;
            PT_SPAWN(pt, &pt_child, modbus_eeprom_write_page_nb(&pt_child, eeprom_addr, page, page_pos, status));
            if(*status != EEPROM_OK) {
                PT_EXIT(pt);
            }
        }
    }

    *status = EEPROM_OK;

#else
    PT_SPAWN(pt, &pt_child, eeprom_erase_all_nb(&pt_child, status));
#endif

    PT_END(pt);
}

//-------------------------------------------------------------------
PT_THREAD(modbus_eeprom_erase_all_polite_nb(PT *pt, int16_t *status))
{
    static uint16_t reg_addr;
    static const MODBUS_REG *reg;
    static PT pt_child;
#if USE_ADDR_TRANSLATION
    static int16_t i;
    static uint8_t page[EEPROM_PAGE_BYTES];
    static uint16_t eeprom_addr;
    static uint16_t page_number;
    static uint16_t page_pos;
    static uint16_t page_valid;
    static uint16_t page_modified;
#else
    static int16_t erase_status;
#endif

    PT_BEGIN(pt);

#if USE_ADDR_TRANSLATION
    // optimized version
    if(addr_tbl_count <= 0) {
        *status = EEPROM_ERROR;
        PT_EXIT(pt);
    }

    page_number = 0;
    page_pos = 0;
    page_valid = 0;
    for(i=0; i<addr_tbl_count; i++) {

        if(page_pos >= EEPROM_PAGE_BYTES) { // full page
            if(page_modified) {
                // write
                eeprom_addr = page_number * EEPROM_PAGE_BYTES;
                if(eeprom_addr + page_pos > EEPROM_SIZE_BYTES - EEPROM_RESERVED_BYTES) {
                    page_pos = EEPROM_SIZE_BYTES - EEPROM_RESERVED_BYTES - eeprom_addr;
                }
                PT_SPAWN(pt, &pt_child, modbus_eeprom_write_page_nb(&pt_child, eeprom_addr, page, page_pos, status));
                if(*status != EEPROM_OK) {
                    PT_EXIT(pt);
                }
            }
            // begin new page
            page_number++;
            page_valid = 0;
        }

        if(!page_valid) {
            eeprom_addr = page_number * EEPROM_PAGE_BYTES;
            PT_SPAWN(pt, &pt_child, eeprom_read_nb(&pt_child, eeprom_addr, page, EEPROM_PAGE_BYTES, status));
            if(*status != EEPROM_OK) {
                PT_EXIT(pt);
            }
            page_valid = 1;
            page_pos = 0;
            page_modified = 0;
        }

        reg_addr = addr_tbl[i];
        reg = &modbus_holding_regs[reg_addr];

        if(reg->type & FACTORY_FLAG)
            if(modbus_regs_mode < MODBUS_REGS_MODE_FACTORY) {
                page_pos += 4;
                continue; // don't touch factory data
            }

        if(reg->type & ENGINEER_FLAG)
            if(modbus_regs_mode < MODBUS_REGS_MODE_ENGINEER) {
                page_pos += 4;
                continue; // don't touch engineer data
            }

        if(reg->type & PROM_FLAG)
        {
            if(page[page_pos] != 0xFF) page_modified = 1;
            page[page_pos++] = 0xFF;
            if(page[page_pos] != 0xFF) page_modified = 1;
            page[page_pos++] = 0xFF;
            if(page[page_pos] != 0xFF) page_modified = 1;
            page[page_pos++] = 0xFF;
            if(page[page_pos] != 0xFF) page_modified = 1;
            page[page_pos++] = 0xFF;
        }
    }
    if(page_pos > 0) {
        if(page_modified) {
            // write last page
            eeprom_addr = page_number * EEPROM_PAGE_BYTES;
            if(eeprom_addr + page_pos > EEPROM_SIZE_BYTES - EEPROM_RESERVED_BYTES) {
                page_pos = EEPROM_SIZE_BYTES - EEPROM_RESERVED_BYTES - eeprom_addr;
            }
            PT_SPAWN(pt, &pt_child, modbus_eeprom_write_page_nb(&pt_child, eeprom_addr, page, page_pos, status));
            if(*status != EEPROM_OK) {
                PT_EXIT(pt);
            }
        }
    }

#else
    for(reg_addr=0; reg_addr<modbus_holding_regs_count; reg_addr++)
    {
        reg = &modbus_holding_regs[reg_addr];

        if(reg->type & FACTORY_FLAG)
            if(modbus_regs_mode < MODBUS_REGS_MODE_FACTORY)
                continue; // don't touch factory data

        if(reg->type & ENGINEER_FLAG)
            if(modbus_regs_mode < MODBUS_REGS_MODE_ENGINEER)
                continue; // don't touch engineer data

        if(reg->type & PROM_FLAG)
        {
            PT_SPAWN(pt, &pt_child, modbus_eeprom_erase_nb(&pt_child, reg_addr, &erase_status));
            if(EEPROM_OK != erase_status) {
                *status = erase_status;
                PT_EXIT(pt);
            }
        }
    }
#endif

    *status = EEPROM_OK;

    PT_END(pt);
}

//-------------------------------------------------------------------
int16_t modbus_eeprom_read(uint16_t reg16_addr, uint16_t *pvalue)
{
    PT pt_child;
    int16_t status;
    PT_INIT(&pt_child);
    while(modbus_eeprom_read_nb(&pt_child, reg16_addr, pvalue, &status) < PT_EXITED) {
        wdog_feed();
    }
    return status;
}

//-------------------------------------------------------------------
int16_t modbus_eeprom_write(uint16_t reg16_addr, uint16_t value)
{
    PT pt_child;
    int16_t status;
    PT_INIT(&pt_child);
    while(modbus_eeprom_write_nb(&pt_child, reg16_addr, value, &status) < PT_EXITED) {
        wdog_feed();
    }
    return status;
}

//-------------------------------------------------------------------
int16_t modbus_eeprom_erase(uint16_t reg16_addr)
{
    PT pt_child;
    int16_t status;
    PT_INIT(&pt_child);
    while(modbus_eeprom_erase_nb(&pt_child, reg16_addr, &status) < PT_EXITED) {
        wdog_feed();
    }
    return status;
}

//-------------------------------------------------------------------
int16_t modbus_eeprom_read_all()
{
    PT pt_child;
    int16_t status;
    PT_INIT(&pt_child);
    while(modbus_eeprom_read_all_nb(&pt_child, &status) < PT_EXITED) {
        wdog_feed();
    }
    return status;
}

//-------------------------------------------------------------------
int16_t modbus_eeprom_write_all()
{
    PT pt_child;
    int16_t status;
    PT_INIT(&pt_child);
    while(modbus_eeprom_write_all_nb(&pt_child, &status) < PT_EXITED) {
        wdog_feed();
    }
    return status;
}

//-------------------------------------------------------------------
int16_t modbus_eeprom_erase_all()
{
    PT pt_child;
    int16_t status;
    PT_INIT(&pt_child);
    while(modbus_eeprom_erase_all_nb(&pt_child, &status) < PT_EXITED) {
        wdog_feed();
    }
    return status;
}

//-------------------------------------------------------------------
int16_t modbus_eeprom_erase_all_polite()
{
    PT pt_child;
    int16_t status;
    PT_INIT(&pt_child);
    while(modbus_eeprom_erase_all_polite_nb(&pt_child, &status) < PT_EXITED) {
        wdog_feed();
    }
    return status;
}

//-------------------------------------------------------------------
static PT_THREAD(task_modbus_eeprom(PT* pt))
{
    static PT pt_child;

    PT_BEGIN(pt);

    while(1) {
        PT_YIELD_UNTIL(pt, write_delayed_pending
                        || modbus_eeprom_erase_all_polite_request
                        || modbus_eeprom_erase_all_request
                        || modbus_eeprom_read_all_request
                        || modbus_eeprom_write_all_request
                           );

        if(write_delayed_pending) {
            PT_SPAWN(pt, &pt_child, modbus_eeprom_write_nb(&pt_child, write_delayed_reg16_addr, write_delayed_value, &write_delayed_status));
            write_delayed_pending = 0;
        }

        if(modbus_eeprom_erase_all_polite_request) {
            PT_SPAWN(pt, &pt_child, modbus_eeprom_erase_all_polite_nb(&pt_child, &modbus_eeprom_erase_all_polite_status));
            modbus_eeprom_status = modbus_eeprom_erase_all_polite_status;
            modbus_eeprom_erase_all_polite_request = 0;
        }

        if(modbus_eeprom_erase_all_request) {
            PT_SPAWN(pt, &pt_child, modbus_eeprom_erase_all_nb(&pt_child, &modbus_eeprom_erase_all_status));
            modbus_eeprom_status = modbus_eeprom_erase_all_status;
            modbus_eeprom_erase_all_request = 0;
        }

        if(modbus_eeprom_read_all_request) {
            PT_SPAWN(pt, &pt_child, modbus_eeprom_read_all_nb(&pt_child, &modbus_eeprom_read_all_status));
            modbus_eeprom_status = modbus_eeprom_read_all_status;
            modbus_eeprom_read_all_request = 0;
        }

        if(modbus_eeprom_write_all_request) {
            PT_SPAWN(pt, &pt_child, modbus_eeprom_write_all_nb(&pt_child, &modbus_eeprom_write_all_status));
            modbus_eeprom_status = modbus_eeprom_write_all_status;
            modbus_eeprom_write_all_request = 0;
        }
    }

    PT_END(pt);
}

//-------------------------------------------------------------------
void modbus_eeprom_task()
{
    task_modbus_eeprom(&pt_modbus_eeprom);
}

//-------------------------------------------------------------------
int16_t modbus_eeprom_write_delayed(uint16_t reg16_addr, uint16_t value)
{
    if(!write_delayed_enabled) {
        return EEPROM_OK;
    }
    if(write_delayed_pending) {
        write_delayed_lost_cnt++;
        return EEPROM_ERROR;
    }
    write_delayed_reg16_addr = reg16_addr;
    write_delayed_value = value;
    write_delayed_pending = 1;
    return EEPROM_BUSY;
}

//-------------------------------------------------------------------
int16_t modbus_eeprom_write_delayed_status()
{
    if(write_delayed_pending) {
        return EEPROM_BUSY;
    }
    if(write_delayed_status != EEPROM_BUSY) {
        return write_delayed_status;
    }
    return EEPROM_ERROR;
}

//-------------------------------------------------------------------
void modbus_eeprom_write_delayed_abort(void)
{
    write_delayed_pending = 0;
}

//-------------------------------------------------------------------
void modbus_eeprom_write_delayed_enable(void)
{
    write_delayed_enabled = 1;
}

//-------------------------------------------------------------------
void modbus_eeprom_write_delayed_disable(void)
{
    write_delayed_enabled = 0;
}
