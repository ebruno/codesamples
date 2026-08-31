// Advanced C++ example — per-stage logging, checksumming, custom error handler
#include <cstdio>
#include <vector>
#include "ringbuffer.hpp"
#include "swtr_ringbuffer_impl.hpp"

using namespace swtr;

// Custom error handler (plain C function pointer)
int my_error_handler(size_t slot_idx, BufferStatus status) {
    std::cerr << "Error in slot " << slot_idx << ": "
              << static_cast<int>(status) << std::endl;
    return 0; // 0 = continue, non-zero = stop pipeline
}

int main() {
    // Transform: XOR each byte with 0xFF
    auto transform = [](std::vector<uint8_t>& data, size_t& size) {
        for (size_t i = 0; i < size; ++i)
            data[i] ^= 0xFF;
    };

    // Create ring buffer with custom error handler
    auto rb = std::make_unique<SwtrRingBuffer>(
        4, BufferStatus::readyforread, 4096, my_error_handler, transform);

    // Configure I/O
    rb->set_read_fd(STDIN_FILENO);
    rb->set_write_fd(STDOUT_FILENO);

    // Enable logging for diagnostics
    rb->set_logging_enabled(true);
    rb->set_output_stream(std::cerr);

    // Per-stage logging configuration (independent verbosity per stage)
    rb->set_read_logging_enabled(true);
    rb->set_read_verbosity(LogLevel::Debug);
    rb->set_transform_logging_enabled(true);
    rb->set_transform_verbosity(LogLevel::Info);
    rb->set_write_logging_enabled(true);
    rb->set_write_verbosity(LogLevel::Info);

    // Checksum algorithm per slot (NONE, MD5, SHA256, SHA512)
    rb->set_checksum_alg(0, ChecksumAlgorithm::SHA256);
    rb->set_checksum_alg(1, ChecksumAlgorithm::SHA256);
    rb->set_checksum_alg(2, ChecksumAlgorithm::SHA256);
    rb->set_checksum_alg(3, ChecksumAlgorithm::SHA256);

    // Run the pipeline
    rb->start();
    rb->wait();
    rb->stop();

    // Inspect final slot states (for debugging/monitoring)
    for (size_t i = 0; i < 4; ++i) {
        std::cerr << "Slot " << i << ": status="
                  << static_cast<int>(rb->get_status(i))
                  << ", checksum=" << rb->get_checksum_val(i)
                  << ", data_size=" << rb->get_data_size(i) << std::endl;
    }

    return 0;
}
