#include "watchdog.h"
#include "atomic.h"


//------------------------------------------------------------------- 
void wdog_enable(void)
{}

//-------------------------------------------------------------------
void wdog_feed(void)
{
}

//------------------------------------------------------------------- 
int wdog_check_reset(void)
{
    // Milandr 1986BE9x does not support IWDG reset detection
    return 0;
}

//------------------------------------------------------------------- 
void wdog_soft_reset(void)
{}

