#include "ringbuffer.hpp"
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

void SwtrRingBuffer::handle_error(size_t slot_idx, BufferStatus status) {
    slots_[slot_idx]->status.store(status);
    if (error_handler_) {
        if (error_handler_(slot_idx, status) != 0) {
            stop();
        }
    }
}

} // namespace swtr
