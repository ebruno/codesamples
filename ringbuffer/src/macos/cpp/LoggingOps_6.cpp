#include "ringbuffer.hpp"
#include "status.hpp"
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

void SwtrRingBuffer::set_write_verbosity(LogLevel level) {
    write_verbosity_.store(level);
}

LogLevel SwtrRingBuffer::get_write_verbosity() const {
    return write_verbosity_.load();
}

} // namespace swtr
