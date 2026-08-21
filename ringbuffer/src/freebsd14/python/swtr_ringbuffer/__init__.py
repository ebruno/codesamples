"""Ring Buffer — auto-selects Concurrent or Pure Python implementation.

This package provides a single entry point that automatically selects the
best available implementation:

1. Concurrent (ctypes + C++ shared library) — tried first
2. Pure Python (no dependencies) — fallback if Concurrent not available

Usage:
    from swtr_ringbuffer import SwtrRingBuffer  # auto-selects best available
    print(SwtrRingBuffer._version)  # "Concurrent" or "Pure Python"

If the C++ shared library is not found, a warning is printed to stderr
and Pure Python is used as fallback.

To explicitly choose an implementation:
    from swtr_ringbuffer.swtr_ringbuffer_concurrent import SwtrRingBufferConcurrent  # Concurrent
    from swtr_ringbuffer_pure import SwtrRingBufferPure  # Pure Python (top-level)
"""

import sys
import os

# Try Concurrent (ctypes) first
try:
    from .swtr_ringbuffer_concurrent import SwtrRingBufferConcurrent as _SwtrRingBuffer
    _version = "Concurrent"
except (ImportError, OSError) as e:
    # Fall back to Pure Python (import from top-level module)
    print(f"WARNING: C++ shared library not available ({e}) — falling back to Pure Python", file=sys.stderr)
    # Import from top-level swtr_ringbuffer_pure module
    _dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    if _dir not in sys.path:
        sys.path.insert(0, _dir)
    import swtr_ringbuffer_pure as _pure_module
    _SwtrRingBuffer = _pure_module.SwtrRingBufferPure
    _version = "Pure Python"

# Export the selected implementation
SwtrRingBuffer = _SwtrRingBuffer
SwtrRingBuffer._version = _version  # Attach version info as class attribute

# Re-export shared types for convenience (from top-level base.py)
import importlib
_base = importlib.import_module('base')
RingBuffer = _base.RingBuffer
BufferStatus = _base.BufferStatus
ChecksumAlgorithm = _base.ChecksumAlgorithm
LogLevel = _base.LogLevel
TransformFn = _base.TransformFn
ErrorHandler = _base.ErrorHandler

__all__ = ["SwtrRingBuffer", "RingBuffer", "BufferStatus", "ChecksumAlgorithm",
           "LogLevel", "TransformFn", "ErrorHandler", "_version"]
