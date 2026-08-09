#include "ringbuffer.hpp"
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

void SwtrRingBuffer::start() {
    std::lock_guard<std::mutex> lock(sync_mutex_);
    
    if (!write_thread_.joinable()) {
        write_thread_ = std::jthread([this](std::stop_token st) { write_loop(st); });
    }
    if (!transform_thread_.joinable()) {
        transform_thread_ = std::jthread([this](std::stop_token st) { transform_loop(st); });
    }
    if (!read_thread_.joinable()) {
        read_thread_ = std::jthread([this](std::stop_token st) { read_loop(st); });
    }
}

void SwtrRingBuffer::stop() {
    std::lock_guard<std::mutex> lock(sync_mutex_);
    read_thread_.request_stop();
    transform_thread_.request_stop();
    write_thread_.request_stop();
    cv_.notify_all();
}

void SwtrRingBuffer::wait() {
    if (read_thread_.joinable()) read_thread_.join();
    if (transform_thread_.joinable()) transform_thread_.join();
    if (write_thread_.joinable()) write_thread_.join();
}

} // namespace swtr
