"""Ring buffer implementation — pure Python with ctypes FFI.

Three-stage pipeline (read → transform → write) operating on a shared pool
of buffer slots with status-driven coordination.

This is the canonical implementation — byte-identical across all platforms.
"""

import ctypes
import io
import os
import sys
import threading
from abc import ABC, abstractmethod
from enum import Enum
from typing import Callable, List, Optional


# === Constants ===

MIN_NUMBER_SLOTS = 1
DEFAULT_BUFFER_SIZE = 4096
MIN_BUFFER_SIZE = 1


# === Enum Definitions ===

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


# === Type Aliases ===

TransformFn = Callable[[bytearray, List[int]], None]
ErrorHandler = Callable[[int, BufferStatus], int]


# === BufferSlot ===

class BufferSlot:
    """Ring buffer slot with atomic-equivalent thread-safe access."""

    def __init__(self, buffer_idx: int, max_data_buffer_size: int):
        # Non-atomic fields (set once during construction)
        self.buffer_idx: int = buffer_idx
        self.max_data_buffer_size: int = max_data_buffer_size
        self.data: bytearray = bytearray(max_data_buffer_size)

        # Atomic-equivalent fields (protected by lock)
        self._lock = threading.Lock()
        self.status: BufferStatus = BufferStatus.READYFORREAD
        self.data_buffer_size: int = 0
        self.transformed_data_buffer_size: int = 0
        self.checksum_alg: ChecksumAlgorithm = ChecksumAlgorithm.NONE
        self.checksum_val: int = 0

    # Atomic-equivalent getters (thread-safe via lock)
    def get_status(self) -> BufferStatus:
        with self._lock:
            return self.status

    def set_status(self, status: BufferStatus) -> None:
        with self._lock:
            self.status = status

    def get_data_buffer_size(self) -> int:
        with self._lock:
            return self.data_buffer_size

    def set_data_buffer_size(self, size: int) -> None:
        with self._lock:
            self.data_buffer_size = size

    def get_transformed_data_buffer_size(self) -> int:
        with self._lock:
            return self.transformed_data_buffer_size

    def set_transformed_data_buffer_size(self, size: int) -> None:
        with self._lock:
            self.transformed_data_buffer_size = size

    def get_checksum_alg(self) -> ChecksumAlgorithm:
        with self._lock:
            return self.checksum_alg

    def set_checksum_alg(self, alg: ChecksumAlgorithm) -> None:
        with self._lock:
            self.checksum_alg = alg

    def get_checksum_val(self) -> int:
        with self._lock:
            return self.checksum_val

    def set_checksum_val(self, val: int) -> None:
        with self._lock:
            self.checksum_val = val

    # Non-atomic getters (no lock needed)
    def get_buffer_idx(self) -> int:
        return self.buffer_idx

    def get_max_data_buffer_size(self) -> int:
        return self.max_data_buffer_size

    def test_status(self, status: BufferStatus) -> bool:
        with self._lock:
            return self.status == status

    def test_checksum_alg(self, alg: ChecksumAlgorithm) -> bool:
        with self._lock:
            return self.checksum_alg == alg

    def test_checksum_val(self, val: int) -> bool:
        with self._lock:
            return self.checksum_val == val

    def clear(self) -> None:
        """Clear slot data (used after write)."""
        with self._lock:
            self.data = bytearray(self.max_data_buffer_size)
            self.data_buffer_size = 0
            self.transformed_data_buffer_size = 0


# === RingBuffer Interface ===

class RingBuffer(ABC):
    """Abstract ring buffer interface."""

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
    def set_write_fd(self, fd: int) -> None:
        """Set the file descriptor for write output."""

    # Logging configuration
    @abstractmethod
    def set_logging_enabled(self, enabled: bool) -> None:
        ...

    @abstractmethod
    def get_logging_enabled(self) -> bool:
        ...

    @abstractmethod
    def set_output_stream(self, stream: io.IOBase) -> None:
        ...

    @abstractmethod
    def get_output_stream(self) -> io.IOBase:
        ...

    @abstractmethod
    def set_read_logging_enabled(self, enabled: bool) -> None:
        ...

    @abstractmethod
    def get_read_logging_enabled(self) -> bool:
        ...

    @abstractmethod
    def set_read_verbosity(self, level: LogLevel) -> None:
        ...

    @abstractmethod
    def get_read_verbosity(self) -> LogLevel:
        ...

    @abstractmethod
    def set_transform_logging_enabled(self, enabled: bool) -> None:
        ...

    @abstractmethod
    def get_transform_logging_enabled(self) -> bool:
        ...

    @abstractmethod
    def set_transform_verbosity(self, level: LogLevel) -> None:
        ...

    @abstractmethod
    def get_transform_verbosity(self) -> LogLevel:
        ...

    @abstractmethod
    def set_write_logging_enabled(self, enabled: bool) -> None:
        ...

    @abstractmethod
    def get_write_logging_enabled(self) -> bool:
        ...

    @abstractmethod
    def set_write_verbosity(self, level: LogLevel) -> None:
        ...

    @abstractmethod
    def get_write_verbosity(self) -> LogLevel:
        ...

    # Accessors
    @abstractmethod
    def get_status(self, slot_idx: int) -> BufferStatus:
        ...

    @abstractmethod
    def set_status(self, slot_idx: int, status: BufferStatus) -> None:
        ...

    @abstractmethod
    def test_status(self, slot_idx: int, status: BufferStatus) -> bool:
        ...

    @abstractmethod
    def get_checksum_alg(self, slot_idx: int) -> ChecksumAlgorithm:
        ...

    @abstractmethod
    def set_checksum_alg(self, slot_idx: int, alg: ChecksumAlgorithm) -> None:
        ...

    @abstractmethod
    def test_checksum_alg(self, slot_idx: int, alg: ChecksumAlgorithm) -> bool:
        ...

    @abstractmethod
    def get_checksum_val(self, slot_idx: int) -> int:
        ...

    @abstractmethod
    def set_checksum_val(self, slot_idx: int, val: int) -> None:
        ...

    @abstractmethod
    def test_checksum_val(self, slot_idx: int, val: int) -> bool:
        ...

    @abstractmethod
    def get_max_size(self, slot_idx: int) -> int:
        ...

    @abstractmethod
    def set_max_size(self, slot_idx: int, size: int) -> None:
        ...

    @abstractmethod
    def get_data_size(self, slot_idx: int) -> int:
        ...

    @abstractmethod
    def set_data_size(self, slot_idx: int, size: int) -> None:
        ...

    @abstractmethod
    def get_transformed_size(self, slot_idx: int) -> int:
        ...

    @abstractmethod
    def set_transformed_size(self, slot_idx: int, size: int) -> None:
        ...


# === SwtrRingBuffer Implementation ===

class SwtrRingBuffer(RingBuffer):
    """Concrete ring buffer implementation — three-stage pipeline with status-driven coordination.

    Pipeline stages:
      1. Read: reads from input FD into buffer slots, marks READYFORTRANSFORM
      2. Transform: applies transform function in-place, marks READYFORWRITE
      3. Write: writes transformed data to output FD, marks READYFORREAD

    Status transitions:
      readyforread → processing_read → readyfortransform → processing_transform
                   → readyforwrite → processing_write → readyforread
      LAST_BUFFER_TO_TRANSFORM → LAST_BUFFER_TO_WRITE (EOF propagation)
    """

    def __init__(self, num_slots: int, initial_status: BufferStatus = BufferStatus.READYFORREAD,
                 buffer_size: int = DEFAULT_BUFFER_SIZE,
                 error_handler: Optional[ErrorHandler] = None,
                 transform_fn: Optional[TransformFn] = None):
        if num_slots < MIN_NUMBER_SLOTS:
            raise ValueError(
                f"num_slots must be >= {MIN_NUMBER_SLOTS}, got: {num_slots}")
        if buffer_size < MIN_BUFFER_SIZE:
            raise ValueError(
                f"buffer_size must be >= {MIN_BUFFER_SIZE}, got: {buffer_size}")

        # Slot storage
        self.slots: List[BufferSlot] = [
            BufferSlot(i, buffer_size) for i in range(num_slots)
        ]
        self.num_slots: int = num_slots

        # Index tracking — one independent counter per pipeline stage
        self.read_index: int = 0
        self.transform_index: int = 0
        self.write_index: int = 0

        # File descriptors
        self.read_fd: int = -1
        self.write_fd: int = -1

        # Buffer size per slot
        self.buffer_size: int = buffer_size

        # Pipeline functions (set once at construction)
        self.error_handler: Optional[ErrorHandler] = error_handler
        self.transform_fn: Optional[TransformFn] = transform_fn

        # Thread management
        self.read_thread: Optional[threading.Thread] = None
        self.transform_thread: Optional[threading.Thread] = None
        self.write_thread: Optional[threading.Thread] = None

        # Synchronization primitives
        self.sync_lock: threading.RLock = threading.RLock()
        self.cond_var: threading.Condition = threading.Condition(self.sync_lock)
        self.running: bool = False

        # Logging configuration
        self.logging_enabled: bool = False
        self.read_logging_enabled: bool = False
        self.transform_logging_enabled: bool = False
        self.write_logging_enabled: bool = False
        self.read_verbosity: LogLevel = LogLevel.INFO
        self.transform_verbosity: LogLevel = LogLevel.INFO
        self.write_verbosity: LogLevel = LogLevel.INFO

        # Output stream
        self.output_stream: io.IOBase = sys.stderr

        # Log lock (separate from sync_lock to avoid nested locking)
        self.log_lock: threading.Lock = threading.Lock()

        # Guard against double-start
        self._started: bool = False

    # === Logging ===

    def _log(self, level: LogLevel, message: str) -> None:
        """Thread-safe logging method."""
        if not self.logging_enabled:
            return
        with self.log_lock:
            self.output_stream.write(f"[{level.name}] {message}\n")
            self.output_stream.flush()

    # === Thread Control ===

    def start(self) -> None:
        """Start the three-stage pipeline threads."""
        with self.sync_lock:
            if self._started:
                self._log(LogLevel.WARNING, "Pipeline already started — ignoring duplicate start() call")
                return
            self._started = True
            self.running = True

            # Create and start read thread
            self.read_thread = threading.Thread(target=self._read_loop, name="ringbuffer-read")
            self.read_thread.daemon = True

            # Create and start transform thread
            self.transform_thread = threading.Thread(target=self._transform_loop, name="ringbuffer-transform")
            self.transform_thread.daemon = True

            # Create and start write thread
            self.write_thread = threading.Thread(target=self._write_loop, name="ringbuffer-write")
            self.write_thread.daemon = True

            # Start all threads
            self.read_thread.start()
            self.transform_thread.start()
            self.write_thread.start()

            self._log(LogLevel.INFO, f"Pipeline started: read={self.read_thread.name}, "
                      f"transform={self.transform_thread.name}, write={self.write_thread.name}")

    def stop(self) -> None:
        """Stop the pipeline and wait for threads to terminate."""
        with self.sync_lock:
            self.running = False

            # Set all thread references (for awaitTermination)
            read_thread = self.read_thread
            transform_thread = self.transform_thread
            write_thread = self.write_thread

            # Notify the condition variable to wake any waiting threads
            self.cond_var.notify_all()

        # Wait for threads to finish (outside the lock)
        if read_thread:
            read_thread.join()
        if transform_thread:
            transform_thread.join()
        if write_thread:
            write_thread.join()

        self._log(LogLevel.INFO, "Pipeline stop signal sent")

    def wait(self) -> None:
        """Wait for all pipeline threads to complete (non-blocking)."""
        if self.read_thread:
            self.read_thread.join()
        if self.transform_thread:
            self.transform_thread.join()
        if self.write_thread:
            self.write_thread.join()
        self._log(LogLevel.INFO, "All pipeline threads terminated")

    # === Configuration ===

    def set_read_fd(self, fd: int) -> None:
        self.read_fd = fd

    def set_write_fd(self, fd: int) -> None:
        self.write_fd = fd

    # Logging configuration
    def set_logging_enabled(self, enabled: bool) -> None:
        self.logging_enabled = enabled

    def get_logging_enabled(self) -> bool:
        return self.logging_enabled

    def set_output_stream(self, stream: io.IOBase) -> None:
        self.output_stream = stream

    def get_output_stream(self) -> io.IOBase:
        return self.output_stream

    def set_read_logging_enabled(self, enabled: bool) -> None:
        self.read_logging_enabled = enabled

    def get_read_logging_enabled(self) -> bool:
        return self.read_logging_enabled

    def set_read_verbosity(self, level: LogLevel) -> None:
        self.read_verbosity = level

    def get_read_verbosity(self) -> LogLevel:
        return self.read_verbosity

    def set_transform_logging_enabled(self, enabled: bool) -> None:
        self.transform_logging_enabled = enabled

    def get_transform_logging_enabled(self) -> bool:
        return self.transform_logging_enabled

    def set_transform_verbosity(self, level: LogLevel) -> None:
        self.transform_verbosity = level

    def get_transform_verbosity(self) -> LogLevel:
        return self.transform_verbosity

    def set_write_logging_enabled(self, enabled: bool) -> None:
        self.write_logging_enabled = enabled

    def get_write_logging_enabled(self) -> bool:
        return self.write_logging_enabled

    def set_write_verbosity(self, level: LogLevel) -> None:
        self.write_verbosity = level

    def get_write_verbosity(self) -> LogLevel:
        return self.write_verbosity

    # === Accessors (with bounds checking) ===

    def _validate_slot(self, slot_idx: int):
        """Validate slot index; return True if valid."""
        if slot_idx < 0 or slot_idx >= self.num_slots:
            return False
        return True

    def get_status(self, slot_idx: int) -> BufferStatus:
        if not self._validate_slot(slot_idx):
            return BufferStatus.STATUS_ERROR
        return self.slots[slot_idx].get_status()

    def set_status(self, slot_idx: int, status: BufferStatus) -> None:
        if not self._validate_slot(slot_idx):
            return
        self.slots[slot_idx].set_status(status)

    def test_status(self, slot_idx: int, status: BufferStatus) -> bool:
        if not self._validate_slot(slot_idx):
            return False
        return self.slots[slot_idx].test_status(status)

    def get_checksum_alg(self, slot_idx: int) -> ChecksumAlgorithm:
        if not self._validate_slot(slot_idx):
            return ChecksumAlgorithm.NONE
        return self.slots[slot_idx].get_checksum_alg()

    def set_checksum_alg(self, slot_idx: int, alg: ChecksumAlgorithm) -> None:
        if not self._validate_slot(slot_idx):
            return
        self.slots[slot_idx].set_checksum_alg(alg)

    def test_checksum_alg(self, slot_idx: int, alg: ChecksumAlgorithm) -> bool:
        if not self._validate_slot(slot_idx):
            return False
        return self.slots[slot_idx].test_checksum_alg(alg)

    def get_checksum_val(self, slot_idx: int) -> int:
        if not self._validate_slot(slot_idx):
            return 0
        return self.slots[slot_idx].get_checksum_val()

    def set_checksum_val(self, slot_idx: int, val: int) -> None:
        if not self._validate_slot(slot_idx):
            return
        self.slots[slot_idx].set_checksum_val(val)

    def test_checksum_val(self, slot_idx: int, val: int) -> bool:
        if not self._validate_slot(slot_idx):
            return False
        return self.slots[slot_idx].test_checksum_val(val)

    def get_max_size(self, slot_idx: int) -> int:
        if not self._validate_slot(slot_idx):
            return 0
        return self.slots[slot_idx].get_max_data_buffer_size()

    def set_max_size(self, slot_idx: int, size: int) -> None:
        if not self._validate_slot(slot_idx):
            return

    def get_data_size(self, slot_idx: int) -> int:
        if not self._validate_slot(slot_idx):
            return 0
        return self.slots[slot_idx].get_data_buffer_size()

    def set_data_size(self, slot_idx: int, size: int) -> None:
        if not self._validate_slot(slot_idx):
            return
        self.slots[slot_idx].set_data_buffer_size(size)

    def get_transformed_size(self, slot_idx: int) -> int:
        if not self._validate_slot(slot_idx):
            return 0
        return self.slots[slot_idx].get_transformed_data_buffer_size()

    def set_transformed_size(self, slot_idx: int, size: int) -> None:
        if not self._validate_slot(slot_idx):
            return
        self.slots[slot_idx].set_transformed_data_buffer_size(size)

    # === Pipeline Logic ===

    def _read_loop(self) -> None:
        """Read loop — reads from input FD into buffer slots.

        Status transitions: READYFORREAD → PROCESSING_READ → READYFORTRANSFORM
        EOF handling: sets LAST_BUFFER_TO_TRANSFORM, advances index, notifies all.
        """
        try:
            while self.running:
                # Get next slot index using read_index with modulo wrapping
                slot_idx = self.read_index % self.num_slots
                slot = self.slots[slot_idx]

                # Wait for slot to be ready for read
                with self.sync_lock:
                    while self.running and slot.status != BufferStatus.READYFORREAD:
                        if slot.status == BufferStatus.STATUS_ERROR:
                            self._handle_slot_error(slot_idx, slot)
                            break
                        self.cond_var.wait(timeout=0.1)  # 100ms timeout for periodic running check
                    if not self.running:
                        break

                # Mark slot as processing read
                slot.set_status(BufferStatus.PROCESSING_READ)

                # Read from input FD using os.read
                if self.read_fd < 0:
                    self._log(LogLevel.WARNING, "Read FD not set — skipping read")
                    slot.set_status(BufferStatus.READYFORREAD)
                    continue

                try:
                    buffer = bytearray(self.buffer_size)
                    bytes_read = os.read(self.read_fd, len(buffer))

                    if len(bytes_read) == 0:
                        # EOF detected — propagate LAST_BUFFER_TO_TRANSFORM
                        self._log(LogLevel.INFO, "EOF detected at read stage")
                        slot.set_status(BufferStatus.LAST_BUFFER_TO_TRANSFORM)
                        slot.set_data_buffer_size(0)

                        # Advance read index and notify all waiting threads
                        self.read_index += 1
                        with self.sync_lock:
                            self.cond_var.notify_all()

                        # Break the loop — EOF means end of input
                        break
                    else:
                        # Successfully read data
                        data_len = len(bytes_read)

                        # Copy data into slot (synchronized on slot's data array)
                        with slot._lock:
                            slot.data[:data_len] = bytes_read

                        slot.set_data_buffer_size(data_len)
                        slot.set_status(BufferStatus.READYFORTRANSFORM)

                        # Advance read index and notify all waiting threads
                        self.read_index += 1
                        with self.sync_lock:
                            self.cond_var.notify_all()

                        self._log(LogLevel.TRACE, f"Read {data_len} bytes into slot {slot_idx}")

                except OSError as e:
                    self._log(LogLevel.ERROR, f"Read error: {e}")
                    slot.set_status(BufferStatus.STATUS_ERROR)
                    self._handle_slot_error(slot_idx, slot)

        except KeyboardInterrupt:
            threading.current_thread().interrupt()
            self._log(LogLevel.INFO, "Read thread interrupted")

    def _transform_loop(self) -> None:
        """Transform loop — applies transform function to slot data in-place.

        Status transitions: READYFORTRANSFORM → PROCESSING_TRANSFORM → READYFORWRITE
        EOF handling: receives LAST_BUFFER_TO_TRANSFORM, converts to LAST_BUFFER_TO_WRITE.
        """
        try:
            while self.running:
                # Get next slot index using transform_index with modulo wrapping
                slot_idx = self.transform_index % self.num_slots
                slot = self.slots[slot_idx]

                # Wait for slot to be ready for transform
                with self.sync_lock:
                    while self.running and slot.status not in (BufferStatus.READYFORTRANSFORM,
                                                               BufferStatus.LAST_BUFFER_TO_TRANSFORM):
                        if slot.status == BufferStatus.STATUS_ERROR:
                            self._handle_slot_error(slot_idx, slot)
                            break
                        self.cond_var.wait(timeout=0.1)  # 100ms timeout for periodic running check
                    if not self.running:
                        break

                    status = slot.status
                    if status == BufferStatus.STATUS_ERROR:
                        break

                    # Check for EOF propagation
                    if status == BufferStatus.LAST_BUFFER_TO_TRANSFORM:
                        self._log(LogLevel.INFO, "EOF propagation: LAST_BUFFER_TO_TRANSFORM → LAST_BUFFER_TO_WRITE")
                        slot.set_status(BufferStatus.LAST_BUFFER_TO_WRITE)

                        # Advance transform index and notify all waiting threads
                        self.transform_index += 1
                        with self.sync_lock:
                            self.cond_var.notify_all()

                        # Break the loop — EOF means end of transform pipeline
                        break

                # Mark slot as processing transform
                slot.set_status(BufferStatus.PROCESSING_TRANSFORM)

                # Apply transform function (in-place modification)
                if self.transform_fn is not None:
                    size_holder = [slot.get_data_buffer_size()]

                    try:
                        self.transform_fn(slot.data, size_holder)

                        # Store transformed size
                        slot.set_transformed_data_buffer_size(size_holder[0])
                    except Exception as e:
                        self._log(LogLevel.ERROR, f"Transform error: {e}")
                        slot.set_status(BufferStatus.STATUS_ERROR)
                        self._handle_slot_error(slot_idx, slot)
                        continue
                else:
                    # No transform function — identity (copy data size to transformed size)
                    slot.set_transformed_data_buffer_size(slot.get_data_buffer_size())

                # Mark slot as ready for write and advance index
                slot.set_status(BufferStatus.READYFORWRITE)

                # Advance transform index and notify all waiting threads
                self.transform_index += 1
                with self.sync_lock:
                    self.cond_var.notify_all()

                self._log(LogLevel.TRACE, f"Transformed slot {slot_idx}, size="
                          f"{slot.get_transformed_data_buffer_size()}")

        except KeyboardInterrupt:
            threading.current_thread().interrupt()
            self._log(LogLevel.INFO, "Transform thread interrupted")

    def _write_loop(self) -> None:
        """Write loop — writes transformed data to output FD.

        Status transitions: READYFORWRITE → PROCESSING_WRITE → READYFORREAD
        EOF handling: receives LAST_BUFFER_TO_WRITE, flushes output, terminates.
        """
        try:
            while self.running:
                # Get next slot index using write_index with modulo wrapping
                slot_idx = self.write_index % self.num_slots
                slot = self.slots[slot_idx]

                # Wait for slot to be ready for write
                with self.sync_lock:
                    while self.running and slot.status not in (BufferStatus.READYFORWRITE,
                                                               BufferStatus.LAST_BUFFER_TO_WRITE):
                        if slot.status == BufferStatus.STATUS_ERROR:
                            self._handle_slot_error(slot_idx, slot)
                            break
                        self.cond_var.wait(timeout=0.1)  # 100ms timeout for periodic running check
                    if not self.running:
                        break

                    status = slot.status
                    if status == BufferStatus.STATUS_ERROR:
                        break

                    # Check for EOF propagation from transform stage
                    if status == BufferStatus.LAST_BUFFER_TO_WRITE:
                        self._log(LogLevel.INFO, "EOF propagation: flushing output and terminating")

                        # Flush the output stream/file descriptor
                        try:
                            if self.write_fd >= 0:
                                os.fsync(self.write_fd)
                        except OSError as e:
                            self._log(LogLevel.WARNING, f"Error flushing output: {e}")

                        # Mark slot as ready for read (cleanup) and advance index
                        slot.set_status(BufferStatus.READYFORREAD)

                        # Advance write index and notify all waiting threads
                        self.write_index += 1
                        with self.sync_lock:
                            self.cond_var.notify_all()

                        # Break the loop — EOF means end of write pipeline
                        break

                # Mark slot as processing write
                slot.set_status(BufferStatus.PROCESSING_WRITE)

                # Get transformed data size and write to output FD
                transformed_size = slot.get_transformed_data_buffer_size()
                if transformed_size > 0:
                    try:
                        data = slot.data[:transformed_size]

                        # Write to file descriptor using os.write
                        bytes_written = 0
                        while bytes_written < transformed_size:
                            remaining = transformed_size - bytes_written
                            n = os.write(self.write_fd, data[bytes_written:])
                            if n == 0:
                                break
                            bytes_written += n

                        self._log(LogLevel.TRACE, f"Wrote {bytes_written} bytes from slot {slot_idx}")

                    except OSError as e:
                        self._log(LogLevel.ERROR, f"Write error: {e}")
                        slot.set_status(BufferStatus.STATUS_ERROR)
                        self._handle_slot_error(slot_idx, slot)
                        continue

                # Clear slot data and reset sizes for next use
                with slot._lock:
                    slot.data = bytearray(self.buffer_size)
                    slot.data_buffer_size = 0
                    slot.transformed_data_buffer_size = 0

                # Mark slot as ready for read and advance index
                slot.set_status(BufferStatus.READYFORREAD)

                # Advance write index and notify all waiting threads
                self.write_index += 1
                with self.sync_lock:
                    self.cond_var.notify_all()

        except KeyboardInterrupt:
            threading.current_thread().interrupt()
            self._log(LogLevel.INFO, "Write thread interrupted")

    # === Error Handling ===

    def _handle_slot_error(self, slot_idx: int, slot: BufferSlot) -> None:
        """Handle a slot error — call the error handler if set."""
        if self.error_handler is not None:
            result = self.error_handler(slot_idx, slot.status)
            if result != 0:
                # Non-zero return triggers cooperative cancellation
                self._log(LogLevel.WARNING, f"Error handler returned non-zero for slot {slot_idx} — stopping pipeline")
                self.stop()


# === Shared Library Loading (ctypes) ===

def load_ringbuffer_library():
    """Load the ringbuffer shared library using ctypes.

    Returns a CDLL instance for the platform-specific shared object.
    """
    lib_dir = os.path.join(os.path.dirname(__file__), '..', 'lib')

    if sys.platform == 'darwin':
        lib_path = os.path.join(lib_dir, 'libswtr_ringbuffer.dylib')
    else:
        lib_path = os.path.join(lib_dir, 'libswtr_ringbuffer.so')

    return ctypes.CDLL(lib_path)


# === Version (from version.mk) ===
# Read from version.py if available, otherwise use default
try:
    _version_ns = {}
    with open(os.path.join(os.path.dirname(__file__), 'version.py')) as _vf:
        exec(_vf.read(), _version_ns)
    __version__ = _version_ns.get('__version__', 'unknown')
except Exception:
    __version__ = "1.0.0-1"
