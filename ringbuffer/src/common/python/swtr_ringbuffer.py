# Backward compatibility shim — do not edit directly.
# This file re-exports from the swtr_ringbuffer package for legacy imports.
# New code should use: from swtr_ringbuffer import SwtrRingBuffer

from .swtr_ringbuffer import SwtrRingBuffer  # noqa: F401
from .swtr_ringbuffer import _version as version  # noqa: F401
