#include "ringbuffer.hpp"
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

LogLevel SwtrRingBuffer::get_write_verbosity() const {
    return write_verbosity_.load();
}

} // namespace swtr
