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
    RingBufferImpl(size_t num_slots, BufferStatus initial_status = BufferStatus::READ_FOR_READ, size_t buffer_size = 4096);

protected:
    /**
     * @brief Implementation of the logging mechanism.
     */
    void do_log(LogLevel level, const std::string& message) override;
};

} // namespace swtr

#endif // SWTR_RINGBUFFER_IMPL_HPP
