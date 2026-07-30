/**
 * @file ReadOps.cpp
 * @brief Implementation of read operations for swtr::RingBuffer.
 */

#include "ringbuffer.hpp"
#include <unistd.h>

namespace swtr {

void RingBuffer::read_op(std::stop_token st, int fd) {
    log_message(LogLevel::Info, "READ", "Reader thread started on fd {}", fd);

    while (!st.stop_requested()) {
        size_t idx = m_read_idx.load();
        
        if (m_slots[idx]->status == BufferStatus::READY_FOR_READ) {
            m_slots[idx]->status = BufferStatus::PROCESSING_READ;
            
            ssize_t bytes_read = read(fd, m_slots[idx]->data.data(), m_slots[idx]->max_data_buffer_size);
            
            if (bytes_read > 0) {
                m_slots[idx]->data_buffer_size = static_cast<size_t>(bytes_read);
                m_slots[idx]->status = BufferStatus::READY_FOR_TRANSFORM;
                log_message(LogLevel::Debug, "READ", "Read {} bytes into slot {}", bytes_read, idx);
            } else if (bytes_read == 0) {
                log_message(LogLevel::Info, "READ", "EOF detected. Marking last buffer and terminating reader.");
                m_slots[idx]->status = BufferStatus::LAST_BUFFER_TO_TRANSFORM;
                break; 
            } else {
                log_message(LogLevel::Error, "READ", "Read error on descriptor {}", fd);
                handle_error(idx, BufferStatus::ERROR);
            }
            
            m_read_idx = (idx + 1) % m_num_slots;
            m_cv.notify_all();
        } else {
            std::unique_lock lock(m_mutex);
            m_cv.wait_for(lock, std::chrono::milliseconds(10), [&]{ 
                return m_slots[m_read_idx]->status == BufferStatus::READY_FOR_READ || st.stop_requested(); 
            });
        }
    }
    log_message(LogLevel::Info, "READ", "Reader thread terminating.");
}

} // namespace swtr
