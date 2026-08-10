#include "ringbuffer.hpp"
#include <atomic>
#include <chrono>
#include <condition_variable>
#include <functional>
#include <mutex>
#include <stop_token>
#include <vector>
#include "status.hpp"
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

void SwtrRingBuffer::transform_loop(std::stop_token st) {
    while (!st.stop_requested()) {
        size_t current_idx = transform_idx_.load() % slots_.size();
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
            transform_idx_.fetch_add(1);
            cv_.notify_all();
        } else if (status == BufferStatus::LAST_BUFFER_TO_TRANSFORM) {
            slot.status.store(BufferStatus::LAST_BUFFER_TO_WRITE);
            transform_idx_.fetch_add(1);
            cv_.notify_all();
            break;
        } else {
            std::unique_lock<std::mutex> lock(sync_mutex_);
            cv_.wait_for(lock, std::chrono::milliseconds(10), [&] {
                return slot.status.load() == BufferStatus::readyfortransform || 
                       slot.status.load() == BufferStatus::LAST_BUFFER_TO_TRANSFORM || 
                       st.stop_requested();
            });
        }
    }
}

} // namespace swtr
