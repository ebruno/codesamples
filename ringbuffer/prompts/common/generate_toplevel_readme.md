# README Generation Workflow

**Objective:** 
Generate a comprehensive `README.md` for the Ringbuffer project that serves as a high-level overview for users and a strict technical manual for developers and maintainers.

**Process:**
1. **Information Gathering**:
   - **Environment**: Detect the current host OS, kernel version, architecture, and hardware specifications. For macOS, use `sw_vers` to retrieve the `ProductName`, `ProductVersion`, and `BuildVersion`.
   - **AI Tooling**: Identify the current LLM and agent harness being used (e.g., LM Studio Bionic). If `lms` is in the system path, execute `lms ps` to determine the active model. Extract the value from the **MODEL** column and use it as the **Model Name**.
   - **Platform Matrix**: Scan `src/` and `prompts/` to determine which OS and Language combinations are implemented. For each language (c, cpp, go, java, python, rust), check for the existence of `src/<os>/<lang>/version.mk` (C/C++ per-OS) or `src/common/<lang>/` markers (Java, Python — platform-insensitive). For Go and Rust, check `src/<os>/<lang>/version.mk` or equivalent build artifacts.
    - If `version.mk` exists: Read `MAJOR`, `MINOR`, and `SUBVERSION`.
        - If `MAJOR > 0`: Use `vMAJOR.MINOR.SUBVERSION`.
        - If `MAJOR == 0`: Use `WIP vMAJOR.MINOR.SUBVERSION`.
    - If `version.mk` does not exist: Use `WIP` or `TBS` based on project progress.
   - **Language Classification**: Classify each language as platform-sensitive (c, cpp — source differs across platforms) or platform-insensitive (java, python, go, rust — identical source everywhere). Platform-sensitive languages have per-OS directories (`src/<os>/cpp/`); platform-insensitive languages use `src/common/<lang>/` (java, python) or per-OS directories with identical content (go, rust). FreeBSD 14 and FreeBSD 15 are separate OS directories (`freebsd14/`, `freebsd15/`), not a single `freebsd/` directory.
   - **Project Status**: Scan `src/` to determine which platforms have complete implementations (version.mk exists). Check for `.gen_state.json` files in each platform directory to verify state tracking is operational. Run `verify_binary_symmetry.sh <workspace_root>` and capture exit code (0 = verified, 1 = failed). Run `lint_prompts.sh <workspace_root>` and capture exit code (0 = passed, 1 = failed). Use these results to populate the "What Works Today" auto-generated table in the README.

2. **Content Structure**:
   The README MUST follow this exact section order, matching the actual README.md structure:

   1. **Title & Introduction** — `# Ringbuffer` with one-sentence value proposition
   2. **## What It Does** — Three-stage pipelined architecture (Read → Transform → Write) in plain English. How each thread fills, transforms, writes slots through shared slot state machines with independent atomic index counters. `std::jthread` cooperative cancellation and `wait()` blocking behavior
   3. **## Overview** — Three-stage pipeline (**Read $
ightarrow$ Transform $
ightarrow$ Write**) and binary symmetry focus. Platform classification:
      - **Platform-Sensitive Languages (C, C++)**: Byte-identical within same OS family; cross-family differences limited to `#ifdef` guards
      - **Platform-Insensitive Languages (Java, Python, Go, Rust)**: Byte-identical across ALL platforms
   4. **## Primary Goal** — Prompt-driven, immediate build-and-run functionality. **Develop-then-refactor** strategy with three phases:
      - Phase A — Platform Development (2–3 representative platforms)
      - Phase B — Common Refactor (`src/common/<lang>/`)
      - Phase C — Platform Rollout (remaining platforms from common spec + per-OS overrides)
      - Current status note: C++ in Phase A; Java/Python in Phase B; C/Go/Rust pre-Phase A
   5. **## Prompt Execution Pattern** — Four-step pattern: common workflow → platform-specific primary document (`create_*.md`) → common spec → platform spec
   6. **## Development Methodology** — LLM-created from scratch. Interactive prompt generation, binary symmetry as deliberate instruction, incremental refinement, **prompt versioning** via `.gen_state.json` SHA-256 hashes with changelog tracking (`prompts/common/CHANGELOG.md`). Post-commit hook (`githooks/post-commit` + `utils/bin/suggest_changelog_entry.sh`) analyzes prompt diffs.
   7. **## Key Specifications** — Multi-OS support (macOS, Fedora, Debian, Ubuntu, Raspberry Pi OS, Arch Linux, FreeBSD 14), Multi-Language support (C++, Java, Python implemented; C, Go, Rust in pipeline). **Language Standards and Classification**: version requirements per language (C23/C17, C++20/C++17, Java SE 25/SE 24-17, Go 1.24/1.23, Python 3.14/3.13-3.10, Rust 1.84.0/1.56.0). **Language-Specific Build Systems**: C/C++ GNU Make, Java Maven, Go Modules, Python interpreted/ctypes, Rust Cargo. Multi-Toolchain (GCC/Clang), C++20 standards, **Library-First API Design** (~20 slot-level accessor methods intentional).
   8. **## Core Features** — **Shared Behavioral Contract (All Languages)**: three-stage pipeline, status-driven coordination (`readyforread` → `readyfortransform` → `readyforwrite` → `readyforread`), cooperative cancellation, error handler callback (non-zero = shutdown), EOF detection (`LAST_BUFFER_TO_TRANSFORM` → `LAST_BUFFER_TO_WRITE`), transform in-place. Pipelined Architecture, Performance (Cache Alignment 64-byte, Small Binaries `-ffunction-sections`, Universal Binaries macOS `lipo -create`, Compiler Flags `-fvisibility=hidden`/`-flto=thin`), Data Integrity (MD5/SHA256/SHA512 per slot), Diagnostics (NVI Logging per-stage verbosity).
   9. **## LLM Knowledge Package** — Versioned knowledge packages for C++, Java, Python. Subsections:
      - **### What It Contains** — `knowledge/` directory tree (manifest.json, Modelfile, system-prompt.md, api-reference/, examples/, patterns/, instruction-dataset/)
      - **### Distribution Paths** — System Prompt (Modelfile, any Qwen model) vs Fine-Tuned (14B GGUF, ~10GB RAM)
      - **### Versioning** — MAJOR/MINOR/SUBVERSION from `version.mk`, BUILD_ID manual input to `update.sh`
      - **### Update Process** — `./knowledge/update.sh <BUILD_ID>` regenerates docs/dataset, `./knowledge/build_model.sh` fine-tunes on M4 Mac mini
      - **### Installation (End Users)** — Path A: `ollama create swtr-ringbuffer -f Modelfile`; Path B: `ollama create swtr-ringbuffer --from model.gguf`
      - **### Development (Internal)** — GitLab private branches → auto-replication to public GitHub mirror
   10. **## LinkedIn Post Generator** — `prompts/common/linkedin/generate_post.py`. Subsections:
       - **### Usage** — CLI examples (from JSON project file, inline args, dry-run, write to file)
       - **### Project Metadata Files** — JSON fields: name, description, features, tech, link, lesson, feedback_area
       - **### Post Guidelines Enforced** — 1000-1500 chars optimal, hook in first 140 chars, single-sentence paragraphs, first-person tone, CTA question, 3-5 hashtags
   11. **## Quick Start: End-to-End Workflow (macOS Example)** — Five-step prompt-driven process with exact prompts and outputs:
       - **### Step 1: Generate Source Code** — `create_functional.md` → `.hpp`, `.cpp` files in `src/macos/cpp/`
       - **### Step 2: Create Build Environment** — `create_build.md` → Makefile, version.mk, library artifacts in `src/macos/cpp/lib/`
       - **### Step 3: Verify the Build** — `verify_build.md` → Mach-O binaries, symbol visibility
       - **### Step 4: Set Up Test Infrastructure** — `create_regression.md` → tests/ with Makefile, test data T001-T007
       - **### Step 5: Execute Regression Tests** — `run_regression.md` → T001-T007, regression_report.md, JUnit XML
       - **### Incremental Updates** — `update_functional.md`, `update_build.md`, `update_testing.md`
   12. **## Library API Example** — Construction, transform setup, I/O configuration, pipeline execution. Subsections:
       - **### Advanced Configuration** — Per-stage logging (`set_read_logging_enabled`, `set_transform_verbosity`), checksum algorithm selection (`set_checksum_alg`), custom error handler (plain C function pointer). Transform types: `0` (identity), `1` (uppercase), `2` (XOR 0xFF). User transforms: `std::function<void(std::vector<uint8_t>&, size_t&)>`
       - **### Version Propagation** — All languages derive version from `version.mk`: C/C++ Makefile include, Java version.sh→pom.xml, Go version.sh→version.go, Python version.sh→version.py, Rust build.rs→src/version.rs
       - **### Pipeline Architecture Diagram** — Mermaid flowchart showing three pipeline threads and slot state transitions. Key points: atomic index counters, slot state progression, EOF propagation
       - **### Pipeline Animation** — `animated_graphics/pipeline_animation.gif` (45 frames, 1000ms each, ~45s cycle)
   13. **## Initial Development Environment** — OS, Hardware (core count + RAM), AI Tools subsection: Agent Harness (name/version/commit), Model Name, Model Specs (parameter count, architecture, optimization method)
   14. **## Project Structure** — Deterministic file mapping strategy (max 3 functions per `.cpp` file). Per-OS `src/<os>/cpp/` includes `specs/` subdirectory. **reference_linux** as canonical reference platform in `prompts/reference_linux/`. Platform-insensitive languages: Java (`src/common/java/`), Python (`src/common/python/`). FreeBSD 14 Python (`src/freebsd14/python/`), Raspberry Pi OS Java (`src/raspios/java/`).
   15. **## Developer & Maintainer Guide** — See Part A/B/C/E below
   16. **## Required Tools** — Per-OS toolchain requirements (compiler, make, binary analysis tools like otool/readelf)
   17. **## Containerized Build Environment (if applicable)** — Base image, toolchain installation, container path
   18. **## macOS Skip Logic (if applicable)** — Graceful skip with logging for Linux-hosts-only platforms
   19. **## Supported Platforms** — OS-grouped table (OS, Language, Version, Verified Compilers). All platforms including FreeBSD 14/15. Footnote: `*TBS: To Be Supplied | WIP: Work In Progress`
   20. **## Known Issues & Toolchain Limitations** — Ubuntu 24.04 clang++ unsupported, FreeBSD 14 RUNPATH limitation (static library only), Arch Linux amd64-only containers
   21. **## Where We Are At** — Current implementation status per platform/language, verification results (binary symmetry, prompt linting), operational capabilities. Subsections:
       - **### Current Status (as of YYYY-MM-DD)** — C++ complete for macOS/Debian/Fedora/Ubuntu/Raspios/ArchLinux; Java/Python common implementations; C/Go/Rust pre-Phase A
       - **### What Works Today** — Auto-generated table: C++ library, Java library, Python library, Build system, Test infrastructure, Binary symmetry, Prompt linting, State tracking, Multi-language verify, Java regression, Changelog suggestions
   22. **## Where We're Going** — Static roadmap (updated manually):
       - **### Near-Term (Next Iterations)** — Additional languages C/Go/Rust, additional test patterns beyond zigzag, enhanced CI/CD
       - **### Medium-Term (Roadmap)** — FreeBSD 15 implementation, Arch Linux C++ source generation on Linux host, more comprehensive test coverage (concurrent access patterns, memory pressure, signal handling), documentation expansion
       - **### Long-Term (Vision)** — Full multi-language library, cross-platform verification suite comparing behavior across language/platform combinations, plugin ecosystem for custom transforms
   23. **## Appendices** — Table of appendix files under `prompts/common/appendices/`: archlinux-platform-analysis.md, cpp-cross-compiler-compatibility.md, debian-platform-analysis.md, fedora-platform-analysis.md, freebsd-platform-analysis.md, freebsd14_java_verification.md, freebsd14_python_verification.md, macos-platform-analysis.md, raspios-platform-analysis.md, ubuntu-platform-analysis.md
   24. **## License** — BSD 3-Clause License

3. **Maintenance & Workflow (Developer/Maintainer Section)**:
   This section must be split into three parts:

   **Part A: The Golden Rules (Coding Standards)**
   - **Binary Symmetry**: Source code MUST be byte-identical across ALL platforms (macOS, Linux — debian, fedora, ubuntu, raspios). The goal is a single canonical source tree that compiles and runs correctly on every target platform. When running on the same OS family (e.g., all Linux distros), source code is naturally identical since toolchain changes are applied uniformly. When using pure C++, pure Java, or pure Python across different Unix-family OSes (Linux vs macOS vs FreeBSD), differences should be minimal — limited only to `#ifdef` guards or macros that wrap OS-specific syscalls. The core logic, architecture, and API surface remain identical across all platforms.
   - **File Distribution**: Max 3 functions per `.cpp` file.
   - **Include Discipline**: `ringbuffer.hpp` first $\rightarrow$ Alphabetical Standard Headers $\rightarrow$ Local Headers.
   - **Naming**: Private members MUST use trailing underscores (`member_variable_`).
   - **Hierarchy**: `RingBuffer` $\rightarrow$ `SwtrRingBuffer`.
   - **Platform Sync**: When updating any platform's source, build, or test artifacts, the same changes MUST be applied to all other Linux platforms. Use the cross-platform update propagation directives in `update_functional.md`, `update_build.md`, and `update_testing.md`.
   - **Prompt Deduplication**: Repeated content (container runtime rules, host-target compatibility checks, spec precedence statements) MUST be extracted into shared reference documents (e.g., `prompts/common/session_hints.md`) and referenced via relative links rather than duplicated verbatim across functional.md, build.md, and testing.md in every platform directory.
   - **Cross-Platform Generation Mandate**: All platform source code MUST be generated **independently** from the common specification. Do NOT copy source files, Makefiles, or Dockerfiles between platforms. Each platform generates its own artifacts from the shared spec, then cross-platform verification checks for byte-identical output (minus allowed differences).
     - **Allowed Makefile differences**: `CONTAINER_IMAGE` variable value, working directory path in container run commands, host distro detection check.
     - **Allowed Dockerfile differences**: `FROM` base image line, package installation RUN blocks (platform-specific package managers).

   **Part A.1: C++ Golden Rules**
   - **Conditional Compilation (C++)**: When a platform lacks a C++ feature available on other platforms, use `#ifdef` blocks to provide an alternative implementation for that OS **only**. Never modify the common code path or "down-rev" features for all other platforms. See `prompts/common/conditional_compilation_rule.md`.

   **Part A.2: C Golden Rules**
   - **Conditional Compilation (C)**: When a platform lacks a C feature available on other platforms, use `#ifdef` blocks to provide an alternative implementation for that OS **only**. Never modify the common code path or "down-rev" features for all other platforms. See `prompts/common/conditional_compilation_rule.md`.

   **Part B: The Prompt-Driven Workflow
   Explain that the agent requires a valid path to the prompt file to execute the workflow.

   **Prompt-Driven Incremental Regeneration:**
   Describe the feature that allows the codebase to be synchronized with specifications without redundant writes.
   - **State Tracking**: Explain the use of `.gen_state.json` at the project root to track SHA-256 hashes of prompts and file fingerprints for delta detection.
   - **3-Phase Sync**: Explain the pipeline: **Functional $\rightarrow$ Build $\rightarrow$ Regression**.
   - **Delta Updates**: Explain that the system uses "Update" prompts to apply targeted diffs rather than rewriting files.

   **Execution Examples:**
   Provide the following common prompts with their **exact paths** and **example command syntax**:

   - **Full Generation (Initial Setup):**
     - *Prompt:* `prompts/<os>/cpp/create_functional.md`
     - *Syntax Example:* `"Use prompts/debian/cpp/create_functional.md to perform a full generation of the ringbuffer for debian"`
   
   - **Incremental Update (Partial Regeneration):**
     - *Functional Update:* `prompts/<os>/cpp/update_functional.md`
     - *Build Update:* `prompts/<os>/cpp/update_build.md`
     - *Testing Update:* `prompts/<os>/cpp/update_testing.md`
     - *Syntax Example:* `"Use prompts/debian/cpp/update_functional.md to synchronize the debian implementation with the updated common specifications"`
   
   - **Verification & Testing:**
     - `prompts/common/verify_build.md`: Use this for a first-pass sanity check on library compilation.
       - *Syntax Example:* `"Use prompts/common/verify_build.md to run build_verify for debian and fedora"`
     - `prompts/common/regression_test.md`: Use this for final validation of the library and test suite.
       - *Syntax Example:* `"Use prompts/common/regression_test.md to do regression_test on debian, fedora, macos"`

   **Test Matrix (T001–T007):**
   Include a table documenting all seven test scenarios. This is ground truth — every implementation must pass:

   | Test | Config | Expected Exit | Output Match? |
   |------|--------|---------------|---------------|
   | T001 | Default (identity transform) | 0 | Yes — output == input |
   | T002 | 1 slot, 1-byte buffer (stress) | 0 | Yes — output == input |
   | T003 | Uppercase transform | 0 | Yes — output matches expected |
   | T004 | Small input, fast EOF | 0 | Yes — output == input |
   | T005 | Fatal error mode | **1** | Not checked (partial output) |
   | T006 | Non-fatal error mode | 0 | Yes — output == input |
   | T007 | XOR transform | 0 | Yes — output matches expected binary data |

   Document the test program CLI: `test001_staticlib [-o output_file] [-l log_file] [-s slots] [-b size] [-t transform_type] [-e error_mode] [-r] [-w <ip:port>] <input_file>`

   **Part C: Session Best Practices**
   The agent harness uses two key configuration files to maintain consistency across development sessions. These are **not** part of the generated README — they are operational files that guide how the agent behaves.

   - **`.bionic`** — Session startup configuration loaded automatically at the beginning of every session. It contains:
     - Project structure quick-reference and path resolution rules
     - Workflow naming conventions (`implement_*`, `run_*`, `verify_*`)
     - Platform classification (native-only vs. containerized)
     - Operational discipline rules (read-before-write, logging format, scope boundaries)
     - Tool availability check and error handling / loop detection policies
     - Transitory markers for workflow coordination

     > **Note:** LM Studio Bionic does not always reliably auto-load `.bionic`. If you do not see the **Tool Availability Report** at session start, manually ask the agent to read `.bionic` to reinitialize session context.

   - **`prompts/common/session_hints.md`** — Host-level quick-reference covering OS detection, macOS/Linux versioning, container runtime configuration, and memory calculation.

   - **`prompts/common/cpp/session_hints.md`** — C++-specific quick-reference loaded when working on source code, Makefiles, or build configurations. It provides:
     - Platform-specific toolchain references (Linux tools vs. macOS tools)
     - Binary format quick-reference (ELF vs. Mach-O)
     - Shared library linking conventions per platform
     - Common pitfalls and gotchas (e.g., macOS Make built-in defaults)

   - **`prompts/common/implement_new_os.md`** — Interactive workflow for adding a new operating system. It provides:
     - Session management with persistence (`:q`, `:wq`, `:ls`, `:rm`, `:status`, `:state`)
     - Template loading from pre-built distribution templates (`:templates`, `:load-template`)
     - Dry-run mode for previewing scaffolding without creating files
     - Multi-language support via comma-separated language list
     - Implementation state tracking (scaffolded → functional_implemented → build_tested → regression_passed → officially_supported)
     - Template management (`:save-template`, `:update-template` with diff-based change selection)

   **Best practice:** Always review `.bionic` at session start to confirm tool availability and operational rules. Reference `session_hints.md` for host-level context, `prompts/common/cpp/session_hints.md` when working on C++-specific tasks to avoid platform-specific gotchas, and `implement_new_os.md` when adding a new operating system.

   **Test Data Pattern System:**
   The Ringbuffer project uses a **pattern-driven** approach to test data generation. Instead of hardcoding pattern logic into each script, patterns are defined in standalone specification files that serve as the single source of truth. This ensures binary symmetry across all platforms and languages.

   - **Pattern files** live in `prompts/common/testing/patterns/`. Each file defines:
     - The template string (48 characters)
     - Line format: `NNNN <payload> NNNN` (4-digit prefix, 47-char payload with zigzag space position, 4-digit suffix)
     - Validation regex: `^[0-9]{4} .{47} [0-9]{4}$`
     - The transformation algorithm (e.g., zig-zag space position)
     - A Python reference implementation (ground truth for all shell variants)
     - Test file line counts and JUnit test matrix
   - **The `create_scripts.md` prompt** reads a pattern file and generates utility scripts in four shell languages (Bash, Zsh, Tcsh, Bourne) that produce byte-identical output.
   - **Scripts are deployed** to each platform's `tests/utils/bin/` directory during test environment setup.

   **Directory Structure:**
   ```
   prompts/common/testing/
   ├── create_scripts.md          ← workflow prompt for generating scripts
   └── patterns/
       ├── README.md              ← instructions + copy-paste template for new patterns
       └── zigzag.md              ← the default zig-zag pattern (also the only one)
   ```

   **Usage Examples:**

   - **Generate scripts from the default pattern:**
     - *Prompt:* `prompts/common/testing/create_scripts.md`
     - *Syntax Example:* `"Use prompts/common/testing/create_scripts.md to create utility scripts from the zigzag pattern"`

   - **Update scripts after modifying a pattern:**
     - *Prompt:* `prompts/common/testing/create_scripts.md`
     - *Syntax Example:* `"Use prompts/common/testing/create_scripts.md to update the utility scripts. The pattern file is at prompts/common/testing/patterns/zigzag.md"`

   - **Create a new pattern and generate scripts:**
     - *Syntax Example:* `"Create a new test data pattern at prompts/common/testing/patterns/sequential.md with template '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^&*()<>', sequential numbering, and validation regex '^[0-9]{4} .{47} [0-9]{4}$'. Then generate the utility scripts."`

   - **Verify generated scripts match the Python reference:**
     - *Syntax Example:* `"Use prompts/common/testing/create_scripts.md to regenerate scripts from zigzag.md and verify all shell variants produce byte-identical output against the Python reference implementation"`

   **Part E: Adding a New Operating System** — Reference guide for implementing support for a new OS. Covers OS classification, identification methods, release naming conventions, container configuration, and required prompt files. Subsections:
   - **1. OS Classification — Container vs. Native**: Table of categories (Native-only, Containerized amd64, Containerized arm64 on Apple Silicon, Linux-hosts-only, Excluded) with container support and example platforms
   - **2. OS Identification**: macOS (`sw_vers`), Universal kernel (`uname -s`), Linux distribution (`/etc/os-release`: ID, VERSION_ID, NAME, ID_LIKE), Architecture (`uname -m`). Special case: Raspberry Pi OS distinguished from stock Debian by `/etc/rpi-issue`
   - **3. Release Naming Conventions**: macOS point releases, Debian-based semver (debian:13, ubuntu:24.04), Fedora point releases (fedora:44), Arch Linux rolling release with datestamp tags, Raspberry Pi OS datestamp-based
   - **4. Container Configuration**: Dockerfile structure (RPM vs DEB package managers), container runtime selection (`container` on macOS, `podman` on Linux), macOS pre-flight checks
   - **5. Required Prompt Files**: 9 files per OS in `prompts/<os>/cpp/` (create_functional.md, create_build.md, create_regression.md, functional.md, build.md, testing.md, update_functional.md, update_build.md, update_testing.md)
   - **6. Reference Implementations to Review**: macOS (native-only, universal binaries), Raspberry Pi OS (arm64 container on Apple Silicon), Arch Linux (Linux-hosts-only, rolling release)
   - **7. Implementation Checklist**: 12 steps from OS classification through README update
   - **### Required Tools**: Per-OS toolchain requirements (compiler, make, binary analysis tools like otool/readelf)
   - **### Containerized Build Environment (if applicable)**: Base image, toolchain installation, container path
   - **### macOS Skip Logic (if applicable)**: Graceful skip with logging for Linux-hosts-only platforms
   - **7.5 SSH Remote Transfer Rule (All Platforms)**: File transfer procedure for remote testing via SSH
   - **7.6 Python Makefiles by Family (GNU vs BSD)**: GNU make syntax for macOS/Linux, BSD make syntax for FreeBSD 14+
   - A status table showing each capability with its current status and brief details. The generator MUST:
     1. Scan `src/` for all platform/language directories (cpp per-OS, common/java, common/python, freebsd14/python, raspios/java)
     2. For each combination, check if `version.mk` exists → status = ✅ Complete
     3. Check for `.gen_state.json` in each platform directory → status = ✅ Operational
     4. Run `verify_binary_symmetry.sh` and capture exit code → status = ✅ Verified or ❌ Failed
     5. Run `lint_prompts.sh` and capture exit code → status = ✅ Operational or ❌ Failed
     6. Generate a Markdown table with columns: Capability, Status (✅/⚠️/❌), Details
     7. Include rows for: C library (per OS), C++ library (per OS — macos, debian, fedora, ubuntu, raspios, archlinux, freebsd14), Go library (per OS), Java library (common + per-OS variants like raspios/java, freebsd14/python), Python library (common + per-OS variants), Rust library (per OS), Build system, Test infrastructure, Binary symmetry, Prompt linting, State tracking, LLM Knowledge Package (check for knowledge/ directory and manifest.json), LinkedIn Post Generator (check for prompts/common/linkedin/)
   
   **Static Roadmap Content:**
   - Near-Term (Next Iterations): Additional languages (C, Go, Rust implementation), additional test patterns beyond zigzag, enhanced CI/CD integration with automated verification scripts
   - Medium-Term (Roadmap): FreeBSD 15 implementation, Arch Linux C++ source generation on a Linux host, more comprehensive test coverage (concurrent access patterns, memory pressure, signal handling), documentation expansion
   - Long-Term (Vision): Full multi-language library with all 6 languages sharing the same functional spec, cross-platform verification suite comparing behavior across language/platform combinations (not just source-level binary symmetry), plugin ecosystem for custom transforms
   
   > **Note:** The roadmap content (near-term, medium-term, long-term) is static and should be updated manually when plans change. Only the "What Works Today" table is auto-generated.

4. **Platforms Table Requirements**:
   - **Values**: 
    - Use the version string (e.g., `v1.0.0` or `WIP v0.1.0`) derived from `version.mk` if it exists.
    - Otherwise, use `TBS` for platforms not yet started and `WIP` for those in progress. Do NOT use `TBD`.
   - **Platforms to Include**:
     - **macOS**: C++, Java, Python (native-only)
     - **Debian**: C++, Java, Python (containerized amd64)
     - **Fedora**: C++, Java, Python (containerized amd64)
     - **Ubuntu**: C++, Java, Python (containerized amd64; clang++ unsupported — see Known Issues)
     - **Raspberry Pi OS**: C++, Java (containerized arm64 on Apple Silicon)
     - **ArchLinux**: C++ (Linux-hosts-only; macOS skip with logging)
     - **FreeBSD 14**: C++, Python (native-only; static library only for C++ — see Known Issues)
     - **FreeBSD 15**: C++ (excluded; zero-length placeholder files only)
   - **Excluded Platforms (MUST ALWAYS APPEAR)**: FreeBSD 15 — C++ with `TBS` status. Never remove it, even if no `version.mk` exists.
   - **Linux-Hosts-Only Platforms**: ArchLinux — C++ (macOS skip with logging)
   - **Footnote**: Immediately following the table, include this exact footnote:
     `*TBS: To Be Supplied | WIP: Work In Progress`

**Verification:**
Ensure all placeholders are replaced with real-time detected data and that the formatting is professional, using clean Markdown tables and lists.
