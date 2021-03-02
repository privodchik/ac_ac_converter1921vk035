#include "stdint_ext.h"
#include "iqmath.h"
#include "modbus_regs.h"
#include "modbus_regs_alias.h"
#include "str_utils.h"

#if MODBUS_REGS_ALIAS_ENABLE

//-------------------------------------------------------------------
#define REG_ALIAS_USE_SORTING    1

//-------------------------------------------------------------------
static uint16_t alias_addr_min = 0xFFFF;
static uint16_t alias_addr_max = 0x0000;

#if REG_ALIAS_USE_SORTING
//-------------------------------------------------------------------
static void qsort_swap(MODBUS_REG_ALIAS *lst, int16_t i1, int16_t i2) {
    MODBUS_REG_ALIAS r0;
    if(i1 == i2) {
        return;
    }
    r0 = lst[i1];
    lst[i1] = lst[i2];
    lst[i2] = r0;
}

//-------------------------------------------------------------------
static int16_t qsort_subpart(MODBUS_REG_ALIAS *lst, int16_t start, int16_t end, int16_t pivot_index) {
    uint16_t pivot;
    int16_t x, y;
    qsort_swap(lst, start, pivot_index);
    pivot = lst[start].alias_addr;
    x = start + 1;
    y = start + 1;
    while(y <= end) {
        if(lst[y].alias_addr <= pivot) {
            qsort_swap(lst, x, y);
            x += 1;
        }
        y += 1;
    }
    qsort_swap(lst, start, x-1);
    return x - 1;
}

//-------------------------------------------------------------------
static void qsort_inplace(MODBUS_REG_ALIAS *lst, int16_t start, int16_t end) {
    int16_t pivot_index;
    int16_t x;
    if(end - start < 1) {
        return;
    }
    pivot_index = start + ((end - start) >> 1);
    x = qsort_subpart(lst, start, end, pivot_index);
    qsort_inplace(lst, start, x - 1);
    qsort_inplace(lst, x + 1, end);
}
#endif //REG_ALIAS_USE_SORTING

//-------------------------------------------------------------------
static void find_orig_addr(MODBUS_REG_ALIAS *alias, uint16_t count) {

    uint16_t i, j, k;
    const MODBUS_REG *p_reg = modbus_holding_regs;
    const MODBUS_REG *p_reg2;
    MODBUS_REG_ALIAS *p_alias;
    const char *group_name = 0;
    char c;
    int16_t len;

    for(i=0; i<(uint16_t)modbus_holding_regs_count; i++) {
        if(p_reg->str) {
            if(startswith_nocase(p_reg->str, "GROUP=")) {
                group_name = (const char *)&(p_reg->str[6]);
                p_alias = alias;
                for(j=0; j<(uint16_t)count; j++) {
                    if(p_alias->group_name && p_alias->reg_name) {
                        if(samestr_nocase(group_name, p_alias->group_name)) {
                            p_reg2 = p_reg;
                            p_reg2++;
                            for(k=i+1; k<(uint16_t)modbus_holding_regs_count; k++) {
                                if(p_reg2->str) {
                                    if(startswith_nocase(p_reg2->str, "GROUP=")) {
                                        break; // next group starts
                                    }
                                    if(startswith_nocase(p_reg2->str, p_alias->reg_name)) {
                                        len = strlen_alt(p_alias->reg_name); // don't confuse stdlib
                                        c = p_reg2->str[len];
                                        if(!c || (c==';') || (c==' ') || (c=='[')) {
                                            p_alias->orig_addr = k;
                                            break; // original register found
                                        }
                                    }
                                }
                                p_reg2++;
                            }
                        }
                    }
                    p_alias++;
                }
            }
        }
        p_reg++;
    }
}

//-------------------------------------------------------------------
void modbus_regs_alias_init(void)
{
#if REG_ALIAS_USE_SORTING
    uint16_t a1, a2;
#else
    MODBUS_REG_ALIAS *p_alias;
    int16_t j;
#endif

#if REG_ALIAS_USE_SORTING
    qsort_inplace(modbus_holding_regs_alias, 0, modbus_holding_regs_alias_count-1);
    qsort_inplace(modbus_input_regs_alias, 0, modbus_input_regs_alias_count-1);
    qsort_inplace(modbus_eeprom_regs_alias, 0, modbus_eeprom_regs_alias_count-1);
#endif

    find_orig_addr(modbus_holding_regs_alias, modbus_holding_regs_alias_count);
    find_orig_addr(modbus_input_regs_alias, modbus_input_regs_alias_count);
    find_orig_addr(modbus_eeprom_regs_alias, modbus_eeprom_regs_alias_count);

    // detect alias address range
#if REG_ALIAS_USE_SORTING
    a1 = modbus_holding_regs_alias[0].alias_addr;
    a2 = modbus_input_regs_alias[0].alias_addr;
    a1 = (a1 < a2) ? a1 : a2;
    a2 = modbus_eeprom_regs_alias[0].alias_addr;
    a1 = (a1 < a2) ? a1 : a2;
    alias_addr_min = a1;
    a1 = modbus_holding_regs_alias[modbus_holding_regs_alias_count-1].alias_addr;
    a2 = modbus_input_regs_alias[modbus_input_regs_alias_count-1].alias_addr;
    a1 = (a1 > a2) ? a1 : a2;
    a2 = modbus_eeprom_regs_alias[modbus_eeprom_regs_alias_count-1].alias_addr;
    a1 = (a1 > a2) ? a1 : a2;
    alias_addr_max = a1;
#else
    alias_addr_min = 0xFFFF;
    alias_addr_max = 0x0000;
    p_alias = modbus_holding_regs_alias;
    for(j=0; j<(uint16_t)modbus_holding_regs_alias_count; j++) {
        if(p_alias->alias_addr < alias_addr_min) alias_addr_min = p_alias->alias_addr;
        if(p_alias->alias_addr > alias_addr_max) alias_addr_max = p_alias->alias_addr;
        p_alias++;
    }
    p_alias = modbus_input_regs_alias;
    for(j=0; j<(uint16_t)modbus_input_regs_alias_count; j++) {
        if(p_alias->alias_addr < alias_addr_min) alias_addr_min = p_alias->alias_addr;
        if(p_alias->alias_addr > alias_addr_max) alias_addr_max = p_alias->alias_addr;
        p_alias++;
    }
    p_alias = modbus_eeprom_regs_alias;
    for(j=0; j<(uint16_t)modbus_eeprom_regs_alias_count; j++) {
        if(p_alias->alias_addr < alias_addr_min) alias_addr_min = p_alias->alias_addr;
        if(p_alias->alias_addr > alias_addr_max) alias_addr_max = p_alias->alias_addr;
        p_alias++;
    }
#endif
}

//-------------------------------------------------------------------
int16_t modbus_regs_alias_address_check(uint16_t alias_addr)
{
    if((alias_addr >= alias_addr_min) && (alias_addr <= alias_addr_max)) {
        return 1;
    }
    return 0;
}

//-------------------------------------------------------------------
static uint16_t modbus_regs_alias_address(uint16_t alias_addr, MODBUS_REG_ALIAS *alias, uint16_t count)
{
    int16_t i;
    const MODBUS_REG_ALIAS *p_alias = alias;
#if REG_ALIAS_USE_SORTING
    int16_t i1, i2;
    // quick search on sorted array
    i1 = 0;
    i2 = count;
    while(1) {
        i = i1 + ((i2 - i1) >> 1);
        if(alias_addr == p_alias[i].alias_addr) {
            return p_alias[i].orig_addr;
        } else
        if(i2 - i1 < 2) {
            break; // not found
        }
        if(alias_addr > p_alias[i].alias_addr) {
            i1 = i;
        } else
        //if(alias_addr < p_alias[i].alias_addr)
        {
            i2 = i;
        }
    }
#else
    // full search
    for(i=0; i<count; i++) {
        if(p_alias->alias_addr == alias_addr) {
            return p_alias->orig_addr;
        }
        p_alias++;
    }
#endif //REG_ALIAS_USE_SORTING

    return 0;
}

//-------------------------------------------------------------------
uint16_t modbus_regs_alias_holding_address(uint16_t alias_addr)
{
    return modbus_regs_alias_address(alias_addr, modbus_holding_regs_alias, modbus_holding_regs_alias_count);
}

//-------------------------------------------------------------------
uint16_t modbus_regs_alias_input_address(uint16_t alias_addr)
{
    return modbus_regs_alias_address(alias_addr, modbus_input_regs_alias, modbus_input_regs_alias_count);
}

//-------------------------------------------------------------------
uint16_t modbus_regs_alias_eeprom_address(uint16_t alias_addr)
{
    return modbus_regs_alias_address(alias_addr, modbus_eeprom_regs_alias, modbus_eeprom_regs_alias_count);
}

#endif //MODBUS_REGS_ALIAS_ENABLE

