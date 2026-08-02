#ifndef STATUS_HPP
#define STATUS_HPP

#include <cstdint>

namespace swtr {

enum class BufferStatus : uint8_t {
    readyforread = 0,
    readyfortransform = 1,
    readyforwrite = 2,
    LAST_BUFFER_TO_TRANSFORM,
    LAST_BUFFER_TO_WRITE,
    STATUS_3,
    STATUS_4,
    STATUS_5,
    STATUS_6,
    STATUS_7,
    STATUS_8,
    STATUS_9,
    STATUS_10,
    STATUS_ERROR = 13
};

enum class ChecksumAlgorithm : uint8_t {
    NONE,
    MD5,
    SHA256,
    SHA512
};

} // namespace swtr

#endif // STATUS_HPP
