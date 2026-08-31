# Python — Reference Linux

**This is a canonical reference directory for cross-platform verification.**
Do NOT generate code here. This directory exists to maintain structural consistency across the prompt tree and serves as a reference point for verifying that per-OS implementations match the common specification.

## Purpose
- **Cross-platform verification**: Compare generated code from `prompts/fedora/python/`, `prompts/debian/python/`, etc. against the common spec in `prompts/common/python/`.
- **Structural consistency**: Ensures all language directories follow the same pattern.

## Reference Files
- `build.md` — Points to `prompts/common/python/build.md` for build requirements (Python 3.14 primary, Python 3.12/3.13 fallback)
- `functional.md` — Points to `prompts/common/python/functional.md` for functional requirements
- `testing.md` — Points to `prompts/common/python/testing.md` for testing requirements

## Do Not Modify
These files are scaffolding only. Any changes to Python specifications should be made in `prompts/common/python/`, not here.
