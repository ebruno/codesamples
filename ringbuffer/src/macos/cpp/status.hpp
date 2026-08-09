#ifndef SWTR_STATUS_HPP
#define SWTR_STATUS_HPP

namespace swtr {

enum class BufferStatus : int {
    readyforread = 0,
    readyfortransform,
    readyforwrite,
    processing_read,
    processing_transform,
    processing_write,
    empty,
    full,
    LAST_BUFFER_TO_TRANSFORM,
    LAST_BUFFER_TO_WRITE,
    pending_read,
    pending_transform,
    pending_write,
    STATUS_ERROR = 13
};

enum class ChecksumAlgorithm : int {
    NONE = 0,
    MD5,
    SHA256,
    SHA512
};

enum class LogLevel : int {
    Trace = 0,
    Debug,
    Info,
    Warning,
    Error,
    Critical
};

} // namespace swtr

#endif // SWTR_STATUS_HPP
