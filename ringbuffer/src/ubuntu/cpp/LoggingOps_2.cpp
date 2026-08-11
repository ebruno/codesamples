#include "ringbuffer.hpp"
#include <iostream>
#include "status.hpp"
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

void SwtrRingBuffer::set_output_stream(std::ostream& stream) {
    output_stream_ = &stream;
}

std::ostream* SwtrRingBuffer::get_output_stream() const {
    return output_stream_;
}

void SwtrRingBuffer::set_read_logging_enabled(bool enabled) {
    read_logging_enabled_.store(enabled);
}

} // namespace swtr
