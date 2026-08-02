#include "ringbuffer.hpp"
#include <stop_token>
#include "status.hpp"
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

void SwtrRingBuffer::transform_loop(std::stop_token st) {
    size_t current_slot_idx = 0;

    while (!st.stop_requested()) {
        std::unique_lock lock(sync_mutex_);
        cv_.wait(lock, st, [this, current_slot_idx] {
            BufferStatus s = slots_[current_slot_idx]->status.load();
            return s == BufferStatus::readyfortransform || s == BufferStatus::LAST_BUFFER_TO_TRANSFORM;
        });

        if (st.stop_requested()) break;

        BufferStatus status = slots_[current_slot_idx]->status.load();
        if (status == BufferStatus::readyfortransform || status == BufferStatus::LAST_BUFFER_TO_TRANSFORM) {
            if (transform_fn_) {
                size_t temp_size = slots_[current_slot_idx]->data_buffer_size.load();
                transform_fn_(slots_[current_slot_idx]->data, temp_size);
                slots_[current_slot_idx]->transformed_data_buffer_size.store(temp_size);
            } else {
                size_t data_size = slots_[current_slot_idx]->data_buffer_size.load();
                slots_[current_slot_idx]->transformed_data_buffer_size.store(data_size);
                log_message(LogLevel::Info, "No transform function specified for slot {}", current_slot_idx);
            }

            if (status == BufferStatus::LAST_BUFFER_TO_TRANSFORM) {
                slots_[current_slot_idx]->status.store(BufferStatus::LAST_BUFFER_TO_WRITE);
                cv_.notify_all();
                return;
            } else {
                slots_[current_slot_idx]->status.store(BufferStatus::readyforwrite);
                cv_.notify_all();
            }
        }
        current_slot_idx = (current_slot_idx + 1) % num_slots_;
    }
}

} // namespace swtr
