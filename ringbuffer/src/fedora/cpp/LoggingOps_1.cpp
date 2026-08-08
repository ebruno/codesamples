#include "ringbuffer.hpp"
#include <iostream>
#include <mutex>
#include <string>
#include "status.hpp"
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

void SwtrRingBuffer::do_log(LogLevel level, const std::string& message) {
    static std::mutex log_mutex;
    std::lock_guard<std::mutex> lock(log_mutex);
    
    std::string level_str;
    switch (level) {
        case LogLevel::Trace:    level_str = "[TRACE]"; break;
        case LogLevel::Debug:    level_str = "[DEBUG]"; break;
        case LogLevel::Info:     level_str = "[INFO]"; break;
        case LogLevel::Warning:  level_str = "[WARN]"; break;
        case LogLevel::Error:    level_str = "[ERROR]"; break;
        case LogLevel::Critical: level_str = "[CRIT]"; break;
    }

    if (output_stream_) {
        *output_stream_ << level_str << " " << message << std::endl;
    }
}

void SwtrRingBuffer::set_logging_enabled(bool enabled) {
    logging_enabled_.store(enabled);
}

bool SwtrRingBuffer::get_logging_enabled() const {
    return logging_enabled_.load();
}

} // namespace swtr
