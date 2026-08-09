#include "ringbuffer.hpp"
#include "swtr_ringbuffer_impl.hpp"
#include <unistd.h>
#include <algorithm>

namespace swtr {

void SwtrRingBuffer::set_read_fd(int fd) {
    read_fd_.store(fd);
}

void SwtrRingBuffer::read_loop(std::stop_token st) {
    while (!st.stop_requested()) {
        size_t idx = read_idx_.load();
        BufferSlot& slot = *slots_[idx % num_slots_];

        if (slot.status.load() == BufferStatus::readyforread) {
            int fd = read_fd_.load();
            if (fd == -1) {
                log_message(LogLevel::Error, "Read FD not set");
                std::this_thread::sleep_for(std::chrono::milliseconds(10));
                continue;
            }

            ssize_t bytes_read = read(fd, slot.data.data(), slot.max_data_buffer_size.load());
            
            if (bytes_read > 0) {
                slot.data_buffer_size.store(static_cast<size_t>(bytes_read));
                slot.status.store(BufferStatus::readyfortransform);
                read_idx_.fetch_add(1);
                cv_.notify_all();
            } else if (bytes_read == 0) {
                slot.status.store(BufferStatus::LAST_BUFFER_TO_TRANSFORM);
                read_idx_.fetch_add(1);
                cv_.notify_all();
                break;
            } else {
                slot.status.store(BufferStatus::STATUS_ERROR);
                if (error_handler_) {
                    if (error_handler_(idx % num_slots_, BufferStatus::STATUS_ERROR) != 0) {
                        stop();
                    }
                }
                break;
            }
        } else {
            std::unique_lock<std::mutex> lock(sync_mutex_);
            cv_.wait_for(lock, std::chrono::milliseconds(10), [&] {
                return slot.status.load() == BufferStatus::readyforread || st.stop_requested();
            });
        }
    }
}

} // namespace swtr
