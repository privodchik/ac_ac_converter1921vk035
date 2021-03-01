#ifndef CLOCK_H
#define CLOCK_H

#ifdef __cplusplus
extern "C" {
#endif

#include "iqmath.h"
#include "time_defs.h"

//-------------------------------------------------------------------
void clock_init(void);
time_t clock_time(void);

void clock_tick(time_t period); // call it from isr

#ifdef __cplusplus
} //extern "C"
#endif

#endif /* CLOCK_H */
