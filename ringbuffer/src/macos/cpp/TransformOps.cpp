/**
 * @file TransformOps.cpp
 * @brief Implementation of transform operations for swtr::RingBuffer.
 */

#include "ringbuffer.hpp"

namespace swtr {

void RingBuffer::transform_op(std::stop_token st) {
    log_message(LogLevel::Info, "TRANSFORM", "Transformer thread started");

    while (!st.stop_requested()) {
        size_t idx = m_transform_idx.load();
        
        if (m_slots[idx]->status == BufferStatus::READY_FOR_TRANSFORM || 
            m_slots[idx]->status == BufferStatus::LAST_BUFFER_TO_TRANSFORM) {
            
            bool is_last = (m_slots[idx]->status == BufferStatus::LAST_BUFFER_TO_TRANSFORM);
            m_slots[idx]->status = BufferStatus::PROCESSING_TRANSFORM;
            
            if (m_transform_func) {
                try {
                    m_transform_func(m_slots[idx]->data, m_slots[idx]->transformed_data_buffer_size);
                    m_slots[idx]->status = is_last ? BufferStatus::LAST_BUFFER_TO_WRITE : BufferStatus::READY_FOR_WRITE;
                    log_message(LogLevel::Debug, "TRANSFORM", "Transformed slot {} {}", idx, is_last ? "(LAST)" : "");
                } catch (...) {
                    log_message(LogLevel::Error, "TRANSFORM", "Exception during transformation of slot {}", idx);
                    handle_error(idx, BufferStatus::ERROR);
                }
            } else {
                m_slots[idx]->status = is_last ? BufferStatus::LAST_BUFFER_TO_WRITE : BufferStatus::READY_FOR_WRITE;
                log_message(LogLevel::Debug, "TRANSFORM", "No transform func specified; bypassing slot {}", idx);
            }
            
            m_transform_idx = (idx + 1) % m_num_slots;
            m_cv.notify_all();
            
            if (is_last) break;
        } else {
            std::unique_lock lock(m_mutex);
            m_cv.wait_for(lock, std::chrono::milliseconds(10), [&]{ 
                return (m_slots[m_transform_idx]->status == BufferStatus::READY_FOR_TRANSFORM || 
                        m_slots[m_transform_idx]->status == BufferStatus::LAST_BUFFER_TO_TRANSFORM) || 
                        st.stop_requested(); 
            });
        }
    }
    log_message(LogLevel::Info, "TRANSFORM", "Transformer thread terminating.");
}

} // namespace swtr
