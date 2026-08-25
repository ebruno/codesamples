#!/usr/bin/env python3
"""Ring buffer test harness — exercises the 7-test matrix (T001-T007).

Usage:
    python3 test_ringbuffer.py <test_number> [num_slots] [buffer_size]

Examples:
    python3 test_ringbuffer.py 1          # T001: Default (identity transform)
    python3 test_ringbuffer.py 3          # T003: Uppercase transform
    python3 test_ringbuffer.py 7          # T007: XOR transform
    python3 test_ringbuffer.py 2 1 1      # T002: Stress test (1 slot, 1-byte buffer)
"""

import argparse
import datetime
import os
import sys
import tempfile

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from swtr_ringbuffer import (
    BufferStatus, LogLevel, SwtrRingBuffer, TransformFn, ErrorHandler
)


DEFAULT_NUM_SLOTS = 4
DEFAULT_BUFFER_SIZE = 4096


def read_all_bytes():
    """Read all bytes from stdin."""
    return sys.stdin.buffer.read()


def run_test001(num_slots, buffer_size):
    """T001: Default (identity transform) — output == input."""
    print("Running T001: Default (identity transform)")

    input_data = read_all_bytes()
    if len(input_data) == 0:
        print("ERROR: T001 — No input data", file=sys.stderr)
        return False

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

        # Create ring buffer with identity transform (None = no-op)
        rb = SwtrRingBuffer(
            num_slots, BufferStatus.READYFORREAD, buffer_size, None, None
        )

        rb.set_read_fd(fd_in)
        rb.set_write_fd(fd_out)
        rb.start()

        try:
            rb.wait()
        except KeyboardInterrupt:
            rb.stop()

        # Read output and compare
        os.close(fd_in)
        os.close(fd_out)

        with open(out_path, 'rb') as f:
            output_data = f.read()

        match = input_data == output_data
        if not match:
            print(f"ERROR: T001 — Output does not match input (input={len(input_data)} bytes, output={len(output_data)} bytes)", file=sys.stderr)
        return match

    finally:
        os.unlink(fin_path)
        if os.path.exists(out_path):
            os.unlink(out_path)


def run_test002(num_slots, buffer_size):
    """T002: Stress test (1 slot, 1-byte buffer) — output == input."""
    print("Running T002: Stress test (1 slot, 1-byte buffer)")

    input_data = read_all_bytes()
    if len(input_data) == 0:
        print("ERROR: T002 — No input data", file=sys.stderr)
        return False

    with tempfile.NamedTemporaryFile(delete=False, suffix='_input') as fin:
        fin.write(input_data)
        fin_path = fin.name

    with tempfile.NamedTemporaryFile(delete=False, suffix='_output') as fout:
        out_path = fout.name

    try:
        fd_in = os.open(fin_path, os.O_RDONLY)
        fd_out = os.open(out_path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC)

        rb = SwtrRingBuffer(1, BufferStatus.READYFORREAD, 1, None, None)
        rb.set_read_fd(fd_in)
        rb.set_write_fd(fd_out)
        rb.start()

        try:
            rb.wait()
        except KeyboardInterrupt:
            rb.stop()

        os.close(fd_in)
        os.close(fd_out)

        with open(out_path, 'rb') as f:
            output_data = f.read()

        match = input_data == output_data
        if not match:
            print(f"ERROR: T002 — Output does not match input", file=sys.stderr)
        return match

    finally:
        os.unlink(fin_path)
        if os.path.exists(out_path):
            os.unlink(out_path)


def to_uppercase(data, size_holder):
    """Transform: convert ASCII bytes to uppercase (in-place)."""
    n = size_holder[0]
    for i in range(n):
        b = data[i]
        if 97 <= b <= 122:  # lowercase a-z
            data[i] = b - 32  # convert to uppercase in-place


def run_test003(num_slots, buffer_size):
    """T003: Uppercase transform — output is uppercase of input."""
    print("Running T003: Uppercase transform")

    input_data = read_all_bytes()
    if len(input_data) == 0:
        print("ERROR: T003 — No input data", file=sys.stderr)
        return False

    expected = bytes(b - 32 if 97 <= b <= 122 else b for b in input_data)

    with tempfile.NamedTemporaryFile(delete=False, suffix='_input') as fin:
        fin.write(input_data)
        fin_path = fin.name

    with tempfile.NamedTemporaryFile(delete=False, suffix='_output') as fout:
        out_path = fout.name

    try:
        fd_in = os.open(fin_path, os.O_RDONLY)
        fd_out = os.open(out_path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC)

        rb = SwtrRingBuffer(
            num_slots, BufferStatus.READYFORREAD, buffer_size, None, to_uppercase
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

        with open(out_path, 'rb') as f:
            output_data = f.read()

        match = output_data == expected
        if not match:
            print(f"ERROR: T003 — Output does not match expected uppercase", file=sys.stderr)
        return match

    finally:
        os.unlink(fin_path)
        if os.path.exists(out_path):
            os.unlink(out_path)


def run_test004(num_slots, buffer_size):
    """T004: Small input, fast EOF — output == input."""
    print("Running T004: Small input, fast EOF")

    input_data = read_all_bytes()
    if len(input_data) == 0:
        print("ERROR: T004 — No input data", file=sys.stderr)
        return False

    with tempfile.NamedTemporaryFile(delete=False, suffix='_input') as fin:
        fin.write(input_data)
        fin_path = fin.name

    with tempfile.NamedTemporaryFile(delete=False, suffix='_output') as fout:
        out_path = fout.name

    try:
        fd_in = os.open(fin_path, os.O_RDONLY)
        fd_out = os.open(out_path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC)

        rb = SwtrRingBuffer(num_slots, BufferStatus.READYFORREAD, buffer_size, None, None)
        rb.set_read_fd(fd_in)
        rb.set_write_fd(fd_out)
        rb.start()

        try:
            rb.wait()
        except KeyboardInterrupt:
            rb.stop()

        os.close(fd_in)
        os.close(fd_out)

        with open(out_path, 'rb') as f:
            output_data = f.read()

        match = input_data == output_data
        if not match:
            print(f"ERROR: T004 — Output does not match input", file=sys.stderr)
        return match

    finally:
        os.unlink(fin_path)
        if os.path.exists(out_path):
            os.unlink(out_path)


def error_handler_fatal(slot_idx, status):
    """Error handler that always returns non-zero (fatal)."""
    print(f"ERROR: Error handler called for slot {slot_idx}", file=sys.stderr)
    return 1


def run_test005(num_slots, buffer_size):
    """T005: Fatal error mode — pipeline stops early (partial output expected)."""
    print("Running T005: Fatal error mode")

    input_data = read_all_bytes()
    if len(input_data) == 0:
        print("ERROR: T005 — No input data", file=sys.stderr)
        return False

    with tempfile.NamedTemporaryFile(delete=False, suffix='_input') as fin:
        fin.write(input_data)
        fin_path = fin.name

    with tempfile.NamedTemporaryFile(delete=False, suffix='_output') as fout:
        out_path = fout.name

    try:
        fd_in = os.open(fin_path, os.O_RDONLY)
        fd_out = os.open(out_path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC)

        rb = SwtrRingBuffer(
            num_slots, BufferStatus.READYFORREAD, buffer_size, error_handler_fatal, None
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

        # For T005, we just verify the pipeline executed (partial output is expected)
        print("T005: Pipeline executed (partial output expected)")
        return False

    finally:
        os.unlink(fin_path)
        if os.path.exists(out_path):
            os.unlink(out_path)


def error_handler_nonfatal(slot_idx, status):
    """Error handler that always returns zero (non-fatal)."""
    print(f"WARNING: Non-fatal error in slot {slot_idx}", file=sys.stderr)
    return 0


def run_test006(num_slots, buffer_size):
    """T006: Non-fatal error mode — output == input."""
    print("Running T006: Non-fatal error mode")

    input_data = read_all_bytes()
    if len(input_data) == 0:
        print("ERROR: T006 — No input data", file=sys.stderr)
        return False

    with tempfile.NamedTemporaryFile(delete=False, suffix='_input') as fin:
        fin.write(input_data)
        fin_path = fin.name

    with tempfile.NamedTemporaryFile(delete=False, suffix='_output') as fout:
        out_path = fout.name

    try:
        fd_in = os.open(fin_path, os.O_RDONLY)
        fd_out = os.open(out_path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC)

        rb = SwtrRingBuffer(
            num_slots, BufferStatus.READYFORREAD, buffer_size, error_handler_nonfatal, None
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

        with open(out_path, 'rb') as f:
            output_data = f.read()

        match = input_data == output_data
        if not match:
            print(f"ERROR: T006 — Output does not match input", file=sys.stderr)
        return match

    finally:
        os.unlink(fin_path)
        if os.path.exists(out_path):
            os.unlink(out_path)


def xor_transform(data, size_holder):
    """Transform: XOR each byte with 0xAA."""
    key = 0xAA
    for i in range(size_holder[0]):
        data[i] = data[i] ^ key


def run_test007(num_slots, buffer_size):
    """T007: XOR transform — output is XOR of input with 0xAA."""
    print("Running T007: XOR transform")

    input_data = read_all_bytes()
    if len(input_data) == 0:
        print("ERROR: T007 — No input data", file=sys.stderr)
        return False

    expected = bytes(b ^ 0xAA for b in input_data)

    with tempfile.NamedTemporaryFile(delete=False, suffix='_input') as fin:
        fin.write(input_data)
        fin_path = fin.name

    with tempfile.NamedTemporaryFile(delete=False, suffix='_output') as fout:
        out_path = fout.name

    try:
        fd_in = os.open(fin_path, os.O_RDONLY)
        fd_out = os.open(out_path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC)

        rb = SwtrRingBuffer(
            num_slots, BufferStatus.READYFORREAD, buffer_size, None, xor_transform
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

        with open(out_path, 'rb') as f:
            output_data = f.read()

        match = output_data == expected
        if not match:
            print(f"ERROR: T007 — Output does not match expected XOR data", file=sys.stderr)
        return match

    finally:
        os.unlink(fin_path)
        if os.path.exists(out_path):
            os.unlink(out_path)


def parse_args():
    """Parse command-line arguments including optional --junit flag."""
    parser = argparse.ArgumentParser(description='Ring buffer test harness (Concurrent)')
    parser.add_argument('test_number', type=int, help='Test number (1-7)')
    parser.add_argument('num_slots', type=int, nargs='?', default=DEFAULT_NUM_SLOTS,
                        help=f'Number of buffer slots (default: {DEFAULT_NUM_SLOTS})')
    parser.add_argument('buffer_size', type=int, nargs='?', default=DEFAULT_BUFFER_SIZE,
                        help=f'Buffer size per slot in bytes (default: {DEFAULT_BUFFER_SIZE})')
    parser.add_argument('--junit', type=str, default=None,
                        help='Path to JUnit XML output file (appends <testcase> element)')
    return parser.parse_args()


def main():
    """Main entry point — dispatches to the specified test."""
    args = parse_args()

    test_number = args.test_number
    num_slots = args.num_slots
    buffer_size = args.buffer_size

    # Validate parameters
    if num_slots < 1:
        print("ERROR: num_slots must be >= 1", file=sys.stderr)
        sys.exit(1)

    if buffer_size < 1:
        print("ERROR: buffer_size must be >= 1", file=sys.stderr)
        sys.exit(1)

    # Run the specified test
    try:
        if test_number == 1:
            success = run_test001(num_slots, buffer_size)
        elif test_number == 2:
            success = run_test002(num_slots, buffer_size)
        elif test_number == 3:
            success = run_test003(num_slots, buffer_size)
        elif test_number == 4:
            success = run_test004(num_slots, buffer_size)
        elif test_number == 5:
            success = run_test005(num_slots, buffer_size)
        elif test_number == 6:
            success = run_test006(num_slots, buffer_size)
        elif test_number == 7:
            success = run_test007(num_slots, buffer_size)
        else:
            print(f"ERROR: Unknown test number {test_number}. Supported: 1-7", file=sys.stderr)
            sys.exit(1)

        if success:
            print(f"Test {test_number} PASSED")
            status = "passed"
        else:
            print(f"Test {test_number} FAILED")
            status = "failed"

        # Write JUnit XML if requested
        junit_file = args.junit
        if junit_file:
            test_id = f"T00{test_number}"
            descriptions = {
                1: "Default (identity transform)",
                2: "Stress test (1 slot, 1-byte buffer)",
                3: "Uppercase transform",
                4: "Small input, fast EOF",
                5: "Fatal error mode",
                6: "Non-fatal error mode",
                7: "XOR transform (bit-inverted)",
            }
            description = descriptions.get(test_number, f"Test {test_number}")
            timestamp = datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
            testcase_xml = (
                f'  <testcase name="{test_id}" classname="swtr_ringbuffer" '
                f'time="0.001" timestamp="{timestamp}">\n'
                f'    <system-out>{description}</system-out>\n'
            )
            if status == "failed":
                testcase_xml += f'    <failure message="Test {test_id} failed"/>\n'
            testcase_xml += f'  </testcase>\n'

            # Append to JUnit file (create if not exists)
            junit_dir = os.path.dirname(junit_file)
            if junit_dir:
                os.makedirs(junit_dir, exist_ok=True)

            # Check if file exists and has content
            if os.path.exists(junit_file) and os.path.getsize(junit_file) > 0:
                with open(junit_file, 'r') as f:
                    existing = f.read()
                # Insert before </testsuites>
                if '</testsuites>' in existing:
                    existing = existing.replace('</testsuites>', testcase_xml + '</testsuites>')
                else:
                    # Append new testsuite
                    existing += testcase_xml + '</testsuites>\n'
                with open(junit_file, 'w') as f:
                    f.write(existing)
            else:
                # Create new JUnit file
                with open(junit_file, 'w') as f:
                    f.write(f'<?xml version="1.0" encoding="UTF-8"?>\n')
                    f.write(f'<testsuites name="ringbuffer_concurrent" tests="1" failures="0" errors="0">\n')
                    f.write(testcase_xml)
                    f.write(f'</testsuites>\n')

        sys.exit(0 if success else 1)

    except Exception as e:
        print(f"ERROR: Test {test_number} raised exception: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
