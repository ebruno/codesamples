#include "ringbuffer.hpp"
#include <thread>
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

void SwtrRingBuffer::start() {
    read_thread_ = std::jthread([this](std::stop_token st) { read_loop(st); });
    transform_thread_ = std::jthread([this](std::stop_token st) { transform_loop(st); });
    write_thread_ = std::jthread([this](std::stop_token st) { write_loop(st); });
}

void SwtrRingBuffer::stop() {
    read_thread_.request_stop();
    transform_thread_.request_stop();
    write_thread_.request_stop();
    if (read_thread_.joinable()) read_thread_.join();
    if (transform_thread_.joinable()) transform_thread_.join();
    if (write_thread_.joinable()) write_thread_.join();
}

void SwtrRingBuffer::wait() {
    if (read_thread_.joinable()) read_thread_.join();
    if (transform_thread_.joinable()) transform_thread_.join();
    if (write_thread_.joinable()) write_thread_.join();
}

} // namespace swtr
