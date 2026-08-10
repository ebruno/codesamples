# Regression Test Infrastructure Setup

**Objective:** Prepare the build and test environment for regression testing across all supported operating systems. This file covers infrastructure setup only; execution is in `regression_test_execution.md`.

**Process:**
1. **Target and Mode Selection**:
   - **Targeting**:
     - **Specified Platform**: If the user request specifies one or more target platforms (e.g., "run regression_test on debian, fedora"), verify their existence in `ringbuffer/src/`. If a requested platform is missing from `ringbuffer/src/`, inform the user that the OS is not currently implemented and list all operating systems that are currently supported (those present as directories in `ringbuffer/src/`). Process only the requested platforms that are implemented.
     - **General Request**: Otherwise, iterate through **all** OS directories found in `ringbuffer/src/` (e.g., debian, fedora, macos).
   - **Mode**: If the request includes the phrase `use container` (e.g., "run regression_test for debian use container"), the container MUST be used for all builds, overriding the Host-OS Optimization rule.

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

   1. **Execution Path Decision**:
      - Compare `host_os` with the target `<os>` (debian, fedora, macos).
      - **Native Execution**: If `host_os == <os>` OR if the target `<os>` is `macos`, the build and verification pipeline MUST be performed natively on the host. Containers MUST NOT be used for macOS targets.
      - **Container Execution**: If `host_os != <os>` AND the target `<os>` is one of `debian`, `fedora`, or `ubuntu` (i.e., not macOS), the build and verification pipeline MUST be performed inside the `ringbuffer_<os>_test` container. Containers MUST NOT be used for macOS targets under any circumstances.

   2. **Container Runtime Pre-flight Check**:
      - **Trigger Condition**: If the Execution Path Decision (step 1) determined that container execution is required AND `host_os` is `Darwin` (macOS), the `container` command MUST be available in the system PATH before any container operations proceed.
      - **Verification**: Execute `command -v container` (or `which container`) to verify the command exists.
      - **Error Handling**: If `container` is NOT found in PATH, STOP immediately and display the following error message to the user:
        ```
        ERROR: The 'container' command is required for cross-OS builds from macOS to Linux targets, but it was not found in PATH.

        Please install Apple Container from: https://github.com/apple/container

        After installation, ensure the 'container' command is available in your PATH and re-run the build or test workflow.
        ```

   3. **Baseline Image Bootstrap (Level 0)**:
      - **Requirement**: Before creating the `_test` image, the base `ringbuffer_<os>_build` image MUST be present and current.
      - **Action**: Navigate to `ringbuffer/src/<os>/cpp` and execute `make container`.
      - **Verification**: Confirm that `ringbuffer_<os>_build` exists using `<runtime> images | grep ringbuffer_<os>_build`, where `<runtime>` is `container` on macOS or `podman` on Linux.

   4. **`ringbuffer_<os>_test` Image Management**:
      - **Mandate**: For Linux platforms (Debian, Fedora), the `ringbuffer_<os>_test` image is the authoritative environment for all subsequent build and verify steps.
      - **Bootstrap Step**: Use the base build image to trigger the creation/update of the test image:
        - Linux (on a Linux host): `<runtime> run --rm -v \$(pwd):/app ringbuffer_<os>_build sh -c "cd /app/cpp/tests && make container"`, where `<runtime>` is `podman`.
      - **Lifecycle Check**: The `make container` target in `tests/Makefile` MUST:
        1. Check if `ringbuffer_<os>_test` exists.
        2. Compare the modification date of `tests/containers/<os>/Dockerfile` AND `version.mk` with the image creation date.
        3. Build the image using `<runtime> build -t ringbuffer_<os>_test -f tests/containers/<os>/Dockerfile .` if either file is newer or the image is missing, where `<runtime>` is `container` on macOS or `podman` on Linux.

   **Container Build Failure Handling:**
   If any container image build step (Step 3 or Step 4) fails, the following procedure MUST be followed:

   1. **Capture and Report**: Record the full error output from the failed `make container` or `<runtime> build` command. Display it to the user in a clearly marked error block:
      ```
      CONTAINER BUILD FAILED — [OS Name]

      Command that failed: <the exact command>
      Exit code: <exit_code>

      Error output:
      <full error output>
      ```

   2. **Suggest Fixes** based on the failure category:
      - **Dockerfile not found**: "The file `tests/containers/<os>/Dockerfile` (or `containers/Dockerfile`) does not exist. Generate it from the specifications in `prompts/<os>/cpp/build.md`."
      - **Insufficient disk space**: "Free at least 5 GB of disk space and retry. Check with `df -h`."
      - **Insufficient memory**: "Allocate more memory to the container runtime. On macOS, increase Docker Desktop / Podman VM memory in settings."
      - **Network timeout (pulling base image)**: "Check network connectivity. Retry with `--network=host` or configure a mirror registry."
      - **Permission denied**: "Ensure the current user has permissions to run `<runtime>` without sudo. On Linux, add the user to the `podman` or `docker` group."
      - **Unknown/other**: "Review the error output above. If the cause is not clear, run the command manually in a terminal to inspect it interactively."

   3. **Exit**: After reporting the error and suggestions, STOP all further processing for this OS target. Do NOT attempt retries or proceed to subsequent steps.

   **Maximum Retry Policy**: If a fix is applied and the build is retried, allow at most **2 retry attempts**. If all retries fail, report the final failure and exit.

   5. **Resource Allocation (macOS Host)**:
      - Run `vm_stat`.
      - Extract the page size from the first line (e.g., `16384`).
      - Extract `Pages free` and `Pages inactive`.
      - Calculate total available bytes: `(Pages free + Pages inactive) * page size`.
      - Convert to GiB: `total bytes / 1,073,741,824`.
      - Set container memory limit (`-m`) to 50% of this value, capped at 3 GB.
      - Store this as `<memory_limit>`.

   6. **Test Environment Pre-flight**:
      - **Requirement**: Verify if the `tests/` directory exists in `ringbuffer/src/<os>/cpp/`.
      - **Mandate**: If the `tests/` directory is missing, it MUST be generated from scratch following the specifications in `ringbuffer/prompts/common/cpp/testing.md` and `ringbuffer/prompts/<os>/cpp/testing.md`.
      - **Prohibition**: DO NOT copy the `tests/` directory from another operating system. All test artifacts, including the `Dockerfile` in `tests/containers/<os>/`, must be created based on the prompts to ensure toolchain and environment compatibility.

**Next Step:** After completing infrastructure setup, proceed to `regression_test_execution.md` for the build and verification steps.

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions (e.g., `.cpp`, `.hpp`, or `Makefile`), such as `` ErrorOps.cpp`} ``, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.
<EOF>
