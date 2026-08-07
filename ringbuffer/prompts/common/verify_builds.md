# Build Verification Workflow

**Objective:** 
Ensure the C++ implementation builds successfully across all supported operating systems.

**Process:**
1. **Target and Mode Selection**:
   - **Targeting**: If the user request specifies one or more target platforms (e.g., "run build_verify for debian" or "do regression_test on debian, fedora"), perform the following steps **only** for the specified OSs. Otherwise, iterate through **all** OS directories found in `ringbuffer/src/` (e.g., debian, fedora, macos).
   - **Mode**: If the request includes the phrase `use container` (e.g., "run build_verify for debian use container"), the container MUST be used for all builds, overriding the Host-OS Optimization rule.

2. **Execution Steps**:
   For the selected OS directory, perform the following:

   0. **Container Pre-check and Resource Allocation**:
      - Verify that the required build container `ringbuffer_<os>_build` exists on the host system.
      - **Command**:
        - macOS: `container images | grep ringbuffer_<os>_build`
        - Linux: `podman images | grep ringbuffer_<os>_build`
      - **Action**: If the image is missing or outdated, navigate to `ringbuffer/src/<os>/cpp` and execute `make container` to initialize the environment before proceeding.
      - **Resource Allocation (macOS)**:
        1. Run `vm_stat`.
        2. Extract the page size from the first line (e.g., `16384`).
        3. Extract `Pages free` and `Pages inactive`.
        4. Calculate total available bytes: `(Pages free + Pages inactive) * page size`.
        5. Convert to GiB: `total bytes / 1,073,741,824`.
        6. Set container memory limit (`-m`) to 50% of this value, capped at 3 GB.
        7. Report the calculated memory limit before starting the container.

   1. **Library Build**:
      - **Host-OS Optimization**: If the host operating system is the same as the target `<os>`, the build in `src/<os>/cpp` may be performed natively without using the container. However, the container MUST be used if this prompt was initiated with the statement `read build_verify use container`, `run build_verify use container`, or `use build_verify use container`.
      - **Navigate**: `cd ringbuffer/src/<os>`
      - **Execute**: 
        - Use the calculated memory limit (e.g., `-m 2G`).
        - Ensure the container execution timeout is set to a maximum of 600,000 ms (10 minutes).
        - macOS: `container run --rm -m <memory_limit> -v $(pwd):/app ringbuffer_<os>_build sh -c "cd /app/cpp && make clean && make"`
        - Linux: `podman run --rm -m <memory_limit> -v $(pwd):/app ringbuffer_<os>_build sh -c "cd /app/cpp && make clean && make"`
      - **Evaluate**: If this fails, analyze logs, apply fixes to the workspace, and repeat this step.

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
