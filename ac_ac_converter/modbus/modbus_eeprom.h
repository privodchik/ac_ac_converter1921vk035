#ifndef MODBUS_EEPROM_H
#define MODBUS_EEPROM_H

#ifdef __cplusplus
extern "C" {
#endif

#include "stdint_ext.h"
#include "eeprom.h"
#include "pt.h"

//-------------------------------------------------------------------
extern int16_t modbus_eeprom_read_all_request;
extern int16_t modbus_eeprom_write_all_request;
extern int16_t modbus_eeprom_erase_all_request;
extern int16_t modbus_eeprom_erase_all_polite_request;

extern int16_t modbus_eeprom_read_all_status;
extern int16_t modbus_eeprom_write_all_status;
extern int16_t modbus_eeprom_erase_all_status;
extern int16_t modbus_eeprom_erase_all_polite_status;

extern int16_t modbus_eeprom_status;

extern int16_t modbus_eeprom_need_erase;

//-------------------------------------------------------------------
int16_t modbus_eeprom_init(void);
void modbus_eeprom_task(void);

// non-blocking functions
PT_THREAD(modbus_eeprom_read_nb(PT *pt, uint16_t reg16_addr, uint16_t *pvalue, int16_t *status));
PT_THREAD(modbus_eeprom_write_nb(PT *pt, uint16_t reg16_addr, uint16_t value, int16_t *status));
PT_THREAD(modbus_eeprom_erase_nb(PT *pt, uint16_t reg16_addr, int16_t *status));

PT_THREAD(modbus_eeprom_read_all_nb(PT *pt, int16_t *status));
PT_THREAD(modbus_eeprom_write_all_nb(PT *pt, int16_t *status));
PT_THREAD(modbus_eeprom_erase_all_nb(PT *pt, int16_t *status));
PT_THREAD(modbus_eeprom_erase_all_polite_nb(PT *pt, int16_t *status));

// special non-blocking functions
int16_t modbus_eeprom_write_delayed(uint16_t reg16_addr, uint16_t value);
int16_t modbus_eeprom_write_delayed_status(void);
void modbus_eeprom_write_delayed_enable(void);
void modbus_eeprom_write_delayed_disable(void);

// blocking functions
int16_t modbus_eeprom_read(uint16_t reg16_addr, uint16_t *pvalue);
int16_t modbus_eeprom_write(uint16_t reg16_addr, uint16_t value);
int16_t modbus_eeprom_erase(uint16_t reg16_addr);

int16_t modbus_eeprom_read_all(void);
int16_t modbus_eeprom_write_all(void);
int16_t modbus_eeprom_erase_all(void);
int16_t modbus_eeprom_erase_all_polite(void); // erase favouring access rights


#ifdef __cplusplus
}
#endif

#endif //MODBUS_EEPROM_H
