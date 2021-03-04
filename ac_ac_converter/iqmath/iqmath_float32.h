// auto-generated file 02.12.2018 12:41:46
#ifndef IQMATH_FLOAT32_H
#define IQMATH_FLOAT32_H

//-------------------------------------------------------------------
#ifdef __cplusplus
extern "C" {
#endif

#define IQMATH_FLOAT32          1
#define IQMATH_FLOAT32_DEBUG    0 // debug range before using int32

#include "stdint.h"
#include <math.h>

//-------------------------------------------------------------------
#if IQMATH_FLOAT32_DEBUG
    extern float iqmath_float32_max;
    extern float iqmath_float32_min;
    extern int iqmath_float32_check_range_enabled;
    float iqmath_float32_check_range(float x);
    float IQmpy_float32(float A, float B);
    float IQdiv_float32(float A, float B);
#endif

//-------------------------------------------------------------------
typedef float iq_t;

#define Q_GLOBAL        21

#define Q30             30
#define Q29             29
#define Q28             28
#define Q27             27
#define Q26             26
#define Q25             25
#define Q24             24
#define Q23             23
#define Q22             22
#define Q21             21
#define Q20             20
#define Q19             19
#define Q18             18
#define Q17             17
#define Q16             16
#define Q15             15
#define Q14             14
#define Q13             13
#define Q12             12
#define Q11             11
#define Q10             10
#define Q9              9
#define Q8              8
#define Q7              7
#define Q6              6
#define Q5              5
#define Q4              4
#define Q3              3
#define Q2              2
#define Q1              1
#define Q0              0
#define QG              Q_GLOBAL

//-------------------------------------------------------------------
#define IQ_MAX_INT      (float)(((int32_t)1<<10)-1)
#define IQ_MIN_INT      (float)(-((int32_t)1<<10))

#define IQ(A)           IQ21(A)
#define IQ2INT(A)       floorf(A)
#define IQ2FLOAT(A)     IQ21toF(A)

#define IQmpy(A,B)      IQ21mpy(A,B)
#define IQdiv(A,B)      IQ21div(A,B)

#define IQlsh(A,bits)   ((iq_t)(A)*(float)((int32_t)1<<(bits)))
#define IQrsh(A,bits)   ((iq_t)(A)*((float)1.0/(float)((int32_t)1<<(bits))))

#define IQlsh_signed(x, sh) (sh>=0 ? IQlsh(x, sh) : IQrsh(x, -sh))
#define IQrsh_signed(x, sh) (sh>=0 ? IQrsh(x, sh) : IQlsh(x, -sh))

extern iq_t IQdiv_safe(iq_t num, iq_t den);

//-------------------------------------------------------------------
#if IQMATH_FLOAT32_DEBUG
    #define IQmpy2(A)       iqmath_float32_check_range((A)*(float)2.0)
    #define IQmpy4(A)       iqmath_float32_check_range((A)*(float)4.0)
    #define IQmpy8(A)       iqmath_float32_check_range((A)*(float)8.0)
    #define IQmpy16(A)      iqmath_float32_check_range((A)*(float)16.0)
    #define IQmpy32(A)      iqmath_float32_check_range((A)*(float)32.0)
    #define IQmpy64(A)      iqmath_float32_check_range((A)*(float)64.0)
    #define IQmpy128(A)     iqmath_float32_check_range((A)*(float)128.0)
    #define IQmpy256(A)     iqmath_float32_check_range((A)*(float)256.0)
    #define IQmpy512(A)     iqmath_float32_check_range((A)*(float)512.0)
    #define IQmpy1024(A)    iqmath_float32_check_range((A)*(float)1024.0)
#else //IQMATH_FLOAT32_DEBUG
    #define IQmpy2(A)       ((A)*(float)2.0)
    #define IQmpy4(A)       ((A)*(float)4.0)
    #define IQmpy8(A)       ((A)*(float)8.0)
    #define IQmpy16(A)      ((A)*(float)16.0)
    #define IQmpy32(A)      ((A)*(float)32.0)
    #define IQmpy64(A)      ((A)*(float)64.0)
    #define IQmpy128(A)     ((A)*(float)128.0)
    #define IQmpy256(A)     ((A)*(float)256.0)
    #define IQmpy512(A)     ((A)*(float)512.0)
    #define IQmpy1024(A)    ((A)*(float)1024.0)
#endif //IQMATH_FLOAT32_DEBUG

#define IQdiv2(A)       ((A)*(float)0.5)
#define IQdiv4(A)       ((A)*(float)0.25)
#define IQdiv8(A)       ((A)*(float)0.125)
#define IQdiv16(A)      ((A)*(float)0.0625)
#define IQdiv32(A)      ((A)*(float)0.03125)
#define IQdiv64(A)      ((A)*(float)0.015625)
#define IQdiv128(A)     ((A)*(float)0.0078125)
#define IQdiv256(A)     ((A)*(float)0.00390625)
#define IQdiv512(A)     ((A)*(float)0.001953125)
#define IQdiv1024(A)    ((A)*(float)0.0009765625)

//-------------------------------------------------------------------
#define IQcos(x)        cosf((float)x)
#define IQsin(x)        sinf((float)x)
#define IQsqrt(x)       sqrtf((float)x)
#define IQatan2(y,x)    atan2f((float)y, (float)x)
#define IQabs(x)        fabsf((float)x)

//-------------------------------------------------------------------
typedef float           iq30_t;
typedef float           iq29_t;
typedef float           iq28_t;
typedef float           iq27_t;
typedef float           iq26_t;
typedef float           iq25_t;
typedef float           iq24_t;
typedef float           iq23_t;
typedef float           iq22_t;
typedef float           iq21_t;
typedef float           iq20_t;
typedef float           iq19_t;
typedef float           iq18_t;
typedef float           iq17_t;
typedef float           iq16_t;
typedef float           iq15_t;
typedef float           iq14_t;
typedef float           iq13_t;
typedef float           iq12_t;
typedef float           iq11_t;
typedef float           iq10_t;
typedef float           iq9_t;
typedef float           iq8_t;
typedef float           iq7_t;
typedef float           iq6_t;
typedef float           iq5_t;
typedef float           iq4_t;
typedef float           iq3_t;
typedef float           iq2_t;
typedef float           iq1_t;
typedef float           iq0_t;

//-------------------------------------------------------------------
#define IQ30(A)         (iq30_t)(A)
#define IQ29(A)         (iq29_t)(A)
#define IQ28(A)         (iq28_t)(A)
#define IQ27(A)         (iq27_t)(A)
#define IQ26(A)         (iq26_t)(A)
#define IQ25(A)         (iq25_t)(A)
#define IQ24(A)         (iq24_t)(A)
#define IQ23(A)         (iq23_t)(A)
#define IQ22(A)         (iq22_t)(A)
#define IQ21(A)         (iq21_t)(A)
#define IQ20(A)         (iq20_t)(A)
#define IQ19(A)         (iq19_t)(A)
#define IQ18(A)         (iq18_t)(A)
#define IQ17(A)         (iq17_t)(A)
#define IQ16(A)         (iq16_t)(A)
#define IQ15(A)         (iq15_t)(A)
#define IQ14(A)         (iq14_t)(A)
#define IQ13(A)         (iq13_t)(A)
#define IQ12(A)         (iq12_t)(A)
#define IQ11(A)         (iq11_t)(A)
#define IQ10(A)         (iq10_t)(A)
#define IQ9(A)          (iq9_t)(A)
#define IQ8(A)          (iq8_t)(A)
#define IQ7(A)          (iq7_t)(A)
#define IQ6(A)          (iq6_t)(A)
#define IQ5(A)          (iq5_t)(A)
#define IQ4(A)          (iq4_t)(A)
#define IQ3(A)          (iq3_t)(A)
#define IQ2(A)          (iq2_t)(A)
#define IQ1(A)          (iq1_t)(A)
#define IQ0(A)          (iq0_t)(A)

//-------------------------------------------------------------------
#define IQtoIQ30(A)     (iq30_t)(A)
#define IQtoIQ29(A)     (iq29_t)(A)
#define IQtoIQ28(A)     (iq28_t)(A)
#define IQtoIQ27(A)     (iq27_t)(A)
#define IQtoIQ26(A)     (iq26_t)(A)
#define IQtoIQ25(A)     (iq25_t)(A)
#define IQtoIQ24(A)     (iq24_t)(A)
#define IQtoIQ23(A)     (iq23_t)(A)
#define IQtoIQ22(A)     (iq22_t)(A)
#define IQtoIQ21(A)     (iq21_t)(A)
#define IQtoIQ20(A)     (iq20_t)(A)
#define IQtoIQ19(A)     (iq19_t)(A)
#define IQtoIQ18(A)     (iq18_t)(A)
#define IQtoIQ17(A)     (iq17_t)(A)
#define IQtoIQ16(A)     (iq16_t)(A)
#define IQtoIQ15(A)     (iq15_t)(A)
#define IQtoIQ14(A)     (iq14_t)(A)
#define IQtoIQ13(A)     (iq13_t)(A)
#define IQtoIQ12(A)     (iq12_t)(A)
#define IQtoIQ11(A)     (iq11_t)(A)
#define IQtoIQ10(A)     (iq10_t)(A)
#define IQtoIQ9(A)      (iq9_t)(A)
#define IQtoIQ8(A)      (iq8_t)(A)
#define IQtoIQ7(A)      (iq7_t)(A)
#define IQtoIQ6(A)      (iq6_t)(A)
#define IQtoIQ5(A)      (iq5_t)(A)
#define IQtoIQ4(A)      (iq4_t)(A)
#define IQtoIQ3(A)      (iq3_t)(A)
#define IQtoIQ2(A)      (iq2_t)(A)
#define IQtoIQ1(A)      (iq1_t)(A)
#define IQtoIQ0(A)      (iq0_t)(A)

//-------------------------------------------------------------------
#define IQ30toIQ(A)     (iq_t)(A)
#define IQ29toIQ(A)     (iq_t)(A)
#define IQ28toIQ(A)     (iq_t)(A)
#define IQ27toIQ(A)     (iq_t)(A)
#define IQ26toIQ(A)     (iq_t)(A)
#define IQ25toIQ(A)     (iq_t)(A)
#define IQ24toIQ(A)     (iq_t)(A)
#define IQ23toIQ(A)     (iq_t)(A)
#define IQ22toIQ(A)     (iq_t)(A)
#define IQ21toIQ(A)     (iq_t)(A)
#define IQ20toIQ(A)     (iq_t)(A)
#define IQ19toIQ(A)     (iq_t)(A)
#define IQ18toIQ(A)     (iq_t)(A)
#define IQ17toIQ(A)     (iq_t)(A)
#define IQ16toIQ(A)     (iq_t)(A)
#define IQ15toIQ(A)     (iq_t)(A)
#define IQ14toIQ(A)     (iq_t)(A)
#define IQ13toIQ(A)     (iq_t)(A)
#define IQ12toIQ(A)     (iq_t)(A)
#define IQ11toIQ(A)     (iq_t)(A)
#define IQ10toIQ(A)     (iq_t)(A)
#define IQ9toIQ(A)      (iq_t)(A)
#define IQ8toIQ(A)      (iq_t)(A)
#define IQ7toIQ(A)      (iq_t)(A)
#define IQ6toIQ(A)      (iq_t)(A)
#define IQ5toIQ(A)      (iq_t)(A)
#define IQ4toIQ(A)      (iq_t)(A)
#define IQ3toIQ(A)      (iq_t)(A)
#define IQ2toIQ(A)      (iq_t)(A)
#define IQ1toIQ(A)      (iq_t)(A)
#define IQ0toIQ(A)      (iq_t)(A)

//-------------------------------------------------------------------
#if IQMATH_FLOAT32_DEBUG
    #define IQ30mpy(A,B)    IQmpy_float32(A,B)
    #define IQ29mpy(A,B)    IQmpy_float32(A,B)
    #define IQ28mpy(A,B)    IQmpy_float32(A,B)
    #define IQ27mpy(A,B)    IQmpy_float32(A,B)
    #define IQ26mpy(A,B)    IQmpy_float32(A,B)
    #define IQ25mpy(A,B)    IQmpy_float32(A,B)
    #define IQ24mpy(A,B)    IQmpy_float32(A,B)
    #define IQ23mpy(A,B)    IQmpy_float32(A,B)
    #define IQ22mpy(A,B)    IQmpy_float32(A,B)
    #define IQ21mpy(A,B)    IQmpy_float32(A,B)
    #define IQ20mpy(A,B)    IQmpy_float32(A,B)
    #define IQ19mpy(A,B)    IQmpy_float32(A,B)
    #define IQ18mpy(A,B)    IQmpy_float32(A,B)
    #define IQ17mpy(A,B)    IQmpy_float32(A,B)
    #define IQ16mpy(A,B)    IQmpy_float32(A,B)
    #define IQ15mpy(A,B)    IQmpy_float32(A,B)
    #define IQ14mpy(A,B)    IQmpy_float32(A,B)
    #define IQ13mpy(A,B)    IQmpy_float32(A,B)
    #define IQ12mpy(A,B)    IQmpy_float32(A,B)
    #define IQ11mpy(A,B)    IQmpy_float32(A,B)
    #define IQ10mpy(A,B)    IQmpy_float32(A,B)
    #define IQ9mpy(A,B)     IQmpy_float32(A,B)
    #define IQ8mpy(A,B)     IQmpy_float32(A,B)
    #define IQ7mpy(A,B)     IQmpy_float32(A,B)
    #define IQ6mpy(A,B)     IQmpy_float32(A,B)
    #define IQ5mpy(A,B)     IQmpy_float32(A,B)
    #define IQ4mpy(A,B)     IQmpy_float32(A,B)
    #define IQ3mpy(A,B)     IQmpy_float32(A,B)
    #define IQ2mpy(A,B)     IQmpy_float32(A,B)
    #define IQ1mpy(A,B)     IQmpy_float32(A,B)
    #define IQ0mpy(A,B)     IQmpy_float32(A,B)
#else //IQMATH_FLOAT32_DEBUG
    #define IQ30mpy(A,B)    ((A)*(B))
    #define IQ29mpy(A,B)    ((A)*(B))
    #define IQ28mpy(A,B)    ((A)*(B))
    #define IQ27mpy(A,B)    ((A)*(B))
    #define IQ26mpy(A,B)    ((A)*(B))
    #define IQ25mpy(A,B)    ((A)*(B))
    #define IQ24mpy(A,B)    ((A)*(B))
    #define IQ23mpy(A,B)    ((A)*(B))
    #define IQ22mpy(A,B)    ((A)*(B))
    #define IQ21mpy(A,B)    ((A)*(B))
    #define IQ20mpy(A,B)    ((A)*(B))
    #define IQ19mpy(A,B)    ((A)*(B))
    #define IQ18mpy(A,B)    ((A)*(B))
    #define IQ17mpy(A,B)    ((A)*(B))
    #define IQ16mpy(A,B)    ((A)*(B))
    #define IQ15mpy(A,B)    ((A)*(B))
    #define IQ14mpy(A,B)    ((A)*(B))
    #define IQ13mpy(A,B)    ((A)*(B))
    #define IQ12mpy(A,B)    ((A)*(B))
    #define IQ11mpy(A,B)    ((A)*(B))
    #define IQ10mpy(A,B)    ((A)*(B))
    #define IQ9mpy(A,B)     ((A)*(B))
    #define IQ8mpy(A,B)     ((A)*(B))
    #define IQ7mpy(A,B)     ((A)*(B))
    #define IQ6mpy(A,B)     ((A)*(B))
    #define IQ5mpy(A,B)     ((A)*(B))
    #define IQ4mpy(A,B)     ((A)*(B))
    #define IQ3mpy(A,B)     ((A)*(B))
    #define IQ2mpy(A,B)     ((A)*(B))
    #define IQ1mpy(A,B)     ((A)*(B))
    #define IQ0mpy(A,B)     ((A)*(B))
#endif //IQMATH_FLOAT32_DEBUG

//-------------------------------------------------------------------
#if IQMATH_FLOAT32_DEBUG
    #define IQ30div(A,B)    IQdiv_float32(A,B)
    #define IQ29div(A,B)    IQdiv_float32(A,B)
    #define IQ28div(A,B)    IQdiv_float32(A,B)
    #define IQ27div(A,B)    IQdiv_float32(A,B)
    #define IQ26div(A,B)    IQdiv_float32(A,B)
    #define IQ25div(A,B)    IQdiv_float32(A,B)
    #define IQ24div(A,B)    IQdiv_float32(A,B)
    #define IQ23div(A,B)    IQdiv_float32(A,B)
    #define IQ22div(A,B)    IQdiv_float32(A,B)
    #define IQ21div(A,B)    IQdiv_float32(A,B)
    #define IQ20div(A,B)    IQdiv_float32(A,B)
    #define IQ19div(A,B)    IQdiv_float32(A,B)
    #define IQ18div(A,B)    IQdiv_float32(A,B)
    #define IQ17div(A,B)    IQdiv_float32(A,B)
    #define IQ16div(A,B)    IQdiv_float32(A,B)
    #define IQ15div(A,B)    IQdiv_float32(A,B)
    #define IQ14div(A,B)    IQdiv_float32(A,B)
    #define IQ13div(A,B)    IQdiv_float32(A,B)
    #define IQ12div(A,B)    IQdiv_float32(A,B)
    #define IQ11div(A,B)    IQdiv_float32(A,B)
    #define IQ10div(A,B)    IQdiv_float32(A,B)
    #define IQ9div(A,B)     IQdiv_float32(A,B)
    #define IQ8div(A,B)     IQdiv_float32(A,B)
    #define IQ7div(A,B)     IQdiv_float32(A,B)
    #define IQ6div(A,B)     IQdiv_float32(A,B)
    #define IQ5div(A,B)     IQdiv_float32(A,B)
    #define IQ4div(A,B)     IQdiv_float32(A,B)
    #define IQ3div(A,B)     IQdiv_float32(A,B)
    #define IQ2div(A,B)     IQdiv_float32(A,B)
    #define IQ1div(A,B)     IQdiv_float32(A,B)
    #define IQ0div(A,B)     IQdiv_float32(A,B)
#else //IQMATH_FLOAT32_DEBUG
    #define IQ30div(A,B)    ((A)/(B))
    #define IQ29div(A,B)    ((A)/(B))
    #define IQ28div(A,B)    ((A)/(B))
    #define IQ27div(A,B)    ((A)/(B))
    #define IQ26div(A,B)    ((A)/(B))
    #define IQ25div(A,B)    ((A)/(B))
    #define IQ24div(A,B)    ((A)/(B))
    #define IQ23div(A,B)    ((A)/(B))
    #define IQ22div(A,B)    ((A)/(B))
    #define IQ21div(A,B)    ((A)/(B))
    #define IQ20div(A,B)    ((A)/(B))
    #define IQ19div(A,B)    ((A)/(B))
    #define IQ18div(A,B)    ((A)/(B))
    #define IQ17div(A,B)    ((A)/(B))
    #define IQ16div(A,B)    ((A)/(B))
    #define IQ15div(A,B)    ((A)/(B))
    #define IQ14div(A,B)    ((A)/(B))
    #define IQ13div(A,B)    ((A)/(B))
    #define IQ12div(A,B)    ((A)/(B))
    #define IQ11div(A,B)    ((A)/(B))
    #define IQ10div(A,B)    ((A)/(B))
    #define IQ9div(A,B)     ((A)/(B))
    #define IQ8div(A,B)     ((A)/(B))
    #define IQ7div(A,B)     ((A)/(B))
    #define IQ6div(A,B)     ((A)/(B))
    #define IQ5div(A,B)     ((A)/(B))
    #define IQ4div(A,B)     ((A)/(B))
    #define IQ3div(A,B)     ((A)/(B))
    #define IQ2div(A,B)     ((A)/(B))
    #define IQ1div(A,B)     ((A)/(B))
    #define IQ0div(A,B)     ((A)/(B))
#endif //IQMATH_FLOAT32_DEBUG

//-------------------------------------------------------------------
#define IQ30toF(A)      (float)(A)
#define IQ29toF(A)      (float)(A)
#define IQ28toF(A)      (float)(A)
#define IQ27toF(A)      (float)(A)
#define IQ26toF(A)      (float)(A)
#define IQ25toF(A)      (float)(A)
#define IQ24toF(A)      (float)(A)
#define IQ23toF(A)      (float)(A)
#define IQ22toF(A)      (float)(A)
#define IQ21toF(A)      (float)(A)
#define IQ20toF(A)      (float)(A)
#define IQ19toF(A)      (float)(A)
#define IQ18toF(A)      (float)(A)
#define IQ17toF(A)      (float)(A)
#define IQ16toF(A)      (float)(A)
#define IQ15toF(A)      (float)(A)
#define IQ14toF(A)      (float)(A)
#define IQ13toF(A)      (float)(A)
#define IQ12toF(A)      (float)(A)
#define IQ11toF(A)      (float)(A)
#define IQ10toF(A)      (float)(A)
#define IQ9toF(A)       (float)(A)
#define IQ8toF(A)       (float)(A)
#define IQ7toF(A)       (float)(A)
#define IQ6toF(A)       (float)(A)
#define IQ5toF(A)       (float)(A)
#define IQ4toF(A)       (float)(A)
#define IQ3toF(A)       (float)(A)
#define IQ2toF(A)       (float)(A)
#define IQ1toF(A)       (float)(A)
#define IQ0toF(A)       (float)(A)



//-------------------------------------------------------------------
#ifdef __cplusplus
} // extern "C"
#endif

#endif /* IQMATH_FLOAT32_H */
