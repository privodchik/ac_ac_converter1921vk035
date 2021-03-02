#include "stdint_ext.h"
#include "str_utils.h"

//-------------------------------------------------------------------
static char lower(char c) {
    if((c >= 'A') && (c <= 'Z')) return (char)(c|0x20);
    return c;
}

//-------------------------------------------------------------------
static char upper(char c) {
    if((c >= 'a') && (c <= 'z')) return (char)(c&(~0x20));
    return c;
}

//-------------------------------------------------------------------
static int16_t samechar_nocase(char c1, char c2) {
    if(c1 == c2) return 1;
    if(lower(c1) == lower(c2)) return 1;
    return 0;
}

//-------------------------------------------------------------------
int16_t strlen_alt(const char *s)
{
    int16_t len;
    if(!s) return 0;
    len = 0;
    while(*s) {
        s++;
        len++;
        if(len > 512) {
            return 0; // failsafe, avoid too long garbage
        }
    }
    return len;
}

//-------------------------------------------------------------------
int16_t samestr_nocase(const char *s1, const char *s2)
{
    if(!s1) return 0;
    if(!s2) return 0;
    while((*s1) && (*s2)) {
        if(!samechar_nocase(*s1, *s2)) {
            return 0;
        }
        s1++;
        s2++;
    }
    if(!(*s1) && !(*s2)) {
        return 1;
    }
    return 0;
}

//-------------------------------------------------------------------
int16_t startswith_nocase(const char *s1, const char *s2)
{
    if(!s1) return 0;
    if(!s2) return 0;
    while((*s1) && (*s2)) {
        if(!samechar_nocase(*s1, *s2)) {
            return 0;
        }
        s1++;
        s2++;
    }
    if(!(*s2)) {
        return 1;
    }
    return 0;
}
