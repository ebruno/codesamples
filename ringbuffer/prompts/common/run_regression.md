# Regression Test Execution

**Objective:** 
Execute the regression test matrix (T001–T007) on an already-set-up platform. This covers build, test execution, artifact verification, report generation, state tracking, and log finalization.

**Prerequisite:** Infrastructure setup from `prompts/common/implement_regression.md` must be completed before proceeding. The `tests/` directory, test Makefile, Dockerfile, utility scripts, and test data must already exist.

**Inputs:**
1. **Target OSes**: One or more operating systems to target (e.g., `fedora`, `debian,ubuntu`). If not specified, all OSes in `src/` are processed.
2. **Target Image**: An optional container image override (e.g., `fedora:43`, `debian:12`). If provided, this overrides the default image specified in each OS's `create_regression.md`.

**Process:**
1. **Target Selection**:
   - **Specified Platforms**: If the user request specifies target platforms (e.g., "run regression for fedora, debian"), verify their existence in `src/`. If a requested platform is missing from `src/`, inform the user that the OS is not currently implemented and list all operating systems that are currently supported (those present as directories in `src/`). Process only the requested platforms that are implemented.
   - **General Request**: Otherwise, iterate through **all** OS directories found in `src/` (e.g., debian, fedora, ubuntu).
   - **Entry Point**: When targeting a specific OS, first check if `prompts/<os>/cpp/create_regression.md` exists.
     - **If it exists**: Consult it for image resolution and platform-specific directives.
     - **If it does not exist**: Proceed with only `prompts/common/cpp/testing.md` as the specification. Skip platform-specific directives and log: `[timestamp] create_regression.md not found for <os> — proceeding with common spec only.`

2. **Execution Steps**:
   For the selected OS directory, perform the following.

   0. **Environment Setup**:
      - **Timeout Configuration**: All timeout values are defined as variables for easy adjustment:
        - `CONTAINER_BUILD_TIMEOUT_MS`: 600,000 ms (10 minutes) — maximum time for `make container`
        - `TEST_EXECUTION_TIMEOUT_MS`: 600,000 ms (10 minutes) — maximum time for the full test matrix
      - **Resolve Image**: Determine the Target Image from Inputs (see above). If not provided by the user, read the default image from `prompts/<os>/cpp/create_regression.md` (look for an `IMAGE=` or `Default Image:` directive). If no image is specified in the per-OS file, derive it from `prompts/<os>/cpp/testing.md` (e.g., `fedora:44`, `debian:13`, `ubuntu:24.04`). If the resolved image is `N/A` (macOS native-only), log: `IMAGE=N/A (native-only platform)`. Otherwise, log: `IMAGE=<resolved_image>`.
      - **Shared Version Context**: Read the version from `src/<os>/cpp/.gen_state.json` (if it exists). This file was **created by `implement_functional.md`** and progressively enriched by subsequent steps (`implement_build.md` adds build artifact hashes, `run_regression.md` adds test artifact hashes). The version represents the Ringbuffer library version (`MAJOR.MINOR.SUBVERSION`). If `.gen_state.json` does not exist, read `src/<os>/cpp/version.mk` as a fallback. Log: `VERSION=<resolved_version>`.
      - **Execution Path Decision**: Detect the host OS. If `uname -s` returns `Darwin`, set `host_os = macOS`. If it returns `Linux`, read the distro ID from `/etc/os-release` using: `host_os=$(grep '^ID=' /etc/os-release | cut -d= -f2)`.
        - **macOS Host Detection**: When `uname -s` returns `Darwin`, the host OS is macOS. Use `sw_vers --productVersion` to get the actual macOS version (e.g., "26.5.2"). Example:
          ```
          $ sw_vers --productVersion
          26.5.2
          ```
          Full output:
          ```
          $ sw_vers
          ProductName:		macOS
          ProductVersion:		26.5.2
          BuildVersion:		25F84
          ```
          Help: `sw_vers -h` → Usage: sw_vers [--help|--productName|--productVersion|--productVersionExtra|--buildVersion]
        - **Apple Container Runtime**: macOS uses the `container` command (Apple Container), NOT Docker or podman. This is unique to macOS Apple Silicon machines. Key subcommands:
          - `container run` — Run a container (equivalent to `docker run`)
          - `container build` / `container image build` — Build an image from Dockerfile (equivalent to `docker build`)
          - `container images` / `container image list` — List images (equivalent to `docker images`)
          - `container system status` — Show container services status
          - `container system version` — Show container runtime version
          Help: `container --help` → Overview of all subcommands (run, build, images, exec, logs, etc.)
          System help: `container system --help` → df, dns, kernel, logs, property, start, status, stop, version
        - **Service Management**: The `container` daemon does NOT start automatically on macOS. This workflow includes an automatic service check and start step before any container operations. If you need to manually manage the service:
          - Check status: `container system status` — shows whether container services are active
          - Start service: `container system start` — starts the container daemon and required services
        - **Native Execution**: If `host_os == <os>` OR if the target `<os>` is `macos`, all test and verification steps MUST be performed natively on the host. Containers MUST NOT be used for macOS targets.
        - **Container Execution**: If `host_os != <os>` AND the target `<os>` is NOT `macos`, all test and verification steps MUST be performed inside the `ringbuffer_<os>_test` container.
        - **Log Your Decision**: Print a one-line summary to stdout and append it to `build.log`.
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
      - **Apple Container Service Start (macOS host, container execution only)**: If the Execution Path Decision determined container execution AND `host_os` is macOS, ensure the Apple Container daemon is running before any container operations:
        - Check service status: `container system status`
        - If the output indicates services are not running (or the command fails), start the daemon: `container system start`
        - Wait for the service to become ready, then verify again with `container system status`. If services are active, proceed.
        - Log: `[timestamp] Apple Container service verified — running.` or `[timestamp] Apple Container service started — services active.`
        - If the service fails to start, STOP and display:
          ```
          ERROR: Apple Container daemon failed to start.

          The 'container' command is installed but the service could not be started.
          Try running manually: container system start

          If the issue persists, check system logs with:
            container system logs

          After resolving the issue, re-run the build or test workflow.
          ```
      - **Navigate**: `cd src/<os>/cpp`
      - **Dockerfile/Image Validation (Linux targets only)**: If the target `<os>` is NOT `macos`:
        - **Validate Existing Dockerfile**: If the build Dockerfile exists at `src/<os>/cpp/containers/Dockerfile`, verify that the resolved Target Image matches its `FROM` base image tag. If it does not match, log an error and stop processing — the requested image conflicts with the existing container configuration.
        - **Validate Test Dockerfile**: If `tests/containers/<os>/Dockerfile` exists, verify its `FROM` base image matches the resolved Target Image. If it does not match, log an error and stop processing.
        - **Build Build Image**: Before creating the `_test` image, ensure the base `ringbuffer_<os>_build` image is present. Check if it already exists using `<runtime> images | grep ringbuffer_<os>_build`. If not found, execute `make container` from the source directory. Verify that `ringbuffer_<os>_build` exists using `<runtime> images | grep ringbuffer_<os>_build`.
        - **Test Image Management**: Ensure the `ringbuffer_<os>_test` image exists. If it does not, navigate to `tests/` and execute `make container`. Verify that `ringbuffer_<os>_test` exists using `<runtime> images | grep ringbuffer_<os>_test`.
      - If the target IS `macos`, log: `[timestamp] Dockerfile/Image validation skipped — macOS is native-only.` and proceed.
      - **Infrastructure Pre-flight**: Verify that the `tests/` directory exists and contains all required artifacts:
        - `tests/Makefile` — must exist with targets `all`, `static`, `dynamic`, `clean`, `dist-clean`, `container`, `verify`.
        - If the target `<os>` is NOT `macos`: `tests/containers/<os>/Dockerfile` — must exist.
        - If the target `<os>` is `macos`: skip Dockerfile check (native-only platform).
        - If the target `<os>` is `macos`: `tests/utils/bin/verify_test_data.zsh` — must exist and be executable.
        - If the target `<os>` is NOT `macos`: `tests/utils/bin/verify_test_data.sh` — must exist and be executable.
        - `tests/data/inputs/test001.txt` through `test007.txt` — must exist.
        - If any required artifact is missing, STOP and report: `[timestamp] Infrastructure incomplete — <missing artifact> not found. Run implement_regression.md first.`
      - **Log Initialization**: If `logs/build.log` does not exist, create it with the start timestamp and routing decision.

   1. **Infrastructure Verification**:
      - If the target `<os>` is `macos`, skip cross-platform verification and log: `[timestamp] Cross-platform verification skipped — macOS is native-only with different binary format (Mach-O).` Proceed to Step 2.
      - If the target `<os>` is NOT `macos`, verify that the test Makefile and Dockerfile conform to cross-platform symmetry requirements:
        - **Identify a Reference Platform**: First, check if `src/reference_linux/cpp/tests/Makefile` exists. If it does, use `reference_linux` as the reference platform (this is the canonical source of truth). If it does not exist, fall back to alphabetical iteration through directories in `src/` (e.g., `debian`, `fedora`, `ubuntu`) and select the first one where `src/<ref_os>/cpp/tests/Makefile` exists.
        - **Fallback**: If no reference platform has a test Makefile, skip cross-platform verification and log: `[timestamp] Cross-platform verification skipped — no reference platform available.` Proceed to Step 2.
        - **Test Makefile Comparison**: Strip the three allowed differences from both the test Makefile and the reference:
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
      - Create or update `.gen_state.json` in `src/<os>/cpp/` containing:
        - The resolved version (from shared context or `version.mk`).
        - The resolved image (`N/A` for macOS native-only platforms).
        - SHA-256 hashes of `common/cpp/testing.md` and `<os>/cpp/testing.md`.
        - SHA-256 hashes of all generated test artifacts (test Makefile, utility scripts). For Linux targets, also include the test Dockerfile hash.
        - File fingerprints for all source files.
      - **Version Change Detection**: Before updating `.gen_state.json`, compare the current `version.mk` values against those stored in `.gen_state.json`. If any value has changed (e.g., `MAJOR`, `MINOR`, `SUBVERSION`, or `BUILD_ID`), regenerate all versioned artifact names and symlinks in the `lib/` directory before proceeding.

   6. **Final Self-Audit**:
      - Verify the following and log results:
        - **Test Makefile Targets**: All required targets are present (`clean`, `dist-clean`, `container`, `verify`).
        - If the target `<os>` is NOT `macos`: **Test Dockerfile** (`tests/containers/<os>/Dockerfile`): Exists and has valid syntax (base image, package installation).
        - If the target `<os>` is `macos`: skip Dockerfile check (native-only platform).
        - **Test Data**: All seven test files (`test001.txt`–`test007.txt`) exist in `tests/data/inputs/`.
        - **Test Binaries**: Both `test001_staticlib` and `test001_dynamiclib` exist in `tests/bin/`.
        - **Reports**: Both `regression_report.md` and `regression_report_junit.xml` exist in `tests/reports/`.
        - **Source Consistency**: All test source files in `tests/src/` are listed in the test Makefile's build rules.
        - **Artifact Verification**: Test binaries (`test001_staticlib`, `test001_dynamiclib`) exist and are executable.

   7. **Finalize Logs**:
      - Append a final entry to `build.log` stating that the regression test execution is complete.
      - Calculate and include the total elapsed time since the start timestamp in this final entry.

**Directives:**
1. Use `prompts/<os>/cpp/testing.md` for platform-specific prerequisites (package lists, container settings).
2. Use `prompts/common/cpp/testing.md` as the primary testing specification.

**Reporting:**
The report generated in Step 4 serves as the final summary.

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions (e.g., `` ErrorOps.cpp`} ``, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.

## Scope Boundary — Execution Only

The purpose of this prompt is to **execute** the regression test matrix on an already-set-up platform. It assumes all infrastructure (directories, Dockerfile, Makefile, scripts, test data) was created by `prompts/common/implement_regression.md`.

You MUST NOT:
- Create the `tests/` directory structure from scratch (use `implement_regression.md` for that).
- Modify source code files in `src/<os>/cpp/*.cpp` or `src/<os>/cpp/*.hpp`.
- Generate new test scenarios beyond T001–T007.
- Proceed to performance benchmarking or additional validation beyond the defined test matrix.

**Directory Scope Restriction:**
- **NEVER create, modify, or delete any files outside the `tests/` directory and the OS cpp root** (except for `build.log`, `.gen_state.json`, and report files).
- The `tests/` directory is managed exclusively by this regression test workflow.

**Excluded Platforms:**
- **FreeBSD 14**, **FreeBSD 15**, and **ArchLinux** are excluded from active development.
- Do not modify, add content to, or create new files in `prompts/freebsd14/`, `prompts/freebsd15/`, or `prompts/archlinux/`.
- The only files that should exist in these directories are zero-length `build.md`, `functional.md`, and `testing.md` files.
- If these directories contain any non-zero files, remove them.

If the user wants to set up test infrastructure from scratch, they should use `prompts/common/implement_regression.md` instead.
