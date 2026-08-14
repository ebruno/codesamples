# Build Requirements — Ringbuffer (Python)

**Implementation Directive:**
This build specification MUST be followed exactly to ensure consistency across platforms. Platform-specific deviations are permitted only for Python version requirements.

**Spec Precedence Rule:** When platform-specific specs (e.g., `prompts/<os>/python/build.md`) conflict with common specs (`prompts/common/python/build.md`), the platform-specific spec takes precedence for Python version. All other requirements in the common spec remain authoritative unless explicitly overridden by a platform-specific directive.

## Language Standards
- **Primary Version**: Python 3.14
- **Fallback Versions** (in priority order): Python 3.13, Python 3.12, Python 3.11, Python 3.10
- **Minimum Supported**: Python 3.10 — all implementations MUST be compatible with this version
- **Encoding**: UTF-8

## Build System: None (Pure Python)
Python is an interpreted language. There is no compilation step for the ringbuffer library itself. The "build" consists of:
1. Verifying Python is available and meets version requirements
2. Running syntax checks on all `.py` files
3. Verifying the module imports cleanly and core classes are instantiable

### Required Tools
- `python3` (Python interpreter, version 3.10+)

### Build Targets
The following build targets MUST be supported:

| Target | Description |
|--------|-------------|
| `build` | Verify Python version, syntax check all `.py` files, verify module imports and class instantiation. No compilation needed. |
| `test` | Run the test binary: `python3 test_ringbuffer.py <config>` |
| `lint` | Run syntax check: `python3 -m py_compile <file>` (built-in, no external tools) |
| `clean` | Remove any generated cache files (`__pycache__/`, `.pyc`). |

### Build Process
1. **Version Check**: Verify Python version meets minimum requirements (3.10+). Log the detected version.
2. **Syntax Check**: Run `python3 -m py_compile` on all `.py` files in the source directory to verify syntax correctness.
3. **Import Check**: Run `python3 -c "import swtr_ringbuffer; print(swtr_ringbuffer.__version__)"` to verify the module imports cleanly.
4. **Instantiation Check**: Run `python3 -c "from swtr_ringbuffer import SwtrRingBuffer; rb = SwtrRingBuffer(4, 256); print(type(rb))"` to verify core classes are instantiable.
5. **Completion**: The build is complete once all Python files pass syntax checking, the module imports cleanly, and core classes are instantiable.

### Artifact Naming
No artifacts are produced by the Python build itself. The implementation is pure Python with no external dependencies.

### Source Directory Structure
```
src/common/python/
├── swtr_ringbuffer.py       # Complete implementation (BufferSlot, SwtrRingBuffer)
├── __init__.py              # Package init (exports public API)
├── version.py               # Library version constants
└── test_ringbuffer.py       # Test binary (7-test matrix)
```

### Platform-Specific Considerations
- **macOS**: Use the native Python installation (e.g., Homebrew `python3` or system Python). No container support.
- **Linux**: Use the platform-appropriate Python package (e.g., `python3` on Ubuntu, `python3` on Fedora).
- **Container builds**: If building in a container, the Dockerfile MUST install Python 3.10+ before running build commands.

### Temporary Workspace
- All temporary files MUST be placed in a `tmp/` directory or Python's cache (`__pycache__/`).
- Do NOT create temporary files in the project root or source directories.

### Build Process Logging
- Create a directory at `src/common/python/logs/`.
- Log build actions to `build.log` in the format: `[YYYY-MM-DD HH:MM:SS +/-HHMM] <Action Description>`.
- Append to existing log files; do NOT overwrite.

### Scope Boundary — Build Phase Only
The purpose of this prompt is to verify the Python implementation. **Your task ends once all Python files pass syntax checking, the module imports cleanly, and core classes are instantiable.**

You MUST NOT:
- Run the test binary (`test_ringbuffer.py`) or any testing workflow
- Generate test data, compile test binaries, or execute any tests
- Proceed to verification, reporting, or test matrix execution

**Directory Scope Restriction:**
- **NEVER create, modify, or delete any files inside the `tests/` directory.** This directory is managed exclusively by testing-related prompts. Build-only prompts must treat it as read-only.

### Excluded Platforms
- **FreeBSD 14**, **FreeBSD 15**, and **ArchLinux** are excluded from active development.
- Do not modify, add content to, or create new files in `prompts/freebsd14/`, `prompts/freebsd15/`, or `prompts/archlinux/`.

### Version Reporting
The build process MUST detect and report the actual Python version in use:
- At the start of `build.log`: `[timestamp] Python Version=<detected_version>`
- If the primary version (3.14) is not available, detect the highest fallback version that IS available and report it.
- If the detected Python version is below 3.10, STOP and report: `ERROR: Detected Python version <detected_version> is below minimum supported 3.10. Cannot proceed.`

Example log entries:
```
[2026-08-14 10:30:00 -0700] Python Version=3.14.0 (primary target)
[2026-08-14 10:30:00 -0700] Build started for target macos
[2026-08-14 10:30:01 -0700] Syntax check passed for swtr_ringbuffer.py
[2026-08-14 10:30:01 -0700] Module import successful
[2026-08-14 10:30:01 -0700] SwtrRingBuffer instantiation successful
```
