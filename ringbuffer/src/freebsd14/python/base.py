"""Ring Buffer Abstract Base Class.

This module defines the RingBuffer abstract interface that both
Concurrent (ctypes) and Pure Python implementations must satisfy.

All methods in this ABC are abstract — every concrete implementation
must provide full, working implementations with real behavior.
"""

import io
from abc import ABC, abstractmethod
from enum import Enum
from typing import Callable, List, Optional


# === Type Aliases ===

TransformFn = Callable[[bytearray, List[int]], None]
ErrorHandler = Callable[[int, "BufferStatus"], int]


# === Enum Definitions (shared across implementations) ===

class BufferStatus(int, Enum):
    """Slot status in the three-stage pipeline."""
    READYFORREAD = 0
    READYFORTRANSFORM = 1
    READYFORWRITE = 2
    PROCESSING_READ = 3
    PROCESSING_TRANSFORM = 4
    PROCESSING_WRITE = 5
    EMPTY = 6
    FULL = 7
    LAST_BUFFER_TO_TRANSFORM = 8
    LAST_BUFFER_TO_WRITE = 9
    PENDING_READ = 10
    PENDING_TRANSFORM = 11
    PENDING_WRITE = 12
    STATUS_ERROR = 13

    def __str__(self):
        return self.name


class ChecksumAlgorithm(int, Enum):
    """Checksum algorithm selection."""
    NONE = 0
    MD5 = 1
    SHA256 = 2
    SHA512 = 3

    def __str__(self):
        return self.name


class LogLevel(int, Enum):
    """Logging verbosity levels."""
    TRACE = 0
    DEBUG = 1
    INFO = 2
    WARNING = 3
    ERROR = 4
    CRITICAL = 5

    def __str__(self):
        return self.name


# === RingBuffer Abstract Base Class ===

class RingBuffer(ABC):
    """Abstract ring buffer interface — three-stage pipeline.

    All methods in this ABC are abstract and must be fully implemented
    by every concrete subclass. No no-ops, no stubs — real behavior required.

    Pipeline stages:
      1. Read: reads from input FD into buffer slots, marks READYFORTRANSFORM
      2. Transform: applies transform function in-place, marks READYFORWRITE
      3. Write: writes transformed data to output FD, marks READYFORREAD

    Status transitions:
      readyforread -> processing_read -> readyfortransform -> processing_transform
                   -> readyforwrite -> processing_write -> readyforread
      LAST_BUFFER_TO_TRANSFORM -> LAST_BUFFER_TO_WRITE (EOF propagation)
    """

    @abstractmethod
    def start(self) -> None:
        """Start the three-stage pipeline threads."""

    @abstractmethod
    def stop(self) -> None:
        """Stop the pipeline and wait for threads to terminate."""

    @abstractmethod
    def wait(self) -> None:
        """Wait for all pipeline threads to complete (non-blocking)."""

    @abstractmethod
    def set_read_fd(self, fd: int) -> None:
        """Set the file descriptor for read input."""

    @abstractmethod
    def get_read_fd(self) -> int:
        """Get the file descriptor for read input."""

    @abstractmethod
    def set_write_fd(self, fd: int) -> None:
        """Set the file descriptor for write output."""

    @abstractmethod
    def get_write_fd(self) -> int:
        """Get the file descriptor for write output."""

    # === Logging configuration ===

    @abstractmethod
    def set_logging_enabled(self, enabled: bool) -> None:
        """Enable or disable all logging."""

    @abstractmethod
    def get_logging_enabled(self) -> bool:
        """Check if logging is enabled."""

    @abstractmethod
    def set_output_stream(self, stream: io.IOBase) -> None:
        """Set the output stream for log messages."""

    @abstractmethod
    def get_output_stream(self) -> io.IOBase:
        """Get the output stream for log messages."""

    @abstractmethod
    def set_read_logging_enabled(self, enabled: bool) -> None:
        """Enable or disable read stage logging."""

    @abstractmethod
    def get_read_logging_enabled(self) -> bool:
        """Check if read stage logging is enabled."""

    @abstractmethod
    def set_read_verbosity(self, level: LogLevel) -> None:
        """Set the verbosity level for read stage logging."""

    @abstractmethod
    def get_read_verbosity(self) -> LogLevel:
        """Get the verbosity level for read stage logging."""

    @abstractmethod
    def set_transform_logging_enabled(self, enabled: bool) -> None:
        """Enable or disable transform stage logging."""

    @abstractmethod
    def get_transform_logging_enabled(self) -> bool:
        """Check if transform stage logging is enabled."""

    @abstractmethod
    def set_transform_verbosity(self, level: LogLevel) -> None:
        """Set the verbosity level for transform stage logging."""

    @abstractmethod
    def get_transform_verbosity(self) -> LogLevel:
        """Get the verbosity level for transform stage logging."""

    @abstractmethod
    def set_write_logging_enabled(self, enabled: bool) -> None:
        """Enable or disable write stage logging."""

    @abstractmethod
    def get_write_logging_enabled(self) -> bool:
        """Check if write stage logging is enabled."""

    @abstractmethod
    def set_write_verbosity(self, level: LogLevel) -> None:
        """Set the verbosity level for write stage logging."""

    @abstractmethod
    def get_write_verbosity(self) -> LogLevel:
        """Get the verbosity level for write stage logging."""

    # === Slot accessors (all require slot_idx parameter) ===

    @abstractmethod
    def get_status(self, slot_idx: int) -> BufferStatus:
        """Get the status of a specific buffer slot."""

    @abstractmethod
    def set_status(self, slot_idx: int, status: BufferStatus) -> None:
        """Set the status of a specific buffer slot."""

    @abstractmethod
    def test_status(self, slot_idx: int, status: BufferStatus) -> bool:
        """Test if a specific buffer slot has the given status."""

    @abstractmethod
    def get_checksum_alg(self, slot_idx: int) -> ChecksumAlgorithm:
        """Get the checksum algorithm for a specific buffer slot."""

    @abstractmethod
    def set_checksum_alg(self, slot_idx: int, alg: ChecksumAlgorithm) -> None:
        """Set the checksum algorithm for a specific buffer slot."""

    @abstractmethod
    def test_checksum_alg(self, slot_idx: int, alg: ChecksumAlgorithm) -> bool:
        """Test if a specific buffer slot uses the given checksum algorithm."""

    @abstractmethod
    def get_checksum_val(self, slot_idx: int) -> int:
        """Get the checksum value for a specific buffer slot."""

    @abstractmethod
    def set_checksum_val(self, slot_idx: int, val: int) -> None:
        """Set the checksum value for a specific buffer slot."""

    @abstractmethod
    def test_checksum_val(self, slot_idx: int, val: int) -> bool:
        """Test if a specific buffer slot has the given checksum value."""

    @abstractmethod
    def get_max_size(self, slot_idx: int) -> int:
        """Get the maximum data size for a specific buffer slot."""

    @abstractmethod
    def set_max_size(self, slot_idx: int, size: int) -> None:
        """Set the maximum data size for a specific buffer slot."""

    @abstractmethod
    def get_data_size(self, slot_idx: int) -> int:
        """Get the current data size for a specific buffer slot."""

    @abstractmethod
    def set_data_size(self, slot_idx: int, size: int) -> None:
        """Set the current data size for a specific buffer slot."""

    @abstractmethod
    def get_transformed_size(self, slot_idx: int) -> int:
        """Get the transformed data size for a specific buffer slot."""

    @abstractmethod
    def set_transformed_size(self, slot_idx: int, size: int) -> None:
        """Set the transformed data size for a specific buffer slot."""
