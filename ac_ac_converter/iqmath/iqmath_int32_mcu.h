// auto-generated file 04.03.2021 08:49:32
#ifndef IQMATH_INT32_MCU_H
#define IQMATH_INT32_MCU_H

#define IQMATH_INT32            1
#define IQMATH_INT32_MCU        1

#include "stdint.h"
#include <math.h>

//-------------------------------------------------------------------
typedef int32_t iq_t;

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
#define IQ_MAX_INT      (int32_t)(((int32_t)1<<10)-1)
#define IQ_MIN_INT      (int32_t)(-((int32_t)1<<10))

#define IQ(A)           IQ21(A)
#define IQ2INT(A)       ((A)>>Q_GLOBAL)
#define IQ2FLOAT(A)     IQ21toF(A)

#define IQmpy(A,B)      IQ21mpy(A,B)
#define IQdiv(A,B)      IQ21div(A,B)

#define IQlsh(A,bits)   ((iq_t)(A)<<(bits))
#define IQrsh(A,bits)   ((iq_t)(A)>>(bits))

#define IQlsh_signed(x, sh) (sh>=0 ? IQlsh(x, sh) : IQrsh(x, -sh))
#define IQrsh_signed(x, sh) (sh>=0 ? IQrsh(x, sh) : IQlsh(x, -sh))

extern iq_t IQdiv_safe(iq_t num, iq_t den);

//-------------------------------------------------------------------
#define IQmpy2(A)       ((A)<<1)
#define IQmpy4(A)       ((A)<<2)
#define IQmpy8(A)       ((A)<<3)
#define IQmpy16(A)      ((A)<<4)
#define IQmpy32(A)      ((A)<<5)
#define IQmpy64(A)      ((A)<<6)
#define IQmpy128(A)     ((A)<<7)
#define IQmpy256(A)     ((A)<<8)
#define IQmpy512(A)     ((A)<<9)
#define IQmpy1024(A)    ((A)<<10)

#define IQdiv2(A)       ((A)>>1)
#define IQdiv4(A)       ((A)>>2)
#define IQdiv8(A)       ((A)>>3)
#define IQdiv16(A)      ((A)>>4)
#define IQdiv32(A)      ((A)>>5)
#define IQdiv64(A)      ((A)>>6)
#define IQdiv128(A)     ((A)>>7)
#define IQdiv256(A)     ((A)>>8)
#define IQdiv512(A)     ((A)>>9)
#define IQdiv1024(A)    ((A)>>10)

//-------------------------------------------------------------------
typedef int32_t         iq30_t;
typedef int32_t         iq29_t;
typedef int32_t         iq28_t;
typedef int32_t         iq27_t;
typedef int32_t         iq26_t;
typedef int32_t         iq25_t;
typedef int32_t         iq24_t;
typedef int32_t         iq23_t;
typedef int32_t         iq22_t;
typedef int32_t         iq21_t;
typedef int32_t         iq20_t;
typedef int32_t         iq19_t;
typedef int32_t         iq18_t;
typedef int32_t         iq17_t;
typedef int32_t         iq16_t;
typedef int32_t         iq15_t;
typedef int32_t         iq14_t;
typedef int32_t         iq13_t;
typedef int32_t         iq12_t;
typedef int32_t         iq11_t;
typedef int32_t         iq10_t;
typedef int32_t         iq9_t;
typedef int32_t         iq8_t;
typedef int32_t         iq7_t;
typedef int32_t         iq6_t;
typedef int32_t         iq5_t;
typedef int32_t         iq4_t;
typedef int32_t         iq3_t;
typedef int32_t         iq2_t;
typedef int32_t         iq1_t;
typedef int32_t         iq0_t;

//-------------------------------------------------------------------
extern iq21_t _IQ21cos(iq21_t x);
extern iq21_t _IQ21sin(iq21_t x);
extern iq21_t _IQ21sqrt(iq21_t x);
extern iq21_t _IQ21atan2(iq21_t y, iq21_t x);
extern iq21_t _IQ21abs(iq21_t x);

#define IQcos(x)        _IQ21cos(x)
#define IQsin(x)        _IQ21sin(x)
#define IQsqrt(x)       _IQ21sqrt(x)
#define IQatan2(y,x)    _IQ21atan2(y, x)
#define IQabs(x)        (((x) < 0) ? -(x) : (x))

//-------------------------------------------------------------------
#define IQ30(A)         (iq30_t)((A) * 1073741824)
#define IQ29(A)         (iq29_t)((A) * 536870912)
#define IQ28(A)         (iq28_t)((A) * 268435456)
#define IQ27(A)         (iq27_t)((A) * 134217728)
#define IQ26(A)         (iq26_t)((A) * 67108864)
#define IQ25(A)         (iq25_t)((A) * 33554432)
#define IQ24(A)         (iq24_t)((A) * 16777216)
#define IQ23(A)         (iq23_t)((A) * 8388608)
#define IQ22(A)         (iq22_t)((A) * 4194304)
#define IQ21(A)         (iq21_t)((A) * 2097152)
#define IQ20(A)         (iq20_t)((A) * 1048576)
#define IQ19(A)         (iq19_t)((A) * 524288)
#define IQ18(A)         (iq18_t)((A) * 262144)
#define IQ17(A)         (iq17_t)((A) * 131072)
#define IQ16(A)         (iq16_t)((A) * 65536)
#define IQ15(A)         (iq15_t)((A) * 32768)
#define IQ14(A)         (iq14_t)((A) * 16384)
#define IQ13(A)         (iq13_t)((A) * 8192)
#define IQ12(A)         (iq12_t)((A) * 4096)
#define IQ11(A)         (iq11_t)((A) * 2048)
#define IQ10(A)         (iq10_t)((A) * 1024)
#define IQ9(A)          (iq9_t)((A) * 512)
#define IQ8(A)          (iq8_t)((A) * 256)
#define IQ7(A)          (iq7_t)((A) * 128)
#define IQ6(A)          (iq6_t)((A) * 64)
#define IQ5(A)          (iq5_t)((A) * 32)
#define IQ4(A)          (iq4_t)((A) * 16)
#define IQ3(A)          (iq3_t)((A) * 8)
#define IQ2(A)          (iq2_t)((A) * 4)
#define IQ1(A)          (iq1_t)((A) * 2)
#define IQ0(A)          (iq0_t)((A) * 1)

//-------------------------------------------------------------------
#define IQtoIQ30(A)     ((iq30_t)(A)<<9)
#define IQtoIQ29(A)     ((iq29_t)(A)<<8)
#define IQtoIQ28(A)     ((iq28_t)(A)<<7)
#define IQtoIQ27(A)     ((iq27_t)(A)<<6)
#define IQtoIQ26(A)     ((iq26_t)(A)<<5)
#define IQtoIQ25(A)     ((iq25_t)(A)<<4)
#define IQtoIQ24(A)     ((iq24_t)(A)<<3)
#define IQtoIQ23(A)     ((iq23_t)(A)<<2)
#define IQtoIQ22(A)     ((iq22_t)(A)<<1)
#define IQtoIQ21(A)     ((iq21_t)(A))
#define IQtoIQ20(A)     ((iq20_t)(A)>>1)
#define IQtoIQ19(A)     ((iq19_t)(A)>>2)
#define IQtoIQ18(A)     ((iq18_t)(A)>>3)
#define IQtoIQ17(A)     ((iq17_t)(A)>>4)
#define IQtoIQ16(A)     ((iq16_t)(A)>>5)
#define IQtoIQ15(A)     ((iq15_t)(A)>>6)
#define IQtoIQ14(A)     ((iq14_t)(A)>>7)
#define IQtoIQ13(A)     ((iq13_t)(A)>>8)
#define IQtoIQ12(A)     ((iq12_t)(A)>>9)
#define IQtoIQ11(A)     ((iq11_t)(A)>>10)
#define IQtoIQ10(A)     ((iq10_t)(A)>>11)
#define IQtoIQ9(A)      ((iq9_t)(A)>>12)
#define IQtoIQ8(A)      ((iq8_t)(A)>>13)
#define IQtoIQ7(A)      ((iq7_t)(A)>>14)
#define IQtoIQ6(A)      ((iq6_t)(A)>>15)
#define IQtoIQ5(A)      ((iq5_t)(A)>>16)
#define IQtoIQ4(A)      ((iq4_t)(A)>>17)
#define IQtoIQ3(A)      ((iq3_t)(A)>>18)
#define IQtoIQ2(A)      ((iq2_t)(A)>>19)
#define IQtoIQ1(A)      ((iq1_t)(A)>>20)
#define IQtoIQ0(A)      ((iq0_t)(A)>>21)

//-------------------------------------------------------------------
#define IQ30toIQ(A)     ((iq_t)(A)>>9)
#define IQ29toIQ(A)     ((iq_t)(A)>>8)
#define IQ28toIQ(A)     ((iq_t)(A)>>7)
#define IQ27toIQ(A)     ((iq_t)(A)>>6)
#define IQ26toIQ(A)     ((iq_t)(A)>>5)
#define IQ25toIQ(A)     ((iq_t)(A)>>4)
#define IQ24toIQ(A)     ((iq_t)(A)>>3)
#define IQ23toIQ(A)     ((iq_t)(A)>>2)
#define IQ22toIQ(A)     ((iq_t)(A)>>1)
#define IQ21toIQ(A)     ((iq_t)(A))
#define IQ20toIQ(A)     ((iq_t)(A)<<1)
#define IQ19toIQ(A)     ((iq_t)(A)<<2)
#define IQ18toIQ(A)     ((iq_t)(A)<<3)
#define IQ17toIQ(A)     ((iq_t)(A)<<4)
#define IQ16toIQ(A)     ((iq_t)(A)<<5)
#define IQ15toIQ(A)     ((iq_t)(A)<<6)
#define IQ14toIQ(A)     ((iq_t)(A)<<7)
#define IQ13toIQ(A)     ((iq_t)(A)<<8)
#define IQ12toIQ(A)     ((iq_t)(A)<<9)
#define IQ11toIQ(A)     ((iq_t)(A)<<10)
#define IQ10toIQ(A)     ((iq_t)(A)<<11)
#define IQ9toIQ(A)      ((iq_t)(A)<<12)
#define IQ8toIQ(A)      ((iq_t)(A)<<13)
#define IQ7toIQ(A)      ((iq_t)(A)<<14)
#define IQ6toIQ(A)      ((iq_t)(A)<<15)
#define IQ5toIQ(A)      ((iq_t)(A)<<16)
#define IQ4toIQ(A)      ((iq_t)(A)<<17)
#define IQ3toIQ(A)      ((iq_t)(A)<<18)
#define IQ2toIQ(A)      ((iq_t)(A)<<19)
#define IQ1toIQ(A)      ((iq_t)(A)<<20)
#define IQ0toIQ(A)      ((iq_t)(A)<<21)

//-------------------------------------------------------------------
#define IQ30mpy(A,B)    (iq_t)(((int64_t)(A)*(B))>>30)
#define IQ29mpy(A,B)    (iq_t)(((int64_t)(A)*(B))>>29)
#define IQ28mpy(A,B)    (iq_t)(((int64_t)(A)*(B))>>28)
#define IQ27mpy(A,B)    (iq_t)(((int64_t)(A)*(B))>>27)
#define IQ26mpy(A,B)    (iq_t)(((int64_t)(A)*(B))>>26)
#define IQ25mpy(A,B)    (iq_t)(((int64_t)(A)*(B))>>25)
#define IQ24mpy(A,B)    (iq_t)(((int64_t)(A)*(B))>>24)
#define IQ23mpy(A,B)    (iq_t)(((int64_t)(A)*(B))>>23)
#define IQ22mpy(A,B)    (iq_t)(((int64_t)(A)*(B))>>22)
#define IQ21mpy(A,B)    (iq_t)(((int64_t)(A)*(B))>>21)
#define IQ20mpy(A,B)    (iq_t)(((int64_t)(A)*(B))>>20)
#define IQ19mpy(A,B)    (iq_t)(((int64_t)(A)*(B))>>19)
#define IQ18mpy(A,B)    (iq_t)(((int64_t)(A)*(B))>>18)
#define IQ17mpy(A,B)    (iq_t)(((int64_t)(A)*(B))>>17)
#define IQ16mpy(A,B)    (iq_t)(((int64_t)(A)*(B))>>16)
#define IQ15mpy(A,B)    (iq_t)(((int64_t)(A)*(B))>>15)
#define IQ14mpy(A,B)    (iq_t)(((int64_t)(A)*(B))>>14)
#define IQ13mpy(A,B)    (iq_t)(((int64_t)(A)*(B))>>13)
#define IQ12mpy(A,B)    (iq_t)(((int64_t)(A)*(B))>>12)
#define IQ11mpy(A,B)    (iq_t)(((int64_t)(A)*(B))>>11)
#define IQ10mpy(A,B)    (iq_t)(((int64_t)(A)*(B))>>10)
#define IQ9mpy(A,B)     (iq_t)(((int64_t)(A)*(B))>>9)
#define IQ8mpy(A,B)     (iq_t)(((int64_t)(A)*(B))>>8)
#define IQ7mpy(A,B)     (iq_t)(((int64_t)(A)*(B))>>7)
#define IQ6mpy(A,B)     (iq_t)(((int64_t)(A)*(B))>>6)
#define IQ5mpy(A,B)     (iq_t)(((int64_t)(A)*(B))>>5)
#define IQ4mpy(A,B)     (iq_t)(((int64_t)(A)*(B))>>4)
#define IQ3mpy(A,B)     (iq_t)(((int64_t)(A)*(B))>>3)
#define IQ2mpy(A,B)     (iq_t)(((int64_t)(A)*(B))>>2)
#define IQ1mpy(A,B)     (iq_t)(((int64_t)(A)*(B))>>1)
#define IQ0mpy(A,B)     (iq_t)(((int64_t)(A)*(B))>>0)

//-------------------------------------------------------------------
#define IQ30div(A,B)    (iq_t)(((int64_t)(A)<<30) / (B))
#define IQ29div(A,B)    (iq_t)(((int64_t)(A)<<29) / (B))
#define IQ28div(A,B)    (iq_t)(((int64_t)(A)<<28) / (B))
#define IQ27div(A,B)    (iq_t)(((int64_t)(A)<<27) / (B))
#define IQ26div(A,B)    (iq_t)(((int64_t)(A)<<26) / (B))
#define IQ25div(A,B)    (iq_t)(((int64_t)(A)<<25) / (B))
#define IQ24div(A,B)    (iq_t)(((int64_t)(A)<<24) / (B))
#define IQ23div(A,B)    (iq_t)(((int64_t)(A)<<23) / (B))
#define IQ22div(A,B)    (iq_t)(((int64_t)(A)<<22) / (B))
#define IQ21div(A,B)    (iq_t)(((int64_t)(A)<<21) / (B))
#define IQ20div(A,B)    (iq_t)(((int64_t)(A)<<20) / (B))
#define IQ19div(A,B)    (iq_t)(((int64_t)(A)<<19) / (B))
#define IQ18div(A,B)    (iq_t)(((int64_t)(A)<<18) / (B))
#define IQ17div(A,B)    (iq_t)(((int64_t)(A)<<17) / (B))
#define IQ16div(A,B)    (iq_t)(((int64_t)(A)<<16) / (B))
#define IQ15div(A,B)    (iq_t)(((int64_t)(A)<<15) / (B))
#define IQ14div(A,B)    (iq_t)(((int64_t)(A)<<14) / (B))
#define IQ13div(A,B)    (iq_t)(((int64_t)(A)<<13) / (B))
#define IQ12div(A,B)    (iq_t)(((int64_t)(A)<<12) / (B))
#define IQ11div(A,B)    (iq_t)(((int64_t)(A)<<11) / (B))
#define IQ10div(A,B)    (iq_t)(((int64_t)(A)<<10) / (B))
#define IQ9div(A,B)     (iq_t)(((int64_t)(A)<<9) / (B))
#define IQ8div(A,B)     (iq_t)(((int64_t)(A)<<8) / (B))
#define IQ7div(A,B)     (iq_t)(((int64_t)(A)<<7) / (B))
#define IQ6div(A,B)     (iq_t)(((int64_t)(A)<<6) / (B))
#define IQ5div(A,B)     (iq_t)(((int64_t)(A)<<5) / (B))
#define IQ4div(A,B)     (iq_t)(((int64_t)(A)<<4) / (B))
#define IQ3div(A,B)     (iq_t)(((int64_t)(A)<<3) / (B))
#define IQ2div(A,B)     (iq_t)(((int64_t)(A)<<2) / (B))
#define IQ1div(A,B)     (iq_t)(((int64_t)(A)<<1) / (B))
#define IQ0div(A,B)     (iq_t)(((int64_t)(A)<<0) / (B))

//-------------------------------------------------------------------
#define IQ30toF(A)      ((float)(A)*(9.313226e-10))
#define IQ29toF(A)      ((float)(A)*(1.862645e-09))
#define IQ28toF(A)      ((float)(A)*(3.72529e-09))
#define IQ27toF(A)      ((float)(A)*(7.450581e-09))
#define IQ26toF(A)      ((float)(A)*(1.490116e-08))
#define IQ25toF(A)      ((float)(A)*(2.980232e-08))
#define IQ24toF(A)      ((float)(A)*(5.960464e-08))
#define IQ23toF(A)      ((float)(A)*(1.192093e-07))
#define IQ22toF(A)      ((float)(A)*(2.384186e-07))
#define IQ21toF(A)      ((float)(A)*(4.768372e-07))
#define IQ20toF(A)      ((float)(A)*(9.536743e-07))
#define IQ19toF(A)      ((float)(A)*(1.907349e-06))
#define IQ18toF(A)      ((float)(A)*(3.814697e-06))
#define IQ17toF(A)      ((float)(A)*(7.629395e-06))
#define IQ16toF(A)      ((float)(A)*(1.525879e-05))
#define IQ15toF(A)      ((float)(A)*(3.051758e-05))
#define IQ14toF(A)      ((float)(A)*(6.103516e-05))
#define IQ13toF(A)      ((float)(A)*(0.0001220703))
#define IQ12toF(A)      ((float)(A)*(0.0002441406))
#define IQ11toF(A)      ((float)(A)*(0.0004882813))
#define IQ10toF(A)      ((float)(A)*(0.0009765625))
#define IQ9toF(A)       ((float)(A)*(0.001953125))
#define IQ8toF(A)       ((float)(A)*(0.00390625))
#define IQ7toF(A)       ((float)(A)*(0.0078125))
#define IQ6toF(A)       ((float)(A)*(0.015625))
#define IQ5toF(A)       ((float)(A)*(0.03125))
#define IQ4toF(A)       ((float)(A)*(0.0625))
#define IQ3toF(A)       ((float)(A)*(0.125))
#define IQ2toF(A)       ((float)(A)*(0.25))
#define IQ1toF(A)       ((float)(A)*(0.5))
#define IQ0toF(A)       ((float)(A)*(1))


#endif /* IQMATH_INT32_MCU_H */
