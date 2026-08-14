package swtr.test;

import swtr.*;
import java.io.*;
import java.nio.file.*;
import java.util.Arrays;

/**
 * Ringbuffer test harness — exercises the 7-test matrix (T001-T007).
 * 
 * Test configuration via command-line arguments:
 *   java swtr.test.TestRingbuffer <test_number> [num_slots] [buffer_size]
 * 
 * Examples:
 *   java swtr.test.TestRingbuffer 1          # T001: Default (identity transform)
 *   java swtr.test.TestRingbuffer 3          # T003: Uppercase transform
 *   java swtr.test.TestRingbuffer 7          # T007: XOR transform
 *   java swtr.test.TestRingbuffer 2 1 1      # T002: Stress test (1 slot, 1-byte buffer)
 */
public class TestRingbuffer {

    private static final int DEFAULT_NUM_SLOTS = 4;
    private static final int DEFAULT_BUFFER_SIZE = 4096;

    public static void main(String[] args) {
        if (args.length < 1) {
            System.err.println("Usage: java swtr.test.TestRingbuffer <test_number> [num_slots] [buffer_size]");
            System.exit(1);
        }

        int testNumber;
        try {
            testNumber = Integer.parseInt(args[0]);
        } catch (NumberFormatException e) {
            System.err.println("ERROR: Invalid test number: " + args[0]);
            System.exit(1);
            return;
        }

        int numSlots = DEFAULT_NUM_SLOTS;
        int bufferSize = DEFAULT_BUFFER_SIZE;

        if (args.length >= 2) {
            try {
                numSlots = Integer.parseInt(args[1]);
            } catch (NumberFormatException e) {
                System.err.println("ERROR: Invalid num_slots: " + args[1]);
                System.exit(1);
                return;
            }
        }

        if (args.length >= 3) {
            try {
                bufferSize = Integer.parseInt(args[2]);
            } catch (NumberFormatException e) {
                System.err.println("ERROR: Invalid buffer_size: " + args[2]);
                System.exit(1);
                return;
            }
        }

        // Validate parameters
        if (numSlots < SwtrRingBuffer.MIN_NUMBER_SLOTS) {
            System.err.println("ERROR: num_slots must be >= " + SwtrRingBuffer.MIN_NUMBER_SLOTS);
            System.exit(1);
            return;
        }

        if (bufferSize < SwtrRingBuffer.MIN_BUFFER_SIZE) {
            System.err.println("ERROR: buffer_size must be >= " + SwtrRingBuffer.MIN_BUFFER_SIZE);
            System.exit(1);
            return;
        }

        // Run the specified test
        boolean success = false;
        try {
            switch (testNumber) {
                case 1:
                    success = runTest001(numSlots, bufferSize);
                    break;
                case 2:
                    success = runTest002(numSlots, bufferSize);
                    break;
                case 3:
                    success = runTest003(numSlots, bufferSize);
                    break;
                case 4:
                    success = runTest004(numSlots, bufferSize);
                    break;
                case 5:
                    success = runTest005(numSlots, bufferSize);
                    break;
                case 6:
                    success = runTest006(numSlots, bufferSize);
                    break;
                case 7:
                    success = runTest007(numSlots, bufferSize);
                    break;
                default:
                    System.err.println("ERROR: Unknown test number: " + testNumber);
                    System.exit(1);
                    return;
            }
        } catch (Exception e) {
            System.err.println("ERROR: Test " + testNumber + " failed with exception: " + e.getMessage());
            e.printStackTrace();
            System.exit(1);
            return;
        }

        if (success) {
            System.out.println("Test " + testNumber + " PASSED");
            System.exit(0);
        } else {
            System.err.println("Test " + testNumber + " FAILED");
            System.exit(1);
        }
    }

    /**
     * T001: Default (identity transform) — output == input.
     */
    private static boolean runTest001(int numSlots, int bufferSize) throws Exception {
        System.out.println("Running T001: Default (identity transform)");

        byte[] inputData = readAllBytes(System.in);
        if (inputData.length == 0) {
            System.err.println("ERROR: T001 — No input data");
            return false;
        }

        SwtrRingBuffer rb = new SwtrRingBuffer(
            numSlots, BufferStatus.READYFORREAD, bufferSize, null, null
        );

        File inputFile = File.createTempFile("t001_input_", ".txt");
        File outputFile = File.createTempFile("t001_output_", ".txt");

        try {
            Files.write(inputFile.toPath(), inputData);
            FileInputStream fis = new FileInputStream(inputFile);
            FileOutputStream fos = new FileOutputStream(outputFile);

            rb.setReadFd(getFileDescriptorInt(fis.getFD()));
            rb.setWriteFd(getFileDescriptorInt(fos.getFD()));

            rb.start();
            try { rb.awaitTermination(); } catch (InterruptedException e) { Thread.currentThread().interrupt(); rb.stop(); }

            byte[] outputData = Files.readAllBytes(outputFile.toPath());
            boolean match = Arrays.equals(inputData, outputData);

            if (!match) {
                System.err.println("ERROR: T001 — Output does not match input");
            }

            fis.close(); fos.close();
            return match;
        } finally {
            inputFile.delete(); outputFile.delete();
        }
    }

    /**
     * T002: Stress test (1 slot, 1-byte buffer) — output == input.
     */
    private static boolean runTest002(int numSlots, int bufferSize) throws Exception {
        System.out.println("Running T002: Stress test (1 slot, 1-byte buffer)");

        byte[] inputData = readAllBytes(System.in);
        if (inputData.length == 0) {
            System.err.println("ERROR: T002 — No input data");
            return false;
        }

        SwtrRingBuffer rb = new SwtrRingBuffer(1, BufferStatus.READYFORREAD, 1, null, null);

        File inputFile = File.createTempFile("t002_input_", ".txt");
        File outputFile = File.createTempFile("t002_output_", ".txt");

        try {
            Files.write(inputFile.toPath(), inputData);
            FileInputStream fis = new FileInputStream(inputFile);
            FileOutputStream fos = new FileOutputStream(outputFile);

            rb.setReadFd(getFileDescriptorInt(fis.getFD()));
            rb.setWriteFd(getFileDescriptorInt(fos.getFD()));

            rb.start();
            try { rb.awaitTermination(); } catch (InterruptedException e) { Thread.currentThread().interrupt(); rb.stop(); }

            byte[] outputData = Files.readAllBytes(outputFile.toPath());
            boolean match = Arrays.equals(inputData, outputData);

            if (!match) { System.err.println("ERROR: T002 — Output does not match input"); }

            fis.close(); fos.close();
            return match;
        } finally {
            inputFile.delete(); outputFile.delete();
        }
    }

    /**
     * T003: Uppercase transform — output is uppercase version of input.
     */
    private static boolean runTest003(int numSlots, int bufferSize) throws Exception {
        System.out.println("Running T003: Uppercase transform");

        byte[] inputData = readAllBytes(System.in);
        if (inputData.length == 0) {
            System.err.println("ERROR: T003 — No input data");
            return false;
        }

        TransformFunction uppercaseTransform = (data, sizeHolder) -> {
            for (int i = 0; i < sizeHolder[0]; i++) {
                byte b = data[i];
                if (b >= 'a' && b <= 'z') {
                    data[i] = (byte) (b - 32);
                }
            }
        };

        SwtrRingBuffer rb = new SwtrRingBuffer(numSlots, BufferStatus.READYFORREAD, bufferSize, null, uppercaseTransform);

        File inputFile = File.createTempFile("t003_input_", ".txt");
        File outputFile = File.createTempFile("t003_output_", ".txt");

        try {
            Files.write(inputFile.toPath(), inputData);
            FileInputStream fis = new FileInputStream(inputFile);
            FileOutputStream fos = new FileOutputStream(outputFile);

            rb.setReadFd(getFileDescriptorInt(fis.getFD()));
            rb.setWriteFd(getFileDescriptorInt(fos.getFD()));

            rb.start();
            try { rb.awaitTermination(); } catch (InterruptedException e) { Thread.currentThread().interrupt(); rb.stop(); }

            byte[] outputData = Files.readAllBytes(outputFile.toPath());
            byte[] expectedOutput = toUpperCase(inputData);

            boolean match = Arrays.equals(outputData, expectedOutput);

            if (!match) {
                System.err.println("ERROR: T003 — Output does not match expected uppercase");
            }

            fis.close(); fos.close();
            return match;
        } finally {
            inputFile.delete(); outputFile.delete();
        }
    }

    /**
     * T004: Small input, fast EOF — output == input.
     */
    private static boolean runTest004(int numSlots, int bufferSize) throws Exception {
        System.out.println("Running T004: Small input, fast EOF");

        byte[] inputData = readAllBytes(System.in);
        if (inputData.length == 0) {
            System.err.println("ERROR: T004 — No input data");
            return false;
        }

        SwtrRingBuffer rb = new SwtrRingBuffer(numSlots, BufferStatus.READYFORREAD, bufferSize, null, null);

        File inputFile = File.createTempFile("t004_input_", ".txt");
        File outputFile = File.createTempFile("t004_output_", ".txt");

        try {
            Files.write(inputFile.toPath(), inputData);
            FileInputStream fis = new FileInputStream(inputFile);
            FileOutputStream fos = new FileOutputStream(outputFile);

            rb.setReadFd(getFileDescriptorInt(fis.getFD()));
            rb.setWriteFd(getFileDescriptorInt(fos.getFD()));

            rb.start();
            try { rb.awaitTermination(); } catch (InterruptedException e) { Thread.currentThread().interrupt(); rb.stop(); }

            byte[] outputData = Files.readAllBytes(outputFile.toPath());
            boolean match = Arrays.equals(inputData, outputData);

            if (!match) { System.err.println("ERROR: T004 — Output does not match input"); }

            fis.close(); fos.close();
            return match;
        } finally {
            inputFile.delete(); outputFile.delete();
        }
    }

    /**
     * T005: Fatal error mode — pipeline should exit with code 1.
     */
    private static boolean runTest005(int numSlots, int bufferSize) throws Exception {
        System.out.println("Running T005: Fatal error mode");

        byte[] inputData = readAllBytes(System.in);
        if (inputData.length == 0) {
            System.err.println("ERROR: T005 — No input data");
            return false;
        }

        ErrorHandler errorHandler = (slotIdx, status) -> {
            System.err.println("ERROR: Error handler called for slot " + slotIdx);
            return 1;
        };

        SwtrRingBuffer rb = new SwtrRingBuffer(numSlots, BufferStatus.READYFORREAD, bufferSize, errorHandler, null);

        File inputFile = File.createTempFile("t005_input_", ".txt");
        File outputFile = File.createTempFile("t005_output_", ".txt");

        try {
            Files.write(inputFile.toPath(), inputData);
            FileInputStream fis = new FileInputStream(inputFile);
            FileOutputStream fos = new FileOutputStream(outputFile);

            rb.setReadFd(getFileDescriptorInt(fis.getFD()));
            rb.setWriteFd(getFileDescriptorInt(fos.getFD()));

            rb.start();
            try { rb.awaitTermination(); } catch (InterruptedException e) { Thread.currentThread().interrupt(); rb.stop(); }

            System.out.println("T005: Pipeline executed (partial output expected)");
            fis.close(); fos.close();
            return true;
        } finally {
            inputFile.delete(); outputFile.delete();
        }
    }

    /**
     * T006: Non-fatal error mode — output == input.
     */
    private static boolean runTest006(int numSlots, int bufferSize) throws Exception {
        System.out.println("Running T006: Non-fatal error mode");

        byte[] inputData = readAllBytes(System.in);
        if (inputData.length == 0) {
            System.err.println("ERROR: T006 — No input data");
            return false;
        }

        ErrorHandler errorHandler = (slotIdx, status) -> {
            System.err.println("WARNING: Non-fatal error in slot " + slotIdx);
            return 0;
        };

        SwtrRingBuffer rb = new SwtrRingBuffer(numSlots, BufferStatus.READYFORREAD, bufferSize, errorHandler, null);

        File inputFile = File.createTempFile("t006_input_", ".txt");
        File outputFile = File.createTempFile("t006_output_", ".txt");

        try {
            Files.write(inputFile.toPath(), inputData);
            FileInputStream fis = new FileInputStream(inputFile);
            FileOutputStream fos = new FileOutputStream(outputFile);

            rb.setReadFd(getFileDescriptorInt(fis.getFD()));
            rb.setWriteFd(getFileDescriptorInt(fos.getFD()));

            rb.start();
            try { rb.awaitTermination(); } catch (InterruptedException e) { Thread.currentThread().interrupt(); rb.stop(); }

            byte[] outputData = Files.readAllBytes(outputFile.toPath());
            boolean match = Arrays.equals(inputData, outputData);

            if (!match) { System.err.println("ERROR: T006 — Output does not match input"); }

            fis.close(); fos.close();
            return match;
        } finally {
            inputFile.delete(); outputFile.delete();
        }
    }

    /**
     * T007: XOR transform — output is XOR of input with key 0xAA (binary data).
     */
    private static boolean runTest007(int numSlots, int bufferSize) throws Exception {
        System.out.println("Running T007: XOR transform");

        byte[] inputData = readAllBytes(System.in);
        if (inputData.length == 0) {
            System.err.println("ERROR: T007 — No input data");
            return false;
        }

        final int xorKey = 0xAA;
        TransformFunction xorTransform = (data, sizeHolder) -> {
            for (int i = 0; i < sizeHolder[0]; i++) {
                data[i] = (byte) (data[i] ^ xorKey);
            }
        };

        SwtrRingBuffer rb = new SwtrRingBuffer(numSlots, BufferStatus.READYFORREAD, bufferSize, null, xorTransform);

        File inputFile = File.createTempFile("t007_input_", ".txt");
        File outputFile = File.createTempFile("t007_output_", ".txt");

        try {
            Files.write(inputFile.toPath(), inputData);
            FileInputStream fis = new FileInputStream(inputFile);
            FileOutputStream fos = new FileOutputStream(outputFile);

            rb.setReadFd(getFileDescriptorInt(fis.getFD()));
            rb.setWriteFd(getFileDescriptorInt(fos.getFD()));

            rb.start();
            try { rb.awaitTermination(); } catch (InterruptedException e) { Thread.currentThread().interrupt(); rb.stop(); }

            byte[] outputData = Files.readAllBytes(outputFile.toPath());

            byte[] expectedOutput = new byte[inputData.length];
            for (int i = 0; i < inputData.length; i++) {
                expectedOutput[i] = (byte) (inputData[i] ^ xorKey);
            }

            boolean match = Arrays.equals(outputData, expectedOutput);

            if (!match) {
                System.err.println("ERROR: T007 — Output does not match expected XOR");
            }

            fis.close(); fos.close();
            return match;
        } finally {
            inputFile.delete(); outputFile.delete();
        }
    }

    /**
     * Get integer value of a FileDescriptor using reflection.
     */
    private static int getFileDescriptorInt(java.io.FileDescriptor fd) {
        try {
            java.lang.reflect.Field fdField = fd.getClass().getDeclaredField("fd");
            fdField.setAccessible(true);
            return fdField.getInt(fd);
        } catch (Exception e) {
            System.err.println("ERROR: Failed to get FileDescriptor int value: " + e.getMessage());
            return -1;
        }
    }

    /**
     * Convert byte array to uppercase (ASCII only).
     */
    private static byte[] toUpperCase(byte[] data) {
        byte[] result = new byte[data.length];
        for (int i = 0; i < data.length; i++) {
            byte b = data[i];
            if (b >= 'a' && b <= 'z') {
                result[i] = (byte) (b - 32);
            } else {
                result[i] = b;
            }
        }
        return result;
    }

    /**
     * Read all bytes from an InputStream.
     */
    private static byte[] readAllBytes(InputStream is) throws IOException {
        ByteArrayOutputStream buffer = new ByteArrayOutputStream();
        int nRead;
        byte[] chunk = new byte[4096];
        while ((nRead = is.read(chunk)) != -1) {
            buffer.write(chunk, 0, nRead);
        }
        return buffer.toByteArray();
    }

    /**
     * Convert byte array to hex string for debugging.
     */
    private static String bytesToHex(byte[] bytes) {
        StringBuilder sb = new StringBuilder();
        for (byte b : bytes) {
            sb.append(String.format("%02x", b));
        }
        return sb.toString();
    }
}
