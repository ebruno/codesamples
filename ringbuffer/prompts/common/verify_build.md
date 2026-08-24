# Build Verification Workflow

**Objective:** 
Verify that all implemented languages build successfully across supported operating systems.

**STEP 0 — LOAD BUILD WORKFLOW RULES (FIRST ACTION):**
Before executing any step in this document, read and load `rules/verify-build-workflow.md`. This document defines the build verification workflow rules — Pre-Action Checklist, Build vs Test Workflow Pattern, Pre-Flight Check, Standard Clean + Build Process, and Verification Scripts. All execution in this document must comply with those rules.

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
     - `src/<os>/cpp/` → C++ verification (platform-sensitive, per-OS)
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
     - **C++**: FreeBSD 14 is supported (clang++/g++ available). FreeBSD 15 is excluded — zero-length files only.
     - **C**: Not yet implemented — common specs exist (`prompts/common/c/`) but no source generation or build verification.
     - **Python/Java**: FreeBSD 14 Python is verified and active — build verification IS executed for common languages on FreeBSD 14.
     - **ArchLinux**: Native tooling supported (g++/clang++). Linux-hosts-only for container-based verification from macOS hosts.

   **Container Pre-flight Check** (C++ Linux targets only):
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
        - C++: Makefile with platform-specific flags, or `version.mk` compatibility
        - Python: per-OS Makefile with correct interpreter path
        - Go: `go.mod` with compatible version constraint
        - Rust: `Cargo.toml` with compatible edition/target
     2. **If an override exists**: verify it matches the detected toolchain version (see step 3). If it does, proceed to build. If not, update the override (step 4).
     3. **Detect the actual toolchain version** in the target environment (container or remote):
        - **Java**: `JDK_VER=$(java -version 2>&1 | grep 'version' | head -1 | sed 's/.*"\([0-9]*\).*/\1/')`
        - **C++**: `CC_VER=$($CC --version 2>&1 | head -1)` (detect compiler and version)
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
        - For C++: If the detected compiler does not support required flags (e.g., `-std=c++20`), create a platform-specific Makefile override with compatible flags.
        - For Python: If detected version is below minimum, create a platform-specific Makefile override targeting the available version.
        - For Go/Rust: If detected version is below minimum, create a platform-specific build config override.
     5. **Log**: `[timestamp] Toolchain compatibility check: lang=<lang> detected=<version> required=<config_version> STATUS=OK|MISMATCH override_created=<yes|no>`
     6. **This gate must pass for every language/platform combination** before any build or test command is executed.
     7. **Key principle**: Check for overrides first, create them if missing (with correct version baked in), then proceed on the **first try**. No STOP/re-execute loop needed.

   **0.4 Prompt Lint Check** (all languages):
   - Before or after build verification, run the prompt lint script to ensure all platform/language directories follow conventions:
     ```bash
     ./prompts/common/cpp/utils/bin/lint_prompts.sh <workspace_root>
     ```
   - If the script reports any errors, log them and STOP — this indicates a structural issue with the prompt directory layout.
   - Warnings (e.g., excluded platforms not found) are acceptable and should be logged but do not stop processing.

   **0.1 Java Verification** (from `src/common/java/`):
   - Java is a **common language** — source lives in `src/common/java/` but must be verified on each supported OS.
   - **Determine target OSes to verify**:
     - If a specific OS was requested → only that OS.
     - Otherwise → all supported OSes (macos, debian, fedora, ubuntu, raspios, archlinux, freebsd14) using the routing table.
   - **Routing Decision** (per-OS build path):
     - **macOS**: Native-only — no containers. Run `make all` directly on the host.
     - **Linux distros (fedora, debian, ubuntu, raspios)**: Container-based — use `container` on macOS host or `podman` on Linux host.
     - **FreeBSD 14**: Native-only via SSH remote — use `ssh freebsd-runner`.
     - **Arch Linux**: Native-only via SSH remote — use `ssh archlinux-runner`.
   - For each target OS:
     1. **macOS Build Path** (native):
        ```bash
        cd src/common/java && make all
        # The Makefile runs Maven to compile and package, creates JAR symlink.
        ```
     2. **Linux Container Build Path** (fedora, debian, ubuntu, raspios):
        - The Makefile in `src/common/java/` handles container build and execution automatically.
        ```bash
        cd src/common/java && make all TARGET_OS=<os>
        # The Makefile detects macOS host, uses ringbuffer_<os>_build image,
        # mounts workspace root and per-platform pom.xml override if present,
        # and runs make all inside the target OS container.
        ```
     3. **FreeBSD 14 SSH Build Path**:
        - Pre-flight: `command -v ssh`
        - **Host Requirement:** `<freebsd_host>` must be provided by the user. If not provided, STOP and ask: "Please provide the FreeBSD 14 SSH host (e.g., `<user>@<IP address|FQDN>`)."
        ```bash
        # Clean everything on remote (emulates clean git checkout)
        ssh <freebsd_host> "rm -rf ~/ringbuffer"
        # Create tarball of entire ringbuffer from parent dir (tcsh-compatible: semicolon, not &&)
        tar -czf /tmp/ringbuffer_freebsd14.tar.gz -C .. ringbuffer
        # SCP and unpack on remote at ~/ringbuffer
        scp /tmp/ringbuffer_freebsd14.tar.gz <freebsd_host>:~/
        ssh <freebsd_host> "cd ~ ; tar -xzf ringbuffer_freebsd14.tar.gz"
        # Build Java on remote — FreeBSD 14 uses BSD make override at src/freebsd14/java/
        scp utils/bin/run_freebsd_native_or_ssh.tcsh <freebsd_host>:/tmp/
        ssh <freebsd_host> "tcsh /tmp/run_freebsd_native_or_ssh.tcsh ~/ringbuffer freebsd14 java-build"
        ssh <freebsd_host> "rm -f /tmp/run_freebsd_native_or_ssh.tcsh"
        ```
     4. **Arch Linux SSH Build Path**:
        - Pre-flight: `command -v ssh`
        - **Host Requirement:** `<archlinux_host>` must be provided by the user. If not provided, STOP and ask: "Please provide the Arch Linux SSH host (e.g., `<user>@<IP address|FQDN>`)."
        ```bash
        # Clean everything on remote (emulates clean git checkout)
        ssh <archlinux_host> "rm -rf ~/ringbuffer"
        # Create tarball of entire ringbuffer from parent dir (Arch Linux uses bash, && is safe)
        tar -czf /tmp/ringbuffer_archlinux.tar.gz -C .. ringbuffer
        # SCP and unpack on remote at ~/ringbuffer
        scp /tmp/ringbuffer_archlinux.tar.gz <archlinux_host>:~/
        ssh <archlinux_host> "cd ~ && tar -xzf ringbuffer_archlinux.tar.gz"
        # Build Java on remote (Arch Linux default shell is bash)
        ssh <archlinux_host> "cd ~/ringbuffer/src/common/java && make clean && make all"
        ```
     5. **Post-Build Verification** (all OSes, unified step):
        - Verify the JAR artifact exists: `target/ringbuffer-<version>.jar`
        - Verify the symlink exists: `lib/ringbuffer.jar` → `target/ringbuffer-<version>.jar`
        - Verify JAR is non-empty: `test -s target/ringbuffer-<version>.jar`
     4. **Log**: Append results to `src/common/java/logs/build.log` with the target OS noted: `[timestamp] Java verification on <target_os>: ROUTE=<native|container> STATUS=<PASS/FAIL>`.

   ---

   **0.2 Python Verification** (from `src/common/python/`):
   - Python is a **common language** — source lives in `src/common/python/` but must be verified on each supported OS.
   - **Determine target OSes to verify**:
     - If a specific OS was requested → only that OS.
     - Otherwise → all supported OSes (macos, debian, fedora, ubuntu, raspios, archlinux, freebsd14) using the routing table.
   - **Routing Decision** (per-OS build path):
     - **macOS**: Native-only — no containers. Run `make all` directly on the host.
     - **Linux distros (fedora, debian, ubuntu, raspios)**: Container-based — use `container` on macOS host or `podman` on Linux host.
     - **FreeBSD 14**: Native-only via SSH remote — use `ssh freebsd-runner`.
     - **Arch Linux**: Native-only via SSH remote — use `ssh archlinux-runner`.
   - For each target OS:
     1. **macOS Build Path** (native):
        ```bash
        cd src/macos/cpp && make clean          # Remove stale C++ library
        cd src/common/python && make clean      # Remove stale Python artifacts
        cd src/common/python && make all        # Build C++ lib, create symlinks
        ```
     2. **Linux Container Build Path** (fedora, debian, ubuntu, raspios):
        - The Makefile in `src/common/python/` handles container build and execution automatically.
        ```bash
        cd src/common/python && make all TARGET_OS=<os>
        # The Makefile detects macOS host, uses ringbuffer_<os>_build image,
        # mounts workspace root and common/cpp for symlink resolution,
        # and runs make all inside the target OS container.
        ```
     3. **FreeBSD 14 SSH Build Path**:
        - Pre-flight: `command -v ssh`
        - **Host Requirement:** `<freebsd_host>` must be provided by the user. If not provided, STOP and ask: "Please provide the FreeBSD 14 SSH host (e.g., `<user>@<IP address|FQDN>`)."
        ```bash
        # Clean everything on remote (emulates clean git checkout)
        ssh <freebsd_host> "rm -rf ~/ringbuffer"
        # Create tarball of entire ringbuffer from parent dir (tcsh-compatible: semicolon, not &&)
        tar -czf /tmp/ringbuffer_freebsd14.tar.gz -C .. ringbuffer
        # SCP and unpack on remote at ~/ringbuffer
        scp /tmp/ringbuffer_freebsd14.tar.gz <freebsd_host>:~/
        ssh <freebsd_host> "cd ~ ; tar -xzf ringbuffer_freebsd14.tar.gz"
        # Build Python — FreeBSD 14 uses tcsh script
        scp utils/bin/run_freebsd_native_or_ssh.tcsh <freebsd_host>:/tmp/
        ssh <freebsd_host> "tcsh /tmp/run_freebsd_native_or_ssh.tcsh ~/ringbuffer freebsd14 python-build"
        ssh <freebsd_host> "rm -f /tmp/run_freebsd_native_or_ssh.tcsh"
        ```
     4. **Arch Linux SSH Build Path**:
        - Pre-flight: `command -v ssh`
        - **Host Requirement:** `<archlinux_host>` must be provided by the user. If not provided, STOP and ask: "Please provide the Arch Linux SSH host (e.g., `<user>@<IP address|FQDN>`)."
        ```bash
        # Clean everything on remote (emulates clean git checkout)
        ssh <archlinux_host> "rm -rf ~/ringbuffer"
        # Create tarball of entire ringbuffer from parent dir (Arch Linux uses bash, && is safe)
        tar -czf /tmp/ringbuffer_archlinux.tar.gz -C .. ringbuffer
        # SCP and unpack on remote at ~/ringbuffer
        scp /tmp/ringbuffer_archlinux.tar.gz <archlinux_host>:~/
        ssh <archlinux_host> "cd ~ && tar -xzf ringbuffer_archlinux.tar.gz"
        # Build C++ lib first (Python depends on it), then Python (Arch Linux default shell is bash)
        ssh <archlinux_host> "cd ~/ringbuffer/src/archlinux/cpp && make clean && make all"
        ssh <archlinux_host> "cd ~/ringbuffer/src/common/python && make clean && make all"
        ```
     5. **Post-Build Verification** (all OSes, unified step):
        - Verify the C++ shared library exists in `src/<os>/cpp/lib/`
        - Per-OS binary format check:
          - **macOS**: `file lib/libswtr_ringbuffer.dylib` should show "Mach-O"
          - **Linux/FreeBSD/Arch**: `file lib/libswtr_ringbuffer.so` should show "ELF 64-bit"
        - Verify symlink exists: `lib/libswtr_ringbuffer.so` → versioned library
        - Verify Python import works: `python3 -c "from swtr_ringbuffer import SwtrRingBuffer"`
     6. **Log**: Append results to `src/common/python/logs/build.log` with the target OS noted: `[timestamp] Python verification on <target_os>: ROUTE=<native|container|ssh> STATUS=<PASS/FAIL>`.

   ---

   **0.3 C++ Verification** (from `src/<os>/cpp/`):
   - Navigate to `src/<os>/cpp/`.
   - **Routing Decision** (per-OS build path):
     - **macOS**: Native-only — no containers. Run `make all` directly on the host.
     - **Linux distros (fedora, debian, ubuntu, raspios)**: Container-based — use `container` on macOS host or `podman` on Linux host.
     - **FreeBSD 14**: Native-only via SSH remote — use `ssh freebsd-runner`.
     - **Arch Linux**: Native-only via SSH remote — use `ssh archlinux-runner`.
   - For each target OS:
     1. **macOS Build Path** (native):
        ```bash
        cd src/macos/cpp && make clean          # Remove stale C++ library artifacts
        cd src/macos/cpp && make all            # Build static + shared libraries
        ```
     2. **Linux Container Build Path** (fedora, debian, ubuntu, raspios):
        - The Makefile in `src/<os>/cpp/` handles container build and execution automatically.
        ```bash
        cd src/<os>/cpp && make all
        # The Makefile detects macOS host, builds container image if needed,
        # mounts workspace root at /app/ringbuffer, and runs make all inside the target OS container.
        ```
     3. **FreeBSD 14 SSH Build Path**:
        - Pre-flight: `command -v ssh`
        - **Host Requirement:** `<freebsd_host>` must be provided by the user. If not provided, STOP and ask: "Please provide the FreeBSD 14 SSH host (e.g., `<user>@<IP address|FQDN>`)."
        ```bash
        # Clean everything on remote (emulates clean git checkout)
        ssh <freebsd_host> "rm -rf ~/ringbuffer"
        # Create tarball of entire ringbuffer from parent dir (tcsh-compatible: semicolon, not &&)
        tar -czf /tmp/ringbuffer_freebsd14.tar.gz -C .. ringbuffer
        # SCP and unpack on remote at ~/ringbuffer
        scp /tmp/ringbuffer_freebsd14.tar.gz <freebsd_host>:~/
        ssh <freebsd_host> "cd ~ ; tar -xzf ringbuffer_freebsd14.tar.gz"
        # Build C++ on remote — FreeBSD 14 uses tcsh script
        scp utils/bin/run_freebsd_native_or_ssh.tcsh <freebsd_host>:/tmp/
        ssh <freebsd_host> "tcsh /tmp/run_freebsd_native_or_ssh.tcsh ~/ringbuffer freebsd14 cpp"
        ssh <freebsd_host> "rm -f /tmp/run_freebsd_native_or_ssh.tcsh"
        ```
     4. **Arch Linux SSH Build Path**:
        - Pre-flight: `command -v ssh`
        - **Host Requirement:** `<archlinux_host>` must be provided by the user. If not provided, STOP and ask: "Please provide the Arch Linux SSH host (e.g., `<user>@<IP address|FQDN>`)."
        ```bash
        # Clean everything on remote (emulates clean git checkout)
        ssh <archlinux_host> "rm -rf ~/ringbuffer"
        # Create tarball of entire ringbuffer from parent dir (Arch Linux uses bash, && is safe)
        tar -czf /tmp/ringbuffer_archlinux.tar.gz -C .. ringbuffer
        # SCP and unpack on remote at ~/ringbuffer
        scp /tmp/ringbuffer_archlinux.tar.gz <archlinux_host>:~/
        ssh <archlinux_host> "cd ~ && tar -xzf ringbuffer_archlinux.tar.gz"
        # Build on remote (Arch Linux default shell is bash)
        ssh <archlinux_host> "cd ~/ringbuffer/src/archlinux/cpp && make clean && make all"
        ```
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

   **1. Report Generation**:
   - For C++: Generate a build verification report at `reports/cpp/per_os/<os>_build_verify.md` and JUnit XML at `reports/cpp/per_os/<os>_regression_report_junit.xml` (if applicable) with the following format:
     ```markdown
     # Build Verification Report - [OS Name] <version> — C++
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
   - For Python: Generate a build verification report at `reports/python/per_os/<os>_build_verify.md` with the following format:
     ```markdown
     # Build Verification Report — Python
     **Date:** [YYYY-MM-DD HH:MM:SS +/-HHMM]
     **Host OS:** <host_os>
     **Python Version:** <detected_version>
     **Build Route:** <native|container|ssh>

     ## Build Status
     - **C++ Shared Library**: [PASS/FAIL]
     - **Python Module Build**: [PASS/FAIL]
     - **Symlink Verification**: [PASS/FAIL]
     - **Binary Format Check**: [PASS/FAIL]
     - **Python Import Test**: [PASS/FAIL]

     ## Artifacts
     - `src/<os>/cpp/lib/libswtr_ringbuffer.so` / `.dylib`: <size> bytes
     - `src/common/python/lib/libswtr_ringbuffer.so` → symlink to versioned library
     - `src/common/python/swtr_ringbuffer/`: Python module directory

     ## Notes
     - Any additional notes about the build process (e.g., C++ library not available, container runtime used).
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
       "sha256": {
         "pom_xml": "<hash>",
         "version_mk": "<hash>",
         "Dockerfile_build": "<hash of src/<os>/containers/build/Dockerfile>",
         "Dockerfile_test": "<hash of src/<os>/containers/test/Dockerfile>",
         "generate_junit_report": "<hash of prompts/common/cpp/utils/bin/generate_junit_report.sh>",
         "verify_test_data": "<hash of prompts/common/cpp/utils/bin/verify_test_data.sh>"
       }
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
         "test_ringbuffer_pure_py": "<hash>",
         "Dockerfile_build": "<hash of src/<os>/containers/build/Dockerfile>",
         "Dockerfile_test": "<hash of src/<os>/containers/test/Dockerfile>",
         "generate_junit_report": "<hash of prompts/common/cpp/utils/bin/generate_junit_report.sh>",
         "verify_test_data": "<hash of prompts/common/cpp/utils/bin/verify_test_data.sh>"
       }
     }
     ```
   - Compute SHA-256 hashes of relevant source files for each language.

   **3. Log Finalization**:
   - For each language verified, append a final entry to its respective `build.log` stating that build verification is complete.
   - Calculate and include the total elapsed time since the start timestamp in each final entry.

**Reporting:**
Once verification is complete:
1. Generate the per-OS report at `reports/<lang>/per_os/<os>_build_verify.md` (Java/Python) or `reports/cpp/per_os/<os>_build_verify.md` (C++).
2. Generate JUnit XML at `reports/<lang>/per_os/<os>_regression_report_junit.xml` (Java/Python) or copy from test harness output (C++).
3. Update the consolidated summary at `reports/<lang>/build_verify.md` by merging all per-OS results into a single table.
4. Append to `src/common/<lang>/logs/build.log` with the target OS noted.
5. After all languages complete, run `utils/bin/aggregate_junit.sh` to merge all JUnit XML files into `reports/junit/aggregated.xml` and generate `reports/junit/aggregated.html`.

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions (e.g., `.cpp`, `.hpp`, or `Makefile`), such as `` ErrorOps.cpp`} ``, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.
