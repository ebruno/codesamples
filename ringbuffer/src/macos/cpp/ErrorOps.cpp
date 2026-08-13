#include "ringbuffer.hpp"
#include "swtr_ringbuffer_impl.hpp"

namespace swtr {

int default_error_handler(size_t slot_idx, BufferStatus status) {
    // Default error handler: log the error and request stop
    (void)slot_idx;
    (void)status;
    return 1; // non-zero triggers cooperative cancellation
}

} // namespace swtr
