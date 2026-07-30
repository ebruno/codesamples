/**
 * @file Accessors_ChecksumAlg.cpp
 * @brief Implementation of checksum algorithm accessors for swtr::RingBuffer.
 */

#include "ringbuffer.hpp"

namespace swtr {

ChecksumAlgorithm RingBuffer::get_checksum_alg(size_t idx) const {
    if (idx >= m_num_slots) return ChecksumAlgorithm::NONE;
    return m_slots[idx].checksum_alg;
}

void RingBuffer::set_checksum_alg(size_t idx, ChecksumAlgorithm alg) {
    if (idx < m_num_slots) {
        m_slots[idx].checksum_alg = alg;
    }
}

bool RingBuffer::test_checksum_alg(size_t idx, ChecksumAlgorithm alg) const {
    return get_checksum_alg(idx) == alg;
}

} // namespace swtr
