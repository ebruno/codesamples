#pragma once

#include <atomic>
#include <condition_variable>
#include <functional>
#include <memory>
#include <mutex>
#include <stop_token>
#include <string>
#include <thread>
#include <vector>
#include "ringbuffer.hpp"
#include "status.hpp"

namespace swtr {

struct BufferSlot {
    size_t buffer_idx;                                    // non-atomic: slot index
    std::atomic<BufferStatus> status;                     // atomic: current buffer state
    size_t max_data_buffer_size;                          // non-atomic: maximum capacity
    std::atomic<size_t> data_buffer_size;                 // atomic: current bytes in data buffer
    std::atomic<size_t> transformed_data_buffer_size;     // atomic: current bytes in transformed buffer
    std::atomic<ChecksumAlgorithm> checksum_alg;          // atomic: algorithm used for checksum
    std::atomic<uint32_t> checksum_val;                   // atomic: computed checksum value
    std::vector<uint8_t> data;                            // non-atomic: internal data buffer (raw bytes)
};

class __attribute__((visibility("default"))) SwtrRingBuffer : public RingBuffer {
public:
    SwtrRingBuffer(size_t num_slots = MIN_NUMBER_SLOTS,
                   BufferStatus initial_status = BufferStatus::readyforread,
                   size_t buffer_size = DEFAULT_BUFFER_SIZE,
                   ErrorHandler err_handler = nullptr,
                   TransformFn transform_fn = nullptr);
    ~SwtrRingBuffer() override = default;

    // Thread Control
    void start() override;
    void stop() override;
    void wait() override;

    // Configuration
    void set_read_fd(int fd) override;
    void set_write_fd(int fd) override;

    // Logging
    void set_logging_enabled(bool enabled) override;
    bool get_logging_enabled() const override;
    void set_output_stream(std::ostream& stream) override;
    std::ostream* get_output_stream() const override;
    void set_read_logging_enabled(bool enabled) override;
    bool get_read_logging_enabled() const override;
    void set_read_verbosity(LogLevel level) override;
    LogLevel get_read_verbosity() const override;
    void set_transform_logging_enabled(bool enabled) override;
    bool get_transform_logging_enabled() const override;
    void set_transform_verbosity(LogLevel level) override;
    LogLevel get_transform_verbosity() const override;
    void set_write_logging_enabled(bool enabled) override;
    bool get_write_logging_enabled() const override;
    void set_write_verbosity(LogLevel level) override;
    LogLevel get_write_verbosity() const override;

    // Accessors
    BufferStatus get_status(size_t slot_idx) const override;
    void set_status(size_t slot_idx, BufferStatus status) override;
    bool test_status(size_t slot_idx, BufferStatus status) const override;
    ChecksumAlgorithm get_checksum_alg(size_t slot_idx) const override;
    void set_checksum_alg(size_t slot_idx, ChecksumAlgorithm alg) override;
    bool test_checksum_alg(size_t slot_idx, ChecksumAlgorithm alg) const override;
    uint32_t get_checksum_val(size_t slot_idx) const override;
    void set_checksum_val(size_t slot_idx, uint32_t val) override;
    bool test_checksum_val(size_t slot_idx, uint32_t val) const override;
    size_t get_max_size(size_t slot_idx) const override;
    void set_max_size(size_t slot_idx, size_t size) override;
    size_t get_data_size(size_t slot_idx) const override;
    void set_data_size(size_t slot_idx, size_t size) override;
    size_t get_transformed_size(size_t slot_idx) const override;
    void set_transformed_size(size_t slot_idx, size_t size) override;

protected:
    void do_log(LogLevel level, const std::string& message) override;

private:
    void read_loop(std::stop_token st);
    void transform_loop(std::stop_token st);
    void write_loop(std::stop_token st);

    // Slot storage
    std::vector<std::unique_ptr<BufferSlot>> slots_;
    size_t num_slots_;

    // Index tracking — one independent atomic counter per pipeline stage
    std::atomic<size_t> read_index_{0};
    std::atomic<size_t> transform_index_{0};
    std::atomic<size_t> write_index_{0};

    // File descriptors (atomic for cross-thread access)
    std::atomic<int> read_fd_{-1};
    std::atomic<int> write_fd_{-1};

    // Buffer size per slot
    size_t buffer_size_;

    // Pipeline functions (non-atomic: set once at construction)
    ErrorHandler err_handler_;
    TransformFn transform_fn_;

    // Thread management
    std::jthread read_thread_;
    std::jthread transform_thread_;
    std::jthread write_thread_;

    // Synchronization primitives (aligned to cache line)
    alignas(64) std::mutex sync_mutex_;
    std::condition_variable_any cv_;

    // Logging configuration (atomic for runtime reconfiguration)
    std::atomic<bool> logging_enabled_{false};
    std::atomic<bool> read_logging_enabled_{false};
    std::atomic<bool> transform_logging_enabled_{false};
    std::atomic<bool> write_logging_enabled_{false};
    std::atomic<LogLevel> read_verbosity_{LogLevel::Info};
    std::atomic<LogLevel> transform_verbosity_{LogLevel::Info};
    std::atomic<LogLevel> write_verbosity_{LogLevel::Info};

    // Output stream (pointer, not reference)
    std::ostream* output_stream_{&std::cerr};

    // Log mutex (separate from sync_mutex_ to avoid nested locking)
    std::mutex log_mutex_;
};

} // namespace swtr
