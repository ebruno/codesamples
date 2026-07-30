/**
 * @file Logging_Stage_Setters.cpp
 * @brief Implementation of stage logging setters for swtr::RingBuffer.
 */

#include "ringbuffer.hpp"

namespace swtr {

void RingBuffer::set_stage_logging_enabled(const std::string& stage, bool enabled) {
    std::lock_guard lock(m_mutex);
    m_stage_configs[stage].enabled = enabled;
}

void RingBuffer::set_stage_verbosity(const std::string& stage, LogLevel level) {
    std::lock_guard lock(m_mutex);
    m_stage_configs[stage].verbosity = level;
}

} // namespace swtr
