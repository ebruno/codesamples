package swtr;

/**
 * Log level enum — 6 values with explicit ordinal assignments.
 */
public enum LogLevel {
    /** Verbose internal state transitions */
    TRACE(0),
    /** Detailed operational information */
    DEBUG(1),
    /** General pipeline events (default) */
    INFO(2),
    /** Non-fatal conditions that may indicate issues */
    WARNING(3),
    /** Recoverable error conditions */
    ERROR(4),
    /** Fatal errors requiring pipeline shutdown */
    CRITICAL(5);

    private final int value;

    LogLevel(int value) {
        this.value = value;
    }

    public int getValue() {
        return value;
    }

    /**
     * Convert integer value to LogLevel enum.
     * Returns INFO for unknown values.
     */
    public static LogLevel fromValue(int value) {
        for (LogLevel level : values()) {
            if (level.value == value) return level;
        }
        return INFO;
    }

    @Override
    public String toString() {
        return name();
    }
}
