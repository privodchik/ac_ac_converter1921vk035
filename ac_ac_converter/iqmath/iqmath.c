#include "iqmath.h"

#if IQMATH_INT32
//-------------------------------------------------------------------
iq_t IQdiv_safe(iq_t num, iq_t den) {
    if(den != IQ(0.0) && IQabs(den) > IQrsh(IQabs(num), 31-Q_GLOBAL)) {
        return IQdiv(num, den);
    } else {
        if(num == IQ(0.0)) return IQ(0.0);
        if(num > IQ(0.0) && den > IQ(0.0)) return IQ_MAX_INT;
        if(num < IQ(0.0) && den < IQ(0.0)) return IQ_MAX_INT;
        return IQ_MIN_INT;
    }
}
#endif

#if IQMATH_FLOAT32

#if IQMATH_FLOAT32_DEBUG
//-------------------------------------------------------------------
iq_t IQdiv_safe(iq_t num, iq_t den) {
    if(den != IQ(0.0) && IQabs(den) > IQrsh(IQabs(num), 31-Q_GLOBAL)) {
        return IQdiv(num, den);
    } else {
        if(num == IQ(0.0)) return IQ(0.0);
        if(num > IQ(0.0) && den > IQ(0.0)) return IQ_MAX_INT;
        if(num < IQ(0.0) && den < IQ(0.0)) return IQ_MAX_INT;
        return IQ_MIN_INT;
    }
}
#else
//-------------------------------------------------------------------
iq_t IQdiv_safe(iq_t num, iq_t den) {
    if(den != IQ(0.0) && (IQabs(den) > IQabs(num) * (float)1e-9)) {
        return IQdiv(num, den);
    } else {
        if(num == IQ(0.0)) return IQ(0.0);
        if(num > IQ(0.0) && den > IQ(0.0)) return (float)1e9;
        if(num < IQ(0.0) && den < IQ(0.0)) return (float)1e9;
        return (float)-1e9;
    }
}
#endif //IQMATH_FLOAT32_DEBUG

#endif // IQMATH_FLOAT32
