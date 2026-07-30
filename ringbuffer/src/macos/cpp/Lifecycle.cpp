/**
 * @file Lifecycle.cpp
 * @brief Implementation of constructor and destructor for swtr::RingBuffer.
 */

#include "ringbuffer.hpp"
#include <stdexcept>

namespace swtr {

/**
 * @brief Constructs the RingBuffer and initializes all slots.
 * 
 * @throws std::invalid_argument if num_slots <= 1 or buffer_size <= 1.
 */
RingBuffer::RingBuffer(size_t num_slots, BufferStatus initial_status, size_t buffer_size) 
    : m_num_slots(num_slots) {
    
    if (num_slots <= 1) {
        throw std::invalid_argument("Number of slots must be greater than 1");
    }
    if (buffer_size <= 1) {
        throw std::invalid_argument("Buffer size per slot must be greater than 1");
    }
    
    m_slots.resize(num_slots);
    for (size_t i = 0; i < num_slots; ++i) {
        m_slots[i].idx = i;
        m_slots[i].status = initial_status;
        m_slots[i].max_data_buffer_size = buffer_size;
        m_slots[i].data_buffer_size = 0;
        m_slots[i].transformed_data_buffer_size = 0;
        m_slots[i].checksum_alg = ChecksumAlgorithm::NONE;
        m_slots[i].checksum_val = 0;
        m_slots[i].data.resize(buffer_size);
    }
}

/**
 * @brief Stops all threads before destruction.
 */
RingBuffer::~RingBuffer() {
    stop();
}

} // namespace swtr
