package swtr;

/**
 * Buffer status enum — 14 values with explicit ordinal assignments.
 * Matches the C specification exactly for cross-language ABI compatibility.
 */
public enum BufferStatus {
    READYFORREAD(0),
    READYFORTRANSFORM(1),
    READYFORWRITE(2),
    PROCESSING_READ(3),
    PROCESSING_TRANSFORM(4),
    PROCESSING_WRITE(5),
    EMPTY(6),
    FULL(7),
    LAST_BUFFER_TO_TRANSFORM(8),
    LAST_BUFFER_TO_WRITE(9),
    PENDING_READ(10),
    PENDING_TRANSFORM(11),
    PENDING_WRITE(12),
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
