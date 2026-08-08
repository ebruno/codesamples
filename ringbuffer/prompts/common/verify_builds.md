# Build Verification Workflow

**Objective:** 
Ensure the C++ implementation builds successfully across all supported operating systems.

**Process:**
1. **Target and Mode Selection**:
   - **Targeting**: If the user request specifies one or more target platforms (e.g., "run build_verify for debian" or "do regression_test on debian, fedora"), perform the following steps **only** for the specified OSs. Otherwise, iterate through **all** OS directories found in `ringbuffer/src/` (e.g., debian, fedora, macos).
   - **Mode**: If the request includes the phrase `use container` (e.g., "run build_verify for debian use container"), the container MUST be used for all supported builds (excluding macOS), overriding the Host-OS Optimization rule.

2. **Execution Steps**:
   For the selected OS directory, perform the following:

   0. **Container Pre-check and Resource Allocation**:
      - Verify that the required build container `ringbuffer_<os>_build` exists on the host system.
      - **Command**: Use the appropriate container runtime for the host (e.g., `podman` on Linux, `container` on macOS) to check for the image: `<runtime> images | grep ringbuffer_<os>_build`.
      - **Action**: If the image is missing or outdated, navigate to `ringbuffer/src/<os>/cpp` and execute `make container` to initialize the environment before proceeding.

   1. **Build System Validation**:
      - Navigate to `ringbuffer/src/<os>/cpp`.
      - Verify that `Makefile` and `version.mk` exist.
      - **Toolchain Verification**: Ensure the required tools listed in the platform's build requirements (`prompts/<os>/cpp/build.md` and `prompts/common/cpp/build.md`) are available for the target OS.
      - **Recovery**: If build files are missing, analyze the `cpp` directories of other supported OSs to recreate them, adapting toolchains and extensions (e.g., `.so` to `.dylib`) as appropriate for the target `<os>`.

   2. **Library Build**:
      - **Host-OS Optimization**: If the host operating system is the same as the target `<os>`, the build in `src/<os>/cpp` may be performed natively. For macOS, native building is the only supported method. For other OSs, the container MUST be used if this prompt was initiated with the statement `read build_verify use container`, `run build_verify use container`, or `use build_verify use container`.
      - **Navigate**: `cd ringbuffer/src/<os>`
      - **Execute**: 
        - Ensure the container execution timeout is set to a maximum of 600,000 ms (10 minutes).
        - Use the appropriate container runtime for the host (e.g., `podman` on Linux, `container` on macOS): `<runtime> run --rm -m 2G -v $(pwd):/app ringbuffer_<os>_build sh -c "cd /app/cpp && make clean && make"`.
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
