/**
 * @file ringbuffer.hpp
 * @brief Main abstract base class definition for the swtr ringbuffer implementation.
 */

#ifndef SWTR_RINGBUFFER_HPP
#define SWTR_RINGBUFFER_HPP

#include <vector>
#include <atomic>
#include <mutex>
#include <condition_variable>
#include <stop_token>
#include <thread>
#include <functional>
#include <iostream>
#include <string>
#include <unordered_map>
#include <memory>
#include <format>
#include <stdexcept>
#include "status.hpp"

namespace swtr {

struct alignas(64) BufferSlot {
    size_t idx;
    std::atomic<BufferStatus> status;
    size_t max_data_buffer_size;
    size_t data_buffer_size;
    size_t transformed_data_buffer_size;
    ChecksumAlgorithm checksum_alg;
    uint64_t checksum_val;
    std::vector<uint8_t> data;
};

class RingBuffer {
public:
    virtual ~RingBuffer() = default;

    /**
     * @brief Constructs the ringbuffer. 
     * @throws std::invalid_argument if num_slots <= 1 or buffer_size <= 1.
     */
    RingBuffer(size_t num_slots, BufferStatus initial_status = BufferStatus::READ_FOR_READ, size_t buffer_size = 4096);

    void start(int read_fd, int write_fd, 
               std::function<void(std::vector<uint8_t>&, size_t&)> transform_func,
               int (*error_handler)(size_t, BufferStatus));

    void stop();
    void wait();

    void read_op(std::stop_token st, int fd);
    void transform_op(std::stop_token st);
    void write_op(std::stop_token st, int fd);
    void handle_error(size_t slot_idx, BufferStatus status);

    // Accessors
    BufferStatus get_status(size_t idx) const;
    void set_status(size_t idx, BufferStatus status);
    bool test_status(size_t idx, BufferStatus status) const;
    ChecksumAlgorithm get_checksum_alg(size_t idx) const;
    void set_checksum_alg(size_t idx, ChecksumAlgorithm alg);
    bool test_checksum_alg(size_t idx, ChecksumAlgorithm alg) const;
    uint64_t get_checksum_val(size_t idx) const;
    void set_checksum_val(size_t idx, uint64_t val);
    bool test_checksum_val(size_t idx, uint64_t val) const;
    size_t get_max_size(size_t idx) const;
    void set_max_size(size_t idx, size_t size);
    size_t get_data_size(size_t idx) const;
    void set_data_size(size_t idx, size_t size);
    size_t get_transformed_size(size_t idx) const;
    void set_transformed_size(size_t idx, size_t size);

    // Logging NVI
    template <typename... Args>
    void log_message(LogLevel level, const std::string& stage, const std::string& fmt, Args&&... args) {
        if (!m_logging_enabled.load()) return;

        LogLevel effective_verbosity = m_global_verbosity.load();
        if (stage != "GLOBAL") {
            std::lock_guard lock(m_mutex);
            auto it = m_stage_configs.find(stage);
            if (it != m_stage_configs.end()) {
                if (!it->second.enabled) return;
                effective_verbosity = it->second.verbosity;
            }
        }

        if (static_cast<uint8_t>(level) > static_cast<uint8_t>(effective_verbosity)) {
            return;
        }

        std::string msg = std::vformat(fmt, std::make_format_args(args...));
        do_log(level, msg);
    }

    void set_logging_enabled(bool enabled);
    bool is_logging_enabled() const;
    void set_global_verbosity(LogLevel level);
    LogLevel get_global_verbosity() const;
    void set_stage_logging_enabled(const std::string& stage, bool enabled);
    bool is_stage_logging_enabled(const std::string& stage) const;
    void set_stage_verbosity(const std::string& stage, LogLevel level);
    LogLevel get_stage_verbosity(const std::string& stage) const;
    void set_output_stream(std::ostream& os);
    std::ostream& get_output_stream() const;

protected:
    virtual void do_log(LogLevel level, const std::string& message) = 0;

    alignas(64) size_t m_num_slots;
    std::vector<BufferSlot> m_slots;
    alignas(64) std::atomic<size_t> m_read_idx{0};
    alignas(64) std::atomic<size_t> m_transform_idx{0};
    alignas(64) std::atomic<size_t> m_write_idx{0};
    mutable std::mutex m_mutex;
    std::condition_variable m_cv;
    std::stop_source m_stop_source;
    std::jthread m_read_thread;
    std::jthread m_transform_thread;
    std::jthread m_write_thread;
    std::function<void(std::vector<uint8_t>&, size_t&)> m_transform_func;
    int (*m_error_handler)(size_t, BufferStatus) = nullptr;
    std::atomic<bool> m_logging_enabled{true};
    std::atomic<LogLevel> m_global_verbosity{LogLevel::Info};
    std::ostream* m_log_stream = &std::cerr;
    struct StageConfig { bool enabled = true; LogLevel verbosity = LogLevel::Info; };
    std::unordered_map<std::string, StageConfig> m_stage_configs;
};

} // namespace swtr

#endif // SWTR_RINGBUFFER_HPP
