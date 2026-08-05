# README Generation Workflow

**Objective:** 
Generate a comprehensive `README.md` for the Ringbuffer project that serves as a high-level overview for users and a strict technical manual for developers and maintainers.

**Process:**
1. **Information Gathering**:
   - **Environment**: Detect the current host OS, kernel version, architecture, and hardware specifications. For macOS, use `sw_vers` to retrieve the `ProductName`, `ProductVersion`, and `BuildVersion`.
   - **AI Tooling**: Identify the current LLM and agent harness being used (e.g., LM Studio Bionic).
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

   **Part B: The Prompt-Driven Workflow**
   Explain how and when to use the following common prompts, including **example command syntax** for each:
   - `implement_functional.md`: Use this when initiating source code creation or updating core logic. 
     - *Syntax Example:* `"implement functional for debian"`
   - `verify_builds.md`: Use this for a first-pass sanity check on library compilation.
     - *Syntax Example:* `"run build_verify for fedora"`
   - `regression_test.md`: Use this for final validation of the library and test suite.
     - *Syntax Example:* `"do regression_test on debian, fedora, macos"`

4. **Platforms Table Requirements**:
   - **Values**: 
    - Use the version string (e.g., `v1.0.0` or `WIP v0.1.0`) derived from `version.mk` if it exists.
    - Otherwise, use `TBS` for platforms not yet started and `WIP` for those in progress. Do NOT use `TBD`.
   - **Footnote**: Immediately following the table, include this exact footnote:
     `*TBS: To Be Supplied | WIP: Work In Progress`

**Verification:**
Ensure all placeholders are replaced with real-time detected data and that the formatting is professional, using clean Markdown tables and lists.
