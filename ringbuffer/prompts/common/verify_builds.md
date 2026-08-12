# Build Verification Workflow

**Objective:** 
Ensure the C++ implementation builds successfully across all supported operating systems.

**Process:**
1. **Target and Mode Selection**:
   - **Targeting**: 
     - **Specified Platform**: If the user request specifies one or more target platforms (e.g., "run build_verify for debian" or "do regression_test on debian, fedora"), verify their existence in `ringbuffer/src/`. If a requested platform is missing from `ringbuffer/src/`, inform the user that the OS is not currently implemented and list all operating systems that are currently supported (those present as directories in `ringbuffer/src/`). Process only the requested platforms that are implemented.
     - **General Request**: Otherwise, iterate through **all** OS directories found in `ringbuffer/src/` (e.g., debian, fedora, macos).
   - **Mode**: If the request includes the phrase `use container` (e.g., "run build_verify for debian use container"), the container MUST be used for all supported builds (excluding macOS), overriding the Host-OS Optimization rule.

2. **Execution Steps**:
   For the selected OS directory, perform the following:

   **Timeout Configuration**: All timeout values are defined as variables for easy adjustment:
   - `CONTAINER_BUILD_TIMEOUT_MS`: 600,000 ms (10 minutes) — maximum time for `make container`
   - `LIBRARY_BUILD_TIMEOUT_MS`: 600,000 ms (10 minutes) — maximum time for `make clean && make`

   **Log Initialization**: Before performing any build operations, create the log directory `ringbuffer/src/<os>/cpp/logs/` if it does not exist. Record the start timestamp in a variable (e.g., `START_TIME=$(date '+%Y-%m-%d %H:%M:%S %z')`). Initialize `build.log` with the start timestamp and action description ("Build verification started"). If `build.log` already exists, append to it rather than overwriting.

   0. **Execution Strategy**:

      0.1 **Execution Path Decision**:
         - Detect the host OS: If `uname -s` returns `Darwin`, set `host_os = macOS`. If it returns `Linux`, read the distro ID from `/etc/os-release` using: `host_os=$(grep '^ID=' /etc/os-release | cut -d= -f2)`.
         - **Native Execution**: If `host_os == <os>` (e.g., host is Fedora and target is fedora) OR if the target `<os>` is `macos`, the build and verification pipeline MUST be performed natively on the host. Containers MUST NOT be used for macOS targets.
         - **Container Execution**: If `host_os != <os>` AND the target `<os>` is NOT `macos`, or if the mode 'use container' was specified (and target is not macos), the workflow MUST use the `ringbuffer_<os>_build` container.
         - **Log Your Decision**: Before executing any build command, print a one-line summary to stdout AND append it to `ringbuffer/src/<os>/cpp/logs/build.log`:
           ```
           HOST=<host_os> TARGET=<os> ROUTING=container|native REASON=<brief explanation>
           ```
      0.15 **Container Runtime Pre-flight Check**:
         - **Trigger Condition**: If the Execution Path Decision (step 0.1) determined that container execution is required:
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
      0.2 **Container Pre-check and Resource Allocation**:
         - **Source Directory Check**: Verify that `ringbuffer/src/<os>/cpp/` exists. If it does NOT exist, log: `[timestamp] Source directory missing — ringbuffer/src/<os>/cpp/ not found. Cannot proceed with build verification.` and STOP processing this platform.
         - **Container Image Check**: Verify that the required build container `ringbuffer_<os>_build` exists on the host system.
         - **Command**: Use the appropriate container runtime for the host (e.g., `podman` on Linux, `container` on macOS) to check for the image: `<runtime> images | grep ringbuffer_<os>_build`.
         - **Action**: If the image is missing or outdated, navigate to `ringbuffer/src/<os>/cpp` and execute `make container`. Set a timeout of `${CONTAINER_BUILD_TIMEOUT_MS}` ms for this operation. If the timeout is exceeded, log: `[timestamp] Container build timed out after ${CONTAINER_BUILD_TIMEOUT_MS} ms. Stopping.` and STOP processing this platform.
         - **Container Build Failure Procedure**: If `make container` fails:
           1. Capture the full error output from the failed command.
           2. Analyze logs to determine root cause (Dockerfile errors, missing base image, failed package installation).
           3. Apply the minimal fix required (e.g., correct Dockerfile syntax, update package names).
           4. Retry at most **1 time**.
           5. If the retry fails, STOP immediately and report:
              ```
              CONTAINER BUILD FAILED — <os>

              Command: make container
              Exit code: <exit_code>

              Error output:
              <full error output>

              Recommendation: Investigate manually. Check `cpp/logs/build.log` and `src/<os>/cpp/containers/Dockerfile`.
              ```
         - **Container Build Success**: After `make container` completes successfully (or if the image was already present), log: `[timestamp] Container build completed — ringbuffer_<os>_build ready.`
      0.3 **Image Management**:
         - For Linux platforms (Debian, Fedora), the `ringbuffer_<os>_build` image is the authoritative environment for all subsequent build and verify steps.

   1. **Build System Validation**:
      - Navigate to `ringbuffer/src/<os>/cpp`.
      - Verify that `Makefile` and `version.mk` exist. If either is missing, log: `[timestamp] Build system validation FAILED — <filename> not found. Cannot proceed.` and STOP processing this platform.
      - **Toolchain Verification**: Ensure the required tools listed in the platform's build requirements (`prompts/<os>/cpp/build.md` and `prompts/common/cpp/build.md`) are available for the target OS. For each required tool, verify with `command -v <tool>`. If any tool is missing, log: `[timestamp] Toolchain verification FAILED — required tool '<tool>' not found in PATH. Cannot proceed.` and STOP processing this platform.
      - **Toolchain Logging**: After determining the execution path, log which compiler will be used: `[timestamp] Toolchain: <CXX> version <version>` (obtained via `<CXX> --version`).
      - **Recovery**: If critical build files are missing (Makefile, `containers/Dockerfile`, or `version.mk`), generate them independently from `ringbuffer/prompts/common/cpp/build.md` and the target platform's build spec. Do NOT copy build files from other platforms. Log: `[timestamp] Build file recovery — generated independently, no files copied from other platforms.`

   2. **Library Build**:
      - **Execution**:
        - **Navigate**: `cd ringbuffer/src/<os>`
        - **Execute**: 
          - Ensure the container execution timeout is set to a maximum of `${LIBRARY_BUILD_TIMEOUT_MS}` ms.
          - If executing in a container: Use the appropriate container runtime for the host (e.g., `podman` on Linux, `container` on macOS): `<runtime> run --rm -m 2G -v $(pwd):/app ringbuffer_<os>_build sh -c "cd /app/cpp && make clean && make"`.
          - If executing natively: `cd cpp && make clean && make`.
        - **Log Success**: If the build succeeds, log to `build.log`: `[timestamp] Library build completed successfully — <os> target`
        - **Evaluate**: If this fails, follow the procedure below. Do NOT loop indefinitely.

        **Library Build Failure Procedure:**
        1. Capture the full error output from `make`.
        2. Analyze logs to determine root cause (compiler errors, missing files, toolchain issues).
        3. Apply the minimal fix required.
        4. Retry at most **1 time**.
        5. If the retry fails, STOP immediately. Do NOT retry again.
           Report the error with diagnostic output and escalate to the user:
           ```
           LIBRARY BUILD FAILED — [OS Name]

           Command: make clean && make
           Exit code: <exit_code>

           Error output:
           <full error output>

           Fixes attempted:
           - <fix 1>: <description>

           Recommendation: Investigate manually. Check `cpp/logs/build.log`.
           ```

   2.5 **Artifact Verification**: After a successful build, verify the produced artifacts and log each result to `ringbuffer/src/<os>/cpp/logs/build.log`:
      - **Pre-check**: Verify that `lib/` directory exists and contains `.a` and `.so` files. If not, log: `[timestamp] Artifact check — SKIPPED: lib/ directory missing or empty. Build may have produced artifacts elsewhere.` and skip to Step 3.
      - **Architecture**: Run `file -L` on both `.a` and `.so` files in the `lib/` directory. The `-L` flag follows symlinks to versioned artifacts. PASS if output contains "ELF 64-bit" for Linux targets; FAIL otherwise (e.g., "Mach-O", "ELF 32-bit"). Log: `[timestamp] Artifact check - Architecture: PASS/FAIL — <output>`
      - **SONAME**: Run `readelf -d lib/libswtr_ringbuffer.so` and verify it contains `SONAME [libswtr_ringbuffer.so]`. PASS if the exact string is present; FAIL otherwise. Log: `[timestamp] Artifact check - SONAME: PASS/FAIL — <output>`
      - **Binary Size**: Run `size` on both artifacts. Parse the total column to record the byte count for the report. Log: `[timestamp] Artifact check - Binary Size: <total> bytes (text=<t>, data=<d>, bss=<b>)`
      - **Symbol Visibility**: Run `nm -gjU lib/libswtr_ringbuffer.so`. PASS if the output contains only expected public symbols (e.g., `RingBuffer`, `SwtrRingBuffer` and their methods) with no internal implementation symbols; FAIL if internal symbols are visible. Log: `[timestamp] Artifact check - Symbol Visibility: PASS/FAIL — <summary>`
      - If any check fails, record it in the report and continue (do not stop — these are informational).

   3. **Source Consistency Check**:
      - List all `.cpp` files in the source directory and compare against the `SRCS` variable in the Makefile. Log: `[timestamp] Source consistency check — found <N> .cpp files, SRCS lists <M> files`
      - **Action**: If any `.cpp` file is missing from the build:
        1. Log: `[timestamp] Source consistency — MISSING FILE DETECTED: <filename>`
        2. Update the `Makefile` to include the missing file(s) in the `SRCS` variable. Log: `[timestamp] Makefile updated — added <filename> to SRCS`
        3. Retry the **Library Build** step (Step 2) at most **1 time**.
        4. If the build still fails after this single retry, STOP and report the failure using the procedure in Step 2.
      - If all files are accounted for, log: `[timestamp] Source consistency check — PASS. All .cpp files present in SRCS.`

   **Workflow Completion**: After all steps are complete (or stopped due to failure), calculate the elapsed time by subtracting the start timestamp from the current timestamp. Format as `HH:MM:SS` or human-readable duration (e.g., "2h 15m 30s"). Log the final status:
   - On success: `[timestamp] Build verification completed successfully — <os> target. Total elapsed time: <duration>.`
   - On failure: `[timestamp] Build verification FAILED — <os> target. Total elapsed time: <duration>. See report at ringbuffer/src/<os>/reports/build_verification_report.md.`

**Reporting:**
For each platform processed, generate a detailed report at `ringbuffer/src/<os>/reports/build_verification_report.md` using the following format:

# Build Verification Report - [OS Name]
**Date:** [YYYY-MM-DD HH:MM:SS]
**Start Time:** [YYYY-MM-DD HH:MM:SS]
**End Time:** [YYYY-MM-DD HH:MM:SS]
**Elapsed Time:** [Duration]
**Host OS:** [Host OS Name/Version]

## Status
**Final Result:** [PASS / FAIL]

## Fixes and Modifications
*If files were modified to achieve a successful build, list them here:*
- `path/to/file`: [Brief explanation of the fix]

## Verification Details
- **Library Build**: [Success/Failure] - [Brief note on logs/errors]
- **Artifacts Verified**: [Yes/No] (Architecture, SONAME, Binary Size)

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions (e.g., `.cpp`, `.hpp`, or `Makefile`), such as `` ErrorOps.cpp`} ``, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.
