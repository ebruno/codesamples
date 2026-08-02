#include "ringbuffer.hpp"
#include <unistd.h>
#include <stop_token>
#include "status.hpp"
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

void SwtrRingBuffer::set_write_fd(int fd) {
    write_fd_ = fd;
}

void SwtrRingBuffer::write_loop(std::stop_token st) {
    size_t current_slot_idx = 0;

    while (!st.stop_requested()) {
        std::unique_lock lock(sync_mutex_);
        cv_.wait(lock, st, [this, current_slot_idx] {
            BufferStatus s = slots_[current_slot_idx]->status.load();
            return s == BufferStatus::readyforwrite || s == BufferStatus::LAST_BUFFER_TO_WRITE;
        });

        if (st.stop_requested()) break;

        BufferStatus status = slots_[current_slot_idx]->status.load();
        if (status == BufferStatus::readyforwrite || status == BufferStatus::LAST_BUFFER_TO_WRITE) {
            if (write_fd_ == -1) {
                handle_error(current_slot_idx, BufferStatus::STATUS_ERROR);
                return;
            }

            size_t size_to_write = slots_[current_slot_idx]->transformed_data_buffer_size.load();
            size_t original_size = slots_[current_slot_idx]->data_buffer_size.load();
            
            ssize_t bytes_written = write(write_fd_, slots_[current_slot_idx]->data.data(), size_to_write);

            if (bytes_written >= 0) {
                log_message(LogLevel::Info, "Slot {}: written {} bytes (original size {})", 
                            current_slot_idx, bytes_written, original_size);
                slots_[current_slot_idx]->data_buffer_size.store(0);

                if (status == BufferStatus::LAST_BUFFER_TO_WRITE) {
                    fsync(write_fd_);
                    cv_.notify_all();
                    return;
                }
                slots_[current_slot_idx]->status.store(BufferStatus::readyforread);
            } else {
                handle_error(current_slot_idx, BufferStatus::STATUS_ERROR);
                return;
            }
            cv_.notify_all();
        }
        current_slot_idx = (current_slot_idx + 1) % num_slots_;
    }
}

} // namespace swtr
