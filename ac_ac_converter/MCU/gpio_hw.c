#include "gpio_hw.h"
#include "config.h"


//-------------------------------------------------------------------
void gpio_hw_init()
{
    GPIO_Init_TypeDef GPIO_InitStruct;   
    GPIO_StructInit(&GPIO_InitStruct);
    GPIO_InitStruct.Digital = ENABLE;
    GPIO_InitStruct.Out = ENABLE;
    
    // RS485_1_TX PB12
    GPIO_InitStruct.Pin = GPIO_Pin_12;
    GPIO_Init(GPIOB, &GPIO_InitStruct);

    // RS485_2_TX PB13
    GPIO_InitStruct.Pin = GPIO_Pin_13;
    GPIO_Init(GPIOB, &GPIO_InitStruct);

}

//-------------------------------------------------------------------
void gpio_hw_deinit()
{
    GPIO_DeInit(GPIOA);
    GPIO_DeInit(GPIOB);
}
