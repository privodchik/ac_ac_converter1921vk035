#ifndef STR_UTILS_H
#define STR_UTILS_H

#ifdef __cplusplus
extern "C" {
#endif

#include "stdint_ext.h"

//-------------------------------------------------------------------
int16_t strlen_alt(const char *s);
int16_t samestr_nocase(const char *s1, const char *s2);
int16_t startswith_nocase(const char *s1, const char *s2);

#ifdef __cplusplus
}
#endif

#endif // STR_UTILS_H

