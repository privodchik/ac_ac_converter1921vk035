// Date: 19.02.2021
// Creator: ID

#ifndef _UTILITY_H
#define _UTILITY_H

#include <cstdint>
#include <utility>

template<class T>
T set_bit(T _bitNo){
    return
        static_cast<T>(1) << _bitNo;
}


enum eQuant{
    eQ0 = 0,
    eQ1 = 1,
    eQ2 = 2,
    eQ3 = 3,
    eQ4 = 4,
    eQ5 = 5,
    eQ6 = 6,
    eQ7 = 7,
    eQ8 = 8,
    eQ9 = 9,
    eQ10 = 10,
    eQ11 = 11,
    eQ12 = 12,
    eQ13 = 13,
    eQ14 = 14,
    eQ15 = 15,

    eQ24 = 24
};


template<class T, std::size_t N>
constexpr std::size_t array_size(T (&)[N]){
    return N;
}

#define ABS(x) ((x) < 0 ? (-x) : (x))


#endif //_UTILITY_H
