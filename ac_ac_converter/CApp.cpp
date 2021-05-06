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

void acs(iq_t _Ts);


CApp::CApp(){
    
    sensors[0] = &sens_iFull;
    sensors[1] = &sens_iLoad;
//    sensors[2] = &sens_uBUSP_N;
//    sensors[3] = &sens_uBUSN_N;
//    sensors[4] = &sens_uOut;
    sensors[2] = &sens_uBUS;
    sensors[3] = &sens_uOut;

    IState::state_machine_register(&sm);
    
}

static const uint32_t SYSTEM_CLOCK = 100000000;

void CApp::init(){
    CMCU(SYSTEM_CLOCK).init();
    
    __disable_irq();
    
    __NVIC_SetPriority(ADC_SEQ0_IRQn, 2);
    __NVIC_SetPriority(PWM0_IRQn, 1);
    

    leds_init();
    fun_init();
    pwm_init();
    adc_init();
    
    gpio_init();
    modbus_regs_enter_password(modbus1_password);
    modbus1_init();
    
    sens_init();
    
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


#pragma inline = forced
void CApp::isr(time_t _period){
    
//    sm.critical_operate();
    clock_tick(_period);
    modbus_scope_tick(_period);
    uart_hw_task(); // here or in background loop
    acs(_period);
    
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
    ledWORK.clear();
    
    CPin _pin2{CPin::ePort::PORT_E, CPin::ePin::Pin_5}; 
    
    _pin2.direction_set(CPin::eDir::OUT);
    _pin2.alt_func_set(CPin::eAltFunc::ALTFUNC_1);
    _pin2.mode_set(CPin::eMode::IO);
    _pin2.out_mode(CPin::eOutMode::PUSH_PULL);
    _pin2.pullUp_set(IPheriphery::eState::ON);    
    _pin2.out_allow(IPheriphery::eState::ON);
    _pin2.config_set();
    
    ledADC.define_pin(_pin2);
    ledADC.clear();
}

void CApp::fun_init(){
    fun.direction_set(CPin::eDir::OUT);
    fun.mode_set(CPin::eMode::IO);
    fun.out_mode(CPin::eOutMode::PUSH_PULL);
    fun.pullUp_set(IPheriphery::eState::ON);    
    fun.out_allow(IPheriphery::eState::ON);
    fun.config_set();
    
    fun.write(FUN_OFF);
    
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
    
    PWM_CMP_InitStruct.PWM_ChAction_CTREqCMPA_Up_B =   PWM_ChAction_ToOne;
    PWM_CMP_InitStruct.PWM_ChAction_CTREqCMPA_Down_B = PWM_ChAction_ToZero;
    
    PWM_CMP_InitStruct.PWM_CMPB = PWM_MAX/4;
    PWM_CMP_InitStruct.PWM_CMPA = PWM_MAX/4;
    
    PWM_CMP_Init(NT_PWM0, &PWM_CMP_InitStruct);
    PWM_CMP_Init(NT_PWM1, &PWM_CMP_InitStruct);
    
    pwm_A.out_disable();
    pwm_B.out_disable();
    
    
    // DTG Initialization
    
    PWM_DB_Init_TypeDef PWM_DTG_InitStruct;
    PWM_DB_StructInit(&PWM_DTG_InitStruct);
      /* inversion enable*/
    PWM_DTG_InitStruct.PWM_DB_In = PWM_DB_In_ARiseBFall;
    PWM_DTG_InitStruct.PWM_DB_Out = PWM_DB_Out_DelayAB;
    PWM_DTG_InitStruct.PWM_DB_Pol = PWM_DB_Pol_ActHighCompl;

      /* inversion disable*/
//    PWM_DTG_InitStruct.PWM_DB_In = PWM_DB_In_ARiseBFall;
//    PWM_DTG_InitStruct.PWM_DB_Out = PWM_DB_Out_DelayAB;
//    PWM_DTG_InitStruct.PWM_DB_Pol = PWM_DB_Pol_ActHighCompl;
////    PWM_DTG_InitStruct.PWM_DB_Pol = PWM_DB_Pol_ActHigh;
    
    PWM_DTG_InitStruct.PWM_DB_RiseDelay = 120; //1000 ns
    PWM_DTG_InitStruct.PWM_DB_FallDelay = 120; //1000 ns
    PWM_DB_Init(NT_PWM0, &PWM_DTG_InitStruct);
    PWM_DB_Init(NT_PWM1, &PWM_DTG_InitStruct);
    
    
    
    
    pwm_A.out_disable();
    pwm_B.out_disable();
    
    
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
    
    
    pwm_A.out_disable();
    pwm_B.out_disable();
    
    
    
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
    
    
    // TZ init
    // PWM_A TZ0
    _pin = CPin(CPin::ePort::PORT_E, CPin::ePin::Pin_8);
    _pin.mode_set(CPin::eMode::ALT_FUNC);
    _pin.alt_func_set(CPin::eAltFunc::ALTFUNC_1);
    _pin.direction_set(CPin::eDir::IN);
    _pin.config_set();
    
    // PWM_B TZ1
    
    _pin.pin_set(CPin::ePin::Pin_9);
    _pin.config_set();
    
    
    pwm_A.TZ_enable(CPWM::eTZChannel::Channel_0, true);
    pwm_B.TZ_enable(CPWM::eTZChannel::Channel_1, true);
    
    __NVIC_EnableIRQ(PWM0_TZ_IRQn);
    __NVIC_EnableIRQ(PWM1_TZ_IRQn);
    
    
    
    
}

void CApp::adc_init(){
    
//    for (int i = 0; i < 24; i++)
//      ADC_DC_DeInit(static_cast<ADC_DC_Module_TypeDef>(i));
//
//    RCC_PeriphClkCmd(RCC_PeriphClk_ADC, ENABLE);
//
//
//    ADC_Init_TypeDef ADC_InitStruct;
//    ADC_StructInit(&ADC_InitStruct);
//    ADC_InitStruct.ADC_Resolution = ADC_Resolution_12bit;
//    ADC_InitStruct.ADC_Average = ADC_Average_Disable;
//    ADC_InitStruct.ADC_Mode = ADC_Mode_Active;
//    uint32_t _phase = 300;
////    uint32_t _phase = 0;
//    ADC_InitStruct.ADC_Phase = _phase;
//
//    for (int i = 0; i < array_size(adc_modules); i++){
//        RCC_ADCClkDivConfig(static_cast<RCC_ADCClk_TypeDef>(i), adc.get_module(i).clk_div_get(), ENABLE);
//        RCC_ADCClkCmd(static_cast<RCC_ADCClk_TypeDef>(i), ENABLE);
//        ADC_Init(static_cast<ADC_Module_TypeDef>(i), &ADC_InitStruct);
//        ADC_Cmd(static_cast<ADC_Module_TypeDef>(i), ENABLE);
//    }
//
//    // Sequencers 0 & 1 work from PWM
//    ADC_SEQ_Init_TypeDef ADC_SEQ_InitStruct;
//    ADC_SEQ_StructInit(&ADC_SEQ_InitStruct);
//
//    ADC_SEQ_InitStruct.ADC_SEQ_StartEvent =   ADC_SEQ_StartEvent_PWM012A;
//    ADC_SEQ_InitStruct.ADC_SEQ_SWReqEn= ENABLE;
//    ADC_SEQ_InitStruct.ADC_Channels = ( ADC_Channel_0 | ADC_Channel_2
//                                       | ADC_Channel_4 | ADC_Channel_6
//                                       | ADC_Channel_8 | ADC_Channel_10
//                                       | ADC_Channel_12| ADC_Channel_14
//                                       | ADC_Channel_16| ADC_Channel_18
//                                       | ADC_Channel_20);
//
//    ADC_SEQ_Init(ADC_SEQ_Module_0, &ADC_SEQ_InitStruct);
//    ADC_SEQ_ITConfig(ADC_SEQ_Module_0, 1, ENABLE);
//    ADC_SEQ_ITCmd(ADC_SEQ_Module_0, ENABLE);
//
////    for (int i = 0; i < 8; i++)
////      ADC_SEQ_Cmd(static_cast<ADC_SEQ_Module_TypeDef>(i), ENABLE);
//    ADC_SEQ_Cmd(ADC_SEQ_Module_0, ENABLE);
//    __NVIC_EnableIRQ(ADC_SEQ0_IRQn);
    
    
      ADC_Init_TypeDef ADC_InitStruct;

	for (uint32_t i = 0; i < 24; i++)
    {
        ADC_DC_DeInit((ADC_DC_Module_TypeDef)i);
    }
		RCC_PeriphClkCmd(RCC_PeriphClk_ADC, ENABLE);

	    // ????? ????????? ??????? ?? 6, ? ???????? ???????????? ??? 12???.
		// Fadc = Fsysclk/(2*(DIV_ADCn + 1))
        uint8_t ADCDIV = 4;

        RCC_ADCClkDivConfig(RCC_ADCClk_0,ADCDIV, ENABLE);
        RCC_ADCClkDivConfig(RCC_ADCClk_1,ADCDIV, ENABLE);
        RCC_ADCClkDivConfig(RCC_ADCClk_2,ADCDIV, ENABLE);
        RCC_ADCClkDivConfig(RCC_ADCClk_3,ADCDIV, ENABLE);
        RCC_ADCClkDivConfig(RCC_ADCClk_4,ADCDIV, ENABLE);
        RCC_ADCClkDivConfig(RCC_ADCClk_5,ADCDIV, ENABLE);
        RCC_ADCClkDivConfig(RCC_ADCClk_6,ADCDIV, ENABLE);
        RCC_ADCClkDivConfig(RCC_ADCClk_7,ADCDIV, ENABLE);
        RCC_ADCClkDivConfig(RCC_ADCClk_8,ADCDIV, ENABLE);
        RCC_ADCClkDivConfig(RCC_ADCClk_9,ADCDIV, ENABLE);
        RCC_ADCClkDivConfig(RCC_ADCClk_10,ADCDIV, ENABLE);

        RCC_ADCClkCmd(RCC_ADCClk_0,ENABLE);
        RCC_ADCClkCmd(RCC_ADCClk_1,ENABLE);
        RCC_ADCClkCmd(RCC_ADCClk_2,ENABLE);
        RCC_ADCClkCmd(RCC_ADCClk_3,ENABLE);
        RCC_ADCClkCmd(RCC_ADCClk_4,ENABLE);
        RCC_ADCClkCmd(RCC_ADCClk_5,ENABLE);
        RCC_ADCClkCmd(RCC_ADCClk_6,ENABLE);
        RCC_ADCClkCmd(RCC_ADCClk_7,ENABLE);
        RCC_ADCClkCmd(RCC_ADCClk_8,ENABLE);
        RCC_ADCClkCmd(RCC_ADCClk_9,ENABLE);
        RCC_ADCClkCmd(RCC_ADCClk_10,ENABLE);

        uint8_t dly= 300;
	    ADC_StructInit(&ADC_InitStruct);
	    ADC_InitStruct.ADC_Resolution = ADC_Resolution_12bit;
	    ADC_InitStruct.ADC_Average = ADC_Average_Disable;
	    ADC_InitStruct.ADC_Mode = ADC_Mode_Active;
	    ADC_Init(ADC_Module_0, &ADC_InitStruct);
	    ADC_InitStruct.ADC_Phase=dly;
	    ADC_Init(ADC_Module_1, &ADC_InitStruct);
	    ADC_InitStruct.ADC_Phase=dly;
	    ADC_Init(ADC_Module_2, &ADC_InitStruct);
	    ADC_InitStruct.ADC_Phase=dly;
	    ADC_Init(ADC_Module_3, &ADC_InitStruct);
	    ADC_InitStruct.ADC_Phase=dly;
	    ADC_Init(ADC_Module_4, &ADC_InitStruct);
	    ADC_InitStruct.ADC_Phase=dly;
	    ADC_Init(ADC_Module_5, &ADC_InitStruct);
	    ADC_InitStruct.ADC_Phase=dly;
	    ADC_Init(ADC_Module_6, &ADC_InitStruct);
	    ADC_InitStruct.ADC_Phase=dly;
	    ADC_Init(ADC_Module_7, &ADC_InitStruct);
	    ADC_InitStruct.ADC_Phase=dly;
	    ADC_Init(ADC_Module_8, &ADC_InitStruct);
	    ADC_InitStruct.ADC_Phase=dly;
	    ADC_Init(ADC_Module_9, &ADC_InitStruct);
	    ADC_InitStruct.ADC_Phase=dly;
	    ADC_Init(ADC_Module_10, &ADC_InitStruct);


	    // ????????? ?????? ???
	    ADC_Cmd(ADC_Module_0, ENABLE);
	    ADC_Cmd(ADC_Module_1, ENABLE);
	    ADC_Cmd(ADC_Module_2, ENABLE);
	    ADC_Cmd(ADC_Module_3, ENABLE);
	    ADC_Cmd(ADC_Module_4, ENABLE);
	    ADC_Cmd(ADC_Module_5, ENABLE);
	    ADC_Cmd(ADC_Module_6, ENABLE);
	    ADC_Cmd(ADC_Module_7, ENABLE);
	    ADC_Cmd(ADC_Module_8, ENABLE);
	    ADC_Cmd(ADC_Module_9, ENABLE);
	    ADC_Cmd(ADC_Module_10, ENABLE);


	    // ????????? 0,1 ???????? ?? ??????? ???
	    ADC_SEQ_Init_TypeDef ADC_SEQ_InitStruct;
	    ADC_SEQ_StructInit(&ADC_SEQ_InitStruct);

	    ADC_SEQ_InitStruct.ADC_SEQ_StartEvent =   ADC_SEQ_StartEvent_PWM012A;

	    ADC_SEQ_InitStruct.ADC_SEQ_SWReqEn= ENABLE;

	    ADC_SEQ_InitStruct.ADC_Channels = ( ADC_Channel_0 | ADC_Channel_2 | ADC_Channel_4 | ADC_Channel_6 | ADC_Channel_8|
	    								    ADC_Channel_10| ADC_Channel_12| ADC_Channel_14| ADC_Channel_16| ADC_Channel_18 | ADC_Channel_20);

	    ADC_SEQ_Init(ADC_SEQ_Module_0, &ADC_SEQ_InitStruct);
	    ADC_SEQ_ITConfig(ADC_SEQ_Module_0, 1, ENABLE);
	    ADC_SEQ_ITCmd(ADC_SEQ_Module_0, ENABLE);

	    ADC_SEQ_Cmd(ADC_SEQ_Module_0, ENABLE);
	    ADC_SEQ_Cmd(ADC_SEQ_Module_1, DISABLE);
	    ADC_SEQ_Cmd(ADC_SEQ_Module_2, DISABLE);
	    ADC_SEQ_Cmd(ADC_SEQ_Module_3, DISABLE);
	    ADC_SEQ_Cmd(ADC_SEQ_Module_4, DISABLE);
	    ADC_SEQ_Cmd(ADC_SEQ_Module_5, DISABLE);
	    ADC_SEQ_Cmd(ADC_SEQ_Module_6, DISABLE);
	    ADC_SEQ_Cmd(ADC_SEQ_Module_7, DISABLE);
            
            
            NVIC_SetPriority(ADC_SEQ0_IRQn,3);
            __NVIC_EnableIRQ(ADC_SEQ0_IRQn);
}

void CApp::uart_init(){
    
}


void CApp::state_machine_init(){
}


void CApp::sens_init(){
//    sens_uBUS.correct_coef_set(0.885);
//    sens_uOut.correct_coef_set(0.925);
    
    sens_iFull.correct_offset(2045);
    sens_iLoad.correct_offset(2040);
    sens_uBUS.correct_offset(2005);
    sens_uOut.correct_offset(2002);
    
    sens_uBUS.gain_set(IQ(0.4596));
    sens_uOut.gain_set(IQ(0.2298));
    sens_iLoad.gain_set(0.0787);
    sens_iFull.gain_set(0.0787);
    
    
    
    
}


extern CApp app;

void PWM0_IRQHandler(void){
    app.ledWORK.set();
    
    __NVIC_ClearPendingIRQ(PWM0_IRQn);
    PWM_ITStatusClear(NT_PWM0);
    PWM_ITPendClear(NT_PWM0);
    
    app.isr(TIME_USEC(1000/FREQ_KHZ));
    
    app.ledWORK.clear();
    
    
    
}


void ADC_SEQ0_IRQHandler(void){
    
    
//    ADC_SEQ_ITStatusClear(ADC_SEQ_Module_0);
    
    NT_ADC->ISC = 1<<((uint32_t)ADC_SEQ_Module_0);
    
    
    app.ledADC.set();
//    for (int i = 0; i < 11; i++){
//      adcBuffer[i] = (int16_t) NT_ADC->SEQ[(uint32_t) ADC_SEQ_Module_0].FIFO_bit.DATA;
//    }
//    app.ledWORK.clear();
    
    
    //app.ledWORK.set();
    
    for (int i = 0; i < array_size(adc_modules); i++){
        uint16_t _adcVal = static_cast<uint16_t>(NT_ADC->SEQ[(uint32_t) ADC_SEQ_Module_0].FIFO_bit.DATA);
        adc_modules[i].write(_adcVal);
    }
    
    
    
    app.sens_iFull.adc_val_set(adc_modules[0].read());
    app.sens_iLoad.adc_val_set(adc_modules[1].read());
//    app.sens_uBUSP_N.adc_val_set(adc_modules[2].read());
//    app.sens_uBUSN_N.adc_val_set(adc_modules[3].read());
    app.sens_uBUS.adc_val_set(adc_modules[4].read());
    app.sens_uOut.adc_val_set(adc_modules[6].read());
    
    
//    app.ledWORK.clear();
    
    
    //app.isr(TIME_USEC(1000/FREQ_KHZ));

    while (NT_ADC->SEQ[(uint32_t) ADC_SEQ_Module_0].FSTAT != 0)
      NT_ADC->SEQ[(uint32_t) ADC_SEQ_Module_0].FIFO_bit.DATA;					  // Check AI FIFO

    app.ledADC.clear();
}


inline void shutdown(){
    app.errors.set(CErrors::eError_t::ERROR_FLT);
    app.sm.state_set(&app.stFault);
//    __NVIC_ClearPendingIRQ(PWM0_TZ_IRQn);
    
    app.pwm_A.TZ_reset();
    app.pwm_B.TZ_reset();
    
    app.pwm_A.out_disable();
    app.pwm_B.out_disable();
    
    __NVIC_DisableIRQ(PWM0_TZ_IRQn);
    __NVIC_DisableIRQ(PWM1_TZ_IRQn);
    
    __NVIC_ClearPendingIRQ(PWM0_TZ_IRQn);
    __NVIC_ClearPendingIRQ(PWM1_TZ_IRQn);

    
}


void PWM0_TZ_IRQHandler(void){
    shutdown();
}

void PWM1_TZ_IRQHandler(void){
    shutdown();
}


static int fil = 0;

static uint16_t CCR = 1000;
uint16_t FR = 400;
uint16_t AMP = 180;

uint16_t iCCRA = 0;
uint16_t iCCRB = 0;


//iq_t test_var = 0;

iq_t uRef_d_ = 0;
iq_t uRef_q_ = 0;

iq_t uOut_d_ = 0;
iq_t uOut_q_ = 0;

iq_t uOut_ = 0;

uint16_t simple_sin = 0;

volatile int32_t off1=0;
volatile int32_t off2=60;

volatile float loadFb = 0.6;

volatile float koef = 50;




#pragma inline = forced
inline void acs(iq_t _Ts){
    
    if (   app.sm.state_name_get() == IState::eState::RUN 
        && app.stRun.m_isRegsInit)
    {
//#ifndef FORM_SIMPLE_U_SINUS
       if(! simple_sin ) {
       app.regUd.config_set();
       app.regUq.config_set();
       app.regId.config_set();
       app.lpf.config_set();
        
//      iq_t _wt = app.stRun.angle_est( utl::W , _Ts);
      iq_t _wt = app.stRun.angle_est( IQmpy(FR, IQ(6.281593)), _Ts);
      iq_t sinus = IQsin(_wt);
      iq_t cosin = IQcos(_wt);
      
//      iq_t virtGrd = IQmpy(IQ(165.0), cosin); 
      app.stRun.m_virtGrid = IQmpy(IQ(AMP), cosin); 
      
//      iq_t uRef_d =  IQmpy(app.stRun.m_virtGrid, cosin);
//      iq_t uRef_q = -IQmpy(app.stRun.m_virtGrid, sinus);
      iq_t uRef_d =  IQmpy(app.stRun.m_virtGrid, cosin);
      iq_t uRef_q = -IQmpy(app.stRun.m_virtGrid, sinus);
      uRef_d_ = uRef_d;      
      uRef_q_ = uRef_q;      
      
      iq_t uOut_d =  IQmpy(app.sens_uOut.read(), cosin);
      iq_t uOut_q = -IQmpy(app.sens_uOut.read(), sinus);
      uOut_d_ = uOut_d;
      uOut_q_ = uOut_q;
      
      
      iq_t _err = IQmpy(uRef_d - uOut_d, IQ(0.1));
      iq_t u_d = app.regUd.out_est(_err);

      _err = IQmpy(uRef_q - uOut_q, IQ(0.1));
      iq_t u_q = app.regUq.out_est(_err);

      // Output current controller
      iq_t out = IQmpy(u_d, cosin) - IQmpy(u_q, sinus);
      uOut_ = out;
      
      
//      _err = (out - 
//            IQmpy(app.sens_iLoad.read(), IQ(1.0)) +
//            IQmpy(app.sens_iLoad.read(), IQ(0.85)))/350 -
//            fil/50;
      
      _err  = out;
      _err -= IQmpy(app.sens_iFull.read(), IQ(1.0));
      _err += IQmpy(app.sens_iLoad.read(), IQ(loadFb));
      _err  = IQdiv(_err, 350.0);
      _err  -= IQdiv(app.lpf.out_est(app.sens_uOut.read()), koef); 
      
      
       iq_t ccr = app.regId.out_est(_err);
       
       //ccr = app.lpf.out_est(ccr);
       
       int _offset = app.pwm_A.freq_in_ticks_get()>>1;
       
       int iCCR = static_cast<int>(IQmpy(ccr,IQ(_offset)));
       
       if (iCCR > 0){
           NT_PWM0->ETSEL_bit.SOCASEL = PWM_Event_CTREqPeriod;
       }
       else{
           NT_PWM0->ETSEL_bit.SOCASEL = PWM_Event_CTREqZero;
       }

       iCCRA = uint16_t(iCCR < 0 ? 0 : iCCR + off1);
       iCCRB = uint16_t(iCCR < 0 ? iCCR + _offset + off2 : _offset);
       
       app.pwm_A.cmp_set(iCCRA);
       app.pwm_B.cmp_set(iCCRB);
       
       app.pwm_A.out_enable();
       app.pwm_B.out_enable();
       }
//#else
       else{
       iq_t _wt = app.stRun.angle_est( FR*6.281593 , _Ts);
       
       
       iq_t sinus = IQsin(_wt);
       iq_t cosin = IQcos(_wt);
       app.stRun.m_virtGrid = IQmpy(IQ(60.0), sinus); 
       
       
       int iCCR = static_cast<int>(IQmpy(IQ(CCR), sinus));
       app.stRun.m_ccr = iCCR;
       
//       app.pwm_A.cmp_set( iCCR < 0 ? 0 : iCCR);
//       app.pwm_B.cmp_set(-iCCR < 0 ? 0 : iCCR);

       int _offset = app.pwm_A.freq_in_ticks_get()>>1;
       
       if (iCCR > 0){
           NT_PWM0->ETSEL_bit.SOCASEL = PWM_Event_CTREqPeriod;
       }
       else{
           NT_PWM0->ETSEL_bit.SOCASEL = PWM_Event_CTREqZero;
       }

       iCCRA = uint16_t(iCCR < 0 ? 0 : iCCR);
       iCCRB = uint16_t(iCCR < 0 ? iCCR + _offset : _offset);
       
       app.pwm_A.cmp_set( iCCRA);
       app.pwm_B.cmp_set( iCCRB);
       
       app.pwm_A.out_enable();
       app.pwm_B.out_enable();
       
       
       
       }
       
//#endif       
       
    } else if (app.sm.state_name_get() == IState::eState::DIAG){
        
    } else{
        app.pwm_A.out_disable();
        app.pwm_B.out_disable();
    }
    
    
}

