"""Ringbuffer package — pure Python implementation.

A high-performance, cross-platform circular buffer library implementing a
three-stage pipelined architecture (Read → Transform → Write) with lock-free
atomic coordination.

Usage:
    from ringbuffer import SwtrRingBuffer, BufferStatus, ChecksumAlgorithm

    rb = SwtrRingBuffer(num_slots=4)
    rb.set_read_fd(0)   # stdin
    rb.set_write_fd(1)  # stdout
    rb.start()
    rb.wait()           # blocks until all data flows through pipeline
    rb.stop()
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
