# C — Reference Linux

**This is a canonical reference directory for cross-platform verification.**
Do NOT generate code here. This directory exists to maintain structural consistency across the prompt tree and serves as a reference point for verifying that per-OS implementations match the common specification.

## Purpose
- **Cross-platform verification**: Compare generated code from `prompts/fedora/c/`, `prompts/debian/c/`, etc. against the common spec in `prompts/common/c/`.
- **Structural consistency**: Ensures all language directories follow the same pattern.

## Reference Files
- `build.md` — Points to `prompts/common/c/build.md` for build requirements (C23 primary, C17/C11 fallback)
- `functional.md` — Points to `prompts/common/c/functional.md` for functional requirements
- `testing.md` — Points to `prompts/common/c/testing.md` for testing requirements

## Do Not Modify
These files are scaffolding only. Any changes to C specifications should be made in `prompts/common/c/`, not here.
