# Ringbuffer

A high-performance, cross-platform circular buffer library designed for binary symmetry and deterministic execution.

## What It Does

The Ringbuffer library implements a **three-stage pipelined architecture** (Read → Transform → Write) that connects independent threads through a fixed-size array of shared slots. Each slot carries its own state machine, checksum, and data buffer, enabling lock-free concurrent processing with cache-line-aligned counters to prevent false sharing.

**How the pipeline works:**

1. **Read thread** fills slots from an input file descriptor, marking each slot `readyfortransform` when full. On EOF, it marks the final slot with `LAST_BUFFER_TO_TRANSFORM`.
2. **Transform thread** applies a user-supplied `std::function` to each slot's data, computes an atomic checksum (MD5/SHA256/SHA512), and marks the slot `readyforwrite`.
3. **Write thread** writes transformed data to an output file descriptor, clears the slot buffer, and resets it to `readyforread`. On the last buffer, it flushes (`fsync`) before signaling completion.

Each stage uses its own independent atomic index counter, so threads operate on slots without contention. The `wait()` method blocks until all data has flowed through the entire pipeline and threads have joined cleanly via `std::jthread` cooperative cancellation.

## Overview
The Ringbuffer library implements a three-stage pipelined architecture (**Read $\rightarrow$ Transform $\rightarrow$ Write**) to ensure efficient data movement and processing. Each stage runs in its own thread, communicating through a fixed-size array of shared slots with independent atomic index counters. The core focus of the project is **binary symmetry**, meaning the source code remains identical across all supported operating systems to ensure maintainability and predictable behavior.

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
    - **Universal Binaries (macOS)**: Built with both `arm64` and `x86_64` slices via `lipo -create`, enabling execution on both Apple Silicon and Intel Macs.
    - **Compiler Flags**: `-fvisibility=hidden` (hide internal symbols), `-flto` (link-time optimization), `-ffunction-sections -fdata-sections` (enable dead code elimination).
- **Data Integrity**: Integrated checksumming (MD5, SHA256, SHA512) for every buffer slot.
- **Diagnostics**: Non-Virtual Public Interface (NVI) logging system with per-stage (read/transform/write) independently configurable verbosity levels.

## Quick Start: End-to-End Workflow (macOS Example)

The following sequence shows the complete prompt-driven workflow for setting up, building, verifying, and testing on macOS. Each step depends on the previous one — execute them in order.

### Step 1: Generate Source Code
```
"Use prompts/macos/cpp/create_functional.md to perform a full generation of the ringbuffer for macos"
```
Produces: `ringbuffer.hpp`, `status.hpp`, `swtr_ringbuffer_impl.hpp`, and all `.cpp` implementation files in `src/macos/cpp/`.

### Step 2: Create Build Environment
```
"Use prompts/macos/cpp/create_build.md to create the build environment for macos"
```
Produces: `Makefile`, `version.mk`, and built library artifacts (`.a` static, `.dylib` shared) in `src/macos/cpp/lib/`. Libraries are versioned as `libswtr_ringbuffer-<MAJOR>.<MINOR>.<SUBVERSION>-<BUILD_ID>` with unversioned symlinks for convenience.

### Step 3: Verify the Build
```
"Use prompts/common/verify_build.md to run build_verify for macos"
```
Confirms: library compiles, produces correct Mach-O binaries, symbol visibility is correct, and binary sizes are within expected ranges.

### Step 4: Set Up Test Infrastructure
```
"Use prompts/macos/cpp/create_regression.md to create the test environment for macos"
```
Produces: `tests/` directory with Makefile, test data (T001–T007), utility scripts, and builds `test001_staticlib` / `test001_dynamiclib`.

### Step 5: Execute Regression Tests
```
"Use prompts/common/run_regression.md to run regression_test on macos"
```
Executes: the full T001–T007 test matrix, generates `regression_report.md` and `regression_report_junit.xml`.

**Linux platforms:** Replace native commands with container-wrapped equivalents. For example, `make` becomes `container run --rm -v $(pwd):/app ringbuffer_ubuntu_test make`. The container runtime (`container` on macOS hosts, `podman` on Linux hosts) is selected automatically by the Makefile.

### Incremental Updates
After the initial setup, use update prompts to synchronize with changed specifications:
```
"Use prompts/macos/cpp/update_functional.md to synchronize the macos implementation with updated common specifications"
```

## Library API Example

The following example demonstrates the core Ringbuffer API — construction, transform setup, and pipeline execution:

```cpp
#include "ringbuffer.hpp"
#include "swtr_ringbuffer_impl.hpp"
using namespace swtr;

int main() {
    // Transform: convert input to uppercase
    auto transform = [](std::vector<uint8_t>& data, size_t& size) {
        for (size_t i = 0; i < size; ++i)
            if (data[i] >= 'a' && data[i] <= 'z') data[i] -= 32;
    };

    // Create a ring buffer with 4 slots, 4096 bytes each
    auto rb = std::make_unique<SwtrRingBuffer>(4, BufferStatus::readyforread, 4096, nullptr, transform);

    // Configure I/O: read from stdin, write to stdout
    rb->set_read_fd(STDIN_FILENO);
    rb->set_write_fd(STDOUT_FILENO);

    // Enable logging for diagnostics
    rb->set_logging_enabled(true);
    rb->set_output_stream(std::cerr);

    // Run the pipeline: reads until EOF, transforms each slot, writes output
    rb->start();
    rb->wait();   // blocks until all data flows through read $\rightarrow$ transform $\rightarrow$ write
    rb->stop();
}
```

Build with: `clang++ -std=c++20 main.cpp -I../src/macos/cpp -L../src/macos/cpp/lib -lswtr_ringbuffer -o main`

### Advanced Configuration

The Ringbuffer API supports per-stage logging, checksum algorithm selection, and custom error handlers:

```cpp
// Per-stage logging configuration (independent verbosity per stage)
rb->set_read_logging_enabled(true);
rb->set_read_verbosity(LogLevel::Debug);
rb->set_transform_logging_enabled(true);
rb->set_write_logging_enabled(true);

// Checksum algorithm per slot (NONE, MD5, SHA256, SHA512)
rb->set_checksum_alg(0, ChecksumAlgorithm::SHA256);

// Custom error handler (plain C function pointer)
int my_error_handler(size_t slot_idx, BufferStatus status) {
    std::cerr << "Error in slot " << slot_idx << ": "
              << static_cast<int>(status) << std::endl;
    return 0; // 0 = continue, non-zero = stop pipeline
}
auto rb = std::make_unique<SwtrRingBuffer>(4, BufferStatus::readyforread, 4096, my_error_handler, transform);
```

**Transform types**: `0` (identity/bypass), `1` (uppercase), `2` (XOR with 0xFF). User-supplied transforms are passed as `std::function<void(std::vector<uint8_t>&, size_t&)>` and can implement any custom logic.

### Pipeline Architecture Diagram

The following diagram shows how the three pipeline threads interact through shared slots:

```mermaid
flowchart LR
    subgraph ReadThread ["Read Thread"]
        R1[readyforread] -->|fill slot with data| R2[processing_read]
        R2 -->|EOF? no, next slot| R1
        R2 -->|data ready, checksum computed| R3[readyfortransform]
    end

    subgraph TransformThread ["Transform Thread"]
        T1[readyfortransform] -->|apply user transform fn| T2[processing_transform]
        T2 -->|transform done, checksum computed| T3[readyforwrite]
    end

    subgraph WriteThread ["Write Thread"]
        W1[readyforwrite] -->|write data to output fd| W2[processing_write]
        W2 -->|clear buffer, reset slot| W3[readyforread]
    end

    ReadThread -->|slots: data + status| TransformThread
    TransformThread -->|slots: transformed data| WriteThread

    classDef thread fill:#e8f4fd,stroke:#2196F3,stroke-width:2px
    classDef slot fill:#fff3e0,stroke:#FF9800,stroke-width:2px
    class ReadThread,TransformThread,WriteThread thread
```

**Key points:**
- Each stage uses its own independent atomic index counter (`read_index_`, `transform_index_`, `write_index_`)
- Slots transition through states: `readyforread` $\rightarrow$ `processing_read` $\rightarrow$ `readyfortransform` $\rightarrow$ `processing_transform` $\rightarrow$ `readyforwrite` $\rightarrow$ `processing_write` $\rightarrow$ `readyforread`
- On EOF, the read thread marks the final slot with `LAST_BUFFER_TO_TRANSFORM`, which propagates through transform (`LAST_BUFFER_TO_WRITE`) to write, then all threads break and `wait()` returns

### Pipeline Animation

The following animation demonstrates the three-stage pipeline in action, showing how data flows through the read $\rightarrow$ transform $\rightarrow$ write stages:

![Pipeline Animation](animated_graphics/pipeline_animation.gif)

## Initial Development Environment
- **Operating System**: macOS 26.5.2 (Darwin 25.5.0)
- **Hardware**: Apple M4 Pro (arm64), 14 cores, 64 GB RAM
- **AI Tools**:
    - **Agent Harness**: LM Studio Bionic (CLI commit: 71bd99c)
    - **Model Name**: qwen3.6-35b-a3b-mlx
    - **Model Specs**: 37.75 GB, 162816 context window, parallelism factor 4, Decoder-only Transformer architecture, local execution.

## Project Structure
The project uses a **Deterministic File Mapping** strategy. Logic groups are mapped to specific filenames (e.g., `ReadOps.cpp`, `Threading.cpp`) with a strict constraint of **maximum 3 functions per file** to minimize git collisions and maximize modularity.

Each platform directory (`src/<os>/cpp/`) includes a `specs/` subdirectory containing copies of the specification files used to generate that platform's code, for reference and audit purposes.

**reference_linux**: A canonical reference platform in `prompts/reference_linux/cpp/` used for cross-platform verification. Source code is not generated here; it serves as the authoritative spec against which other platforms are compared.

## Developer & Maintainer Guide

### Part A: The Golden Rules (Coding Standards)
- **Binary Symmetry**: Source code MUST be identical across all platforms.
- **File Distribution**: No `.cpp` file may contain more than 3 function definitions.
- **Include Discipline**: `ringbuffer.hpp` must be the first non-comment include, followed by alphabetical standard headers, then local headers.
- **Naming**: All private member variables MUST use the trailing underscore convention (e.g., `member_variable_`).
- **Hierarchy**: The implementation must strictly follow the `RingBuffer` $\rightarrow$ `SwtrRingBuffer` hierarchy.
- **Platform Sync**: When updating any platform's source, build, or test artifacts, the same changes MUST be applied to all other Linux platforms. Use the cross-platform update propagation directives in `update_functional.md`, `update_build.md`, and `update_testing.md`.

### Part B: The Prompt-Driven Workflow
This project is managed via a set of prompts that define the desired state of the codebase. The agent requires a valid path to the prompt file to execute the workflow.

#### Prompt-Driven Incremental Regeneration
The codebase supports incremental synchronization using a state-tracking system (`.gen_state.json`). This allows the AI to update only the files affected by a specification change.
- **State Tracking**: Uses SHA-256 hashes of prompts and file fingerprints to detect changes.
- **3-Phase Sync**: Execution follows a strict pipeline: **Functional $\rightarrow$ Build $\rightarrow$ Regression**.
- **Delta Updates**: "Update" prompts are used to apply targeted diffs, preserving manual overrides and reducing churn.

#### Execution Examples

**Full Generation (Initial Setup):**
Use this when adding a new platform or resetting the codebase.
- *Prompt:* `prompts/<os>/cpp/create_functional.md`
- *Example:* `"Use prompts/ubuntu/cpp/create_functional.md to perform a full generation of the ringbuffer for ubuntu"`

**Incremental Update (Partial Regeneration):**
Use these to synchronize the codebase with updated specifications.
- *Functional Update:* `prompts/<os>/cpp/update_functional.md`
- *Build Update:* `prompts/<os>/cpp/update_build.md`
- *Testing Update:* `prompts/<os>/cpp/update_testing.md`
- *Example:* `"Use prompts/ubuntu/cpp/update_functional.md to synchronize the ubuntu implementation with the updated common specifications"`

**Verification & Testing:**
- *Build Verify:* `prompts/common/verify_build.md` — Use this for a first-pass sanity check on library compilation.
  - *Example:* `"Use prompts/common/verify_build.md to run build_verify for debian and fedora"`
- *Regression Test:* `prompts/common/regression_test.md` — Use this for final validation of the library and test suite.
  - *Example:* `"Use prompts/common/regression_test.md to do regression_test on debian, fedora, macos"`

#### Test Data Pattern System
The Ringbuffer project uses a **pattern-driven** approach to test data generation. Instead of hardcoding pattern logic into each script, patterns are defined in standalone specification files that serve as the single source of truth. This ensures binary symmetry across all platforms and languages.

- **Pattern files** live in `prompts/common/testing/patterns/`. Each file defines:
  - The template string (48 characters)
  - Line format: `NNNN <payload> NNNN` (4-digit prefix, 47-char payload with zigzag space position, 4-digit suffix)
  - Validation regex: `^[0-9]{4} .{47} [0-9]{4}$`
  - The transformation algorithm (e.g., zig-zag space position)
  - A Python reference implementation (ground truth for all shell variants)
  - Validation regex, test file line counts, and JUnit test matrix
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

#### Part C: Session Best Practices
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

**Best practice:** Always review `.bionic` at session start to confirm tool availability and operational rules. Reference `session_hints.md` for host-level context, and `prompts/common/cpp/session_hints.md` when working on C++-specific tasks to avoid platform-specific gotchas.

#### Test Matrix (T001–T007)
The test suite validates functional correctness, error handling, transform operations, and stress conditions:

| Test ID | Description | Transform | Error Mode | Expected Exit Code |
| :--- | :--- | :--- | :--- | :--- |
| T001 | Identity (normal) | 0 (none) | 0 (no error) | 0 |
| T002 | Stress test (1 slot, 1 byte) | 0 (none) | 0 (no error) | 0 |
| T003 | Uppercase transform | 1 (uppercase) | 0 (no error) | 0 |
| T004 | Small input, fast EOF | 0 (none) | 0 (no error) | 0 |
| T005 | Fatal error mode | 0 (none) | 1 (fatal) | 1 |
| T006 | Non-fatal error mode | 0 (none) | 2 (non-fatal) | 0 |
| T007 | XOR transform | 2 (XOR 0xFF) | 0 (no error) | 0 |

**Test program CLI**: `test001_staticlib [-o output_file] [-l log_file] [-s slots] [-b size] [-t transform_type] [-e error_mode] [-r] [-w <ip:port>] <input_file>`

#### State Tracking
The state file `.gen_state.json` at the project root tracks SHA-256 hashes of all prompt files and source file fingerprints, enabling delta detection for incremental regeneration.

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
