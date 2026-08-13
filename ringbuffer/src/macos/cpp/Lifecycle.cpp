#include "ringbuffer.hpp"
#include "swtr_ringbuffer_impl.hpp"
#include <stdexcept>

namespace swtr {

SwtrRingBuffer::SwtrRingBuffer(size_t num_slots,
                               BufferStatus initial_status,
                               size_t buffer_size,
                               ErrorHandler err_handler,
                               TransformFn transform_fn)
    : num_slots_(num_slots), buffer_size_(buffer_size), err_handler_(err_handler), transform_fn_(transform_fn) {

    if (num_slots_ < MIN_NUMBER_SLOTS) {
        throw std::invalid_argument("Number of slots must be at least 1");
    }
    if (buffer_size_ < MIN_BUFFER_SIZE) {
        throw std::invalid_argument("Buffer size must be at least 1");
    }

    slots_.reserve(num_slots_);
    for (size_t i = 0; i < num_slots_; ++i) {
        auto slot = std::make_unique<BufferSlot>();
        slot->buffer_idx = i;
        slot->status.store(initial_status);
        slot->max_data_buffer_size = buffer_size_;
        slot->data_buffer_size.store(0);
        slot->transformed_data_buffer_size.store(0);
        slot->checksum_alg.store(ChecksumAlgorithm::NONE);
        slot->checksum_val.store(0);
        slot->data.resize(buffer_size_);
        slots_.push_back(std::move(slot));
    }
}

} // namespace swtr
