#include "ringbuffer.hpp"
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

BufferStatus SwtrRingBuffer::get_status(size_t slot_idx) const {
    return slots_[slot_idx % num_slots_]->status.load();
}

void SwtrRingBuffer::set_status(size_t slot_idx, BufferStatus status) {
    slots_[slot_idx % num_slots_]->status.store(status);
}

bool SwtrRingBuffer::test_status(size_t slot_idx, BufferStatus status) const {
    return slots_[slot_idx % num_slots_]->status.load() == status;
}

} // namespace swtr
