#pragma once
#include <cstdint>

// BufferStatus enum (14 values, explicit int backing type for ABI stability)
enum class BufferStatus : int {
    readyforread = 0,       ///< Slot is empty and ready to accept new data from read thread
    readyfortransform = 1,  ///< Data filled; awaiting transform thread to process
    readyforwrite = 2,      ///< Transformed data ready; awaiting write thread to flush
    processing_read = 3,    ///< Read thread is actively writing data into this slot
    processing_transform = 4, ///< Transform thread is actively processing this slot
    processing_write = 5,   ///< Write thread is actively flushing data to output fd
    empty = 6,              ///< Slot has been cleared and is logically empty
    full = 7,               ///< Slot contains data but not yet marked for next stage
    LAST_BUFFER_TO_TRANSFORM = 8, ///< EOF sentinel: last buffer to be transformed
    LAST_BUFFER_TO_WRITE = 9,     ///< EOF sentinel: last buffer to be written
    pending_read = 10,      ///< Read thread is waiting for available slots
    pending_transform = 11, ///< Transform thread is waiting for work
    pending_write = 12,     ///< Write thread is waiting for transformed data
    STATUS_ERROR = 13       ///< An error occurred in this slot's pipeline stage
};

// ChecksumAlgorithm enum (4 values)
enum class ChecksumAlgorithm : int {
    NONE = 0,   ///< No checksum computation
    MD5 = 1,    ///< MD5 hash (128-bit)
    SHA256 = 2, ///< SHA-256 hash (256-bit)
    SHA512 = 3  ///< SHA-512 hash (512-bit)
};

// LogLevel enum (6 values)
enum class LogLevel : int {
    Trace = 0,    ///< Verbose internal state transitions
    Debug = 1,    ///< Detailed operational information
    Info = 2,     ///< General pipeline events (default)
    Warning = 3,  ///< Non-fatal conditions that may indicate issues
    Error = 4,    ///< Recoverable error conditions
    Critical = 5  ///< Fatal errors requiring pipeline shutdown
};
