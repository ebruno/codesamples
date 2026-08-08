#include "ringbuffer.hpp"
#include <atomic>
#include <chrono>
#include <condition_variable>
#include <mutex>
#include <stop_token>
#include <unistd.h>
#include <vector>
#include "status.hpp"
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

void SwtrRingBuffer::set_read_fd(int fd) {
    read_fd_.store(fd);
}

void SwtrRingBuffer::read_loop(std::stop_token st) {
    while (!st.stop_requested()) {
        size_t current_idx = read_idx_.load() % slots_.size();
        BufferSlot& slot = *slots_[current_idx];

        if (slot.status.load() == BufferStatus::readyforread) {
            std::cout << "Read loop: slot " << current_idx << " is readyforread" << std::endl;
            int fd = read_fd_.load();
            if (fd == -1) {
                handle_error(current_idx, BufferStatus::STATUS_ERROR);
                break;
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
                handle_error(current_idx, BufferStatus::STATUS_ERROR);
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
