#include "ringbuffer.hpp"
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

void SwtrRingBuffer::transform_loop(std::stop_token st) {
    while (!st.stop_requested()) {
        size_t idx = transform_idx_.load();
        BufferSlot& slot = *slots_[idx % num_slots_];

        if (slot.status.load() == BufferStatus::readyfortransform) {
            size_t data_size = slot.data_buffer_size.load();
            std::vector<uint8_t> temp_data(slot.data.begin(), slot.data.begin() + data_size);
            size_t transformed_size = data_size;

            if (transform_fn_) {
                transform_fn_(temp_data, transformed_size);
                // In a real implementation, we'd handle the transformed data. 
                // For this spec, we just update the size and mark as ready.
            }

            slot.transformed_data_buffer_size.store(transformed_size);
            slot.status.store(BufferStatus::readyforwrite);
            transform_idx_.fetch_add(1);
            cv_.notify_all();
        } else if (slot.status.load() == BufferStatus::LAST_BUFFER_TO_TRANSFORM) {
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
