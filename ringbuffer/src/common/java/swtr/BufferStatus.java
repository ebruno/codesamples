package swtr;

/**
 * Buffer status enum — 14 values with explicit ordinal assignments.
 * Matches the C specification exactly for cross-language ABI compatibility.
 */
public enum BufferStatus {
    /** Slot is empty and ready to accept new data from read thread */
    READYFORREAD(0),
    /** Data filled; awaiting transform thread to process */
    READYFORTRANSFORM(1),
    /** Transformed data ready; awaiting write thread to flush */
    READYFORWRITE(2),
    /** Read thread is actively writing data into this slot */
    PROCESSING_READ(3),
    /** Transform thread is actively processing this slot */
    PROCESSING_TRANSFORM(4),
    /** Write thread is actively flushing data to output fd */
    PROCESSING_WRITE(5),
    /** Slot has been cleared and is logically empty */
    EMPTY(6),
    /** Slot contains data but not yet marked for next stage */
    FULL(7),
    /** EOF sentinel: last buffer to be transformed */
    LAST_BUFFER_TO_TRANSFORM(8),
    /** EOF sentinel: last buffer to be written */
    LAST_BUFFER_TO_WRITE(9),
    /** Read thread is waiting for available slots */
    PENDING_READ(10),
    /** Transform thread is waiting for work */
    PENDING_TRANSFORM(11),
    /** Write thread is waiting for transformed data */
    PENDING_WRITE(12),
    /** An error occurred in this slot's pipeline stage */
    STATUS_ERROR(13);

    private final int value;

    BufferStatus(int value) {
        this.value = value;
    }

    public int getValue() {
        return value;
    }

    /**
     * Convert integer value to BufferStatus enum.
     * Returns STATUS_ERROR for unknown values.
     */
    public static BufferStatus fromValue(int value) {
        for (BufferStatus status : values()) {
            if (status.value == value) return status;
        }
        return STATUS_ERROR;
    }

    @Override
    public String toString() {
        return name();
    }
}
