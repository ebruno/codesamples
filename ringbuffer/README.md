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
- **Hardware**: 
    - **Model**: Mac16,11 (Mac mini)
    - **CPU**: 14-core Apple Silicon processor
    - **Memory**: 64 GB Unified Memory

### AI Tools
- **Agent Harness**: LM Studio Bionic Version 1.0.4+9
- **LLM**: `google/gemma-4-31B-it-qat`
- **Model Specifications**: 
    - **Architecture**: Decoder-only Transformer.
    - **Parameters**: ~31 Billion.
    - **Optimization**: Quantization-Aware Training (QAT) for high-efficiency inference without significant loss in reasoning or coding capability.
    - **Specialization**: Instruct-tuned for advanced reasoning, complex coding tasks, and precise instruction following.

## Project Structure
The project follows a strict deterministic file mapping to ensure build consistency and minimize version control collisions, separating interfaces, implementation logic, and accessors into discrete files.

## Supported Platforms
- **Archlinux**
    - C: To Be Supplied
    - C++: To Be Supplied
    - Go: To Be Supplied
    - Java: To Be Supplied
    - Python: To Be Supplied
    - Rust: To Be Supplied
- **Debian**
    - C: To Be Supplied
    - C++: Work in Progress
    - Go: To Be Supplied
    - Java: To Be Supplied
    - Python: To Be Supplied
    - Rust: To Be Supplied
- **Fedora**
    - C: To Be Supplied
    - C++: Work in Progress
    - Go: To Be Supplied
    - Java: To Be Supplied
    - Python: To Be Supplied
    - Rust: To Be Supplied
- **Freebsd14**
    - C: To Be Supplied
    - C++: To Be Supplied
    - Go: To Be Supplied
    - Java: To Be Supplied
    - Python: To Be Supplied
    - Rust: To Be Supplied
- **Freebsd15**
    - C: To Be Supplied
    - C++: To Be Supplied
    - Go: To Be Supplied
    - Java: To Be Supplied
    - Python: To Be Supplied
    - Rust: To Be Supplied
- **Macos**
    - C: To Be Supplied
    - C++: Work in Progress
    - Go: To Be Supplied
    - Java: To Be Supplied
    - Python: To Be Supplied
    - Rust: To Be Supplied
- **Ubuntu**
    - C: To Be Supplied
    - C++: To Be Supplied
    - Go: To Be Supplied
    - Java: To Be Supplied
    - Python: To Be Supplied
    - Rust: To Be Supplied

## License
This project is licensed under the **BSD 3-Clause License**.
