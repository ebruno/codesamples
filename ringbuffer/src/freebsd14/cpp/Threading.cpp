#include "ringbuffer.hpp"
#include <mutex>
#include <thread>
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

void SwtrRingBuffer::start() {
    std::lock_guard<std::mutex> lock(sync_mutex_);

    // Start threads in order: Write, Transform, Read
    // FreeBSD: std::thread + stop_source (no <jthread> available)
    if (!write_thread_.joinable()) {
        write_thread_ = std::thread([this]() { write_loop(stop_src_.get_token()); });
    }
    if (!transform_thread_.joinable()) {
        transform_thread_ = std::thread([this]() { transform_loop(stop_src_.get_token()); });
    }
    if (!read_thread_.joinable()) {
        read_thread_ = std::thread([this]() { read_loop(stop_src_.get_token()); });
    }
}

void SwtrRingBuffer::stop() {
    std::lock_guard<std::mutex> lock(sync_mutex_);
    // FreeBSD: request_stop() on stop_source, not on threads
    stop_src_.request_stop();
    cv_.notify_all();
}

void SwtrRingBuffer::wait() {
    if (read_thread_.joinable()) read_thread_.join();
    if (transform_thread_.joinable()) transform_thread_.join();
    if (write_thread_.joinable()) write_thread_.join();
}

} // namespace swtr
