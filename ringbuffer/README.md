# Ringbuffer

A high-performance, binary-symmetric ringbuffer implementation designed for deterministic cross-platform behavior.

## Overview
The Ringbuffer implements a three-stage pipeline (**Read $\rightarrow$ Transform $\rightarrow$ Write**) with a core focus on binary symmetry. This architecture ensures that data is ingested, processed, and persisted with minimal overhead and identical behavior across all supported operating systems.

## Primary Goal
The primary objective is to achieve prompt-driven, immediate build-and-run functionality, where AI-generated source code is deterministic, verifiable, and consistent across diverse toolchains.

## Key Specifications
- **Multi-OS Support**: Native implementations for Linux (Debian, Fedora) and macOS.
- **Multi-Toolchain Compatibility**: Optimized for both GCC and Clang.
- **Standard**: Strict adherence to the C++20 standard.

## Core Features
- **Pipelined Architecture**: Decoupled read, transform, and write stages for maximum throughput.
- **Performance**: Cache-aligned structures and small binary footprints to minimize latency.
- **Data Integrity**: Built-in checksum algorithms to verify data consistency throughout the pipeline.
- **Diagnostics**: Non-Virtual Interface (NVI) logging for deep visibility into internal state without sacrificing performance.

## Initial Development Environment
- **OS**: macOS 26.5.2 (Build 25F84)
- **Hardware**: Apple M4 Pro (arm64)
- **AI Tools**:
    - **Agent Harness**: LM Studio Bionic
    - **Model Name**: `google/gemma-4-31B-it-qat`
    - **Model Specs**: 31B Parameter Decoder-only Transformer, Quantization-Aware Training (QAT), Instruct-tuned for complex coding.

## Project Structure
The project employs a deterministic file mapping strategy. Source code is distributed across multiple small files (max 3 functions per file) to ensure modularity and ease of verification. Each platform implementation is mirrored exactly to maintain binary symmetry.

## Developer & Maintainer Guide

### The Golden Rules (Coding Standards)
- **Binary Symmetry**: Source code MUST be identical across all platforms.
- **File Distribution**: Max 3 functions per `.cpp` file.
- **Include Discipline**: `ringbuffer.hpp` first $\rightarrow$ Alphabetical Standard Headers $\rightarrow$ Local Headers.
- **Naming**: Private members MUST use trailing underscores (`member_variable_`).
- **Hierarchy**: `RingBuffer` $\rightarrow$ `SwtrRingBuffer`.

### The Prompt-Driven Workflow
The agent requires a valid path to the prompt file to execute the workflow. Use the following common prompts:

- `ringbuffer/prompts/common/implement_functional.md`: Use this when initiating source code creation or updating core logic.
  - *Syntax Example:* `"Use ringbuffer/prompts/common/implement_functional.md to implement functional for debian and fedora"`
- `ringbuffer/prompts/common/verify_builds.md`: Use this for a first-pass sanity check on library compilation.
  - *Syntax Example:* `"Use ringbuffer/prompts/common/verify_builds.md to run build_verify for debian and fedora"`
- `ringbuffer/prompts/common/regression_test.md`: Use this for final validation of the library and test suite.
  - *Syntax Example:* `"Use ringbuffer/prompts/common/regression_test.md to do regression_test on debian, fedora, macos"`

## Supported Platforms

| OS | Language | Version |
| :--- | :--- | :--- |
| Debian | C++ | v1.0.0 |
| Fedora | C++ | v1.0.0 |
| macOS | C++ | v1.0.0 |
| ArchLinux | C++ | WIP |
| FreeBSD 14 | C++ | WIP |
| FreeBSD 15 | C++ | WIP |
| Ubuntu | C++ | WIP |

`*TBS: To Be Supplied | WIP: Work In Progress`

## License
This project is licensed under the BSD 3-Clause License.
