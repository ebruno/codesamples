/**
 * @file Logging_Global_Setters.cpp
 * @brief Implementation of global logging setters for swtr::RingBuffer.
 */

#include "ringbuffer.hpp"

namespace swtr {

void RingBuffer::set_logging_enabled(bool enabled) {
    m_logging_enabled.store(enabled);
}

void RingBuffer::set_global_verbosity(LogLevel level) {
    m_global_verbosity.store(level);
}

void RingBuffer::set_output_stream(std::ostream& os) {
    m_log_stream = &os;
}

} // namespace swtr
