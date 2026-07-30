/**
 * @file Logging_Stage_Getters.cpp
 * @brief Implementation of stage logging getters for swtr::RingBuffer.
 */

#include "ringbuffer.hpp"

namespace swtr {

bool RingBuffer::is_stage_logging_enabled(const std::string& stage) const {
    std::lock_guard lock(m_mutex);
    auto it = m_stage_configs.find(stage);
    if (it != m_stage_configs.end()) {
        return it->second.enabled;
    }
    return m_logging_enabled.load();
}

LogLevel RingBuffer::get_stage_verbosity(const std::string& stage) const {
    std::lock_guard lock(m_mutex);
    auto it = m_stage_configs.find(stage);
    if (it != m_stage_configs.end()) {
        return it->second.verbosity;
    }
    return m_global_verbosity.load();
}

} // namespace swtr
