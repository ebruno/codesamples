# Build Verification Workflow

**Objective:** 
Verify that all implemented languages build successfully across supported operating systems. This is a build-only workflow — no tests are executed.

**ENTRY POINT — READ FIRST:** All build verification MUST go through `utils/bin/run_build.<zsh|sh>` — never run `make all` directly. The script handles container detection, routing via `config/host_targets.json`, and delegates to the Makefile.

> **FreeBSD hosts only:** On FreeBSD 14, use `utils/bin/run_freebsd_native_or_ssh.tcsh` with the build mode (e.g., `cpp`, `python-build`, `java-build`). This script is tcsh-only and supports native FreeBSD builds only.

> **Note on shell selection:** `run_build.zsh` is used on macOS hosts, `run_build.sh` on Linux hosts. Cross-platform execution (bash on macOS, zsh on Linux) is only allowed for syntax testing (`-n`) or when the user explicitly requests it (see `.bionic` Cross-Platform Script Execution rule).

**STEP 0 — LOAD BUILD WORKFLOW RULES (FIRST ACTION):**
Before executing any step in this document, read and load `rules/verify-build-workflow.md`. This document defines the build verification workflow rules — Pre-Action Checklist, Build vs Test Workflow Pattern, Pre-Flight Check, Standard Clean + Build Process, and Verification Scripts. All execution in this document must comply with those rules.

**Build/Test Pattern (MANDATORY):** Every language follows the same two-step pattern:
- `verify_build` → `utils/bin/run_build.<zsh|sh> <os>` (build only, no tests — delegates to `<os>/<lang>/Makefile all`)
- `run_regression` → `utils/bin/run_regression.<zsh|sh> <os> verify` (test matrix T001-T007)
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

4. **Unsupported OS/Language Documentation.** When an OS/language combination cannot build:
   - Create `src/<os>/<lang>/UNSUPPORTED.md` explaining why
   - Include: detected toolchain version, required minimum version, specific error
   - Update the consolidated report with `UNSUPPORTED` status and link to the reason file

**Process:**
1. **Target Selection & Host-OS Routing**:
   - **Host-OS Auto-Detection**: At the start of every run, detect the host OS:
     - If `uname -s` returns `Darwin`, set `host_os = macOS`.
     - If it returns `Linux`, read the distro ID from `/etc/os-release`: `host_os=$(grep '^ID=' /etc/os-release | cut -d= -f2)`.
     - Supported Linux distros: `ubuntu`, `debian`, `fedora`, `raspios`, `archlinux`.
   - **Targeting**:
     - **Specified Platform + Language**: If the user specifies a language and platform (e.g., "verify_build for java on fedora"), verify only that language on that OS. Use the routing table to determine how.
     - **Specified Platform Only**: If the user specifies a platform but no language (e.g., "verify_build for debian"), verify all implemented languages on that OS. Use the routing table to determine how.
     - **Specified Language Only**: If the user specifies a language but no platform (e.g., "verify_build for java"), verify that language on all supported OSes using the routing table.
     - **General Request (no platform, no language)**: Verify all implemented languages on all supported OSes using the routing table.
   - **Routing Decision**: The `run_build.<zsh|sh>` script reads `config/host_targets.json` — this is the single source of truth for routing. The script looks up the entry for the current `host_os` and finds the target OS's transport method:
     - `native` → run directly on the host (no container, no SSH)
     - `container` → use the appropriate container runtime (`container` on macOS, `podman` on Linux)
     - `ssh` → use SSH to the remote host (resolved from `config/ssh_hosts.json`)
     - `skip` → do not verify this target (log and skip)
   - **Container Runtime Selection**:
     - macOS host → use `container` command (Apple Container)
     - Linux host → use `podman`
   - **macOS is native-only**: macOS builds and tests NEVER use containers, regardless of host OS.
   - **FreeBSD is native-only**: FreeBSD builds and tests NEVER use containers, regardless of host OS.

2. **Language Dispatch**:
   After target selection, determine which language(s) to process and dispatch accordingly:

   **Common Languages (Java, Python)** — source lives in `src/common/<lang>/`, identical across all OSes:
   - For each target OS, delegate to `run_build.<zsh|sh> -L <lang> <os>`.
   - Each common language manages its own `.gen_state.json` in `src/common/<lang>/`.

   **C++** — source lives in `src/<os>/cpp/`, per-OS implementation:
   - Proceed to C++ Build Verification section below.

---

### C++ Build Verification

   0. **Environment Setup**:
      - **Timeout Configuration**: All timeout values are defined as variables for easy adjustment:
        - `CONTAINER_BUILD_TIMEOUT_MS`: 600,000 ms (10 minutes) — maximum time for `make container`
        - `LIBRARY_BUILD_TIMEOUT_MS`: 600,000 ms (10 minutes) — maximum time for `make clean && make all`
      - **Resolve Image**: Determine the target container image. If not provided by the user, derive it from the OS (e.g., `fedora:44`, `debian:13`, `ubuntu:24.04`). If the target is `macos`, log: `IMAGE=N/A (native-only platform)`. Otherwise, log: `IMAGE=<resolved_image>`.
      - **Shared Version Context**: Read the version from `src/<os>/cpp/.gen_state.json` (if it exists). If `.gen_state.json` does not exist, read `src/<os>/cpp/version.mk` as a fallback. Log: `VERSION=<resolved_version>`.
      - **Execution Path Decision**: Detect the host OS. If `uname -s` returns `Darwin`, set `host_os = macOS`. If it returns `Linux`, read the distro ID from `/etc/os-release` using: `host_os=$(grep '^ID=' /etc/os-release | cut -d= -f2)`.
        - **macOS Host Detection**: When `uname -s` returns `Darwin`, the host OS is macOS. Use `sw_vers --productVersion` to get the actual macOS version (e.g., "26.5.2").
        - **Apple Container Runtime**: macOS uses the `container` command (Apple Container), NOT Docker or podman.
        - **Service Management**: The `container` daemon does NOT start automatically on macOS. This workflow includes an automatic service check and start step before any container operations.
        - **Native Execution**: If `host_os == <os>` OR if the target `<os>` is `macos`, all build and verification steps MUST be performed natively on the host. Containers MUST NOT be used for macOS targets.
        - **Container Execution**: If `host_os != <os>` AND the target `<os>` is NOT `macos`, all build and verification steps MUST be performed inside the `ringbuffer_<os>_build` container.
        - **Log Your Decision**: Print a one-line summary to stdout and append it to `build.log`.
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
        - Store this as `<memory_limit>` for use in container run commands.
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

          After installation, ensure the 'podman' command is available in your PATH and re-run the build workflow.
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

          After resolving the issue, re-run the build workflow.
          ```
      - **Navigate**: `cd src/<os>/cpp`
      - **Dockerfile/Image Validation (Linux targets only)**: If the target `<os>` is NOT `macos`:
        - **Validate Existing Dockerfile**: If the build Dockerfile exists at `src/<os>/containers/build/Dockerfile`, verify that the resolved Target Image matches its `FROM` base image tag. If it does not match, log an error and stop processing.
        - **Build Build Image**: Before building, ensure the `ringbuffer_<os>_build` image is present. Check if it already exists using `<runtime> images | grep ringbuffer_<os>_build`. If not found, execute `make container` from the source directory.
      - If the target IS `macos`, log: `[timestamp] Dockerfile/Image validation skipped — macOS is native-only.` and proceed.
      - **Infrastructure Pre-flight**: Verify that the source directory contains all required artifacts:
        - `Makefile` — must exist with targets `all`, `static`, `dynamic`, `clean`, `dist-clean`, `container`.
        - `version.mk` — must exist.
        - Source files (`*.cpp`, `*.hpp`) — must exist.
        - If any required artifact is missing, STOP and report: `[timestamp] Infrastructure incomplete — <missing artifact> not found.`
      - **Log Initialization**: If `logs/build.log` does not exist, create it with the start timestamp and routing decision.

      > **Routing Confirmation**: The transport (native/container/ssh) for this host→target pair is determined by `config/host_targets.json`. The `run_build.<zsh|sh>` script handles it internally — do NOT manually follow the SSH paths below. Delegate all execution to the script.
      > **Explicit routing**: When host=macos and target=archlinux, transport is `ssh` (not container) because archlinux is Linux-hosts-only from macOS hosts. When host=macos and target=freebsd14, transport is `ssh`. When host=macos and target=fedora/debian/ubuntu/raspios, transport is `container`.
      > **Note:** Steps below (FreeBSD/Arch SSH paths) are reference documentation for SSH transport. The script handles SSH routing internally — delegate to the script rather than executing these inline commands manually.

      - **FreeBSD 14 SSH Build Path** (reference only — delegate to script):
        ```bash
        ssh <freebsd_host> "rm -rf ~/ringbuffer"
        tar -czf /tmp/ringbuffer_freebsd14.tar.gz -C .. ringbuffer
        scp /tmp/ringbuffer_freebsd14.tar.gz <freebsd_host>:~/
        ssh <freebsd_host> "cd ~ ; tar -xzf ringbuffer_freebsd14.tar.gz"
        ssh <freebsd_host> "tcsh ~/ringbuffer/utils/bin/run_freebsd_native_or_ssh.tcsh ~/ringbuffer freebsd14 cpp"
        ```

      - **Arch Linux SSH Build Path** (reference only — delegate to script):
        ```bash
        ssh <archlinux_host> "rm -rf ~/ringbuffer"
        tar -czf /tmp/ringbuffer_archlinux.tar.gz -C .. ringbuffer
        scp /tmp/ringbuffer_archlinux.tar.gz <archlinux_host>:~/
        ssh <archlinux_host> "cd ~ && tar -xzf ringbuffer_archlinux.tar.gz"
        ssh <archlinux_host> "cd ~/ringbuffer/src/archlinux/cpp && make clean && make all"
        ```

   1. **Cross-Platform Source Verification**:
      - If the target `<os>` is `macos`, skip cross-platform verification and log: `[timestamp] Cross-platform verification skipped — macOS is native-only with different binary format (Mach-O).` Proceed to Step 2.
      - If the target `<os>` is NOT `macos`, verify source file symmetry across Linux platforms:
        - Run the binary symmetry verification script:
          ```bash
          ./prompts/common/cpp/utils/bin/verify_binary_symmetry.sh <workspace_root>
          ```
        - If the script reports any differences, log them and STOP — this indicates a violation of the binary symmetry requirement.
        - If all files are identical, log: `[timestamp] Binary symmetry verification passed — all Linux platforms produce byte-identical source.`

   2. **Build Execution**:
      - **Timeout Limit**: Maximum of 600,000 ms (10 minutes) for the build step.
      - **Execute**:
        ```bash
        ./utils/bin/run_build.<zsh|sh> -L cpp <os>     # Build C++ library via script (zsh on macOS hosts, sh on Linux hosts)
        ```
      - **Verify Artifacts**:
        - Confirm that `lib/libswtr_ringbuffer.a` (static) exists.
        - Confirm that `lib/libswtr_ringbuffer.so` / `.dylib` (shared) exists.
        - Verify binary format:
          - **Linux**: `file lib/libswtr_ringbuffer.so` should show "ELF 64-bit"
          - **macOS**: `file lib/libswtr_ringbuffer.dylib` should show "Mach-O"
        - Verify symbol visibility:
          - **Linux**: `nm -gjU lib/libswtr_ringbuffer.so` should show only exported symbols
          - **macOS**: `nm -gU lib/libswtr_ringbuffer.dylib` should show only exported symbols
        - Verify binary size: Check that the library is within expected size range (typically < 100KB).
      - **Evaluate**: If any step fails, follow the Build Failure Procedure below.

         **Build Failure Procedure:**
         1. Capture the full error output (compiler errors, linker errors).
         2. Analyze the logs to determine the root cause.
         3. Do NOT attempt fixes — record the error and mark as UNSUPPORTED if appropriate.
         4. If the failure is transient (e.g., container image pull timeout), retry the entire build pipeline at most **1 time**.
         5. If the retry also fails, STOP immediately. Report the error with diagnostic output.

   3. **Per-Platform Cleanup**: Before generating reports, remove only this platform's existing report files to avoid stale data:
      ```bash
      rm -f reports/cpp/per_os/<os>_build_verify.md
      ```
      Do NOT delete other OS reports or the entire `reports/` directory.

   4. **Report Generation**:
      - Generate the build verification report at `reports/cpp/per_os/<os>_build_verify.md` using the following format:

        ```markdown
        # Build Verification Report - [Full Platform Name] (use the full platform name, e.g., 'Fedora 44', 'Debian 13', 'Ubuntu 24.04 LTS')
        **Date:** [YYYY-MM-DD HH:MM:SS ±HHMM]
        **Start Time:** [YYYY-MM-DD HH:MM:SS ±HHMM]
        **End Time:** [YYYY-MM-DD HH:MM:SS ±HHMM]
        **Elapsed Time:** [Duration]
        **Host OS:** [Host OS Name/Version]

        ## Status
        **Final Result:** [PASS / FAIL]

        ## Audit Trail
        - **Compiler**: [Version output from g++ -v or clang++ -v]
        - **Linker**: [Version output from ld -v or lld -v]

        ## Artifacts
        - `lib/libswtr_ringbuffer.a`: [size] bytes
        - `lib/libswtr_ringbuffer.so` / `.dylib`: [size] bytes

        ## Verification Details
        - **Compilation**: [Success/Failure]
        - **Static Library**: [Success/Failure]
        - **Shared Library**: [Success/Failure]
        - **Binary Format**: [PASS/FAIL]
        - **Symbol Visibility**: [PASS/FAIL]

        ## Fixes and Modifications
        *If files were modified to achieve a successful build, list them here:*
        - `path/to/file`: [Brief explanation]
        ```

   5. **State Tracking**:
      - Create or update `.gen_state.json` in `src/<os>/cpp/` containing:
        - The resolved version (from shared context or `version.mk`).
        - The resolved image (`N/A` for macOS native-only platforms).
        - Build status (route, status, timestamp).
        - SHA-256 hashes of source files, `Makefile`, `version.mk`.
      - **Version Change Detection**: Before updating `.gen_state.json`, compare the current `version.mk` values against those stored in `.gen_state.json`. If any value has changed, regenerate all versioned artifact names and symlinks in the `lib/` directory before proceeding.
      - If no existing `.gen_state.json`, create a new one:
        ```json
        {
          "language": "cpp",
          "version": "<MAJOR.MINOR.SUBVERSION-BUILD_ID from version.mk>",
          "compiler": "<detected compiler version>",
          "image": "<resolved container image or N/A>",
          "build_status": {
            "route": "native|container|ssh",
            "status": "PASS|FAIL",
            "timestamp": "<ISO timestamp>"
          },
          "artifacts": {
            "static_lib": "lib/libswtr_ringbuffer.a",
            "shared_lib": "lib/libswtr_ringbuffer.so"
          },
          "sha256": {
            "Makefile": "<hash>",
            "version_mk": "<hash>",
            "Dockerfile_build": "<hash of src/<os>/containers/build/Dockerfile>",
            "verify_binary_symmetry": "<hash of prompts/common/cpp/utils/bin/verify_binary_symmetry.sh>",
            "lint_prompts": "<hash of prompts/common/cpp/utils/bin/lint_prompts.sh>"
          }
        }
        ```
      - Compute SHA-256 hashes of `Makefile`, `version.mk`, Dockerfiles, and utility scripts.

   6. **Final Self-Audit**:
      - Verify the following and log results:
        - **Makefile Targets**: All required targets are present (`all`, `static`, `dynamic`, `clean`, `dist-clean`, `container`).
        - **Library Artifacts**: Both static and shared libraries exist in `lib/`.
        - **Binary Format**: Correct format for the target platform (ELF/Mach-O).
        - **Symbol Visibility**: Only exported symbols visible.
        - **Reports**: `reports/cpp/per_os/<os>_build_verify.md` exists.
        - **State File**: `.gen_state.json` was created/updated.

   7. **Finalize Logs**:
      - Append a final entry to `build.log` stating that build verification is complete.
      - Calculate and include the total elapsed time since the start timestamp in this final entry.

---

**Error Handling Discipline** (applies to ALL languages and platforms):
- When `verify_build` or `run_regression` encounters an error for a specific language/os combination:
  1. **STOP** processing that language/os immediately — do NOT attempt to fix the error.
  2. **Record** the full error details (command run, output, exit code) in that language/os's individual report file.
  3. **Move on** to the next language/os in the list — do not let one failure block verification of other platforms.
  4. **Do NOT make any changes** to source files, build configs, or platform overrides unless the user has explicitly granted permission.
- This prevents agents from silently fixing issues during verification runs, which masks real problems and makes unauthorized changes.
- The agent's role is to **detect and report**, not to **fix and continue**.

**Error Reporting Structure** (at the end of all processing):
- After all language/os combinations have been processed, generate a final summary section with:
  1. **Overall Status**: Count of passed vs failed language/os pairs.
  2. **TODO List**: A numbered list of all lang/os pairs that encountered errors, with:
     - Platform and language (e.g., `1. Java on Raspberry Pi OS`)
     - Brief error description (e.g., `JDK 17 does not support <release>25</release>`)
     - Location of detailed error in individual report (e.g., `See src/raspios/java/reports/verify_report.md`)
  3. **Full Error Details**: For each failed lang/os pair, include the complete error output in a clearly delimited section.

**CRITICAL — DO NOT CONFUSE:**
- `verify_build` → **always** uses `utils/bin/run_build.<zsh|sh> <os>` (build only, no tests)
- `run_regression` → **always** uses `utils/bin/run_regression.<zsh|sh> <os> verify` (build + T001-T007)
- If you find yourself about to run `make verify` during `verify_build`, STOP — that is wrong.
- If you find yourself about to run `make all` directly (bypassing the script) during `verify_build`, STOP — delegate to the script.

**SELF-CHECK BEFORE EXECUTING:**
- Am I in `verify_build`? → Must use `run_build.<zsh|sh>`, NOT `make verify` and NOT raw `make all`
- Am I in `run_regression`? → Must use `run_regression.<zsh|sh>`, NOT raw `make verify`
- If unsure, re-read the workflow header to confirm which mode you are in.

**Standard Clean + Build Process (When C++ Is Used)**
- For any language that depends on the C++ shared library (Python, and future languages with C bindings), the script handles the clean + build sequence automatically:
  1. **`make clean`** in `<os>/cpp/` — removes stale C++ library artifacts
  2. **`make clean`** in `<os>/<lang>/` (or `src/common/<lang>/`) — removes stale language-specific build artifacts
  3. **`make all`** in `<os>/<lang>/` (or `src/common/<lang>/`) — builds C++ library, creates symlinks
- **Why this matters:** If the C++ library was previously built for a different platform (e.g., ELF ARM64 inside a container), stale artifacts on the host will cause linker errors.
- **Example — Python on Fedora (from macOS host):**
  ```bash
  ./utils/bin/run_build.<zsh|sh> -L python fedora  # Script handles all cleanup (zsh on macOS hosts, sh on Linux hosts)
  ```

> **Note:** When using `run_build.<zsh|sh>` (not raw `make all`), the script handles all cleanup internally — including C++ library clean for dependent languages. Do not run manual `make clean` steps before invoking the script; doing so is redundant.

**Universal Toolchain Compatibility Gate** (applies to ALL languages — runs BEFORE any build attempt):
- This is a **blocking gate** for every language and platform — the build cannot proceed until toolchain versions match.
- For each target OS, BEFORE executing any language-specific build:
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
  4. **If no override exists, or the existing one does not match**: create a platform-specific override with the correct version baked in.
  5. **Log**: `[timestamp] Toolchain compatibility check: lang=<lang> detected=<version> required=<config_version> STATUS=OK|MISMATCH override_created=<yes|no>`
  6. **This gate must pass for every language/platform combination** before any build command is executed.

**0.4 Prompt Lint Check** (all languages):
- Before or after build verification, run the prompt lint script to ensure all platform/language directories follow conventions:
  ```bash
  ./prompts/common/cpp/utils/bin/lint_prompts.sh <workspace_root>
  ```
- If the script reports any errors, log them and STOP — this indicates a structural issue with the prompt directory layout.
- Warnings (e.g., excluded platforms not found) are acceptable and should be logged but do not stop processing.

**Java Build Verification** (from `src/common/java/`):
- Java is a **common language** — source lives in `src/common/java/` but must be verified on each supported OS.
- **Determine target OSes to verify**:
  - If a specific OS was requested → only that OS.
  - Otherwise → all supported OSes (macos, debian, fedora, ubuntu, raspios, archlinux, freebsd14) using the routing table.
- For each target OS:
  > **Routing Confirmation**: The transport (native/container/ssh) for this host→target pair is determined by `config/host_targets.json`. The script handles it internally — do NOT manually run container or SSH commands. Delegate all execution to `run_build.<zsh|sh>`.

  1. **Execute Build**:
     ```bash
     ./utils/bin/run_build.<zsh|sh> -L java <os>   # Build Java via script (zsh on macOS hosts, sh on Linux hosts)
     ```

     > **Note:** The script handles all cleanup internally. Do not run manual `make clean` steps before invoking the script.

  2. **Post-Build Verification** (all OSes, unified step):
     - Verify the JAR artifact exists: `target/ringbuffer-<version>.jar`
     - Verify the symlink exists: `lib/ringbuffer.jar` → `target/ringbuffer-<version>.jar`
     - Verify JAR is non-empty: `test -s target/ringbuffer-<version>.jar`

  3. **Log**: Append results to `src/common/java/logs/build.log` with the target OS noted: `[timestamp] Java verification on <target_os>: ROUTE=<native|container|ssh> STATUS=<PASS/FAIL>`.

  **Java State Tracking** (after all target OSes complete):
  - Read existing `.gen_state.json` from `src/common/java/` if it exists. Preserve all existing fields.
  - Update/merge the following fields:
    - `build_status`: Add or update entries for each target OS with build results (route, status, timestamp).
    - Recompute SHA-256 hashes of `pom.xml` and `version.mk`.
  - If no existing `.gen_state.json`, create a new one with the full structure:
    ```json
    {
      "language": "java",
      "version": "<MAJOR.MINOR.SUBVERSION-BUILD_ID from version.mk>",
      "java_version": "<detected JDK version, e.g., 25.0.3>",
      "maven_version": "<detected Maven version, e.g., 3.9.16>",
      "build_status": {
        "<os>": {
          "route": "native|container|ssh",
          "status": "PASS|FAIL",
          "timestamp": "<ISO timestamp>"
        }
      },
      "artifacts": {
        "jar": "target/ringbuffer-<version>.jar"
      },
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

  - **Per-Platform Cleanup**: Before generating reports, remove only this platform's existing report files:
    ```bash
    rm -f reports/java/per_os/<os>_build_verify.md
    ```

  **Java Report Generation** (after all target OSes complete):
  - Generate the build verification report at `reports/java/per_os/<os>_build_verify.md` using the following format:

    ```markdown
    # Build Verification Report — Java
    **Date:** [YYYY-MM-DD HH:MM:SS ±HHMM]
    **Start Time:** [YYYY-MM-DD HH:MM:SS ±HHMM]
    **End Time:** [YYYY-MM-DD HH:MM:SS ±HHMM]
    **Elapsed Time:** [Duration]
    **Host OS:** [Host OS Name/Version]

    ## Status
    **Final Result:** [PASS / FAIL]

    ## Audit Trail
    - **JDK**: [Version output from `java --version`]
    - **Maven**: [Version output from `mvn --version`]

    ## Per-OS Results
    | Target OS | Route | Image/Version | Status | Notes |
    |-----------|-------|---------------|--------|-------|
    | macos | native | JDK <ver> | [PASS/FAIL] | [Brief note] |
    | debian | container (debian:13) | JDK <ver> | [PASS/FAIL] | [Brief note] |
    | fedora | container (fedora:44) | JDK <ver> | [PASS/FAIL] | [Brief note] |
    | ubuntu | container (ubuntu:24.04) | JDK <ver> | [PASS/FAIL] | [Brief note] |

    ## Artifacts
    - `target/ringbuffer-<version>.jar`: [size] bytes

    ## Fixes and Modifications
    *If files were modified to achieve a successful build, list them here:*
    - `path/to/file`: [Brief explanation]

    ## Verification Details
    - **Maven Compile**: [Success/Failure]
    - **Maven Package**: [Success/Failure]
    - **JAR Artifact**: [Present/Absent]
    - **Symlink**: [Present/Absent]
    ```

  **Java Self-Audit** (after report generation):
  - Verify the following and log results:
    - **JAR Artifact**: `target/ringbuffer-*.jar` exists and is non-empty.
    - **Symlink**: `lib/ringbuffer.jar` → `target/ringbuffer-<version>.jar` exists.
    - **Reports Generated**: `reports/java/per_os/<os>_build_verify.md` exists.
    - **State File**: `src/common/java/.gen_state.json` was created/updated.

---

**Python Build Verification** (common source + platform-specific Makefile):
- Python is a **common language** — source lives in `src/common/python/` but must be verified on each supported OS.
- **Makefile Selection**:
  - GNU make systems (macOS, Linux): Use `src/common/python/Makefile.gnu`
  - BSD make systems (FreeBSD 14+): Use `src/<os>/python/Makefile` (per-OS directory with BSD-compatible Makefile)
- **Determine target OSes to verify**:
  - If a specific OS was requested → only that OS.
  - Otherwise → all supported OSes (macos, debian, fedora, ubuntu, raspios, archlinux, freebsd14) using the routing table.
- For each target OS:
  > **Routing Confirmation**: The transport (native/container/ssh) for this host→target pair is determined by `config/host_targets.json`. The script handles it internally — do NOT manually run container or SSH commands. Delegate all execution to `run_build.<zsh|sh>`.

  1. **Execute Build**:
     ```bash
     ./utils/bin/run_build.<zsh|sh> -L python <os>   # Build Python via script (zsh on macOS hosts, sh on Linux hosts)
     ```

     > **Note:** The script handles all cleanup internally — including C++ library build for Python. Do not run manual `make clean` steps before invoking the script.

  2. **Post-Build Verification** (all OSes, unified step):
     - Verify the C++ shared library exists in `src/<os>/cpp/lib/`
     - Per-OS binary format check:
       - **macOS**: `file lib/libswtr_ringbuffer.dylib` should show "Mach-O"
       - **Linux/FreeBSD/Arch**: `file lib/libswtr_ringbuffer.so` should show "ELF 64-bit"
     - Verify symlink exists: `lib/libswtr_ringbuffer.so` → versioned library
     - Verify Python import works: `python3 -c "from swtr_ringbuffer import SwtrRingBuffer"`

  3. **Log**: Append results to `src/common/python/logs/build.log` with the target OS noted: `[timestamp] Python verification on <target_os>: ROUTE=<native|container|ssh> STATUS=<PASS/FAIL>`.

  **Python State Tracking** (after all target OSes complete):
  - Read existing `.gen_state.json` from `src/common/python/` if it exists. Preserve all existing fields.
  - Update/merge the following fields:
    - `build_status`: Add or update entries for each target OS with build results (route, python_version, status, timestamp).
    - Recompute SHA-256 hashes of `version.mk` and relevant source files.
  - If no existing `.gen_state.json`, create a new one with the full structure:
    ```json
    {
      "language": "python",
      "version": "<MAJOR.MINOR.SUBVERSION-BUILD_ID from version.mk>",
      "python_version": "<detected Python version, e.g., 3.14.6>",
      "build_status": {
        "<os>": {
          "route": "native|container|ssh",
          "python_version": "<detected Python version in that context>",
          "status": "PASS|FAIL",
          "timestamp": "<ISO timestamp>"
        }
      },
      "artifacts": {
        "concurrent_module": "swtr_ringbuffer/swtr_ringbuffer_concurrent.py",
        "pure_python_module": "swtr_ringbuffer_pure.py"
      },
      "sha256": {
        "version_mk": "<hash>",
        "base_py": "<hash>",
        "swtr_ringbuffer_concurrent_py": "<hash>",
        "swtr_ringbuffer_pure_py": "<hash>",
        "Dockerfile_build": "<hash of src/<os>/containers/build/Dockerfile>",
        "Dockerfile_test": "<hash of src/<os>/containers/test/Dockerfile>",
        "generate_junit_report": "<hash of prompts/common/cpp/utils/bin/generate_junit_report.sh>",
        "verify_test_data": "<hash of prompts/common/cpp/utils/bin/verify_test_data.sh>"
      }
    }
    ```

  - **Per-Platform Cleanup**: Before generating reports, remove only this platform's existing report files:
    ```bash
    rm -f reports/python/per_os/<os>_build_verify.md
    ```

  **Python Report Generation** (after all target OSes complete):
  - Generate the build verification report at `reports/python/per_os/<os>_build_verify.md` using the following format:

    ```markdown
    # Build Verification Report — Python
    **Date:** [YYYY-MM-DD HH:MM:SS ±HHMM]
    **Start Time:** [YYYY-MM-DD HH:MM:SS ±HHMM]
    **End Time:** [YYYY-MM-DD HH:MM:SS ±HHMM]
    **Elapsed Time:** [Duration]
    **Host OS:** [Host OS Name/Version]
    **Python Version:** [detected_version]
    **Build Route:** [native|container|ssh]

    ## Status
    **Final Result:** [PASS / FAIL]

    ## Audit Trail
    - **Python**: [Version output from `python3 --version`]

    ## Per-OS Results
    | Target OS | Route | Python Version | Status | Notes |
    |-----------|-------|---------------|--------|-------|
    | macos | native | 3.14.x | [PASS/FAIL] | [Brief note] |
    | fedora | container | 3.x.x | [PASS/FAIL] | [Brief note] |
    | debian | container | 3.x.x | [PASS/FAIL] | [Brief note] |
    | ubuntu | container | 3.x.x | [PASS/FAIL] | [Brief note] |
    | archlinux | native | 3.x.x | [PASS/FAIL] | Linux-hosts-only |
    | raspios | container | 3.x.x | [PASS/FAIL] | [Brief note] |
    | freebsd14 | native | 3.11.x | [PASS/FAIL] | [Brief note] |

    ## Artifacts
    - `src/<os>/cpp/lib/libswtr_ringbuffer.so` / `.dylib`: [size] bytes
    - `src/common/python/lib/libswtr_ringbuffer.so` → symlink
    - `src/common/python/swtr_ringbuffer/`: Python module directory

    ## Fixes and Modifications
    *If files were modified to achieve a successful build, list them here:*
    - `path/to/file`: [Brief explanation]

    ## Verification Details
    - **C++ Shared Library**: [Success/Failure]
    - **Python Module Build**: [Success/Failure]
    - **Symlink Verification**: [Success/Failure]
    - **Binary Format Check**: [PASS/FAIL]
    - **Python Import Test**: [PASS/FAIL]
    ```

  **Python Self-Audit** (after report generation):
  - Verify the following and log results:
    - **Concurrent Module**: `swtr_ringbuffer/swtr_ringbuffer_concurrent.py` exists and is non-empty.
    - **Pure Python Module**: `swtr_ringbuffer_pure.py` exists and is non-empty.
    - **C++ Shared Library**: Present in the correct platform directory.
    - **Symlink**: `lib/libswtr_ringbuffer.so` → versioned library exists.
    - **Reports Generated**: `reports/python/per_os/<os>_build_verify.md` exists.
    - **State File**: `src/common/python/.gen_state.json` was created/updated.

**Report Generation and Aggregation** (runs automatically at end of each `verify_build`):
- **Per-OS report:** `populate_build_reports()` writes `reports/<lang>/per_os/<os>_build_verify.md` with build status (PASS/FAIL/UNSUPPORTED)
- **Status detection:** `run_native`/`run_container` capture `make all` output — if it contains "unsupported", `BUILD_STATUS` is set to `UNSUPPORTED`. Non-zero exit sets FAIL. Otherwise PASS.
- **Aggregate summary:** `utils/bin/aggregate_verify_build.{zsh,sh}` auto-runs to produce `reports/build_verify_summary.md` with Overview table (PASS/FAIL/UNSUPPORTED counts) and Per-OS Results table (one row per OS, `<br>`-separated languages)
- **Aggregate JUnit:** Not applicable to `verify_build` (no tests run) — JUnit aggregation is handled by `run_regression`

**Excluded Platforms:**
- **C++**: FreeBSD 14 is supported (clang++/g++ available). FreeBSD 15 is excluded — zero-length files only.
- **C**: Not yet implemented — common specs exist (`prompts/common/c/`) but no source generation or build verification.
- **Python/Java**: FreeBSD 14 Python is verified and active — build verification IS executed for common languages on FreeBSD 14.
- **ArchLinux**: Native tooling supported (g++/clang++). Linux-hosts-only for container-based verification from macOS hosts.
- Do not modify, add content to, or create new files in `prompts/freebsd14/`, `prompts/freebsd15/`, or `prompts/archlinux/` for C++.
- For C++: The only files that should exist in these directories are zero-length `build.md`, `functional.md`, and `testing.md` files. If these directories contain any non-zero C++ prompt files, remove them.

**Tooling and Recovery:**
- **Invalid Filenames**: If you encounter files or directories with trailing characters after valid extensions, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors**: If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.

## Scope Boundary — Build Only

The purpose of this prompt is to **verify builds** across supported platforms. It assumes all source code and build configuration was created by `prompts/common/implement_build.md`.

You MUST NOT:
- Run tests (test matrix T001–T007).
- Modify source code files.
- Generate new build artifacts beyond those produced by `make all`.
- Proceed to regression testing or performance benchmarking.

**Directory Scope Restriction:**
- **NEVER create, modify, or delete any files outside the `<os>/<lang>/` source directory** (except for `build.log`, `.gen_state.json`, and report files).
- For **common languages** (Java, Python): `.gen_state.json` and reports are managed in `src/common/<lang>/`.
- The `tests/` directory is managed exclusively by the regression test workflow — do NOT touch it.
