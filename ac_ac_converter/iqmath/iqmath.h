#ifndef IQMATH_H
#define IQMATH_H

#include "stdint.h"

// include one of options
//-------------------------------------------------------------------
//#include "iqmath_float32.h"
//#include "iqmath_int32_pc.h"
//#include "iqmath_int32_mcu.h"

#include "IQmathLib.h"

#ifdef __cplusplus
extern "C"
{
#endif

#define IQMATH_INT32            1
#define IQMATH_INT32_MCU        1	
	
typedef int32_t iq_t;

#define Q0              0

//-------------------------------------------------------------------
#define IQ_MAX_INT      (int32_t)(((int32_t)1<<10)-1)
#define IQ_MIN_INT      (int32_t)(-((int32_t)1<<10))

#define IQ(A)           _IQ(A)

#define IQ2INT(A)       ((A)>>Q_GLOBAL)
#define IQ2FLOAT(A)     _IQtoF(A)

#define IQmpy(A,B)      _IQmpy(A,B)
#define IQdiv(A,B)      _IQdiv(A,B)

#define IQlsh(A,bits)   ((iq_t)(A)<<(bits))
#define IQrsh(A,bits)   ((iq_t)(A)>>(bits))

#define IQlsh_signed(x, sh) (sh>=0 ? IQlsh(x, sh) : IQrsh(x, -sh))
#define IQrsh_signed(x, sh) (sh>=0 ? IQrsh(x, sh) : IQlsh(x, -sh))

extern iq_t IQdiv_safe(iq_t num, iq_t den);

//-------------------------------------------------------------------
#define IQmpy2(A)       _IQmpy2(A)
#define IQmpy4(A)       _IQmpy4(A)
#define IQmpy8(A)       _IQmpy8(A)
#define IQmpy16(A)      _IQmpy16(A)       
#define IQmpy32(A)      _IQmpy32(A)       
#define IQmpy64(A)      _IQmpy64(A)       
#define IQmpy128(A)     _IQmpy128(A)       
#define IQmpy256(A)     _IQmpy256(A)       
#define IQmpy512(A)     _IQmpy512(A)       
#define IQmpy1024(A)    _IQmpy1024(A)       

#define IQdiv2(A)       _IQdiv2(A)
#define IQdiv4(A)       _IQdiv4(A)
#define IQdiv8(A)       _IQdiv8(A)
#define IQdiv16(A)      _IQdiv16(A)
#define IQdiv32(A)      _IQdiv32(A)
#define IQdiv64(A)      _IQdiv64(A)
#define IQdiv128(A)     _IQdiv128(A)
#define IQdiv256(A)     _IQdiv256(A)
#define IQdiv512(A)     _IQdiv512(A)
#define IQdiv1024(A)    _IQdiv1024(A)

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

#define IQcos(x)        _IQcos(x)
#define IQsin(x)        _IQsin(x)
#define IQsqrt(x)       _IQsqrt(x)
#define IQatan2(y,x)    _IQatan2(y, x)
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
extern float _IQ0toF(iq0_t A);

#define IQ30toF(A)      _IQ30toF(A)
#define IQ29toF(A)      _IQ29toF(A)
#define IQ28toF(A)      _IQ28toF(A)
#define IQ27toF(A)      _IQ27toF(A)
#define IQ26toF(A)      _IQ26toF(A)
#define IQ25toF(A)      _IQ25toF(A)
#define IQ24toF(A)      _IQ24toF(A)
#define IQ23toF(A)      _IQ23toF(A)
#define IQ22toF(A)      _IQ22toF(A)
#define IQ21toF(A)      _IQ21toF(A)
#define IQ20toF(A)      _IQ20toF(A)
#define IQ19toF(A)      _IQ19toF(A)
#define IQ18toF(A)      _IQ18toF(A)
#define IQ17toF(A)      _IQ17toF(A)
#define IQ16toF(A)      _IQ16toF(A)
#define IQ15toF(A)      _IQ15toF(A)
#define IQ14toF(A)      _IQ14toF(A)
#define IQ13toF(A)      _IQ13toF(A)
#define IQ12toF(A)      _IQ12toF(A)
#define IQ11toF(A)      _IQ11toF(A)
#define IQ10toF(A)      _IQ10toF(A)
#define IQ9toF(A)       _IQ9toF(A)
#define IQ8toF(A)       _IQ8toF(A)
#define IQ7toF(A)       _IQ7toF(A)
#define IQ6toF(A)       _IQ6toF(A)
#define IQ5toF(A)       _IQ5toF(A)
#define IQ4toF(A)       _IQ4toF(A)
#define IQ3toF(A)       _IQ3toF(A)
#define IQ2toF(A)       _IQ2toF(A)
#define IQ1toF(A)       _IQ1toF(A)
#define IQ0toF(A)       _IQ0toF(A)

#ifdef __cplusplus
}
#endif

#endif /* IQMATH_H */
