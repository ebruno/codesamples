#include "ringbuffer.hpp"
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

void SwtrRingBuffer::set_transform_logging_enabled(bool enabled) {
    transform_logging_enabled_.store(enabled);
}

bool SwtrRingBuffer::get_transform_logging_enabled() const {
    return transform_logging_enabled_.load();
}

void SwtrRingBuffer::set_transform_verbosity(LogLevel level) {
    transform_verbosity_.store(level);
}

} // namespace swtr
