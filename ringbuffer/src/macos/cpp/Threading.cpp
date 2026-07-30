/**
 * @file Threading.cpp
 * @brief Implementation of thread management for swtr::RingBuffer.
 */

#include "ringbuffer.hpp"
#include <iostream>

namespace swtr {

/**
 * @brief Launches the pipeline threads with the provided configurations.
 */
void RingBuffer::start(int read_fd, int write_fd, 
                       std::function<void(std::vector<uint8_t>&, size_t&)> transform_func,
                       int (*error_handler)(size_t, BufferStatus)) {
    m_transform_func = transform_func;
    m_error_handler = error_handler;

    // To avoid stop_source/stop_token SDK compatibility issues, 
    // we use a simple flag or the jthread's own stop token in the workers.
    // For the specific requirement of a stop_callback, we use a lambda in the stop() method.

    m_read_thread = std::jthread([this, read_fd](std::stop_token st) {
        this->read_op(st, read_fd);
    });

    m_transform_thread = std::jthread([this](std::stop_token st) {
        this->transform_op(st);
    });

    m_write_thread = std::jthread([this, write_fd](std::stop_token st) {
        this->write_op(st, write_fd);
    });
}

/**
 * @brief Requests stop and joins all pipeline threads.
 */
void RingBuffer::stop() {
    std::cout << "[swtr] Stop signal received: initiating immediate pipeline shutdown..." << std::endl;
    m_stop_source.request_stop();
    m_cv.notify_all();
    
    if (m_read_thread.joinable()) m_read_thread.join();
    if (m_transform_thread.joinable()) m_transform_thread.join();
    if (m_write_thread.joinable()) m_write_thread.join();
}

/**
 * @brief Blocks until all pipeline threads have terminated.
 */
void RingBuffer::wait() {
    if (m_read_thread.joinable()) m_read_thread.join();
    if (m_transform_thread.joinable()) m_transform_thread.join();
    if (m_write_thread.joinable()) m_write_thread.join();
}

} // namespace swtr
