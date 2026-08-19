# Build Verification Workflow

**Objective:** 
Verify that all implemented languages build successfully across supported operating systems.

**Process:**
1. **Target and Mode Selection**:
   - **Host-OS Auto-Detection**: At the start of every run, detect the host OS:
     - If `uname -s` returns `Darwin`, set `host_os = macOS`.
     - If it returns `Linux`, read the distro ID from `/etc/os-release`: `host_os=$(grep '^ID=' /etc/os-release | cut -d= -f2)`.
     - Supported Linux distros: `ubuntu`, `debian`, `fedora`, `raspios`, `archlinux`.
   - **Targeting**: 
     - **Specified Platform + Language**: If the user specifies a language and platform (e.g., "verify_build for java on fedora"), verify only that language on that OS. Run natively if host matches target; use container if host doesn't match.
     - **Specified Platform Only**: If the user specifies a platform but no language (e.g., "run build_verify for debian"), verify all implemented languages on that OS. Run natively if host matches target; use container if host doesn't match.
     - **Specified Language Only**: If the user specifies a language but no platform (e.g., "verify_build for java"), verify that language on all supported OSes using the routing table below.
     - **General Request (no platform, no language)**: Verify all implemented languages on all supported OSes using the routing table below.
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

2. **Execution Steps**:
   For each language present in the workspace, perform the appropriate verification independently. A failure in one language does not stop verification of others.

   **Language Dispatch**:
   - Detect which languages are implemented by checking for source directories:
     - `src/<os>/cpp/` → C/C++ verification (platform-sensitive, per-OS)
     - `src/common/java/` → Java verification (platform-insensitive, common)
     - `src/common/python/` → Python verification (platform-insensitive, common)
   - Log which languages are being verified: `[timestamp] Languages detected: <comma-separated list>`

   **Timeout Configuration**: All timeout values are defined as variables for easy adjustment:
   - `CONTAINER_BUILD_TIMEOUT_MS`: 600,000 ms (10 minutes) — maximum time for `make container`
   - `LIBRARY_BUILD_TIMEOUT_MS`: 600,000 ms (10 minutes) — maximum time for `make clean && make`
   - `JAVA_BUILD_TIMEOUT_MS`: 600,000 ms (10 minutes) — maximum time for `mvn compile`
   - `PYTHON_BUILD_TIMEOUT_MS`: 60,000 ms (1 minute) — maximum time for Python syntax/import checks

   **Host-OS Detection** (applies to all languages):
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
     ProductVersion:	26.5.2
     BuildVersion:	25F84
     ```
     Help: `sw_vers -h` → Usage: sw_vers [--help|--productName|--productVersion|--productVersionExtra|--buildVersion]
   - **Apple Container Runtime**: macOS uses the `container` command (Apple Container), NOT Docker or podman. Key subcommands:
     - `container run` — Run a container
     - `container build` / `container image build` — Build an image from Dockerfile
     - `container images` / `container image list` — List images
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
   - **Excluded Platforms**:
     - **C/C++**: FreeBSD 14, FreeBSD 15, and ArchLinux are excluded from active C/C++ development (no native build toolchain on FreeBSD).
     - **Python/Java**: FreeBSD 14 Python is verified and active — build verification IS executed for common languages on FreeBSD 14.
     - **ArchLinux**: Excluded from all active development (no container images for Apple Silicon).

   **Container Pre-flight Check** (C/C++ Linux targets only):
   - If the target OS is a Linux distribution and the host OS does not match, verify the container runtime is available:
     - **macOS host**: `command -v container` — if not found, STOP and display error about installing Apple Container.
     - **Linux host**: `command -v podman` — if not found, STOP and display error about installing Podman.
   - If the target is macOS or FreeBSD, skip container checks entirely.

   ---

   **0.1 Java Verification** (from `src/common/java/`):
   - Java is a **common language** — source lives in `src/common/java/` but must be verified on each supported OS.
   - **Determine target OSes to verify**:
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
     3. **Execute Verification**:
        - **Native**: Navigate to `src/common/java/`, then run the verification steps directly.
        - **Container**: Run in a container matching the target OS:
          - First, resolve the image from the per-OS Dockerfile: `IMAGE=$(head -1 src/common/java/containers/<os>/Dockerfile | sed 's/^FROM //')`
          - If no per-OS Dockerfile exists, fall back to the C/C++ Dockerfile: `IMAGE=$(head -1 src/<os>/cpp/containers/Dockerfile | sed 's/^FROM //')`
          - **Per-platform pom.xml override**: If a platform-specific `pom.xml` exists at `src/<os>/java/pom.xml`, mount it to override the common pom.xml. This is required when the platform's JDK version differs from the common spec (e.g., raspios has JDK 17, but common pom.xml uses `<release>25</release>`).
          ```bash
          # macOS host targeting Linux distro:
          if [ -f src/<os>/java/pom.xml ]; then
              container run --rm -v $(pwd)/src/common/java:/app -v $(pwd)/src/<os>/java/pom.xml:/app/pom.xml $IMAGE sh -c "cd /app && mvn compile package && rm -rf target/classes target/test-classes"
          else
              container run --rm -v $(pwd)/src/common/java:/app $IMAGE sh -c "cd /app && mvn compile package && rm -rf target/classes target/test-classes"
          fi
          # Linux host targeting another Linux distro:
          if [ -f src/<os>/java/pom.xml ]; then
              podman run --rm -v $(pwd)/src/common/java:/app -v $(pwd)/src/<os>/java/pom.xml:/app/pom.xml $IMAGE sh -c "cd /app && mvn compile package && rm -rf target/classes target/test-classes"
          else
              podman run --rm -v $(pwd)/src/common/java:/app $IMAGE sh -c "cd /app && mvn compile package && rm -rf target/classes target/test-classes"
          fi
          ```
     4. **Verification Steps** (run in the appropriate execution context):
        - Navigate to `src/common/java/`.
        - **Toolchain Check**: Verify `mvn` is available: `command -v mvn`. If not found, STOP and report that Maven must be installed.
        - **Compile + Package**: Run `mvn compile package` with timeout `${JAVA_BUILD_TIMEOUT_MS}` ms. Verify exit code 0.
        - **Clean up intermediates**: `rm -rf target/classes target/test-classes`.
        - **Artifact Check**: Verify JAR exists in `target/`: `ls target/ringbuffer-*.jar`. If no JAR found, STOP and report build failure.
        - **Classload Test**: Run a quick classload test to verify no runtime errors on load:
          ```bash
          java -cp "target/ringbuffer-*.jar" swtr.test.TestRingbuffer 2>&1 | head -5
          ```
          Verify no `NoClassDefFoundError`, `ExceptionInInitializerError`, or other runtime exceptions.
          If multiple JARs exist (e.g., sources jar), use the main artifact explicitly:
          ```bash
          MAIN_JAR=$(ls target/ringbuffer-*.jar | grep -v sources)
          java -cp "$MAIN_JAR" swtr.test.TestRingbuffer 2>&1 | head -5
          ```
     5. **Log**: Append results to `src/common/java/logs/build.log` with the target OS noted: `[timestamp] Java verification on <target_os>: ROUTE=<native|container> STATUS=<PASS/FAIL>`.

   ---

   **0.2 Python Verification** (from `src/common/python/`):
   - Python is a **common language** — source lives in `src/common/python/` but must be verified on each supported OS.
   - **Determine target OSes to verify**:
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
     3. **Execute Verification**:
        - **Native**: Navigate to `src/common/python/`, then run `make build` to compile the C++ shared library and create the symlink in `lib/`. If the C++ build fails (e.g., no C++ source directory), note it and continue — Pure Python tests still apply. Then run the verification steps below.
        - **Container**: Run in a container matching the target OS:
          - Build the per-OS Python container image first: `cd src/common/python && $(CONTAINER_CMD) build -t ringbuffer_python_<os> -f containers/<os>/build/Dockerfile .`
          - If no per-OS Dockerfile exists, fall back to the C/C++ Dockerfile: `IMAGE=$(head -1 src/<os>/cpp/containers/Dockerfile | sed 's/^FROM //')`
          ```bash
          # macOS host targeting Linux distro:
          cd src/common/python && container build -t ringbuffer_python_<os> -f containers/<os>/build/Dockerfile .
          container run --rm -v $(pwd)/src/common/python:/app ringbuffer_python_<os> sh -c "cd /app && python3 -m py_compile *.py"
          # Linux host targeting another Linux distro:
          cd src/common/python && podman build -t ringbuffer_python_<os> -f containers/<os>/build/Dockerfile .
          podman run --rm -v $(pwd)/src/common/python:/app ringbuffer_python_<os> sh -c "cd /app && python3 -m py_compile *.py"
          ```
     4. **Verification Steps** (run in the appropriate execution context):
        - Navigate to `src/common/python/`.
        - **Version Check**: Verify Python version meets minimum requirements (3.10+): `python3 --version`. If below 3.10, STOP and report: `ERROR: Detected Python version <detected_version> is below minimum supported 3.10. Cannot proceed.`
        - **Syntax Check**: Run `python3 -m py_compile` on all `.py` files:
          ```bash
          for f in *.py; do python3 -m py_compile "$f" || { echo "SYNTAX ERROR in $f"; exit 1; }; done
          ```
          If any file fails, STOP and report the error.
        - **Import Check (Concurrent)**: Run `python3 -c "import swtr_ringbuffer; print(swtr_ringbuffer._version)"` to verify the Concurrent module imports cleanly. If import fails, STOP and report the error.
        - **Instantiation Check (Concurrent)**: Run `python3 -c "from swtr_ringbuffer import SwtrRingBuffer; rb = SwtrRingBuffer(4, 256); print(type(rb))"` to verify Concurrent class is instantiable. If instantiation fails, STOP and report the error.
        - **Import Check (Pure Python)**: Run `python3 -c "import swtr_ringbuffer_pure; print(swtr_ringbuffer_pure.__name__)"` to verify the Pure Python module imports cleanly. If import fails, STOP and report the error.
        - **Instantiation Check (Pure Python)**: Run `python3 -c "from swtr_ringbuffer_pure import SwtrRingBufferPure; rb = SwtrRingBufferPure(4, 256); print(type(rb))"` to verify Pure Python class is instantiable. If instantiation fails, STOP and report the error.
     5. **Log**: Append results to `src/common/python/logs/build.log` with the target OS noted: `[timestamp] Python verification on <target_os>: ROUTE=<native|container> STATUS=<PASS/FAIL>`.

   ---

   **0.3 C/C++ Verification** (from `src/<os>/cpp/`):
   - Navigate to `src/<os>/cpp/`.
   - **Build Execution**: If using a container, wrap the build command with the appropriate runtime:
     - **macOS host**: `container run --rm -v $(pwd):/app <container_image> make clean && make`
     - **Linux host**: `podman run --rm -v $(pwd):/app <container_image> make clean && make`
     - If native execution is permitted (host matches target), run `make clean && make` directly.
     - If the build fails, log the error and STOP processing for this platform.
   - **Post-Build Verification**:
     - Verify the library was built: Check that `lib/libswtr_ringbuffer.a` (static) and/or `lib/libswtr_ringbuffer.so` / `.dylib` (shared) exist.
     - Verify binary format:
       - **Linux**: `file lib/libswtr_ringbuffer.so` should show "ELF 64-bit"
       - **macOS**: `file lib/libswtr_ringbuffer.dylib` should show "Mach-O"
     - Verify symbol visibility:
       - **Linux**: `nm -gjU lib/libswtr_ringbuffer.so` should show only exported symbols
       - **macOS**: `nm -gU lib/libswtr_ringbuffer.dylib` should show only exported symbols
     - Verify binary size: Check that the library is within expected size range (typically < 100KB for this project).
   - **Binary Symmetry Check** (Linux platforms only):
     - After building all Linux platforms, run the binary symmetry verification script to ensure source files are byte-identical across platforms:
       ```bash
       ./prompts/common/cpp/utils/bin/verify_binary_symmetry.sh <workspace_root>
       ```
     - If the script reports any differences, log them and STOP — this indicates a violation of the binary symmetry requirement.
     - If all files are identical, log: `[timestamp] Binary symmetry verification passed — all Linux platforms produce byte-identical source.`
   - **Log**: Append results to `src/<os>/cpp/logs/build.log`.

   ---

   **0.4 Prompt Lint Check** (all languages):
   - Before or after build verification, run the prompt lint script to ensure all platform/language directories follow conventions:
     ```bash
     ./prompts/common/cpp/utils/bin/lint_prompts.sh <workspace_root>
     ```
   - If the script reports any errors, log them and STOP — this indicates a structural issue with the prompt directory layout.
   - Warnings (e.g., excluded platforms not found) are acceptable and should be logged but do not stop processing.

   ---

   **1. Report Generation**:
   - For C/C++: Generate a build verification report at `reports/cpp/per_os/<os>_build_verify.md` and JUnit XML at `reports/cpp/per_os/<os>_regression_report_junit.xml` (if applicable) with the following format:
     ```markdown
     # Build Verification Report - [OS Name] <version> — C/C++
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
   - For Java: Generate a build verification report at `reports/java/per_os/<os>_build_verify.md` and copy JUnit XML from `target/surefire-reports/TEST-*.xml` to `reports/java/per_os/<os>_regression_report_junit.xml` with the following format:
     ```markdown
     # Build Verification Report — Java
     **Date:** [YYYY-MM-DD HH:MM:SS +/-HHMM]
     **Host OS:** <host_os>

     ## Build Status
     - **Maven Compile**: [PASS/FAIL]
     - **Maven Package**: [PASS/FAIL]
     - **JAR Artifact**: [PASS/FAIL]
     - **Classload Test**: [PASS/FAIL]

     ## Artifacts
     - `target/ringbuffer-<version>.jar`: <size> bytes

     ## Notes
     - Any additional notes about the build process.
     ```
   - For Python: Generate a build verification report at `reports/python/per_os/<os>_build_verify.md` and JUnit XML at `reports/python/per_os/<os>_regression_report_junit.xml` with the following format:
     ```markdown
     # Build Verification Report — Python
     **Date:** [YYYY-MM-DD HH:MM:SS +/-HHMM]
     **Host OS:** <host_os>
     **Python Version:** <detected_version>

     ## Build Status
     - **Syntax Check**: [PASS/FAIL] (all .py files)
     - **Concurrent Import**: [PASS/FAIL]
     - **Concurrent Instantiation**: [PASS/FAIL]
     - **Pure Python Import**: [PASS/FAIL]
     - **Pure Python Instantiation**: [PASS/FAIL]

     ## Concurrent (ctypes) Verification
     | Check | Result | Details |
     |-------|--------|---------|
     | Syntax Check | [PASS/FAIL] | swtr_ringbuffer/swtr_ringbuffer_hp.py, base.py, __init__.py |
     | Import Check | [PASS/FAIL] | import swtr_ringbuffer, version = "Concurrent" |
     | Instantiation Check | [PASS/FAIL] | SwtrRingBufferHP(4, 256) |
     | Shared Library | [PASS/FAIL] | libswtr_ringbuffer.so/.dylib available |

     ## Pure Python Verification
     | Check | Result | Details |
     |-------|--------|---------|
     | Syntax Check | [PASS/FAIL] | swtr_ringbuffer_pure.py |
     | Import Check | [PASS/FAIL] | import swtr_ringbuffer_pure |
     | Instantiation Check | [PASS/FAIL] | SwtrRingBufferPure(4, 256) |
     | Dependencies | [PASS/FAIL] | No external dependencies |

     ## Notes
     - Any additional notes about the build process.
     ```

   **2. State Tracking** (Java and Python only):
   - For common languages, `verify_build.md` creates the initial `.gen_state.json`. `run_regression.md` will later enrich it with test results.
   - **Java**: Create or update `.gen_state.json` in `src/common/java/` containing:
     ```json
     {
       "language": "java",
       "version": "<MAJOR.MINOR.SUBVERSION-BUILD_ID from version.mk>",
       "java_version": "<detected JDK version>",
       "maven_version": "<detected Maven version>",
       "build_status": {
         "<os>": {"route": "native|container", "status": "PASS|FAIL", "timestamp": "<ISO timestamp>"}
       },
       "artifacts": {"jar": "target/ringbuffer-<version>.jar"},
       "sha256": {"pom_xml": "<hash>", "version_mk": "<hash>"}
     }
     ```
   - **Python**: Create or update `.gen_state.json` in `src/common/python/` containing:
     ```json
     {
       "language": "python",
       "version": "<MAJOR.MINOR.SUBVERSION-BUILD_ID from version.mk>",
       "python_version": "<detected Python version>",
       "build_status": {
         "<os>": {"route": "native|container", "status": "PASS|FAIL", "timestamp": "<ISO timestamp>"}
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
   - Compute SHA-256 hashes of relevant source files for each language.

   **3. Log Finalization**:
   - For each language verified, append a final entry to its respective `build.log` stating that build verification is complete.
   - Calculate and include the total elapsed time since the start timestamp in each final entry.

**Reporting:**
Once verification is complete:
1. Generate the per-OS report at `reports/<lang>/per_os/<os>_build_verify.md` (Java/Python) or `reports/cpp/per_os/<os>_build_verify.md` (C/C++).
2. Generate JUnit XML at `reports/<lang>/per_os/<os>_regression_report_junit.xml` (Java/Python) or copy from test harness output (C/C++).
3. Update the consolidated summary at `reports/<lang>/build_verify.md` by merging all per-OS results into a single table.
4. Append to `src/common/<lang>/logs/build.log` with the target OS noted.
5. After all languages complete, run `reports/aggregate_junit.sh` to merge all JUnit XML files into `reports/junit/aggregated.xml` and generate `reports/junit/aggregated.html`.

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions (e.g., `.cpp`, `.hpp`, or `Makefile`), such as `` ErrorOps.cpp`} ``, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.
