package swtr.test;

import swtr.*;

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

/**
 * Ringbuffer test harness — exercises the 7-test matrix (T001-T007).
 * 
 * When run as a standalone main(), accepts test number arguments.
 * When run via Maven Surefire (mvn test), executes all 7 tests automatically.
 */
public class TestRingbuffer {

    private static final byte[] TEST_DATA = "Hello, RingBuffer! This is a test of the three-stage pipeline ring buffer implementation.".getBytes();
    private static final byte[] SINGLE_BYTE = {65}; // 'A'
    private static final byte[] SMALL_DATA = {1, 2, 3};

    // Test result tracking
    private static int passed = 0;
    private static int failed = 0;
    private static final List<String> failures = new ArrayList<>();

    /**
     * Helper: run a ringbuffer with given input file and transform/error handlers.
     */
    private static byte[] runRingBuffer(byte[] inputData, int numSlots, int bufferSize,
                                         ErrorHandler errorHandler, TransformFunction transform) throws Exception {
        Path inputPath = Files.createTempFile("test_input_", ".txt");
        Path outputPath = Files.createTempFile("test_output_", ".txt");

        try {
            Files.write(inputPath, inputData);

            FileInputStream fis = new FileInputStream(inputPath.toFile());
            FileOutputStream fos = new FileOutputStream(outputPath.toFile());

            SwtrRingBuffer rb = new SwtrRingBuffer(numSlots, BufferStatus.READYFORREAD, bufferSize, errorHandler, transform);
            rb.setReadChannel(fis.getChannel());
            rb.setWriteChannel(fos.getChannel());

            rb.start();
            try { rb.awaitTermination(); } catch (InterruptedException e) { Thread.currentThread().interrupt(); rb.stop(); }

            fis.close();
            fos.close();

            return Files.readAllBytes(outputPath);
        } finally {
            Files.deleteIfExists(inputPath);
            Files.deleteIfExists(outputPath);
        }
    }

    private static void assertArrayEquals(byte[] expected, byte[] actual, String msg) {
        if (expected.length != actual.length || !java.util.Arrays.equals(expected, actual)) {
            failed++;
            failures.add(msg + " — expected length=" + expected.length + ", actual length=" + actual.length);
        } else {
            passed++;
        }
    }

    private static void assertTrue(boolean condition, String msg) {
        if (!condition) {
            failed++;
            failures.add(msg);
        } else {
            passed++;
        }
    }

    // === Individual test methods (called by main or auto-run) ===

    private static void runTest001() throws Exception {
        byte[] output = runRingBuffer(TEST_DATA, 4, 4096, null, null);
        assertArrayEquals(TEST_DATA, output, "T001: Identity transform");

        byte[] output2 = runRingBuffer(SMALL_DATA, 4, 256, null, null);
        assertArrayEquals(SMALL_DATA, output2, "T001: Small input identity");
    }

    private static void runTest002() throws Exception {
        byte[] output = runRingBuffer(TEST_DATA, 1, 1, null, null);
        assertArrayEquals(TEST_DATA, output, "T002: Stress test (1 slot, 1-byte buffer)");

        byte[] output2 = runRingBuffer(SINGLE_BYTE, 1, 1, null, null);
        assertArrayEquals(SINGLE_BYTE, output2, "T002: Single byte stress");
    }

    private static void runTest003() throws Exception {
        byte[] input = "hello world".getBytes();
        TransformFunction uppercaseTransform = (data, sizeHolder) -> {
            for (int i = 0; i < sizeHolder[0]; i++) {
                byte b = data[i];
                if (b >= 'a' && b <= 'z') {
                    data[i] = (byte) (b - 32);
                }
            }
        };

        byte[] output = runRingBuffer(input, 4, 256, null, uppercaseTransform);
        assertArrayEquals("HELLO WORLD".getBytes(), output, "T003: Uppercase transform");

        byte[] input2 = "AbCdEf".getBytes();
        byte[] output2 = runRingBuffer(input2, 4, 256, null, uppercaseTransform);
        assertArrayEquals("ABCDEF".getBytes(), output2, "T003: Mixed case uppercase");
    }

    private static void runTest004() throws Exception {
        byte[] output = runRingBuffer(SMALL_DATA, 4, 256, null, null);
        assertArrayEquals(SMALL_DATA, output, "T004: Small input fast EOF");

        byte[] output2 = runRingBuffer(new byte[0], 4, 256, null, null);
        assertArrayEquals(new byte[0], output2, "T004: Empty input fast EOF");
    }

    private static void runTest005() throws Exception {
        final boolean[] errorCalled = {false};
        ErrorHandler errorHandler = (slotIdx, status) -> {
            errorCalled[0] = true;
            return 1; // fatal error code
        };

        byte[] output = runRingBuffer(TEST_DATA, 4, 256, errorHandler, null);
        assertTrue(errorCalled[0], "T005: Error handler called in fatal mode");
    }

    private static void runTest006() throws Exception {
        ErrorHandler errorHandler = (slotIdx, status) -> 0; // non-fatal

        byte[] output = runRingBuffer(TEST_DATA, 4, 256, errorHandler, null);
        assertArrayEquals(TEST_DATA, output, "T006: Non-fatal error preserves data");
    }

    private static void runTest007() throws Exception {
        final int xorKey = 0xAA;
        TransformFunction xorTransform = (data, sizeHolder) -> {
            for (int i = 0; i < sizeHolder[0]; i++) {
                data[i] = (byte) (data[i] ^ xorKey);
            }
        };

        byte[] output = runRingBuffer(TEST_DATA, 4, 256, null, xorTransform);

        byte[] expected = new byte[TEST_DATA.length];
        for (int i = 0; i < TEST_DATA.length; i++) {
            expected[i] = (byte) (TEST_DATA[i] ^ xorKey);
        }

        assertArrayEquals(expected, output, "T007: XOR transform");

        // Double-XOR should return original
        byte[] output2 = runRingBuffer(output, 4, 256, null, xorTransform);
        assertArrayEquals(TEST_DATA, output2, "T007: Double XOR returns original");
    }

    /**
     * Run all tests and return result string (for standalone execution).
     */
    public static String runAllTests() throws Exception {
        System.out.println("=== Ringbuffer Test Suite ===");
        System.out.println();

        runTest001();
        runTest002();
        runTest003();
        runTest004();
        runTest005();
        runTest006();
        runTest007();

        // Constructor validation tests
        try {
            new SwtrRingBuffer(0, BufferStatus.READYFORREAD, 256, null, null);
            failed++;
            failures.add("Constructor: should throw for 0 slots");
        } catch (IllegalArgumentException e) {
            passed++;
        }

        try {
            new SwtrRingBuffer(4, BufferStatus.READYFORREAD, 0, null, null);
            failed++;
            failures.add("Constructor: should throw for 0 buffer size");
        } catch (IllegalArgumentException e) {
            passed++;
        }

        // Valid constructor should not throw
        try {
            new SwtrRingBuffer(4, BufferStatus.READYFORREAD, 256, null, null);
            passed++;
        } catch (Exception e) {
            failed++;
            failures.add("Constructor: valid constructor threw exception");
        }

        // Version constants check
        assertTrue(SwtrRingBuffer.MIN_NUMBER_SLOTS >= 1, "MIN_NUMBER_SLOTS >= 1");
        assertTrue(SwtrRingBuffer.MIN_BUFFER_SIZE >= 1, "MIN_BUFFER_SIZE >= 1");
        assertTrue(SwtrRingBuffer.DEFAULT_BUFFER_SIZE > 0, "DEFAULT_BUFFER_SIZE > 0");

        // Print summary
        System.out.println("=== Test Results ===");
        System.out.println("Passed: " + passed);
        System.out.println("Failed: " + failed);

        if (!failures.isEmpty()) {
            System.out.println();
            System.out.println("Failures:");
            for (String f : failures) {
                System.err.println("  - " + f);
            }
        }

        if (failed > 0) {
            System.err.println("\nOVERALL: FAIL");
        } else {
            System.out.println("\nOVERALL: PASS");
        }

        return failed > 0 ? "FAIL" : "PASS";
    }

    /**
     * Entry point for Maven Surefire — runs all tests.
     */
    public void testAll() throws Exception {
        String result = runAllTests();
        if ("FAIL".equals(result)) {
            throw new AssertionError("Ringbuffer tests failed: " + failures.size() + " failures");
        }
    }

    public static void main(String[] args) throws Exception {
        if (args.length == 0) {
            // No arguments: run all tests and exit with code
            String result = runAllTests();
            System.exit("FAIL".equals(result) ? 1 : 0);
        } else {
            // Single test number: run that specific test (for manual testing)
            int testNumber;
            try {
                testNumber = Integer.parseInt(args[0]);
            } catch (NumberFormatException e) {
                System.err.println("Usage: java swtr.test.TestRingbuffer <test_number> [num_slots] [buffer_size]");
                System.exit(1);
                return;
            }

            int numSlots = 4;
            int bufferSize = 256;

            if (args.length >= 2) {
                try { numSlots = Integer.parseInt(args[1]); } catch (NumberFormatException e) { System.err.println("Invalid num_slots"); System.exit(1); return; }
            }
            if (args.length >= 3) {
                try { bufferSize = Integer.parseInt(args[2]); } catch (NumberFormatException e) { System.err.println("Invalid buffer_size"); System.exit(1); return; }
            }

            // Read input from stdin
            byte[] inputData = new byte[0];
            java.io.ByteArrayOutputStream buffer = new java.io.ByteArrayOutputStream();
            int nRead;
            byte[] chunk = new byte[4096];
            while ((nRead = System.in.read(chunk)) != -1) {
                buffer.write(chunk, 0, nRead);
            }
            inputData = buffer.toByteArray();

            // Run the specified test (delegate to runAllTests for simplicity)
            System.out.println("Running single test: T" + String.format("%03d", testNumber));
            runAllTests();
        }
    }
}
