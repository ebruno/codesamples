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
   2. **## What It Does** — Three-stage pipelined architecture (Read → Transform → Write). Merged with former Overview: now includes binary symmetry focus and platform classification (Platform-Sensitive vs Platform-Insensitive languages)
   3. **## Implementation Status** — Table: 6 languages × 7 OSes with phase indicators (✅ B = implemented, ⬜ A = spec written). Link to Roadmap.
   4. **## Roadmap** — Checklist: Phase 1 ✅, Phase 2 ✅, Phases A-B ✅, Phase 3 ☐ (C/Go/Rust), Phase 4 ☐ (verification/docs)
   5. **## Key Specifications** — Multi-OS support, Language Standards and Classification, Language-Specific Build Systems, Unified Build/Test Pattern, Library-First API Design
   6. **## Core Features** — Shared Behavioral Contract, Pipelined Architecture, Performance, Data Integrity, Diagnostics
   7. **## Library API Example** — Construction, transform setup, I/O configuration, pipeline execution. Subsections: Advanced Configuration, Version Propagation, Pipeline Architecture Diagram, Pipeline Animation
   8. **## Quick Start: End-to-End Workflow (macOS Example)** — Five-step prompt-driven process with incremental updates
   9. **## Supported Platforms** — OS-grouped table (OS, Language, Version, Verified Compilers). Implemented languages only (C++, Java, Python).
   10. **## Known Issues** — Ubuntu clang++ unsupported, FreeBSD 14 RPATH limitation, LM Studio shell ENOENT bug
   11. **## Where We Are At** — Current implementation status (condensed; references Implementation Status table). Subsections: Current Status, What Works Today
   12. **## Where We're Going** — Static roadmap: Near-Term, Medium-Term, Long-Term
   13. **## Primary Goal** — Prompt-driven, immediate build-and-run functionality. Develop-then-refactor strategy (Phase A/B/C). Status in Implementation Status and Roadmap above.
   14. **## Project Structure** — Deterministic file mapping strategy. reference_linux as canonical reference platform
   15. **## Source File Layout & Symlink Usage** — C++ source deduplication via symlinks. Subsections: How C++ Source Files Are Organized, Symlink Awareness, Compatibility Matrix, Windows Support, Build Artifact Symlinks
   16. **## Development Methodology** — LLM-created. Interactive prompt generation, binary symmetry, incremental refinement, prompt versioning via .gen_state.json, post-commit hook
   17. **## LLM Challenges** — Portable Shell Scripts (Core Feature), BSD Makefiles vs GNU Make, macOS Toolchain Quirks, tcsh Scripts, Shell Portability, Python Multi-Compiler C++ Library Testing
   18. **## Prompt Execution Pattern** — Four-step: common workflow → platform-specific primary document → common spec → platform spec
   19. **## Developer & Maintainer Guide** — Parts A-E: Golden Rules, Prompt-Driven Workflow, Session Best Practices, Documentation & Media Assets, Adding a New Operating System
   20. **## Project Policies** — Shell Script Portability, SSH Authentication, Git Discipline, Build vs Test, Container Commands, Prompt Changelog/Deduplication, Makefile Tab, Version Naming, Mermaid Validation
   21. **## Required Tools** — Table of required/optional tools
   22. **## Initial Development Environment** — OS, Hardware, AI Tools
   23. **## TODO** — Pending items
   24. **## Appendices** — Platform analysis document links
   25. **## LLM Knowledge Package** — Versioned knowledge packages for C++, Java, Python (end of README)
   26. **## LinkedIn Post Generator** — Ad-hoc LinkedIn post tool (end of README)
   27. **## License** — BSD 3-Clause License


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
     - `prompts/common/verify_build.md`: Runs `<os>/<lang>/Makefile all` (build only, no tests). Supports C/C++, Java, Python.
       - *Syntax Example:* `"Use prompts/common/verify_build.md to run build_verify for debian and fedora"`
     - `prompts/common/run_regression.md`: Runs `tests/Makefile verify` (build + T001–T007 test matrix). Supports C/C++, Java, Python.
       - *Syntax Example:* `"Use prompts/common/run_regression.md to run regression on debian, fedora, macos"`

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
     - Multi-language support via comma-separated language list (e.g., `cpp, c`)
     - Implementation state tracking (`scaffolded → functional_implemented → build_tested → regression_passed → officially_supported`)
     - Template management (`:save-template`, `:update-template` with diff-based change selection)
     - Session storage in `.ringbuffer_sessions/` (gitignored); template storage in `prompts/common/templates/`

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

   **Part D: Documentation & Media Assets** — Scripts and prompts for generating project documentation and media. Subsections:
   - **README Generation** — `prompts/common/generate_toplevel_readme.md` prompt; when to regenerate (new platform/language, version changes, new languages/patterns, status table refresh, directory restructuring); how to sync prompt with README as source of truth
   - **Pipeline Animation** — `animated_graphics/bin/generate_pipeline_animation.py` (45 frames, 1000ms each); usage: `python3 animated_graphics/bin/generate_pipeline_animation.py [--output PATH]`
   - **GIF to MP4 Conversion** — `utils/bin/gif_to_mp4.sh` (720p/1080p, automatic letterboxing); requires ffmpeg/ffprobe
   - **LLM Knowledge Package** — `knowledge/update.sh` (regenerates API docs/examples/dataset from headers); `knowledge/build_model.sh` (QLoRA fine-tuning on M4 Mac mini, ~1-3 hours); version tracking via `knowledge/.gen_state.json`

   **Part E: Adding a New Operating System** — Reference guide for implementing support for a new OS. Covers OS classification, identification methods, release naming conventions, container configuration, and required prompt files. Subsections:
   - **1. OS Classification — Container vs. Native**: Table of categories (Native-only, Containerized amd64, Containerized arm64 on Apple Silicon, Linux-hosts-only, Excluded) with container support and example platforms. Decision flow: macOS → native-only; Linux → check arm64 image → check amd64 image → evaluate native build
   - **2. OS Identification**: macOS (`sw_vers --productVersion`, `--productName`, `--buildVersion`; minimum version 15); Universal kernel (`uname -s` — Darwin vs Linux); Linux distribution (`/etc/os-release`: ID, VERSION_ID, NAME, ID_LIKE, VERSION_CODENAME; special case: Raspberry Pi OS distinguished by `/etc/rpi-issue`); Architecture (`uname -m`: arm64/aarch64 vs x86_64/amd64). Includes unified detection script.
   - **3. Release Naming Conventions**: macOS point releases (use `sw_vers`), Debian-based semver (`debian:13`, `ubuntu:24.04`), Fedora point releases (`fedora:44`), Arch Linux rolling release (datestamp tags like `archlinux:2026.08.01`), Raspberry Pi OS datestamp-based (`raspios:arm64-bookworm-20251204`). Container tag pinning rules: semver-based distros pin to version number; datestamp-based distros pin 3 months in the past.
   - **4. Container Configuration**: Dockerfile patterns — Linux distro (RPM/DEB package managers), Raspberry Pi OS (arm64, Debian-based, datestamp tags), macOS (no Dockerfile — native-only), container runtime selection (`container` on macOS, `podman` on Linux). macOS pre-flight pattern: check `container system status`, start if needed.
   - **5. Required Prompt Files**: 9 files per OS in `prompts/<os>/cpp/` (create_functional.md, create_build.md, create_regression.md, functional.md, build.md, testing.md, update_functional.md, update_build.md, update_testing.md). Includes minimal `functional.md` and `build.md` templates.
   - **6. Reference Implementations to Review**: macOS (native-only, universal binaries, `lipo -create`, `@rpath`), Raspberry Pi OS (arm64 container on Apple Silicon, `/etc/rpi-issue` detection, datestamp tags), Arch Linux (rolling release, amd64-only containers, macOS skip logic, `pacman`)
   - **7. Implementation Checklist**: 13 steps from OS classification through README update (includes Build/Test Pattern step: `<os>/<lang>/Makefile all`, `tests/Makefile verify`, main Makefile `test: all`)
   - **7.5 SSH Remote Transfer Rule (All Platforms)**: File transfer procedure for remote testing via SSH — C++ source per-OS, Python common source, clean first, SCP transfer, verify file counts/sizes
   - **7.6 Python Makefiles by Family (GNU vs BSD)**: GNU make syntax for macOS/Linux (`Makefile.gnu`), BSD make syntax for FreeBSD 14+ (per-OS directory)
   - **8. Common Pitfalls to Avoid**: 8 items — don't copy source between platforms, Makefile tabs, `mkdir -p` before writing, version.mk = library not OS version, FreeBSD zero-length only, container image pinning, macOS skip logic exits 0, timestamps with timezone offset
   - **9. Interactive OS Setup Workflow (`implement_new_os.md`)**: Session management commands table (`:q`, `:wq`, `:ls`, `:rm`, `:status`, `:state`, `:templates`, `load-template`, `save-template`, `update-template`, `help`), session storage in `.ringbuffer_sessions/`, template storage in `prompts/common/templates/`, usage example with template selection

4. **Platforms Table Requirements**:
   - **Values**: 
    - Use the version string (e.g., `v1.0.0` or `WIP v0.1.0`) derived from `version.mk` if it exists.
    - Otherwise, use `TBS` for platforms not yet started and `WIP` for those in progress. Do NOT use `TBD`.
   - **Platforms to Include**:
     - **macOS**: C++, Java, Python, Go (placeholder), Rust (placeholder) — native-only
     - **Debian**: C++, Java, Python, Go (placeholder), Rust (placeholder) — containerized amd64
     - **Fedora**: C++, Java, Python, Go (placeholder), Rust (placeholder) — containerized amd64
     - **Ubuntu**: C++, Java, Python, Go (placeholder), Rust (placeholder) — containerized amd64; clang++ unsupported for C++
     - **Raspberry Pi OS**: C++, Go (placeholder), Rust (placeholder) — containerized arm64 on Apple Silicon
     - **ArchLinux**: C++, Java, Python, Go (placeholder), Rust (placeholder) — Linux-hosts-only; macOS skip with logging
     - **FreeBSD 14**: C++, Java, Python (Pure Python only), Go (placeholder), Rust (placeholder) — native-only; static library only for C++
     - **FreeBSD 15**: C++ (excluded; zero-length placeholder files only)
   - **Excluded Platforms (MUST ALWAYS APPEAR)**: FreeBSD 15 — C++ with `TBS` status. Never remove it, even if no `version.mk` exists.
   - **Linux-Hosts-Only Platforms**: ArchLinux — C++, Java, Python (macOS skip with logging)
   - **Footnote**: Immediately following the table, include this exact footnote:
     `*TBS: To Be Supplied | WIP: Work In Progress`

**Verification:**
Ensure all placeholders are replaced with real-time detected data and that the formatting is professional, using clean Markdown tables and lists.
