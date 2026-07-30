/**
 * @file status.hpp
 * @brief Defines status and checksum enumerations for the swtr ringbuffer.
 */

#ifndef SWTR_STATUS_HPP
#define SWTR_STATUS_HPP

#include <cstdint>
#include <string_view>

namespace swtr {

enum class BufferStatus : uint8_t {
    READY_FOR_READ = 0,
    READY_FOR_TRANSFORM = 1,
    READY_FOR_WRITE = 2,
    PROCESSING_READ = 3,
    PROCESSING_TRANSFORM = 4,
    PROCESSING_WRITE = 5,
    ERROR = 6,
    EMPTY = 7,
    FULL = 8,
    INITIALIZING = 9,
    CLEANING = 10,
    RESERVED = 11,
    LAST_BUFFER_TO_TRANSFORM = 12,
    LAST_BUFFER_TO_WRITE = 13
};

inline constexpr BufferStatus readytoread = BufferStatus::READY_FOR_READ;
inline constexpr BufferStatus readyfortransform = BufferStatus::READY_FOR_TRANSFORM;
inline constexpr BufferStatus readyforwrite = BufferStatus::READY_FOR_WRITE;

enum class ChecksumAlgorithm : uint8_t {
    NONE = 0,
    MD5 = 1,
    SHA256 = 2,
    SHA512 = 3
};

enum class LogLevel : uint8_t {
    Trace = 0, Debug = 1, Info = 2, Warning = 3, Error = 4, Critical = 5
};

inline constexpr std::string_view log_level_to_string(LogLevel level) {
    switch (level) {
        case LogLevel::Trace:    return "TRACE";
        case LogLevel::Debug:    return "DEBUG";
        case LogLevel::Info:     return "INFO";
        case LogLevel::Warning:  return "WARNING";
        case LogLevel::Error:    return "ERROR";
        case LogLevel::Critical: return "CRITICAL";
        default:                 return "UNKNOWN";
    }
}

} // namespace swtr

#endif // SWTR_STATUS_HPP
