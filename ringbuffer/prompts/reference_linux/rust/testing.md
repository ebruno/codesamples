# Rust — Reference Linux

**This is a canonical reference directory for cross-platform verification.**
Do NOT generate code here. This directory exists to maintain structural consistency across the prompt tree and serves as a reference point for verifying that per-OS implementations match the common specification.

## Purpose
- **Cross-platform verification**: Compare generated code from `prompts/fedora/rust/`, `prompts/debian/rust/`, etc. against the common spec in `prompts/common/rust/`.
- **Structural consistency**: Ensures all language directories follow the same pattern.

## Reference Files
- `build.md` — Points to `prompts/common/rust/build.md` for build requirements (Rust 1.84.0 primary, Rust 1.56.0 fallback)
- `functional.md` — Points to `prompts/common/rust/functional.md` for functional requirements
- `testing.md` — Points to `prompts/common/rust/testing.md` for testing requirements

## Do Not Modify
These files are scaffolding only. Any changes to Rust specifications should be made in `prompts/common/rust/`, not here.
