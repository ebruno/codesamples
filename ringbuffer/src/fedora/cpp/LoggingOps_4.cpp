#include "ringbuffer.hpp"
#include "status.hpp"
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

bool SwtrRingBuffer::get_transform_logging_enabled() const {
    return transform_logging_enabled_.load();
}

void SwtrRingBuffer::set_transform_verbosity(LogLevel level) {
    transform_verbosity_.store(level);
}

LogLevel SwtrRingBuffer::get_transform_verbosity() const {
    return transform_verbosity_.load();
}

} // namespace swtr
