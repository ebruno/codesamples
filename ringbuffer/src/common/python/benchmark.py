#!/usr/bin/env python3
"""Benchmark script — compares pure Python ringbuffer vs ctypes ringbuffer.

Runs the 7-test matrix (T001-T007) on both implementations and reports
side-by-side performance comparison.

Usage:
    python3 benchmark.py [--iterations N] [--input-file FILE]
"""

import os
import sys
import time
import tempfile
import subprocess
from typing import Dict, List, Tuple

# Add current directory to path for imports
sys.path.insert(0, os.path.dirname(__file__))


# === Test Matrix Definition ===

TESTS = [
    {'id': 'T001', 'name': 'Identity (normal)',       'slots': 4, 'bufsize': 4096, 'transform': 0, 'error': 0},
    {'id': 'T002', 'name': 'Stress test (1 slot, 1 byte)', 'slots': 1, 'bufsize': 1,   'transform': 0, 'error': 0},
    {'id': 'T003', 'name': 'Uppercase transform',     'slots': 4, 'bufsize': 10,    'transform': 1, 'error': 0},
    {'id': 'T004', 'name': 'Small input, fast EOF',   'slots': 4, 'bufsize': 4096,  'transform': 0, 'error': 0},
    {'id': 'T005', 'name': 'Fatal error mode',        'slots': 4, 'bufsize': 4096,  'transform': 0, 'error': 1},
    {'id': 'T006', 'name': 'Non-fatal error mode',    'slots': 4, 'bufsize': 4096,  'transform': 0, 'error': 2},
    {'id': 'T007', 'name': 'XOR transform',           'slots': 4, 'bufsize': 4096,  'transform': 2, 'error': 0},
]


def create_test_input() -> str:
    """Create a test input file with standard zigzag pattern."""
    content = ""
    for i in range(1, 26):
        prefix = f"{i:04d}"
        # Zigzag space position pattern (48 chars total)
        payload = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()<> "
        # Move space position in zigzag pattern
        space_pos = (i - 1) % len(payload)
        payload = payload[:space_pos] + " " + payload[space_pos+1:]
        suffix = f"{i:04d}"
        content += f"{prefix} {payload} {suffix}\n"
    return content


def run_ctypes_test(test: dict, input_file: str) -> Tuple[float, int]:
    """Run a test using the existing ctypes implementation.

    Returns (elapsed_seconds, exit_code).
    """
    cmd = [
        sys.executable, 'test_ringbuffer.py',
        input_file,
        '-s', str(test['slots']),
        '-b', str(test['bufsize']),
        '-t', str(test['transform']),
        '-e', str(test['error']),
    ]

    start = time.perf_counter()
    result = subprocess.run(cmd, capture_output=True, timeout=30)
    elapsed = time.perf_counter() - start

    return (elapsed, result.returncode)


def run_pure_test(test: dict, input_file: str) -> Tuple[float, int]:
    """Run a test using the pure Python implementation.

    Returns (elapsed_seconds, exit_code).
    """
    cmd = [
        sys.executable, 'test_ringbuffer_pure.py',
        input_file,
        '-s', str(test['slots']),
        '-b', str(test['bufsize']),
        '-t', str(test['transform']),
        '-e', str(test['error']),
    ]

    start = time.perf_counter()
    result = subprocess.run(cmd, capture_output=True, timeout=30)
    elapsed = time.perf_counter() - start

    return (elapsed, result.returncode)


def run_benchmark(iterations: int = 10):
    """Run the full benchmark comparing both implementations."""

    # Create test input file
    with tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False) as f:
        f.write(create_test_input())
        input_file = f.name

    try:
        print("=" * 80)
        print("Ringbuffer Performance Benchmark")
        print(f"Comparing: Concurrent (ctypes + C++ shared lib) vs pure Python")
        print(f"Iterations per test: {iterations}")
        print("=" * 80)
        print()

        # Collect results
        ctypes_results: Dict[str, List[float]] = {}
        pure_results: Dict[str, List[float]] = {}

        for test in TESTS:
            tid = test['id']
            ctypes_times: List[float] = []
            pure_times: List[float] = []

            print(f"Running {tid}: {test['name']}...")

            # Run ctypes version
            for i in range(iterations):
                elapsed, exit_code = run_ctypes_test(test, input_file)
                ctypes_times.append(elapsed)

            # Run pure Python version
            for i in range(iterations):
                elapsed, exit_code = run_pure_test(test, input_file)
                pure_times.append(elapsed)

            ctypes_results[tid] = ctypes_times
            pure_results[tid] = pure_times

            # Calculate statistics
            ctypes_mean = sum(ctypes_times) / len(ctypes_times)
            pure_mean = sum(pure_times) / len(pure_times)

            # Calculate speedup (pure / ctypes, >1 means pure is slower)
            if ctypes_mean > 0:
                speedup = pure_mean / ctypes_mean
            else:
                speedup = float('inf')

            print(f"  Concurrent (ctypes): mean={ctypes_mean*1000:.2f}ms")
            print(f"  Pure Python:  mean={pure_mean*1000:.2f}ms")
            print(f"  Speedup:      {speedup:.2f}x (pure Python is {'slower' if speedup > 1 else 'faster'})")
            print()

        # Print summary table
        print("=" * 80)
        print("SUMMARY TABLE")
        print("=" * 80)
        print(f"{'Test':<10} {'Description':<35} {'Concurrent (ms)':>12} {'Pure (ms)':>12} {'Speedup':>10}")
        print("-" * 80)

        for test in TESTS:
            tid = test['id']
            ctypes_mean = sum(ctypes_results[tid]) / len(ctypes_results[tid]) * 1000
            pure_mean = sum(pure_results[tid]) / len(pure_results[tid]) * 1000

            if ctypes_mean > 0:
                speedup = pure_mean / ctypes_mean
            else:
                speedup = float('inf')

            print(f"{tid:<10} {test['name']:<35} {ctypes_mean:>12.2f} {pure_mean:>12.2f} {speedup:>9.2f}x")

        print("=" * 80)
        print()

        # Overall average speedup
        all_ctypes = []
        all_pure = []
        for tid in ctypes_results:
            all_ctypes.extend(ctypes_results[tid])
            all_pure.extend(pure_results[tid])

        overall_ctypes = sum(all_ctypes) / len(all_ctypes) * 1000
        overall_pure = sum(all_pure) / len(all_pure) * 1000

        if overall_ctypes > 0:
            overall_speedup = overall_pure / overall_ctypes
        else:
            overall_speedup = float('inf')

        print(f"OVERALL AVERAGE:")
        print(f"  Concurrent (ctypes): {overall_ctypes:.2f}ms")
        print(f"  Pure Python:  {overall_pure:.2f}ms")
        print(f"  Speedup:      {overall_speedup:.2f}x (pure Python is {'slower' if overall_speedup > 1 else 'faster'})")
        print()

    finally:
        os.unlink(input_file)


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(description='Ringbuffer Benchmark')
    parser.add_argument('--iterations', type=int, default=10, help='Iterations per test (default: 10)')

    args = parser.parse_args()
    run_benchmark(args.iterations)
