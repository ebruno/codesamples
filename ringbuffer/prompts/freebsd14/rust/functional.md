# Rust Functional — FreeBSD 14

**Note:** Rust is a platform-insensitive language. Source code is identical across all platforms.
Use `prompts/common/rust/functional.md` as the primary specification for functional requirements.
No platform-specific functional overrides are needed for Rust on FreeBSD 14.

## Functional Notes
- The Rust implementation follows the common spec exactly: three-stage pipeline (read → transform → write) with status-driven coordination.
- Error handling uses Rust closures and channels for cooperative cancellation.
- Version reporting: detect `rustc --version` at runtime, log to functional.log and build.log.
