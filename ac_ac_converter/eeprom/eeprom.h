#ifndef EEPROM_H
#define EEPROM_H

#ifdef __cplusplus
extern "C" {
#endif

#include "mcu.h"
#include "eeprom_dummy.h"

//-------------------------------------------------------------------
#define EEPROM_OK               0
#define EEPROM_ERROR            1
#define EEPROM_NEED_ERASE       2
#define EEPROM_NEED_INIT        3
#define EEPROM_NOT_FOUND        4
#define EEPROM_NO_RESPONSE      5
#define EEPROM_SHORT_RESPONSE   6
#define EEPROM_EMPTY            7
#define EEPROM_FULL             8
#define EEPROM_BUSY             9
#define EEPROM_WRONG_ADDRESS    10
#define EEPROM_I2C_BUSY         11
#define EEPROM_I2C_ERROR        12
#define EEPROM_TEST_FAIL        13
#define EEPROM_TIMEOUT          14
#define EEPROM_READ_ONLY        15

//-------------------------------------------------------------------
const char *eeprom_status_str(int16_t status);

#ifdef __cplusplus
}
#endif

#endif //EEPROM_H
