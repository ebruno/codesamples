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

   0. **Execution Strategy**:
      0.1 **Execution Path Decision**:
         - **Native Execution**: If `host_os == <os>` OR if the target `<os>` is `macos`, the build and verification pipeline MUST be performed natively on the host. Containers MUST NOT be used for macOS targets.
         - **Container Execution**: If `host_os != <os>` AND the target `<os>` is NOT `macos`, or if the mode 'use container' was specified (and target is not macos), the workflow MUST use the `ringbuffer_<os>_test` container.
      0.15 **Container Runtime Pre-flight Check**:
         - **Trigger Condition**: If the Execution Path Decision (step 0.1) determined that container execution is required AND `host_os` is `Darwin` (macOS), the `container` command MUST be available in the system PATH before any container operations proceed.
         - **Verification**: Execute `command -v container` (or `which container`) to verify the command exists.
         - **Error Handling**: If `container` is NOT found in PATH, STOP immediately and display the following error message to the user:
           ```
           ERROR: The 'container' command is required for cross-OS builds from macOS to Linux targets, but it was not found in PATH.
           
           Please install Apple Container from: https://github.com/apple/container
           
           After installation, ensure the 'container' command is available in your PATH and re-run the build or test workflow.
           ```
      0.2 **Container Pre-check and Resource Allocation**:
         - Verify that the required build container `ringbuffer_<os>_test` exists on the host system.
         - **Command**: Use the appropriate container runtime for the host (e.g., `podman` on Linux, `container` on macOS) to check for the image: `<runtime> images | grep ringbuffer_<os>_test`.
         - **Action**: If the image is missing or outdated, navigate to `ringbuffer/src/<os>/cpp` and execute `make container` to initialize the environment before proceeding.
      0.3 **Image Management**:
         - For Linux platforms (Debian, Fedora), the `ringbuffer_<os>_test` image is the authoritative environment for all subsequent build and verify steps.

   1. **Build System Validation**:
      - Navigate to `ringbuffer/src/<os>/cpp`.
      - Verify that `Makefile` and `version.mk` exist.
      - **Toolchain Verification**: Ensure the required tools listed in the platform's build requirements (`prompts/<os>/cpp/build.md` and `prompts/common/cpp/build.md`) are available for the target OS.
      - **Recovery**: If build files are missing, analyze the `cpp` directories of other supported OSs to recreate them, adapting toolchains and extensions (e.g., `.so` to `.dylib`) as appropriate for the target `<os>`.

   2. **Library Build**:
      - **Execution**:
        - **Navigate**: `cd ringbuffer/src/<os>`
        - **Execute**: 
          - Ensure the container execution timeout is set to a maximum of 600,000 ms (10 minutes).
          - If executing in a container: Use the appropriate container runtime for the host (e.g., `podman` on Linux, `container` on macOS): `<runtime> run --rm -m 2G -v $(pwd):/app ringbuffer_<os>_test sh -c "cd /app/cpp && make clean && make"`.
          - If executing natively: `cd cpp && make clean && make`.
        - **Evaluate**: If this fails, analyze logs, apply fixes to the workspace, and repeat this step.

   3. **Source Consistency Check**:
      - List all `.cpp` files in the source directory.
      - Compare this list against the object files generated in the build directory or the `SRCS` variable in the `Makefile`.
      - **Action**: If any `.cpp` file is missing from the build, update the `Makefile` and repeat the **Library Build** step.

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
