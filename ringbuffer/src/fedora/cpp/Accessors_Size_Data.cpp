#include "ringbuffer.hpp"
#include "status.hpp"
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

size_t SwtrRingBuffer::get_data_size(size_t slot_idx) const {
    return slots_[slot_idx]->data_buffer_size.load();
}

void SwtrRingBuffer::set_data_size(size_t slot_idx, size_t size) {
    slots_[slot_idx]->data_buffer_size.store(size);
}

} // namespace swtr
