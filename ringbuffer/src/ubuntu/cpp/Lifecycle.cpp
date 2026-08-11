#include "ringbuffer.hpp"
#include <stdexcept>
#include <memory>
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

SwtrRingBuffer::SwtrRingBuffer(size_t num_slots, 
                               BufferStatus initial_status, 
                               size_t buffer_size, 
                               ErrorHandler err_handler, 
                               std::function<void(std::vector<uint8_t>&, size_t&)> transform_fn)
    : read_fd_(-1), 
      write_fd_(-1), 
      logging_enabled_(false), 
      read_logging_enabled_(false), 
      transform_logging_enabled_(false), 
      write_logging_enabled_(false), 
      read_verbosity_(LogLevel::Info), 
      transform_verbosity_(LogLevel::Info), 
      write_verbosity_(LogLevel::Info), 
      output_stream_(&std::cerr), 
      transform_fn_(transform_fn), 
      err_handler_(err_handler) 
{
    if (num_slots < MIN_NUMBER_SLOTS) {
        throw std::invalid_argument("Number of slots must be at least MIN_NUMBER_SLOTS");
    }
    if (buffer_size < MIN_BUFFER_SIZE) {
        throw std::invalid_argument("Buffer size must be at least MIN_BUFFER_SIZE");
    }

    slots_.reserve(num_slots);
    for (size_t i = 0; i < num_slots; ++i) {
        auto slot = std::make_unique<BufferSlot>(i, buffer_size);
        slot->status.store(initial_status);
        slots_.push_back(std::move(slot));
    }
}

} // namespace swtr
