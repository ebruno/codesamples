/**
 * @file Accessors_Size_Transformed.cpp
 * @brief Implementation of transformed data size accessors for swtr::RingBuffer.
 */

#include "ringbuffer.hpp"

namespace swtr {

size_t RingBuffer::get_transformed_size(size_t idx) const {
    if (idx >= m_num_slots) return 0;
    return m_slots[idx].transformed_data_buffer_size;
}

void RingBuffer::set_transformed_size(size_t idx, size_t size) {
    if (idx < m_num_slots) {
        m_slots[idx].transformed_data_buffer_size = size;
    }
}

} // namespace swtr
