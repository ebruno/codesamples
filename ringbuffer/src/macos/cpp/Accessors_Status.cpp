/**
 * @file Accessors_Status.cpp
 * @brief Implementation of status accessors for swtr::RingBuffer.
 */

#include "ringbuffer.hpp"

namespace swtr {

BufferStatus RingBuffer::get_status(size_t idx) const {
    if (idx >= m_num_slots) return BufferStatus::ERROR;
    return m_slots[idx]->status.load();
}

void RingBuffer::set_status(size_t idx, BufferStatus status) {
    if (idx < m_num_slots) {
        m_slots[idx]->status = status;
    }
}

bool RingBuffer::test_status(size_t idx, BufferStatus status) const {
    return get_status(idx) == status;
}

} // namespace swtr
