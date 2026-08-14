# Add Language to OS — Dispatcher Prompt

**Purpose:** This is the unified entry point for adding a new language implementation to an operating system. It validates inputs, classifies the language as platform-sensitive or platform-insensitive, routes to the appropriate workflow, and generates source code with test infrastructure.

**Prompt Syntax:** `add <language> to <os>`
- **`<language>`**: One of `c`, `cpp`, `python`, `java`, `go`, `rust`
- **`<os>`**: One of `macos`, `fedora`, `debian`, `ubuntu`
- **Inferred**: Ringbuffer implementation for the specified language on the target OS

---

## 1. Input Validation

### Step 1.1: Validate Language
Verify `<language>` is one of the supported languages:

| Language | Platform-Sensitive? | Common Spec Path |
|----------|---------------------|------------------|
| `c` | Yes | `prompts/common/c/functional.md`, `build.md` |
| `cpp` | Yes | `prompts/common/cpp/functional.md`, `build.md` |
| `python` | No | `prompts/common/python/functional.md`, `build.md` |
| `java` | No | `prompts/common/java/functional.md`, `build.md` |
| `go` | No | `prompts/common/go/functional.md`, `build.md` |
| `rust` | No | `prompts/common/rust/functional.md`, `build.md` |

If the language is not in this list, STOP and report:
```
ERROR: Unsupported language '<language>'. Supported languages: c, cpp, python, java, go, rust
```

### Step 1.2: Validate OS
Verify `<os>` is one of the supported platforms:

| Platform | Container Support? | Notes |
|----------|-------------------|-------|
| `macos` | Native only | All builds run natively on the host |
| `fedora` | Yes (podman / docker) | Linux distribution; native containers |
| `debian` | Yes (docker / podman) | Linux distribution; native containers |
| `ubuntu` | Yes (docker / podman) | Linux distribution; native containers |

If the OS is not in this list, STOP and report:
```
ERROR: Unsupported platform '<os>'. Supported platforms: macos, fedora, debian, ubuntu
```

### Step 1.3: Check Excluded Platforms
Verify `<os>` is NOT one of the excluded platforms (FreeBSD 14, FreeBSD 15, ArchLinux). If it is:
```
ERROR: Platform '<os>' is excluded from active development. Do not add languages to this platform.
```

---

## 2. Language Classification and Routing

### Step 2.1: Classify Platform Sensitivity
Based on the language, determine the routing strategy:

**Platform-Sensitive Languages** (`c`, `cpp`):
- Source code differs across platforms (threading, I/O, build flags)
- Read common spec (`prompts/common/<lang>/functional.md`, `build.md`)
- Read per-OS override files (`prompts/<os>/<lang>/functional.md`, `build.md`)
- Generate platform-specific source code to `src/<os>/<lang>/`
- For Linux distros: use containers (podman/docker) to verify the build and tests
- For macOS: run natively on the host
- Cross-platform symmetry verification between Fedora, Debian, Ubuntu

**Platform-Insensitive Languages** (`python`, `java`, `go`, `rust`):
- Source code is identical across all platforms
- Read single common spec (`prompts/common/<lang>/functional.md`, `build.md`)
- Per-OS override files are zero-length (no platform-specific content)
- Generate source code to `src/common/<lang>/` (single shared directory, not per-OS)
- **Run natively on the host OS** — no containers needed (runtime is platform-insensitive)
- No cross-platform symmetry verification needed
- **Testing**: Verify the runtime is available on the host and run tests natively. No container testing required.

### Step 2.2: Detect Available Version
Detect the actual compiler/language version available on the target platform:

| Language | Detection Command | Primary Version | Fallback Versions |
|----------|-------------------|-----------------|-------------------|
| C/C++ | `clang --version` or `gcc --version` | C23 (C++) | C17, C11 |
| Python | `python3 --version` | 3.14 | 3.13, 3.12, 3.11, 3.10 |
| Java | `javac -version` | SE 25 | SE 24, 23, 22, 21, 20, 19, 18, 17 |
| Go | `go version` | 1.24 | 1.23, 1.22 |
| Rust | `rustc --version` | 1.84.0 | 1.56.0 |

**Version Detection Rules:**
1. Try the primary version first
2. If not available, try fallback versions in priority order
3. Report the detected version in `functional.log` and `build.log`:
   ```
   [timestamp] Language=<lang> Version=<detected_version> (primary was <primary_version>)
   [timestamp] Compiler=<compiler_name> Version=<detected_version>
   ```
4. If the detected version is below the minimum supported version, STOP and report:
   ```
   ERROR: Detected <lang> version <detected_version> is below minimum supported <minimum_version>. Cannot proceed.
   ```

---

## 3. Source Code Generation

### Step 3.1: Create Directory Structure
Create the target directory for source code:

```bash
mkdir -p src/<os>/<lang>/
```

Directory structure varies by language:

**C/C++:**
```
src/<os>/<lang>/
├── status.h / status.hpp          // Enum definitions
├── ringbuffer.h / ringbuffer.hpp  // Public API header
├── ringbuffer.c / ringbuffer.cpp  // Core implementation
├── swtr_ringbuffer_impl.c/.cpp    // Pipeline implementation (platform-specific)
├── Makefile                       // Build configuration
└── version.mk                     // Library version
```

**Java:**
```
src/common/java/
├── pom.xml                        // Maven build configuration (version injected from version.mk)
├── version.sh                     // Build script: reads version.mk, injects into pom.xml
├── swtr/                          // Package directory
│   ├── BufferStatus.java
│   ├── ChecksumAlgorithm.java
│   ├── LogLevel.java
│   ├── RingBuffer.java
│   ├── TransformFunction.java
│   ├── ErrorHandler.java
│   ├── BufferSlot.java
│   └── SwtrRingBuffer.java
└── swtr/test/                     // Test binary (single file)
    └── TestRingbuffer.java
```

**Go:**
```
src/<os>/go/
├── go.mod                         // Go module definition
├── version.sh                     // Build script: reads version.mk, generates version.go
└── swtr.go                        // All source code (package swtr)
```

**Python:**
```
src/common/python/
├── swtr_ringbuffer.py             // Complete implementation (BufferSlot, SwtrRingBuffer)
├── __init__.py                    // Package init (exports public API)
├── version.py                     // Version constants (generated from version.mk)
└── test_ringbuffer.py             // Test binary (7-test matrix)
```

**Rust:**
```
src/<os>/rust/
├── Cargo.toml                     // Rust package manifest (version injected from version.mk)
├── build.rs                       // Build script: reads version.mk, generates version.rs
└── src/
    ├── lib.rs                     // Library root (all implementation)
    └── main.rs                    // Test binary entry point
```

### Step 3.1.5: Create version.mk (C/C++ Only)
For C and C++ implementations, create `src/<os>/<lang>/version.mk` with the following content:

```makefile
MAJOR=1
MINOR=0
SUBVERSION=0
BUILD_ID=1
```

**Rules:**
- This file is the **single source of truth** for version numbers across ALL languages
- The format is `KEY=VALUE` (no spaces around `=`) — this is GNU Make syntax
- The `VERSION` variable is computed by the Makefile as `$(MAJOR).$(MINOR).$(SUBVERSION)-$(BUILD_ID)`
- **Do NOT include a `VERSION` line in version.mk** — it is computed by the Makefile
- All implementations on all platforms use identical `version.mk` content (library version, not OS version)
- **All languages reference `version.mk` as the source of truth** — each language's build config derives its version from it:
  - **C/C++**: Makefile sources `version.mk` directly via `include version.mk`
  - **Java**: Build script reads `version.mk` and injects values into `pom.xml` (`<major>`, `<minor>`, `<subversion>`, `<build_id>` properties)
  - **Go**: Build script reads `version.mk` and generates a `version.go` file with constants (`Major`, `Minor`, `SubVersion`, `BuildId`, `Version string`)
  - **Python**: Build script reads `version.mk` and generates a `version.py` module with constants (`MAJOR`, `MINOR`, `SUBVERSION`, `BUILD_ID`, `VERSION`)
  - **Rust**: Build script reads `version.mk` and generates a `version.rs` file with constants (`MAJOR`, `MINOR`, `SUBVERSION`, `BUILD_ID`, `VERSION`), or uses a build script (`build.rs`) to read it at compile time
- **No language defines its own version independently** — all derive from `version.mk`

### Step 3.2: Generate Source Code from Common Spec
Generate source code independently from the common specification. **Do NOT copy files between platforms.**

**For Platform-Sensitive Languages (C, C++):**
1. Read the common spec (`prompts/common/<lang>/functional.md`, `build.md`)
2. Read the per-OS override file (`prompts/<os>/<lang>/functional.md`, `build.md`)
3. Generate platform-specific source code that satisfies both the common spec and per-OS overrides
4. The common spec defines the behavioral contract, API surface, and test matrix
5. The per-OS override file defines platform-specific threading primitives, I/O calls, and build flags

**For Platform-Insensitive Languages (Python, Java, Go, Rust):**
1. Read the common spec (`prompts/common/<lang>/functional.md`, `build.md`)
2. Generate identical source code for all platforms
3. Per-OS override files are zero-length (no platform-specific content)

### Step 3.3: Generate Build Configuration
Generate the build system configuration based on the language. **All version numbers derive from `version.mk`** (the single source of truth).

**C/C++:** GNU Make (`Makefile`)
- Compiler flags from common spec + per-OS overrides
- Shared library naming: `.so` (Linux) or `.dylib` (macOS)
- Universal binary support on macOS (`lipo`)
- Makefile sources `version.mk` via `include version.mk`

**Java:** Apache Maven (`pom.xml`)
- Group ID: `com.swtr`
- Artifact ID: `ringbuffer`
- Version injected from `version.mk` via `version.sh` build script
  - Script reads `MAJOR`, `MINOR`, `SUBVERSION`, `BUILD_ID` from `version.mk`
  - Injects into `pom.xml` as `<major>`, `<minor>`, `<subversion>`, `<build_id>` properties
  - Computes `VERSION` as `${major}.${minor}.${subversion}-${build_id}`

**Go:** Go Modules (`go.mod`)
- Module path: `github.com/swtr/ringbuffer`
- Version generated from `version.mk` via `version.sh` build script
  - Script reads `MAJOR`, `MINOR`, `SUBVERSION`, `BUILD_ID` from `version.mk`
  - Generates `version.go` with typed constants and a formatted `Version string`

**Python:** None (interpreted)
- No build configuration needed for the library itself
- Version generated from `version.mk` via `version.sh` build script
  - Script reads `MAJOR`, `MINOR`, `SUBVERSION`, `BUILD_ID` from `version.mk`
  - Generates `version.py` with module-level constants
- Verify shared library loading via `ctypes`

**Rust:** Cargo (`Cargo.toml`)
- Package name: `ringbuffer`
- Crate type: `["staticlib", "cdylib"]`
- Version injected from `version.mk` via `build.rs` build script
  - Script reads `MAJOR`, `MINOR`, `SUBVERSION`, `BUILD_ID` from `version.mk`
  - Generates `src/version.rs` with typed constants and a formatted `VERSION` string
  - Or uses `build.rs` to read `version.mk` at compile time and set environment variables

---

## 4. Test Infrastructure Generation

### Step 4.1: Create Test Binary
Each language MUST get its own test binary in native language, serving as an implementation example.

**Test Binary Requirements:**
- Written in the target language (not a shared C++ test harness)
- Exercises the 7-test matrix (T001-T007)
- Reads input from stdin, writes output to stdout
- Supports configuration via command-line arguments (number of slots, buffer size, transform type)
- Exits with code 0 on success, 1 on fatal error

**Test Binary Locations:**
| Language | Location |
|----------|----------|
| C/C++ | `src/<os>/<lang>/tests/src/test_ringbuffer.c/.cpp` |
| Java | `src/common/java/swtr/test/TestRingbuffer.java` (single file, CLI dispatches to T001-T007) |
| Go | `src/common/go/swtr_test.go` |
| Python | `src/common/python/test_ringbuffer.py` (single file, CLI dispatches to T001-T007) |
| Rust | `src/common/rust/src/main.rs` (compiled via `cargo run --bin ringbuffer_test`) |

### Step 4.2: Create Test Data
Generate test input data and expected output files:

```
src/<os>/<lang>/tests/
├── data/
│   ├── inputs/                    // Test input files
│   │   ├── t001_input.txt         // Default (identity transform)
│   │   ├── t002_input.txt         // Stress test (1 slot, 1-byte buffer)
│   │   ├── t003_input.txt         // Uppercase transform input
│   │   ├── t004_input.txt         // Small input, fast EOF
│   │   ├── t005_input.txt         // Fatal error mode input
│   │   ├── t006_input.txt         // Non-fatal error mode input
│   │   └── t007_input.txt         // XOR transform input
│   └── expected/                  // Expected output files
│       ├── t001_out.txt           // == input (identity)
│       ├── t002_out.txt           // == input (stress)
│       ├── t003_out.txt           // Uppercase of input
│       ├── t004_out.txt           // == input (small, EOF)
│       ├── t005_out.txt           // Not checked (partial output)
│       ├── t006_out.txt           // == input (non-fatal error)
│       └── t007_out.txt           // XOR of input (binary data)
├── src/                           // Test source code
│   └── test_ringbuffer.<ext>      // Test binary in native language
├── Makefile                       // Test build configuration (C/C++)
└── logs/                          // Test execution logs
    └── functional.log             // Test results and version info
```

### Step 4.3: Generate Expected Outputs
Expected outputs are determined by the transform type and input data:

| Test | Transform | Expected Output |
|------|-----------|-----------------|
| T001 | Identity (none) | Output == Input |
| T002 | Identity (stress: 1 slot, 1-byte buffer) | Output == Input |
| T003 | Uppercase | Output is uppercase version of input |
| T004 | Identity (small input, fast EOF) | Output == Input |
| T005 | Fatal error | Not checked (partial output) |
| T006 | Non-fatal error | Output == Input |
| T007 | XOR (with key 0xAA) | Output is XOR of input with 0xAA (binary data) |

---

## 5. Build and Verification

### Step 5.1: Build the Library
Execute the build process for the target language and platform:

**C/C++:**
```bash
cd src/<os>/<lang>/
make all          # Build both static and shared libraries
```

**Java:**
```bash
cd src/common/java/
mvn compile       # Compile Java sources
mvn package       # Build JAR
```

**Go:**
```bash
cd src/<os>/go/
go build ./...    # Build all packages
```

**Python:**
```bash
cd src/common/python/
python3 -m py_compile swtr_ringbuffer.py  # Syntax check
# Verify shared library loading via ctypes
```

**Rust:**
```bash
cd src/<os>/rust/
cargo build --release  # Build in release mode
```

### Step 5.2: Verify Artifacts
Verify the build produced the expected artifacts:

| Language | Expected Artifacts |
|----------|-------------------|
| C/C++ | `lib/libswtr_ringbuffer-<version>.a`, `lib/libswtr_ringbuffer-<version>.{so|dylib}`, symlinks |
| Java | `target/ringbuffer-<version>.jar` |
| Go | `lib/libringbuffer.{a|so|dylib}` (via `-buildmode=c-{archive,shared}`) |
| Python | No artifacts produced; verify shared library loads via `ctypes` |
| Rust | `target/release/libswtr_ringbuffer.{a,so|dylib}` |

### Step 5.3: Run Tests (If Requested)
**Note:** Testing is a separate workflow. The `add <lang> to <os>` prompt does NOT automatically run tests. Testing is triggered by a separate request (e.g., "run tests" or "verify the build").

If testing is requested:
1. Execute the test binary for each test in the 7-test matrix (T001-T007)
2. Compare output against expected files in `tests/data/expected/`
3. Log results to `src/<os>/<lang>/logs/functional.log`

---

## 6. Implementation Report Generation

Generate an implementation report at `src/<os>/<lang>/reports/implementation_report.md`:

```markdown
# Implementation Report: <language> on <os>

**Generated:** [timestamp]
**Language Version:** <detected_version> (primary target was <primary_version>)
**Platform Sensitivity:** <platform-sensitive|platform-insensitive>

## Summary
- Language: <language>
- Platform: <os>
- Version Detected: <detected_version>
- Primary Target: <primary_version>
- Fallback Used: <yes/no> (if primary was not available)

## Files Generated
| File | Path | Size |
|------|------|------|
| Source | `src/<os>/<lang>/...` | <bytes> |
| Build Config | `src/<os>/<lang>/Makefile/pom.xml/go.mod/Cargo.toml` | <bytes> |
| Version Config | `src/<os>/<lang>/version.mk` (source of truth for all languages) + language-specific version file | <bytes> |
| Test Binary | `src/<os>/<lang>/tests/...` | <bytes> |
| Test Data | `src/<os>/<lang>/tests/data/...` | <bytes> |

## Build Verification
- Static Library: <exists|missing> (<path>)
- Shared Library: <exists|missing> (<path>)
- Symlinks: <created|not created>

## Test Results (If Executed)
| Test | Config | Exit Code | Output Match? |
|------|--------|-----------|---------------|
| T001 | Default (identity) | <code> | <yes/no/partial> |
| T002 | 1 slot, 1-byte buffer | <code> | <yes/no/partial> |
| T003 | Uppercase transform | <code> | <yes/no/partial> |
| T004 | Small input, fast EOF | <code> | <yes/no/partial> |
| T005 | Fatal error mode | <code> | N/A (partial output) |
| T006 | Non-fatal error mode | <code> | <yes/no/partial> |
| T007 | XOR transform | <code> | <yes/no/partial> |

## Notes
- Platform-specific details: <any per-OS overrides applied>
- Cross-platform symmetry: <verified|not applicable> (for platform-sensitive languages on Linux distros)
```

---

## 7. Logging Requirements

All actions MUST be logged to `src/<os>/<lang>/logs/build.log` and `functional.log`:

```
[timestamp] Language=<lang> Version=<detected_version> (primary was <primary_version>)
[timestamp] Compiler=<compiler_name> Version=<detected_version>
[timestamp] Platform sensitivity: <platform-sensitive|platform-insensitive>
[timestamp] Source code generated for <os>/<lang>
[timestamp] Build configuration created: <build_system> (<file>)
[timestamp] Version config created: version.mk (source of truth) + <language-specific version file>
[timestamp] Test binary generated: <path>
[timestamp] Build completed successfully (or failed with error)
```

**Timestamp Format:** `[YYYY-MM-DD HH:MM:SS +/-HHMM]`
- Use `date '+%Y-%m-%d %H:%M:%S %z'` on both Linux and macOS (BSD date supports `%z`)

---

## 8. Scope Boundaries

### What This Prompt Does
- Validates language and OS inputs
- Detects available compiler/language version
- Generates source code from common spec (independently, no copying)
- Creates test infrastructure (test binary, input data, expected outputs)
- Generates build configuration
- Produces implementation report

### What This Prompt Does NOT Do
- **Does NOT run tests** — testing is a separate workflow triggered by a separate request
- **Does NOT modify existing implementations** — each language is generated independently
- **Does NOT perform cross-platform symmetry verification** — this is done after all platforms are implemented (Phase 4)
- **Does NOT update project documentation** — README updates are done in Phase 4

### Directory Scope Restrictions
- **NEVER create, modify, or delete files inside `prompts/`** — prompts are read-only reference documents
- **NEVER modify files in `src/<other_os>/<lang>/`** — each platform is generated independently
- **NEVER modify files in `src/<os>/cpp/`** when implementing a non-C++ language
- The `tests/` directory is managed exclusively by testing-related prompts — build-only workflows must treat it as read-only

### Excluded Platforms
- **FreeBSD 14**, **FreeBSD 15**, and **ArchLinux** are excluded from active development
- Do not add languages to these platforms

---

## 9. Error Handling

### Missing Common Spec
If the common spec file does not exist for the requested language:
```
ERROR: Common spec not found for '<lang>'. Run Phase 1 to create common specs first.
Required files: prompts/common/<lang>/functional.md, prompts/common/<lang>/build.md
```

### Missing Per-OS Override (Platform-Sensitive)
If the per-OS override file does not exist for a platform-sensitive language:
```
ERROR: Per-OS override not found for '<lang>' on '<os>'.
Required file: prompts/<os>/<lang>/functional.md (zero-length files are acceptable)
```

### Missing Toolchain
If the required compiler/language toolchain is not available:
```
ERROR: Required tool '<tool>' not found in PATH. Cannot proceed with <lang> implementation on <os>.
Suggested installation: <install_command based on host OS>
```

### Version Below Minimum
If the detected version is below the minimum supported version:
```
ERROR: Detected <lang> version <detected_version> is below minimum supported <minimum_version>. Cannot proceed.
```

---

## 10. Quick Reference: Language Routing Matrix

| Language | Platform-Sensitive? | Common Spec | Per-OS Overrides? | Build System | Version Source | Test Binary Location |
|----------|---------------------|-------------|-------------------|--------------|----------------|---------------------|
| `c` | Yes | `prompts/common/c/functional.md` | Yes (`prompts/<os>/c/`) | GNU Make | `version.mk` (direct include) | `src/<os>/c/tests/src/test_ringbuffer.c` |
| `cpp` | Yes | `prompts/common/cpp/functional.md` | Yes (`prompts/<os>/cpp/`) | GNU Make | `version.mk` (direct include) | `src/<os>/cpp/tests/src/test_ringbuffer.cpp` |
| `python` | No | `prompts/common/python/functional.md` | No (zero-length) | None (interpreted) | `version.mk` → `version.py` | `src/common/python/test_ringbuffer.py` |
| `java` | No | `prompts/common/java/functional.md` | No (zero-length) | Maven | `version.mk` → `pom.xml` properties | `src/common/java/swtr/test/TestRingbuffer.java` |
| `go` | No | `prompts/common/go/functional.md` | No (zero-length) | Go Modules | `version.mk` → `version.go` | `src/<os>/go/swtr_test.go` |
| `rust` | No | `prompts/common/rust/functional.md` | No (zero-length) | Cargo | `version.mk` → `build.rs`/`version.rs` | `src/<os>/rust/src/main.rs` |

**All languages derive version from `version.mk` — it is the single source of truth.**

---

**This is the unified dispatcher prompt. Execute all steps in order, stopping at any error condition.**
