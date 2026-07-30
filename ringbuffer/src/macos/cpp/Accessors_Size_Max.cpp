/**
 * @file Accessors_Size_Max.cpp
 * @brief Implementation of maximum buffer size accessors for swtr::RingBuffer.
 */

#include "ringbuffer.hpp"

namespace swtr {

size_t RingBuffer::get_max_size(size_t idx) const {
    if (idx >= m_num_slots) return 0;
    return m_slots[idx].max_data_buffer_size;
}

void RingBuffer::set_max_size(size_t idx, size_t size) {
    if (idx < m_num_slots) {
        m_slots[idx].max_data_buffer_size = size;
    }
}

} // namespace swtr
