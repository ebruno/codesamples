package swtr;

import java.io.IOException;
import java.io.OutputStream;
import java.nio.ByteBuffer;
import java.nio.channels.Channels;
import java.nio.channels.ReadableByteChannel;
import java.nio.channels.WritableByteChannel;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Concrete ring buffer implementation — three-stage pipeline with status-driven coordination.
 * 
 * Pipeline stages:
 * 1. Read: reads from input FD into buffer slots, marks READYFORTRANSFORM
 * 2. Transform: applies transform function in-place, marks READYFORWRITE
 * 3. Write: writes transformed data to output FD, marks READYFORREAD
 * 
 * Status transitions:
 *   readyforread → processing_read → readyfortransform → processing_transform 
 *                → readyforwrite → processing_write → readyforread
 *   LAST_BUFFER_TO_TRANSFORM → LAST_BUFFER_TO_WRITE (EOF propagation)
 */
public class SwtrRingBuffer implements RingBuffer {

    // === Constants (from common spec) ===
    public static final int MIN_NUMBER_SLOTS = 1;
    public static final int DEFAULT_BUFFER_SIZE = 4096;
    public static final int MIN_BUFFER_SIZE = 1;

    // === Slot storage ===
    private final BufferSlot[] slots;
    private final int numSlots;

    // === Index tracking — one independent counter per pipeline stage (AtomicInteger for thread safety) ===
    private final AtomicInteger readIndex = new AtomicInteger(0);
    private final AtomicInteger transformIndex = new AtomicInteger(0);
    private final AtomicInteger writeIndex = new AtomicInteger(0);

    // === File descriptors (AtomicInteger for cross-thread access) ===
    private final AtomicInteger readFd = new AtomicInteger(-1);
    private final AtomicInteger writeFd = new AtomicInteger(-1);

    // === Buffer size per slot ===
    private final int bufferSize;

    // === Pipeline functions (set once at construction) ===
    private final ErrorHandler errorHandler;
    private final TransformFunction transformFn;

    // === Thread management ===
    private volatile Thread readThread;
    private volatile Thread transformThread;
    private volatile Thread writeThread;

    // === Synchronization primitives ===
    private final Object syncLock = new Object();
    private volatile boolean running;

    // === Logging configuration (AtomicBoolean for runtime reconfiguration) ===
    private final AtomicBoolean loggingEnabled = new AtomicBoolean(false);
    private final AtomicBoolean readLoggingEnabled = new AtomicBoolean(false);
    private final AtomicBoolean transformLoggingEnabled = new AtomicBoolean(false);
    private final AtomicBoolean writeLoggingEnabled = new AtomicBoolean(false);
    private volatile LogLevel readVerbosity = LogLevel.INFO;
    private volatile LogLevel transformVerbosity = LogLevel.INFO;
    private volatile LogLevel writeVerbosity = LogLevel.INFO;

    // === Output stream (reference, not pointer) ===
    private volatile OutputStream outputStream = System.err;

    // === Log lock (separate from syncLock to avoid nested locking) ===
    private final Object logLock = new Object();

    // === Guard against double-start ===
    private volatile boolean started;

    // === Cached NIO channels (created once from FDs, reused throughout lifecycle) ===
    private volatile java.nio.channels.FileChannel readChannel;
    private volatile java.nio.channels.FileChannel writeChannel;

    /**
     * Create a new SwtrRingBuffer instance.
     * 
     * @param numSlots Number of buffer slots (must be >= MIN_NUMBER_SLOTS)
     * @param initialStatus Initial status for all slots (typically READYFORREAD)
     * @param bufferSize Size of each slot's data buffer (must be >= MIN_BUFFER_SIZE)
     * @param errorHandler Error handler callback; null for default error handling
     * @param transformFn Transform function; null for identity transform (no-op)
     * @throws IllegalArgumentException if numSlots < MIN_NUMBER_SLOTS or bufferSize < MIN_BUFFER_SIZE
     */
    public SwtrRingBuffer(int numSlots, BufferStatus initialStatus, int bufferSize,
                          ErrorHandler errorHandler, TransformFunction transformFn) {
        if (numSlots < MIN_NUMBER_SLOTS) {
            throw new IllegalArgumentException(
                "numSlots must be >= " + MIN_NUMBER_SLOTS + ", got: " + numSlots);
        }
        if (bufferSize < MIN_BUFFER_SIZE) {
            throw new IllegalArgumentException(
                "bufferSize must be >= " + MIN_BUFFER_SIZE + ", got: " + bufferSize);
        }

        this.numSlots = numSlots;
        this.bufferSize = bufferSize;
        this.errorHandler = errorHandler;
        this.transformFn = transformFn;

        // Initialize slots with initial status
        this.slots = new BufferSlot[numSlots];
        for (int i = 0; i < numSlots; i++) {
            slots[i] = new BufferSlot(i, bufferSize);
            slots[i].setStatus(initialStatus);
        }

        // Initialize file descriptors to -1 (invalid)
        this.readFd.set(-1);
        this.writeFd.set(-1);

        // Initialize running state
        this.running = false;
        this.started = false;
    }

    // === Thread Control ===

    @Override
    public void start() {
        synchronized (syncLock) {
            if (started) {
                log(LogLevel.WARNING, "Pipeline already started — ignoring duplicate start() call");
                return;
            }
            started = true;
            running = true;

            // Initialize cached NIO channels from current FD values (FDs are set before start)
            int rfd = readFd.get();
            if (rfd >= 0) {
                readChannel = getFileChannelForRead(rfd);
            }
            int wfd = writeFd.get();
            if (wfd >= 0) {
                writeChannel = getFileChannelForWrite(wfd);
            }

            // Create and start read thread
            readThread = new Thread(this::readLoop, "ringbuffer-read");
            readThread.setDaemon(true);

            // Create and start transform thread
            transformThread = new Thread(this::transformLoop, "ringbuffer-transform");
            transformThread.setDaemon(true);

            // Create and start write thread
            writeThread = new Thread(this::writeLoop, "ringbuffer-write");
            writeThread.setDaemon(true);

            // Start all threads
            readThread.start();
            transformThread.start();
            writeThread.start();

            log(LogLevel.INFO, "Pipeline started: read=" + readThread.getName()
                    + ", transform=" + transformThread.getName()
                    + ", write=" + writeThread.getName());
        }
    }

    @Override
    public void stop() {
        synchronized (syncLock) {
            running = false;

            // Interrupt all threads
            if (readThread != null) readThread.interrupt();
            if (transformThread != null) transformThread.interrupt();
            if (writeThread != null) writeThread.interrupt();

            // Notify condition variable to wake any waiting threads
            synchronized (syncLock) {
                syncLock.notifyAll();
            }

            log(LogLevel.INFO, "Pipeline stop signal sent");
        }
    }

    @Override
    public void awaitTermination() throws InterruptedException {
        if (readThread != null) readThread.join();
        if (transformThread != null) transformThread.join();
        if (writeThread != null) writeThread.join();
        log(LogLevel.INFO, "All pipeline threads terminated");
    }

    // === Configuration ===

    @Override
    public void setReadFd(int fd) {
        readFd.set(fd);
    }

    @Override
    public void setWriteFd(int fd) {
        writeFd.set(fd);
    }

    /**
     * Set read channel directly (bypasses FD-based channel creation).
     * Useful for JDK 16+ where reflection on FileDescriptor.fd is restricted.
     */
    public void setReadChannel(java.nio.channels.FileChannel channel) {
        this.readChannel = channel;
    }

    /**
     * Set write channel directly (bypasses FD-based channel creation).
     * Useful for JDK 16+ where reflection on FileDescriptor.fd is restricted.
     */
    public void setWriteChannel(java.nio.channels.FileChannel channel) {
        this.writeChannel = channel;
    }

    // === Logging Configuration ===

    @Override
    public void setLoggingEnabled(boolean enabled) {
        loggingEnabled.set(enabled);
    }

    @Override
    public boolean isLoggingEnabled() {
        return loggingEnabled.get();
    }

    @Override
    public void setOutputStream(OutputStream stream) {
        this.outputStream = stream;
    }

    @Override
    public OutputStream getOutputStream() {
        return outputStream;
    }

    @Override
    public void setReadLoggingEnabled(boolean enabled) {
        readLoggingEnabled.set(enabled);
    }

    @Override
    public boolean isReadLoggingEnabled() {
        return readLoggingEnabled.get();
    }

    @Override
    public void setReadVerbosity(LogLevel level) {
        readVerbosity = level;
    }

    @Override
    public LogLevel getReadVerbosity() {
        return readVerbosity;
    }

    @Override
    public void setTransformLoggingEnabled(boolean enabled) {
        transformLoggingEnabled.set(enabled);
    }

    @Override
    public boolean isTransformLoggingEnabled() {
        return transformLoggingEnabled.get();
    }

    @Override
    public void setTransformVerbosity(LogLevel level) {
        transformVerbosity = level;
    }

    @Override
    public LogLevel getTransformVerbosity() {
        return transformVerbosity;
    }

    @Override
    public void setWriteLoggingEnabled(boolean enabled) {
        writeLoggingEnabled.set(enabled);
    }

    @Override
    public boolean isWriteLoggingEnabled() {
        return writeLoggingEnabled.get();
    }

    @Override
    public void setWriteVerbosity(LogLevel level) {
        writeVerbosity = level;
    }

    @Override
    public LogLevel getWriteVerbosity() {
        return writeVerbosity;
    }

    // === Accessors (with bounds checking) ===

    @Override
    public BufferStatus getStatus(int slotIdx) {
        if (slotIdx < 0 || slotIdx >= numSlots) return BufferStatus.STATUS_ERROR;
        return slots[slotIdx].getStatus();
    }

    @Override
    public void setStatus(int slotIdx, BufferStatus status) {
        if (slotIdx < 0 || slotIdx >= numSlots) return;
        slots[slotIdx].setStatus(status);
    }

    @Override
    public boolean testStatus(int slotIdx, BufferStatus status) {
        if (slotIdx < 0 || slotIdx >= numSlots) return false;
        return slots[slotIdx].testStatus(status);
    }

    @Override
    public ChecksumAlgorithm getChecksumAlg(int slotIdx) {
        if (slotIdx < 0 || slotIdx >= numSlots) return ChecksumAlgorithm.NONE;
        return slots[slotIdx].getChecksumAlg();
    }

    @Override
    public void setChecksumAlg(int slotIdx, ChecksumAlgorithm alg) {
        if (slotIdx < 0 || slotIdx >= numSlots) return;
        slots[slotIdx].setChecksumAlg(alg);
    }

    @Override
    public boolean testChecksumAlg(int slotIdx, ChecksumAlgorithm alg) {
        if (slotIdx < 0 || slotIdx >= numSlots) return false;
        return slots[slotIdx].testChecksumAlg(alg);
    }

    @Override
    public int getChecksumVal(int slotIdx) {
        if (slotIdx < 0 || slotIdx >= numSlots) return 0;
        return slots[slotIdx].getChecksumVal();
    }

    @Override
    public void setChecksumVal(int slotIdx, int val) {
        if (slotIdx < 0 || slotIdx >= numSlots) return;
        slots[slotIdx].setChecksumVal(val);
    }

    @Override
    public boolean testChecksumVal(int slotIdx, int val) {
        if (slotIdx < 0 || slotIdx >= numSlots) return false;
        return slots[slotIdx].testChecksumVal(val);
    }

    @Override
    public int getMaxSize(int slotIdx) {
        if (slotIdx < 0 || slotIdx >= numSlots) return 0;
        return slots[slotIdx].getMaxDataBufferSize();
    }

    @Override
    public void setMaxSize(int slotIdx, int size) {
        // maxDataBufferSize is immutable after construction — silently ignore
    }

    @Override
    public int getDataSize(int slotIdx) {
        if (slotIdx < 0 || slotIdx >= numSlots) return 0;
        return slots[slotIdx].getDataBufferSize();
    }

    @Override
    public void setDataSize(int slotIdx, int size) {
        if (slotIdx < 0 || slotIdx >= numSlots) return;
        slots[slotIdx].setDataBufferSize(size);
    }

    @Override
    public int getTransformedSize(int slotIdx) {
        if (slotIdx < 0 || slotIdx >= numSlots) return 0;
        return slots[slotIdx].getTransformedDataBufferSize();
    }

    @Override
    public void setTransformedSize(int slotIdx, int size) {
        if (slotIdx < 0 || slotIdx >= numSlots) return;
        slots[slotIdx].setTransformedDataBufferSize(size);
    }

    // === Pipeline Logic ===

    /**
     * Read loop — reads from input FD into buffer slots.
     * Status transitions: READYFORREAD → PROCESSING_READ → READYFORTRANSFORM
     * EOF handling: sets LAST_BUFFER_TO_TRANSFORM, advances index, notifies all.
     */
    private void readLoop() {
        try {
            while (running) {
                // Get next slot index using readIndex with modulo wrapping
                int slotIdx = readIndex.get() % numSlots;
                BufferSlot slot = slots[slotIdx];

                // Wait for slot to be ready for read
                synchronized (syncLock) {
                    while (running && slot.getStatus() != BufferStatus.READYFORREAD) {
                        if (slot.getStatus() == BufferStatus.STATUS_ERROR) {
                            handleSlotError(slotIdx, slot);
                            break;
                        }
                        syncLock.wait(100); // 100ms timeout to allow periodic running check
                    }
                    if (!running) break;
                }

                // Mark slot as processing read
                slot.setStatus(BufferStatus.PROCESSING_READ);

                // Read from input FD using NIO channel
                int fd = readFd.get();
                // Use cached NIO channel for reading (created once in start() from FD, or set directly)
                java.nio.channels.FileChannel channel = readChannel;
                if (channel == null && fd < 0) {
                    log(LogLevel.WARNING, "Read channel not set — skipping read");
                    slot.setStatus(BufferStatus.READYFORREAD);
                    continue;
                }
                if (channel == null) {
                    log(LogLevel.WARNING, "Read channel not initialized — skipping read");
                    slot.setStatus(BufferStatus.READYFORREAD);
                    continue;
                }

                ByteBuffer buffer = ByteBuffer.allocate(bufferSize);
                int bytesRead;
                try {
                    bytesRead = channel.read(buffer);

                    if (bytesRead == 0) {
                        // EOF detected — propagate LAST_BUFFER_TO_TRANSFORM
                        log(LogLevel.INFO, "EOF detected at read stage");
                        slot.setStatus(BufferStatus.LAST_BUFFER_TO_TRANSFORM);
                        slot.setDataBufferSize(0);

                        // Advance read index and notify all waiting threads
                        readIndex.incrementAndGet();
                        synchronized (syncLock) {
                            syncLock.notifyAll();
                        }

                        // Break the loop — EOF means end of input
                        break;
                    } else if (bytesRead < 0) {
                        // Error condition
                        slot.setStatus(BufferStatus.STATUS_ERROR);
                        handleSlotError(slotIdx, slot);
                        break;
                    } else {
                        // Successfully read data
                        buffer.flip();
                        byte[] data = new byte[bytesRead];
                        buffer.get(data);

                        // Copy data into slot (synchronized on slot's data array)
                        synchronized (slot.getData()) {
                            System.arraycopy(data, 0, slot.getData(), 0, bytesRead);
                        }

                        slot.setDataBufferSize(bytesRead);
                        slot.setStatus(BufferStatus.READYFORTRANSFORM);

                        // Advance read index and notify all waiting threads
                        readIndex.incrementAndGet();
                        synchronized (syncLock) {
                            syncLock.notifyAll();
                        }

                        log(LogLevel.TRACE, "Read " + bytesRead + " bytes into slot " + slotIdx);
                    }
                } catch (IOException e) {
                        log(LogLevel.ERROR, "Read error: " + e.getMessage());
                        slot.setStatus(BufferStatus.STATUS_ERROR);
                        handleSlotError(slotIdx, slot);
                    }
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            log(LogLevel.INFO, "Read thread interrupted");
        }
    }

    /**
     * Transform loop — applies transform function to slot data in-place.
     * Status transitions: READYFORTRANSFORM → PROCESSING_TRANSFORM → READYFORWRITE
     * EOF handling: receives LAST_BUFFER_TO_TRANSFORM, converts to LAST_BUFFER_TO_WRITE.
     */
    private void transformLoop() {
        try {
            while (running) {
                // Get next slot index using transformIndex with modulo wrapping
                int slotIdx = transformIndex.get() % numSlots;
                BufferSlot slot = slots[slotIdx];

                // Wait for slot to be ready for transform
                synchronized (syncLock) {
                    while (running && slot.getStatus() != BufferStatus.READYFORTRANSFORM
                            && slot.getStatus() != BufferStatus.LAST_BUFFER_TO_TRANSFORM) {
                        if (slot.getStatus() == BufferStatus.STATUS_ERROR) {
                            handleSlotError(slotIdx, slot);
                            break;
                        }
                        syncLock.wait(100); // 100ms timeout to allow periodic running check
                    }
                    if (!running) break;

                    BufferStatus status = slot.getStatus();
                    if (status == BufferStatus.STATUS_ERROR) break;

                    // Check for EOF propagation
                    if (status == BufferStatus.LAST_BUFFER_TO_TRANSFORM) {
                        log(LogLevel.INFO, "EOF propagation: LAST_BUFFER_TO_TRANSFORM → LAST_BUFFER_TO_WRITE");
                        slot.setStatus(BufferStatus.LAST_BUFFER_TO_WRITE);

                        // Advance transform index and notify all waiting threads
                        transformIndex.incrementAndGet();
                        syncLock.notifyAll();

                        // Break the loop — EOF means end of transform pipeline
                        break;
                    }
                }

                // Mark slot as processing transform
                slot.setStatus(BufferStatus.PROCESSING_TRANSFORM);

                // Apply transform function (in-place modification)
                if (transformFn != null) {
                    byte[] data = slot.getData();
                    int[] sizeHolder = new int[]{slot.getDataBufferSize()};

                    try {
                        transformFn.apply(data, sizeHolder);

                        // Store transformed size
                        slot.setTransformedDataBufferSize(sizeHolder[0]);
                    } catch (Exception e) {
                        log(LogLevel.ERROR, "Transform error: " + e.getMessage());
                        slot.setStatus(BufferStatus.STATUS_ERROR);
                        handleSlotError(slotIdx, slot);
                        continue;
                    }
                } else {
                    // No transform function — identity (copy data size to transformed size)
                    slot.setTransformedDataBufferSize(slot.getDataBufferSize());
                }

                // Mark slot as ready for write and advance index
                slot.setStatus(BufferStatus.READYFORWRITE);

                // Advance transform index and notify all waiting threads
                transformIndex.incrementAndGet();
                synchronized (syncLock) {
                    syncLock.notifyAll();
                }

                log(LogLevel.TRACE, "Transformed slot " + slotIdx + ", size="
                        + slot.getTransformedDataBufferSize());
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            log(LogLevel.INFO, "Transform thread interrupted");
        }
    }

    /**
     * Write loop — writes transformed data to output FD.
     * Status transitions: READYFORWRITE → PROCESSING_WRITE → READYFORREAD
     * EOF handling: receives LAST_BUFFER_TO_WRITE, flushes output, terminates.
     */
    private void writeLoop() {
        try {
            while (running) {
                // Get next slot index using writeIndex with modulo wrapping
                int slotIdx = writeIndex.get() % numSlots;
                BufferSlot slot = slots[slotIdx];

                // Wait for slot to be ready for write
                synchronized (syncLock) {
                    while (running && slot.getStatus() != BufferStatus.READYFORWRITE
                            && slot.getStatus() != BufferStatus.LAST_BUFFER_TO_WRITE) {
                        if (slot.getStatus() == BufferStatus.STATUS_ERROR) {
                            handleSlotError(slotIdx, slot);
                            break;
                        }
                        syncLock.wait(100); // 100ms timeout to allow periodic running check
                    }
                    if (!running) break;

                    BufferStatus status = slot.getStatus();
                    if (status == BufferStatus.STATUS_ERROR) break;

                    // Check for EOF propagation from transform stage
                    if (status == BufferStatus.LAST_BUFFER_TO_WRITE) {
                        log(LogLevel.INFO, "EOF propagation: flushing output and terminating");

                        // Flush the output channel
                        try {
                            if (writeChannel != null) {
                                writeChannel.close();
                            }
                        } catch (IOException e) {
                            log(LogLevel.WARNING, "Error closing output: " + e.getMessage());
                        }

                        // Mark slot as ready for read (cleanup) and advance index
                        slot.setStatus(BufferStatus.READYFORREAD);

                        // Advance write index and notify all waiting threads
                        writeIndex.incrementAndGet();
                        syncLock.notifyAll();

                        // Break the loop — EOF means end of write pipeline
                        break;
                    }
                }

                // Mark slot as processing write
                slot.setStatus(BufferStatus.PROCESSING_WRITE);

                // Write transformed data to output FD
                int fd = writeFd.get();
                java.nio.channels.FileChannel channel = writeChannel;
                if (channel == null && fd < 0) {
                    log(LogLevel.WARNING, "Write channel not set — skipping write");
                    slot.setStatus(BufferStatus.READYFORREAD);

                    // Advance write index and notify all waiting threads
                    writeIndex.incrementAndGet();
                    synchronized (syncLock) {
                        syncLock.notifyAll();
                    }

                    continue;
                }

                // Get transformed data size and write to output FD
                int transformedSize = slot.getTransformedDataBufferSize();
                if (transformedSize > 0) {
                    byte[] data = slot.getData();

                    try {
                        // Write using cached NIO channel (created once in start() from FD, or set directly)
                        java.nio.ByteBuffer buffer = java.nio.ByteBuffer.wrap(data, 0, transformedSize);
                        while (buffer.hasRemaining()) {
                            channel.write(buffer);
                        }

                        log(LogLevel.TRACE, "Wrote " + transformedSize + " bytes from slot " + slotIdx);
                    } catch (IOException e) {
                        log(LogLevel.ERROR, "Write error: " + e.getMessage());
                        slot.setStatus(BufferStatus.STATUS_ERROR);
                        handleSlotError(slotIdx, slot);
                        continue;
                    }
                }

                // Clear slot data and reset sizes for next use
                slot.clear();
                slot.setStatus(BufferStatus.READYFORREAD);

                // Advance write index and notify all waiting threads
                writeIndex.incrementAndGet();
                synchronized (syncLock) {
                    syncLock.notifyAll();
                }
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            log(LogLevel.INFO, "Write thread interrupted");
        }
    }

    /**
     * Handle slot error — calls error handler if set, triggers pipeline shutdown if non-zero.
     */
    private void handleSlotError(int slotIdx, BufferSlot slot) {
        if (errorHandler != null) {
            int result = errorHandler.handle(slotIdx, slot.getStatus());
            if (result != 0) {
                log(LogLevel.ERROR, "Error handler returned non-zero (" + result + ") — triggering pipeline shutdown");
                stop();
            }
        } else {
            log(LogLevel.ERROR, "Error in slot " + slotIdx + " — no error handler set");
        }
    }

    // === Logging Utility ===

    /**
     * Log a message if logging is enabled and verbosity level permits.
     */
    private void log(LogLevel level, String message) {
        if (!loggingEnabled.get()) return;

        // Check verbosity level (only log if message level >= configured level)
        if (level.ordinal() < LogLevel.INFO.ordinal()) return;

        synchronized (logLock) {
            try {
                String logMessage = "[" + level + "] " + message;
                outputStream.write((logMessage + "\n").getBytes("UTF-8"));
                outputStream.flush();
            } catch (IOException e) {
                System.err.println("[ERROR] Failed to write log: " + e.getMessage());
            }
        }
    }

    @Override
    public String toString() {
        return "SwtrRingBuffer{" +
                "numSlots=" + numSlots +
                ", bufferSize=" + bufferSize +
                ", running=" + running +
                ", readIndex=" + readIndex.get() +
                ", transformIndex=" + transformIndex.get() +
                ", writeIndex=" + writeIndex.get() +
                '}';
    }

    /**
     * Get a FileChannel for reading from an int file descriptor.
     * Uses reflection to create a FileInputStream(FileDescriptor) — the int-arg constructor
     * was removed in Java 17+, so we create a FileDescriptor object and set its internal fd field.
     */
    private java.nio.channels.FileChannel getFileChannelForRead(int fd) {
        try {
            // Create a FileDescriptor object (public no-arg constructor)
            java.io.FileDescriptor fdObj = new java.io.FileDescriptor();
            // Set the private 'fd' int field via reflection
            java.lang.reflect.Field fdField = java.io.FileDescriptor.class.getDeclaredField("fd");
            fdField.setAccessible(true);
            fdField.setInt(fdObj, fd);
            // Use the protected FileInputStream(FileDescriptor) constructor
            java.lang.reflect.Constructor<java.io.FileInputStream> constructor =
                java.io.FileInputStream.class.getDeclaredConstructor(java.io.FileDescriptor.class);
            constructor.setAccessible(true);
            java.io.FileInputStream fis = constructor.newInstance(fdObj);
            return fis.getChannel();
        } catch (Exception e) {
            System.err.println("ERROR: Failed to create FileChannel for read FD " + fd + ": " + e.getMessage());
            return null;
        }
    }

    /**
     * Get a FileChannel for writing to an int file descriptor.
     * Uses reflection to create a FileOutputStream(FileDescriptor) — the int-arg constructor
     * was removed in Java 17+, so we create a FileDescriptor object and set its internal fd field.
     */
    private java.nio.channels.FileChannel getFileChannelForWrite(int fd) {
        try {
            // Create a FileDescriptor object (public no-arg constructor)
            java.io.FileDescriptor fdObj = new java.io.FileDescriptor();
            // Set the private 'fd' int field via reflection
            java.lang.reflect.Field fdField = java.io.FileDescriptor.class.getDeclaredField("fd");
            fdField.setAccessible(true);
            fdField.setInt(fdObj, fd);
            // Use the protected FileOutputStream(FileDescriptor) constructor
            java.lang.reflect.Constructor<java.io.FileOutputStream> constructor =
                java.io.FileOutputStream.class.getDeclaredConstructor(java.io.FileDescriptor.class);
            constructor.setAccessible(true);
            java.io.FileOutputStream fos = constructor.newInstance(fdObj);
            return fos.getChannel();
        } catch (Exception e) {
            System.err.println("ERROR: Failed to create FileChannel for FD " + fd + ": " + e.getMessage());
            return null;
        }
    }
}
