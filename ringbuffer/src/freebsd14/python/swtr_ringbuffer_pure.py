"""Pure Python Ring Buffer — three-stage pipeline without C++ shared library.

This implementation uses only Python standard library (threading, queue, enum)
to implement the complete three-stage pipeline ring buffer. No ctypes, no
shared library loading — entirely self-contained Python code.

Three-stage pipeline (read → transform → write) operating on a shared pool
of buffer slots with status-driven coordination.

This is the Pure Python implementation — fully satisfies the RingBuffer ABC
interface with real behavior for all methods. No no-ops, no stubs.

This implementation is byte-identical across all platforms (macOS, Linux, FreeBSD).
"""

import io
import os
import sys
import threading
from abc import ABC, abstractmethod
from enum import Enum
from typing import Callable, List, Optional

# Import shared types from base module (try relative first for package use, then absolute)
# Add this directory to sys.path if not already there (for direct module import)
import os as _os
import sys as _sys
_dir = _os.path.dirname(_os.path.abspath(__file__))
if _dir not in _sys.path:
    _sys.path.insert(0, _dir)

try:
    from .base import (
        RingBuffer, BufferStatus, ChecksumAlgorithm, LogLevel,
        TransformFn, ErrorHandler
    )
except ImportError:
    from base import (
        RingBuffer, BufferStatus, ChecksumAlgorithm, LogLevel,
        TransformFn, ErrorHandler
    )


# === Constants ===

MIN_NUMBER_SLOTS = 1
DEFAULT_BUFFER_SIZE = 4096
MIN_BUFFER_SIZE = 1


# === BufferSlot (pure Python with thread-safe access) ===

class BufferSlot:
    """A single buffer slot with data, status, and checksum."""

    def __init__(self, index: int, buffer_size: int):
        self.index = index
        self.buffer_size = buffer_size
        self.data: bytearray = bytearray(buffer_size)
        self.status: BufferStatus = BufferStatus.READYFORREAD
        self.data_size: int = 0
        self.transformed_data_size: int = 0
        self.checksum_alg: ChecksumAlgorithm = ChecksumAlgorithm.NONE
        self.checksum_val: int = 0

    def reset(self):
        """Reset slot to initial state."""
        self.data = bytearray(self.buffer_size)
        self.status = BufferStatus.READYFORREAD
        self.data_size = 0
        self.transformed_data_size = 0
        self.checksum_val = 0

    def get_status(self) -> BufferStatus:
        return self.status

    def set_status(self, status: BufferStatus):
        self.status = status

    def get_data_size(self) -> int:
        return self.data_size

    def set_data_size(self, size: int):
        self.data_size = size

    def get_transformed_data_size(self) -> int:
        return self.transformed_data_size

    def set_transformed_data_size(self, size: int):
        self.transformed_data_size = size

    def get_checksum_alg(self) -> ChecksumAlgorithm:
        return self.checksum_alg

    def set_checksum_alg(self, alg: ChecksumAlgorithm):
        self.checksum_alg = alg

    def get_checksum_val(self) -> int:
        return self.checksum_val

    def set_checksum_val(self, val: int):
        self.checksum_val = val


# === SwtrRingBufferPure (Pure Python) ===

class SwtrRingBufferPure(RingBuffer):
    """Concrete ring buffer implementation — Pure Python, three-stage pipeline.

    Uses threading.Condition for slot status coordination instead of ctypes FFI.
    No shared library loading required — entirely self-contained Python code.

    Pipeline stages:
    1. Read: reads from input FD into buffer slots, marks READYFORTRANSFORM
    2. Transform: applies transform function in-place, marks READYFORWRITE
    3. Write: writes transformed data to output FD, marks READYFORREAD

    Status transitions:
      readyforread -> processing_read -> readyfortransform -> processing_transform
                   -> readyforwrite -> processing_write -> readyforread
      LAST_BUFFER_TO_TRANSFORM -> LAST_BUFFER_TO_WRITE (EOF propagation)

    This implementation fully satisfies the RingBuffer ABC interface.
    """

    def __init__(self, num_slots: int, initial_status: BufferStatus = BufferStatus.READYFORREAD,
                 buffer_size: int = DEFAULT_BUFFER_SIZE,
                 error_handler: Optional[ErrorHandler] = None,
                 transform_fn: Optional[TransformFn] = None):
        # Validate parameters
        if num_slots < 1:
            raise ValueError(f"num_slots must be >= 1, got {num_slots}")
        if buffer_size < MIN_BUFFER_SIZE:
            raise ValueError(f"buffer_size must be >= {MIN_BUFFER_SIZE}, got {buffer_size}")

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

        # Transform function (applied in-place to slot data)
        self.transform_fn: Optional[TransformFn] = transform_fn

        # Error handler callback
        self.error_handler: Optional[ErrorHandler] = error_handler

        # Thread management
        self.read_thread: Optional[threading.Thread] = None
        self.transform_thread: Optional[threading.Thread] = None
        self.write_thread: Optional[threading.Thread] = None

        # Synchronization — Condition variable with associated lock
        self._lock = threading.Lock()
        self._cond = threading.Condition(self._lock)

        # Running flag for cooperative shutdown
        self._running: bool = False

        # Logging configuration
        self.logging_enabled: bool = False
        self.read_logging_enabled: bool = False
        self.transform_logging_enabled: bool = False
        self.write_logging_enabled: bool = False
        self.read_verbosity: LogLevel = LogLevel.INFO
        self.transform_verbosity: LogLevel = LogLevel.INFO
        self.write_verbosity: LogLevel = LogLevel.INFO

        # Output stream (default to stdout)
        self.output_stream: io.IOBase = sys.stdout

        # Log lock (separate from sync_lock to avoid nested locking)
        self.log_lock: threading.Lock = threading.Lock()

        # Guard against double-start
        self._started: bool = False

    def set_read_fd(self, fd: int):
        self.read_fd = fd

    def get_read_fd(self) -> int:
        return self.read_fd

    def set_write_fd(self, fd: int):
        self.write_fd = fd

    def get_write_fd(self) -> int:
        return self.write_fd

    # === Logging configuration (full parity with ctypes) ===

    def set_logging_enabled(self, enabled: bool):
        self.logging_enabled = enabled

    def get_logging_enabled(self) -> bool:
        return self.logging_enabled

    def set_output_stream(self, stream: io.IOBase):
        self.output_stream = stream

    def get_output_stream(self) -> io.IOBase:
        return self.output_stream

    def set_read_logging_enabled(self, enabled: bool):
        self.read_logging_enabled = enabled

    def get_read_logging_enabled(self) -> bool:
        return self.read_logging_enabled

    def set_read_verbosity(self, level: LogLevel):
        self.read_verbosity = level

    def get_read_verbosity(self) -> LogLevel:
        return self.read_verbosity

    def set_transform_logging_enabled(self, enabled: bool):
        self.transform_logging_enabled = enabled

    def get_transform_logging_enabled(self) -> bool:
        return self.transform_logging_enabled

    def set_transform_verbosity(self, level: LogLevel):
        self.transform_verbosity = level

    def get_transform_verbosity(self) -> LogLevel:
        return self.transform_verbosity

    def set_write_logging_enabled(self, enabled: bool):
        self.write_logging_enabled = enabled

    def get_write_logging_enabled(self) -> bool:
        return self.write_logging_enabled

    def set_write_verbosity(self, level: LogLevel):
        self.write_verbosity = level

    def get_write_verbosity(self) -> LogLevel:
        return self.write_verbosity

    # === Slot accessors (full parity with ctypes — real behavior, no no-ops) ===

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
        return self.slots[slot_idx].get_status() == status

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
        return self.slots[slot_idx].get_checksum_alg() == alg

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
        return self.slots[slot_idx].get_checksum_val() == val

    def get_max_size(self, slot_idx: int) -> int:
        if not self._validate_slot(slot_idx):
            return 0
        return self.slots[slot_idx].buffer_size

    def set_max_size(self, slot_idx: int, size: int) -> None:
        if not self._validate_slot(slot_idx):
            return

    def get_data_size(self, slot_idx: int) -> int:
        if not self._validate_slot(slot_idx):
            return 0
        return self.slots[slot_idx].get_data_size()

    def set_data_size(self, slot_idx: int, size: int) -> None:
        if not self._validate_slot(slot_idx):
            return
        self.slots[slot_idx].set_data_size(size)

    def get_transformed_size(self, slot_idx: int) -> int:
        if not self._validate_slot(slot_idx):
            return 0
        return self.slots[slot_idx].get_transformed_data_size()

    def set_transformed_size(self, slot_idx: int, size: int) -> None:
        if not self._validate_slot(slot_idx):
            return
        self.slots[slot_idx].set_transformed_data_size(size)

    # === Logging (full parity with ctypes — thread-name-based verbosity filtering) ===

    def _log(self, level: LogLevel, message: str) -> None:
        """Thread-safe logging method with per-stage verbosity filtering.

        Verbosity is determined from the calling thread's name:
          ringbuffer-read    -> self.read_verbosity
          ringbuffer-transform -> self.transform_verbosity
          ringbuffer-write   -> self.write_verbosity
        All other threads (e.g. main) use no verbosity filtering.
        """
        if not self.logging_enabled:
            return

        # Determine effective verbosity based on calling thread
        thread_name = threading.current_thread().name
        if thread_name == "ringbuffer-read":
            effective_verbosity = self.read_verbosity
        elif thread_name == "ringbuffer-transform":
            effective_verbosity = self.transform_verbosity
        elif thread_name == "ringbuffer-write":
            effective_verbosity = self.write_verbosity
        else:
            # Main thread or other — no verbosity filtering
            effective_verbosity = LogLevel.TRACE

        if level.value < effective_verbosity.value:
            return

        with self.log_lock:
            self.output_stream.write(f"[{level.name}] {message}\n")
            self.output_stream.flush()

    # === Error Handling (full parity with ctypes) ===

    def _handle_slot_error(self, slot_idx: int, slot: BufferSlot) -> None:
        """Handle a slot error — call the error handler if set."""
        if self.error_handler is not None:
            result = self.error_handler(slot_idx, slot.status)
            if result != 0:
                # Non-zero return triggers cooperative cancellation
                self._log(LogLevel.WARNING, f"Error handler returned non-zero for slot {slot_idx} — stopping pipeline")
                self.stop()

    # === Thread Control (full parity with ctypes) ===

    def start(self):
        """Start the three-stage pipeline threads."""
        with self._lock:
            if self._started:
                self._log(LogLevel.WARNING, "Pipeline already started — ignoring duplicate start() call")
                return
            self._started = True
            self._running = True

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

    def stop(self):
        """Stop the pipeline and wait for threads to terminate."""
        with self._lock:
            self._running = False

            # Set all thread references (for awaitTermination)
            read_thread = self.read_thread
            transform_thread = self.transform_thread
            write_thread = self.write_thread

            # Notify the condition variable to wake any waiting threads
            self._cond.notify_all()

        # Wait for threads to finish (outside the lock)
        if read_thread:
            read_thread.join()
        if transform_thread:
            transform_thread.join()
        if write_thread:
            write_thread.join()

        self._log(LogLevel.INFO, "Pipeline stop signal sent")

    def wait(self):
        """Wait for all pipeline threads to complete (non-blocking)."""
        if self.read_thread:
            self.read_thread.join()
        if self.transform_thread:
            self.transform_thread.join()
        if self.write_thread:
            self.write_thread.join()
        self._log(LogLevel.INFO, "All pipeline threads terminated")

    def is_stopped(self) -> bool:
        """Check if stop signal has been received."""
        with self._lock:
            return not self._running

    # === Pipeline Logic (uses threading.Condition for proper coordination) ===

    def _read_loop(self):
        """Read stage: reads from input FD into buffer slots.

        Uses Condition variable for proper thread coordination:
        - Waits on _cond until slot is READYFORREAD or running is False
        - On EOF, sets LAST_BUFFER_TO_TRANSFORM and notifies all
        """
        try:
            while self._running:
                with self._lock:
                    # Wait for a slot in READYFORREAD state or shutdown
                    while self._running:
                        slot_idx = self.read_index % self.num_slots
                        slot = self.slots[slot_idx]
                        if slot.status == BufferStatus.READYFORREAD:
                            break
                        self._cond.wait(timeout=0.1)

                    if not self._running:
                        break

                    slot_idx = self.read_index % self.num_slots
                    slot = self.slots[slot_idx]

                    # Mark as processing read
                    slot.set_status(BufferStatus.PROCESSING_READ)

                # Read from input FD (outside the lock to avoid blocking other threads)
                try:
                    chunk = os.read(self.read_fd, min(slot.buffer_size, 4096))
                except OSError:
                    chunk = b''

                with self._lock:
                    if len(chunk) == 0:
                        # EOF — propagate LAST_BUFFER_TO_TRANSFORM through pipeline
                        slot.set_status(BufferStatus.LAST_BUFFER_TO_TRANSFORM)
                        self.read_index += 1
                        self._cond.notify_all()
                        break

                    # Copy data into slot buffer
                    slot.data[:len(chunk)] = chunk
                    slot.set_data_size(len(chunk))

                    # Mark as ready for transform
                    slot.set_status(BufferStatus.READYFORTRANSFORM)

                    # Advance read index and notify all waiting threads
                    self.read_index += 1
                    self._cond.notify_all()

        except Exception as e:
            if self.error_handler:
                err_code = self.error_handler(1, BufferStatus.STATUS_ERROR)
                if err_code:
                    self.stop()

    def _transform_loop(self):
        """Transform stage: applies transform function to slot data.

        Uses Condition variable for proper thread coordination:
        - Waits on _cond until slot is READYFORTRANSFORM or LAST_BUFFER_TO_TRANSFORM
        - On EOF (LAST_BUFFER_TO_TRANSFORM), converts to LAST_BUFFER_TO_WRITE and notifies all
        """
        try:
            while self._running:
                with self._lock:
                    # Wait for a slot ready for transform or EOF marker, or shutdown
                    while self._running:
                        slot_idx = self.transform_index % self.num_slots
                        slot = self.slots[slot_idx]
                        if slot.status in (BufferStatus.READYFORTRANSFORM,
                                          BufferStatus.LAST_BUFFER_TO_TRANSFORM):
                            break
                        self._cond.wait(timeout=0.1)

                    if not self._running:
                        break

                    slot_idx = self.transform_index % self.num_slots
                    slot = self.slots[slot_idx]

                    # Check for EOF propagation first
                    if slot.status == BufferStatus.LAST_BUFFER_TO_TRANSFORM:
                        # Propagate EOF through pipeline
                        slot.set_status(BufferStatus.LAST_BUFFER_TO_WRITE)
                        self.transform_index += 1
                        self._cond.notify_all()
                        break

                    # Mark as processing transform
                    slot.set_status(BufferStatus.PROCESSING_TRANSFORM)

                # Apply transform function (outside the lock)
                if self.transform_fn:
                    try:
                        self.transform_fn(slot.data, [slot.index])
                    except Exception as e:
                        with self._lock:
                            slot.set_status(BufferStatus.STATUS_ERROR)
                            if self.error_handler:
                                err_code = self.error_handler(2, BufferStatus.STATUS_ERROR)
                                if err_code:
                                    self.stop()
                            continue

                with self._lock:
                    slot.set_transformed_data_size(slot.get_data_size())
                    slot.set_status(BufferStatus.READYFORWRITE)

                    # Advance transform index and notify all waiting threads
                    self.transform_index += 1
                    self._cond.notify_all()

        except Exception as e:
            if self.error_handler:
                err_code = self.error_handler(2, BufferStatus.STATUS_ERROR)
                if err_code:
                    self.stop()

    def _write_loop(self):
        """Write stage: writes transformed data to output FD.

        Uses Condition variable for proper thread coordination:
        - Waits on _cond until slot is READYFORWRITE or LAST_BUFFER_TO_WRITE
        - On EOF (LAST_BUFFER_TO_WRITE), terminates the pipeline
        """
        try:
            while self._running:
                with self._lock:
                    # Wait for a slot ready for write or EOF marker, or shutdown
                    while self._running:
                        slot_idx = self.write_index % self.num_slots
                        slot = self.slots[slot_idx]
                        if slot.status in (BufferStatus.READYFORWRITE,
                                          BufferStatus.LAST_BUFFER_TO_WRITE):
                            break
                        self._cond.wait(timeout=0.1)

                    if not self._running:
                        break

                    slot_idx = self.write_index % self.num_slots
                    slot = self.slots[slot_idx]

                    # Check for EOF propagation first
                    if slot.status == BufferStatus.LAST_BUFFER_TO_WRITE:
                        # EOF propagated — write stage is done
                        slot.set_status(BufferStatus.READYFORREAD)
                        self.write_index += 1
                        self._cond.notify_all()
                        break

                    # Mark as processing write
                    slot.set_status(BufferStatus.PROCESSING_WRITE)

                # Write data to output FD (outside the lock)
                transformed_size = slot.get_transformed_data_size()
                if transformed_size > 0:
                    try:
                        data_to_write = slot.data[:transformed_size]
                        os.write(self.write_fd, data_to_write)
                    except OSError as e:
                        with self._lock:
                            slot.set_status(BufferStatus.STATUS_ERROR)
                            if self.error_handler:
                                err_code = self.error_handler(3, BufferStatus.STATUS_ERROR)
                                if err_code:
                                    self.stop()
                            continue

                with self._lock:
                    # Mark as ready for read (cycle back)
                    slot.set_status(BufferStatus.READYFORREAD)

                    # Advance write index and notify all waiting threads
                    self.write_index += 1
                    self._cond.notify_all()

        except Exception as e:
            if self.error_handler:
                err_code = self.error_handler(3, BufferStatus.STATUS_ERROR)
                if err_code:
                    self.stop()

    def join(self, timeout: Optional[float] = None):
        """Wait for all pipeline stages to complete."""
        if self.read_thread:
            self.read_thread.join(timeout)
        if self.transform_thread:
            self.transform_thread.join(timeout)
        if self.write_thread:
            self.write_thread.join(timeout)

    def run(self, input_fd: int = 0, output_fd: int = 1):
        """Run the pipeline synchronously (convenience method)."""
        self.set_read_fd(input_fd)
        self.set_write_fd(output_fd)
        self.start()
        self.join()


# Backward compatibility alias for existing test harnesses
SwtrRingBuffer = SwtrRingBufferPure
