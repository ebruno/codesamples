package swtr;

/**
 * Checksum algorithm enum — 4 values with explicit ordinal assignments.
 */
public enum ChecksumAlgorithm {
    NONE(0),
    MD5(1),
    SHA256(2),
    SHA512(3);

    private final int value;

    ChecksumAlgorithm(int value) {
        this.value = value;
    }

    public int getValue() {
        return value;
    }

    /**
     * Convert integer value to ChecksumAlgorithm enum.
     * Returns NONE for unknown values.
     */
    public static ChecksumAlgorithm fromValue(int value) {
        for (ChecksumAlgorithm alg : values()) {
            if (alg.value == value) return alg;
        }
        return NONE;
    }

    @Override
    public String toString() {
        return name();
    }
}
