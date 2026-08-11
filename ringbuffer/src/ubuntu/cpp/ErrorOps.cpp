#include "ringbuffer.hpp"
#include "status.hpp"
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

void SwtrRingBuffer::handle_error(size_t slot_idx, BufferStatus status) {
    if (err_handler_) {
        if (err_handler_(slot_idx, status) != 0) {
            stop();
        }
    }
}

} // namespace swtr
