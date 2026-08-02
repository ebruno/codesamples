#include "ringbuffer.hpp"
#include <unistd.h>
#include <stop_token>
#include <vector>
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

void SwtrRingBuffer::set_write_fd(int fd) {
    write_fd_ = fd;
}

void SwtrRingBuffer::write_loop(std::stop_token st) {
    size_t current_slot = 0;
    while (!st.stop_requested()) {
        BufferStatus status = slots_[current_slot]->status.load();
        if (status == BufferStatus::readyforwrite || status == BufferStatus::LAST_BUFFER_TO_WRITE) {
            if (write_fd_ == -1) {
                handle_error(current_slot, BufferStatus::STATUS_ERROR);
                return;
            }
            
            size_t size_to_write = slots_[current_slot]->transformed_data_buffer_size.load();
            ssize_t bytes_written = write(write_fd_, slots_[current_slot]->data.data(), size_to_write);
            
            if (bytes_written >= 0) {
                log_message(LogLevel::Info, "Slot {}: written {} bytes (original size {})", 
                            current_slot, bytes_written, slots_[current_slot]->data_buffer_size.load());
                slots_[current_slot]->data_buffer_size.store(0);
                
                if (status == BufferStatus::LAST_BUFFER_TO_WRITE) {
                    fsync(write_fd_);
                    cv_.notify_all();
                    return;
                }
                slots_[current_slot]->status.store(BufferStatus::readforread);
            } else {
                handle_error(current_slot, BufferStatus::STATUS_ERROR);
            }
            cv_.notify_all();
        }
        current_slot = (current_slot + 1) % num_slots_;
    }
}

} // namespace swtr
