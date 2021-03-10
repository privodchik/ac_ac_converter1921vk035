// Date: 2020.12.10
// User: ID


#include "CErrors.h"


CErrors::CErrors(eError_t* _pErrArray, size_t _bufSize): 
  m_pErrorsArray(_pErrArray),
  ERRORS_MAX(_bufSize){
  clr();
}

void CErrors::clr(){
  for (int i = 0; i < ERRORS_MAX; i++)	m_pErrorsArray[i] = NOERR;
	m_errors_cnt = 0;
  m_current_error = NOERR;
}

void CErrors::set(eError_t _err){
	
	if (_err == m_current_error) return;
	
	if (m_errors_cnt < ERRORS_MAX){
		m_pErrorsArray[m_errors_cnt++] = _err;
		m_current_error = _err;
	}
}


bool CErrors::is_error(eError_t _error){
	for (int i = 0; i < ERRORS_MAX; i++)
          if (m_pErrorsArray[i] == _error) return true;
	return false;
}

bool CErrors::is_errors_in_range(eError_t _firstErr, eError_t _lastErr){
	for (int i = 0; i < ERRORS_MAX; i++){
          for (int err = _firstErr; err <= _lastErr; err++){
              if (m_pErrorsArray[i] == err) return true;
          }
	}
    return false;
}


