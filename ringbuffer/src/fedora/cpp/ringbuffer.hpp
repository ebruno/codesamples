#ifndef RINGBUFFER_HPP
#define RINGBUFFER_HPP

#include <atomic>
#include <cstdint>
#include <format>
#include <functional>
#include <iostream>
#include <mutex>
#include <string>
#include <vector>
#include "status.hpp"

namespace swtr {

enum class LogLevel {
    Trace,
    Debug,
    Info,
    Warning,
    Error,
    Critical
};

struct alignas(64) BufferSlot {
    size_t buffer_idx;
    std::atomic<BufferStatus> status;
    std::atomic<size_t> max_data_buffer_size;
    std::atomic<size_t> data_buffer_size;
    std::atomic<size_t> transformed_data_buffer_size;
    std::atomic<ChecksumAlgorithm> checksum_alg;
    std::atomic<uint32_t> checksum_val;
    std::vector<uint8_t> data;
};

class RingBuffer {
public:
    virtual ~RingBuffer() = default;

    // Thread Control
    virtual void start() = 0;
    virtual void stop() = 0;
    virtual void wait() = 0;

    // Configuration
    virtual void set_read_fd(int fd) = 0;
    virtual void set_write_fd(int fd) = 0;

    // Logging
    virtual void set_logging_enabled(bool enabled) = 0;
    virtual bool get_logging_enabled() const = 0;
    virtual void set_output_stream(std::ostream& stream) = 0;
    virtual std::ostream* get_output_stream() const = 0;

    template<typename... Args>
    void log_message(LogLevel level, std::format_string<Args...> fmt, Args&&... args) {
        std::string msg = std::format(fmt, std::forward<Args>(args)...);
        do_log(level, msg);
    }

    // Stage Logging
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
    virtual void do_log(LogLevel level, const std::string& message) = 0;
};

} // namespace swtr

#endif // RINGBUFFER_HPP
