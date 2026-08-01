#include "ringbuffer.hpp"
#include <stdexcept>
#include <memory>
#include <vector>
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

SwtrRingBuffer::SwtrRingBuffer(size_t num_slots, BufferStatus initial_status, size_t buffer_size, ErrorHandler err_handler, std::function<void(std::vector<uint8_t>&, size_t&)> transform_fn)
    : num_slots_(num_slots), transform_fn_(transform_fn), error_handler_(err_handler) {
    
    if (num_slots < MIN_NUMBER_SLOTS) {
        throw std::invalid_argument("Number of slots must be at least MIN_NUMBER_SLOTS");
    }
    if (buffer_size < MIN_BUFFER_SIZE) {
        throw std::invalid_argument("Buffer size must be at least MIN_BUFFER_SIZE");
    }

    for (size_t i = 0; i < num_slots_; ++i) {
        slots_.push_back(std::make_unique<BufferSlot>(i, buffer_size));
        slots_[i]->status.store(initial_status);
    }
}

SwtrRingBuffer::~SwtrRingBuffer() {
    stop();
}

} // namespace swtr
