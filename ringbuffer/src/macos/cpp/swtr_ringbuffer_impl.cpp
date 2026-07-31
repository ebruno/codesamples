/**
 * @file swtr_ringbuffer_impl.cpp
 * @brief Implementation of the concrete RingBufferImpl class.
 */

#include "swtr_ringbuffer_impl.hpp"
#include <iostream>
#include <iomanip>
#include <chrono>

namespace swtr {

RingBufferImpl::RingBufferImpl(size_t num_slots, BufferStatus initial_status, size_t buffer_size) 
    : RingBuffer(num_slots, initial_status, buffer_size) {}

void RingBufferImpl::do_log(LogLevel level, const std::string& message) {
    if (!m_log_stream) return;

    auto now = std::chrono::system_clock::now();
    auto in_time_t = std::chrono::system_clock::to_time_t(now);
    
    *m_log_stream << std::put_time(std::localtime(&in_time_t), "%Y-%m-%d %X") 
                 << " [" << log_level_to_string(level) << "] " << message << std::endl;
}

} // namespace swtr
