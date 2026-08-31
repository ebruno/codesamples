// Advanced Java example — per-stage logging, checksumming, custom error handler
import swtr.*;

public class AdvancedExample {
    // Custom error handler (functional interface)
    static int myErrorHandler(int slotIdx, BufferStatus status) {
        System.err.println("Error in slot " + slotIdx + ": " + status);
        return 0; // 0 = continue, non-zero = stop pipeline
    }

    public static void main(String[] args) throws Exception {
        // Transform: XOR each byte with 0xFF
        TransformFunction transform = (data, size) -> {
            for (int i = 0; i < size; ++i)
                data[i] ^= 0xFF;
        };

        // Create ring buffer with custom error handler
        SwtrRingBuffer rb = new SwtrRingBuffer(
            4, BufferStatus.READYFORWRITE, 4096, AdvancedExample::myErrorHandler, transform);

        // Configure I/O
        rb.setReadFd(0);
        rb.setWriteFd(1);

        // Enable logging for diagnostics
        rb.setLoggingEnabled(true);
        rb.setOutputStream(System.err);

        // Per-stage logging configuration (independent verbosity per stage)
        rb.setReadLoggingEnabled(true);
        rb.setReadVerbosity(LogLevel.DEBUG);
        rb.setTransformLoggingEnabled(true);
        rb.setTransformVerbosity(LogLevel.INFO);
        rb.setWriteLoggingEnabled(true);
        rb.setWriteVerbosity(LogLevel.INFO);

        // Checksum algorithm per slot (NONE, MD5, SHA256, SHA512)
        rb.setChecksumAlg(0, ChecksumAlgorithm.SHA256);
        rb.setChecksumAlg(1, ChecksumAlgorithm.SHA256);
        rb.setChecksumAlg(2, ChecksumAlgorithm.SHA256);
        rb.setChecksumAlg(3, ChecksumAlgorithm.SHA256);

        // Run the pipeline
        rb.start();
        rb.awaitTermination();
        rb.stop();

        // Inspect final slot states (for debugging/monitoring)
        for (int i = 0; i < 4; ++i) {
            System.err.println("Slot " + i + ": status=" + rb.getStatus(i)
                + ", checksum=" + rb.getChecksumVal(i)
                + ", data_size=" + rb.getDataSize(i));
        }

        System.out.println("Pipeline completed successfully.");
    }
}
