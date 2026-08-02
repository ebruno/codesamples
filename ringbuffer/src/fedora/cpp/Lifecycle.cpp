#include "ringbuffer.hpp"
#include <memory>
#include <stdexcept>
#include <vector>
#include "status.hpp"
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

    slots_.reserve(num_slots_);
    for (size_t i = 0; i < num_slots_; ++i) {
        auto slot = std::make_unique<BufferSlot>();
        slot->buffer_idx = i;
        slot->status.store(initial_status);
        slot->max_data_buffer_size.store(buffer_size);
        slot->data_buffer_size.store(0);
        slot->transformed_data_buffer_size.store(0);
        slot->checksum_alg.store(ChecksumAlgorithm::NONE);
        slot->checksum_val.store(0);
        slot->data.assign(buffer_size, 0);
        slots_.push_back(std::move(slot));
    }
}

SwtrRingBuffer::~SwtrRingBuffer() {
    stop();
}

} // namespace swtr
