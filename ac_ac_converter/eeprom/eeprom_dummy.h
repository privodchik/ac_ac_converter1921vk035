#ifndef EEPROM_DUMMY_H
#define EEPROM_DUMMY_H

#ifdef __cplusplus
extern "C" {
#endif

//#include "mcu.h"
#include "pt.h"
#include "config.h"

//-------------------------------------------------------------------
#define DUMMY_SIZE_BYTES         4096
#define DUMMY_PAGE_BYTES         64
#define DUMMY_RESERVED_BYTES     0

#define EEPROM_SIZE_BYTES       DUMMY_SIZE_BYTES
#define EEPROM_PAGE_BYTES       DUMMY_PAGE_BYTES
#define EEPROM_RESERVED_BYTES   DUMMY_RESERVED_BYTES

//-------------------------------------------------------------------
extern int16_t eeprom_status;
extern uint16_t eeprom_errors;

//-------------------------------------------------------------------
int16_t eeprom_init(void);

// non blocking functions
PT_THREAD(eeprom_ready_nb(PT *pt, int16_t *status));
PT_THREAD(eeprom_read_nb(PT *pt, uint16_t address, uint8_t *buf, uint16_t len, int16_t *status));
PT_THREAD(eeprom_write_nb(PT *pt, uint16_t address, uint8_t *buf, uint16_t len, int16_t *status));
PT_THREAD(eeprom_erase_all_nb(PT *pt, int16_t *status));

// blocking functions
int16_t eeprom_ready(void);
int16_t eeprom_read(uint16_t address, uint8_t *buf, uint16_t len);
int16_t eeprom_write(uint16_t address, uint8_t *buf, uint16_t len);
int16_t eeprom_erase_all(void);


#ifdef __cplusplus
}
#endif

#endif //EEPROM_DUMMY_H

