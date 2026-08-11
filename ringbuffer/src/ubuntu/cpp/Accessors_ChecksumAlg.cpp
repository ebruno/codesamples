#include "ringbuffer.hpp"
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

ChecksumAlgorithm SwtrRingBuffer::get_checksum_alg(size_t slot_idx) const {
    if (slot_idx >= num_slots_) { handle_error(slot_idx, BufferStatus::STATUS_ERROR); return ChecksumAlgorithm::NONE; }
    return slots_[slot_idx]->checksum_alg.load();
}

void SwtrRingBuffer::set_checksum_alg(size_t slot_idx, ChecksumAlgorithm alg) {
    if (slot_idx >= num_slots_) { handle_error(slot_idx, BufferStatus::STATUS_ERROR); return; }
    slots_[slot_idx]->checksum_alg.store(alg);
}

bool SwtrRingBuffer::test_checksum_alg(size_t slot_idx, ChecksumAlgorithm alg) const {
    if (slot_idx >= num_slots_) { handle_error(slot_idx, BufferStatus::STATUS_ERROR); return false; }
    return slots_[slot_idx]->checksum_alg.load() == alg;
}

} // namespace swtr
