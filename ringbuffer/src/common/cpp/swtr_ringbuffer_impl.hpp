#pragma once

#include <atomic>
#include <condition_variable>
#include <functional>
#include <mutex>
#ifndef __FreeBSD__
#include <stop_token>
#endif
#include <string>
#include <thread>
#include <vector>
#include "ringbuffer.hpp"
#include "status.hpp"

// Symbol visibility macro for shared library exports
#ifndef SWTR_EXPORT
#define SWTR_EXPORT __attribute__((visibility("default")))
#endif

namespace swtr {

/// @brief Concrete implementation of the pipelined ringbuffer with lock-free atomic coordination.
/// Uses three independent threads (read → transform → write) operating on shared slots with atomic index counters.
class SWTR_EXPORT SwtrRingBuffer : public RingBuffer {
public:
    /// @brief Construct a new SwtrRingBuffer.
    /// @param num_slots Number of pipeline slots (minimum 1).
    /// @param initial_status Initial state for all slots.
    /// @param buffer_size Per-slot data buffer capacity in bytes.
    /// @param err_handler Optional error callback; return non-zero to abort pipeline on error.
    /// @param transform_fn User-supplied function applied to each buffer slot's data by the transform thread.
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
    // Pipelines
#ifdef __FreeBSD__
    /// @brief Read thread: fills slots from input fd, marks readyfortransform on EOF.
    void read_loop();
    /// @brief Transform thread: applies user function, computes checksum.
    void transform_loop();
    /// @brief Write thread: writes transformed data, clears slots.
    void write_loop();
#else
    /// @brief Read thread: fills slots from input fd, marks readyfortransform on EOF.
    void read_loop(std::stop_token st);
    /// @brief Transform thread: applies user function, computes checksum.
    void transform_loop(std::stop_token st);
    /// @brief Write thread: writes transformed data, clears slots.
    void write_loop(std::stop_token st);
#endif

    // Error Handling
    /// @brief Error handler: invokes callback and triggers pipeline shutdown.
    void handle_error(size_t slot_idx, BufferStatus status);

    // Members
    std::vector<std::unique_ptr<BufferSlot>> slots_;
    size_t num_slots_;

    // Index tracking (atomic for cross-thread access) — one per pipeline stage
    alignas(64) std::atomic<size_t> read_index_{0};
    alignas(64) std::atomic<size_t> transform_index_{0};
    alignas(64) std::atomic<size_t> write_index_{0};

    // File descriptors (atomic for cross-thread access)
    std::atomic<int> read_fd_{-1};
    std::atomic<int> write_fd_{-1};

    // Buffer size per slot
    size_t buffer_size_;

    // Pipeline functions (non-atomic: set once at construction)
    ErrorHandler err_handler_{nullptr};
    TransformFn transform_fn_;

    // Thread management — macOS/Linux: jthread (auto-stops), FreeBSD: thread + atomic flag
#ifdef __FreeBSD__
    std::atomic<bool> stop_flag_{false};
#endif
#ifdef __FreeBSD__
    std::thread read_thread_;
#else
    std::jthread read_thread_;
#endif
#ifdef __FreeBSD__
    std::thread transform_thread_;
#else
    std::jthread transform_thread_;
#endif
#ifdef __FreeBSD__
    std::thread write_thread_;
#else
    std::jthread write_thread_;
#endif

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
