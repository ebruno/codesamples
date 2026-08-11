# Update Regression Tests - Debian

**Objective:** Update the test suite to cover new functionality or modified interfaces.

**Temporary Workspace Lifecycle:**
1. **Initialization**: Create the `ringbuffer/tmp` directory as the very first action before starting any other task.
2. **Usage**: Ensure all temporary files and scripts generated during the process are stored exclusively within `ringbuffer/tmp`.
3. **Cleanup**: Recursively delete the `ringbuffer/tmp` directory and all its contents immediately upon completion of all tasks associated with this prompt.

**Inputs:**
1. The current `ringbuffer.hpp` (The Interface).
2. The current test files in `src/debian/cpp/tests/`.
3. `ringbuffer/prompts/debian/cpp/testing.md`.

**Directives:**
- Use `ringbuffer/prompts/debian/cpp/testing.md` as the primary platform-specific directive.
- Follow all requirements in `ringbuffer/prompts/common/cpp/testing.md` for common C++ testing specifications.

**Instructions:**
- **Interface Gap Analysis:** Identify any new virtual functions or changed signatures in `ringbuffer.hpp` that are not covered by existing tests.
- **Test Expansion:** Create new test cases or update existing ones to validate the new behavior.
- **Regression Check:** Ensure that existing tests still pass and that new tests do not break existing functionality.
- **Log Validation:** Ensure tests verify that the correct logs are being written to `testing.log`.

**Architecture Changes:**
When the test suite needs to adapt to source tree changes:
1. **New Test Binaries:** If new library variants are added (e.g., a new linking mode), create corresponding test binaries in `tests/Makefile`.
2. **Test Matrix Updates:** If new functionality requires additional test scenarios, add rows to the Test Matrix table in `testing.md` with unique Test IDs (e.g., T008, T009).
3. **Test Data Updates:** If new input patterns are required, generate additional test data files following the zig-zag pattern specification.
4. **Script Updates:** If new utility scripts are needed, create them in `tests/utils/bin/` and update the README.md with usage instructions.

**Container Runtime Pre-flight (macOS Host):**
If this update involves container operations, and the host OS is macOS, the `container` command MUST be available in PATH before proceeding.
- **Verification**: Execute `command -v container` to confirm availability.
- **Error Handling**: If `container` is NOT found, STOP and display:
  ```
  ERROR: The 'container' command is required for cross-OS testing from macOS to Linux targets, but it was not found in PATH.
  
  Please install Apple Container from: https://github.com/apple/container
  
  After installation, ensure the 'container' command is available in your PATH and re-run the test workflow.
  ```

**State Management:**
- **Spec Hash Update:** Update the hash of the platform-specific `testing.md` in `.gen_state.json` upon completion.

**Documentation Synchronization:**
- **README Update:** If the build or testing changes affect the high-level project status (e.g., a platform is now "WIP" instead of "TBS"), use `ringbuffer/prompts/common/generate_toplevel_readme.md` to update the top-level `README.md`.

**Output:**
- Updated or new test source files.

## Cross-Platform Update Propagation
After successfully updating the test suite for this platform, you MUST:
1. Copy the updated `tests/Makefile` to the other Linux platform's source directory (e.g., Debian → Ubuntu, or vice versa), adjusting only `CONTAINER_IMAGE`, Dockerfile path, and report title.
2. Copy any updated test utility scripts from `tests/utils/bin/` to the other platform.
3. Verify byte-identity of all non-platform-specific content with `diff`.
4. Update `.gen_state.json` in **both** platforms.
5. Log the propagation action in both platform's `logs/testing.log`.

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions (e.g., `.cpp`, `.hpp`, or `Makefile`), such as `` ErrorOps.cpp`} ``, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.
<EOF>
