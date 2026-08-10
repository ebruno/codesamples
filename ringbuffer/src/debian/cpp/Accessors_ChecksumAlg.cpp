#include "ringbuffer.hpp"
#include "status.hpp"
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

ChecksumAlgorithm SwtrRingBuffer::get_checksum_alg(size_t slot_idx) const {
    return slots_[slot_idx % slots_.size()]->checksum_alg.load();
}

void SwtrRingBuffer::set_checksum_alg(size_t slot_idx, ChecksumAlgorithm alg) {
    slots_[slot_idx % slots_.size()]->checksum_alg.store(alg);
}

bool SwtrRingBuffer::test_checksum_alg(size_t slot_idx, ChecksumAlgorithm alg) const {
    return get_checksum_alg(slot_idx) == alg;
}

} // namespace swtr
