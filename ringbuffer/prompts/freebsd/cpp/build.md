# Build Requirements - Ringbuffer (FreeBSD, C++)

**Implementation Directive:**
This build specification MUST follow the common build specification exactly to ensure binary symmetry across platforms. Platform-specific deviations are permitted only for toolchain specifics and binary format requirements.

Refer to [prompts/common/cpp/build.md](../../common/cpp/build.md) for all shared requirements.

Refer to [prompts/common/cpp/build.md](../../common/cpp/build.md) for the Platform and Container Runtime Reference before planning any build operation.

## Platform Specifics
- **Target Environment**: FreeBSD 14.x or 15.x (amd64/x86_64)
- **Compiler**: FreeBSD clang++ (only compiler available — no g++)
- **Binary Format**: ELF `.so` with SONAME (not Mach-O)

## SSH Key Requirement
**Prerequisite:** The user MUST have SSH keys installed on the remote FreeBSD system before execution. This prompt uses key-based authentication — password auth is NOT supported. The caller must ensure:
```bash
ssh-copy-id <user>@<hostname_or_ip>
```
has been run from the host system. The agent constructs commands as `ssh <user>@<host> ...` with no password prompts.

## Required Tools
- `clang++` (Compiler/Linker) — FreeBSD clang 19.x or later
- `make` (FreeBSD make, NOT GNU make)
- `ar` (Archiver — for `.a` static libraries)
- `/usr/local/bin/bash` (for commands requiring subshell grouping — tcsh is the default shell and lacks `{ }` support)
- `readelf` or `file` (binary analysis)

## FreeBSD Binary Requirements
### Compilation
- Single architecture only — no universal binaries. No `-arch` flags, no `lipo`.
- Use `-pthread` flag for all compilations (FreeBSD clang requires it for `std::thread`).

### Linking
- **Static Library**: Use `ar rcs` (not macOS `libtool -static`).
- **Shared Library**: Use `-shared -Wl,-soname,<SONAME>` (not macOS `@rpath` install names).
- **RPATH**: Use `$ORIGIN/../lib` (FreeBSD/ELF convention, NOT macOS `@executable_path`).

### Artifact Naming
- Static: `libswtr_ringbuffer-<version>.a` (symlinked from `libswtr_ringbuffer.a`)
- Shared: `libswtr_ringbuffer-<version>.so` (symlinked from `libswtr_ringbuffer.so`, SONAME = `libswtr_ringbuffer.so`)

## C++20 Support Matrix (FreeBSD clang 19.x)
| Feature | Available? | Notes |
|---------|-----------|-------|
| `<format>` | ✅ Yes | Compiles cleanly |
| `<thread>` | ✅ Yes | Requires `-pthread` flag |
| `<atomic>` | ✅ Yes | `std::atomic<bool>` works for stop flags |
| `<stop_token>` header file | ⚠️ Partial | Header exists but `std::stop_token`/`std::stop_source` types are NOT implemented |
| `<jthread>` | ❌ No | `fatal error: 'jthread' file not found` — must use manual stop flag pattern |

## Shell Environment
- **Default shell**: tcsh 6.x — does NOT support `{ }` grouping syntax, `$?` is make's automatic variable
- **bash**: Available at `/usr/local/bin/bash` — use for commands needing subshell grouping or `$?` exit code capture
- **zsh**: NOT installed — JUnit report generation must be skipped

## Makefile Syntax
FreeBSD ships with BSD `make`, not GNU make. Key differences:
- Variable expansion: `${VAR}` (not `$(VAR)`)
- Conditionals: `.if` / `.elif` / `.else` / `.endif` (not `ifeq`/`ifdef`)
- No GNU make automatic variables like `$?` (use tcsh `$status` or bash `$?`)
- Recipe lines use tabs, same as GNU make

## Host-Target Compatibility
FreeBSD builds are **native-only**. No container support. The host OS MUST be FreeBSD; no containerized cross-compilation is supported.

## Required Makefile Targets
- `all` — build both static and shared libraries
- `static` — build static library only
- `shared` — build shared library only
- `clean` — remove object files and build artifacts
- `dist-clean` — full reset including logs and reports directories

### Linker Flags
- No `-dead_strip` (macOS) or `--gc-sections` (Linux equivalent not needed for FreeBSD ringbuffer builds)
- Use `-Wl,-soname,libswtr_ringbuffer.so` for shared library SONAME

## Verification
- **Binary Format**: Use `file lib/libswtr_ringbuffer.so` to confirm ELF format
- **SONAME**: Use `readelf -d lib/libswtr_ringbuffer.so | grep SONAME` to verify
- **Static Library**: Use `ar t lib/libswtr_ringbuffer.a | wc -l` to confirm object count
- **Test Suite**: Run `make verify` in tests/ — expect all 7 tests PASS (T001-T004, T006-T007 output match; T005 exit code 1)

## Known Limitations
- FreeBSD clang 19.x has **partial** C++20 `<stop_token>` support — header exists but types are undefined
- `std::jthread` is **not available** in FreeBSD clang 19.x — use `std::atomic<bool>` stop flag pattern
- `g++` is **not installed** — only clang++ available
- zsh is **not installed** — JUnit report generation skipped
