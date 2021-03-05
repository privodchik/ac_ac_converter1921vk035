// Date: 28.02.2021
// Creator: ID

#ifndef _CADC_H
#define _CADC_H

#include "IPheriphery.h"
#include "niietcm4_adc.h"
#include <utility>
#include "aux_utility.h"
#include "niietcm4.h"



class CADCModule
{
  private:
    int m_id;
    uint32_t m_clkDiv;
    uint16_t m_result;

  public:
    CADCModule(){}
    CADCModule(int _id, uint32_t _clkDiv) :
      m_id(_id),
      m_clkDiv(_clkDiv),
      m_result(0)
    {}

    void clk_div_set(uint32_t _clkDiv){m_clkDiv = _clkDiv;}
    uint32_t clk_div_get() const {return m_clkDiv;}

    int id_get(){return m_id;}
    
    uint16_t read() const {return m_result;}
    void write(uint16_t _res) {m_result = _res;}
};

extern CADCModule adc_modules[11];



class CADC : public IPheriphery
{

    CADCModule* m_padcModules;
    std::size_t m_modulesQuant;

  public:
    static const int MODULES_QUANTITY = eQ24;

  public:
    CADC(CADCModule* const _adcModules, std::size_t _n) :
      m_padcModules(_adcModules),
      m_modulesQuant(_n){}


    CADCModule& get_module(int _no){
      assert_param( _no <= m_modulesQuant);
      assert_param( _no > -1);

      return m_padcModules[_no];
    }
    
    
};

extern uint16_t adcBuffer[];


#endif //_CADC_H
