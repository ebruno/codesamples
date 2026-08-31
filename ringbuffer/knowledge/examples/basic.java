// Basic Java example — construct, transform, run pipeline
import swtr.*;

public class BasicExample {
    public static void main(String[] args) throws Exception {
        // Transform: convert input to uppercase
        TransformFunction transform = (data, size) -> {
            for (int i = 0; i < size; ++i)
                if (data[i] >= 'a' && data[i] <= 'z') data[i] -= 32;
        };

        // Create a ring buffer with 4 slots, 4096 bytes each
        SwtrRingBuffer rb = new SwtrRingBuffer(
            4, BufferStatus.READYFORREAD, 4096, null, transform);

        // Configure I/O: read from stdin (fd 0), write to stdout (fd 1)
        rb.setReadFd(0);
        rb.setWriteFd(1);

        // Run the pipeline: reads until EOF, transforms each slot, writes output
        rb.start();
        rb.awaitTermination();  // blocks until all threads complete
        rb.stop();

        System.out.println("Pipeline completed successfully.");
    }
}
