/**
 * @file WriteOps.cpp
 * @brief Implementation of write operations for swtr::RingBuffer.
 */

#include "ringbuffer.hpp"
#include <unistd.h>

namespace swtr {

void RingBuffer::write_op(std::stop_token st, int fd) {
    log_message(LogLevel::Info, "WRITE", "Writer thread started on fd {}", fd);

    while (!st.stop_requested()) {
        size_t idx = m_write_idx.load();
        
        if (m_slots[idx].status == BufferStatus::READY_FOR_WRITE || 
            m_slots[idx].status == BufferStatus::LAST_BUFFER_TO_WRITE) {
            
            bool is_last = (m_slots[idx].status == BufferStatus::LAST_BUFFER_TO_WRITE);
            m_slots[idx].status = BufferStatus::PROCESSING_WRITE;
            
            ssize_t bytes_written = write(fd, m_slots[idx].data.data(), m_slots[idx].transformed_data_buffer_size);
            
            if (bytes_written >= 0) {
                m_slots[idx].data_buffer_size = 0;
                m_slots[idx].status = BufferStatus::READ_FOR_READ;
                log_message(LogLevel::Debug, "WRITE", "Wrote data from slot {} {}", idx, is_last ? "(LAST)" : "");
            } else {
                log_message(LogLevel::Error, "WRITE", "Write error on descriptor {}", fd);
                handle_error(idx, BufferStatus::ERROR);
            }
            
            m_write_idx = (idx + 1) % m_num_slots;
            m_cv.notify_all();
            
            if (is_last) break;
        } else {
            std::unique_lock lock(m_mutex);
            m_cv.wait_for(lock, std::chrono::milliseconds(10), [&]{ 
                return (m_slots[m_write_idx].status == BufferStatus::READY_FOR_WRITE || 
                        m_slots[m_write_idx].status == BufferStatus::LAST_BUFFER_TO_WRITE) || 
                        st.stop_requested(); 
            });
        }
    }
    log_message(LogLevel::Info, "WRITE", "Writer thread terminating.");
}

} // namespace swtr
