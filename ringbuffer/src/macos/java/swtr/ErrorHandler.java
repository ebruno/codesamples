package swtr;

/**
 * Error handler interface — returns non-zero to trigger pipeline shutdown.
 */
@FunctionalInterface
public interface ErrorHandler {
    /**
     * Handle an error condition.
     * @param slotIdx The index of the slot where the error occurred
     * @param status The buffer status at the time of the error
     * @return Non-zero to trigger cooperative cancellation (pipeline shutdown)
     */
    int handle(int slotIdx, BufferStatus status);
}
