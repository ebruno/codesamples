#include "ringbuffer.hpp"
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

void SwtrRingBuffer::set_write_logging_enabled(bool enabled) {
    write_logging_enabled_.store(enabled);
}

bool SwtrRingBuffer::get_write_logging_enabled() const {
    return write_logging_enabled_.load();
}

void SwtrRingBuffer::set_write_verbosity(LogLevel level) {
    write_verbosity_.store(level);
}

} // namespace swtr
