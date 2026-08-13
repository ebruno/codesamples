#include "ringbuffer.hpp"
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

size_t SwtrRingBuffer::get_transformed_size(size_t slot_idx) const {
    if (slot_idx >= num_slots_) return 0;
    return slots_[slot_idx]->transformed_data_buffer_size.load();
}

void SwtrRingBuffer::set_transformed_size(size_t slot_idx, size_t size) {
    if (slot_idx >= num_slots_) return;
    slots_[slot_idx]->transformed_data_buffer_size.store(size);
}

} // namespace swtr
