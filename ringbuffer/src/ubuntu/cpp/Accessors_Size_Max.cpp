#include "ringbuffer.hpp"
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

size_t SwtrRingBuffer::get_max_size(size_t slot_idx) const {
    if (slot_idx >= num_slots_) { handle_error(slot_idx, BufferStatus::STATUS_ERROR); return 0; }
    return slots_[slot_idx]->max_data_buffer_size;
}

void SwtrRingBuffer::set_max_size(size_t slot_idx, size_t size) {
    if (slot_idx >= num_slots_) { handle_error(slot_idx, BufferStatus::STATUS_ERROR); return; }
    slots_[slot_idx]->max_data_buffer_size = size;
}

} // namespace swtr
