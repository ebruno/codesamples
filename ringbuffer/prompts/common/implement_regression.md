# Regression Test Infrastructure Setup

**Objective:** 
Create the test environment for regression testing on a target platform. This covers infrastructure setup only — host detection, container runtime pre-flight, image bootstrap, resource allocation, and test environment creation (directories, Dockerfile, Makefile, scripts, data).

**Execution:** Use `prompts/common/run_regression.md` to execute the test matrix on an already-set-up platform.

**Inputs:**
1. **Target OSes**: One or more operating systems to target (e.g., `fedora`, `debian,ubuntu`). If not specified, all OSes in `src/` are processed.
2. **Target Image**: An optional container image override (e.g., `fedora:43`, `debian:12`). If provided, this overrides the default image specified in each OS's `create_regression.md`. If not provided, use the default image from the target OS's prompt.

**Process:**
1. **Target Selection**:
   - **Specified Platforms**: If the user request specifies target platforms (e.g., "implement regression for fedora, debian"), verify their existence in `src/`. If a requested platform is missing from `src/`, inform the user that the OS is not currently implemented and list all operating systems that are currently supported (those present as directories in `src/`). Process only the requested platforms that are implemented.
   - **General Request**: Otherwise, iterate through **all** OS directories found in `src/` (e.g., debian, fedora, ubuntu).
   - **Entry Point**: When targeting a specific OS, first check if `prompts/<os>/cpp/create_regression.md` exists.
     - **If it exists**: Consult it for immediate requirements and platform-specific directives. Execute it as the PRIMARY document.
     - **If it does not exist**: Proceed with only `prompts/common/cpp/testing.md` as the specification. Skip platform-specific directives and log: `[timestamp] create_regression.md not found for <os> — proceeding with common spec only.`
   - **Language**: This workflow specifically targets the C++ test environment.

2. **Execution Steps**:
   For the selected OS directory, perform the following.

   **Workflow Precedence:** Execute this common workflow's Step 0 first for image resolution and execution path decision. Then execute `prompts/<os>/cpp/create_regression.md` as the **PRIMARY** document and skip this common workflow's Steps 1-2. This common workflow serves as a reference for structure and provides the image resolution mechanism.

   **Note:** `create_regression.md` is read as a data source for image resolution in Step 0, then executed as the PRIMARY document afterward.

   0. **Environment Setup**:
      - **Timeout Configuration**: All timeout values are defined as variables for easy adjustment:
        - `CONTAINER_BUILD_TIMEOUT_MS`: 600,000 ms (10 minutes) — maximum time for `make container`
      - **Resolve Image**: Determine the Target Image from Inputs (see above). If not provided by the user, read the default image from `prompts/<os>/cpp/create_regression.md` (look for an `IMAGE=` or `Default Image:` directive). If no image is specified in the per-OS file, derive it from `prompts/<os>/cpp/testing.md` (e.g., `fedora:44`, `debian:13`, `ubuntu:24.04`). For macOS native-only platforms (where Default Image is N/A), log: `IMAGE=N/A (native-only platform)`. Otherwise, log: `IMAGE=<resolved_image>`.
      - **Shared Version Context**: Read the version from `src/<os>/cpp/.gen_state.json` (if it exists). This version was set by `implement_functional.md` and represents the Ringbuffer library version (`MAJOR.MINOR.SUBVERSION`). If `.gen_state.json` does not exist, read `src/<os>/cpp/version.mk` as a fallback. Log: `VERSION=<resolved_version>`.
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
        - Store this as `<memory_limit>` for use in `run_regression.md` Step 2's container run command.
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
      - **Validate Existing Dockerfile** (Linux targets only): If `target != macos` and the build Dockerfile exists at `src/<os>/cpp/containers/Dockerfile`, verify that the resolved Target Image matches its `FROM` base image tag. If it does not match, log an error and stop processing — the requested image conflicts with the existing container configuration. macOS targets skip this step (native-only platform).
      - **Validate Test Dockerfile** (Linux targets only): If `target != macos` and `tests/containers/<os>/Dockerfile` exists, verify its `FROM` base image matches the resolved Target Image. If it does not match, log an error and stop processing.
      - **Build Build Image** (Linux targets only): If `target != macos`, before creating the `_test` image, ensure the base `ringbuffer_<os>_build` image is present. Check if it already exists using `<runtime> images | grep ringbuffer_<os>_build`. If not found, execute `make container` from the source directory. Verify that `ringbuffer_<os>_build` exists using `<runtime> images | grep ringbuffer_<os>_build`. macOS targets skip this step (native-only platform).
      - **Step 0 Dockerfile Marker**: If a minimal test Dockerfile was created in this sub-step, create a marker file at `src/<os>/cpp/.dockerfile_created_by_step0` to signal that the Dockerfile already exists. `create_regression.md` (Step 1) MUST check for this marker and skip Dockerfile creation if it exists.
      - **Log Initialization**: Create the log directory `logs/` if it does not exist. Initialize `build.log` with the start timestamp, action description, and resolved image/version as per the "Generation Process Logging" requirement.

   1. **Test Infrastructure Setup**:
      - Execute the directives in `prompts/<os>/cpp/create_regression.md` to create:
        - The test directory structure (`tests/`) with all required subdirectories and `.required_directory` markers.
        - The test Dockerfile (`tests/containers/<os>/Dockerfile`) — create from scratch or augment based on the `.dockerfile_created_by_step0` marker.
        - The test container image (`ringbuffer_<os>_test`) built from `tests/containers/<os>/Dockerfile` (via `make container` in the tests directory, as directed by `create_regression.md`).
        - Utility scripts deployed to `tests/utils/bin/` from `prompts/common/cpp/utils/bin/`.
        - Test data files (`test001.txt` through `test007.txt`) in `tests/data/inputs/`.
        - Expected output files (golden files) in `tests/data/expected/` — pre-computed correct outputs for each test scenario, generated by running the test program with known inputs and capturing output.
        - Test binary source code (`tests/src/test001.cpp`) implementing the full CLI interface described in `prompts/common/cpp/testing.md` (including socket mode `-r`/`-w`, error modes, transform types, and all option flags). The Makefile must build two variants: `test001_staticlib` (linked against static library) and `test001_dynamiclib` (linked against shared library with rpath).
        - Test Makefile (`tests/Makefile`). **CXX Default in Test Makefile:** On macOS targets, the test `Makefile` MUST use `CXX := clang++` (not `?=`) to override macOS Make's built-in default of `CXX = c++`. **Clean Targets:** The test Makefile MUST implement: `clean` — remove contents of `bin/` and `logs/`, all `*.o`, `*~`, and `#*#` files; preserve directories. Do NOT remove `data/expected/*` — those are golden reference files used for test verification. `dist-clean` — call `clean`, then remove the entire `logs/` and `reports/` directories.
        - A `tests/README.md` describing the test suite, build process, and how to run scenarios T001–T007.
      - **Test Data Validation**: Before running `verify_test_data.sh`, ensure it has been deployed to `tests/utils/bin/` from `prompts/common/cpp/utils/bin/`. After generating test data, run the validator script. All seven files must pass validation (line count and format checks). Log success or failure for each file.
      - **Test Binary Build**: Compile `test001_staticlib` (linked against static library) and `test001_dynamiclib` (linked against shared library with rpath). Verify both binaries exist in `tests/bin/`.
      - Log each file creation and build step in `build.log` immediately after the action completes.

   1.5 **Cross-Platform Verification**: After creating the test Makefile and Dockerfile, verify they conform to the binary symmetry requirements:
      - **Identify a Reference Platform**: First, check if `src/reference_linux/cpp/tests/Makefile` exists. If it does, use `reference_linux` as the reference platform (this is the canonical source of truth). If it does not exist, fall back to alphabetical iteration through directories in `src/` (e.g., `debian`, `fedora`, `ubuntu`) and select the first one where `src/<ref_os>/cpp/tests/Makefile` exists.
      - **Fallback**: If no reference platform has a test Makefile, skip cross-platform verification and log: `[timestamp] Cross-platform verification skipped — no reference platform available.` Proceed to `run_regression.md`.
      - **Test Makefile Comparison**: Strip the three allowed differences from both the generated test Makefile and the reference:
        1. `CONTAINER_IMAGE` variable value
        2. Dockerfile path in container run commands (`containers/debian/Dockerfile` vs `containers/fedora/Dockerfile`)
        3. Report title in the Markdown report generation section
      - Compare the remaining content byte-for-byte.
      - **Dockerfile Comparison**: Strip lines starting with `FROM` and `ARG BASE_IMAGE`. Strip any multi-line RUN command where ANY line (including continuation lines) contains a package manager invocation (`dnf install`, `apt-get update`, `apt-get install`, `yum install`) — strip the entire RUN block, not just the package manager portion. Do NOT strip other Dockerfile instructions (`WORKDIR`, `ENV`, `COPY`, `CMD`, etc.). Normalize consecutive empty lines to a single empty line. Compare the remaining content byte-for-byte.
      - **If differences are found beyond the allowed set**: Log: `[timestamp] Cross-platform verification FAILED — <os> test Makefile/Dockerfile differs from reference beyond allowed differences.` STOP and report the deviation for manual review.
      - **If verification passes**: Log: `[timestamp] Cross-platform verification passed — <os> test Makefile/Dockerfile matches reference (allowed differences only).`

**Directives:**
1. Use `prompts/<os>/cpp/testing.md` for platform-specific prerequisites (package lists, container settings).
2. Use `prompts/common/cpp/testing.md` as the primary testing specification.

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions (e.g., `` ErrorOps.cpp`} ``, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.

## Scope Boundary — Infrastructure Setup Only

The purpose of this prompt is to create the test environment: directories, Dockerfile, Makefile, utility scripts, test data, and test binaries. **Your task ends once the `tests/` directory is fully set up with all required artifacts.**

You MUST NOT:
- Execute `make verify` or run the test matrix (T001–T007).
- Generate regression reports (`regression_report.md` or `regression_report_junit.xml`).
- Update `.gen_state.json` with test execution results.
- Proceed to build verification or report generation — use `prompts/common/run_regression.md` for that.

**Directory Scope Restriction:**
- **NEVER create, modify, or delete any files outside the `tests/` directory and the OS cpp root** (except for `build.log`, `.gen_state.json`, and report files).
- The `tests/` directory is managed exclusively by this regression test workflow.

**Excluded Platforms:**
- **FreeBSD 14**, **FreeBSD 15**, and **ArchLinux** are excluded from active development.
- Do not modify, add content to, or create new files in `prompts/freebsd14/`, `prompts/freebsd15/`, or `prompts/archlinux/`.
- The only files that should exist in these directories are zero-length `build.md`, `functional.md`, and `testing.md` files.
- If these directories contain any non-zero files, remove them.

If the user wants to execute tests on an already-set-up platform, they should use `prompts/common/run_regression.md` instead.
