#pragma once

#include <atomic>
#include <cstddef>
#include <format>
#include <functional>
#include <iostream>
#include <string>
#include "status.hpp"

namespace swtr {

using ErrorHandler = int (*)(size_t slot_idx, BufferStatus status);
using TransformFn = std::function<void(std::vector<uint8_t>&, size_t&)>;

constexpr size_t MIN_NUMBER_SLOTS = 1;
constexpr size_t DEFAULT_BUFFER_SIZE = 4096;
constexpr size_t MIN_BUFFER_SIZE = 1;

class RingBuffer {
public:
    virtual ~RingBuffer() = default;

    // NVI Logging
    template<typename... Args>
    void log_message(LogLevel level, std::format_string<Args...> fmt, Args&&... args) {
        if (get_logging_enabled()) {
            do_log(level, std::format(fmt, std::forward<Args>(args)...));
        }
    }

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
