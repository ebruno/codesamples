#include "ringbuffer.hpp"
#include <unistd.h>
#include <stop_token>
#include "status.hpp"
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

void SwtrRingBuffer::set_read_fd(int fd) {
    read_fd_ = fd;
}

void SwtrRingBuffer::read_loop(std::stop_token st) {
    size_t current_slot_idx = 0;

    while (!st.stop_requested()) {
        std::unique_lock lock(sync_mutex_);
        cv_.wait(lock, st, [this, current_slot_idx] {
            return slots_[current_slot_idx]->status.load() == BufferStatus::readyforread;
        });

        if (st.stop_requested()) break;

        if (read_fd_ == -1) {
            handle_error(current_slot_idx, BufferStatus::STATUS_ERROR);
            return;
        }

        ssize_t bytes_read = read(read_fd_, slots_[current_slot_idx]->data.data(), slots_[current_slot_idx]->max_data_buffer_size.load());

        if (bytes_read > 0) {
            slots_[current_slot_idx]->data_buffer_size.store(static_cast<size_t>(bytes_read));
            slots_[current_slot_idx]->status.store(BufferStatus::readyfortransform);
        } else if (bytes_read == 0) {
            slots_[current_slot_idx]->status.store(BufferStatus::LAST_BUFFER_TO_TRANSFORM);
            cv_.notify_all();
            return;
        } else {
            slots_[current_slot_idx]->data_buffer_size.store(0);
            handle_error(current_slot_idx, BufferStatus::STATUS_ERROR);
            return;
        }

        cv_.notify_all();
        current_slot_idx = (current_slot_idx + 1) % num_slots_;
    }
}

} // namespace swtr
