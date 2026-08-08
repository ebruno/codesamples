#include "ringbuffer.hpp"
#include "status.hpp"
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

LogLevel SwtrRingBuffer::get_transform_verbosity() const {
    return transform_verbosity_.load();
}

void SwtrRingBuffer::set_write_logging_enabled(bool enabled) {
    write_logging_enabled_.store(enabled);
}

bool SwtrRingBuffer::get_write_logging_enabled() const {
    return write_logging_enabled_.load();
}

} // namespace swtr
