# Go — Reference Linux

**This is a canonical reference directory for cross-platform verification.**
Do NOT generate code here. This directory exists to maintain structural consistency across the prompt tree and serves as a reference point for verifying that per-OS implementations match the common specification.

## Purpose
- **Cross-platform verification**: Compare generated code from `prompts/fedora/go/`, `prompts/debian/go/`, etc. against the common spec in `prompts/common/go/`.
- **Structural consistency**: Ensures all language directories follow the same pattern.

## Reference Files
- `build.md` — Points to `prompts/common/go/build.md` for build requirements (Go 1.24 primary, Go 1.23/1.22 fallback)
- `functional.md` — Points to `prompts/common/go/functional.md` for functional requirements
- `testing.md` — Points to `prompts/common/go/testing.md` for testing requirements

## Do Not Modify
These files are scaffolding only. Any changes to Go specifications should be made in `prompts/common/go/`, not here.
