# README Generation Workflow

**Objective:** 
Generate a comprehensive `README.md` for the Ringbuffer project that serves as a high-level overview for users and a strict technical manual for developers and maintainers.

**Process:**
1. **Information Gathering**:
   - **Environment**: Detect the current host OS, kernel version, architecture, and hardware specifications. For macOS, use `sw_vers` to retrieve the `ProductName`, `ProductVersion`, and `BuildVersion`.
   - **AI Tooling**: Identify the current LLM and agent harness being used (e.g., LM Studio Bionic). If `lms` is in the system path, execute `lms ps` to determine the active model. Extract the value from the **MODEL** column and use it as the **Model Name**.
   - **Platform Matrix**: Scan `src/` and `prompts/` to determine which OS and Language combinations are implemented. For C++, check for the existence of `src/<os>/cpp/version.mk`.
    - If `version.mk` exists: Read `MAJOR`, `MINOR`, and `SUBVERSION`.
        - If `MAJOR > 0`: Use `vMAJOR.MINOR.SUBVERSION`.
        - If `MAJOR == 0`: Use `WIP vMAJOR.MINOR.SUBVERSION`.
    - If `version.mk` does not exist: Use `WIP` or `TBS` based on project progress.
   - **Project Status**: Scan `src/` to determine which platforms have complete implementations (version.mk exists). Check for `.gen_state.json` files in each platform directory to verify state tracking is operational. Run `verify_binary_symmetry.sh <workspace_root>` and capture exit code (0 = verified, 1 = failed). Run `lint_prompts.sh <workspace_root>` and capture exit code (0 = passed, 1 = failed). Use these results to populate the "What Works Today" auto-generated table in the README.

2. **Content Structure**:
   The README MUST follow this exact section order:
   
   - **Title & Introduction**: Project name and a concise one-sentence value proposition.
   - **What It Does**: Explain the three-stage pipelined architecture (Read → Transform → Write) in plain English. Describe how each thread fills, transforms, and writes slots through shared slot state machines with independent atomic index counters. Mention `std::jthread` cooperative cancellation and the `wait()` blocking behavior.
   - **Overview**: Describe the three-stage pipeline (**Read $\rightarrow$ Transform $\rightarrow$ Write**) and the focus on binary symmetry.
   - **Primary Goal**: State the objective of ensuring prompt-driven, immediate build-and-run functionality.
   - **Development Methodology**: Explain that the project was created entirely from scratch using an LLM as the primary development tool. Describe interactive prompt generation, binary symmetry as a deliberate instruction, and incremental refinement methodology.
   - **Key Specifications**: Highlight Multi-OS support, Multi-Toolchain compatibility (GCC/Clang), and C++20 standards.
   - **Core Features**: Detailed bullets on Pipelined Architecture, Performance (Cache Alignment, Small Binaries, Universal Binaries for macOS via `lipo -create`, Compiler Flags including `-fvisibility=hidden`, `-flto`, `-ffunction-sections -fdata-sections`), Data Integrity (Checksums: MD5, SHA256, SHA512 per slot), and Diagnostics (NVI Logging with per-stage verbosity).
   - **Quick Start**: A condensed end-to-end workflow showing the five-step prompt-driven process (generate source → create build → verify build → set up tests → run regression). Include a note that Linux platforms require container-wrapped commands (`container` on macOS hosts, `podman` on Linux hosts). Document library versioning: artifacts are named `libswtr_ringbuffer-<MAJOR>.<MINOR>.<SUBVERSION>-<BUILD_ID>` with unversioned symlinks.
   - **Library API Example**: Include a basic example showing construction, transform setup, I/O configuration, and pipeline execution. Follow with an **Advanced Configuration** subsection demonstrating per-stage logging (`set_read_logging_enabled`, `set_transform_verbosity`, etc.), checksum algorithm selection (`set_checksum_alg`), and custom error handler registration (plain C function pointer). Document transform types: `0` (identity/bypass), `1` (uppercase), `2` (XOR with 0xFF). User-supplied transforms are `std::function<void(std::vector<uint8_t>&, size_t&)>`.
   - **Pipeline Architecture Diagram**: Include a Mermaid flowchart showing the three pipeline threads (Read, Transform, Write) and their slot state transitions. Follow with a **Key points** subsection listing the atomic index counters, slot state progression, and EOF propagation mechanism.
   - **Pipeline Animation**: Include the animated GIF demonstrating the pipeline in action. Use the relative path `animated_graphics/pipeline_animation.gif` so it renders inline on GitHub and GitLab.
   - **Initial Development Environment**: A technical snapshot including OS, Hardware (with core count and RAM), and a specific **AI Tools** subsection. This subsection MUST detail:
    - **Agent Harness**: Name and version (include CLI commit if available).
    - **Model Name**: Full identifier (e.g., `google/gemma-4-31B-it-qat`).
    - **Model Specs**: Parameter count, architecture (e.g., Decoder-only Transformer), optimization method (e.g., Quantization-Aware Training - QAT), and specific tuning specialization (e.g., Instruct-tuned for complex coding).
   - **Project Structure**: Explain the deterministic file mapping strategy. Mention that each platform directory (`src/<os>/cpp/`) includes a `specs/` subdirectory with copies of the specification files used to generate that platform's code. Document **reference_linux** as a canonical reference platform in `prompts/reference_linux/cpp/` used for cross-platform verification (source code is not generated here).
   - **Developer & Maintainer Guide**: (See "Maintenance & Workflow" below).
   - **Supported Platforms**: A formatted matrix of OS vs Language. Include all platforms — implemented ones with version strings, Linux-hosts-only (ArchLinux) with a note about macOS limitation, and excluded ones (FreeBSD 14/15) with `TBS`.
   - **Where We Are At**: A status report covering current implementation progress (which platforms/languages are complete), verification results (binary symmetry, prompt linting), and operational capabilities. Includes a "What Works Today" table showing status of each capability (C++ library, build system, test infrastructure, binary symmetry, prompt linting, state tracking) — this table is auto-generated by scanning `src/` for `version.mk`, `.gen_state.json`, and running verification scripts.
   - **Where We're Going**: A roadmap covering near-term goals (additional languages, new test patterns, CI/CD integration), medium-term plans (FreeBSD implementation, Arch Linux C++ source generation on a Linux host, expanded test coverage, documentation expansion), and long-term vision (full multi-language library, cross-platform verification suite, plugin ecosystem). This section is static and updated manually when plans change.
   - **License**: State the BSD 3-Clause License.
   - **Documentation & Media Assets**: Include a Part D subsection under Developer & Maintainer Guide documenting:
     - `prompts/common/generate_toplevel_readme.md` — the README generation workflow prompt
     - `animated_graphics/bin/generate_pipeline_animation.py` — pipeline animation GIF generator (45 frames, 1000ms each)
     - `utils/bin/gif_to_mp4.sh` — GIF to MP4 conversion utility (720p/1080p)

3. **Maintenance & Workflow (Developer/Maintainer Section)**:
   This section must be split into three parts:

   **Part A: The Golden Rules (Coding Standards)**
   - **Binary Symmetry**: Source code MUST be identical across all platforms.
   - **File Distribution**: Max 3 functions per `.cpp` file.
   - **Include Discipline**: `ringbuffer.hpp` first $\rightarrow$ Alphabetical Standard Headers $\rightarrow$ Local Headers.
   - **Naming**: Private members MUST use trailing underscores (`member_variable_`).
   - **Hierarchy**: `RingBuffer` $\rightarrow$ `SwtrRingBuffer`.
   - **Platform Sync**: When updating any platform's source, build, or test artifacts, the same changes MUST be applied to all other Linux platforms. Use the cross-platform update propagation directives in `update_functional.md`, `update_build.md`, and `update_testing.md`.

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
   Include a table documenting all seven test scenarios:

   | Test ID | Description | Transform | Error Mode | Expected Exit Code |
   | :--- | :--- | :--- | :--- | :--- |
   | T001 | Identity (normal) | 0 (none) | 0 (no error) | 0 |
   | T002 | Stress test (1 slot, 1 byte) | 0 (none) | 0 (no error) | 0 |
   | T003 | Uppercase transform | 1 (uppercase) | 0 (no error) | 0 |
   | T004 | Small input, fast EOF | 0 (none) | 0 (no error) | 0 |
   | T005 | Fatal error mode | 0 (none) | 1 (fatal) | 1 |
   | T006 | Non-fatal error mode | 0 (none) | 2 (non-fatal) | 0 |
   | T007 | XOR transform | 2 (XOR 0xFF) | 0 (no error) | 0 |

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

   **Part E: Project Status and Roadmap**
   
   This section documents the current state of the project and future plans. It is updated during each README regeneration cycle to reflect actual progress.
   
   **Where We Are At:**
   - Current implementation status per platform/language (complete, in progress, not started)
   - Verification results: binary symmetry check status, prompt linting results
   - Operational capabilities: state tracking, automated verification scripts, test infrastructure
   
   **Where We're Going:**
   - Near-term goals: additional languages (C, Go, Java, Python, Rust), new test patterns, CI/CD integration
   - Medium-term plans: FreeBSD/ArchLinux implementation, expanded test coverage, documentation expansion
   - Long-term vision: full multi-language library, cross-platform verification suite, plugin ecosystem
   
   **What Works Today (Auto-Generated):**
   - A status table showing each capability with its current status and brief details. The generator MUST:
     1. Scan `src/` for all platform/language directories
     2. For each combination, check if `version.mk` exists → status = ✅ Complete
     3. Check for `.gen_state.json` in each platform directory → status = ✅ Operational
     4. Run `verify_binary_symmetry.sh` and capture exit code → status = ✅ Verified or ❌ Failed
     5. Run `lint_prompts.sh` and capture exit code → status = ✅ Operational or ❌ Failed
     6. Generate a Markdown table with columns: Capability, Status (✅/⚠️/❌), Details
     7. Include rows for: C library (per OS), C++ library (per OS), Go library (per OS), Java library (per OS), Python library (per OS), Rust library (per OS), Build system, Test infrastructure, Binary symmetry, Prompt linting, State tracking
   
   **Static Roadmap Content:**
   - Near-Term (Next Iterations): Additional languages, additional patterns, enhanced CI/CD
   - Medium-Term (Roadmap): FreeBSD implementation, Arch Linux C++ source generation on a Linux host, more comprehensive test coverage, documentation expansion
   - Long-Term (Vision): Full multi-language library, cross-platform verification suite, plugin ecosystem
   
   > **Note:** The roadmap content (near-term, medium-term, long-term) is static and should be updated manually when plans change. Only the "What Works Today" table is auto-generated.

4. **Platforms Table Requirements**:
   - **Values**: 
    - Use the version string (e.g., `v1.0.0` or `WIP v0.1.0`) derived from `version.mk` if it exists.
    - Otherwise, use `TBS` for platforms not yet started and `WIP` for those in progress. Do NOT use `TBD`.
   - **Excluded Platforms (MUST ALWAYS APPEAR)**: The following platforms are excluded from active development but MUST remain in the table with `TBS` status. Never remove them, even if no `version.mk` exists:
     - **FreeBSD 14** — C++
     - **FreeBSD 15** — C++
   - **Linux-Hosts-Only Platforms**: The following platform has implemented prompts but requires a Linux host for build/test:
     - **ArchLinux** — C++ (Linux-hosts-only; macOS skip with logging)
   - **Footnote**: Immediately following the table, include this exact footnote:
     `*TBS: To Be Supplied | WIP: Work In Progress`

5. **PDF Generation** (Post-Processing):
   After the README is generated or updated, convert it to PDF. Mermaid diagrams are rendered as SVG images via `mmdc`, then embedded by pandoc.

   - **Prerequisites**: pandoc (v3.x+), mmdc (mermaid-cli via npm), node.js, and lualatex must be installed.
   - **Step 1 — Extract mermaid diagrams to SVG**:
     ```bash
     mmdc -i README.md -o README_diagrams.md -a diagrams --outputFormat svg
     ```
     This produces `diagrams/README_diagrams-1.svg` (the rendered diagram) and `README_diagrams.md` (a copy of README with mermaid blocks replaced by image references).
   - **Step 2 — Generate PDF**:
     ```bash
     pandoc README_diagrams.md --pdf-engine=lualatex -o doc/README.pdf
     ```
   - **Output**: The PDF is written to `doc/README.pdf`.
   - **When to regenerate**: Run both steps after any README update that adds or modifies mermaid diagrams, or when the content structure changes significantly.
   - **Verification**: Open `doc/README.pdf` and confirm all mermaid diagrams render correctly with proper formatting.

**Verification:**
Ensure all placeholders are replaced with real-time detected data and that the formatting is professional, using clean Markdown tables and lists.
