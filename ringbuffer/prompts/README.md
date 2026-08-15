# Ringbuffer Project Prompts

This directory contains the functional and testing requirements for the ringbuffer library, organized by operating system and programming language.

## Structure

`prompts/{os}/{language}/`

- `functional.md`: Defines the functional requirements for the library in the specific language on the specific OS.
- `testing.md`: Defines the testing requirements and test cases for the library in the specific language on the specific OS.

## Operating Systems

### Implemented
The currently implemented operating systems are defined by the directories present in `src/`. These are the only platforms that should be processed during creation or update cycles.

- **C++**: macOS, Fedora, Debian, Ubuntu (platform-sensitive — per-OS overrides)
- **C++**: Arch Linux (Linux-hosts-only — see macOS limitation below)
- **Java**: All platforms via `src/common/java/` (platform-insensitive — single common spec)
- **Python**: All platforms via `src/common/python/` (platform-insensitive — single common spec)

**Arch Linux macOS Limitation:** Arch Linux container images are amd64-only. On Apple Silicon (M-series) Macs, there is no ARM64 Arch Linux container available. Source code generation is supported on all platforms; build and test require a Linux host with `podman` or `docker`. See `prompts/common/session_hints.md` Section 3 for details.

### Supported (Prompts Available)
The following platforms have prompt specifications available in this directory:
- `macos`: macOS (native-only, no containers)
- `fedora`: Fedora Linux
- `debian`: Debian Linux
- `ubuntu`: Ubuntu Linux
- `archlinux`: Arch Linux (Linux-hosts-only — see macOS limitation in Implemented section)

### Reference
- `reference_linux`: Canonical reference set for Linux distributions used in cross-platform verification. Not an operating system — source code is not generated here; it serves as the authoritative spec against which other Linux platforms are compared.

### Excluded
The following platforms are excluded from active development. Their prompt directories contain only zero-length placeholder files:
- `freebsd14`: FreeBSD 14
- `freebsd15`: FreeBSD 15

## Supported Languages

| Language | Platform Sensitivity | Implementation Location |
|----------|---------------------|------------------------|
| `c`      | Platform-sensitive  | Per-OS (`src/<os>/c/`) |
| `cpp`    | Platform-sensitive  | Per-OS (`src/<os>/cpp/`) |
| `java`   | Platform-insensitive| Common (`src/common/java/`) |
| `python` | Platform-insensitive| Common (`src/common/python/`) |
| `go`     | Platform-insensitive| Per-OS (scaffolding in place) |
| `rust`   | Platform-insensitive| Per-OS (scaffolding in place) |
