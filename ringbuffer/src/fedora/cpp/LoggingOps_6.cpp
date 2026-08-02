#include "ringbuffer.hpp"
#include <iostream>
#include <string>
#include "status.hpp"
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

LogLevel SwtrRingBuffer::get_write_verbosity() const {
    return write_verbosity_.load();
}

void SwtrRingBuffer::do_log(LogLevel level, const std::string& message) {
    if (!logging_enabled_.load()) return;

    std::lock_guard<std::mutex> lock(log_mutex_);
    if (!output_stream_) return;

    std::string level_str;
    switch (level) {
        case LogLevel::Trace:    level_str = "[TRACE]"; break;
        case LogLevel::Debug:    level_str = "[DEBUG]"; break;
        case LogLevel::Info:     level_str = "[INFO]"; break;
        case LogLevel::Warning:  level_str = "[WARNING]"; break;
        case LogLevel::Error:    level_str = "[ERROR]"; break;
        case LogLevel::Critical: level_str = "[CRITICAL]"; break;
    }

    *output_stream_ << level_str << " " << message << std::endl;
}

} // namespace swtr
