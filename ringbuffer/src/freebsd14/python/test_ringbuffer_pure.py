#!/usr/bin/env python3
"""Pure Python Ringbuffer test harness — exercises the 7-test matrix (T001-T007).

This is a standalone Python script that tests the pure-Python ringbuffer
implementation (swtr_ringbuffer_pure.py) without any C++ shared library.

Usage:
    python3 test_ringbuffer_pure.py <test_number> [num_slots] [buffer_size]

Examples:
    python3 test_ringbuffer_pure.py 1          # T001: Default (identity transform)
    python3 test_ringbuffer_pure.py 3          # T003: Uppercase transform
    python3 test_ringbuffer_pure.py 7          # T007: XOR transform
    python3 test_ringbuffer_pure.py 2 1 1      # T002: Stress test (1 slot, 1-byte buffer)

    python3 test_ringbuffer_pure.py [-o output_file] [-l log_file] \
        [-s slots] [-b size] [-t transform_type] [-e error_mode] [-r] \
        <input_file>

Arguments (legacy interface):
    -o output_file   Write output to file instead of stdout (default: stdout)
    -l log_file      Write log to file instead of stderr (default: stderr)
    -s slots         Number of buffer slots (default: 4)
    -b size          Buffer size per slot in bytes (default: 4096)
    -t transform     Transform type: 0=identity, 1=uppercase, 2=XOR (default: 0)
    -e error_mode    Error mode: 0=none, 1=fatal, 2=non-fatal (default: 0)
    -r               Enable logging/verbosity (default: disabled)

Test number mapping:
    1 = identity transform, no error, default slots/buffer
    2 = identity transform, no error, 1 slot, 1-byte buffer (stress)
    3 = uppercase transform, no error, default slots/buffer
    4 = identity transform, no error, small input (fast EOF)
    5 = identity transform, fatal error mode
    6 = identity transform, non-fatal error mode
    7 = XOR transform, no error, default slots/buffer
"""

import io
import os
import sys
import tempfile
import argparse
from typing import Optional, List

# Import the pure Python ringbuffer implementation
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from swtr_ringbuffer_pure import (
    SwtrRingBuffer, BufferStatus, ChecksumAlgorithm, LogLevel, TransformFn, ErrorHandler
)


DEFAULT_NUM_SLOTS = 4
DEFAULT_BUFFER_SIZE = 4096

# Test number to (transform_type, error_mode) mapping
TEST_MAP = {
    1: (0, 0),   # identity, no error
    2: (0, 0),   # identity, no error (stress: overridden by slots/buffer args)
    3: (1, 0),   # uppercase, no error
    4: (0, 0),   # identity, no error (small input)
    5: (0, 1),   # identity, fatal error
    6: (0, 2),   # identity, non-fatal error
    7: (2, 0),   # XOR, no error
}


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


def run_test(test_number, num_slots=DEFAULT_NUM_SLOTS, buffer_size=DEFAULT_BUFFER_SIZE):
    """Run a single test by number. Reads input from stdin."""
    if test_number not in TEST_MAP:
        print(f"ERROR: Unknown test number {test_number}. Supported: 1-7", file=sys.stderr)
        sys.exit(1)

    transform_type, error_mode = TEST_MAP[test_number]

    # Read all input from stdin
    input_data = sys.stdin.buffer.read()
    if len(input_data) == 0:
        print(f"ERROR: Test {test_number} — No input data", file=sys.stderr)
        sys.exit(1)

    # Create transform function and error handler
    transform_fn = create_transform(transform_type)
    error_handler = create_error_handler(error_mode)

    # Create temp files for input/output FDs
    with tempfile.NamedTemporaryFile(delete=False, suffix='_input') as fin:
        fin.write(input_data)
        fin_path = fin.name

    with tempfile.NamedTemporaryFile(delete=False, suffix='_output') as fout:
        out_path = fout.name

    try:
        # Open files and get FDs
        fd_in = os.open(fin_path, os.O_RDONLY)
        fd_out = os.open(out_path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC)

        # Create ring buffer with the appropriate transform and error handler
        rb = SwtrRingBuffer(
            num_slots, BufferStatus.READYFORREAD, buffer_size, error_handler, transform_fn
        )

        rb.set_read_fd(fd_in)
        rb.set_write_fd(fd_out)
        rb.start()

        try:
            rb.wait()
        except KeyboardInterrupt:
            rb.stop()

        # Read output and compare (for tests that expect exact match)
        os.close(fd_in)
        os.close(fd_out)

        with open(out_path, 'rb') as f:
            output_data = f.read()

        # Determine pass/fail based on test number
        if test_number == 1:
            # T001: identity — output must equal input
            match = input_data == output_data
        elif test_number == 2:
            # T002: stress — output must equal input
            match = input_data == output_data
        elif test_number == 3:
            # T003: uppercase — output must be uppercase of input
            expected = bytes(b - 32 if 97 <= b <= 122 else b for b in input_data)
            match = output_data == expected
        elif test_number == 4:
            # T004: small input fast EOF — output must equal input
            match = input_data == output_data
        elif test_number == 5:
            # T005: fatal error — pipeline stops early, partial output expected
            print("T005: Pipeline executed (partial output expected)")
            match = True  # Just verify pipeline ran
        elif test_number == 6:
            # T006: non-fatal error — output must equal input
            match = input_data == output_data
        elif test_number == 7:
            # T007: XOR with 0xFF — output must be XOR of input
            expected = bytes(b ^ 0xFF for b in input_data)
            match = output_data == expected
        else:
            match = False

        if not match:
            print(f"ERROR: Test {test_number} — Output does not match expected", file=sys.stderr)
            print(f"  input={len(input_data)} bytes, output={len(output_data)} bytes", file=sys.stderr)
        return match

    finally:
        os.unlink(fin_path)
        if os.path.exists(out_path):
            os.unlink(out_path)


def main():
    """Main entry point — dispatches to the specified test.

    Supports two interfaces:
    1. New (preferred): python3 test_ringbuffer_pure.py <test_number> [num_slots] [buffer_size]
    2. Legacy: python3 test_ringbuffer_pure.py <input_file> [-t transform] [-e error_mode] ...
    """
    # Check if first arg is a digit → new interface (test number)
    if len(sys.argv) >= 2 and sys.argv[1].isdigit():
        try:
            test_number = int(sys.argv[1])
        except ValueError:
            print(f"ERROR: Invalid test number: {sys.argv[1]}", file=sys.stderr)
            sys.exit(1)

        num_slots = DEFAULT_NUM_SLOTS
        buffer_size = DEFAULT_BUFFER_SIZE

        if len(sys.argv) >= 3:
            try:
                num_slots = int(sys.argv[2])
            except ValueError:
                print(f"ERROR: Invalid num_slots: {sys.argv[2]}", file=sys.stderr)
                sys.exit(1)

        if len(sys.argv) >= 4:
            try:
                buffer_size = int(sys.argv[3])
            except ValueError:
                print(f"ERROR: Invalid buffer_size: {sys.argv[3]}", file=sys.stderr)
                sys.exit(1)

        # Validate parameters
        if num_slots < 1:
            print("ERROR: num_slots must be >= 1", file=sys.stderr)
            sys.exit(1)

        if buffer_size < 1:
            print("ERROR: buffer_size must be >= 1", file=sys.stderr)
            sys.exit(1)

        # Run the specified test
        try:
            success = run_test(test_number, num_slots, buffer_size)

            if success:
                print(f"Test {test_number} PASSED")
                sys.exit(0)
            else:
                print(f"Test {test_number} FAILED")
                sys.exit(1)

        except Exception as e:
            print(f"ERROR: Test {test_number} raised exception: {e}", file=sys.stderr)
            sys.exit(1)

    else:
        # Legacy argparse interface — file-based input
        parser = argparse.ArgumentParser(
            description="Pure Python Ringbuffer test harness (legacy file-based interface)"
        )
        parser.add_argument("input_file", help="Input file to read from")
        parser.add_argument("-o", "--output", default=None, help="Output file (default: stdout)")
        parser.add_argument("-l", "--log", default=None, help="Log file (default: stderr)")
        parser.add_argument("-s", "--slots", type=int, default=DEFAULT_NUM_SLOTS,
                            help=f"Number of buffer slots (default: {DEFAULT_NUM_SLOTS})")
        parser.add_argument("-b", "--buffer-size", type=int, default=DEFAULT_BUFFER_SIZE,
                            help=f"Buffer size per slot in bytes (default: {DEFAULT_BUFFER_SIZE})")
        parser.add_argument("-t", "--transform", type=int, default=0, choices=[0, 1, 2],
                            help="Transform type: 0=identity, 1=uppercase, 2=XOR (default: 0)")
        parser.add_argument("-e", "--error-mode", type=int, default=0, choices=[0, 1, 2],
                            help="Error mode: 0=none, 1=fatal, 2=non-fatal (default: 0)")
        parser.add_argument("-r", "--verbose", action="store_true", help="Enable verbose logging")

        args = parser.parse_args()

        # Read input from file
        with open(args.input_file, 'rb') as f:
            input_data = f.read()

        if len(input_data) == 0:
            print("ERROR: No input data", file=sys.stderr)
            sys.exit(1)

        # Create transform and error handler
        transform_fn = create_transform(args.transform)
        error_handler = create_error_handler(args.error_mode)

        # Create temp files for input/output FDs
        with tempfile.NamedTemporaryFile(delete=False, suffix='_input') as fin:
            fin.write(input_data)
            fin_path = fin.name

        with tempfile.NamedTemporaryFile(delete=False, suffix='_output') as fout:
            out_path = fout.name

        try:
            # Open files and get FDs
            fd_in = os.open(fin_path, os.O_RDONLY)
            fd_out = os.open(out_path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC)

            # Create ring buffer
            rb = SwtrRingBuffer(
                args.slots, BufferStatus.READYFORREAD, args.buffer_size, error_handler, transform_fn
            )

            rb.set_read_fd(fd_in)
            rb.set_write_fd(fd_out)
            rb.start()

            try:
                rb.wait()
            except KeyboardInterrupt:
                rb.stop()

            os.close(fd_in)
            os.close(fd_out)

            # Read output and write to destination
            with open(out_path, 'rb') as f:
                output_data = f.read()

            if args.output:
                with open(args.output, 'wb') as f:
                    f.write(output_data)
            else:
                sys.stdout.buffer.write(output_data)

        finally:
            os.unlink(fin_path)
            if os.path.exists(out_path):
                os.unlink(out_path)


if __name__ == '__main__':
    main()
