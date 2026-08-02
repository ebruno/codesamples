#include "ringbuffer.hpp"
#include <stop_token>
#include <vector>
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

void SwtrRingBuffer::transform_loop(std::stop_token st) {
    size_t current_slot = 0;
    while (!st.stop_requested()) {
        BufferStatus status = slots_[current_slot]->status.load();
        if (status == BufferStatus::readyfortransform || status == BufferStatus::LAST_BUFFER_TO_TRANSFORM) {
            if (transform_fn_) {
                size_t transformed_size = 0;
                transform_fn_(slots_[current_slot]->data, transformed_size);
                slots_[current_slot]->transformed_data_buffer_size.store(transformed_size);
            } else {
                slots_[current_slot]->transformed_data_buffer_size.store(slots_[current_slot]->data_buffer_size.load());
                log_message(LogLevel::Info, "No transform function specified for slot {}", current_slot);
            }
            
            if (status == BufferStatus::LAST_BUFFER_TO_TRANSFORM) {
                slots_[current_slot]->status.store(BufferStatus::LAST_BUFFER_TO_WRITE);
                cv_.notify_all();
                return;
            } else {
                slots_[current_slot]->status.store(BufferStatus::readyforwrite);
                cv_.notify_all();
            }
        }
        current_slot = (current_slot + 1) % num_slots_;
    }
}

} // namespace swtr
