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
    
    m_slots.reserve(num_slots);
    for (size_t i = 0; i < num_slots; ++i) {
        auto slot = std::make_unique<BufferSlot>();
        slot->idx = i;
        slot->status = initial_status;
        slot->max_data_buffer_size = buffer_size;
        slot->data_buffer_size = 0;
        slot->transformed_data_buffer_size = 0;
        slot->checksum_alg = ChecksumAlgorithm::NONE;
        slot->checksum_val = 0;
        slot->data.resize(buffer_size);
        m_slots.push_back(std::move(slot));
    }
}

/**
 * @brief Stops all threads before destruction.
 * 
 * Note: We do not use = default in the header because the implementation
 * calls stop() to ensure threads are joined.
 */
RingBuffer::~RingBuffer() {
    stop();
}

} // namespace swtr
