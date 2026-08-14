package swtr;

import java.io.OutputStream;

/**
 * Ring buffer abstract interface — defines the public API for all implementations.
 * 
 * The ring buffer implements a three-stage pipeline:
 * 1. Read stage: reads from input file descriptor into buffer slots
 * 2. Transform stage: applies transform function to slot data in-place
 * 3. Write stage: writes transformed data to output file descriptor
 */
public interface RingBuffer {

    // === Thread Control ===

    /**
     * Start the three-stage pipeline threads.
     * Must not be called more than once without stopping first.
     */
    void start();

    /**
     * Stop the pipeline and wait for threads to terminate.
     * Initiates cooperative cancellation of all pipeline stages.
     */
    void stop();

    /**
     * Wait for all pipeline threads to complete (blocking).
     */
    void awaitTermination() throws InterruptedException;

    // === Configuration ===

    /**
     * Set the file descriptor for read input.
     * @param fd POSIX file descriptor (e.g., from System.in or a file)
     */
    void setReadFd(int fd);

    /**
     * Set the file descriptor for write output.
     * @param fd POSIX file descriptor (e.g., from System.out or a file)
     */
    void setWriteFd(int fd);

    // === Logging Configuration ===

    /**
     * Enable or disable logging.
     */
    void setLoggingEnabled(boolean enabled);

    /**
     * Check if logging is enabled.
     */
    boolean isLoggingEnabled();

    /**
     * Set the output stream for log messages.
     */
    void setOutputStream(OutputStream stream);

    /**
     * Get the current output stream for log messages.
     */
    OutputStream getOutputStream();

    /**
     * Enable or disable read stage logging.
     */
    void setReadLoggingEnabled(boolean enabled);

    /**
     * Check if read stage logging is enabled.
     */
    boolean isReadLoggingEnabled();

    /**
     * Set the verbosity level for read stage logging.
     */
    void setReadVerbosity(LogLevel level);

    /**
     * Get the verbosity level for read stage logging.
     */
    LogLevel getReadVerbosity();

    /**
     * Enable or disable transform stage logging.
     */
    void setTransformLoggingEnabled(boolean enabled);

    /**
     * Check if transform stage logging is enabled.
     */
    boolean isTransformLoggingEnabled();

    /**
     * Set the verbosity level for transform stage logging.
     */
    void setTransformVerbosity(LogLevel level);

    /**
     * Get the verbosity level for transform stage logging.
     */
    LogLevel getTransformVerbosity();

    /**
     * Enable or disable write stage logging.
     */
    void setWriteLoggingEnabled(boolean enabled);

    /**
     * Check if write stage logging is enabled.
     */
    boolean isWriteLoggingEnabled();

    /**
     * Set the verbosity level for write stage logging.
     */
    void setWriteVerbosity(LogLevel level);

    /**
     * Get the verbosity level for write stage logging.
     */
    LogLevel getWriteVerbosity();

    // === Accessors (slot-level) ===

    /**
     * Get the status of a buffer slot.
     * @param slotIdx Slot index (must be < numSlots)
     * @return Buffer status, or STATUS_ERROR if slotIdx is out of bounds
     */
    BufferStatus getStatus(int slotIdx);

    /**
     * Set the status of a buffer slot.
     * @param slotIdx Slot index (must be < numSlots)
     * @param status New buffer status
     */
    void setStatus(int slotIdx, BufferStatus status);

    /**
     * Test if a buffer slot has the specified status.
     * @param slotIdx Slot index (must be < numSlots)
     * @param status Status to test for
     * @return true if slot has the specified status, false otherwise (or if out of bounds)
     */
    boolean testStatus(int slotIdx, BufferStatus status);

    /**
     * Get the checksum algorithm for a buffer slot.
     */
    ChecksumAlgorithm getChecksumAlg(int slotIdx);

    /**
     * Set the checksum algorithm for a buffer slot.
     */
    void setChecksumAlg(int slotIdx, ChecksumAlgorithm alg);

    /**
     * Test if a buffer slot has the specified checksum algorithm.
     */
    boolean testChecksumAlg(int slotIdx, ChecksumAlgorithm alg);

    /**
     * Get the checksum value for a buffer slot.
     */
    int getChecksumVal(int slotIdx);

    /**
     * Set the checksum value for a buffer slot.
     */
    void setChecksumVal(int slotIdx, int val);

    /**
     * Test if a buffer slot has the specified checksum value.
     */
    boolean testChecksumVal(int slotIdx, int val);

    /**
     * Get the maximum data buffer size for a slot.
     */
    int getMaxSize(int slotIdx);

    /**
     * Set the maximum data buffer size for a slot.
     */
    void setMaxSize(int slotIdx, int size);

    /**
     * Get the current data buffer size for a slot.
     */
    int getDataSize(int slotIdx);

    /**
     * Set the current data buffer size for a slot.
     */
    void setDataSize(int slotIdx, int size);

    /**
     * Get the current transformed data buffer size for a slot.
     */
    int getTransformedSize(int slotIdx);

    /**
     * Set the current transformed data buffer size for a slot.
     */
    void setTransformedSize(int slotIdx, int size);
}
