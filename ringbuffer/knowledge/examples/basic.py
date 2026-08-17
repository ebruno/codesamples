# Basic Python example — construct, transform, run pipeline
from swtr_ringbuffer import SwtrRingBuffer, BufferStatus

# Transform: convert input to uppercase
def transform(data, size):
    for i in range(size):
        if data[i] >= ord('a') and data[i] <= ord('z'):
            data[i] -= 32

# Create a ring buffer with 4 slots, 4096 bytes each
rb = SwtrRingBuffer(
    num_slots=4,
    initial_status=BufferStatus.READYFORREAD,
    buffer_size=4096,
    error_handler=None,
    transform_fn=transform
)

# Configure I/O: read from stdin (fd 0), write to stdout (fd 1)
rb.set_read_fd(0)
rb.set_write_fd(1)

# Run the pipeline: reads until EOF, transforms each slot, writes output
rb.start()
rb.wait()      # blocks until all threads complete
rb.stop()

print("Pipeline completed successfully.")
