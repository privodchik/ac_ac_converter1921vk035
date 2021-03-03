#include "iqmath_float32.h"

//-------------------------------------------------------------------
#if IQMATH_FLOAT32_DEBUG

float iqmath_float32_max = 0.0;
float iqmath_float32_min = 0.0;

int iqmath_float32_check_range_enabled = 1;

static int iqmath_float32_overflow = 0;

//-------------------------------------------------------------------
float iqmath_float32_check_range(float x)
{
    if(!iqmath_float32_check_range_enabled)
        return x;

    if(x > iqmath_float32_max) iqmath_float32_max = x;
    if(x < iqmath_float32_min) iqmath_float32_min = x;
    if(x > IQ_MAX_INT)
    {
        iqmath_float32_overflow++;
    }
    if(x < IQ_MIN_INT)
    {
        iqmath_float32_overflow++;
    }
    return x;
}

//-------------------------------------------------------------------
float IQmpy_float32(float A, float B)
{
    iqmath_float32_check_range(A);
    iqmath_float32_check_range(B);
    return iqmath_float32_check_range(A * B);
}

//-------------------------------------------------------------------
float IQdiv_float32(float A, float B)
{
    iqmath_float32_check_range(A);
    iqmath_float32_check_range(B);
    return iqmath_float32_check_range(A / B);
}

#endif //IQMATH_FLOAT32_DEBUG
