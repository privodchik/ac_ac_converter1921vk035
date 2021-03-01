#include "clock.h"

#include "c_lang_adapter.h"


//-------------------------------------------------------------------
void clock_init()
{
    *pnowTimeMs = TIME_SEC(0.0);
}

//-------------------------------------------------------------------
time_t clock_time()
{
    return *pnowTimeMs;
}

//-------------------------------------------------------------------
// should call it from isr to update software clock
//void clock_tick(time_t period)
//{
//    time_now += period; // overflow is ok
//    sw_clock_alive = 1;
//}
