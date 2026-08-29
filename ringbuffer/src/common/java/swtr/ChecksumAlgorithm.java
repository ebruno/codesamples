package swtr;

/**
 * Checksum algorithm enum — 4 values with explicit ordinal assignments.
 */
public enum ChecksumAlgorithm {
    /** No checksum computation */
    NONE(0),
    /** MD5 hash (128-bit) */
    MD5(1),
    /** SHA-256 hash (256-bit) */
    SHA256(2),
    /** SHA-512 hash (512-bit) */
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
