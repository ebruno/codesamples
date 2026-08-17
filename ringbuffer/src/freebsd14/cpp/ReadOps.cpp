#include "ringbuffer.hpp"
#include <chrono>
#include <condition_variable>
#include <mutex>
#include <unistd.h>
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

void SwtrRingBuffer::set_read_fd(int fd) {
    read_fd_.store(fd);
}

void SwtrRingBuffer::read_loop() {
    while (!stop_flag_.load()) {
        size_t current_idx = read_index_.load() % slots_.size();
        BufferSlot& slot = *slots_[current_idx];

        if (slot.status.load() == BufferStatus::readyforread) {
            int fd = read_fd_.load();
            if (fd == -1) {
                handle_error(current_idx, BufferStatus::STATUS_ERROR);
                break;
            }

            ssize_t bytes_read = read(fd, slot.data.data(), slot.max_data_buffer_size);
            if (bytes_read > 0) {
                slot.data_buffer_size.store(static_cast<size_t>(bytes_read));
                slot.status.store(BufferStatus::readyfortransform);
                read_index_.fetch_add(1);
                cv_.notify_all();
            } else if (bytes_read == 0) {
                slot.status.store(BufferStatus::LAST_BUFFER_TO_TRANSFORM);
                read_index_.fetch_add(1);
                cv_.notify_all();
                break;
            } else {
                handle_error(current_idx, BufferStatus::STATUS_ERROR);
                break;
            }
        } else {
            std::unique_lock<std::mutex> lock(sync_mutex_);
            cv_.wait_for(lock, std::chrono::milliseconds(10), [&] {
                return slot.status.load() == BufferStatus::readyforread || stop_flag_.load();
            });
        }
    }
}

} // namespace swtr
