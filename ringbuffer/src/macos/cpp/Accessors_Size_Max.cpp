#include "ringbuffer.hpp"
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

size_t SwtrRingBuffer::get_max_size(size_t slot_idx) const {
    return slots_[slot_idx % num_slots_]->max_data_buffer_size.load();
}

void SwtrRingBuffer::set_max_size(size_t slot_idx, size_t size) {
    slots_[slot_idx % num_slots_]->max_data_buffer_size.store(size);
}

} // namespace swtr
