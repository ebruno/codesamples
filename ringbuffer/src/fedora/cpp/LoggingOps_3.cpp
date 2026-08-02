#include "ringbuffer.hpp"
#include "status.hpp"
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

void SwtrRingBuffer::set_read_verbosity(LogLevel level) {
    read_verbosity_.store(level);
}

LogLevel SwtrRingBuffer::get_read_verbosity() const {
    return read_verbosity_.load();
}

void SwtrRingBuffer::set_transform_logging_enabled(bool enabled) {
    transform_logging_enabled_.store(enabled);
}

} // namespace swtr
