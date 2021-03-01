#include "timer.h"
#include "clock.h"

//-------------------------------------------------------------------
void timer_set(struct timer *t, time_t time)
{
    t->interval = time;
    t->start = clock_time();
}

//-------------------------------------------------------------------
int timer_expired(struct timer *t)
{
    return clock_time() - t->start >= t->interval;
}

//-------------------------------------------------------------------
time_t timer_elapsed(struct timer *t)
{
    return clock_time() - t->start;
}

//-------------------------------------------------------------------
void timer_advance(struct timer *t, time_t time)
{
    t->start += time;
}

