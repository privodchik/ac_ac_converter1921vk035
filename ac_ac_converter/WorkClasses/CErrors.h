// Date: 2020.12.10
// User: ID

#ifndef _CErrors_H
#define _CErrors_H

#include <stdint.h>
#include "aux_utility.h"

using namespace std;

class CErrors
{
  public:
    enum eError_t{
        NOERR                         = 0, 

        ERROR_BUS                     =  100,
        ERROR_BUS_U                   =  101,
        ERROR_BUS_MAX                 =  102,
        ERROR_BUS_MIN                 =  103,
        
        ERROR_CONVERTER               =  200,
        ERROR_CONVERTER_VMAX          =  201,
        ERROR_CONVERTER_VMIN          =  202,
        ERROR_CONVERTER_VUNBAL        =  203,
        
        ERROR_CONVERTER_IMAX          = 211,
        ERROR_CONVERTER_IMIN          = 212,
        ERROR_CONVERTER_IOVERLOAD     = 213,

        ERROR_FLT                     = 300
    };

  private:
    const int ERRORS_MAX;
  
  private:
    eError_t* 	m_pErrorsArray;
    uint16_t	m_errors_cnt;
    eError_t 	m_current_error;
    
    
  public:
    CErrors(eError_t* _pErrArray, size_t _bufSize);
    
    void clr();
    void set(eError_t _err);
    
    const uint16_t& cnt() const {return m_errors_cnt;}
    const eError_t& current() const{return m_current_error;}
		
    bool is_error(eError_t _error);
    bool is_errors_in_range(eError_t _firstErr, eError_t _lastErr);
};


#endif


