# Regression Test Implementation Workflow

**Objective:** 
Create the test environment, generate test data, build test binaries, execute the full regression test matrix (T001–T007), and generate reports for the Ringbuffer library. This workflow mirrors `implement_build.md` but focuses on testing infrastructure and execution.

**Inputs:**
1. **Target OSes**: One or more operating systems to target (e.g., `fedora`, `debian,ubuntu`). If not specified, all OSes in `ringbuffer/src/` are processed.
2. **Target Image**: An optional container image override (e.g., `fedora:43`, `debian:12`). If provided, this overrides the default image specified in each OS's `create_regression.md`. If not provided, use the default image from the target OS's prompt.

**Process:**
1. **Target Selection**:
   - **Specified Platforms**: If the user request specifies target platforms (e.g., "implement regression for fedora, debian"), verify their existence in `ringbuffer/src/`. If a requested platform is missing from `ringbuffer/src/`, inform the user that the OS is not currently implemented and list all operating systems that are currently supported (those present as directories in `ringbuffer/src/`). Process only the requested platforms that are implemented.
   - **General Request**: Otherwise, iterate through **all** OS directories found in `ringbuffer/src/` (e.g., debian, fedora, ubuntu).
   - **Entry Point**: When targeting a specific OS, first check if `ringbuffer/prompts/<os>/cpp/create_regression.md` exists.
     - **If it exists**: Consult it for immediate requirements and platform-specific directives. Execute it as the PRIMARY document.
     - **If it does not exist**: Proceed with only `ringbuffer/prompts/common/cpp/testing.md` as the specification. Skip platform-specific directives and log: `[timestamp] create_regression.md not found for <os> — proceeding with common spec only.`
   - **Language**: This workflow specifically targets the C++ test environment.

2. **Execution Steps**:
   For the selected OS directory, perform the following.

   **Workflow Precedence:** Execute this common workflow's Step 0 first for image resolution and execution path decision. Then execute `ringbuffer/prompts/<os>/cpp/create_regression.md` as the **PRIMARY** document and skip this common workflow's Steps 1-7. This common workflow serves as a reference for structure and provides the image resolution mechanism.

   **Note:** `create_regression.md` is read as a data source for image resolution in Step 0, then executed as the PRIMARY document afterward.

   0. **Environment Setup**:
      - **Timeout Configuration**: All timeout values are defined as variables for easy adjustment:
        - `CONTAINER_BUILD_TIMEOUT_MS`: 600,000 ms (10 minutes) — maximum time for `make container`
        - `TEST_EXECUTION_TIMEOUT_MS`: 600,000 ms (10 minutes) — maximum time for the full test matrix
      - **Resolve Image**: Determine the Target Image from Inputs (see above). If not provided by the user, read the default image from `ringbuffer/prompts/<os>/cpp/create_regression.md` (look for an `IMAGE=` or `Default Image:` directive). If no image is specified in the per-OS file, derive it from `ringbuffer/prompts/<os>/cpp/testing.md` (e.g., `fedora:44`, `debian:13`, `ubuntu:24.04`). Log: `IMAGE=<resolved_image>`.
      - **Shared Version Context**: Read the version from `ringbuffer/src/<os>/cpp/.gen_state.json` (if it exists). This version was set by `implement_functional.md` and represents the Ringbuffer library version (`MAJOR.MINOR.SUBVERSION`). If `.gen_state.json` does not exist, read `ringbuffer/src/<os>/cpp/version.mk` as a fallback. Log: `VERSION=<resolved_version>`.
      - **Execution Path Decision**: Detect the host OS. If `uname -s` returns `Darwin`, set `host_os = macOS`. If it returns `Linux`, read the distro ID from `/etc/os-release` using: `host_os=$(grep '^ID=' /etc/os-release | cut -d= -f2)`.
        - **Native Execution**: If `host_os == <os>` OR if the target `<os>` is `macos`, all test and verification steps MUST be performed natively on the host. Containers MUST NOT be used for macOS targets.
        - **Container Execution**: If `host_os != <os>` AND the target `<os>` is NOT `macos`, all test and verification steps MUST be performed inside the `ringbuffer_<os>_test` container.
        - **Log Your Decision**: Print a one-line summary to stdout. After log initialization (Step 0, Log Initialization), append the same line to `build.log`.
          ```
          HOST=<host_os> TARGET=<os> ROUTING=container|native REASON=<brief explanation>
          ```

      - **Resource Allocation (macOS Host, Container Execution Only)**: If the Execution Path Decision determined container execution AND `host_os` is macOS, calculate the memory limit:
        - Run `vm_stat`.
        - Extract the page size from the first line (e.g., `16384`).
        - Extract `Pages free` and `Pages inactive`.
        - Calculate total available bytes: `(Pages free + Pages inactive) * page size`.
        - Convert to GiB: `total bytes / 1,073,741,824`.
        - Set container memory limit (`-m`) to 50% of this value, capped at 3 GB.
        - Store this as `<memory_limit>` for use in Step 2's container run command.
      - **Container Runtime Pre-flight Check**: If the Execution Path Decision determined that container execution is required:
        - **macOS host**: The `container` command MUST be available. Execute `command -v container`. If not found, STOP and display:
          ```
          ERROR: The 'container' command is required for cross-OS builds from macOS to Linux targets, but it was not found in PATH.
          
          Please install Apple Container from: https://github.com/apple/container
          
          After installation, ensure the 'container' command is available in your PATH and re-run the build or test workflow.
          ```
        - **Linux host**: The `podman` command MUST be available. Execute `command -v podman`. If not found, STOP and display:
          ```
          ERROR: The 'podman' command is required for cross-OS builds on Linux, but it was not found in PATH.
          
          Install podman with: sudo dnf install -y podman   (Fedora)
          Or:                  sudo apt-get install -y podman  (Debian/Ubuntu)
          
          After installation, ensure the 'podman' command is available in your PATH and re-run the build or test workflow.
          ```
      - **Navigate**: `cd ringbuffer/src/<os>/cpp`
      - **Validate Existing Dockerfile**: If the build Dockerfile exists at `ringbuffer/src/<os>/cpp/containers/Dockerfile`, verify that the resolved Target Image matches its `FROM` base image tag. If it does not match, log an error and stop processing — the requested image conflicts with the existing container configuration.
      - **Validate Test Dockerfile**: If `tests/containers/<os>/Dockerfile` exists, verify its `FROM` base image matches the resolved Target Image. If it does not match, log an error and stop processing.
      - **Build Build Image**: Before creating the `_test` image, ensure the base `ringbuffer_<os>_build` image is present. Check if it already exists using `<runtime> images | grep ringbuffer_<os>_build`. If not found, execute `make container`. Verify that `ringbuffer_<os>_build` exists using `<runtime> images | grep ringbuffer_<os>_build`.
      - **Step 0 Dockerfile Marker**: If a minimal test Dockerfile was created in this sub-step, create a marker file at `ringbuffer/src/<os>/cpp/.dockerfile_created_by_step0` to signal that the Dockerfile already exists. `create_regression.md` (Step 1) MUST check for this marker and skip Dockerfile creation if it exists.
      - **Log Initialization**: Create the log directory `logs/` if it does not exist. Initialize `build.log` with the start timestamp, action description, and resolved image/version as per the "Generation Process Logging" requirement.

   1. **Test Infrastructure Setup**:
      - Execute the directives in `ringbuffer/prompts/<os>/cpp/create_regression.md` to create:
        - The test directory structure (`tests/`) with all required subdirectories and `.required_directory` markers.
        - The test Dockerfile (`tests/containers/<os>/Dockerfile`) — create from scratch or augment based on the `.dockerfile_created_by_step0` marker.
        - The test container image (`ringbuffer_<os>_test`) built from `tests/containers/<os>/Dockerfile` (via `make container` in the tests directory, as directed by `create_regression.md`).
        - Utility scripts deployed to `tests/utils/bin/` from `ringbuffer/prompts/common/cpp/utils/bin/`.
        - Test data files (`test001.txt` through `test007.txt`) in `tests/data/inputs/`.
        - Expected output files (golden files) in `tests/data/expected/` — pre-computed correct outputs for each test scenario, generated by running the test program with known inputs and capturing output.
        - Test binary source code (`tests/src/test001.cpp`) implementing the full CLI interface described in `ringbuffer/prompts/common/cpp/testing.md` (including socket mode `-r`/`-w`, error modes, transform types, and all option flags). The Makefile must build two variants: `test001_staticlib` (linked against static library) and `test001_dynamiclib` (linked against shared library with rpath).
        - Test Makefile (`tests/Makefile`).
        - A `tests/README.md` describing the test suite, build process, and how to run scenarios T001–T007.
      - **Test Data Validation**: Before running `verify_test_data.sh`, ensure it has been deployed to `tests/utils/bin/` from `ringbuffer/prompts/common/cpp/utils/bin/`. After generating test data, run the validator script. All seven files must pass validation (line count and format checks). Log success or failure for each file.
      - **Test Binary Build**: Compile `test001_staticlib` (linked against static library) and `test001_dynamiclib` (linked against shared library with rpath). Verify both binaries exist in `tests/bin/`.
      - Log each file creation and build step in `build.log` immediately after the action completes.

   1.5 **Cross-Platform Verification**: After creating the test Makefile and Dockerfile, verify they conform to the binary symmetry requirements:
      - **Identify a Reference Platform**: First, check if `ringbuffer/src/reference_linux/cpp/tests/Makefile` exists. If it does, use `reference_linux` as the reference platform (this is the canonical source of truth). If it does not exist, fall back to alphabetical iteration through directories in `ringbuffer/src/` (e.g., `debian`, `fedora`, `ubuntu`) and select the first one where `ringbuffer/src/<ref_os>/cpp/tests/Makefile` exists.
      - **Fallback**: If no reference platform has a test Makefile, skip cross-platform verification and log: `[timestamp] Cross-platform verification skipped — no reference platform available.` Proceed to Step 2.
      - **Test Makefile Comparison**: Strip the three allowed differences from both the generated test Makefile and the reference:
        1. `CONTAINER_IMAGE` variable value
        2. Dockerfile path in container run commands (`containers/debian/Dockerfile` vs `containers/fedora/Dockerfile`)
        3. Report title in the Markdown report generation section
      - Compare the remaining content byte-for-byte.
      - **Dockerfile Comparison**: Strip lines starting with `FROM` and `ARG BASE_IMAGE`. Strip any multi-line RUN command where ANY line (including continuation lines) contains a package manager invocation (`dnf install`, `apt-get update`, `apt-get install`, `yum install`) — strip the entire RUN block, not just the package manager portion. Do NOT strip other Dockerfile instructions (`WORKDIR`, `ENV`, `COPY`, `CMD`, etc.). Normalize consecutive empty lines to a single empty line. Compare the remaining content byte-for-byte.
      - **If differences are found beyond the allowed set**: Log: `[timestamp] Cross-platform verification FAILED — <os> test Makefile/Dockerfile differs from reference beyond allowed differences.` STOP and report the deviation for manual review.
      - **If verification passes**: Log: `[timestamp] Cross-platform verification passed — <os> test Makefile/Dockerfile matches reference (allowed differences only).`

   2. **Consolidated Build and Verification**:
      - **Timeout Limit**: Maximum of 600,000 ms (10 minutes) for the entire Step 2 pipeline (build + verify combined).
      - **Execute (Split Pipeline)**:
        - Use `JOBS` (e.g., 4 or 8) to enable parallel compilation.
        - **Step 1: Build Library and Tests**:
          - **Native**: `make clean && make -j$(JOBS) && if [ -d tests ]; then cd tests && make clean && make -j$(JOBS); else echo 'ERROR: Tests directory missing.'; exit 1; fi`
            - Note: `make clean` removes existing library artifacts (`build/`, `lib/`). This is intentional to ensure a fresh build.
          - **Container**: `<runtime> run --rm -m <memory_limit> -v $(pwd):/app ringbuffer_<os>_test sh -c "cd /app && make clean && make -j$(JOBS) && if [ -d tests ]; then cd tests && make clean && make -j$(JOBS); else echo 'ERROR: Tests directory missing.'; exit 1; fi"`, where `<runtime>` is `container` on macOS or `podman` on Linux.
        - **Step 2: Run Verification**:
          - **Native**: `cd tests && make verify`
          - **Container**: `<runtime> run --rm -m <memory_limit> -v $(pwd):/app ringbuffer_<os>_test sh -c "cd /app/tests && make verify"`, where `<runtime>` is `container` on macOS or `podman` on Linux.
      - **Timing Requirements**:
        - **Start Time**: The report `Start Time` MUST be captured at the exact moment the `make verify` target is invoked in the `tests/Makefile`.
        - **End Time**: The report `End Time` MUST be captured immediately after the final test scenario (T007) in the test matrix has completed its execution.
      - **Verify Artifacts**:
        - Confirm that both `test001_staticlib` and `test001_dynamiclib` exist in the `tests/bin/` directory. If either is missing, STOP and report a build failure.
        - Confirm that the `make verify` target in the test Makefile completed successfully (this includes library artifact verification, full test matrix execution, and report generation).
        - **JUnit Report**: Confirm that `tests/reports/regression_report_junit.xml` was generated and follows the required JUnit XML structure.
      - **Evaluate**: If any step fails, follow the procedure below. Do NOT loop indefinitely.

         **Build/Verification Failure Procedure:**
         1. Capture the full error output (compiler errors, linker errors, test failures).
         2. Analyze the logs to determine the root cause:
            - **Compiler errors**: Check for missing includes, type mismatches, or syntax errors in the source files.
            - **Linker errors**: Verify that all object files are present and that library dependencies are correctly specified.
            - **Test failures**: Compare actual output against expected results in `tests/data/expected/`.
         3. Apply the minimal fix required to address the root cause.
         4. Retry the **entire consolidated pipeline** (build + verify) at most **1 time**.
         5. If all retries fail, STOP immediately. Do NOT retry again.
            Report the error with diagnostic output and escalate to the user:
            - The original error output
            - A list of all fixes attempted (max 1)
            - Diagnostic results (container status, disk space, Dockerfile syntax check)
            - A recommendation to investigate manually
            ```
            BUILD/VERIFICATION FAILED — [Full Platform Name]

            Fixes attempted:
            - <fix 1>: <description>

            Final error: <last error output>

            Recommendation: Investigate the root cause manually. Check `cpp/logs/build.log` and `tests/logs/` for detailed output.
            ```

   3. **Test Artifact Verification**:
      - Verify the produced test artifacts:
        - **Architecture**: Use `file` on both `test001_staticlib` and `test001_dynamiclib`.
          - **Linux targets**: PASS if output contains "ELF 64-bit". FAIL otherwise.
          - **macOS targets**: PASS if output contains "Mach-O". FAIL otherwise.
        - **Executable**: Both binaries must be executable (`test -x`).
        - **Library linkage**:
          - **Linux**: `ldd test001_dynamiclib` should show `libswtr_ringbuffer.so`. `test001_staticlib` should NOT show dynamic library dependencies.
          - **macOS**: `otool -L test001_dynamiclib` should show the shared library. `test001_staticlib` should not.
      - Log results to `build.log`.

   4. **Report Generation**:
      - Generate the Markdown regression report at `tests/reports/regression_report.md` using the following format:

        ```markdown
        # Regression Verification Report - [Full Platform Name] (use the full platform name from `testing.md`, e.g., 'Fedora 44', 'Debian 13', 'Ubuntu 24.04 LTS')
        **Date:** [YYYY-MM-DD HH:MM:SS ±HHMM]
        **Start Time:** [YYYY-MM-DD HH:MM:SS ±HHMM]
        **End Time:** [YYYY-MM-DD HH:MM:SS ±HHMM]
        **Elapsed Time:** [Duration]
        **Host OS:** [Host OS Name/Version]

        ## Status
        **Final Result:** [PASS / FAIL]

        ## Audit Trail
        - **Compiler**: [Version output from g++ -v or clang++ -v]
        - **Linker**: [Version output from ld -v or lld -v]

        ## Test Results
        | Test ID | Description | Result | Execution Time | Note |
        | :--- | :--- | :--- | :--- | :--- |
        | T001 | Exact match with input | [PASS/FAIL] | [Time] | [Brief note] |
        | T002 | Stress test (1 slot, 1 byte) | [PASS/FAIL] | [Time] | [Brief note] |
        | T003 | All chars uppercase | [PASS/FAIL] | [Time] | [Brief note] |
        | T004 | Input < 1 slot (fast EOF) | [PASS/FAIL] | [Time] | [Brief note] |
        | T005 | Pipeline stop (Fatal Error) | [PASS/FAIL] | [Time] | [Brief note] |
        | T006 | Pipeline continues (Non-fatal) | [PASS/FAIL] | [Time] | [Brief note] |
        | T007 | Bit-inverted output | [PASS/FAIL] | [Time] | [Brief note] |

        ## Fixes and Modifications
        *If files were modified to achieve a successful build, list them here:*
        - `path/to/file`: [Brief explanation of the fix]

        ## Verification Details
        - **Library Build**: [Success/Failure] - [Brief note on logs/errors]
        - **Test Build**: [Success/Failure] - [Brief note on logs/errors]
        - **Artifacts Verified**: [Yes/No] (Architecture, SONAME/Install Name, Binary Size)
        ```

      - Generate the JUnit XML report at `tests/reports/regression_report_junit.xml` following the mandated JUnit XML structure, including per-test `<testcase time="...">` attributes and a `<system-out>` summary with total execution time.
      - Log report generation to `build.log`.

   5. **State Tracking**:
      - Create or update `.gen_state.json` in `ringbuffer/src/<os>/cpp/` containing:
        - The resolved version (from shared context or `version.mk`).
        - The resolved image.
        - SHA-256 hashes of `common/cpp/testing.md` and `<os>/cpp/testing.md`.
        - SHA-256 hashes of all generated test artifacts (test Makefile, test Dockerfile, utility scripts).
        - File fingerprints for all source files.
      - **Version Change Detection**: Before updating `.gen_state.json`, compare the current `version.mk` values against those stored in `.gen_state.json`. If any value has changed (e.g., `MAJOR`, `MINOR`, `SUBVERSION`, or `BUILD_ID`), regenerate all versioned artifact names and symlinks in the `lib/` directory before proceeding.

   6. **Final Self-Audit**:
      - Verify the following and log results:
        - **Test Makefile Targets**: All required targets are present (`clean`, `dist-clean`, `container`, `verify`).
        - **Test Dockerfile** (`tests/containers/<os>/Dockerfile`): Exists and has valid syntax (base image, package installation).
        - **Test Data**: All seven test files (`test001.txt`–`test007.txt`) exist in `tests/data/inputs/`.
        - **Test Binaries**: Both `test001_staticlib` and `test001_dynamiclib` exist in `tests/bin/`.
        - **Reports**: Both `regression_report.md` and `regression_report_junit.xml` exist in `tests/reports/`.
        - **Source Consistency**: All test source files in `tests/src/` are listed in the test Makefile's build rules.
        - **Artifact Verification**: Test binaries (`test001_staticlib`, `test001_dynamiclib`) exist and are executable.

   7. **Finalize Logs**:
      - Append a final entry to `build.log` stating that the regression test implementation is complete.
      - Calculate and include the total elapsed time since the start timestamp in this final entry.

**Directives:**
1. Use `ringbuffer/prompts/<os>/cpp/testing.md` for platform-specific prerequisites (package lists, container settings).
2. Use `ringbuffer/prompts/common/cpp/testing.md` as the primary testing specification.
(See Steps 1–7 above for detailed requirements.)

**Reporting:**
The report generated in Step 4 serves as the final summary.

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions (e.g., `` ErrorOps.cpp`} ``, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.

## Scope Boundary — Regression Test Phase Only

The purpose of this prompt is to create the test environment, generate test data, build test binaries, execute the full regression test matrix (T001–T007), and generate reports. **Your task ends once both `regression_report.md` and `regression_report_junit.xml` exist with correct content.**

You MUST NOT:
- Modify source code files in `ringbuffer/src/<os>/cpp/*.cpp` or `ringbuffer/src/<os>/cpp/*.hpp`.
- Run `make verify` on the main library as a standalone step (this is handled within the consolidated pipeline).
- Generate new test scenarios beyond T001–T007.
- Proceed to performance benchmarking or additional validation beyond the defined test matrix.

**Directory Scope Restriction:**
- **NEVER create, modify, or delete any files outside the `tests/` directory and the OS cpp root** (except for `build.log`, `.gen_state.json`, and report files).
- The `tests/` directory is managed exclusively by this regression test workflow.

**Excluded Platforms:**
- **FreeBSD 14**, **FreeBSD 15**, and **ArchLinux** are excluded from active development.
- Do not modify, add content to, or create new files in `ringbuffer/prompts/freebsd14/`, `ringbuffer/prompts/freebsd15/`, or `ringbuffer/prompts/archlinux/`.
- The only files that should exist in these directories are zero-length `build.md`, `functional.md`, and `testing.md` files.
- If these directories contain any non-zero files, remove them.

If the user wants build changes, they will issue a separate request (e.g., "implement build" or "fix the Makefile"). Do not assume build changes are part of a regression test request.
