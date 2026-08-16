#pragma once
#include <cstdint>

// BufferStatus enum (14 values, explicit int backing type for ABI stability)
enum class BufferStatus : int {
    readyforread = 0,
    readyfortransform = 1,
    readyforwrite = 2,
    processing_read = 3,
    processing_transform = 4,
    processing_write = 5,
    empty = 6,
    full = 7,
    LAST_BUFFER_TO_TRANSFORM = 8,
    LAST_BUFFER_TO_WRITE = 9,
    pending_read = 10,
    pending_transform = 11,
    pending_write = 12,
    STATUS_ERROR = 13
};

// ChecksumAlgorithm enum (4 values)
enum class ChecksumAlgorithm : int {
    NONE = 0,
    MD5 = 1,
    SHA256 = 2,
    SHA512 = 3
};

// LogLevel enum (6 values)
enum class LogLevel : int {
    Trace = 0,
    Debug = 1,
    Info = 2,
    Warning = 3,
    Error = 4,
    Critical = 5
};
