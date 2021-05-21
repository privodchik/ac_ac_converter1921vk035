// Date: 24.02.2021
// Created: ID

#include "CApp.h"
#include "mcu.h"
#include "plib035_rcu.h"
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
        counting++;

        modbus_rtu_task(); // on uart2
        gpio_task();
        
        sm.operate();
        
        rms_est(TIME_USEC(100));
    }
    
}



char CApp::task_rms(time_t _periodUSEC, PT* pt){
    
    static TIMER tmr;
    static TIMER tmr2;
    
    PT_BEGIN(pt);
    {
      iq_t _t = IQmpy(IQ(_periodUSEC), IQ(0.0000001));
      iInvRms.Ts_set(_t);
      iInvRmsLpf.Ts_set(_t);
      iInvRmsLpf.config_set();
      
    }
    timer_set(&tmr, _periodUSEC);
    timer_set(&tmr2, TIME_SEC(1.0/FR));
    
    
    while(1){
        
      PT_YIELD_UNTIL(pt, timer_expired(&tmr));
      iInvRms.out_est(sens_iFull.read());
      if (timer_expired(&tmr2)){
          iInvRms.rms_set();
          iInvRms.out_reset();
          timer_advance(&tmr2, TIME_SEC(1.0/FR));
      }
      
      iInvRmsLpf.out_est(iInvRms.rms());
      timer_advance(&tmr, _periodUSEC);
      
    }
    
    PT_END(pt);
}

static PT pt_rms;
void CApp::rms_est(time_t _periodUS){
    task_rms(_periodUS, &pt_rms);
}


#pragma inline = forced
void CApp::isr(time_t _period){
    
    clock_tick(_period);
    modbus_scope_tick(_period);
    uart_hw_task(); // here or in background loop
    acs(_period);
    
}


void CApp::leds_init(){
    CPin _pin{CPin::ePort::PORT_A, CPin::ePin::Pin_12}; 
    
    _pin.mode_set(CPin::eMode::IO);
    _pin.direction_set(CPin::eDir::OUT);
    _pin.out_mode(CPin::eOutMode::PUSH_PULL);
    _pin.in_mode(CPin::eInMode::DISABLE);
    _pin.pull_mode(CPin::ePullMode::PD);
    _pin.drive_mode(CPin::eDriveMode::HIGH_FAST);
    _pin.config_set();

    ledWORK.define_pin(_pin);
    ledWORK.clear();
}

void CApp::fun_init(){
    fun.mode_set(CPin::eMode::IO);
    fun.direction_set(CPin::eDir::OUT);
    fun.out_mode(CPin::eOutMode::PUSH_PULL);
    fun.in_mode(CPin::eInMode::DISABLE);
    fun.pull_mode(CPin::ePullMode::PD);
    fun.drive_mode(CPin::eDriveMode::HIGH_FAST);
    fun.config_set();
    
    fun.write(FUN_OFF);
}

void CApp::pwm_init(){
    
    pwm_A.freq_set(FREQ_KHZ);
    pwm_B.freq_set(FREQ_KHZ);
    
    const uint32_t PWM_MAX = pwm_A.freq_in_ticks_get(); // or pwm_B.freq_in_ticks_get()
    
    RCU_APBClkCmd(RCU_APBClk_PWM0, ENABLE);
    RCU_APBRstCmd(RCU_APBRst_PWM0, ENABLE);
    RCU_APBClkCmd(RCU_APBClk_PWM1, ENABLE);
    RCU_APBRstCmd(RCU_APBRst_PWM1, ENABLE);
    
//  ----------------------------------------------------------------------------    
    PWM_TB_Init_TypeDef PWM_TB_InitStruct;
    //Channel_0 is Master
    PWM_TB_InitStruct.Halt = PWM_TB_Halt_Free;
    PWM_TB_InitStruct.ClkDiv = PWM_TB_ClkDiv_1;
    PWM_TB_InitStruct.ClkDivExtra = PWM_TB_ClkDivExtra_1;    
    PWM_TB_InitStruct.SyncOut = PWM_TB_SyncOut_CTREqZero;
    PWM_TB_InitStruct.PhaseSync = ENABLE;
    PWM_TB_InitStruct.PhaseSyncDir = PWM_TB_Dir_Up;
    PWM_TB_InitStruct.Phase = 0;
    PWM_TB_InitStruct.Mode = PWM_TB_Mode_UpDown;
    PWM_TB_InitStruct.PeriodDirectLoad = DISABLE;
    PWM_TB_InitStruct.Period = PWM_MAX/2 - 1;
    
    PWM_TB_Init(PWM0, &PWM_TB_InitStruct);
    
    //Channel_1 is Slave
    PWM_TB_InitStruct.SyncOut = PWM_TB_SyncOut_SyncIn;
    PWM_TB_InitStruct.Phase = 1;
    PWM_TB_Init(PWM1, &PWM_TB_InitStruct);
    
//  ----------------------------------------------------------------------------
    //Comparators Initialization
    PWM_CMP_Init_TypeDef PWM_CMP_InitStruct;
    PWM_CMP_StructInit(&PWM_CMP_InitStruct);

    PWM_CMP_InitStruct.CmpADirectLoad = DISABLE;
    PWM_CMP_InitStruct.CmpBDirectLoad = DISABLE;
    PWM_CMP_InitStruct.LoadEventCmpA = PWM_CMP_LoadEvent_CTREqZero;
    PWM_CMP_InitStruct.LoadEventCmpB = PWM_CMP_LoadEvent_CTREqZero;
    PWM_CMP_InitStruct.CmpA = PWM_MAX/4;
    PWM_CMP_InitStruct.CmpB = PWM_MAX/4;
    
    PWM_CMP_Init(PWM0, &PWM_CMP_InitStruct);
    PWM_CMP_Init(PWM1, &PWM_CMP_InitStruct);
    
//  ----------------------------------------------------------------------------    
    PWM_AQ_Init_TypeDef PWM_AQ_InitStruct;
    PWM_AQ_StructInit(&PWM_AQ_InitStruct);
    PWM_AQ_InitStruct.ActionA_CTREqCMPAUp = PWM_AQ_Action_ToOne;
    PWM_AQ_InitStruct.ActionA_CTREqCMPADown = PWM_AQ_Action_ToZero;
    PWM_AQ_InitStruct.ActionB_CTREqCMPAUp = PWM_AQ_Action_ToOne;
    PWM_AQ_InitStruct.ActionB_CTREqCMPADown = PWM_AQ_Action_ToZero;
    
    PWM_AQ_Init(PWM0, &PWM_AQ_InitStruct);
    PWM_AQ_Init(PWM1, &PWM_AQ_InitStruct);

//  ----------------------------------------------------------------------------    
    pwm_A.out_disable();  // FIXME
    pwm_B.out_disable();  // FIXME
    
//  ----------------------------------------------------------------------------        
    // DTG Initialization
    PWM_DB_Init_TypeDef PWM_DTG_InitStruct;
    PWM_DB_StructInit(&PWM_DTG_InitStruct);
    PWM_DTG_InitStruct.In = PWM_DB_In_AFallBRise;
    PWM_DTG_InitStruct.Polarity = PWM_DB_Polarity_ActiveHighCompl;
    PWM_DTG_InitStruct.Out = PWM_DB_Out_BypassAB;
    PWM_DTG_InitStruct.RiseDelay = 120;
    PWM_DTG_InitStruct.FallDelay = 120;
    PWM_DB_Init(PWM0, &PWM_DTG_InitStruct);
    PWM_DB_Init(PWM1, &PWM_DTG_InitStruct);
    
//  ----------------------------------------------------------------------------            
    pwm_A.out_disable();
    pwm_B.out_disable();
    
//  ----------------------------------------------------------------------------                
     //ADC starts from PWM0 event
    PWM_ET_Init_TypeDef PWM_ET_InitStruct;
    PWM_ET_StructInit(&PWM_ET_InitStruct);
    PWM_ET_InitStruct.EventSOCA = PWM_ET_Event_CTREqZero;
    PWM_ET_InitStruct.SOCA = ENABLE;
    PWM_ET_Init(PWM0, &PWM_ET_InitStruct);
    
//  ----------------------------------------------------------------------------
    pwm_A.out_disable();
    pwm_B.out_disable();
    
//  ----------------------------------------------------------------------------    
    PWM_TB_PrescCmd(PWM_TB_Presc_0 | PWM_TB_Presc_1, ENABLE);

//  ----------------------------------------------------------------------------    
    pwm_A.out_disable();
    pwm_B.out_disable();
    
//  ----------------------------------------------------------------------------        
    // PWM Pins Configuration
    CPin _pin{CPin::ePort::PORT_A, CPin::ePin::Pin_8}; // PWM_A0
    _pin.mode_set(CPin::eMode::ALT_FUNC);
    _pin.direction_set(CPin::eDir::OUT);
    _pin.drive_mode(CPin::eDriveMode::HIGH_FAST);
    _pin.config_set();
    
    _pin.pin_set(CPin::ePin::Pin_9);    // PWM_B0
    _pin.config_set();
    
    _pin.pin_set(CPin::ePin::Pin_10);   // PWM_A1
    _pin.config_set();
    
    _pin.pin_set(CPin::ePin::Pin_11);   // PWM_B1
    _pin.config_set();
    
    
    // TZ init
    _pin.pin_set(CPin::ePin::Pin_7); // PWM_A TZ0
    _pin.direction_set(CPin::eDir::IN);
    _pin.config_set();
    
    pwm_A.TZ_enable(true);
    pwm_B.TZ_enable(true);
    
    __NVIC_EnableIRQ(PWM0_TZ_IRQn);
    __NVIC_EnableIRQ(PWM1_TZ_IRQn);
    
    
    
    
}

void CApp::adc_init(){
    
// -----------------------------------------------------------------------------
    ADC_SEQ_Init_TypeDef ADC_SEQ_InitStruct;
    
    RCU_ADCClkConfig(RCU_PeriphClk_PLLClk, 7, ENABLE); //12.5MHz
    RCU_ADCClkCmd(ENABLE);
    RCU_ADCRstCmd(ENABLE);
    
    
    //Modul ADC is switched on
    ADC_AM_Cmd(ENABLE);

    ADC_SEQ_StructInit(&ADC_SEQ_InitStruct);
    ADC_SEQ_InitStruct.StartEvent = ADC_SEQ_StartEvent_PWM012A;
    ADC_SEQ_InitStruct.SWStartEn = DISABLE;
    ADC_SEQ_InitStruct.Req[ADC_SEQ_ReqNum_0] = ADC_CH_Num_0;
    ADC_SEQ_InitStruct.Req[ADC_SEQ_ReqNum_1] = ADC_CH_Num_1;
    ADC_SEQ_InitStruct.Req[ADC_SEQ_ReqNum_2] = ADC_CH_Num_2;
    ADC_SEQ_InitStruct.Req[ADC_SEQ_ReqNum_3] = ADC_CH_Num_3;
    ADC_SEQ_InitStruct.ReqMax = ADC_SEQ_ReqNum_3;
    ADC_SEQ_InitStruct.RestartCount = 0;
    ADC_SEQ_Init(ADC_SEQ_Num_0, &ADC_SEQ_InitStruct);
    ADC_SEQ_Cmd(ADC_SEQ_Num_0, ENABLE);
    while (!ADC_AM_ReadyStatus()) {
    }

    ADC_SEQ_ITConfig(ADC_SEQ_Num_0, 0, DISABLE);
    ADC_SEQ_ITCmd(ADC_SEQ_Num_0, ENABLE);
    NVIC_EnableIRQ(ADC_SEQ0_IRQn);
// -----------------------------------------------------------------------------    
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
    PWM_ITStatusClear(PWM0);
    PWM_ITPendStatusClear(PWM0);
    
    app.isr(TIME_USEC(1000/FREQ_KHZ));
    
    app.ledWORK.clear();
    
}




void ADC_SEQ0_IRQHandler(void){
    
    ADC_SEQ_ITStatusClear(ADC_SEQ_Num_0);
    
    uint16_t _iFull     = ADC_SEQ_GetFIFOData(ADC_SEQ_Num_0);
    uint16_t _iLoad     = ADC_SEQ_GetFIFOData(ADC_SEQ_Num_0);
    uint16_t _uBus      = ADC_SEQ_GetFIFOData(ADC_SEQ_Num_0);
    uint16_t _uUout     = ADC_SEQ_GetFIFOData(ADC_SEQ_Num_0);
    
    app.sens_iFull.adc_val_set(_iFull);
    app.sens_iLoad.adc_val_set(_iLoad);
    app.sens_uBUS.adc_val_set(_uBus);
    app.sens_uOut.adc_val_set(_uUout);
    
    while (ADC_SEQ_GetFIFOLoad(ADC_SEQ_Num_0))
        ADC_SEQ_GetFIFOData(ADC_SEQ_Num_0);

}


inline void shutdown(){
    app.errors.set(CErrors::eError_t::ERROR_FLT);
    app.sm.state_set(&app.stFault);
//    __NVIC_ClearPendingIRQ(PWM0_TZ_IRQn);
    
    app.pwm_A.TZ_IT_reset();
    app.pwm_B.TZ_IT_reset();
    
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
      
      
      iq_t _err = uRef_d - uOut_d;
      iq_t u_d = app.regUd.out_est(_err);

      _err = uRef_q - uOut_q;
      iq_t u_q = app.regUq.out_est(_err);

      // Output current controller
      iq_t out = IQmpy(u_d, cosin) - IQmpy(u_q, sinus);
      uOut_ = out;
      
      
      _err  = out;
      _err -= IQmpy(app.sens_iFull.read(), IQ(1.0));
      _err += IQmpy(app.sens_iLoad.read(), IQ(loadFb));
      _err  -= IQdiv(app.lpf.out_est(app.sens_uOut.read()), koef); 
      
      
       iq_t ccr = app.regId.out_est(_err);
       
       //ccr = app.lpf.out_est(ccr);
       
       int _offset = app.pwm_A.freq_in_ticks_get()>>1;
       
       int iCCR = static_cast<int>(IQmpy(ccr,IQ(_offset)));
       
       if (iCCR > 0){
           PWM0->ETSEL_bit.SOCASEL = PWM_AQ_Event_CTREqPeriod;
       }
       else{
           PWM0->ETSEL_bit.SOCASEL = PWM_AQ_Event_CTREqZero;
       }

       iCCRA = uint16_t(iCCR < 0 ? 0 : iCCR + off1);
       iCCRB = uint16_t(iCCR < 0 ? iCCR + _offset + off2 : _offset);
       
       app.pwm_A.cmp_set(iCCRA);
       app.pwm_B.cmp_set(iCCRB);
       
       app.pwm_A.out_enable();
       app.pwm_B.out_enable();
       }
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
           PWM0->ETSEL_bit.SOCASEL = PWM_AQ_Event_CTREqPeriod;
       }
       else{
           PWM0->ETSEL_bit.SOCASEL = PWM_AQ_Event_CTREqZero;
       }

       iCCRA = uint16_t(iCCR < 0 ? 0 : iCCR);
       iCCRB = uint16_t(iCCR < 0 ? iCCR + _offset : _offset);
       
       app.pwm_A.cmp_set( iCCRA);
       app.pwm_B.cmp_set( iCCRB);
       
       app.pwm_A.out_enable();
       app.pwm_B.out_enable();
       
       
       
       }
       
       
    } else if (app.sm.state_name_get() == IState::eState::DIAG){
        
    } else{
        app.pwm_A.out_disable();
        app.pwm_B.out_disable();
    }
    
    
}

