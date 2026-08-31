# Advanced Python example — per-stage logging, checksumming, custom error handler
from swtr_ringbuffer import SwtrRingBuffer, BufferStatus, ChecksumAlgorithm, LogLevel

# Custom error handler
def my_error_handler(slot_idx: int, status: BufferStatus) -> int:
    print(f"Error in slot {slot_idx}: {status}", flush=True)
    return 0  # 0 = continue, non-zero = stop pipeline

# Transform: XOR each byte with 0xFF
def transform(data, size):
    for i in range(size):
        data[i] ^= 0xFF

# Create ring buffer with custom error handler
rb = SwtrRingBuffer(
    num_slots=4,
    initial_status=BufferStatus.READYFORWRITE,  # Note: Python uses enum names (uppercase)
    buffer_size=4096,
    error_handler=my_error_handler,
    transform_fn=transform
)

# Configure I/O
rb.set_read_fd(0)
rb.set_write_fd(1)

# Enable logging for diagnostics
rb.set_logging_enabled(True)
rb.set_output_stream(__import__('sys').stderr)

# Per-stage logging configuration (independent verbosity per stage)
rb.set_read_logging_enabled(True)
rb.set_read_verbosity(LogLevel.DEBUG)
rb.set_transform_logging_enabled(True)
rb.set_transform_verbosity(LogLevel.INFO)
rb.set_write_logging_enabled(True)
rb.set_write_verbosity(LogLevel.INFO)

# Checksum algorithm per slot (NONE, MD5, SHA256, SHA512)
rb.set_checksum_alg(0, ChecksumAlgorithm.SHA256)
rb.set_checksum_alg(1, ChecksumAlgorithm.SHA256)
rb.set_checksum_alg(2, ChecksumAlgorithm.SHA256)
rb.set_checksum_alg(3, ChecksumAlgorithm.SHA256)

# Run the pipeline
rb.start()
rb.wait()      # blocks until all threads complete
rb.stop()

# Inspect final slot states (for debugging/monitoring)
for i in range(4):
    print(f"Slot {i}: status={rb.get_status(i)}, checksum={rb.get_checksum_val(i)}, "
          f"data_size={rb.get_data_size(i)}", flush=True)

print("Pipeline completed successfully.")
