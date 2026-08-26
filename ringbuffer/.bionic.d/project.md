# Ringbuffer Project — Session Startup Instructions

## 1. Project Structure Quick Reference

```
ringbuffer/
├── prompts/                          # All workflow and spec documents (read-only reference)
│   ├── common/                       # Shared workflows, specs, and utilities
│   │   ├── implement_functional.md   # Functional code generation workflow
│   │   ├── implement_build.md        # Build environment creation workflow
│   │   ├── implement_regression.md   # Test infrastructure setup workflow
│   │   ├── implement_new_os.md       # Interactive OS scaffolding wizard
│   │   ├── run_regression.md         # Test execution workflow
│   │   ├── verify_build.md           # Build verification workflow
│   │   ├── health_check.md           # Project health diagnostics
│   │   ├── conditional_compilation_rule.md  # Conditional compilation guidelines
│   │   ├── session_hints.md          # Shared hints (container rules, host-target compat, spec precedence)
│   │   ├── CHANGELOG.md              # Prompt modification changelog
│   │   ├── CHANGELOG_TEMPLATE.md     # Template for changelog entries
│   │   ├── generate_toplevel_readme.md  # README generation spec (synced with README.md)
│   │   ├── add_language.md           # `add <lang> to <os>` dispatcher prompt
│   │   ├── templates/                # OS configuration JSON templates
│   │   │   ├── template_fedora.json  # Fedora platform template
│   │   │   └── template_debian.json  # Debian platform template
│   │   ├── testing/                  # Test infrastructure specs
│   │   │   ├── create_scripts.md     # Test script creation workflow
│   │   │   └── patterns/             # Testing pattern docs (zigzag, etc.)
│   │   ├── linkedin/                 # LinkedIn post generation
│   │   │   ├── generate_post.py      # Post generation script
│   │   │   └── projects/ringbuffer.json  # Project metadata for posts
│   │   ├── <lang>/                   # Language-specific specs (shared across all OSes)
│   │   │   ├── build.md              # Build specification
│   │   │   └── functional.md         # Functional implementation spec
│   │   ├── <lang>/session_hints.md   # Language-specific shared hints (c/, cpp/)
│   │   ├── cpp/                      # C++-specific specs (shared)
│   │   │   ├── build.md              # Build specification
│   │   │   ├── functional.md         # Functional implementation spec
│   │   │   ├── testing.md            # Testing specification
│   │   │   └── utils/bin/            # C++ utility scripts (4 shell variants each)
│   │   │       ├── generate_test_data.*      # Test data generation
│   │   │       ├── generate_junit_report.*   # JUnit XML report generation
│   │   │       ├── verify_test_data.*        # Test data validation
│   │   │       ├── verify_binary_symmetry.*  # Cross-platform source comparison
│   │   │       └── lint_prompts.*            # Prompt directory validation
│   │   ├── appendices/               # Platform analysis documents
│   │   │   ├── macos-platform-analysis.md
│   │   │   ├── fedora-platform-analysis.md
│   │   │   ├── debian-platform-analysis.md
│   │   │   ├── ubuntu-platform-analysis.md
│   │   │   ├── archlinux-platform-analysis.md
│   │   │   ├── raspios-platform-analysis.md
│   │   │   ├── freebsd-platform-analysis.md
│   │   │   ├── cpp-cross-compiler-compatibility.md
│   │   │   ├── freebsd14_java_verification.md
│   │   │   └── freebsd14_python_verification.md
│   │   ├── <os>/cpp/                 # Per-platform documents (fedora, debian, ubuntu, macos)
│   │   │   ├── create_functional.md      # PRIMARY document for functional impl.
│   │   │   ├── update_functional.md      # Update existing functional implementation
│   │   │   ├── create_build.md           # PRIMARY document for build creation
│   │   │   ├── update_build.md           # Update existing build configuration
│   │   │   ├── create_testing.md         # PRIMARY document for test infra setup
│   │   │   ├── update_testing.md         # Update existing test infrastructure
│   │   │   ├── create_regression.md      # PRIMARY document for regression infra setup
│   │   │   ├── functional.md             # Platform-specific functional requirements
│   │   │   ├── build.md                  # Platform-specific build requirements
│   │   │   └── testing.md                # Platform-specific test requirements
│   ├── <os>/<lang>/                  # Per-OS placeholder prompts (build.md, functional.md, testing.md)
│   │   # Contains non-zero placeholder text pointing to common specs
│   │   # (except C/C++ which have full platform-specific specs, FreeBSD 15 is zero-length)
│   └── reference_linux/<lang>/       # Canonical reference for cross-platform verification (non-zero placeholder text)
├── src/                              # Generated source code per platform
│   ├── <os>/cpp/                     # Per-OS C++ source (one directory per target OS)
│   │   ├── *.hpp / *.cpp             # Source files
│   │   ├── Makefile                  # Build configuration
│   │   ├── version.mk                # Library version (NOT OS version)
│   │   ├── LICENSE                   # Project license file (present in all OS dirs)
│   │   ├── containers/               # DEPRECATED — Dockerfiles consolidated to src/<os>/containers/
│   │   ├── tests/                    # Test infrastructure
│   │   ├── logs/                     # Build and execution logs (build.log)
│   │   ├── reports/                  # Build and verification reports
│   │   ├── lib/                      # Built libraries (.a, .so/.dylib)
│   │   ├── specs/                    # Copied spec files for reference
│   │   ├── build/                    # Build output artifacts (fedora, debian, ubuntu, raspios)
│   │   ├── src/                      # Nested source (fedora, ubuntu — for container builds)
│   │   ├── tasks/                    # Task tracking (raspios)
│   │   └── tmp/                      # Temporary files (raspios)
│   ├── <os>/containers/              # Unified Dockerfiles per OS (build + test)
│   │   ├── build/Dockerfile          # Full toolset for all languages (C/C++, Java, Python)
│   │   └── test/Dockerfile           # Identical to build — no cross-inheritance
│   ├── common/java/                  # Common Java source (identical across all OSes)
│   │   ├── pom.xml                   # Maven build configuration
│   │   └── swtr/                    # Java source packages
│   ├── common/python/                # Common Python source (identical across all OSes)
│   │   ├── Makefile.gnu              # GNU make build configuration
│   │   ├── swtr_ringbuffer/          # Concurrent (ctypes) module
│   │   ├── swtr_ringbuffer_pure.py   # Pure Python implementation
│   │   └── test_*.py                 # Test scripts
├── doc/                            # Documentation and generated assets
│   └── README.pdf                  # Rendered PDF of README.md
├── docs/                           # GitLab Pages documentation (zero-length .required_directory)
├── reports/                        # Per-language build/regression reports (java/, python/, cpp/)
│   ├── java/                       # Java build and regression reports
│   │   ├── build_verify.md         # Build verification report
│   │   └── regression.md           # Regression test report
│   ├── python/                     # Python build and regression reports
│   │   ├── build_verify.md         # Build verification report
│   │   └── regression.md           # Regression test report
│   └── cpp/                        # C++ build and regression reports
│       ├── build_verify.md         # Build verification report
│       └── per_os/                 # Per-OS reports
├── animated_graphics/              # Animated graphics artifacts
│   ├── bin/                        # Scripts for generating animated graphics
│   │   └── generate_pipeline_animation.py
│   └── pipeline_animation.gif
├── utils/bin/                      # Utility scripts (gif_to_mp4.sh, etc.)
├── images/                         # Static image assets (gif, mp4, png)
└── README.md                         # Project-level documentation
```

**Key directories:**
- `prompts/` — **Read-only reference.** Never modify generated files here.
- `src/<os>/cpp/` — **Write target.** All generated code, Makefiles, and artifacts go here.
- `src/<os>/cpp/tests/` — **Managed exclusively by testing workflows.** Build-only prompts must treat this as read-only.
- `src/<os>/cpp/LICENSE` — **License file.** Present in all OS directories; do not remove or modify.
- `reports/` — **Per-language reports.** Build and regression reports for Java, Python, C++, etc. Regenerated on every run.
- `animated_graphics/` — **Animated graphics.** Artifacts (GIFs) go here; scripts in `animated_graphics/bin/`.
- `utils/bin/` — **Utility scripts.** Store general-purpose utility scripts here (e.g., gif_to_mp4.sh).
- `images/` — **Image assets.** Store gif, mp4, png files here.
- `docs/` — **GitLab Pages documentation.** Contains information intended for use by GitLab Pages.

## 2. Workflow File Naming Convention

| Prefix | Purpose | Example |
|--------|---------|---------|
| `implement_*` | Creates infrastructure from scratch | `implement_build.md`, `implement_functional.md` |
| `run_*` | Executes on already-set-up infrastructure | `run_regression.md` |
| `verify_*` | Validates existing artifacts | `verify_build.md` |
| `update_*` | Updates existing implementation (build, functional, testing) | `update_build.md`, `update_functional.md`, `update_testing.md` |

**Primary documents** (per-OS) are named `create_<phase>.md`:
- `create_functional.md` — PRIMARY for functional implementation
- `create_build.md` — PRIMARY for build environment creation
- `create_testing.md` — PRIMARY for test infrastructure setup (parallel to create_regression)
- `create_regression.md` — PRIMARY for regression test execution infrastructure

**Update documents** (per-OS, C++ only) are named `update_<phase>.md`:
- `update_functional.md` — Update existing functional implementation
- `update_build.md` — Update existing build configuration
- `update_testing.md` — Update existing test infrastructure

## 3. Prompt Execution Pattern

Every workflow follows this pattern:
1. **Common workflow** provides structure, image/version resolution, and routing decisions
2. **Platform-specific primary document** (`create_*.md`) is the authoritative execution guide
3. **Common spec** (`common/cpp/*.md`) provides technical requirements
4. **Platform spec** (`<os>/cpp/*.md`) provides platform-specific overrides
5. **Shared hints** (`common/session_hints.md` or `<lang>/session_hints.md`) provide cross-cutting rules (container commands, host-target compatibility, spec precedence) — always check these before duplicating content

When a common workflow says "execute `create_*.md` as the PRIMARY document," it means:
- Read it for directives and immediate requirements
- Follow its steps as the main execution path
- Use the common workflow for infrastructure (image resolution, routing) only

## 4. Platform Classification

| Category | Platforms | Container Support |
|----------|-----------|-------------------|
| Native-only | macOS, FreeBSD 14/15 | None — no Dockerfiles, no containers |
| Linux distributions (amd64) | Fedora, Debian (stock), Ubuntu, reference_linux | Yes — `container` on macOS hosts, `podman` on Linux hosts |
| Linux distributions (arm64) | Raspberry Pi OS | Yes — native on Apple Silicon, `podman` on Linux hosts |
| Excluded | FreeBSD 15 only | Zero-length files only; do not modify |
| Generic FreeBSD | `prompts/freebsd/` (C++ only) | Non-zero — generic 14.x/15.x FreeBSD C++ build spec for SSH-based remote builds |
| Implemented (Linux-hosts-only) | Arch Linux | Yes — `podman` on Linux hosts; macOS skip with logging

> **Debian vs. Raspberry Pi OS:** Both share `ID=debian` in `/etc/os-release`. They are distinguished by the presence of `/etc/rpi-issue`: if it exists, this is Raspberry Pi OS; otherwise, stock Debian. See `prompts/common/session_hints.md` for the full detection logic.

**macOS is native-only.** It never uses containers, Dockerfiles, or `container` targets. All builds and tests run on the host using native toolchains (Clang, `make`, `ar`).

**Linux distro testing on macOS host:** When running regression tests for Linux distributions (Fedora, Debian, Ubuntu, Raspberry Pi OS) from a macOS host, tests MUST run inside the target OS container — never natively on macOS. The `container` command (Apple Container) is used to execute `make verify` inside the `ringbuffer_<os>_test` container. The library is built in a separate `_build` container and the test directory (with Makefile, data, utils) is mounted into the `_test` container. This ensures `readelf`, `g++`, and other Linux-specific tools are available during verification.

<!-- RULES-LOAD: macos -> rules/macos-containers.md -->
### Language Version Requirements
| Language | Primary Version | Fallback Versions (priority order) | Minimum Supported |
|----------|-----------------|-----------------------------------|-------------------|
| **C** | C23 | C17, C11 | ✅ Common spec created |
| **C++** | C++20 | C++17 | *(already in place)* |
| **Java** | Java SE 25 (JDK 25) | SE 24, 23, 22, 21, 20, 19, 18, 17 | ✅ Common spec created |
| **Go** | Go 1.24 | Go 1.23, 1.22 | ✅ Common spec created |
| **Python** | Python 3.14 | 3.13, 3.12, 3.11, 3.10 | ✅ Common spec created |
| **Rust** | 1.84.0 | 1.56.0 (fallback) | ✅ Common spec created |

### Language Classification (Platform Sensitivity)
| Category | Languages | Prompt Structure | Rationale |
|----------|-----------|-----------------|-----------|
| **Platform-sensitive** | `c`, `cpp` | Common spec + per-OS overrides. Source code differs across platforms (threading, I/O, build flags). | Requires platform-specific concurrency primitives (`pthread` on both but different threading library availability), I/O multiplexing (`epoll` vs `kqueue`), and build flags (shared lib naming, linker options, universal binary on macOS). |
| **Platform-insensitive** | `python`, `java`, `go`, `rust` | Single common spec. Per-OS directories contain placeholder text in `build.md`, `functional.md`, and `testing.md` (pointing to the common spec). Source code is identical everywhere. | Standard library abstracts platform differences; build config (`Cargo.toml`, `pom.xml`, `go.mod`) is identical across platforms. Python implementation is **pure Python** (no C-extension wrapping). Rust uses Unix-family abstractions (`std::sync::atomic`, `std::thread`, `libc`) that work identically on macOS and Linux. |

### Language-Specific Build Systems
| Language | Build System | Artifact Output |
|----------|-------------|-----------------|
| C/C++ | GNU Make (`Makefile`) | `lib/libswtr_ringbuffer-<version>.{a|so|dylib}` |
| Java | Apache Maven (`pom.xml`) | `target/ringbuffer-<version>.jar` |
| Go | Go Modules (`go.mod`) | `lib/libringbuffer.{a|so|dylib}` (via `-buildmode=c-{archive,shared}`) |
| Python | None (interpreted) | Depends on C library shared object (`libswtr_ringbuffer.so`/`.dylib`) |
| Rust | Cargo (`Cargo.toml`) | `target/release/libswtr_ringbuffer.{a,so|dylib}` (via `crate-type = ["staticlib", "cdylib"]`) |

### Prompt Syntax for Adding Languages
The basic prompt syntax is: `add <language> to <os>`

**MANDATORY — Build/Test Pattern for Every New OS/Language:** When adding a new OS or language, you MUST create the following Makefile targets:

1. **`<os>/<lang>/Makefile all`** — Build target (used by `verify_build`). Must:
   - Compile/package the language source
   - Create versioned artifacts (e.g., `libswtr_ringbuffer-1.0.0.a`)
   - Create symlinks from unversioned names to versioned artifacts (e.g., `libswtr_ringbuffer.a` → `libswtr_ringbuffer-1.0.0.a`)
   - **Never** run tests

2. **`<os>/<lang>/tests/Makefile verify`** — Test target (used by `run_regression`). Must:
   - Run the full T001-T007 test matrix
   - Compare output against expected results
   - Generate JUnit XML and Markdown reports
   - The `tests/Makefile` must also have a `test: verify` target so `make test` works

3. **Main Makefile** must have: `test: all` → calls `$(MAKE) -C tests verify`

**Golden rule:** `verify_build` uses `<os>/<lang>/Makefile all`. `run_regression` uses `tests/Makefile verify`. Never cross these boundaries.

- **Inferred**: Ringbuffer implementation for the specified language on the target OS
- **Platform-sensitive routing** (`c`, `cpp`): Reads common spec + per-OS overrides, generates platform-specific source, performs cross-platform symmetry verification between Linux distros
- **Platform-insensitive routing** (`python`, `java`, `go`, `rust`): Reads single common spec, generates identical source for all platforms, no cross-platform symmetry needed
- **Supported languages**: `c`, `cpp`, `python`, `java`, `go`, `rust`
- **Excluded platforms**: FreeBSD 15 only — do not add languages to this platform
- **Arch Linux**: C++ fully implemented, tested on both g++ and clang++ (`prompts/archlinux/cpp/`); Linux-hosts-only (macOS skip with logging)

### Shared Behavioral Contract (All Languages)
Every implementation must satisfy these requirements regardless of language:
- **Three-stage pipeline**: Independent read, transform, and write stages operating on a shared pool of buffer slots
- **Status-driven coordination**: Slots transition through states (`readyforread` → `readyfortransform` → `readyforwrite` → `readyforread`)
- **Cooperative cancellation**: Pipeline stages must support graceful shutdown via a stop signal / equivalent mechanism
- **Error handling**: An error handler callback that returns non-zero to trigger pipeline shutdown
- **EOF detection**: When read returns EOF (0 bytes), the pipeline must propagate `LAST_BUFFER_TO_TRANSFORM` → `LAST_BUFFER_TO_WRITE` through all stages, then terminate cleanly
- **Transform in-place**: The transform function receives the slot's data buffer and modifies it directly; `transformed_data_buffer_size` must be updated with the result size
- **Test compliance**: All implementations must pass the 7-test matrix (see below)

### Test Matrix (Ground Truth — All Languages)
| Test | Config | Expected Exit | Output Match? |
|------|--------|---------------|---------------|
| T001 | Default (identity transform) | 0 | Yes — output == input |
| T002 | 1 slot, 1-byte buffer (stress) | 0 | Yes — output == input |
| T003 | Uppercase transform | 0 | Yes — output matches expected |
| T004 | Small input, fast EOF | 0 | Yes — output == input |
| T005 | Fatal error mode | **1** | Not checked (partial output) |
| T006 | Non-fatal error mode | 0 | Yes — output == input |
| T007 | XOR transform | 0 | Yes — output matches expected binary data |

## 6. Implementation Plan

### Current State (As of Session)
| Component | Status |
|-----------|--------|
| C++ (macOS) | ✅ Fully implemented, tested, bug-fixed (transform in-place) |
| C++ (Linux distros) | ✅ Byte-identical across Fedora/Debian/Ubuntu |
| C++ (Arch Linux) | ✅ Fully implemented, tested on both g++ and clang++ (multi-compiler Makefile with auto-detection) |
| C++ common specs | ✅ `prompts/common/cpp/functional.md`, `build.md` complete |
| Java common specs | ✅ `prompts/common/java/functional.md`, `build.md` created |
| Go common specs | ✅ `prompts/common/go/functional.md`, `build.md` created |
| C common specs | ✅ `prompts/common/c/functional.md` (21,810 bytes), `build.md` (10,247 bytes) created |
| Python common specs | ✅ `prompts/common/python/functional.md` (22,797 bytes), `build.md` (7,028 bytes) created |
| Rust common specs | ✅ `prompts/common/rust/functional.md` (23,398 bytes), `build.md` (6,141 bytes) created |
| `add <lang> to <os>` dispatcher prompt | ✅ `prompts/common/add_language.md` (23,258 bytes) created — Phase 2 complete |
| Per-OS language directories | ✅ Placeholder files exist for all languages/OSes (macos, fedora, debian, ubuntu, archlinux, raspios) — `build.md`, `functional.md`, `testing.md` all contain non-zero placeholder text pointing to common specs. FreeBSD 15 remains zero-length only (excluded). All languages have placeholders on all OSes. C/C++ per-OS prompts contain full platform-specific specs including `create_functional.md`, `update_*` variants, and `create_testing.md`. |
| `reference_linux` scaffolding | ✅ Complete — non-zero placeholder text exists for C, Go, Python, Rust (`build.md`, `functional.md`, `testing.md`). |

### Implementation Phases

#### Phase 1: Complete Common Specs ✅ COMPLETE
All common spec files have been created:
1. **C**: `prompts/common/c/functional.md` (21,810 bytes), `build.md` (10,247 bytes) — C23 primary, C17/C11 fallback. Platform-sensitive (follows C++ pattern with per-OS overrides).
2. **Python**: `prompts/common/python/functional.md` (22,797 bytes), `build.md` (7,028 bytes) — Python 3.14 primary, fallback to 3.10/3.12/3.13. Pure Python (no C-extension wrapping), uses `ctypes` to load shared library.
3. **Rust**: `prompts/common/rust/functional.md` (23,398 bytes), `build.md` (6,141 bytes) — Rust 1.84.0 primary, 1.56.0 fallback. Platform-insensitive (Unix family covers macOS + Linux).

Each common spec defines:
- Language-specific API surface (idiomatic to the language)
- How the 3-stage pipeline maps to that language's concurrency model
- The error handling contract (ErrorHandler callback)
- How the 7-test matrix is satisfied
- File organization and naming conventions
- Build system configuration (Makefile, pom.xml, go.mod, Cargo.toml)
- Version reporting requirements in functional.log and build.log

#### Phase 2: Finalize Dispatcher Prompt ✅ COMPLETE
Created `prompts/common/add_language.md` (23,258 bytes) — the unified entry point for `add <lang> to <os>`:
- Validates language (`c`, `cpp`, `python`, `java`, `go`, `rust`) and OS (`macos`, `fedora`, `debian`, `ubuntu`) inputs
- Classifies language as platform-sensitive (`c`, `cpp`) or platform-insensitive (`python`, `java`, `go`, `rust`)
- Routes to appropriate workflow: common spec + per-OS overrides vs. single common spec
- Detects available compiler/language version with fallback support
- Creates `version.mk` as the **single source of truth** for all languages (Step 3.1.5)
- Generates source code to `src/<os>/<lang>/` independently (no copying between platforms)
- Creates test infrastructure: native-language test binary, input data, expected outputs
- Generates implementation report with version reporting in `functional.log` and `build.log`
- Includes comprehensive error handling for missing specs, toolchains, and version requirements
- **Version propagation**: All languages derive version from `version.mk` — each has a specific mechanism:
  - C/C++: Makefile `include version.mk` (direct)
  - Java: `version.sh` reads `version.mk`, injects into `pom.xml` as Maven properties
  - Go: `version.sh` reads `version.mk`, generates `version.go` with typed constants
  - Python: `version.sh` reads `version.mk`, generates `version.py` with module constants
  - Rust: `build.rs` reads `version.mk`, generates `src/version.rs` with constants

#### Phase 3: Implement Languages on Platforms
For each language, implement on all target OSes:
1. **C**: Implement on macOS (native), Fedora, Debian, Ubuntu, Arch Linux (Linux-hosts-only), Raspberry Pi OS
2. **Java**: Implement on macOS (native), Fedora, Debian, Ubuntu, Arch Linux (Linux-hosts-only), Raspberry Pi OS
3. **Go**: Implement on macOS (native), Fedora, Debian, Ubuntu, Arch Linux (Linux-hosts-only), Raspberry Pi OS
4. **Python**: Implement on macOS (native), Fedora, Debian, Ubuntu, Arch Linux (Linux-hosts-only), Raspberry Pi OS
5. **Rust**: Implement on macOS (native), Fedora, Debian, Ubuntu, Arch Linux (Linux-hosts-only), Raspberry Pi OS

Each implementation must:
- Generate source code from the common spec (independently, no copying)
- Pass all 7 tests in the test matrix
- For platform-sensitive languages (C): maintain cross-platform symmetry between Linux distros
- For platform-insensitive languages: source is identical across all platforms
- **Always report the actual compiler/language version used** — detect and log the exact version of the language toolchain available on the target platform (e.g., `clang++ 18.1.8`, `javac 25.0.1`, `go version go1.24.0 darwin/arm64`, `rustc 1.84.0`). If the primary version is not available, detect the highest fallback version that IS available and report it. This must be recorded in:
  - `functional.log` at the start of implementation: `[timestamp] Language=<lang> Version=<detected_version> (primary was <primary_version>)`
  - `build.log` at the start of build: `[timestamp] Compiler=<compiler_name> Version=<detected_version>`
  - The implementation report header: `**Language Version:** <actual_detected_version> (primary target was <primary_version>)`
- If the detected version is below the minimum supported version for that language, STOP and report: `ERROR: Detected <lang> version <detected_version> is below minimum supported <minimum_version>. Cannot proceed.`

##### Phase 3 Sub-Steps (Per Language)
Each language implementation follows these sub-steps:

**3.A — Create `version.mk` (All Languages)**
Create `src/<os>/<lang>/version.mk` as the single source of truth:
```makefile
MAJOR=1
MINOR=0
SUBVERSION=0
BUILD_ID=1
```
All 6 languages derive version from this file — no language defines its own version independently.

**3.B — Create Version Propagation Scripts (Non-C/C++ Languages)**
Generate scripts that read `version.mk` and produce language-specific version files:
| Language | Script | Output |
|----------|--------|--------|
| Java | `version.sh` | Injects `<major>`, `<minor>`, `<subversion>`, `<build_id>` into `pom.xml` |
| Go | `version.sh` | Generates `version.go` with typed constants (`Major`, `Minor`, `SubVersion`, `BuildId`, `Version string`) |
| Python | `version.sh` | Generates `version.py` with module-level constants (`MAJOR`, `MINOR`, `SUBVERSION`, `BUILD_ID`, `VERSION`) |
| Rust | `build.rs` | Generates `src/version.rs` with typed constants, or sets env vars for compile-time injection |

**3.C — Generate Source Code from Common Spec**
- Platform-sensitive (C, C++): Read common spec + per-OS overrides → generate platform-specific source
- Platform-insensitive (Python, Java, Go, Rust): Read single common spec → generate identical source for all platforms
- **Do NOT copy files between platforms** — each platform generates independently from the shared spec

**3.D — Generate Build Configuration**
- C/C++: GNU Make (`Makefile`) with `include version.mk`
- Java: Maven (`pom.xml`) with version properties injected from `version.sh`
- Go: Go Modules (`go.mod`) + `version.go` generated from `version.sh`
- Python: No build system; `version.py` generated from `version.sh`; verify shared library loads via `ctypes`
- Rust: Cargo (`Cargo.toml`) + `build.rs` reads `version.mk`, generates `src/version.rs`

**3.E — Create Test Infrastructure**
- Generate test binary in native language (not shared C++ harness)
- Create input data and expected outputs for T001-T007
- Test binary reads stdin, writes stdout, exits 0 on success / 1 on fatal error

**3.F — Build and Verify Artifacts**
- Execute language-appropriate build commands
- Verify expected artifacts exist (libraries, JARs, etc.)
- Log results to `build.log`

**3.G — Generate Implementation Report**
- Create `src/<os>/<lang>/reports/implementation_report.md`
- Include detected version, files generated, build verification results

##### Risk Notes for Phase 3
- **C per-OS overrides are placeholders**: All C per-OS `build.md`, `functional.md`, and `testing.md` files contain placeholder text pointing to common specs (non-zero). Unlike C++ (which has ~6KB per-OS overrides with real platform-specific content), C implementation will be more speculative. The common spec covers all platform differences, but there is no per-OS reference to validate against.
- **Non-C++ source code exists**: `src/common/python/` and `src/common/java/` have full source code. Go, Rust, and C source directories do not yet exist — those languages will be generated from specs alone.
- **Reference Linux scaffolding complete**: Non-zero placeholder files exist for C, Go, Python, Rust in `reference_linux/`.

#### Phase 4: Verification and Documentation
1. Run `verify_binary_symmetry.sh` for C (Linux distros)
2. Run `lint_prompts.sh` to validate prompt structure
3. Update project README with multi-language support documentation
4. Generate PDF documentation with `pandoc`
5. ~~Create `reference_linux` scaffolding~~ — **Already complete** (non-zero placeholder files exist for C, Go, Python, Rust)
6. Clarify utility scripts scope — determine if `prompts/common/cpp/utils/bin/` scripts are language-agnostic or C++-specific

##### Phase 4 Sub-Steps
**4.A — Reference Linux Scaffolding** — **Already complete.** Non-zero placeholder files exist in `prompts/reference_linux/c/`, `go/`, `python/`, and `rust/`.

**4.B — Utility Scripts Scope Review**
The existing utility scripts in `prompts/common/cpp/utils/bin/` are:
| Script | Purpose | Language-Agnostic? |
|--------|---------|--------------------|
| `generate_test_data.*` | Generate test input/expected output files | **Yes** — test data is language-independent |
| `generate_junit_report.*` | Generate JUnit XML reports from test results | **No** — C++ specific (JUnit format) |
| `verify_test_data.*` | Validate test data integrity | **Yes** — language-independent |
| `verify_binary_symmetry.*` | Compare source files across Linux platforms | **Yes** — language-independent |
| `lint_prompts.*` | Validate prompt directory structure | **Yes** — language-independent |

Recommendation: Move language-agnostic scripts to `prompts/common/utils/bin/` (no `/cpp/` subdirectory). Keep C++-specific scripts in `prompts/common/cpp/utils/bin/`.

**4.C — README Update**
Update project README to document:
- Multi-language support (C, C++, Java, Go, Python, Rust)
- Language classification (platform-sensitive vs platform-insensitive)
- Version propagation from `version.mk` to each language
- Build system per language (Make, Maven, Go Modules, Cargo)
- Test matrix T001-T007 applies to all languages

### Core Principle — Library-First Flexibility
Ringbuffer is designed as a library, not an application. Every API design decision should be evaluated against this principle:
- **Consumer flexibility > API simplicity:** If a choice gives consumers more power at the cost of a larger API surface, choose flexibility.
- **No hidden abstractions:** Consumers should be able to observe and control state at any granularity without requiring wrapper code or reflection.
- **Opt-in complexity:** Basic usage should be simple (construct, set transform, start), but advanced usage must not require extending the library.
- **Stable contract:** The abstract class interface is a public API contract. Breaking changes require major version bumps.

### Key Constraints
- **Transform bug is fixed**: All implementations must use in-place transform (modify `slot.data` directly)
- **Test matrix is ground truth**: All implementations must pass T001-T007
- **Cross-platform symmetry**: Only applies to platform-sensitive languages between Linux distros
- **macOS is native-only**: No containers, no Dockerfiles for any language on macOS
- **Excluded platforms**: FreeBSD 15 only — zero-length files only
- **Arch Linux C++**: Fully implemented, tested on both g++ and clang++; source generation requires a Linux host
- **Language standards are binding**: Each implementation must target the primary version with fallback support as specified in Section 5
- **Version reporting is mandatory**: Every implementation MUST detect and report the actual compiler/language version in use. This enables traceability — if a platform only has Java SE 17, the implementation must report that fact rather than silently targeting Java SE 25. The version must appear in `functional.log`, `build.log`, and the implementation report.

### Cross-Platform Generation Mandate
All platform source code MUST be generated **independently** from the common specification. Do NOT copy source files, Makefiles, or Dockerfiles between platforms. Each platform generates its own artifacts from the shared spec, then cross-platform verification checks for byte-identical output (minus allowed differences).

**Allowed Makefile differences:**
1. `CONTAINER_IMAGE` variable value
2. Working directory path in container run commands
3. Host distro detection check

**Allowed Dockerfile differences:**
1. `FROM` base image line
2. Package installation RUN blocks (platform-specific package managers)

### Excluded Platforms
FreeBSD 15 is excluded from active development. Its prompt directories contain explicit exclusion messages (`build.md`, `functional.md`, `testing.md` all state: "Excluded platform — do not modify"). If any non-zero content exists beyond these exclusion messages, remove it.

FreeBSD 14 C++ is implemented and verified (static library only). Its prompt directories contain placeholder text pointing to `prompts/freebsd/cpp/` (generic FreeBSD 14.x/15.x spec) and `prompts/common/cpp/` (common specs). Java is implemented on FreeBSD 14 — BSD make override at `src/freebsd14/java/Makefile`, source from `src/common/java/`. Python is implemented on FreeBSD 14 — Pure Python only (Concurrent skipped due to RPATH limitation). C, Go, and Rust per-OS prompt directories contain non-zero placeholder text pointing to common specs — this is allowed and recommended to prevent zero-length file confusion.

<!-- RULES-LOAD: freebsd14 -> rules/freebsd-shell.md -->
<!-- RULES-LOAD: freebsd14 -> rules/tcsh-syntax.md -->
<!-- RULES-LOAD: archlinux -> rules/archlinux-containers.md -->
<!-- RULES-LOAD: ssh-transfer -> rules/ssh-transfer.md -->

### Python Makefiles by Family (GNU vs BSD)
 Family (GNU vs BSD)
The Python implementation uses different Makefile syntax for GNU make and BSD make systems:
- **GNU make** (macOS, Linux): `src/common/python/Makefile.gnu` — uses `$(shell ...)`, `ifeq/else`
- **BSD make** (FreeBSD 14+): `src/<os>/python/Makefile` — per-OS directory with BSD-compatible syntax (no `$(shell)`, no `ifeq/else`)
- **Common source**: Both use the same Python source files from `src/common/python/` (swtr_ringbuffer_pure.py, test scripts, base types)
- **Per-platform overrides**: FreeBSD 14 has `src/freebsd14/python/` with its own Makefile and copies of common source. FreeBSD 15 will use the same structure.
- **Makefile selection**: The agent must select the correct Makefile based on the target OS family (GNU vs BSD).


<!-- RULES-LOAD: macos -> rules/macos-containers.md -->
<!-- RULES-LOAD: verify-build -> rules/verify-build-workflow.md -->
