# Build Verification Workflow

**Objective:** 
Ensure the C++ implementation and its associated tests build successfully across all supported operating systems.

**Process:**
1. **Target and Mode Selection**:
   - **Targeting**: 
     - **Specified Platform**: If the user request specifies one or more target platforms (e.g., "run build_verify for debian" or "do regression_test on debian, fedora"), verify their existence in `ringbuffer/src/`. If a requested platform is missing from `ringbuffer/src/`, inform the user that the OS is not currently implemented and list all operating systems that are currently supported (those present as directories in `ringbuffer/src/`). Process only the requested platforms that are implemented.
     - **General Request**: Otherwise, iterate through **all** OS directories found in `ringbuffer/src/` (e.g., debian, fedora, macos).
   - **Mode**: If the request includes the phrase `use container` (e.g., "run build_verify for debian use container"), the container MUST be used for all builds, overriding the Host-OS Optimization rule.

2. **Execution Steps**:
   For the selected OS directory, perform the following:

   0. **Host OS Identification**:
      - Run `uname -s`.
      - **If result is `Darwin`**:
        - Run `sw_vers -productName`.
        - Convert the output to lowercase (e.g., "macOS" $\rightarrow$ "macos").
        - Store this as `host_os`.
      - **If result is NOT `Darwin`**:
        - Read the file `/etc/os-release`.
        - Extract the value assigned to `ID=` (e.g., `ID="debian"` $\rightarrow$ "debian").
        - Store this as `host_os`.

   0.1 **Execution Path Decision**:
      - Compare `host_os` with the target `<os>` (debian, fedora, macos).
      - **Native Execution**: If `host_os == <os>` OR if the target `<os>` is `macos`, the build and verification pipeline MUST be performed natively on the host. Containers MUST NOT be used for macOS targets.
      - **Container Execution**: If `host_os != <os>` AND the target `<os>` is NOT `macos`, or if the mode "use container" was specified (and target is not macos), the workflow MUST use the `ringbuffer_<os>_test` container.

   0.2 **Baseline Image Bootstrap (Level 0)**:
      - **Requirement**: Before creating the `_test` image, the base `ringbuffer_<os>_build` image MUST be present and current.
      - **Action**: Navigate to `ringbuffer/src/<os>/cpp` and execute `make container`.
      - **Verification**: Confirm that `ringbuffer_<os>_build` exists using `container images | grep ringbuffer_<os>_build`.

   0.3 **`ringbuffer_<os>_test` Image Management**:
      - **Mandate**: For Linux platforms (Debian, Fedora), the `ringbuffer_<os>_test` image is the authoritative environment for all subsequent build and verify steps.
      - **Bootstrap Step**: Use the base build image to trigger the creation/update of the test image:
        - Linux: `podman run --rm -v \$(pwd):/app ringbuffer_<os>_build sh -c "cd /app/cpp/tests && make container"`
      - **Lifecycle Check**: The `make container` target in `tests/Makefile` MUST:
        1. Check if `ringbuffer_<os>_test` exists.
        2. Compare the modification date of `tests/containers/<os>/Dockerfile` AND `version.mk` with the image creation date.
        3. Build the image using `container build -t ringbuffer_<os>_test -f tests/containers/<os>/Dockerfile .` if either file is newer or the image is missing.

   0.4 **Resource Allocation (macOS Host)**:
      - Run `vm_stat`.
      - Extract the page size from the first line (e.g., `16384`).
      - Extract `Pages free` and `Pages inactive`.
      - Calculate total available bytes: `(Pages free + Pages inactive) * page size`.
      - Convert to GiB: `total bytes / 1,073,741,824`.
      - Set container memory limit (`-m`) to 50% of this value, capped at 3 GB.
      - Store this as `<memory_limit>`.

   0.5 **Test Environment Pre-flight**:
      - **Requirement**: Verify if the `tests/` directory exists in `ringbuffer/src/<os>/cpp/`.
      - **Mandate**: If the `tests/` directory is missing, it MUST be generated from scratch following the specifications in `ringbuffer/prompts/common/cpp/testing.md` and `ringbuffer/prompts/<os>/cpp/testing.md`.
      - **Prohibition**: DO NOT copy the `tests/` directory from another operating system. All test artifacts, including the `Dockerfile` in `tests/containers/<os>/`, must be created based on the prompts to ensure toolchain and environment compatibility.

   1. **Consolidated Build and Verification**:
      - **Timeout Limit**: Container execution timeouts must be limited to a maximum of 600,000 ms (10 minutes).
      - **Navigate**: `cd ringbuffer/src/<os>`
      - **Execute (Split Pipeline)**:
        - Use `JOBS` (e.g., 4 or 8) to enable parallel compilation.
        - **Step 1: Build Library and Tests**:
          - **Native**: `cd cpp && make clean && make -j\$(JOBS) && if [ -d tests ]; then cd tests && make clean && make -j\$(JOBS); else echo 'ERROR: Tests directory missing.'; exit 1; fi`
          - **Container**: `container run --rm -m <memory_limit> -v \$(pwd):/app ringbuffer_<os>_test sh -c "cd /app/cpp && make clean && make -j\$(JOBS) && if [ -d tests ]; then cd tests && make clean && make -j\$(JOBS); else echo 'ERROR: Tests directory missing.'; exit 1; fi"`
        - **Step 2: Run Verification**:
          - **Native**: `cd cpp && make verify`
          - **Container**: `container run --rm -m <memory_limit> -v \$(pwd):/app ringbuffer_<os>_test sh -c "cd /app/cpp && make verify"`
      - **Timing Requirements**:
        - **Start Time**: The report `Start Time` MUST be captured at the exact moment the `make verify` target is invoked in the `tests/Makefile`.
        - **End Time**: The report `End Time` MUST be captured immediately after the final test scenario (T007) in the test matrix has completed its execution.
      - **Verify Artifacts**:
        - Confirm that both `test001_staticlib` and `test001_dynamiclib` were created in the `bin/` directory of the tests folder.
        - Confirm that the `make verify` target passed for the main library.
        - **JUnit Report**: Confirm that `tests/reports/regression_report_junit.xml` was generated and follows the required JUnit XML structure.
      - **Evaluate**: If any step fails, analyze logs, apply fixes to the workspace (either in the library or the test source), and repeat the entire consolidated pipeline.

**Reporting:**
For each platform processed, generate a detailed report at `ringbuffer/src/<os>/reports/regression_report.md` using the following format:

# Regression Verification Report - [OS Name]
**Date:** [YYYY-MM-DD HH:MM:SS ±HHMM]
**Start Time:** [YYYY-MM-DD HH:MM:SS ±HHMM]
**End Time:** [YYYY-MM-DD HH:MM:SS ±HHMM]
**Elapsed Time:** [Duration]
**Host OS:** [Host OS Name/Version]

## Status
**Final Result:** [PASS / FAIL]

## Audit Trail
- **Compiler**: [Version output from -v]
- **Linker**: [Version output from -v]

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

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions (e.g., `.cpp`, `.hpp`, or `Makefile`), such as `` ErrorOps.cpp`} ``, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.
<EOF>
