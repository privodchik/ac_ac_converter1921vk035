#ifndef WATCHDOG_H
#define WATCHDOG_H

#ifdef __cplusplus
extern "C" {
#endif

//-------------------------------------------------------------------
void wdog_enable(void);
void wdog_feed(void);
int wdog_check_reset(void);
void wdog_soft_reset(void);

#ifdef __cplusplus
}
#endif	
	
#endif //WATCHDOG_H
