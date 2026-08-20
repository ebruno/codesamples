# Regression Test Execution

**Objective:** 
Execute the regression test matrix (T001–T007) on an already-set-up platform. This covers build, test execution, artifact verification, report generation, state tracking, and log finalization.

**Prerequisite:** Infrastructure setup from `prompts/common/implement_regression.md` must be completed before proceeding. The `tests/` directory, test Makefile, Dockerfile, utility scripts, and test data must already exist.

**Inputs:**
1. **Target OSes**: One or more operating systems to target (e.g., `fedora`, `debian,ubuntu`). If not specified, all OSes in `src/` are processed.
2. **Target Image**: An optional container image override (e.g., `fedora:43`, `debian:12`). If provided, this overrides the default image specified in each OS's `create_regression.md`.

**Process:**
1. **Target Selection & Host-OS Routing**:
   - **Host-OS Auto-Detection**: At the start of every run, detect the host OS:
     - If `uname -s` returns `Darwin`, set `host_os = macOS`.
     - If it returns `Linux`, read the distro ID from `/etc/os-release`: `host_os=$(grep '^ID=' /etc/os-release | cut -d= -f2)`.
     - Supported Linux distros: `ubuntu`, `debian`, `fedora`, `raspios`, `archlinux`.
   - **Targeting**:
     - **Specified Platform + Language**: If the user specifies a language and platform (e.g., "run regression for java on fedora"), run tests only for that language on that OS. Run natively if host matches target; use container if host doesn't match.
     - **Specified Platform Only**: If the user specifies a platform but no language (e.g., "run regression for debian"), run tests for all implemented languages on that OS. Run natively if host matches target; use container if host doesn't match.
     - **Specified Language Only**: If the user specifies a language but no platform (e.g., "run regression for java"), run tests for that language on all supported OSes using the routing table below.
     - **General Request (no platform, no language)**: Run tests for all implemented languages on all supported OSes using the routing table below.
   - **Routing Table** (applies when no specific OS is given, or when host ≠ target):
     | Host OS | Target OS | Action |
     |---------|-----------|--------|
     | macOS | macos | Run natively |
     | macOS | debian/fedora/ubuntu/raspios | Use `container` command to run in target OS container |
     | Fedora | fedora | Run natively |
     | Fedora | debian/ubuntu/raspios | Use `podman` to run in target OS container |
     | Fedora | macos | **Skip** — macOS cannot be containerized |
     | Debian | debian | Run natively |
     | Debian | fedora/ubuntu/raspios | Use `podman` to run in target OS container |
     | Debian | macos | **Skip** — macOS cannot be containerized |
     | Ubuntu | ubuntu | Run natively |
     | Ubuntu | debian/fedora/raspios | Use `podman` to run in target OS container |
     | Ubuntu | macos | **Skip** — macOS cannot be containerized |
     | raspios | raspios | Run natively (arm64 native on Apple Silicon) |
     | raspios | debian/fedora/ubuntu | Use `podman` to run in target OS container |
     | raspios | macos | **Skip** — macOS cannot be containerized |
     | macOS | archlinux | **Skip** — Arch Linux is Linux-hosts-only (no container images for Apple Silicon) |
     | Fedora | archlinux | Use `podman` to run in target OS container |
     | Debian | archlinux | Use `podman` to run in target OS container |
     | Ubuntu | archlinux | Use `podman` to run in target OS container |
     | raspios | archlinux | Use `podman` to run in target OS container |
     | Arch Linux | archlinux | Run natively (Linux-hosts-only) |
     | Arch Linux | macos | **Skip** — macOS cannot be containerized |
     | freebsd14 | freebsd14 | Run natively (FreeBSD is native-only, no containers) |
     | macOS | freebsd14 | **Skip** — FreeBSD is native-only, no containers available on macOS |
     | Fedora | freebsd14 | **Skip** — FreeBSD is native-only, no containers available on Linux |
     | Debian | freebsd14 | **Skip** — FreeBSD is native-only, no containers available on Linux |
     | Ubuntu | freebsd14 | **Skip** — FreeBSD is native-only, no containers available on Linux |
     | raspios | freebsd14 | **Skip** — FreeBSD is native-only, no containers available on Linux |
     | Arch Linux | freebsd14 | **Skip** — FreeBSD is native-only, no containers available on Linux |
   - **Mode Override**: If the request includes `use container`, force container execution for all non-macOS targets, overriding native routing.
   - **Container Runtime Selection**:
     - macOS host → use `container` command (Apple Container)
     - Linux host → use `podman`
   - **macOS is native-only**: macOS builds and tests NEVER use containers, regardless of host OS.
   - **FreeBSD is native-only**: FreeBSD builds and tests NEVER use containers, regardless of host OS.
   - **Entry Point** (C/C++ only): When targeting a specific C/C++ OS, first check if `prompts/<os>/cpp/create_regression.md` exists.
     - **If it exists**: Consult it for image resolution and platform-specific directives.
     - **If it does not exist**: Proceed with only `prompts/common/cpp/testing.md` as the specification. Skip platform-specific directives and log: `[timestamp] create_regression.md not found for <os> — proceeding with common spec only.`

2. **Language Dispatch**:
   After target selection, determine which language(s) to process and dispatch accordingly:

   **Common Languages (Java, Python)** — source lives in `src/common/<lang>/`, identical across all OSes:
   - **Skip Steps 0–7** (these are C/C++-specific). Go directly to the language-specific section below.
   - For each target OS, apply routing (native if host matches; container otherwise).
   - Each common language manages its own `.gen_state.json` in `src/common/<lang>/`.

   **C/C++** — source lives in `src/<os>/cpp/`, per-OS implementation:
   - Proceed to Steps 0–7 below.

---

### C/C++ Execution Steps (Steps 0–7)
*These steps apply ONLY to C/C++. Common languages skip directly to their own sections below.*

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
          ProductVersion:	26.5.2
          BuildVersion:	25F84
          ```
          Help: `sw_vers -h` → Usage: sw_vers [--help|--productName|--productVersion|--productVersionExtra|--buildVersion]
        - **Apple Container Runtime**: macOS uses the `container` command (Apple Container), NOT Docker or podman. This is unique to macOS Apple Silicon machines. Key subcommands:
          - `container run` — Run a container
          - `container build` / `container image build` — Build an image from Dockerfile
          - `container images` / `container image list` — List images
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
        - **JUnit Report**: Confirm that `reports/cpp/per_os/<os>_regression_report_junit.xml` was generated and follows the required JUnit XML structure.
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
      - Generate the Markdown regression report at `reports/cpp/per_os/<os>_regression.md` and JUnit XML at `reports/cpp/per_os/<os>_regression_report_junit.xml` using the following format:

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

      - Generate the JUnit XML report at `reports/cpp/per_os/<os>_regression_report_junit.xml` following the mandated JUnit XML structure, including per-test `<testcase time="...">` attributes and a `<system-out>` summary with total execution time.
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

   ---

**Error Handling Discipline** (applies to ALL languages and platforms):
- When `verify_build` or `run_regression` encounters an error for a specific language/os combination:
  1. **STOP** processing that language/os immediately — do NOT attempt to fix the error.
  2. **Record** the full error details (command run, output, exit code) in that language/os's individual report file.
  3. **Move on** to the next language/os in the list — do not let one failure block testing of other platforms.
  4. **Do NOT make any changes** to source files, build configs, or platform overrides unless the user has explicitly granted permission.
- This prevents agents from silently fixing issues during verification/regression runs, which masks real problems and makes unauthorized changes.
- The agent's role is to **detect and report**, not to **fix and continue**.

**Error Reporting Structure** (at the end of all processing):
- After all language/os combinations have been processed, generate a final summary section with:
  1. **Overall Status**: Count of passed vs failed language/os pairs.
  2. **TODO List**: A numbered list of all lang/os pairs that encountered errors, with:
     - Platform and language (e.g., `1. Java on Raspberry Pi OS`)
     - Brief error description (e.g., `JDK 17 does not support <release>25</release>`)
     - Location of detailed error in individual report (e.g., `See src/raspios/java/reports/verify_report.md`)
  3. **Full Error Details**: For each failed lang/os pair, include the complete error output in a collapsible or clearly delimited section.
- Example format:
  ```
  ## Error Summary
  **Passed:** 5/7 | **Failed:** 2/7

  ### TODO — Items Requiring User Attention
  1. **Java on Raspberry Pi OS**
     - Error: JDK 17 does not support `<release>25</release>` in pom.xml
     - Detail: `error: release version 25 not supported`
     - See: `src/raspios/java/reports/verify_report.md`
  2. **Java on Arch Linux**
     - Error: JDK 21 does not support `<release>25</release>` in pom.xml
     - Detail: `error: release version 25 not supported`
     - See: `src/archlinux/java/reports/verify_report.md`

  ### Full Error Details
  #### Java on Raspberry Pi OS
  ```
  [full error output, command run, exit code]
  ```
  #### Java on Arch Linux
  ```
  [full error output, command run, exit code]
  ```
  ```

**Universal Toolchain Compatibility Gate** (applies to ALL languages — runs BEFORE any build attempt):
- This is a **blocking gate** for every language and platform — tests cannot proceed until toolchain versions match.
- For each target OS, BEFORE executing any language-specific build or test:
  1. **Check for an existing platform-specific override** at `src/<os>/<lang>/`:
     - Java: `pom.xml`
     - C/C++: Makefile with platform-specific flags, or `version.mk` compatibility
     - Python: per-OS Makefile with correct interpreter path
     - Go: `go.mod` with compatible version constraint
     - Rust: `Cargo.toml` with compatible edition/target
  2. **If an override exists**: verify it matches the detected toolchain version (see step 3). If it does, proceed to build. If not, update the override (step 4).
  3. **Detect the actual toolchain version** in the target environment (container or remote):
     - **Java**: `JDK_VER=$(java -version 2>&1 | grep 'version' | head -1 | sed 's/.*"\([0-9]*\).*/\1/')`
     - **C/C++**: `CC_VER=$($CC --version 2>&1 | head -1)` (detect compiler and version)
     - **Python**: `PY_VER=$(python3 --version 2>&1 | awk '{print $2}' | cut -d. -f1,2)`
     - **Go**: `GO_VER=$(go version 2>&1 | awk '{print $3}' | sed 's/go//')`
     - **Rust**: `RUST_VER=$(rustc --version 2>&1 | awk '{print $2}')`
  4. **If no override exists, or the existing one does not match**: create a platform-specific override with the correct version baked in:
     ```bash
     # Example for Java (JDK version too low):
     if [ "$JDK_VER" -lt "$POM_RELEASE" ]; then
         echo "Creating platform override: JDK $JDK_VER does not support <release>$POM_RELEASE</release>"
         mkdir -p src/<os>/<lang>/
         sed "s|<release>$POM_RELEASE</release>|<release>$JDK_VER</release>|g" src/common/<lang>/pom.xml > src/<os>/<lang>/pom.xml
         echo "Created src/<os>/<lang>/pom.xml with <release>$JDK_VER</release>"
     fi
     ```
     - For C/C++: If the detected compiler does not support required flags (e.g., `-std=c++20`), create a platform-specific Makefile override with compatible flags.
     - For Python: If detected version is below minimum, create a platform-specific Makefile override targeting the available version.
     - For Go/Rust: If detected version is below minimum, create a platform-specific build config override.
  5. **Log**: `[timestamp] Toolchain compatibility check: lang=<lang> detected=<version> required=<config_version> STATUS=OK|MISMATCH override_created=<yes|no>`
  6. **This gate must pass for every language/platform combination** before any build or test command is executed.
  7. **Key principle**: Check for overrides first, create them if missing (with correct version baked in), then proceed on the **first try**. No STOP/re-execute loop needed.

**Java Test Execution** (from `src/common/java/`):
- Java is a **common language** — source lives in `src/common/java/` but tests must run on each supported OS.
- **Determine target OSes to test**:
  - If a specific OS was requested → only that OS.
  - Otherwise → all supported OSes (macos, debian, fedora, ubuntu, raspios) using the routing table.
- For each target OS:
  1. **Routing Decision**: Apply the routing table from Step 1.
     - If target is macOS and host is not macOS → **SKIP** (macOS cannot be containerized).
     - If target matches host → run natively.
     - Otherwise → use container with the appropriate runtime (`container` on macOS host, `podman` on Linux host).
  2. **Container Pre-flight Check** (Linux targets only):
     - macOS host: `command -v container` — if not found, STOP.
     - Linux host: `command -v podman` — if not found, STOP.
  3. **Execute Tests**:
     - **Native**: Navigate to `src/common/java/`, then run tests directly.
       After Maven completes, copy JUnit XML to the reports directory:
       ```bash
       cp target/surefire-reports/TEST-*.xml reports/java/per_os/<os>_regression_report_junit.xml
       ```
     - **Container**: Run in a container matching the target OS:
       - First, resolve the image from the per-OS Dockerfile: `IMAGE=$(head -1 src/common/java/containers/<os>/Dockerfile | sed 's/^FROM //')`
       - If no per-OS Dockerfile exists, fall back to the C/C++ Dockerfile: `IMAGE=$(head -1 src/<os>/cpp/containers/Dockerfile | sed 's/^FROM //')`
       - **Per-platform pom.xml override**: If a platform-specific `pom.xml` exists at `src/<os>/java/pom.xml`, mount it to override the common pom.xml. This is required when the platform's JDK version differs from the common spec (e.g., raspios has JDK 17, but common pom.xml uses `<release>25</release>`).
       ```bash
       # macOS host targeting Linux distro:
       if [ -f src/<os>/java/pom.xml ]; then
           container run --rm -v $(pwd)/src/common/java:/app -v $(pwd)/src/<os>/java/pom.xml:/app/pom.xml $IMAGE sh -c "cd /app && mvn test package -DskipTests && rm -rf target/classes target/test-classes"
       else
           container run --rm -v $(pwd)/src/common/java:/app $IMAGE sh -c "cd /app && mvn test package -DskipTests && rm -rf target/classes target/test-classes"
       fi
       # Linux host targeting another Linux distro:
       if [ -f src/<os>/java/pom.xml ]; then
           podman run --rm -v $(pwd)/src/common/java:/app -v $(pwd)/src/<os>/java/pom.xml:/app/pom.xml $IMAGE sh -c "cd /app && mvn test package -DskipTests && rm -rf target/classes target/test-classes"
       else
           podman run --rm -v $(pwd)/src/common/java:/app $IMAGE sh -c "cd /app && mvn test package -DskipTests && rm -rf target/classes target/test-classes"
       fi
       ```
  4. **Verification Steps**:
     - Navigate to `src/common/java/`.
     - Run `mvn test package -DskipTests` with timeout `${JAVA_BUILD_TIMEOUT_MS}` ms. Verify exit code 0.
     - Clean up intermediate build artifacts: `rm -rf target/classes target/test-classes`.
     - Verify test reports exist in `target/surefire-reports/`.
     - Verify no test failures in the output.
     - Verify JAR artifact exists in `target/`: `ls target/ringbuffer-*.jar`. If no JAR found, STOP and report build failure.
  5. **Log**: Append results to `src/common/java/logs/build.log` with the target OS noted: `[timestamp] Java tests on <target_os>: ROUTE=<native|container> STATUS=<PASS/FAIL>`.

  **Java State Tracking** (after all target OSes complete):
  - Read existing `.gen_state.json` from `src/common/java/` if it exists (created by `verify_build.md`). Preserve all existing fields.
  - Update/merge the following fields:
    - `os_results`: Add or update entries for each target OS with test results (route, image, status, timestamp).
    - `artifacts.test_reports`: Set to `target/surefire-reports/`.
    - Recompute SHA-256 hashes of `pom.xml` and `version.mk`.
  - If no existing `.gen_state.json`, create a new one with the full structure:
    ```json
    {
      "language": "java",
      "version": "<MAJOR.MINOR.SUBVERSION-BUILD_ID from version.mk>",
      "java_version": "<detected JDK version, e.g., 25.0.3>",
      "maven_version": "<detected Maven version, e.g., 3.9.16>",
      "os_results": {
        "<os>": {
          "route": "native|container",
          "image": "<resolved container image or N/A>",
          "status": "PASS|FAIL",
          "timestamp": "<ISO timestamp>"
        }
      },
      "artifacts": {
        "jar": "target/ringbuffer-<version>.jar",
        "test_reports": "target/surefire-reports/"
      },
      "sha256": {
        "pom_xml": "<hash>",
        "version_mk": "<hash>"
      }
    }
    ```
  - Compute SHA-256 hashes of `pom.xml` and `version.mk`.

  **Java Report Generation** (after all target OSes complete):
  - Generate the Markdown regression report at `reports/java/per_os/<os>_regression.md` and copy JUnit XML from `target/surefire-reports/TEST-*.xml` to `reports/java/per_os/<os>_regression_report_junit.xml` using the following format:

    ```markdown
    # Regression Verification Report — Java
    **Date:** [YYYY-MM-DD HH:MM:SS ±HHMM]
    **Start Time:** [YYYY-MM-DD HH:MM:SS ±HHMM]
    **End Time:** [YYYY-MM-DD HH:MM:SS ±HHMM]
    **Elapsed Time:** [Duration]
    **Host OS:** [Host OS Name/Version]

    ## Status
    **Final Result:** [PASS / FAIL]

    ## Audit Trail
    - **JDK**: [Version output from `java --version`]
    - **Maven**: [Version output from `mvn --version`]

    ## Per-OS Results
    | Target OS | Route | Image/Version | Status | Notes |
    |-----------|-------|---------------|--------|-------|
    | macos | native | JDK <ver> | [PASS/FAIL] | [Brief note] |
    | debian | container (debian:13) | JDK <ver> | [PASS/FAIL] | [Brief note] |
    | fedora | container (fedora:44) | JDK <ver> | [PASS/FAIL] | [Brief note] |
    | ubuntu | container (ubuntu:24.04) | JDK <ver> | [PASS/FAIL] | [Brief note] |

    ## Fixes and Modifications
    *If files were modified to achieve successful tests, list them here:*
    - `path/to/file`: [Brief explanation of the fix]

    ## Verification Details
    - **Maven Compile**: [Success/Failure]
    - **Maven Package**: [Success/Failure]
    - **JAR Artifact**: [Present/Absent] — `target/ringbuffer-<version>.jar`
    - **Test Reports**: [Present/Absent] — `target/surefire-reports/`
    - **Test Failures**: [Count] failures detected in surefire output
    ```

  **Java Self-Audit** (after report generation):
  - Verify the following and log results:
    - **JAR Artifact**: `target/ringbuffer-*.jar` exists and is non-empty.
    - **Test Reports**: `target/surefire-reports/` directory exists and contains test result files.
    - **No Test Failures**: surefire output shows 0 failures (check `target/surefire-reports/*.txt` for "Failures:" or "Errors:").
    - **Reports Generated**: `reports/java/per_os/<os>_regression.md` exists.
    - **JUnit XML**: `reports/java/per_os/<os>_regression_report_junit.xml` exists (copied from `target/surefire-reports/TEST-*.xml`).
    - **State File**: `src/common/java/.gen_state.json` was created/updated.

  ---

**Python Test Execution** (common source + platform-specific Makefile):
- Python is a **common language** — source lives in `src/common/python/` but tests must run on each supported OS.
- **Makefile Selection**:
  - GNU make systems (macOS, Linux): Use `src/common/python/Makefile.gnu`
  - BSD make systems (FreeBSD 14+): Use `src/<os>/python/Makefile` (per-OS directory with BSD-compatible Makefile)
- **Determine target OSes to test**:
  - If a specific OS was requested → only that OS.
  - Otherwise → all supported OSes (macos, debian, fedora, ubuntu, raspios, archlinux, freebsd14) using the routing table.
- For each target OS:
  1. **Routing Decision**: Apply the routing table from Step 1.
     - If target is macOS and host is not macOS → **SKIP** (macOS cannot be containerized).
     - If target matches host → run natively.
     - Otherwise → use container with the appropriate runtime (`container` on macOS host, `podman` on Linux host).
  2. **Container Pre-flight Check** (Linux targets only):
     - macOS host: `command -v container` — if not found, STOP.
     - Linux host: `command -v podman` — if not found, STOP.
  3. **Execute Tests**:
     - **Native**: Navigate to the appropriate Python directory (see Makefile Selection above), then run `make test`. The Makefile automatically:
       1. Attempts to build the C++ shared library from `src/<os>/cpp/` (target-host-specific).
       2. If the C++ build fails, gracefully falls back to Pure Python tests only.
       3. Logs all results (including skip reasons) to `logs/build.log`.
     - **JUnit Generation**: After running tests, generate JUnit XML by executing both test harnesses with `--junit` flag:
       ```bash
       # Clear any existing JUnit file
       rm -f reports/python/per_os/<os>_regression_report_junit.xml
       # Run Concurrent tests (T001-T007)
       for t in 1 2 3 4 5 6 7; do
           echo 'Hello, World! This is a test input for the ringbuffer pipeline.' | \
           python3 test_ringbuffer.py $t --junit reports/python/per_os/<os>_regression_report_junit.xml || exit 1
       done
       # Run Pure Python tests (T001-T007) — appends to same file
       for t in 1 2 3 4 5 6 7; do
           echo 'Hello, World! This is a test input for the ringbuffer pipeline.' | \
           python3 test_ringbuffer_pure.py $t --junit reports/python/per_os/<os>_regression_report_junit.xml || exit 1
       done
       ```
       The JUnit file will contain two `<testsuite>` elements: one for `ringbuffer_concurrent` and one for `ringbuffer_pure_python`, each with 7 `<testcase>` elements.
     - **Container**: Run in a container matching the target OS:
       - Build the per-OS Python container image first: `cd src/common/python && $(CONTAINER_CMD) build -t ringbuffer_python_<os> -f containers/<os>/build/Dockerfile .`
       - If no per-OS Dockerfile exists, fall back to the C/C++ Dockerfile: `IMAGE=$(head -1 src/<os>/cpp/containers/Dockerfile | sed 's/^FROM //')`
       ```bash
       # macOS host targeting Linux distro:
       cd src/common/python && container build -t ringbuffer_python_<os> -f containers/<os>/build/Dockerfile .
       # Run Concurrent version tests
       container run --rm -v $(pwd)/src/common/python:/app ringbuffer_python_<os> sh -c "cd /app && for t in 1 2 3 4 5 6 7; do echo 'Hello, World! This is a test input for the ringbuffer pipeline.' | python3 test_ringbuffer.py \$t || exit 1; done"
       # Run Pure Python version tests
       container run --rm -v $(pwd)/src/common/python:/app ringbuffer_python_<os> sh -c "cd /app && for t in 1 2 3 4 5 6 7; do echo 'Hello, World! This is a test input for the ringbuffer pipeline.' | python3 test_ringbuffer_pure.py \$t || exit 1; done"
       # Linux host targeting another Linux distro:
       cd src/common/python && podman build -t ringbuffer_python_<os> -f containers/<os>/build/Dockerfile .
       # Run Concurrent version tests
       podman run --rm -v $(pwd)/src/common/python:/app ringbuffer_python_<os> sh -c "cd /app && for t in 1 2 3 4 5 6 7; do echo 'Hello, World! This is a test input for the ringbuffer pipeline.' | python3 test_ringbuffer.py \$t || exit 1; done"
       # Run Pure Python version tests
       podman run --rm -v $(pwd)/src/common/python:/app ringbuffer_python_<os> sh -c "cd /app && for t in 1 2 3 4 5 6 7; do echo 'Hello, World! This is a test input for the ringbuffer pipeline.' | python3 test_ringbuffer_pure.py \$t || exit 1; done"
       ```
  4. **Verification Steps**:
     - Navigate to `src/common/python/`.
     - Verify Python version meets minimum requirements (3.10+): `python3 --version`.
     - **FreeBSD 14 exception**: Concurrent tests are SKIPPED on FreeBSD 14 due to RPATH limitation (`ld-elf.so.1` strips `$ORIGIN` from RUNPATH at runtime — dynamic library testing is not possible). Only Pure Python tests are run.
     - Run Concurrent version tests (7 scenarios): `for t in 1 2 3 4 5 6 7; do echo 'Hello, World! This is a test input for the ringbuffer pipeline.' | python3 test_ringbuffer.py $t || exit 1; done`. Verify exit code 0.
     - Run Pure Python version tests (7 scenarios): `for t in 1 2 3 4 5 6 7; do echo 'Hello, World! This is a test input for the ringbuffer pipeline.' | python3 test_ringbuffer_pure.py $t || exit 1; done`. Verify exit code 0.
     - Verify all expected outputs are produced correctly for both versions.
     - **Check C++ build status**: Look for `.cpp_build_failed` marker file in `src/common/python/`. If it exists, note the skip reason from `logs/build.log` (e.g., source directory missing, Makefile not found, build failure). If it does not exist, C++ build succeeded.
  5. **Performance Comparison** (Concurrent vs Pure Python):
     - Check if the C++ shared library is present in `src/common/python/swtr_ringbuffer/` (look for `.so`, `.dylib`, or `.dll`).
     - **If the C++ library exists**: Run `python3 benchmark.py` to perform a side-by-side performance comparison between the Concurrent (ctypes + C++ shared lib) and Pure Python implementations. Record timing results, speedup ratios, and overall summary in `src/common/python/logs/build.log`.
     - **If the C++ library does NOT exist**: Skip the performance comparison. Log a note explaining why (e.g., `C++ library not built for this platform — skipping performance comparison`). The Pure Python tests still run and are validated as above.
  6. **Log**: Append results to `src/common/python/logs/build.log` with the target OS noted: `[timestamp] Python tests on <target_os>: ROUTE=<native|container> STATUS=<PASS/FAIL> (Concurrent + Pure Python)`. If performance comparison was skipped, include the skip reason.

  **Python State Tracking** (after all target OSes complete):
  - Read existing `.gen_state.json` from `src/common/python/` if it exists (created by `verify_build.md`). Preserve all existing fields.
  - Update/merge the following fields:
    - `os_results`: Add or update entries for each target OS with test results (route, image, python_version, status, timestamp).
    - Recompute SHA-256 hashes of `version.mk`, both test modules, and both test scripts.
  - If no existing `.gen_state.json`, create a new one with the full structure:
    ```json
    {
      "language": "python",
      "version": "<MAJOR.MINOR.SUBVERSION-BUILD_ID from version.mk>",
      "python_version": "<detected Python version, e.g., 3.14.6>",
      "os_results": {
        "<os>": {
          "route": "native|container",
          "image": "<resolved container image or N/A>",
          "python_version": "<detected Python version in that context>",
          "status": "PASS|FAIL",
          "timestamp": "<ISO timestamp>"
        }
      },
      "artifacts": {
        "concurrent_module": "swtr_ringbuffer/swtr_ringbuffer_hp.py",
        "pure_python_module": "swtr_ringbuffer_pure.py",
        "test_script_concurrent": "test_ringbuffer.py",
        "test_script_pure": "test_ringbuffer_pure.py"
      },
      "sha256": {
        "version_mk": "<hash>",
        "base_py": "<hash>",
        "swtr_ringbuffer_hp_py": "<hash>",
        "swtr_ringbuffer_pure_py": "<hash>",
        "test_ringbuffer_py": "<hash>",
        "test_ringbuffer_pure_py": "<hash>"
      }
    }
    ```
  - Compute SHA-256 hashes of `version.mk`, both test modules, and both test scripts.

  **Python Report Generation** (after all target OSes complete):
  - Generate the Markdown regression report at `reports/python/per_os/<os>_regression.md` and JUnit XML at `reports/python/per_os/<os>_regression_report_junit.xml` using the following format:

    ```markdown
    # Regression Verification Report — Python
    **Date:** [YYYY-MM-DD HH:MM:SS ±HHMM]
    **Start Time:** [YYYY-MM-DD HH:MM:SS ±HHMM]
    **End Time:** [YYYY-MM-DD HH:MM:SS ±HHMM]
    **Elapsed Time:** [Duration]
    **Host OS:** [Host OS Name/Version]

    ## Status
    **Final Result:** [PASS / FAIL]

    ## Audit Trail
    - **Python**: [Version output from `python3 --version`]
    - **C++ Build Status**: [SUCCESS / SKIPPED — reason] (checked via `.cpp_build_failed` marker in `src/common/python/`)

    ## Per-OS Results (Current Run)
    | Target OS | Route | Python Version | Status | Notes |
    |-----------|-------|---------------|--------|-------|
    | macos | native | 3.14.x | [PASS/FAIL] | Both Concurrent and Pure Python tested |
    | fedora | container | 3.x.x | [PASS/FAIL] | Both Concurrent and Pure Python tested |
    | debian | container | 3.x.x | [PASS/FAIL] | Both Concurrent and Pure Python tested |
    | ubuntu | container | 3.x.x | [PASS/FAIL] | Both Concurrent and Pure Python tested |
    | archlinux | native | 3.x.x | [PASS/FAIL] | Linux-hosts-only — both Concurrent and Pure Python tested |
    | raspios | container | 3.x.x | [PASS/FAIL] | Both Concurrent and Pure Python tested |
    | freebsd14 | native | 3.11.x | [PASS/FAIL] | Pure Python only — Concurrent skipped (FreeBSD 14 RPATH limitation) |

    **Note:** FreeBSD 14 Concurrent tests are skipped due to `ld-elf.so.1` stripping `$ORIGIN` from RUNPATH at runtime — dynamic library testing is not possible.

    ## Fixes and Modifications
    *If files were modified to achieve successful tests, list them here:*
    - `path/to/file`: [Brief explanation of the fix]

    ## Concurrent (ctypes) Test Results
    **Implementation:** `swtr_ringbuffer/swtr_ringbuffer_hp.py` — ctypes binding to C++ shared library for concurrent I/O
    **Entry Point:** `from swtr_ringbuffer import SwtrRingBuffer` (auto-selects Concurrent when available)

    | Test | Description | Result | Notes |
    |------|-------------|--------|-------|
    | T001 | Default (identity transform) | [PASS/FAIL] | Output matches input exactly |
    | T002 | Stress test (1 slot, 1-byte buffer) | [PASS/FAIL] | Handles extreme buffering constraints |
    | T003 | Uppercase transform | [PASS/FAIL] | ASCII letters converted to uppercase |
    | T004 | Small input, fast EOF | [PASS/FAIL] | Handles input smaller than buffer slot |
    | T005 | Fatal error mode | [PASS/FAIL] | Pipeline shuts down on fatal error |
    | T006 | Non-fatal error mode | [PASS/FAIL] | Pipeline continues after non-fatal error |
    | T007 | XOR transform (bit-inverted) | [PASS/FAIL] | All bits flipped via 0xFF XOR |

    **Overall:** [X]/7 tests passed. Concurrent (ctypes) selected as default via auto-import.

    **FreeBSD 14 Note:** Concurrent tests are SKIPPED on FreeBSD 14 due to RPATH limitation (`ld-elf.so.1` strips `$ORIGIN` from RUNPATH at runtime). Only Pure Python tests are run on FreeBSD 14.

    ## Pure Python Test Results
    **Implementation:** `swtr_ringbuffer_pure.py` — pure Python, no C++ dependency
    **Entry Point:** `from swtr_ringbuffer_pure import SwtrRingBufferPure`

    | Test | Description | Result | Notes |
    |------|-------------|--------|-------|
    | T001 | Default (identity transform) | [PASS/FAIL] | Output matches input exactly |
    | T002 | Stress test (1 slot, 1-byte buffer) | [PASS/FAIL] | Handles extreme buffering constraints |
    | T003 | Uppercase transform | [PASS/FAIL] | ASCII letters converted to uppercase |
    | T004 | Small input, fast EOF | [PASS/FAIL] | Handles input smaller than buffer slot |
    | T005 | Fatal error mode | [PASS/FAIL] | Pipeline shuts down on fatal error |
    | T006 | Non-fatal error mode | [PASS/FAIL] | Pipeline continues after non-fatal error |
    | T007 | XOR transform (bit-inverted) | [PASS/FAIL] | All bits flipped via 0xFF XOR |

    **Overall:** [X]/7 tests passed. Pure Python provides full feature parity with Concurrent version.

    ## Verification Details
    - **Python Version Check**: [PASS/FAIL] (>= 3.10 minimum)
    - **Test Execution**: [PASS/FAIL] (T001-T007 all passed for both implementations; FreeBSD 14: Pure Python only)
    - **Dual-Version Architecture**: Active (Concurrent selected via auto-select, Pure Python available as fallback)
    - **State File Updated**: .gen_state.json includes test results
    ```

  **Python Self-Audit** (after report generation):
  - Verify the following and log results:
    - **Concurrent Module**: `swtr_ringbuffer/swtr_ringbuffer_hp.py` exists and is non-empty.
    - **Pure Python Module**: `swtr_ringbuffer_pure.py` exists and is non-empty.
    - **Concurrent Test Script**: `test_ringbuffer.py` exists, is executable (or readable by python3), and exits 0.
    - **Pure Python Test Script**: `test_ringbuffer_pure.py` exists, is executable (or readable by python3), and exits 0.
    - **No Test Failures**: Pure Python test script shows 0 failures (7/7 passed). Concurrent: 7/7 passed on GNU make systems; SKIPPED on FreeBSD 14 (RPATH limitation).
    - **Reports Generated**: `reports/python/per_os/<os>_regression.md` exists.
    - **JUnit XML**: `reports/python/per_os/<os>_regression_report_junit.xml` exists (contains both Concurrent and Pure Python results).
    - **State File**: `src/common/python/.gen_state.json` was created/updated.
    - **C++ Build Status Noted**: Report includes C++ build status (SUCCESS or SKIPPED with reason) in the Audit Trail section.

**Final Aggregation** (after all languages complete):
- Run `utils/bin/aggregate_junit.sh` to merge all per-OS JUnit XML files into:
  - `reports/junit/aggregated.xml` — single merged JUnit document with `os` and `lang` attributes
  - `reports/junit/aggregated.html` — human-readable HTML summary viewable in a browser
- This step is optional but recommended for consolidated review.

**Directives:**
1. Use `prompts/<os>/cpp/testing.md` for platform-specific prerequisites (package lists, container settings).
2. Use `prompts/common/cpp/testing.md` as the primary testing specification.

**Reporting:**
The report generated in Step 4 (C/C++) or the language-specific section (Java/Python) serves as the final summary.

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
- For **common languages** (Java, Python): `.gen_state.json` and reports are managed in `src/common/<lang>/`.
- The `tests/` directory is managed exclusively by this regression test workflow.

**Excluded Platforms:**
- **C/C++**: FreeBSD 14, FreeBSD 15, and ArchLinux are excluded from active C/C++ development (no native build toolchain on FreeBSD).
- **Python/Java**: FreeBSD 14 Python is verified and active — regression testing IS executed for common languages on FreeBSD 14.
- **ArchLinux**: Excluded from all active development (no container images for Apple Silicon).
- Do not modify, add content to, or create new files in `prompts/freebsd14/`, `prompts/freebsd15/`, or `prompts/archlinux/` **for C/C++**.
- For **C/C++**: The only files that should exist in these directories are zero-length `build.md`, `functional.md`, and `testing.md` files. If these directories contain any non-zero C/C++ prompt files, remove them.
- For **Python/Java**: Per-OS `testing.md` files may contain placeholder text (e.g., "Python is platform-insensitive — use common spec"). This is allowed and recommended to prevent zero-length file confusion.

If the user wants to set up test infrastructure from scratch, they should use `prompts/common/implement_regression.md` instead.