/**
 * @file ErrorOps.cpp
 * @brief Implementation of error handling for swtr::RingBuffer.
 */

#include "ringbuffer.hpp"

namespace swtr {

/**
 * @brief Processes slot errors using the configured error handler.
 */
void RingBuffer::handle_error(size_t slot_idx, BufferStatus status) {
    m_slots[slot_idx].status = status;
    
    if (m_error_handler) {
        // Call the user-provided error handling routine
        if (m_error_handler(slot_idx, status) != 0) {
            // Non-zero return triggers full pipeline stop
            m_stop_source.request_stop();
            m_cv.notify_all();
        }
    } else {
        // Default behavior: stop pipeline if no handler is provided
        m_stop_source.request_stop();
        m_cv.notify_all();
    }
}

} // namespace swtr
