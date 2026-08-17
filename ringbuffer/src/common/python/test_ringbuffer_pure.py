#!/usr/bin/env python3
"""Pure Python Ringbuffer test harness — exercises the 7-test matrix (T001-T007).

This is a standalone Python script that tests the pure-Python ringbuffer
implementation (swtr_ringbuffer_pure.py) without any C++ shared library.

Usage:
    python3 test_ringbuffer_pure.py [-o output_file] [-l log_file] \
        [-s slots] [-b size] [-t transform_type] [-e error_mode] [-r] \
        <input_file>

Arguments:
    -o output_file   Write output to file instead of stdout (default: stdout)
    -l log_file      Write log to file instead of stderr (default: stderr)
    -s slots         Number of buffer slots (default: 4)
    -b size          Buffer size per slot in bytes (default: 4096)
    -t transform     Transform type: 0=identity, 1=uppercase, 2=XOR (default: 0)
    -e error_mode    Error mode: 0=none, 1=fatal, 2=non-fatal (default: 0)
    -r               Enable logging/verbosity (default: disabled)
"""

import io
import os
import sys
import argparse
from typing import Optional, List

# Import the pure Python ringbuffer implementation
sys.path.insert(0, os.path.dirname(__file__))
from swtr_ringbuffer_pure import (
    SwtrRingBuffer, BufferStatus, ChecksumAlgorithm, LogLevel, TransformFn, ErrorHandler
)


def create_transform(transform_type: int):
    """Create a transform function based on type code."""
    if transform_type == 0:
        # Identity (no-op) — data passes through unchanged
        return None

    elif transform_type == 1:
        # Uppercase — convert ASCII letters to uppercase in-place
        def uppercase_transform(data: bytearray, slot_indices: List[int]):
            for i in range(len(data)):
                byte = data[i]
                if 97 <= byte <= 122:  # 'a'-'z'
                    data[i] = byte - 32  # Convert to uppercase
        return uppercase_transform

    elif transform_type == 2:
        # XOR with 0xFF — flip all bits in-place
        def xor_transform(data: bytearray, slot_indices: List[int]):
            for i in range(len(data)):
                data[i] = data[i] ^ 0xFF
        return xor_transform

    else:
        raise ValueError(f"Unknown transform type: {transform_type}")


def create_error_handler(error_mode: int):
    """Create an error handler based on mode code."""
    if error_mode == 0:
        # No error — handler never called
        return None

    elif error_mode == 1:
        # Fatal error — returns non-zero to trigger pipeline shutdown
        def fatal_error_handler(slot_idx: int, status: BufferStatus) -> int:
            return 1  # Non-zero triggers shutdown

        return fatal_error_handler

    elif error_mode == 2:
        # Non-fatal error — returns zero, pipeline continues
        def nonfatal_error_handler(slot_idx: int, status: BufferStatus) -> int:
            return 0  # Zero allows pipeline to continue

        return nonfatal_error_handler

    else:
        raise ValueError(f"Unknown error mode: {error_mode}")


def main():
    parser = argparse.ArgumentParser(description='Pure Python Ringbuffer Test Harness')
    parser.add_argument('input_file', help='Input file to read from')
    parser.add_argument('-o', '--output-file', default=None, help='Output file (default: stdout)')
    parser.add_argument('-l', '--log-file', default=None, help='Log file (default: stderr)')
    parser.add_argument('-s', '--slots', type=int, default=4, help='Number of slots (default: 4)')
    parser.add_argument('-b', '--buffer-size', type=int, default=4096, help='Buffer size (default: 4096)')
    parser.add_argument('-t', '--transform', type=int, default=0, help='Transform: 0=identity, 1=uppercase, 2=XOR')
    parser.add_argument('-e', '--error-mode', type=int, default=0, help='Error mode: 0=none, 1=fatal, 2=non-fatal')
    parser.add_argument('-r', '--verbose', action='store_true', help='Enable verbose logging')

    args = parser.parse_args()

    # Setup output
    if args.output_file:
        output_stream = open(args.output_file, 'wb')
    else:
        output_stream = sys.stdout.buffer

    # Setup log
    if args.log_file:
        log_stream = open(args.log_file, 'w')
    else:
        log_stream = sys.stderr

    try:
        # Read input file into memory for testing
        with open(args.input_file, 'rb') as f:
            input_data = f.read()

        # Create transform function
        transform_fn = create_transform(args.transform)

        # Create error handler
        error_handler = create_error_handler(args.error_mode)

        # Create ringbuffer instance
        rb = SwtrRingBuffer(
            num_slots=args.slots,
            initial_status=BufferStatus.READYFORREAD,
            buffer_size=args.buffer_size,
            error_handler=error_handler,
            transform_fn=transform_fn
        )

        if args.verbose:
            rb.set_read_logging_enabled(True)
            rb.set_transform_logging_enabled(True)
            rb.set_write_logging_enabled(True)

        # Write output to ringbuffer's output stream
        rb.set_output_stream(output_stream)

        # Create a temporary file for stdin simulation
        import tempfile
        with tempfile.NamedTemporaryFile(mode='wb', delete=False) as tmp:
            tmp.write(input_data)
            tmp_path = tmp.name

        try:
            # Open input file as fd for the ringbuffer
            input_fd = os.open(tmp_path, os.O_RDONLY)

            # Run the pipeline synchronously
            rb.set_read_fd(input_fd)
            rb.set_write_fd(1)  # stdout

            # Run pipeline in a thread so we can control it
            import threading
            rb.start()

            # Wait for completion with timeout
            rb.join(timeout=30.0)

            # Check if pipeline completed normally (not stopped by error)
            if rb.is_stopped() and args.error_mode == 0:
                # Pipeline was stopped unexpectedly — this is an error
                log_stream.write(f"ERROR: Pipeline stopped unexpectedly\n")
                sys.exit(1)

        finally:
            os.close(input_fd)
            os.unlink(tmp_path)

    except Exception as e:
        log_stream.write(f"ERROR: {e}\n")
        sys.exit(1)

    finally:
        if args.output_file and output_stream != sys.stdout.buffer:
            output_stream.close()
        if args.log_file and log_stream != sys.stderr:
            log_stream.close()

    # Exit code: 0 for success, 1 for fatal error
    sys.exit(0)


if __name__ == '__main__':
    main()
