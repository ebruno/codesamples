# Build Requirements — Ringbuffer (Rust)

**Implementation Directive:**
This build specification MUST be followed exactly to ensure consistency across platforms. Platform-specific deviations are permitted only for Rust version requirements and target triple configuration.

**Spec Precedence Rule:** When platform-specific specs (e.g., `prompts/<os>/rust/build.md`) conflict with common specs (`prompts/common/rust/build.md`), the platform-specific spec takes precedence for Rust version and target triple details. All other requirements in the common spec remain authoritative unless explicitly overridden by a platform-specific directive.

## Language Standards
- **Primary Version**: Rust 1.84.0
- **Fallback Versions** (in priority order): Rust 1.56.0
- **Minimum Supported**: Rust 1.56.0 — all implementations MUST be compatible with this version
- **Encoding**: UTF-8

## Build System: Cargo (Rust Package Manager)
All Rust builds MUST use the native Cargo toolchain. The project root for each platform MUST contain a `Cargo.toml` file.

### Cargo Configuration
- **Package name**: `ringbuffer`
- **Version**: Defined in `Cargo.toml` as `${project.version}` (sourced from `version.rs`)
- **Edition**: Rust 2021 edition (compatible with all supported versions)
- **Target triple**: Platform-specific (`x86_64-apple-darwin` on macOS, `x86_64-unknown-linux-gnu` on Linux)

### Required Cargo.toml
```toml
[package]
name = "ringbuffer"
version = "1.0.0"
edition = "2021"
description = "Ringbuffer library — three-stage pipeline with status-driven coordination"

[lib]
name = "swtr_ringbuffer"
path = "src/lib.rs"
crate-type = ["staticlib", "cdylib"]

[[bin]]
name = "ringbuffer_test"
path = "src/main.rs"
```

No external dependencies are required for the core ringbuffer library. The `Cargo.toml` MUST NOT include any third-party dependencies in the common spec. Platform-specific native access (e.g., `libc` crate for file descriptor I/O) may be added if needed.

### Required Cargo Targets
The following Cargo targets MUST be supported:

| Target | Description |
|--------|-------------|
| `cargo build --release` | Build the library in release mode (optimized) |
| `cargo test` | Run all tests and output results to stdout |
| `cargo check` | Check compilation without producing artifacts (fast feedback) |
| `cargo clean` | Remove the `target/` directory and all build artifacts |

### Artifact Naming
The built library MUST follow Cargo conventions:
- **Static Library**: `target/release/libswtr_ringbuffer.a` (or `.lib` on Windows)
- **Shared Library**: `target/release/libswtr_ringbuffer.so` (Linux), `target/release/libswtr_ringbuffer.dylib` (macOS)

For distribution, copy artifacts to `lib/`:
```bash
mkdir -p lib
cp target/release/libswtr_ringbuffer.{a,so} lib/   # Linux
# or
cp target/release/libswtr_ringbuffer.{a,dylib} lib/ # macOS
```

### Source Directory Structure
```
src/<os>/rust/
├── Cargo.toml                 # Rust package manifest
└── src/
    ├── lib.rs                 # Library root (all implementation)
    └── main.rs                # Test binary entry point
```

### Build Process
1. **Check**: `cargo check` — verifies compilation without producing artifacts (fastest feedback).
2. **Build**: `cargo build --release` — compiles the library in release mode with optimizations (`-C opt-level=3`).
3. **Test**: `cargo test` — runs the test suite and outputs results to stdout.
4. **Clean**: `cargo clean` — removes the `target/` directory and all build artifacts.

### Platform-Specific Considerations
- **macOS**: Use the native Rust installation (e.g., `rustup` or Homebrew `rust`). No container support. Target triple: `x86_64-apple-darwin` (or `aarch64-apple-darwin` on Apple Silicon). For universal binaries, build for both targets and combine with `lipo`.
- **Linux**: Use the platform-appropriate Rust installation (e.g., `rustup` or distro package). Target triple: `x86_64-unknown-linux-gnu`.
- **Container builds**: If building in a container, the Dockerfile MUST install Rust via `rustup` before running build commands.

### Temporary Workspace
- All temporary files MUST be placed in the `target/` directory (Cargo convention) or a `tmp/` directory.
- Do NOT create temporary files in the project root or source directories.

### Build Process Logging
- Create a directory at `src/<os>/rust/logs/`.
- Log build actions to `build.log` in the format: `[YYYY-MM-DD HH:MM:SS +/-HHMM] <Action Description>`.
- Append to existing log files; do NOT overwrite.

### Scope Boundary — Build Phase Only
The purpose of this prompt is to compile the library and produce artifacts in `lib/`. **Your task ends once both static and shared libraries exist in `lib/`.**

You MUST NOT:
- Run `cargo test` or any testing workflow
- Generate test data, compile test binaries, or execute any tests
- Proceed to verification, reporting, or test matrix execution

**Directory Scope Restriction:**
- **NEVER create, modify, or delete any files inside the `tests/` directory.** This directory is managed exclusively by testing-related prompts. Build-only prompts must treat it as read-only.

### Excluded Platforms
- **FreeBSD 14**, **FreeBSD 15**, and **ArchLinux** are excluded from active development.
- Do not modify, add content to, or create new files in `prompts/freebsd14/`, `prompts/freebsd15/`, or `prompts/archlinux/`.

### Version Reporting
The build process MUST detect and report the actual Rust compiler version in use:
- At the start of `build.log`: `[timestamp] rustc Version=<detected_version>`
- If the primary version (1.84.0) is not available, detect the highest fallback version that IS available and report it.
- If the detected Rust version is below 1.56.0, STOP and report: `ERROR: Detected rustc version <detected_version> is below minimum supported 1.56.0. Cannot proceed.`

Example log entries:
```
[2026-08-14 10:30:00 -0700] rustc Version=1.84.0 (primary target)
[2026-08-14 10:30:00 -0700] Build started for target macos
[2026-08-14 10:30:05 -0700] cargo build --release completed successfully
[2026-08-14 10:30:05 -0700] Artifacts copied to lib/
```
