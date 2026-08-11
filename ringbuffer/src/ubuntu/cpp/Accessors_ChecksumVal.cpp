#include "ringbuffer.hpp"
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

uint32_t SwtrRingBuffer::get_checksum_val(size_t slot_idx) const {
    if (slot_idx >= num_slots_) { handle_error(slot_idx, BufferStatus::STATUS_ERROR); return 0; }
    return slots_[slot_idx]->checksum_val.load();
}

void SwtrRingBuffer::set_checksum_val(size_t slot_idx, uint32_t val) {
    if (slot_idx >= num_slots_) { handle_error(slot_idx, BufferStatus::STATUS_ERROR); return; }
    slots_[slot_idx]->checksum_val.store(val);
}

bool SwtrRingBuffer::test_checksum_val(size_t slot_idx, uint32_t val) const {
    if (slot_idx >= num_slots_) { handle_error(slot_idx, BufferStatus::STATUS_ERROR); return false; }
    return slots_[slot_idx]->checksum_val.load() == val;
}

} // namespace swtr
