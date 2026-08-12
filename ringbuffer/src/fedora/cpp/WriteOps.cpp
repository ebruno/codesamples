#include "ringbuffer.hpp"
#include <algorithm>
#include <chrono>
#include <condition_variable>
#include <mutex>
#include <stop_token>
#include <unistd.h>
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

void SwtrRingBuffer::set_write_fd(int fd) {
    write_fd_.store(fd);
}

void SwtrRingBuffer::write_loop(std::stop_token st) {
    while (!st.stop_requested()) {
        size_t current_idx = write_index_.load() % slots_.size();
        BufferSlot& slot = *slots_[current_idx];
        BufferStatus status = slot.status.load();

        if (status == BufferStatus::readyforwrite) {
            int fd = write_fd_.load();
            if (fd == -1) {
                handle_error(current_idx, BufferStatus::STATUS_ERROR);
                break;
            }

            size_t size = slot.transformed_data_buffer_size.load();
            ssize_t bytes_written = write(fd, slot.data.data(), size);
            if (bytes_written >= 0) {
                std::fill(slot.data.begin(), slot.data.end(), 0);
                slot.data_buffer_size.store(0);
                slot.status.store(BufferStatus::readyforread);
                write_index_.fetch_add(1);
                cv_.notify_all();
            } else {
                handle_error(current_idx, BufferStatus::STATUS_ERROR);
                break;
            }
        } else if (status == BufferStatus::LAST_BUFFER_TO_WRITE) {
            int fd = write_fd_.load();
            if (fd != -1) {
                fsync(fd);
            }
            std::fill(slot.data.begin(), slot.data.end(), 0);
            slot.status.store(BufferStatus::readyforread);
            write_index_.fetch_add(1);
            cv_.notify_all();
            break;
        } else {
            std::unique_lock<std::mutex> lock(sync_mutex_);
            cv_.wait_for(lock, std::chrono::milliseconds(10), [&] {
                return slot.status.load() == BufferStatus::readyforwrite ||
                       slot.status.load() == BufferStatus::LAST_BUFFER_TO_WRITE ||
                       st.stop_requested();
            });
        }
    }
}

} // namespace swtr
