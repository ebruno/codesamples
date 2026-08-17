#include "ringbuffer.hpp"
#include <mutex>
#include <thread>
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

void SwtrRingBuffer::start() {
    std::lock_guard<std::mutex> lock(sync_mutex_);

    // Start threads in order: Write, Transform, Read
#ifdef __FreeBSD__
    if (!write_thread_.joinable()) {
        write_thread_ = std::thread([this]() { write_loop(); });
    }
    if (!transform_thread_.joinable()) {
        transform_thread_ = std::thread([this]() { transform_loop(); });
    }
    if (!read_thread_.joinable()) {
        read_thread_ = std::thread([this]() { read_loop(); });
    }
#else
    if (!write_thread_.joinable()) {
        write_thread_ = std::jthread([this](std::stop_token st) { write_loop(st); });
    }
    if (!transform_thread_.joinable()) {
        transform_thread_ = std::jthread([this](std::stop_token st) { transform_loop(st); });
    }
    if (!read_thread_.joinable()) {
        read_thread_ = std::jthread([this](std::stop_token st) { read_loop(st); });
    }
#endif
}

void SwtrRingBuffer::stop() {
    std::lock_guard<std::mutex> lock(sync_mutex_);
#ifdef __FreeBSD__
    stop_flag_.store(true);
#endif
#ifndef __FreeBSD__
    read_thread_.request_stop();
    transform_thread_.request_stop();
    write_thread_.request_stop();
#endif
    cv_.notify_all();
}

void SwtrRingBuffer::wait() {
    if (read_thread_.joinable()) read_thread_.join();
    if (transform_thread_.joinable()) transform_thread_.join();
    if (write_thread_.joinable()) write_thread_.join();
}

} // namespace swtr
