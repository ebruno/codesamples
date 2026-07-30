/**
 * @file Logging_Global_Getters.cpp
 * @brief Implementation of global logging getters for swtr::RingBuffer.
 */

#include "ringbuffer.hpp"

namespace swtr {

bool RingBuffer::is_logging_enabled() const {
    return m_logging_enabled.load();
}

LogLevel RingBuffer::get_global_verbosity() const {
    return m_global_verbosity.load();
}

std::ostream& RingBuffer::get_output_stream() const {
    if (m_log_stream) return *m_log_stream;
    return std::cerr;
}

} // namespace swtr
