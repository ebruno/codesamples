# Rust Testing — <OS>

**Note:** Rust is a platform-insensitive language. Source code is identical across all platforms.
Use `prompts/common/rust/functional.md` and `prompts/common/rust/build.md` as the primary specifications.
No platform-specific overrides are needed for Rust on <OS>.

## Execution Notes
- **Build System**: Cargo (`Cargo.toml`) — identical across all platforms.
- **Compiler**: Primary target is Rust 1.84.0, with fallback to 1.56.0 as needed.
- **Container**: Use `container` (macOS host) or `podman` (Linux host) with image from the per-OS Dockerfile.
  - Arch Linux: Linux-hosts-only (no container images for Apple Silicon).
- **Test matrix**: T001-T007 applies to all implementations.
