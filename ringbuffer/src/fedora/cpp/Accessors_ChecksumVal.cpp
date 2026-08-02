#include "ringbuffer.hpp"
#include "status.hpp"
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

uint32_t SwtrRingBuffer::get_checksum_val(size_t slot_idx) const {
    return slots_[slot_idx]->checksum_val.load();
}

void SwtrRingBuffer::set_checksum_val(size_t slot_idx, uint32_t val) {
    slots_[slot_idx]->checksum_val.store(val);
}

bool SwtrRingBuffer::test_checksum_val(size_t slot_idx, uint32_t val) const {
    return slots_[slot_idx]->checksum_val.load() == val;
}

} // namespace swtr
