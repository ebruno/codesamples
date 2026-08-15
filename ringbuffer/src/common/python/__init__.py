"""Ringbuffer package — pure Python implementation.

Exports the public API for the three-stage pipeline ring buffer.
"""

from swtr_ringbuffer import (
    # Enums
    BufferStatus,
    ChecksumAlgorithm,
    LogLevel,

    # Type aliases
    TransformFn,
    ErrorHandler,

    # Classes
    BufferSlot,
    RingBuffer,
    SwtrRingBuffer,

    # Constants
    MIN_NUMBER_SLOTS,
    DEFAULT_BUFFER_SIZE,
    MIN_BUFFER_SIZE,

    # Shared library loading
    load_ringbuffer_library,
)

__all__ = [
    "BufferStatus",
    "ChecksumAlgorithm",
    "LogLevel",
    "TransformFn",
    "ErrorHandler",
    "BufferSlot",
    "RingBuffer",
    "SwtrRingBuffer",
    "MIN_NUMBER_SLOTS",
    "DEFAULT_BUFFER_SIZE",
    "MIN_BUFFER_SIZE",
    "load_ringbuffer_library",
]
