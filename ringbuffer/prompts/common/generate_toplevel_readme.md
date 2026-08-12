# README Generation Workflow

**Objective:** 
Generate a comprehensive `README.md` for the Ringbuffer project that serves as a high-level overview for users and a strict technical manual for developers and maintainers.

**Process:**
1. **Information Gathering**:
   - **Environment**: Detect the current host OS, kernel version, architecture, and hardware specifications. For macOS, use `sw_vers` to retrieve the `ProductName`, `ProductVersion`, and `BuildVersion`.
   - **AI Tooling**: Identify the current LLM and agent harness being used (e.g., LM Studio Bionic). If `lms` is in the system path, execute `lms ps` to determine the active model. Extract the value from the **MODEL** column and use it as the **Model Name**.
   - **Platform Matrix**: Scan `ringbuffer/src/` and `ringbuffer/prompts/` to determine which OS and Language combinations are implemented. For C++, check for the existence of `ringbuffer/src/<os>/cpp/version.mk`.
    - If `version.mk` exists: Read `MAJOR`, `MINOR`, and `SUBVERSION`.
        - If `MAJOR > 0`: Use `vMAJOR.MINOR.SUBVERSION`.
        - If `MAJOR == 0`: Use `WIP vMAJOR.MINOR.SUBVERSION`.
    - If `version.mk` does not exist: Use `WIP` or `TBS` based on project progress.

2. **Content Structure**:
   The README MUST follow this exact section order:
   
   - **Title & Introduction**: Project name and a concise one-sentence value proposition.
   - **Overview**: Describe the three-stage pipeline (**Read $\rightarrow$ Transform $\rightarrow$ Write**) and the focus on binary symmetry.
   - **Primary Goal**: State the objective of ensuring prompt-driven, immediate build-and-run functionality.
   - **Key Specifications**: Highlight Multi-OS support, Multi-Toolchain compatibility (GCC/Clang), and C++20 standards.
   - **Core Features**: Detailed bullets on Pipelined Architecture, Performance (Cache Alignment, Small Binaries), Data Integrity (Checksums), and Diagnostics (NVI Logging).
   - **Initial Development Environment**: A technical snapshot including OS, Hardware, and a specific **AI Tools** subsection. This subsection MUST detail:
    - **Agent Harness**: Name and version.
    - **Model Name**: Full identifier (e.g., `google/gemma-4-31B-it-qat`).
    - **Model Specs**: Parameter count, architecture (e.g., Decoder-only Transformer), optimization method (e.g., Quantization-Aware Training - QAT), and specific tuning specialization (e.g., Instruct-tuned for complex coding).
   - **Project Structure**: Explain the deterministic file mapping strategy.
   - **Developer & Maintainer Guide**: (See "Maintenance & Workflow" below).
   - **Supported Platforms**: A formatted matrix of OS vs Language.
   - **License**: State the BSD 3-Clause License.

3. **Maintenance & Workflow (Developer/Maintainer Section)**:
   This section must be split into two parts:

   **Part A: The Golden Rules (Coding Standards)**
   - **Binary Symmetry**: Source code MUST be identical across all platforms.
   - **File Distribution**: Max 3 functions per `.cpp` file.
   - **Include Discipline**: `ringbuffer.hpp` first $\rightarrow$ Alphabetical Standard Headers $\rightarrow$ Local Headers.
   - **Naming**: Private members MUST use trailing underscores (`member_variable_`).
   - **Hierarchy**: `RingBuffer` $\rightarrow$ `SwtrRingBuffer`.
   - **Platform Sync**: When updating any platform's source, build, or test artifacts, the same changes MUST be applied to all other Linux platforms. Use the cross-platform update propagation directives in `update_functional.md`, `update_build.md`, and `update_testing.md`.

   **Part B: The Prompt-Driven Workflow
   Explain that the agent requires a valid path to the prompt file to execute the workflow.

   **1. Prompt-Driven Incremental Regeneration:**
   Describe the feature that allows the codebase to be synchronized with specifications without redundant writes.
   - **State Tracking**: Explain the use of `.gen_state.json` to track spec hashes and file fingerprints.
   - **3-Phase Sync**: Explain the pipeline: **Functional $\rightarrow$ Build $\rightarrow$ Regression**.
   - **Delta Updates**: Explain that the system uses "Update" prompts to apply targeted diffs rather than rewriting files.

   **2. Execution Examples:**
   Provide the following common prompts with their **exact paths** and **example command syntax**:

   - **Full Generation (Initial Setup):**
     - *Prompt:* `ringbuffer/prompts/<os>/cpp/create_functional.md`
     - *Syntax Example:* `"Use ringbuffer/prompts/debian/cpp/create_functional.md to perform a full generation of the ringbuffer for debian"`
   
   - **Incremental Update (Partial Regeneration):**
     - *Functional Update:* `ringbuffer/prompts/<os>/cpp/update_functional.md`
     - *Build Update:* `ringbuffer/prompts/<os>/cpp/update_build.md`
     - *Testing Update:* `ringbuffer/prompts/<os>/cpp/update_testing.md`
     - *Syntax Example:* `"Use ringbuffer/prompts/debian/cpp/update_functional.md to synchronize the debian implementation with the updated common specifications"`
   
   - **Verification & Testing:**
     - `ringbuffer/prompts/common/verify_build.md`: Use this for a first-pass sanity check on library compilation.
       - *Syntax Example:* `"Use ringbuffer/prompts/common/verify_build.md to run build_verify for debian and fedora"`
     - `ringbuffer/prompts/common/regression_test.md`: Use this for final validation of the library and test suite.
       - *Syntax Example:* `"Use ringbuffer/prompts/common/regression_test.md to do regression_test on debian, fedora, macos"`

   **3. Test Data Pattern System:**
   The Ringbuffer project uses a **pattern-driven** approach to test data generation. Instead of hardcoding pattern logic into each script, patterns are defined in standalone specification files that serve as the single source of truth. This ensures binary symmetry across all platforms and languages.

   - **Pattern files** live in `ringbuffer/prompts/common/testing/patterns/`. Each file defines:
     - The template string (48 characters)
     - Line format (prefix, payload, suffix structure)
     - The transformation algorithm (e.g., zig-zag space position)
     - A Python reference implementation (ground truth for all shell variants)
     - Validation regex, test file line counts, and JUnit test matrix
   - **The `create_scripts.md` prompt** reads a pattern file and generates utility scripts in four shell languages (Bash, Zsh, Tcsh, Bourne) that produce byte-identical output.
   - **Scripts are deployed** to each platform's `tests/utils/bin/` directory during test environment setup.

   **Directory Structure:**
   ```
   ringbuffer/prompts/common/testing/
   ├── create_scripts.md          ← workflow prompt for generating scripts
   └── patterns/
       ├── README.md              ← instructions + copy-paste template for new patterns
       └── zigzag.md              ← the default zig-zag pattern (also the only one)
   ```

   **Usage Examples:**

   - **Generate scripts from the default pattern:**
     - *Prompt:* `ringbuffer/prompts/common/testing/create_scripts.md`
     - *Syntax Example:* `"Use ringbuffer/prompts/common/testing/create_scripts.md to create utility scripts from the zigzag pattern"`

   - **Update scripts after modifying a pattern:**
     - *Prompt:* `ringbuffer/prompts/common/testing/create_scripts.md`
     - *Syntax Example:* `"Use ringbuffer/prompts/common/testing/create_scripts.md to update the utility scripts. The pattern file is at ringbuffer/prompts/common/testing/patterns/zigzag.md"`

   - **Create a new pattern and generate scripts:**
     - *Syntax Example:* `"Create a new test data pattern at ringbuffer/prompts/common/testing/patterns/sequential.md with template '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^&*()<>', sequential numbering, and validation regex '^[0-9]{4} .{47} [0-9]{4}$'. Then generate the utility scripts."`

   - **Verify generated scripts match the Python reference:**
     - *Syntax Example:* `"Use ringbuffer/prompts/common/testing/create_scripts.md to regenerate scripts from zigzag.md and verify all shell variants produce byte-identical output against the Python reference implementation"`

4. **Platforms Table Requirements**:
   - **Values**: 
    - Use the version string (e.g., `v1.0.0` or `WIP v0.1.0`) derived from `version.mk` if it exists.
    - Otherwise, use `TBS` for platforms not yet started and `WIP` for those in progress. Do NOT use `TBD`.
   - **Footnote**: Immediately following the table, include this exact footnote:
     `*TBS: To Be Supplied | WIP: Work In Progress`

**Verification:**
Ensure all placeholders are replaced with real-time detected data and that the formatting is professional, using clean Markdown tables and lists.
