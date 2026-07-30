/**
 * @file Accessors_ChecksumVal.cpp
 * @brief Implementation of checksum value accessors for swtr::RingBuffer.
 */

#include "ringbuffer.hpp"

namespace swtr {

uint64_t RingBuffer::get_checksum_val(size_t idx) const {
    if (idx >= m_num_slots) return 0;
    return m_slots[idx].checksum_val;
}

void RingBuffer::set_checksum_val(size_t idx, uint64_t val) {
    if (idx < m_num_slots) {
        m_slots[idx].checksum_val = val;
    }
}

bool RingBuffer::test_checksum_val(size_t idx, uint64_t val) const {
    return get_checksum_val(idx) == val;
}

} // namespace swtr
