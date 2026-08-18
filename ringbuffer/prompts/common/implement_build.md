# Build Implementation Workflow

**Objective:** 
Create the build environment for the Ringbuffer library by strictly following the specifications defined in `prompts/common/cpp/build.md` and the platform-specific specifications in `prompts/<os>/cpp/build.md`. For platform-insensitive languages (Java, Python), follow `prompts/common/<lang>/build.md`.

**Inputs:**
1. **Target OSes**: One or more operating systems to target (e.g., `fedora`, `debian,ubuntu`). If not specified, all OSes in `src/` are processed.
2. **Target Image**: An optional container image override (e.g., `fedora:43`, `debian:12`). If provided, this overrides the default image specified in each OS's `create_build.md`. If not provided, use the default image from the target OS's prompt.

**Process:**
1. **Target Selection & Language Dispatch**:
   - **Targeting**: 
     - **Specified Platforms**: If the user request specifies target platforms (e.g., "implement build for fedora, debian"), verify their existence in `src/`. If a requested platform is missing from `src/`, inform the user that the OS is not currently implemented and list all operating systems that are currently supported (those present as directories in `src/`). Process only the requested platforms that are implemented.
     - **General Request**: Otherwise, iterate through **all** OS directories found in `src/` (e.g., debian, fedora, macos).
   - **Language Dispatch**: Detect which languages are implemented by checking for source directories:
     - `src/<os>/cpp/` → C++ build (per-OS, uses `prompts/<os>/cpp/create_build.md` as primary document)
     - `src/common/java/` → Java build (common, platform-insensitive, uses `prompts/common/java/build.md`)
     - `src/common/python/` → Python build (common source, platform-specific Makefile):
       - GNU make systems (macOS, Linux): `src/common/python/Makefile.gnu`
       - BSD make systems (FreeBSD 14+): `src/<os>/python/Makefile` (per-OS directory with BSD-compatible Makefile)
   - Process each detected language independently. A failure in one language does not stop verification of others.
   - Log which languages are being built: `[timestamp] Languages detected for build: <comma-separated list>`

2. **Execution Steps**:
   For the selected OS directory, perform the following.

   **Workflow Precedence:** Execute this common workflow's Step 0 first for image resolution and execution path decision. Then execute `prompts/<os>/cpp/create_build.md` as the **PRIMARY** document and skip this common workflow's Steps 1-6. This common workflow serves as a reference for structure and provides the image resolution mechanism.

   **Note:** `create_build.md` is read as a data source for image resolution in Step 0, then executed as the PRIMARY document afterward.

   0. **Environment Setup**:
      - **Timeout Configuration**: All timeout values are defined as variables for easy adjustment:
        - `CONTAINER_BUILD_TIMEOUT_MS`: 600,000 ms (10 minutes) — maximum time for `make container`
        - `LIBRARY_BUILD_TIMEOUT_MS`: 600,000 ms (10 minutes) — maximum time for `make clean && make`
      - **Resolve Image**: Determine the Target Image from Inputs (see above). If not provided by the user, read the default image from `prompts/<os>/cpp/create_build.md`. If no default image is defined (e.g., macOS native-only platform), log: `IMAGE=N/A (native-only platform)`. Otherwise, log: `IMAGE=<resolved_image>`.
      - **Shared Version Context**: Read the version from `src/<os>/cpp/.gen_state.json` (if it exists). This file was **created by `implement_functional.md`** and progressively enriched by subsequent steps (`implement_build.md` adds build artifact hashes, `run_regression.md` adds test artifact hashes). The version represents the Ringbuffer library version (`MAJOR.MINOR.SUBVERSION`). If `.gen_state.json` does not exist, read `src/<os>/cpp/version.mk` as a fallback. Log: `VERSION=<resolved_version>`.
      - **Marker Cleanup**: If `target != macos`, remove any existing `.dockerfile_created_by_step0` marker file to ensure a clean state for this run: `rm -f src/<os>/cpp/.dockerfile_created_by_step0`. macOS targets skip this step (native-only platform).
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
        - **Native Execution**: If `host_os == <os>` OR if the target `<os>` is `macos`, all build and verification steps MUST be performed natively on the host. Containers MUST NOT be used for macOS targets.
        - **Container Execution**: If `host_os != <os>` AND the target `<os>` is NOT `macos`, all build and verification steps MUST be performed inside the `ringbuffer_<os>_build` container.
        - **Log Your Decision**: Print a one-line summary to stdout AND append it to `src/<os>/cpp/logs/build.log`:
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
        - Store this as `<memory_limit>` for use in Step 3's container run command.
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
      - **Validate Existing Dockerfile** (Linux targets only): If `target != macos` and the Dockerfile exists at `src/<os>/cpp/containers/Dockerfile`, verify that the resolved Target Image matches its `FROM` base image tag. If it does not match, log an error and stop processing — the requested image conflicts with the existing container configuration. macOS targets skip this step (native-only platform).
      - **Create & Validate Container** (Linux targets only): If `target != macos` and the Dockerfile does not exist (build phase), create a minimal Dockerfile in `src/<os>/cpp/containers/Dockerfile` using the resolved image as the base image tag (e.g., `FROM fedora:44`). Attempt to pull or build the container image using the platform-appropriate runtime:
        - **macOS host**: use `container` to pull/build the image.
        - **Linux host**: use `podman` to pull/build the image.

        If the runtime is not available, log: `WARNING: Container runtime unavailable — image <image> could not be validated. Proceeding without container validation.` If the pull/build fails, log: `ERROR: Image <image> is not a supported base image for <OS>. Stopping processing.` and terminate.
      - **Step 0 Dockerfile Marker** (Linux targets only): If `target != macos` and a minimal Dockerfile was created in this sub-step, create a marker file at `src/<os>/cpp/.dockerfile_created_by_step0` to signal that the Dockerfile already exists. `create_build.md` (Step 1) MUST check for this marker and skip Dockerfile creation if it exists. macOS targets skip this step (native-only platform).
      - **Navigate**: `cd src/<os>/cpp`
      - **Log Initialization**: Create the log directory `logs/` if it does not exist. Initialize `build.log` with the start timestamp, action description, and resolved image/version as per the "Generation Process Logging" requirement.

   1. **Build System Creation**:
      - Execute the directives in `prompts/<os>/cpp/create_build.md` to create:
        - The `Makefile` in the source directory.
        - The `containers/Dockerfile` (Linux targets only; macOS is native-only and does not use Dockerfiles). If a minimal Dockerfile was created in Step 0 (Linux targets only), `create_build.md` MUST **augment** it by adding the platform-specific package installations and container settings from `build.md` — do NOT replace or rewrite it. Before creating the Dockerfile, check if `containers/Dockerfile` already exists:
          - If it exists: read its first line (`FROM ...`) and use that as the base image for any package additions. Do NOT rewrite the entire file.
          - If it does not exist: create a new Dockerfile from scratch using the resolved image as the base.
        - The `specs/` subdirectory with `build.md`, `testing_requirements.md`, and `artifacts.md`.
      - The Makefile MUST be generated independently from `prompts/common/cpp/build.md` and the platform-specific build spec. Do NOT copy Makefiles from other platforms.
      - The Dockerfile MUST be generated independently from the build spec's container requirements (Linux targets only; macOS is native-only). Do NOT copy Dockerfiles from other platforms.
      - **specs/build.md**: Copy of `prompts/<os>/cpp/build.md` (platform-specific build requirements).
      - **specs/testing_requirements.md**: Copy of `prompts/<os>/cpp/testing.md` (reference copy for testing requirements — not an instruction to create tests during the build phase). Do NOT name this file `testing.md` — use `testing_requirements.md` to distinguish it from the testing prompt.
      - **Specs Directory Handling**: If the `specs/` directory already exists (e.g., from a previous run), overwrite its contents with the current versions of the prompt files. Do NOT preserve stale copies.
      - **specs/artifacts.md Content**: Create `specs/artifacts.md` with the following structure:
        ```markdown
        # Build Artifacts — [OS Name]

        ## Library Artifacts
        | Artifact | Path | Description |
        |----------|------|-------------|
        | Static Library | `lib/libswtr_ringbuffer-<MAJOR>.<MINOR>.<SUBVERSION>-<BUILD_ID>.a` | Static archive built with `ar` |
        | Shared Library | `lib/libswtr_ringbuffer-<MAJOR>.<MINOR>.<SUBVERSION>-<BUILD_ID>.{so|dylib}` | Shared object built with `-shared` (Linux) or `-dynamiclib` (macOS) |
        | Static Link | `lib/libswtr_ringbuffer.a` → versioned static library | Relative symlink for linking |
        | Shared Link | `lib/libswtr_ringbuffer.{so|dylib}` → versioned shared library | Relative symlink for linking |
        ```
      - Log each file creation in `build.log` immediately after the file is written.

   1.5 **Cross-Platform Verification**:
      - **macOS skip**: If `target == macos`, log `[timestamp] Cross-platform verification skipped — macOS produces Mach-O binaries (not ELF); byte-identical comparison against Linux reference platforms is not applicable.` and proceed to Step 2.
      - **Linux targets**: After creating the Makefile and Dockerfile, verify they conform to the binary symmetry requirements:
        - **Identify a Reference Platform**: Find an OS directory in `src/` that already has a Makefile. Iterate through directories alphabetically (e.g., `debian`, `fedora`, `ubuntu`) and select the first one where `src/<ref_os>/cpp/Makefile` exists.
        - **Fallback**: If no reference platform has a Makefile, skip cross-platform verification and log: `[timestamp] Cross-platform verification skipped — no reference platform available.` Proceed to Step 2.
        - **Makefile Comparison**: Strip the three allowed differences from both the generated Makefile and the reference:
          1. `CONTAINER_IMAGE` variable value
          2. Working directory path in container run commands
          3. Host distro detection check
        - Compare the remaining content byte-for-byte.
        - **Dockerfile Comparison**: Strip lines starting with `FROM`. Strip any multi-line RUN command where the first line contains a package manager invocation (`dnf install`, `apt-get install`, `yum install`) — strip the entire RUN block, not just the package manager portion. Do NOT strip other Dockerfile instructions (`WORKDIR`, `ENV`, `COPY`, `CMD`, etc.). Compare the remaining content byte-for-byte.
        - **If differences are found beyond the allowed set**: Log: `[timestamp] Cross-platform verification FAILED — <os> Makefile/Dockerfile differs from reference beyond allowed differences.` STOP and report the deviation for manual review.
        - **If verification passes**: Log: `[timestamp] Cross-platform verification passed — <os> Makefile/Dockerfile matches reference (allowed differences only).`

   2. **Container Image Build** (Linux targets only): If `target != macos`, execute `make container` from the source directory to build or update the `ringbuffer_<os>_build` image. Set a timeout of `${CONTAINER_BUILD_TIMEOUT_MS}` ms for this operation. If the timeout is exceeded, log: `[timestamp] Container build timed out after ${CONTAINER_BUILD_TIMEOUT_MS} ms. Stopping.` and STOP processing this platform.
      - This step verifies that:
        1. The host OS is correctly detected.
        2. The build image (`ringbuffer_<os>_build`) is successfully created or updated.
        3. The container environment is fully operational and ready for subsequent compilation steps.
      - Log the result to `build.log`. macOS targets skip this step (native-only platform).

      **Container Build Failure Procedure:** If `make container` fails:
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

   3. **Library Build**:
      - **Toolchain Pre-check**: Before building, verify the required compiler is available:
        - **Native execution**: Run `command -v clang++` or `command -v g++`. If neither is found, log: `[timestamp] Toolchain verification FAILED — no C++ compiler found in PATH. Cannot proceed.` and STOP.
        - **Container execution**: The toolchain is verified inside the container during `make container` (Step 2).
      - **Execution**:
        - If executing in a container: Use the appropriate container runtime for the host (e.g., `podman` on Linux, `container` on macOS). Set a timeout of `${LIBRARY_BUILD_TIMEOUT_MS}` ms:
          - If `<memory_limit>` was calculated in Step 0 (macOS host, container execution): `<runtime> run --rm -m <memory_limit> -v $(pwd):/app ringbuffer_<os>_build sh -c "cd /app && make clean && make"`.
          - Otherwise (Linux host, container execution): `<runtime> run --rm -m 2G -v $(pwd):/app ringbuffer_<os>_build sh -c "cd /app && make clean && make"`.
        - If executing natively: `make clean && make`.
      - Log success or failure to `build.log`.

      **Library Build Failure Procedure:** If the build fails:
        1. Capture the full error output from `make`.
        2. Analyze logs to determine root cause (compiler errors, missing files, toolchain issues).
        3. Apply the minimal fix required.
        4. Retry at most **1 time**.
        5. If the retry fails, STOP immediately and report:
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

   4. **Artifact Verification**:
      - Verify the produced artifacts:
        - **Architecture**: Use `file -L` on both `.a` and the shared library (`.so` for Linux, `.dylib` for macOS). The `-L` flag follows symlinks to versioned artifacts.
          - **Linux targets**: PASS if output contains "ELF 64-bit". FAIL otherwise.
          - **macOS targets**: PASS if output contains "Mach-O" or "ar archive". FAIL otherwise.
        - **SONAME**: Use the appropriate tool for the host OS:
          - **Linux**: `readelf -d lib/libswtr_ringbuffer.so` — PASS if output contains `SONAME [libswtr_ringbuffer.so]`.
          - **macOS**: `otool -l lib/libswtr_ringbuffer.dylib | grep -A2 "name"` — PASS if output contains the expected library name.
        - **Binary Size**: Use `size` on both artifacts (macOS/BSD supports the same output format for this purpose).
      - Log results to `build.log`.

   5. **Source Consistency Check**:
      - List all `.cpp` files in the source directory and compare against the `SRCS` variable in the Makefile.
      - If any `.cpp` file is missing from the build, update the `Makefile` to include it and retry the library build at most 1 time.

   6. **State Tracking**:
      - Create or update `.gen_state.json` in `src/<os>/cpp/` containing:
        - The resolved version (from shared context or `version.mk`).
        - The resolved image.
        - SHA-256 hashes of `common/cpp/build.md` and `<os>/cpp/build.md`.
        - SHA-256 hashes of all generated build artifacts (Makefile, specs files; Dockerfile for Linux targets only).
        - File fingerprints for all source files.
      - **Version Change Detection**: Before updating `.gen_state.json`, compare the current `version.mk` values against those stored in `.gen_state.json`. If any value has changed (e.g., `MAJOR`, `MINOR`, `SUBVERSION`, or `BUILD_ID`), regenerate all versioned artifact names and symlinks in the `lib/` directory before proceeding.

   7. **Final Self-Audit**:
      - Verify the following and log results:
        - **Makefile Targets**: All required targets are present (`all`, `static`, `shared`, `clean`, `dist-clean`). If `target != macos`, also verify the `container` target exists. macOS targets do not have a container target (native-only platform).
        - **`dist-clean` Behavior**: The `dist-clean` target MUST include a conditional check for the `tests/` directory. If `tests/` exists, it MUST execute `make -C tests dist-clean`. It MUST also remove both the local `reports/` directory (inside cpp/) and the parent-level `../reports/` directory, plus the `logs/` directory. Verify this by inspecting the Makefile source.
        - **Dockerfile** (Linux targets only): If `target != macos`, verify it exists and has valid syntax (base image, package installation). macOS targets skip this check (native-only platform).
        - **Specs Directory**: `specs/` contains `build.md`, `testing_requirements.md`, and `artifacts.md`.
        - **Source Consistency**: All `.cpp` files are listed in the Makefile's `SRCS`.
        - **Artifact Verification**: Library artifacts exist with correct symlinks.
        - **CXX Variable Assignment**: On macOS targets, verify the Makefile uses `CXX := clang++` (simple expansion), NOT `CXX ?= clang++` (conditional). macOS Make ships with built-in defaults (`CXX = c++`) that override `?=` assignments. Command-line overrides like `make CXX=g++` still work with `:=`.

   8. **Finalize Logs**:
      - Append a final entry to `build.log` stating that the build implementation is complete.
      - Calculate and include the total elapsed time since the start timestamp in this final entry.

   ---

   **Java Build** (from `src/common/java/`):
   - Navigate to `src/common/java/`.
   - **Toolchain Check**: Verify `mvn` is available: `command -v mvn`. If not found, STOP and report that Maven must be installed.
   - **pom.xml Creation**: If `pom.xml` does not exist, create it following `prompts/common/java/build.md` specifications (group ID: `com.swtr`, artifact ID: `ringbuffer`, packaging: `jar`).
   - **Dockerfile Package Validation** (Linux targets only):
     - For each target OS, check the per-OS Dockerfile at `src/common/java/containers/<os>/Dockerfile` and verify it contains:
       - `java-25-openjdk` (Fedora) or `openjdk-25-jdk` (Debian/Ubuntu) — the latest JDK 25 package
       - `maven` installation step (latest available in repos)
     - If the JDK package is missing, add it to the Dockerfile RUN command:
       ```dockerfile
       # Fedora (latest JDK 25 + Maven):
       dnf install -y java-25-openjdk maven
       # Debian/Ubuntu (latest JDK 25 + Maven):
       apt-get update && apt-get install -y openjdk-25-jdk maven
       ```
     - If Maven is missing, add it to the Dockerfile RUN command.
   - **Compile**: Run `mvn compile` with timeout `${JAVA_BUILD_TIMEOUT_MS}` ms. Verify exit code 0.
   - **Package**: Run `mvn package` with timeout `${JAVA_BUILD_TIMEOUT_MS}` ms. Verify exit code 0.
   - **Artifact Check**: Verify JAR exists in `target/`: `ls target/ringbuffer-*.jar`. If no JAR found, STOP and report build failure.
   - **Log**: Append results to `src/common/java/logs/build.log`.

   ---

   **Python Build** (common source + platform-specific Makefile):
   - **Common Source**: `src/common/python/` contains shared Python source files (swtr_ringbuffer_pure.py, test scripts, base types). This directory uses `Makefile.gnu` for GNU make systems (macOS + Linux).
   - **Per-Platform Python Directories**: For BSD make systems (FreeBSD 14+), create `src/<os>/python/` with:
     - BSD-compatible Makefile (no `$(shell)`, no `ifeq/else`)
     - Copies of common Python source files from `src/common/python/`
     - FreeBSD-specific C++ path (`../../freebsd14/cpp`)
   - **Makefile Selection**:
     - GNU make (macOS/Linux): Use `src/common/python/Makefile.gnu`
     - BSD make (FreeBSD 14+): Use `src/<os>/python/Makefile`
   - **Version Check**: Verify Python version meets minimum requirements (3.10+): `python3 --version`. If below 3.10, STOP and report: `ERROR: Detected Python version <detected_version> is below minimum supported 3.10. Cannot proceed.`
   - **Dockerfile Package Validation** (Linux targets only):
     - For each target OS, check the per-OS Dockerfile at `src/common/python/containers/<os>/Dockerfile` and verify it contains:
       - `python3` — latest available Python 3.x in each distro's repos (Fedora: latest stable; Debian/Ubuntu: default python3 which is the distro's latest)
       - `python3-pip` — Python package manager
     - If Python is missing, add it to the Dockerfile RUN command:
       ```dockerfile
       # Fedora (latest Python 3.x + pip):
       dnf install -y python3 python3-pip
       # Debian/Ubuntu (latest Python 3.x + pip):
       apt-get update && apt-get install -y python3 python3-pip
       ```
   - **Syntax Check**: Run `python3 -m py_compile` on all `.py` files in the source directory to verify syntax correctness.
   - **Import Check**: Run `python3 -c "import swtr_ringbuffer; print(swtr_ringbuffer.__version__)"` to verify the module imports cleanly.
   - **Instantiation Check**: Run `python3 -c "from swtr_ringbuffer import SwtrRingBuffer; rb = SwtrRingBuffer(4, 256); print(type(rb))"` to verify core classes are instantiable.
   - **Completion**: The build is complete once all Python files pass syntax checking, the module imports cleanly, and core classes are instantiable.
   - **Log**: Append results to `src/common/python/logs/build.log`.

**Directives:**
1. Use `prompts/<os>/cpp/build.md` for platform-specific prerequisites (package lists, container settings).
2. Use `prompts/common/cpp/build.md` as the primary build specification.

**Immediate Requirements:**
- **Logging**: Every build step, configuration change, and verification result MUST be recorded in `src/<os>/cpp/logs/build.log`.
- **Configuration**: Create the build configuration (Makefile) in `src/<os>/cpp`.
- **Documentation**: Create the `specs/` subdirectory and place `build.md`, `testing_requirements.md`, and `artifacts.md` files within it.
- **Versioning**: The build system MUST source `version.mk` to generate the versioned artifact names.
- **Artifacts**: 
    - Deploy libraries to the `lib/` subdirectory.
    - Create relative symbolic links from unversioned names to versioned artifacts within the `lib/` directory.
- **Optimization**: Ensure `-flto`, `-fvisibility=hidden`, `-ffunction-sections`, `-fdata-sections` are applied. For Linux targets, also add `-Wl,--gc-sections`. For macOS targets, use `-dead_strip` instead of `--gc-sections`.
- **Makefile Consistency**: The generated `Makefile` MUST follow the common build specification exactly, with only the allowed platform-specific differences (`CONTAINER_IMAGE`, working directory path, host distro check). Do not compare against or copy from any other platform's Makefile.
- **CXX Default**: On macOS targets, the Makefile MUST use `CXX := clang++` (not `?=`) to override macOS Make's built-in default of `CXX = c++`.
- **`dist-clean` Target**: The Makefile's `dist-clean` target MUST check whether a `tests/` directory exists. If it does, it MUST execute `make -C tests dist-clean` to recursively clean the test subdirectory. If `tests/` does not exist, it MUST skip silently (no error). It MUST also remove both the local `reports/` directory (inside cpp/) and the parent-level `../reports/` directory, plus the `logs/` directory. This ensures that running `make dist-clean` at the project root fully cleans all build artifacts across both library and test directories.

**Reporting:**
Once implementation is complete, generate a summary report at `src/<os>/reports/build_creation_report.md`:

# Build Creation Report - [OS Name]
**Date:** [YYYY-MM-DD HH:MM:SS +/-HHMM]
**Target Image:** <resolved_image>
**Ringbuffer Version:** <resolved_version from shared context>
**Start Time:** [YYYY-MM-DD HH:MM:SS +/-HHMM]
**End Time:** [YYYY-MM-DD HH:MM:SS +/-HHMM]
**Elapsed Time:** [Duration]

## Status
**Build System Created:** [Yes/No]
**Container Image Built:** [Yes/No — Linux targets only; macOS is native-only]
**Library Build Successful:** [Yes/No]
**Self-Audit Passed:** [Yes/No]

## Artifacts Created
- **Makefile**: `src/<os>/cpp/Makefile`
- **Dockerfile** (Linux targets only): `src/<os>/cpp/containers/Dockerfile`
- **Specs**: `specs/build.md`, `specs/testing_requirements.md`, `specs/artifacts.md`
- **Library Artifacts**: [List of `.a` and `.so` or `.dylib` files in `lib/`]
- **Logs**: `build.log` created and updated.

## Self-Audit Results
- **Makefile Targets**: [PASS/FAIL] — `all`, `static`, `shared`, `clean`, `dist-clean` (and `container` for Linux targets)
- **Dockerfile** (Linux targets only): [PASS/FAIL] — base image, package installation
- **Specs Directory**: [PASS/FAIL] — `build.md`, `testing_requirements.md`, `artifacts.md` present
- **Source Consistency**: [PASS/FAIL] — all `.cpp` files in `SRCS`
- **Artifact Verification**: [PASS/FAIL] — architecture, SONAME/install name, symlinks

## Fixes and Modifications
*If files were modified to achieve a successful build, list them here:*
- `path/to/file`: [Brief explanation of the fix]

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions (e.g., `` ErrorOps.cpp`} ``, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.

## Scope Boundary — Build Phase Only

The purpose of this prompt is to create the build environment and compile the library. **Your task ends once both `libswtr_ringbuffer.a` and `libswtr_ringbuffer.so` (or `.dylib`) exist with correct symlinks.**

You MUST NOT:
- Run `make verify` or `make -C tests`
- Generate test data, compile test binaries, or execute any tests
- Invoke `regression_test_execution.md` or any testing workflow
- Proceed to verification, reporting, or test matrix execution

**Directory Scope Restriction:**
- **NEVER create, modify, or delete any files inside the `tests/` directory.** This includes:
  - Test source code (`tests/src/`)
  - Test data files (`tests/data/inputs/`, `tests/data/expected/`)
  - Test utility scripts (`tests/utils/bin/`)
  - Test container configurations (`tests/containers/`)
  - Test Makefiles, logs, or reports
- If the `tests/` directory is missing required files (e.g., `verify_test_data.sh`, test data, logs/reports directories), **report this as a finding and STOP**. Do not create or fix them.
- The `tests/` directory is managed exclusively by testing-related prompts (e.g., `create_testing.md`, `update_testing.md`). Build-only prompts must treat it as read-only.

**Excluded Platforms:**
- **FreeBSD 14**, **FreeBSD 15**, and **ArchLinux** are excluded from active development.
- Do not modify, add content to, or create new files in `prompts/freebsd14/`, `prompts/freebsd15/`, or `prompts/archlinux/`.
- The only files that should exist in these directories are zero-length `build.md`, `functional.md`, and `testing.md` files.
- If these directories contain any non-zero files, remove them.

If the user wants testing, they will issue a separate request (e.g., "run tests" or "verify the build"). Do not assume testing is part of a build request.
