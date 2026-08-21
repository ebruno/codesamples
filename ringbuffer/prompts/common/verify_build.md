# Build Verification Workflow

**Objective:** 
Verify that all implemented languages build successfully across supported operating systems.

**Build/Test Pattern (MANDATORY):** Every language follows the same two-step pattern:
- `verify_build` → `<os>/<lang>/Makefile all` (build only, no tests)
- `run_regression` → `tests/Makefile verify` (test matrix T001-T007)
- See `.bionic` section "Build vs Test Workflow Pattern (All Languages)" for details.

**GOLDEN RULES — READ BEFORE EXECUTING:**

1. **NEVER modify source code during verification.** `verify_build` and `run_regression` are detect-only workflows. They must NEVER modify:
   - Source code files (`.cpp`, `.hpp`, `.java`, `.py`, etc.)
   - Build configuration files (`Makefile`, `pom.xml`, `go.mod`, `Cargo.toml`)
   - Dockerfiles or container configurations
   
   If a build fails, the agent must:
   - Record the full error in the build log and report
   - Mark the OS/language combination as **UNSUPPORTED** with a reason file at `src/<os>/<lang>/UNSUPPORTED.md`
   - Move on to the next OS/language — do NOT attempt fixes

2. **Detect, don't fix.** The role of `verify_build` and `run_regression` is to identify problems, not solve them.
   - If a compiler version is too old → flag as unsupported, document the minimum required version
   - If a header file is missing → flag as unsupported, document what's needed
   - If a build target fails → record the error, mark as unsupported, continue
   
   Source code changes require explicit user permission at the start of the session.

3. **No silent workarounds.** Do NOT:
   - Change compiler flags to work around missing features
   - Replace `g++` with `clang++` (or vice versa) to avoid errors
   - Modify include paths or preprocessor defines
   - Skip tests silently
   
   Every failure must be reported, not hidden.

4. **Unsupported OS/Language Documentation.** When an OS/language combination cannot build or test:
   - Create `src/<os>/<lang>/UNSUPPORTED.md` explaining why
   - Include: detected toolchain version, required minimum version, specific error
   - Update the consolidated report with `UNSUPPORTED` status and link to the reason file

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

   **CRITICAL — DO NOT CONFUSE:**
   - `verify_build` → **always** uses `make all` (build only, no tests)
   - `run_regression` → **always** uses `make verify` in the `tests/` directory (build + T001-T007)
   - If you find yourself about to run `make verify` during `verify_build`, STOP — that is wrong.
   - If you find yourself about to run `make all` during `run_regression`, STOP — that is wrong.

   **SELF-CHECK BEFORE EXECUTING:**
   - Am I in `verify_build`? → Must run `make all`, NOT `make verify`
   - Am I in `run_regression`? → Must run `make verify`, NOT `make all`
   - If unsure, re-read the workflow header to confirm which mode you are in.

   **Standard Clean + Build Process (When C++ Is Used)**
   - For any language that depends on the C++ shared library (Python, and future languages with C bindings), run this sequence BEFORE `make all` in the language directory:
     1. **`make clean`** in `<os>/cpp/` — removes stale C++ library artifacts (`.a`, `.so`, `.dylib`, object files)
     2. **`make clean`** in `<os>/<lang>/` (or `src/common/<lang>/`) — removes stale language-specific build artifacts
     3. **`make all`** in `<os>/<lang>/` (or `src/common/<lang>/`) — builds C++ library, creates symlinks
   - **Why this matters:** If the C++ library was previously built for a different platform (e.g., ELF ARM64 inside a container), stale artifacts on the host will cause linker errors (e.g., `archive member not a mach-o file`). Cleaning both the C++ and language directories ensures no stale artifacts remain.
   - **Example — Python on macOS:**
     ```bash
     cd src/macos/cpp && make clean          # Remove stale C++ library
     cd src/common/python && make clean      # Remove stale Python artifacts
     cd src/common/python && make all        # Build C++ lib, create symlinks
     ```
   - **Example — Python on Fedora (from macOS host):**
     ```bash
     cd src/fedora/cpp && make clean         # Remove stale C++ library
     cd src/common/python && make clean      # Remove stale Python artifacts
     cd src/common/python && make all        # Builds inside container via Makefile
     ```

   **Universal Toolchain Compatibility Gate** (applies to ALL languages — runs BEFORE any build attempt):
   - This is a **blocking gate** for every language and platform — the build cannot proceed until toolchain versions match.
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
     3. **Execute Build** (verify_build uses `make all` — build only, no tests):
        - **Native**: Navigate to `src/common/java/`, then run `make all`. The Makefile automatically:
          1. Runs Maven to compile and package (`mvn clean compile package`)
          2. Creates JAR symlink: `lib/ringbuffer.jar` → `target/ringbuffer-<version>.jar`
        - **Container**: Run in a container matching the target OS:
          - Build the per-OS build image first: `cd src/common/java && $(CONTAINER_CMD) build -t ringbuffer_<os>_build -f ../../<os>/containers/build/Dockerfile .`
          - **Per-platform pom.xml override**: If a platform-specific `pom.xml` exists at `src/<os>/java/pom.xml`, mount it to override the common pom.xml. This is required when the platform's JDK version differs from the common spec (e.g., raspios has JDK 17, but common pom.xml uses `<release>25</release>`).
          ```bash
          # macOS host targeting Linux distro:
          if [ -f src/<os>/java/pom.xml ]; then
              container run --rm -v $(pwd)/src/common/java:/app -v $(pwd)/src/<os>/java/pom.xml:/app/pom.xml $IMAGE sh -c "cd /app && make all"
          else
              container run --rm -v $(pwd)/src/common/java:/app $IMAGE sh -c "cd /app && make all"
          fi
          # Linux host targeting another Linux distro:
          if [ -f src/<os>/java/pom.xml ]; then
              podman run --rm -v $(pwd)/src/common/java:/app -v $(pwd)/src/<os>/java/pom.xml:/app/pom.xml $IMAGE sh -c "cd /app && make all"
          else
              podman run --rm -v $(pwd)/src/common/java:/app $IMAGE sh -c "cd /app && make all"
          fi
          ```
     4. **Post-Build Verification**:
        - Verify the JAR artifact exists: `target/ringbuffer-<version>.jar`
        - Verify the symlink exists: `lib/ringbuffer.jar` → `target/ringbuffer-<version>.jar`
        - If any check fails, STOP and report the error.
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
     3. **Execute Build** (verify_build uses `make all` — build only, no tests):
        - **Native**: Navigate to `src/common/python/`, then run `make all`. The Makefile automatically:
          1. Builds the C++ shared library from `src/<os>/cpp/` (target-host-specific) via parent Makefile.
          2. Creates symlink: `lib/libswtr_ringbuffer.so` → `<os>/cpp/lib/libswtr_ringbuffer-<version>.so`
        - **Container**: Run in a container matching the target OS:
          - Build the per-OS build image first: `cd src/common/python && $(CONTAINER_CMD) build -t ringbuffer_<os>_build -f ../../<os>/containers/build/Dockerfile .`
          - **Volume mounts**: The Python Makefile.linux uses relative paths (`../../<os>/cpp`) to find C++ source. Inside the container, these resolve to `/<os>/cpp` and `/common/cpp`. Mount both:
          ```bash
          # macOS host targeting Linux distro:
          cd src/common/python && container build -t ringbuffer_<os>_build -f ../../<os>/containers/build/Dockerfile .
          container run --rm \
            -v $(pwd)/src/common/python:/app \
            -v $(pwd)/src/<os>/cpp:/<os>/cpp \
            -v $(pwd)/src/common/cpp:/common/cpp \
            ringbuffer_<os>_build sh -c "cd /app && make all"
          # Linux host targeting another Linux distro:
          cd src/common/python && podman build -t ringbuffer_<os>_build -f ../../<os>/containers/build/Dockerfile .
          podman run --rm \
            -v $(pwd)/src/common/python:/app \
            -v $(pwd)/src/<os>/cpp:/<os>/cpp \
            -v $(pwd)/src/common/cpp:/common/cpp \
            ringbuffer_<os>_build sh -c "cd /app && make all"
          ```
     4. **Post-Build Verification**:
        - Verify the C++ shared library exists in `src/<os>/cpp/lib/`
        - Verify the symlink exists: `lib/libswtr_ringbuffer.so` → versioned library
        - If any check fails, STOP and report the error.
     5. **Log**: Append results to `src/common/python/logs/build.log` with the target OS noted: `[timestamp] Python verification on <target_os>: ROUTE=<native|container> STATUS=<PASS/FAIL>`.

   ---

   **0.3 C/C++ Verification** (from `src/<os>/cpp/`):
   - Navigate to `src/<os>/cpp/`.
   - **Container Image Resolution** (Linux targets on non-matching host only):
     - Build the image if it does not already exist: `container build -t ringbuffer_<os>_build:latest -f ../containers/build/Dockerfile .`
     - Use `ringbuffer_<os>_build:latest` as `<container_image>` in subsequent commands.
   - **Build Execution**: If using a container, wrap the build command with the appropriate runtime:
     - **macOS host**: `container run --rm -v $(pwd):/app ringbuffer_<os>_build:latest make test`
     - **Linux host**: `podman run --rm -v $(pwd):/app ringbuffer_<os>_build:latest make test`
     - If native execution is permitted (host matches target), run `make test` directly.
     - The Makefile's `test` target automatically:
       1. Builds the library (`all` target — static + shared)
       2. Runs tests/verify in the `tests/` subdirectory
     - If `make test` fails, log the error and STOP processing for this platform.
   - **Post-Build Verification** (performed by `tests/Makefile verify`):
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
     - **make test**: [PASS/FAIL]
     - **C++ Library Build**: [SUCCESS / SKIPPED — reason] (checked via `.cpp_build_failed` marker)

     ## Concurrent (ctypes) Test Results
     **Implementation:** `swtr_ringbuffer/swtr_ringbuffer_concurrent.py` — ctypes binding to C++ shared library
     **Entry Point:** `from swtr_ringbuffer import SwtrRingBuffer` (auto-selects Concurrent when available)

     | Test | Description | Result |
     |------|-------------|--------|
     | T001 | Default (identity transform) | [PASS/FAIL] |
     | T002 | Stress test (1 slot, 1-byte buffer) | [PASS/FAIL] |
     | T003 | Uppercase transform | [PASS/FAIL] |
     | T004 | Small input, fast EOF | [PASS/FAIL] |
     | T005 | Fatal error mode | [PASS/FAIL] |
     | T006 | Non-fatal error mode | [PASS/FAIL] |
     | T007 | XOR transform (bit-inverted) | [PASS/FAIL] |

     **Overall:** [X]/7 tests passed. Concurrent (ctypes) selected as default via auto-import.

     ## Pure Python Test Results
     **Implementation:** `swtr_ringbuffer_pure.py` — pure Python, no C++ dependency
     **Entry Point:** `from swtr_ringbuffer_pure import SwtrRingBufferPure`

     | Test | Description | Result |
     |------|-------------|--------|
     | T001 | Default (identity transform) | [PASS/FAIL] |
     | T002 | Stress test (1 slot, 1-byte buffer) | [PASS/FAIL] |
     | T003 | Uppercase transform | [PASS/FAIL] |
     | T004 | Small input, fast EOF | [PASS/FAIL] |
     | T005 | Fatal error mode | [PASS/FAIL] |
     | T006 | Non-fatal error mode | [PASS/FAIL] |
     | T007 | XOR transform (bit-inverted) | [PASS/FAIL] |

     **Overall:** [X]/7 tests passed. Pure Python provides full feature parity with Concurrent version.

     ## Notes
     - Any additional notes about the build process (e.g., C++ library not available, performance benchmark results).
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
         "concurrent_module": "swtr_ringbuffer/swtr_ringbuffer_concurrent.py",
         "pure_python_module": "swtr_ringbuffer_pure.py",
         "test_script_concurrent": "test_ringbuffer.py",
         "test_script_pure": "test_ringbuffer_pure.py"
       },
       "sha256": {
         "version_mk": "<hash>",
         "base_py": "<hash>",
         "swtr_ringbuffer_concurrent_py": "<hash>",
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
5. After all languages complete, run `utils/bin/aggregate_junit.sh` to merge all JUnit XML files into `reports/junit/aggregated.xml` and generate `reports/junit/aggregated.html`.

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions (e.g., `.cpp`, `.hpp`, or `Makefile`), such as `` ErrorOps.cpp`} ``, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.
