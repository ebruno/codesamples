package swtr;

/**
 * Log level enum — 6 values with explicit ordinal assignments.
 */
public enum LogLevel {
    TRACE(0),
    DEBUG(1),
    INFO(2),
    WARNING(3),
    ERROR(4),
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
