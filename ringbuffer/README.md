# Ringbuffer

A high-performance, cross-platform circular buffer library designed for binary symmetry and deterministic execution.

## Overview
The Ringbuffer library implements a three-stage pipelined architecture (**Read $\rightarrow$ Transform $\rightarrow$ Write**) to ensure efficient data movement and processing. The core focus of the project is **binary symmetry**, meaning the source code remains identical across all supported operating systems to ensure maintainability and predictable behavior.

## Primary Goal
The objective is to provide a prompt-driven, immediate build-and-run functionality where the codebase can be regenerated or updated across multiple platforms using a single set of functional specifications.

## Key Specifications
- **Multi-OS Support**: Seamless deployment across various Linux distributions and macOS.
- **Multi-Toolchain Compatibility**: Fully buildable using both **GCC** and **Clang**.
- **C++20 Standard**: Leverages `std::jthread`, cooperative cancellation, and advanced synchronization primitives.

## Core Features
- **Pipelined Architecture**: Decoupled read, transform, and write loops for maximum throughput.
- **Performance**: 
    - **Cache Alignment**: Buffer slots and counters are aligned to 64-byte boundaries to prevent false sharing.
    - **Small Binaries**: Optimized for dead code elimination (`-ffunction-sections`, `-fdata-sections`).
- **Data Integrity**: Integrated checksumming (MD5, SHA256, SHA512) for every buffer slot.
- **Diagnostics**: Non-Virtual Public Interface (NVI) logging system with granular verbosity levels.

## Initial Development Environment
- **Operating System**: macOS 26.5.2 (Darwin 25.5.0)
- **Hardware**: Apple M4 Pro (arm64)
- **AI Tools**:
    - **Agent Harness**: LM Studio Bionic
    - **Model Name**: qwen3.6-35b-a3b-mlx
    - **Model Specs**: 37.75 GB, 162816 context window, parallelism factor 4, local execution.

## Project Structure
The project uses a **Deterministic File Mapping** strategy. Logic groups are mapped to specific filenames (e.g., `ReadOps.cpp`, `Threading.cpp`) with a strict constraint of **maximum 3 functions per file** to minimize git collisions and maximize modularity.

## Developer & Maintainer Guide

### The Golden Rules (Coding Standards)
- **Binary Symmetry**: Source code MUST be identical across all platforms.
- **File Distribution**: No `.cpp` file may contain more than 3 function definitions.
- **Include Discipline**: `ringbuffer.hpp` must be the first non-comment include, followed by alphabetical standard headers, then local headers.
- **Naming**: All private member variables MUST use the trailing underscore convention (e.g., `member_variable_`).
- **Hierarchy**: The implementation must strictly follow the `RingBuffer` $\rightarrow$ `SwtrRingBuffer` hierarchy.

### The Prompt-Driven Workflow
This project is managed via a set of prompts that define the desired state of the codebase.

#### 1. Prompt-Driven Incremental Regeneration
The codebase supports incremental synchronization using a state-tracking system (`.gen_state.json`). This allows the AI to update only the files affected by a specification change.
- **State Tracking**: Uses SHA-256 hashes of prompts and file fingerprints to detect changes.
- **3-Phase Sync**: Execution follows a strict pipeline: **Functional $\rightarrow$ Build $\rightarrow$ Regression**.
- **Delta Updates**: "Update" prompts are used to apply targeted diffs, preserving manual overrides and reducing churn.

#### 2. Execution Examples

**Full Generation (Initial Setup):**
Use this when adding a new platform or resetting the codebase.
- *Prompt:* `ringbuffer/prompts/<os>/cpp/create_functional.md`
- *Example:* `"Use ringbuffer/prompts/ubuntu/cpp/create_functional.md to perform a full generation of the ringbuffer for ubuntu"`

**Incremental Update (Partial Regeneration):**
Use these to synchronize the codebase with updated specifications.
- *Functional Update:* `ringbuffer/prompts/<os>/cpp/update_functional.md`
- *Build Update:* `ringbuffer/prompts/<os>/cpp/update_build.md`
- *Testing Update:* `ringbuffer/prompts/<os>/cpp/update_testing.md`
- *Example:* `"Use ringbuffer/prompts/ubuntu/cpp/update_functional.md to synchronize the ubuntu implementation with the updated common specifications"`

**Verification & Testing:**
- *Build Verify:* `ringbuffer/prompts/common/verify_builds.md`
- *Regression Test:* `ringbuffer/prompts/common/regression_test.md`
- *Example:* `"Use ringbuffer/prompts/common/regression_test.md to do regression_test on debian, fedora, macos"`

#### 3. Test Data Pattern System

The Ringbuffer project uses a **pattern-driven** approach to test data generation. Patterns are defined in standalone specification files that serve as the single source of truth, ensuring binary symmetry across all platforms and languages.

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

## Supported Platforms

| OS | Language | Version |
| :--- | :--- | :--- |
| macOS | C++ | v1.0.0 |
| Debian | C++ | v1.0.0 |
| Fedora | C++ | v1.0.0 |
| Ubuntu | C++ | v1.0.0 |
| ArchLinux | C++ | TBS |
| FreeBSD 14 | C++ | TBS |
| FreeBSD 15 | C++ | TBS |

`*TBS: To Be Supplied | WIP: Work In Progress`

## License
This project is licensed under the **BSD 3-Clause License**.
