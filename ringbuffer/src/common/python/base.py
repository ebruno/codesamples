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
"""Transform function signature — modifies data in-place.

Called by the transform stage on each slot's buffer. The `size` list is used
as a mutable container to communicate the new data size back to the pipeline.

Args:
    data: The slot's byte buffer, modified in-place by the transform.
    size: A single-element list containing the current data length;
          update this to signal a changed buffer size.
"""

ErrorHandler = Callable[[int, "BufferStatus"], int]
"""Error handler callback signature.

Called when an error occurs in a pipeline stage. Return non-zero to trigger
cooperative cancellation (pipeline shutdown).

Args:
    stage: The pipeline stage where the error occurred (1=read, 2=transform,
           3=write).
    status: The current BufferStatus of the slot when the error occurred.

Returns:
    Non-zero to stop the pipeline, zero to continue processing.
"""


# === Enum Definitions (shared across implementations) ===

class BufferStatus(int, Enum):
    """Slot status in the three-stage pipeline.

    Each value represents a state in the slot lifecycle as data flows
    through the read → transform → write pipeline.
    """
    READYFORREAD = 0
    """Slot is empty and ready to accept new data from read thread"""
    READYFORTRANSFORM = 1
    """Data filled; awaiting transform thread to process"""
    READYFORWRITE = 2
    """Transformed data ready; awaiting write thread to flush"""
    PROCESSING_READ = 3
    """Read thread is actively writing data into this slot"""
    PROCESSING_TRANSFORM = 4
    """Transform thread is actively processing this slot"""
    PROCESSING_WRITE = 5
    """Write thread is actively flushing data to output fd"""
    EMPTY = 6
    """Slot has been cleared and is logically empty"""
    FULL = 7
    """Slot contains data but not yet marked for next stage"""
    LAST_BUFFER_TO_TRANSFORM = 8
    """EOF sentinel: last buffer to be transformed"""
    LAST_BUFFER_TO_WRITE = 9
    """EOF sentinel: last buffer to be written"""
    PENDING_READ = 10
    """Read thread is waiting for available slots"""
    PENDING_TRANSFORM = 11
    """Transform thread is waiting for work"""
    PENDING_WRITE = 12
    """Write thread is waiting for transformed data"""
    STATUS_ERROR = 13
    """An error occurred in this slot's pipeline stage"""

    def __str__(self):
        return self.name


class ChecksumAlgorithm(int, Enum):
    """Checksum algorithm selection for per-slot integrity verification."""
    NONE = 0
    """No checksum computation"""
    MD5 = 1
    """MD5 hash (128-bit) — fast but not cryptographically secure"""
    SHA256 = 2
    """SHA-256 hash (256-bit) — good balance of speed and security"""
    SHA512 = 3
    """SHA-512 hash (512-bit) — strongest available option"""

    def __str__(self):
        return self.name


class LogLevel(int, Enum):
    """Logging verbosity levels for pipeline diagnostics.

    Each level controls the detail of log output per stage (read/transform/write).
    Higher levels include all messages from lower levels.
    """
    TRACE = 0
    """Verbose internal state transitions and slot operations"""
    DEBUG = 1
    """Detailed operational information for debugging"""
    INFO = 2
    """General pipeline events (default level)"""
    WARNING = 3
    """Non-fatal conditions that may indicate issues"""
    ERROR = 4
    """Recoverable error conditions in pipeline stages"""
    CRITICAL = 5
    """Fatal errors requiring pipeline shutdown"""

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
        """Start the three-stage pipeline threads (read, transform, write).

        Launches independent threads for each stage. The pipeline begins
        processing data immediately after this call.
        """

    @abstractmethod
    def stop(self) -> None:
        """Stop the pipeline and wait for threads to terminate.

        Signals all stages to stop processing, flushes any remaining data,
        and joins threads cleanly. Safe to call multiple times.
        """

    @abstractmethod
    def wait(self) -> None:
        """Wait for all pipeline threads to complete (non-blocking).

        Blocks until the read thread has consumed all input, the transform
        stage has processed all data, and the write thread has flushed everything.
        Returns only when the entire pipeline has finished processing.
        """

    @abstractmethod
    def set_read_fd(self, fd: int) -> None:
        """Set the file descriptor for read input.

        The read thread will read data from this fd into buffer slots.
        On EOF, the last slot is marked with LAST_BUFFER_TO_TRANSFORM
        to propagate end-of-stream through all pipeline stages.
        """

    @abstractmethod
    def get_read_fd(self) -> int:
        """Get the file descriptor for read input.

        Returns -1 if no fd has been set.
        """

    @abstractmethod
    def set_write_fd(self, fd: int) -> None:
        """Set the file descriptor for write output.

        The write thread will flush transformed data to this fd.
        On the last buffer, fsync is called before signaling completion.
        """

    @abstractmethod
    def get_write_fd(self) -> int:
        """Get the file descriptor for write output.

        Returns -1 if no fd has been set.
        """

    # === Logging configuration ===

    @abstractmethod
    def set_logging_enabled(self, enabled: bool) -> None:
        """Enable or disable all logging across all pipeline stages.

        When disabled, no log output is produced regardless of verbosity settings.
        """

    @abstractmethod
    def get_logging_enabled(self) -> bool:
        """Check if logging is globally enabled.

        Returns True if any stage can produce log output, False otherwise.
        """

    @abstractmethod
    def set_output_stream(self, stream: io.IOBase) -> None:
        """Set the output stream for log messages.

        All stage logs are written to this stream. Defaults to sys.stderr.
        """

    @abstractmethod
    def get_output_stream(self) -> io.IOBase:
        """Get the current output stream for log messages."""

    @abstractmethod
    def set_read_logging_enabled(self, enabled: bool) -> None:
        """Enable or disable logging for the read stage only.

        Overrides global logging setting when explicitly configured.
        """

    @abstractmethod
    def get_read_logging_enabled(self) -> bool:
        """Check if read stage logging is enabled."""

    @abstractmethod
    def set_read_verbosity(self, level: LogLevel) -> None:
        """Set the verbosity level for read stage logging.

        Controls detail of log output from the read thread only.
        """

    @abstractmethod
    def get_read_verbosity(self) -> LogLevel:
        """Get the verbosity level for read stage logging."""

    @abstractmethod
    def set_transform_logging_enabled(self, enabled: bool) -> None:
        """Enable or disable logging for the transform stage only.

        Overrides global logging setting when explicitly configured.
        """

    @abstractmethod
    def get_transform_logging_enabled(self) -> bool:
        """Check if transform stage logging is enabled."""

    @abstractmethod
    def set_transform_verbosity(self, level: LogLevel) -> None:
        """Set the verbosity level for transform stage logging.

        Controls detail of log output from the transform thread only.
        """

    @abstractmethod
    def get_transform_verbosity(self) -> LogLevel:
        """Get the verbosity level for transform stage logging."""

    @abstractmethod
    def set_write_logging_enabled(self, enabled: bool) -> None:
        """Enable or disable logging for the write stage only.

        Overrides global logging setting when explicitly configured.
        """

    @abstractmethod
    def get_write_logging_enabled(self) -> bool:
        """Check if write stage logging is enabled."""

    @abstractmethod
    def set_write_verbosity(self, level: LogLevel) -> None:
        """Set the verbosity level for write stage logging.

        Controls detail of log output from the write thread only.
        """

    @abstractmethod
    def get_write_verbosity(self) -> LogLevel:
        """Get the verbosity level for write stage logging."""

    # === Slot accessors (all require slot_idx parameter) ===

    @abstractmethod
    def get_status(self, slot_idx: int) -> BufferStatus:
        """Get the status of a specific buffer slot.

        Returns the current state of the slot in the pipeline lifecycle.
        """

    @abstractmethod
    def set_status(self, slot_idx: int, status: BufferStatus) -> None:
        """Set the status of a specific buffer slot.

        Directly sets the slot state. Prefer using pipeline methods that
        manage status transitions automatically.
        """

    @abstractmethod
    def test_status(self, slot_idx: int, status: BufferStatus) -> bool:
        """Test if a specific buffer slot has the given status.

        Returns True if slot_idx's current status matches the given value.
        """

    @abstractmethod
    def get_checksum_alg(self, slot_idx: int) -> ChecksumAlgorithm:
        """Get the checksum algorithm configured for a specific buffer slot.

        Returns NONE if no checksum is enabled for this slot.
        """

    @abstractmethod
    def set_checksum_alg(self, slot_idx: int, alg: ChecksumAlgorithm) -> None:
        """Set the checksum algorithm for a specific buffer slot.

        The transform stage will compute this checksum when processing the slot.
        """

    @abstractmethod
    def test_checksum_alg(self, slot_idx: int, alg: ChecksumAlgorithm) -> bool:
        """Test if a specific buffer slot uses the given checksum algorithm."""

    @abstractmethod
    def get_checksum_val(self, slot_idx: int) -> int:
        """Get the computed checksum value for a specific buffer slot.

        Returns 0 if no checksum has been computed yet (e.g., before transform).
        """

    @abstractmethod
    def set_checksum_val(self, slot_idx: int, val: int) -> None:
        """Set the checksum value for a specific buffer slot.

        Directly sets the checksum. Normally computed automatically by transform stage.
        """

    @abstractmethod
    def test_checksum_val(self, slot_idx: int, val: int) -> bool:
        """Test if a specific buffer slot has the given checksum value."""

    @abstractmethod
    def get_max_size(self, slot_idx: int) -> int:
        """Get the maximum data size for a specific buffer slot.

        Returns the allocated buffer capacity (typically DEFAULT_BUFFER_SIZE).
        """

    @abstractmethod
    def set_max_size(self, slot_idx: int, size: int) -> None:
        """Set the maximum data size for a specific buffer slot.

        Limits how much data can be written to this slot. Must not exceed
        the allocated buffer capacity.
        """

    @abstractmethod
    def get_data_size(self, slot_idx: int) -> int:
        """Get the current data size for a specific buffer slot.

        Returns the number of valid bytes in the slot's data buffer.
        """

    @abstractmethod
    def set_data_size(self, slot_idx: int, size: int) -> None:
        """Set the current data size for a specific buffer slot.

        Called by read stage after filling the slot with input data.
        """

    @abstractmethod
    def get_transformed_size(self, slot_idx: int) -> int:
        """Get the transformed data size for a specific buffer slot.

        Returns the number of valid bytes after transform stage processing.
        May differ from data_size if transform changes buffer size.
        """

    @abstractmethod
    def set_transformed_size(self, slot_idx: int, size: int) -> None:
        """Set the transformed data size for a specific buffer slot.

        Called by transform stage after processing. Indicates how many bytes
        of transformed data are valid in the slot.
        """
