#ifndef TIMER_H
#define TIMER_H

#ifdef __cplusplus
extern "C" {
#endif

//-------------------------------------------------------------------
#include "iqmath.h"
#include "time_defs.h"

//-------------------------------------------------------------------
struct timer
{
    time_t start;
    time_t interval;
};

typedef struct timer TIMER;

//-------------------------------------------------------------------
void timer_set(struct timer *t, time_t time);
int timer_expired(struct timer *t);
void timer_advance(struct timer *t, time_t time);
time_t timer_elapsed(struct timer *t);

#ifdef __cplusplus
} //extern "C"
#endif

#endif /* TIMER_H */
