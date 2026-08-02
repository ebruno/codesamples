#include "ringbuffer.hpp"
#include "status.hpp"
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

std::ostream* SwtrRingBuffer::get_output_stream() const {
    std::lock_guard<std::mutex> lock(log_mutex_);
    return output_stream_;
}

void SwtrRingBuffer::set_read_logging_enabled(bool enabled) {
    read_logging_enabled_.store(enabled);
}

bool SwtrRingBuffer::get_read_logging_enabled() const {
    return read_logging_enabled_.load();
}

} // namespace swtr
