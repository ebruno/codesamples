#!/usr/bin/env python3
"""Generate large test input file for ringbuffer benchmarking.

Generates 10,000 lines of the zigzag pattern (~6 MB) for performance
comparison between Concurrent and Pure Python implementations.

Usage:
    python3 generate_large_test.py [output_file]

Default output: src/common/python/tests/large_input_10k.txt
"""

import os
import sys


def generate_zigzag_pattern(num_lines: int = 10000) -> str:
    """Generate num_lines lines of the zigzag space position pattern.

    Each line has format:
        {4-digit-number} {payload-with-space-in-zigzag-position} {4-digit-number}

    The payload is: ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()<>
    The space position moves in a zigzag pattern across the payload.
    """
    content = ""
    for i in range(1, num_lines + 1):
        prefix = f"{i:04d}" if i < 10000 else str(i)
        # Zigzag space position pattern (48 chars total)
        payload = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()<> "
        # Move space position in zigzag pattern
        space_pos = (i - 1) % len(payload)
        payload = payload[:space_pos] + " " + payload[space_pos+1:]
        suffix = f"{i:04d}" if i < 10000 else str(i)
        content += f"{prefix} {payload} {suffix}\n"
    return content


def main():
    output_file = sys.argv[1] if len(sys.argv) > 1 else "src/common/python/tests/large_input_10k.txt"

    print(f"Generating {output_file}...")
    content = generate_zigzag_pattern(10000)

    with open(output_file, 'w') as f:
        f.write(content)

    num_lines = len(content.splitlines())
    file_size = os.path.getsize(output_file)

    print(f"Generated {num_lines} lines")
    print(f"File size: {file_size:,} bytes ({file_size/1024/1024:.2f} MB)")


if __name__ == '__main__':
    main()
