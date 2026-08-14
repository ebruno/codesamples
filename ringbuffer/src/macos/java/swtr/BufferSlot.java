package swtr;

/**
 * Ring buffer slot — thread-safe data structure with volatile fields.
 * 
 * Atomic-equivalent distinction:
 * - bufferIdx, maxDataBufferSize, and data are set once during construction (no volatile needed)
 * - status, dataBufferSize, transformedDataBufferSize, checksumAlg, and checksumVal 
 *   are read/written by multiple pipeline threads (use volatile for thread safety)
 */
public class BufferSlot {
    // Non-atomic fields (set once during construction)
    private final int bufferIdx;
    private final int maxDataBufferSize;
    private final byte[] data;

    // Atomic-equivalent fields (volatile for cross-thread visibility)
    private volatile BufferStatus status;
    private volatile int dataBufferSize;
    private volatile int transformedDataBufferSize;
    private volatile ChecksumAlgorithm checksumAlg;
    private volatile int checksumVal;

    /**
     * Create a new buffer slot.
     * @param bufferIdx The slot index (set once, never modified)
     * @param maxDataBufferSize Maximum capacity of the data buffer (set once, never modified)
     */
    public BufferSlot(int bufferIdx, int maxDataBufferSize) {
        this.bufferIdx = bufferIdx;
        this.maxDataBufferSize = maxDataBufferSize;
        this.data = new byte[maxDataBufferSize];
        this.status = BufferStatus.READYFORREAD;
        this.dataBufferSize = 0;
        this.transformedDataBufferSize = 0;
        this.checksumAlg = ChecksumAlgorithm.NONE;
        this.checksumVal = 0;
    }

    // === Non-atomic getters (no synchronization needed) ===

    public int getBufferIdx() {
        return bufferIdx;
    }

    public int getMaxDataBufferSize() {
        return maxDataBufferSize;
    }

    /**
     * Get the data buffer reference.
     * Note: The caller must synchronize externally if modifying the array contents.
     */
    public byte[] getData() {
        return data;
    }

    // === Atomic-equivalent getters/setters (volatile access) ===

    public BufferStatus getStatus() {
        return status;
    }

    public void setStatus(BufferStatus status) {
        this.status = status;
    }

    public int getDataBufferSize() {
        return dataBufferSize;
    }

    public void setDataBufferSize(int size) {
        this.dataBufferSize = size;
    }

    public int getTransformedDataBufferSize() {
        return transformedDataBufferSize;
    }

    public void setTransformedDataBufferSize(int size) {
        this.transformedDataBufferSize = size;
    }

    public ChecksumAlgorithm getChecksumAlg() {
        return checksumAlg;
    }

    public void setChecksumAlg(ChecksumAlgorithm alg) {
        this.checksumAlg = alg;
    }

    public int getChecksumVal() {
        return checksumVal;
    }

    public void setChecksumVal(int val) {
        this.checksumVal = val;
    }

    // === Test methods (equality checks) ===

    public boolean testStatus(BufferStatus status) {
        return this.status == status;
    }

    public boolean testChecksumAlg(ChecksumAlgorithm alg) {
        return this.checksumAlg == alg;
    }

    public boolean testChecksumVal(int val) {
        return this.checksumVal == val;
    }

    /**
     * Clear slot data (used after write to reset for next read).
     */
    public void clear() {
        synchronized (data) {
            java.util.Arrays.fill(data, (byte) 0);
        }
        this.dataBufferSize = 0;
        this.transformedDataBufferSize = 0;
    }

    @Override
    public String toString() {
        return "BufferSlot{" +
                "bufferIdx=" + bufferIdx +
                ", status=" + status +
                ", dataSize=" + dataBufferSize +
                ", transformedSize=" + transformedDataBufferSize +
                '}';
    }
}
