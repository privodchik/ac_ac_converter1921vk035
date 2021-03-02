#include "gpio_hw.h"
#include "config.h"


//-------------------------------------------------------------------
void gpio_hw_init()
{
    GPIO_Init_TypeDef GPIO_InitStruct;   
    GPIO_StructInit(&GPIO_InitStruct);
    GPIO_InitStruct.GPIO_Mode = GPIO_Mode_IO;
//    GPIO_InitStruct.GPIO_AltFunc = GPIO_AltFunc_1;
    GPIO_InitStruct.GPIO_Dir = GPIO_Dir_Out;
    GPIO_InitStruct.GPIO_OutMode = GPIO_OutMode_PP;
    GPIO_InitStruct.GPIO_Out = GPIO_Out_En;
    GPIO_InitStruct.GPIO_PullUp = GPIO_PullUp_Dis;
    
    // RS485_3_TX PF7
    GPIO_InitStruct.GPIO_Pin = GPIO_Pin_9;
    GPIO_Init(NT_GPIOF, &GPIO_InitStruct);

    // RS485_2_TX PF6
    GPIO_InitStruct.GPIO_Pin = GPIO_Pin_8;
    GPIO_Init(NT_GPIOF, &GPIO_InitStruct);

}

//-------------------------------------------------------------------
void gpio_hw_deinit()
{
    GPIO_DeInit(NT_GPIOA);
    GPIO_DeInit(NT_GPIOB);
    GPIO_DeInit(NT_GPIOC);
    GPIO_DeInit(NT_GPIOD);
    GPIO_DeInit(NT_GPIOE);
    GPIO_DeInit(NT_GPIOF);
    GPIO_DeInit(NT_GPIOG);
    GPIO_DeInit(NT_GPIOH);
}
