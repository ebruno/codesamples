#include "ringbuffer.hpp"
#include "status.hpp"
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

BufferStatus SwtrRingBuffer::get_status(size_t slot_idx) const {
    return slots_[slot_idx % slots_.size()]->status.load();
}

void SwtrRingBuffer::set_status(size_t slot_idx, BufferStatus status) {
    slots_[slot_idx % slots_.size()]->status.store(status);
}

bool SwtrRingBuffer::test_status(size_t slot_idx, BufferStatus status) const {
    return get_status(slot_idx) == status;
}

} // namespace swtr
