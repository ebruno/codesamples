# Artifacts - Ringbuffer (Ubuntu 24.04 LTS, C++)

## Versioning
All artifact names are sourced from `version.mk`:
- MAJOR, MINOR, SUBVERSION: Semantic version components
- BUILD_ID: Build identifier

The versioned name format is: `libswtr_ringbuffer-$(MAJOR).$(MINOR).$(SUBVERSION)-$(BUILD_ID)`

## Build Artifacts (lib/)
- **Static Library**: `lib/libswtr_ringbuffer-$(MAJOR).$(MINOR).$(SUBVERSION)-$(BUILD_ID).a`
  - Created via `ar rcs` from object files.
- **Shared Library**: `lib/libswtr_ringbuffer-$(MAJOR).$(MINOR).$(SUBVERSION)-$(BUILD_ID).so`
  - Created via `g++ -shared` with `-Wl,-soname,libswtr_ringbuffer.so`.
- **Symbolic Links** (relative paths within lib/):
  - `lib/libswtr_ringbuffer.a` → points to the versioned static library.
  - `lib/libswtr_ringbuffer.so` → points to the versioned shared library.

## Intermediate Artifacts (build/)
- **Object Files**: `build/*.o` — compiled position-independent object files from each `.cpp` source module.

## Source Files
All C++ sources reside in `ringbuffer/src/ubuntu/cpp/`:
- Lifecycle.cpp, Threading.cpp, ReadOps.cpp, TransformOps.cpp, WriteOps.cpp, ErrorOps.cpp
- LoggingOps_1.cpp through LoggingOps_6.cpp
- Accessors_Status.cpp, Accessors_ChecksumAlg.cpp, Accessors_ChecksumVal.cpp
- Accessors_Size_Max.cpp, Accessors_Size_Data.cpp, Accessors_Size_Transformed.cpp
- Headers: ringbuffer.hpp, status.hpp, swtr_ringbuffer_impl.hpp

## Configuration Files
- `Makefile` — GNU Make build system with container, verify, clean, dist-clean targets.
- `version.mk` — Version variables (MAJOR, MINOR, SUBVERSION, BUILD_ID).
- `Dockerfile` — Ubuntu 24.04 container image with all build dependencies pre-installed.

## Logs and Reports
- `logs/build.log` — Build process logging (every step, configuration change, verification result).
- `logs/functional.log` — Functional test results.

## Specs Directory
- `specs/build.md` — Platform-specific build requirements (Ubuntu 24.04).
- `specs/testing.md` — Platform-specific testing requirements (Ubuntu 24.04).
- `specs/artifacts.md` — This file.

## Build System Prerequisites (Ubuntu)
The Dockerfile installs: gcc, g++, binutils, make, cmake, doxygen, clang, clang-tidy, clang-format, procps, coreutils, findutils, which, file, patchelf, vim, strace, emacs-nox.
