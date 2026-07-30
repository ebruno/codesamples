/**
 * @file swtr_ringbuffer_impl.hpp
 * @brief Concrete implementation of the swtr::RingBuffer.
 */

#ifndef SWTR_RINGBUFFER_IMPL_HPP
#define SWTR_RINGBUFFER_IMPL_HPP

#include "ringbuffer.hpp"

namespace swtr {

/**
 * @class RingBufferImpl
 * @brief Concrete implementation of the RingBuffer that handles the actual logging.
 */
class RingBufferImpl : public RingBuffer {
public:
    RingBufferImpl(size_t num_slots = MIN_NUMBER_SLOTS, BufferStatus initial_status = BufferStatus::READY_FOR_READ, size_t buffer_size = DEFAULT_BUFFER_SIZE);

protected:
    /**
     * @brief Implementation of the logging mechanism.
     */
    void do_log(LogLevel level, const std::string& message) override;
};

} // namespace swtr

#endif // SWTR_RINGBUFFER_IMPL_HPP
