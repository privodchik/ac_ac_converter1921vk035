#include "clock.h"

#include "c_lang_adapter.h"

static time_t time_now = TIME_SEC(0.0);
static int16_t sw_clock_alive = 0;


//-------------------------------------------------------------------
void clock_init()
{
    time_now = TIME_SEC(0.0);
}

//-------------------------------------------------------------------
time_t clock_time()
{
    return time_now;
}

//-------------------------------------------------------------------
// should call it from isr to update software clock
void clock_tick(time_t period)
{
    time_now += period; // overflow is ok
    sw_clock_alive = 1;
}
