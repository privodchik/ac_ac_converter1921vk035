// Date: 2020.11.26
// User: ID

#include "state_machine.h"

void CStateMachine::state_set(IState::eState _state){
    m_ptr_current_state->state_set(_state);
    m_ptr_current_state = IState::state_current_ptr_get();
}

