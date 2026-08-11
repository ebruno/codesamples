#include "ringbuffer.hpp"
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

BufferStatus SwtrRingBuffer::get_status(size_t slot_idx) const {
    if (slot_idx >= num_slots_) return BufferStatus::STATUS_ERROR;
    return slots_[slot_idx]->status.load();
}

void SwtrRingBuffer::set_status(size_t slot_idx, BufferStatus status) {
    if (slot_idx >= num_slots_) return;
    slots_[slot_idx]->status.store(status);
}

bool SwtrRingBuffer::test_status(size_t slot_idx, BufferStatus status) const {
    if (slot_idx >= num_slots_) return false;
    return slots_[slot_idx]->status.load() == status;
}

} // namespace swtr
