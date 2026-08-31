# Rust Build — <OS>

**Note:** Rust is a platform-insensitive language. Source code is identical across all platforms.
Use `prompts/common/rust/build.md` and `prompts/common/rust/functional.md` as the primary specifications.
No platform-specific build overrides are needed for Rust on <OS>.

## Build Notes
- **Build System**: Cargo (`Cargo.toml`) — identical across all platforms.
- **Compiler**: Primary target is Rust 1.84.0, with fallback to 1.56.0 as needed.
- **Container**: Use `container` (macOS host) or `podman` (Linux host) with image from the per-OS Dockerfile.
  - Arch Linux: Linux-hosts-only (no container images for Apple Silicon).
- **Output**: `target/release/libswtr_ringbuffer.{a,so|dylib}` (via `crate-type = ["staticlib", "cdylib"]`).
