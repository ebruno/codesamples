#include "ringbuffer.hpp"
#include <chrono>
#include <condition_variable>
#include <mutex>
#ifndef __FreeBSD__
#include <stop_token>
#endif
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

#ifdef __FreeBSD__
void SwtrRingBuffer::transform_loop() {
    while (!stop_flag_.load()) {
#else
void SwtrRingBuffer::transform_loop(std::stop_token st) {
    while (!st.stop_requested()) {
#endif
        size_t current_idx = transform_index_.load() % slots_.size();
        BufferSlot& slot = *slots_[current_idx];
        BufferStatus status = slot.status.load();

        if (status == BufferStatus::readyfortransform) {
            size_t data_size = slot.data_buffer_size.load();
            size_t transformed_size = data_size;

            if (transform_fn_) {
                transform_fn_(slot.data, transformed_size);
            }

            slot.transformed_data_buffer_size.store(transformed_size);
            slot.status.store(BufferStatus::readyforwrite);
            transform_index_.fetch_add(1);
            cv_.notify_all();
        } else if (status == BufferStatus::LAST_BUFFER_TO_TRANSFORM) {
            slot.status.store(BufferStatus::LAST_BUFFER_TO_WRITE);
            transform_index_.fetch_add(1);
            cv_.notify_all();
            break;
        } else {
            std::unique_lock<std::mutex> lock(sync_mutex_);
            cv_.wait_for(lock, std::chrono::milliseconds(10), [&] {
#ifdef __FreeBSD__
                return slot.status.load() == BufferStatus::readyfortransform ||
                       slot.status.load() == BufferStatus::LAST_BUFFER_TO_TRANSFORM ||
                       stop_flag_.load();
#else
                return slot.status.load() == BufferStatus::readyfortransform ||
                       slot.status.load() == BufferStatus::LAST_BUFFER_TO_TRANSFORM ||
                       st.stop_requested();
#endif
            });
        }
    }
}

} // namespace swtr
