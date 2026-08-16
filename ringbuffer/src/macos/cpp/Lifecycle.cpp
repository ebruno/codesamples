#include "ringbuffer.hpp"
#include <memory>
#include <stdexcept>
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

SwtrRingBuffer::SwtrRingBuffer(size_t num_slots,
                               BufferStatus initial_status,
                               size_t buffer_size,
                               ErrorHandler err_handler,
                               TransformFn transform_fn)
    : slots_(),
      num_slots_(num_slots),
      read_index_(0),
      write_index_(0),
      read_fd_(-1),
      write_fd_(-1),
      buffer_size_(buffer_size),
      err_handler_(err_handler),
      transform_fn_(transform_fn),
      logging_enabled_(false),
      read_logging_enabled_(false),
      transform_logging_enabled_(false),
      write_logging_enabled_(false),
      read_verbosity_(LogLevel::Info),
      transform_verbosity_(LogLevel::Info),
      write_verbosity_(LogLevel::Info),
      output_stream_(&std::cerr)
{
    if (num_slots < MIN_NUMBER_SLOTS) {
        throw std::invalid_argument("Number of slots must be at least MIN_NUMBER_SLOTS");
    }
    if (buffer_size < 1) {
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
