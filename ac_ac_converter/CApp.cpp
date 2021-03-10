// Date: 24.02.2021
// Created: ID

#include "CApp.h"
#include "mcu.h"
#include "niietcm4_rcc.h"
#include "modbus_regs.h"
#include "modbus_config.h"
#include "modbus_rtu.h"
#include "modbus_scope.h"
#include "clock.h"
#include "gpio.h"
#include "config.h"


const int ERRORS_BUFFER_SIZE = 5;
CErrors::eError_t errorBuffer[ERRORS_BUFFER_SIZE]; 


CApp::CApp(){
    
    sensors[0] = &sens_iFull;
    sensors[1] = &sens_iLoad;
    sensors[2] = &sens_uBUSP_N;
    sensors[3] = &sens_uBUSN_N;
    sensors[4] = &sens_uOut;
    
    states[IState::eState::INIT]= &stInit;
    states[IState::eState::CHARGE]= &stCharge;
    states[IState::eState::READY]= &stReady;
    states[IState::eState::FAULT]= &stFault;
    IState::states_array_register(states);
}

static const uint32_t SYSTEM_CLOCK = 100000000;

void CApp::init(){
    CMCU(SYSTEM_CLOCK).init();
    
    __disable_irq();

    leds_init();
    pwm_init();
    adc_init();
    
    gpio_init();
    modbus_regs_enter_password(modbus1_password);
    modbus1_init();
    
    __enable_irq();
}


void CApp::run(){
    
    while (true){
        
//        (stInit.stInit.*ptrFunc)();
        
        counting++;
//        ledWORK.blinking_task(TIME_SEC(5.0));
        modbus_rtu_task(); // on uart2
        gpio_task();
        
        sm.operate();
    }
}


void CApp::isr(time_t _period){
    
//    sm.critical_operate();
    clock_tick(_period);
    modbus_scope_tick(_period);
    uart_hw_task(); // here or in background loop
    
}


void CApp::leds_init(){
    CPin _pin{CPin::ePort::PORT_E, CPin::ePin::Pin_4}; 
    
    _pin.direction_set(CPin::eDir::OUT);
    _pin.alt_func_set(CPin::eAltFunc::ALTFUNC_1);
    _pin.mode_set(CPin::eMode::IO);
    _pin.out_mode(CPin::eOutMode::PUSH_PULL);
    _pin.pullUp_set(IPheriphery::eState::ON);    
    _pin.out_allow(IPheriphery::eState::ON);
    _pin.config_set();

    ledWORK.define_pin(_pin);
}

void CApp::pwm_init(){
    
    pwm_A.freq_set(FREQ_KHZ);
    pwm_B.freq_set(FREQ_KHZ);
    
    const uint32_t PWM_MAX = pwm_A.freq_in_ticks_get(); // or pwm_B.freq_in_ticks_get()
    
    RCC_PeriphClkCmd(RCC_PeriphClk_PWM0, ENABLE);
    RCC_PeriphRstCmd(RCC_PeriphRst_PWM0, ENABLE);
    RCC_PeriphClkCmd(RCC_PeriphClk_PWM1, ENABLE);
    RCC_PeriphRstCmd(RCC_PeriphRst_PWM1, ENABLE);
    
    PWM_CTR_Init_TypeDef PWM_CTR_InitStruct; 
    //Channel_0 is Master
    PWM_CTR_StructInit(&PWM_CTR_InitStruct);
    PWM_CTR_InitStruct.PWM_ChAction_CTREqZero_A =  PWM_ChAction_ToZero;
    PWM_CTR_InitStruct.PWM_CTR_Mode = PWM_CTR_Mode_UpDown;
    PWM_CTR_InitStruct.PWM_CTR_Dir_Phase = PWM_CTR_Dir_Up;
    PWM_CTR_InitStruct.PWM_Period = PWM_MAX/2 - 1;
    PWM_CTR_InitStruct.PWM_CTR_SyncOut = PWM_CTR_SyncOut_CTREqZero;
    PWM_CTR_Init(NT_PWM0, &PWM_CTR_InitStruct);

    //Channel_1 is Slave
    PWM_CTR_StructInit(&PWM_CTR_InitStruct);
    PWM_CTR_InitStruct.PWM_ChAction_CTREqZero_A =  PWM_ChAction_ToZero;
    PWM_CTR_InitStruct.PWM_CTR_Mode = PWM_CTR_Mode_UpDown;
    PWM_CTR_InitStruct.PWM_Period = PWM_MAX/2 - 1;
    PWM_CTR_InitStruct.PWM_CTR_SyncOut=PWM_CTR_SyncOut_SyncIn;
    PWM_CTR_Init(NT_PWM1, &PWM_CTR_InitStruct);
    
    //Comparators Initialization
    PWM_CMP_Init_TypeDef PWM_CMP_InitStruct;
    PWM_CMP_StructInit(&PWM_CMP_InitStruct);
    
    PWM_CMP_InitStruct.PWM_ChAction_CTREqCMPA_Up_A = PWM_ChAction_ToOne;
    PWM_CMP_InitStruct.PWM_ChAction_CTREqCMPA_Down_A = PWM_ChAction_ToZero;
    
    PWM_CMP_InitStruct.PWM_ChAction_CTREqCMPA_Up_B =   PWM_ChAction_ToZero;
    PWM_CMP_InitStruct.PWM_ChAction_CTREqCMPA_Down_B = PWM_ChAction_ToOne;
    
    PWM_CMP_InitStruct.PWM_CMPB = 0;
    PWM_CMP_InitStruct.PWM_CMPA = 0;
    
    PWM_CMP_Init(NT_PWM0, &PWM_CMP_InitStruct);
    PWM_CMP_Init(NT_PWM1, &PWM_CMP_InitStruct);
    
    // DTG Initialization
    
    PWM_DB_Init_TypeDef PWM_DTG_InitStruct;
    PWM_DB_StructInit(&PWM_DTG_InitStruct);
      /* inversion enable*/
//    PWM_DTG_InitStruct.PWM_DB_In = PWM_DB_In_AFallBRise;
//    PWM_DTG_InitStruct.PWM_DB_Out = PWM_DB_Out_DelayAB;
//    PWM_DTG_InitStruct.PWM_DB_Pol = PWM_DB_Pol_ActLowCompl;

      /* inversion disable*/
    PWM_DTG_InitStruct.PWM_DB_In = PWM_DB_In_ARiseBFall;
    PWM_DTG_InitStruct.PWM_DB_Out = PWM_DB_Out_DelayAB;
//    PWM_DTG_InitStruct.PWM_DB_Pol = PWM_DB_Pol_ActHighCompl;
    PWM_DTG_InitStruct.PWM_DB_Pol = PWM_DB_Pol_ActHigh;
    
    PWM_DTG_InitStruct.PWM_DB_RiseDelay = 50; //500 ns
    PWM_DTG_InitStruct.PWM_DB_FallDelay = 50; //500 ns
    PWM_DB_Init(NT_PWM0, &PWM_DTG_InitStruct);
    PWM_DB_Init(NT_PWM1, &PWM_DTG_InitStruct);
    
    
    // PWM Pins Configuration
    // PWM_A0
    CPin _pin{CPin::ePort::PORT_G, CPin::ePin::Pin_2};
    _pin.mode_set(CPin::eMode::ALT_FUNC);
    _pin.alt_func_set(CPin::eAltFunc::ALTFUNC_1);
    _pin.direction_set(CPin::eDir::OUT);
    _pin.out_allow(IPheriphery::eState::ON);
    _pin.config_set();
    
    // PWM_A1
    _pin.pin_set(CPin::ePin::Pin_3);
    _pin.config_set();
    
    // PWM_B0
    _pin.port_set(CPin::ePort::PORT_A);
    _pin.pin_set(CPin::ePin::Pin_10);
    _pin.alt_func_set(CPin::eAltFunc::ALTFUNC_3);
    _pin.config_set();
    
     // PWM_B1
    _pin.pin_set(CPin::ePin::Pin_11);
    _pin.config_set();
    
     //ADC starts from PWM0 event
    PWM_ET_Init_TypeDef PWM_ET_InitStruct;
    PWM_ET_StructInit(&PWM_ET_InitStruct);
    PWM_ET_InitStruct.PWM_ET_Event_A = PWM_Event_CTREqZero;
    PWM_ET_InitStruct.PWM_ET_Period_A = 0;
    PWM_ET_Init(NT_PWM0, &PWM_ET_InitStruct);
    PWM_ET_Cmd(NT_PWM0, PWM_ET_Channel_A, ENABLE);
    
    
    
    pwm_A.out_disable();
    pwm_B.out_disable();    
    
    PWM_PrescCmd(PWM_Presc_0 | PWM_Presc_1, ENABLE);
    
    __NVIC_EnableIRQ(PWM0_IRQn);
    PWM_ITConfig(NT_PWM0, PWM_Event_CTREqZero, 0);
    PWM_ITCmd(NT_PWM0, ENABLE);
}

void CApp::adc_init(){
    
    for (int i = 0; i < 24; i++)
      ADC_DC_DeInit(static_cast<ADC_DC_Module_TypeDef>(i));

    RCC_PeriphClkCmd(RCC_PeriphClk_ADC, ENABLE);


    ADC_Init_TypeDef ADC_InitStruct;
    ADC_StructInit(&ADC_InitStruct);
    ADC_InitStruct.ADC_Resolution = ADC_Resolution_12bit;
    ADC_InitStruct.ADC_Average = ADC_Average_Disable;
    ADC_InitStruct.ADC_Mode = ADC_Mode_Active;
//    uint32_t _phase = 300;
    uint32_t _phase = 0;
    ADC_InitStruct.ADC_Phase = _phase;

    for (int i = 0; i < array_size(adc_modules); i++){
        RCC_ADCClkDivConfig(static_cast<RCC_ADCClk_TypeDef>(i), adc.get_module(i).clk_div_get(), ENABLE);
        RCC_ADCClkCmd(static_cast<RCC_ADCClk_TypeDef>(i), ENABLE);
        ADC_Init(static_cast<ADC_Module_TypeDef>(i), &ADC_InitStruct);
        ADC_Cmd(static_cast<ADC_Module_TypeDef>(i), ENABLE);
    }

    // Sequencers 0 & 1 work from PWM
    ADC_SEQ_Init_TypeDef ADC_SEQ_InitStruct;
    ADC_SEQ_StructInit(&ADC_SEQ_InitStruct);

    ADC_SEQ_InitStruct.ADC_SEQ_StartEvent =   ADC_SEQ_StartEvent_PWM012A;
    ADC_SEQ_InitStruct.ADC_SEQ_SWReqEn= ENABLE;
    ADC_SEQ_InitStruct.ADC_Channels = ( ADC_Channel_0 | ADC_Channel_2
                                       | ADC_Channel_4 | ADC_Channel_6
                                       | ADC_Channel_8 | ADC_Channel_10
                                       | ADC_Channel_12| ADC_Channel_14
                                       | ADC_Channel_16| ADC_Channel_18
                                       | ADC_Channel_20);

    ADC_SEQ_Init(ADC_SEQ_Module_0, &ADC_SEQ_InitStruct);
    ADC_SEQ_ITConfig(ADC_SEQ_Module_0, 1, ENABLE);
    ADC_SEQ_ITCmd(ADC_SEQ_Module_0, ENABLE);

//    for (int i = 0; i < 8; i++)
//      ADC_SEQ_Cmd(static_cast<ADC_SEQ_Module_TypeDef>(i), ENABLE);
    ADC_SEQ_Cmd(ADC_SEQ_Module_0, ENABLE);
    __NVIC_EnableIRQ(ADC_SEQ0_IRQn);
}

void CApp::uart_init(){
    
}


void CApp::state_machine_init(){
}


extern CApp app;

void PWM0_IRQHandler(void){
    __NVIC_ClearPendingIRQ(PWM0_IRQn);
    PWM_ITStatusClear(NT_PWM0);
    PWM_ITPendClear(NT_PWM0);
    
    app.ledWORK.set();
    
}


void ADC_SEQ0_IRQHandler(void){
    
    
    ADC_SEQ_ITStatusClear(ADC_SEQ_Module_0);
    
    
//    app.ledWORK.set();
//    for (int i = 0; i < 11; i++){
//      adcBuffer[i] = (int16_t) NT_ADC->SEQ[(uint32_t) ADC_SEQ_Module_0].FIFO_bit.DATA;
//    }
//    app.ledWORK.clear();
    
    
    app.ledWORK.set();
    
    for (int i = 0; i < array_size(adc_modules); i++){
        uint16_t _adcVal = static_cast<uint16_t>(NT_ADC->SEQ[(uint32_t) ADC_SEQ_Module_0].FIFO_bit.DATA);
        adc_modules[i].write(_adcVal);
    }
    
    app.sens_iFull.adc_val_set(adc_modules[0].read());
    app.sens_iLoad.adc_val_set(adc_modules[1].read());
    app.sens_uBUSP_N.adc_val_set(adc_modules[2].read());
    app.sens_uBUSN_N.adc_val_set(adc_modules[3].read());
    app.sens_uOut.adc_val_set(adc_modules[4].read());
    
    
//    app.ledWORK.clear();
    
    
    app.isr(TIME_USEC(50));

    while (NT_ADC->SEQ[(uint32_t) ADC_SEQ_Module_0].FSTAT != 0)
      NT_ADC->SEQ[(uint32_t) ADC_SEQ_Module_0].FIFO_bit.DATA;					  // Check AI FIFO

    app.ledWORK.clear();
}




