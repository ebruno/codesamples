#ifndef SWTR_RINGBUFFER_IMPL_HPP
#define SWTR_RINGBUFFER_IMPL_HPP

#include <atomic>
#include <condition_variable>
#include <functional>
#include <mutex>
#include <stop_token>
#include <string>
#include <thread>
#include <vector>
#include "ringbuffer.hpp"
#include "status.hpp"

namespace swtr {

struct alignas(64) BufferSlot {
    std::atomic<size_t> buffer_idx;
    std::atomic<BufferStatus> status;
    std::atomic<size_t> max_data_buffer_size;
    std::atomic<size_t> data_buffer_size;
    std::atomic<size_t> transformed_data_buffer_size;
    std::atomic<ChecksumAlgorithm> checksum_alg;
    std::atomic<uint32_t> checksum_val;
    std::vector<uint8_t> data;

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

class __attribute__((visibility("default"))) SwtrRingBuffer : public RingBuffer {
public:
    static constexpr size_t MIN_NUMBER_SLOTS = 1;
    static constexpr size_t MIN_BUFFER_SIZE = 1;
    static constexpr size_t DEFAULT_BUFFER_SIZE = 4096;

    SwtrRingBuffer(size_t num_slots = MIN_NUMBER_SLOTS, 
                  BufferStatus initial_status = BufferStatus::readyforread, 
                  size_t buffer_size = DEFAULT_BUFFER_SIZE, 
                  ErrorHandler err_handler = nullptr, 
                  std::function<void(std::vector<uint8_t>&, size_t&)> transform_fn = nullptr);
    
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
    void read_loop(std::stop_token st);
    void transform_loop(std::stop_token st);
    void write_loop(std::stop_token st);

    // Error Handling
    void handle_error(size_t slot_idx, BufferStatus status);

    // Members
    std::vector<std::unique_ptr<BufferSlot>> slots_;
    
    alignas(64) std::atomic<size_t> read_idx_{0};
    alignas(64) std::atomic<size_t> transform_idx_{0};
    alignas(64) std::atomic<size_t> write_idx_{0};

    std::atomic<int> read_fd_{-1};
    std::atomic<int> write_fd_{-1};

    std::atomic<bool> logging_enabled_{false};
    std::atomic<bool> read_logging_enabled_{false};
    std::atomic<bool> transform_logging_enabled_{false};
    std::atomic<bool> write_logging_enabled_{false};

    std::atomic<LogLevel> read_verbosity_{LogLevel::Info};
    std::atomic<LogLevel> transform_verbosity_{LogLevel::Info};
    std::atomic<LogLevel> write_verbosity_{LogLevel::Info};

    std::ostream* output_stream_{&std::cerr};

    std::function<void(std::vector<uint8_t>&, size_t&)> transform_fn_;
    ErrorHandler err_handler_{nullptr};

    std::mutex sync_mutex_;
    std::condition_variable_any cv_;

    std::jthread read_thread_;
    std::jthread transform_thread_;
    std::jthread write_thread_;
};

} // namespace swtr

#endif // SWTR_RINGBUFFER_IMPL_HPP
