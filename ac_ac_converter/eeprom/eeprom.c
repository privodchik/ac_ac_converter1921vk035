#include "mcu.h"
#include "eeprom.h"

//-------------------------------------------------------------------
const char *eeprom_status_str(int16_t status)
{
    if(status == EEPROM_OK) return "OK";
    if(status == EEPROM_ERROR) return "ERROR";
    if(status == EEPROM_NEED_ERASE) return "NEED_ERASE";
    if(status == EEPROM_NEED_INIT) return "NEED_INIT";
    if(status == EEPROM_NOT_FOUND) return "NOT_FOUND";
    if(status == EEPROM_NO_RESPONSE) return "NO_RESPONSE";
    if(status == EEPROM_SHORT_RESPONSE) return "SHORT_RESPONSE";
    if(status == EEPROM_EMPTY) return "EMPTY";
    if(status == EEPROM_FULL) return "FULL";
    if(status == EEPROM_BUSY) return "BUSY";
    if(status == EEPROM_WRONG_ADDRESS) return "WRONG_ADDRESS";
    if(status == EEPROM_I2C_BUSY) return "I2C_BUSY";
    if(status == EEPROM_I2C_ERROR) return "I2C_ERROR";
    if(status == EEPROM_TEST_FAIL) return "TEST_FAIL";
    if(status == EEPROM_TIMEOUT) return "TIMEOUT";

    return "?";
}
