# Build Verification Workflow

**Objective:** 
Ensure the C++ implementation builds successfully across all supported operating systems.

**Process:**
1. **Target and Mode Selection**:
   - **Targeting**: 
     - **Specified Platform**: If the user request specifies one or more target platforms (e.g., "run build_verify for debian" or "do regression_test on debian, fedora"), verify their existence in `src/`. If a requested platform is missing from `src/`, inform the user that the OS is not currently implemented and list all operating systems that are currently supported (those present as directories in `src/`). Process only the requested platforms that are implemented.
     - **General Request**: Otherwise, iterate through **all** OS directories found in `src/` (e.g., debian, fedora, macos).
   - **Mode**: If the request includes the phrase `use container` (e.g., "run build_verify for debian use container"), the container MUST be used for all supported builds (excluding macOS), overriding the Host-OS Optimization rule.

2. **Execution Steps**:
   For the selected OS directory, perform the following:

   **Timeout Configuration**: All timeout values are defined as variables for easy adjustment:
   - `CONTAINER_BUILD_TIMEOUT_MS`: 600,000 ms (10 minutes) — maximum time for `make container`
   - `LIBRARY_BUILD_TIMEOUT_MS`: 600,000 ms (10 minutes) — maximum time for `make clean && make`

   **Log Initialization**: Before performing any build operations, create the log directory `src/<os>/cpp/logs/` if it does not exist. Record the start timestamp in a variable (e.g., `START_TIME=$(date '+%Y-%m-%d %H:%M:%S %z')`). Initialize `build.log` with the start timestamp and action description ("Build verification started"). If `build.log` already exists, append to it rather than overwriting.

   0. **Execution Strategy**:

      0.1 **Execution Path Decision**:
         - Detect the host OS: If `uname -s` returns `Darwin`, set `host_os = macOS`. If it returns `Linux`, read the distro ID from `/etc/os-release` using: `host_os=$(grep '^ID=' /etc/os-release | cut -d= -f2)`.
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
         - **Apple Container Runtime**: macOS uses the `container` command (Apple Container), NOT Docker or podman. Key subcommands:
           - `container run` — Run a container (equivalent to `docker run`)
           - `container build` / `container image build` — Build an image from Dockerfile (equivalent to `docker build`)
           - `container images` / `container image list` — List images (equivalent to `docker images`)
           - `container system status` — Show container services status
           - `container system version` — Show container runtime version
           Help: `container --help` → Overview of all subcommands (run, build, images, exec, logs, etc.)
           System help: `container system --help` → df, dns, kernel, logs, property, start, status, stop, version
         - **Service Management**: The `container` daemon does NOT start automatically on macOS. Before using any container commands, ensure the service is running:
           - Check status: `container system status` — shows whether container services are active
           - Start service: `container system start` — starts the container daemon and required services
           - If status shows services are not running, execute `container system start` before proceeding with any container operations.
         - **Linux Host Detection**: When `uname -s` returns `Linux`, read the distro ID from `/etc/os-release`:
           ```bash
           host_os=$(grep '^ID=' /etc/os-release | cut -d= -f2)
           ```
           Supported Linux distros: `ubuntu`, `debian`, `fedora`. If the host OS does not match the target OS, use a container matching the target OS.
         - **Container Runtime on Linux**: On Linux hosts, use `podman` (NOT Docker). Key subcommands:
           - `podman run` — Run a container
           - `podman build` — Build an image from Dockerfile
           - `podman images` — List images
           - `podman system status` — Show podman service status (if applicable)
         - **Host-Target Rule**: If the host OS matches the target OS (e.g., Fedora build on a Fedora host), native execution is permitted. If the host OS does not match the target OS (e.g., macOS build targeting Ubuntu), a container matching the target OS MUST be used.
         - **macOS is native-only**: macOS builds and tests NEVER use containers, regardless of host OS.
         - **FreeBSD is native-only**: FreeBSD builds and tests NEVER use containers, regardless of host OS.
         - **Excluded Platforms**: FreeBSD 14, FreeBSD 15, and ArchLinux are excluded from active development. Do not execute build verification on these platforms.

      0.2 **Container Pre-flight Check (Linux targets only)**:
         - If the target OS is a Linux distribution and the host OS does not match, verify the container runtime is available:
           - **macOS host**: `command -v container` — if not found, STOP and display error about installing Apple Container.
           - **Linux host**: `command -v podman` — if not found, STOP and display error about installing Podman.
         - If the target is macOS or FreeBSD, skip container checks entirely.

      0.3 **Build Execution**:
         - Navigate to `src/<os>/cpp/`
         - If using a container, wrap the build command with the appropriate runtime:
           - **macOS host**: `container run --rm -v $(pwd):/app <container_image> make clean && make`
           - **Linux host**: `podman run --rm -v $(pwd):/app <container_image> make clean && make`
         - If native execution is permitted (host matches target), run `make clean && make` directly.
         - If the build fails, log the error and STOP processing for this platform.

      0.4 **Post-Build Verification**:
         - Verify the library was built: Check that `lib/libswtr_ringbuffer.a` (static) and/or `lib/libswtr_ringbuffer.so` / `.dylib` (shared) exist.
         - Verify binary format:
           - **Linux**: `file lib/libswtr_ringbuffer.so` should show "ELF 64-bit"
           - **macOS**: `file lib/libswtr_ringbuffer.dylib` should show "Mach-O"
         - Verify symbol visibility:
           - **Linux**: `nm -gjU lib/libswtr_ringbuffer.so` should show only exported symbols
           - **macOS**: `nm -gU lib/libswtr_ringbuffer.dylib` should show only exported symbols
         - Verify binary size: Check that the library is within expected size range (typically < 100KB for this project).

      0.5 **Binary Symmetry Check (Linux platforms only)**:
         - After building all Linux platforms, run the binary symmetry verification script to ensure source files are byte-identical across platforms:
           ```bash
           ./prompts/common/cpp/utils/bin/verify_binary_symmetry.sh <workspace_root>
           ```
         - If the script reports any differences, log them and STOP — this indicates a violation of the binary symmetry requirement.
         - If all files are identical, log: `[timestamp] Binary symmetry verification passed — all Linux platforms produce byte-identical source.`

      0.6 **Prompt Lint Check**:
         - Before or after build verification, run the prompt lint script to ensure all platform/language directories follow conventions:
           ```bash
           ./prompts/common/cpp/utils/bin/lint_prompts.sh <workspace_root>
           ```
         - If the script reports any errors, log them and STOP — this indicates a structural issue with the prompt directory layout.
         - Warnings (e.g., excluded platforms not found) are acceptable and should be logged but do not stop processing.

   1. **Report Generation**:
      - Generate a build verification report at `src/<os>/reports/build_verify_report.md` with the following format:
        ```markdown
        # Build Verification Report - [OS Name] <version>
        **Date:** [YYYY-MM-DD HH:MM:SS +/-HHMM]
        **Target Version:** <version>
        **Host OS:** <host_os>
        **Container Runtime:** <container_runtime or "native">

        ## Build Status
        - **Compilation**: [PASS/FAIL]
        - **Static Library**: [PASS/FAIL]
        - **Shared Library**: [PASS/FAIL]
        - **Binary Format**: [PASS/FAIL]
        - **Symbol Visibility**: [PASS/FAIL]

        ## Artifacts
        - `lib/libswtr_ringbuffer.a`: <size> bytes
        - `lib/libswtr_ringbuffer.so` / `.dylib`: <size> bytes

        ## Notes
        - Any additional notes about the build process.
        ```

   2. **Log Finalization**:
      - Append a final entry to `build.log` stating that build verification is complete.
      - Calculate and include the total elapsed time since the start timestamp in this final entry.

**Reporting:**
Once verification is complete, generate a summary report at `src/<os>/reports/build_verify_report.md`.

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions (e.g., `.cpp`, `.hpp`, or `Makefile`), such as `` ErrorOps.cpp`} ``, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.
