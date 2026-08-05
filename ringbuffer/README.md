# Ringbuffer Library

A high-performance, C++20-based circular buffer (FIFO) library designed for robust data pipelining across multiple platforms.

## Overview
The Ringbuffer library provides a fixed-size, first-in-first-out data structure that facilitates a three-stage pipeline: **Read $\rightarrow$ Transform $\rightarrow$ Write**. It is engineered for systems where binary symmetry, memory efficiency, and deterministic behavior are critical.

## Primary Goal
The project's prompts are designed to ensure that the generated source code is fully functional and consistently compiles and runs immediately upon the completion of the source code generation process using the predefined prompts.

## Key Specifications
- **Multi-OS Support**: Designed for deployment across various Linux distributions, ensuring identical source code and binary symmetry.
- **Multi-Toolchain Compatible**: Fully buildable and testable using both **GCC** and **Clang** toolchains.
- **Modern C++ Standard**: Leverages **C++20** features, including `std::jthread`, cooperative cancellation via `std::stop_token`, and advanced synchronization primitives.

## Core Features
- **Pipelined Architecture**:
    - **Read Stage**: Efficiently fills buffer slots from POSIX file descriptors.
    - **Transform Stage**: Applies customizable transformation logic to data.
    - **Write Stage**: Writes processed data to POSIX file descriptors with support for `fsync` on completion.
- **Performance Optimization**:
    - **Cache Alignment**: Buffer slots and counters are aligned to cache line boundaries to prevent false sharing.
    - **Small Binary Footprint**: Optimized for dead code elimination (`-ffunction-sections`, `-fdata-sections`) to minimize the final binary size.
- **Data Integrity & Reliability**:
    - **Checksums**: Integrated support for checksum algorithms (MD5, SHA256, SHA512) to verify data.
    - **Robust Error Handling**: Customizable error handlers can trigger graceful cooperative cancellation of the entire pipeline.
- **Diagnostics**:
    - **Flexible Logging**: Non-Virtual Public Interface (NVI) logging with multiple levels (`Trace` to `Critical`) and configurable output streams.

## Initial Development Environment
- **Operating System**: macOS 26.5.2 (Build 25F84)
- **Kernel**: Darwin 25.5.0
- **Architecture**: arm64 (Apple Silicon)
- **Hardware**: Mac mini (Mac16,11), 14-core CPU, 64 GB Unified Memory

### AI Tools
- **Agent Harness**: LM Studio Bionic
- **LLM**: `gemma-4`
- **Model Specs**: ~31B Parameter Decoder-only Transformer, Quantization-Aware Training (QAT) for high-efficiency inference, and Instruct-tuned for advanced reasoning and precise coding tasks.

## Project Structure
The project follows a strict deterministic file mapping to ensure build consistency and minimize version control collisions, separating interfaces, implementation logic, and accessors into discrete files.

## Developer & Maintainer Guide

### The Golden Rules
To maintain the integrity of the library, all contributors MUST adhere to these standards:
- **Binary Symmetry**: Source code MUST be identical across all target OSs. No platform-specific coding styles.
- **Strict File Distribution**: No `.cpp` file may exceed 3 functions. Use numbered files (e.g., `ReadOps_1.cpp`) if logic exceeds this limit.
- **Include Discipline**: Every `.cpp` must start with `ringbuffer.hpp`, followed by alphabetical standard headers.
- **Naming**: Private members MUST use the trailing underscore (e.g., `sync_mutex_`).
- **Hierarchy**: Adhere strictly to the `RingBuffer` (Interface) $\rightarrow$ `SwtrRingBuffer` (Impl) chain.

### Prompt-Driven Workflow
This project is maintained via a set of common prompts in `ringbuffer/prompts/common/`. Use them in the following order:

1. **`implement_functional.md`**: Use when starting a new OS implementation or updating core logic.
   - **Command Example**: `"implement functional for debian"`
2. **`verify_builds.md`**: Use after implementation to perform a sanity check that the library compiles.
   - **Command Example**: `"run build_verify for fedora"`
3. **`regression_test.md`**: Use as the final step to verify that both the library and the test suite pass.
   - **Command Example**: `"do regression_test on debian, fedora, macos"`

## Supported Platforms
| OS | C | C++ | Go | Java | Python | Rust |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Archlinux** | TBS | TBS | TBS | TBS | TBS | TBS |
| **Debian** | TBS | v1.0.0 | TBS | TBS | TBS | TBS |
| **Fedora** | TBS | v1.0.0 | TBS | TBS | TBS | TBS |
| **Macos** | TBS | v1.0.0 | TBS | TBS | TBS | TBS |
| **Ubuntu** | TBS | TBS | TBS | TBS | TBS | TBS |
| **Freebsd14** | TBS | TBS | TBS | TBS | TBS | TBS |
| **Freebsd15** | TBS | TBS | TBS | TBS | TBS | TBS |

`*TBS: To Be Supplied | WIP: Work In Progress`

## License
This project is licensed under the **BSD 3-Clause License**.
