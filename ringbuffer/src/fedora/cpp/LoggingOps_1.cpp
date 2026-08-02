#include "ringbuffer.hpp"
#include "status.hpp"
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

void SwtrRingBuffer::set_logging_enabled(bool enabled) {
    logging_enabled_.store(enabled);
}

bool SwtrRingBuffer::get_logging_enabled() const {
    return logging_enabled_.load();
}

void SwtrRingBuffer::set_output_stream(std::ostream& stream) {
    std::lock_guard<std::mutex> lock(log_mutex_);
    output_stream_ = &stream;
}

} // namespace swtr
