#ifndef SWTR_STATUS_HPP
#define SWTR_STATUS_HPP

#include <cstdint>

namespace swtr {

enum class BufferStatus : uint8_t {
    readyforread = 0,
    readyfortransform = 1,
    readyforwrite = 2,
    status_3,
    status_4,
    status_5,
    status_6,
    status_7,
    status_8,
    status_9,
    status_10,
    LAST_BUFFER_TO_TRANSFORM,
    LAST_BUFFER_TO_WRITE,
    STATUS_ERROR = 13
};

enum class ChecksumAlgorithm : uint8_t {
    MD5,
    SHA256,
    SHA512,
    NONE
};

} // namespace swtr

#endif // SWTR_STATUS_HPP
