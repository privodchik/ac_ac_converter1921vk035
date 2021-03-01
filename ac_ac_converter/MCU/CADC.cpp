// Date: 28.02.2021
// Creator: ID

#include "CADC.h"
#include "aux_utility.h"

const uint32_t ADC_CLK_DIV = 4;

uint16_t adcBuffer[11]{0};

CADCModule adc_modules[11] = {
    CADCModule{0, ADC_CLK_DIV},
    CADCModule{1, ADC_CLK_DIV},
    CADCModule{2, ADC_CLK_DIV},
    CADCModule{3, ADC_CLK_DIV},
    CADCModule{4, ADC_CLK_DIV},
    CADCModule{5, ADC_CLK_DIV},
    CADCModule{6, ADC_CLK_DIV},
    CADCModule{7, ADC_CLK_DIV},
    CADCModule{8, ADC_CLK_DIV},
    CADCModule{9, ADC_CLK_DIV},
    CADCModule{10, ADC_CLK_DIV},
};

constexpr bool adc_modules_init(){
    for (int i = 0; i < array_size(adc_modules); i++)
        adc_modules[i] = CADCModule{i, ADC_CLK_DIV};
    return true;
}



