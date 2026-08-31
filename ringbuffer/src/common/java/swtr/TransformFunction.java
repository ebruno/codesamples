package swtr;

/**
 * Transform function interface — modifies data buffer in-place.
 * Uses int[] as a size holder because Java does not support pass-by-reference for primitives.
 */
@FunctionalInterface
public interface TransformFunction {
    /**
     * Apply transform to data buffer in-place.
     * @param data The data buffer to modify (modified directly)
     * @param sizeHolder Single-element array holding the current data size; updated with new size
     */
    void apply(byte[] data, int[] sizeHolder);
}
