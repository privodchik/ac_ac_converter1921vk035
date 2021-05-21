// Date: 28.02.2021
// Creator: ID

#ifndef _CADC_H
#define _CADC_H

#include "IPheriphery.h"
#include "plib035_adc.h"
#include <utility>
#include "aux_utility.h"
#include "plib035.h"


class CADC : public IPheriphery
{
    
};

extern uint16_t adcBuffer[];


#endif //_CADC_H
