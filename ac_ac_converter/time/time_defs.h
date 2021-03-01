#ifndef TIME_DEFS_H
#define TIME_DEFS_H

#include <time.h> // gives time_t
//typedef uint32_t time_t; // time in number of microseconds

#include "iqmath.h"

//-------------------------------------------------------------------
// note: float is for TI TMS compiler
//#define TIME_SEC(s)         (time_t)((float)(s)*1000000.0)
//#define TIME_MSEC(ms)       (time_t)((float)(ms)*1000.0)
#define TIME_SEC(s)         (time_t)((s)*1000000.0)
#define TIME_MSEC(ms)       (time_t)((ms)*1000.0)
#define TIME_USEC(us)       (time_t)(us)

#if IQMATH_FLOAT32
    #define time2IQ(T)      ((float)(T)*(float)1e-6)
    #define IQ2time(T)      (time_t)((float)(T)*(float)1e6)
    #define time2IQms(T)    ((float)(T)*(float)1e-3)
    #define IQms2time(T)    (time_t)((float)(T)*(float)1e3)
#endif

#if IQMATH_INT32
    #define time2IQ(T)      IQ20mpy((iq20_t)(T), IQ(1.048576))
    #define IQ2time(T)      IQmpy((iq_t)(T), IQ20(0.953674316))
    #define time2IQms(T)    IQ10mpy((iq10_t)(T), IQ(1.024))
    #define IQms2time(T)    IQmpy(IQdiv1024((iq_t)(T))+1, IQ20(0.9765625))
#endif

#define time2FLOAT(T)       ((float)(T)*1e-6)

#endif // TIME_DEFS_H
