#ifndef ATOMIC_H
#define ATOMIC_H

//-------------------------------------------------------------------
#define USE_ATOMIC_BLOCK    uint32_t ab_flag, ab_primask
#define ATOMIC_BLOCK_BEGIN  ab_primask = __get_PRIMASK(); __disable_irq(); ab_flag=1
#define ATOMIC_BLOCK_END    if(ab_flag) __set_PRIMASK(ab_primask); ab_flag=0

// should never return or break atomic block
#define ATOMIC_BLOCK                                              \
    for(ab_primask = __get_PRIMASK(), __disable_irq(), ab_flag=1; \
       ab_flag;                                                   \
       __set_PRIMASK(ab_primask), ab_flag=0)


#endif /* ATOMIC_H */
