#include "ringbuffer.hpp"
#include "status.hpp"
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

bool SwtrRingBuffer::get_read_logging_enabled() const {
    return read_logging_enabled_.load();
}

void SwtrRingBuffer::set_read_verbosity(LogLevel level) {
    read_verbosity_.store(level);
}

LogLevel SwtrRingBuffer::get_read_verbosity() const {
    return read_verbosity_.load();
}

} // namespace swtr
