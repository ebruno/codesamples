#pragma once
#include <atomic>
#include <cstddef>
#include <format>
#include <functional>
#include <iostream>
#include <string>
#include "status.hpp"

/// @brief Core ringbuffer library namespace.
/// Contains the pipeline types, enums, and class hierarchy for the swtr ringbuffer implementation.
namespace swtr {

/// @brief Error handler callback signature.
/// Invoked when a pipeline error occurs. Return non-zero to trigger pipeline shutdown.
using ErrorHandler = int (*)(size_t slot_idx, BufferStatus status);

/// @brief User-supplied transform function signature.
/// Applied to each buffer slot's data by the transform thread. Modifies `data` in-place and updates `size`.
using TransformFn = std::function<void(std::vector<uint8_t>&, size_t&)>;

/// @brief Shared slot in the pipeline with its own state machine, checksum, and data buffer.
/// Each slot is cache-line aligned (64 bytes) to prevent false sharing between threads.
struct BufferSlot {
    alignas(64) size_t buffer_idx;                                    // non-atomic: slot index
    alignas(64) std::atomic<BufferStatus> status;                     // atomic: current buffer state
    alignas(64) size_t max_data_buffer_size;                          // non-atomic: maximum capacity
    alignas(64) std::atomic<size_t> data_buffer_size;                 // atomic: current bytes in data buffer
    alignas(64) std::atomic<size_t> transformed_data_buffer_size;     // atomic: current bytes in transformed buffer
    alignas(64) std::atomic<ChecksumAlgorithm> checksum_alg;          // atomic: algorithm used for checksum
    alignas(64) std::atomic<uint32_t> checksum_val;                   // atomic: computed checksum value
    std::vector<uint8_t> data;                                        // non-atomic: internal data buffer (raw bytes)

    BufferSlot(size_t idx, size_t max_size)
        : buffer_idx(idx),
          status(BufferStatus::readyforread),
          max_data_buffer_size(max_size),
          data_buffer_size(0),
          transformed_data_buffer_size(0),
          checksum_alg(ChecksumAlgorithm::NONE),
          checksum_val(0),
          data(max_size) {}
};

/// @brief Minimum number of pipeline slots allowed (1).
constexpr size_t MIN_NUMBER_SLOTS = 1;

/// @brief Default per-slot data buffer capacity in bytes (4096).
constexpr size_t DEFAULT_BUFFER_SIZE = 4096;

/// @brief Abstract base class defining the ringbuffer pipeline interface.
/// Provides thread control, configuration, logging, and accessor methods for all implementations.
class RingBuffer {
public:
    virtual ~RingBuffer() = default;

    // Thread Control
    /// @brief Launch read/transform/write threads and begin pipeline processing.
    virtual void start() = 0;
    /// @brief Signal all threads to stop cooperatively.
    virtual void stop() = 0;
    /// @brief Block until pipeline completes and all threads have joined.
    virtual void wait() = 0;

    // Configuration
    /// @brief Set input file descriptor for the read thread.
    virtual void set_read_fd(int fd) = 0;
    /// @brief Set output file descriptor for the write thread.
    virtual void set_write_fd(int fd) = 0;

    // Logging
    virtual void set_logging_enabled(bool enabled) = 0;
    virtual bool get_logging_enabled() const = 0;
    virtual void set_output_stream(std::ostream& stream) = 0;
    virtual std::ostream* get_output_stream() const = 0;
    virtual void set_read_logging_enabled(bool enabled) = 0;
    virtual bool get_read_logging_enabled() const = 0;
    virtual void set_read_verbosity(LogLevel level) = 0;
    virtual LogLevel get_read_verbosity() const = 0;
    virtual void set_transform_logging_enabled(bool enabled) = 0;
    virtual bool get_transform_logging_enabled() const = 0;
    virtual void set_transform_verbosity(LogLevel level) = 0;
    virtual LogLevel get_transform_verbosity() const = 0;
    virtual void set_write_logging_enabled(bool enabled) = 0;
    virtual bool get_write_logging_enabled() const = 0;
    virtual void set_write_verbosity(LogLevel level) = 0;
    virtual LogLevel get_write_verbosity() const = 0;

    // Accessors
    virtual BufferStatus get_status(size_t slot_idx) const = 0;
    virtual void set_status(size_t slot_idx, BufferStatus status) = 0;
    virtual bool test_status(size_t slot_idx, BufferStatus status) const = 0;
    virtual ChecksumAlgorithm get_checksum_alg(size_t slot_idx) const = 0;
    virtual void set_checksum_alg(size_t slot_idx, ChecksumAlgorithm alg) = 0;
    virtual bool test_checksum_alg(size_t slot_idx, ChecksumAlgorithm alg) const = 0;
    virtual uint32_t get_checksum_val(size_t slot_idx) const = 0;
    virtual void set_checksum_val(size_t slot_idx, uint32_t val) = 0;
    virtual bool test_checksum_val(size_t slot_idx, uint32_t val) const = 0;
    virtual size_t get_max_size(size_t slot_idx) const = 0;
    virtual void set_max_size(size_t slot_idx, size_t size) = 0;
    virtual size_t get_data_size(size_t slot_idx) const = 0;
    virtual void set_data_size(size_t slot_idx, size_t size) = 0;
    virtual size_t get_transformed_size(size_t slot_idx) const = 0;
    virtual void set_transformed_size(size_t slot_idx, size_t size) = 0;

protected:
    template <typename... Args>
    void log_message(LogLevel level, std::format_string<Args...> fmt, Args&&... args) {
        if (get_logging_enabled()) {
            do_log(level, std::format(fmt, std::forward<Args>(args)...));
        }
    }

    /// @brief Internal logging dispatch. Called by log_message template when logging is enabled.
    virtual void do_log(LogLevel level, const std::string& message) = 0;
};

} // namespace swtr
