# Build Requirements — Ringbuffer (Go)

**Implementation Directive:**
This build specification MUST be followed exactly to ensure consistency across platforms. Platform-specific deviations are permitted only for Go version requirements and CGO settings.

**Spec Precedence Rule:** When platform-specific specs (e.g., `prompts/<os>/go/build.md`) conflict with common specs (`prompts/common/go/build.md`), the platform-specific spec takes precedence for Go version and CGO details. All other requirements in the common spec remain authoritative unless explicitly overridden by a platform-specific directive.

## Language Standards
- **Primary Version**: Go 1.24
- **Fallback Versions** (in priority order): Go 1.23, Go 1.22
- **Minimum Supported**: Go 1.22 — all implementations MUST be compatible with this version
- **Encoding**: UTF-8

## Build System: Go Modules
All Go builds MUST use the native Go toolchain with Go modules. The project root for each platform MUST contain a `go.mod` file.

### Go Module Configuration
- **Module path**: `github.com/swtr/ringbuffer`
- **Go version**: Platform-specific minimum Go version (see platform spec). Common default: Go 1.24.
- **Build constraints**: No build tags in the common spec. Platform-specific CGO settings may be added per platform.

### Required go.mod
```go
module github.com/swtr/ringbuffer

go 1.24
```

No external dependencies are required for the core ringbuffer library. The `go.mod` MUST NOT include any third-party dependencies in the common spec.

### Required Build Targets
The following Go build targets MUST be supported:

| Target | Description |
|--------|-------------|
| `go build ./...` | Build all packages in the module |
| `go test ./...` | Run all tests |
| `go vet ./...` | Static analysis (linting) |
| `go build -o lib/libringbuffer.a -buildmode=c-archive .` | Build static library (if C interop is needed) |
| `go build -o lib/libringbuffer.so -buildmode=c-shared .` | Build shared library (if C interop is needed) |

### Artifact Naming
The built binary/library MUST follow Go conventions. For a library package, the output is typically imported by other Go modules rather than produced as a standalone binary. If C interop is required, produce:
- Static library: `lib/libringbuffer.a` (via `-buildmode=c-archive`)
- Shared library: `lib/libringbuffer.so` on Linux, `lib/libringbuffer.dylib` on macOS (via `-buildmode=c-shared`)

### Source Directory Structure
```
src/<os>/go/
├── go.mod                     # Go module definition
└── swtr.go                    # All source code (package swtr)
```

### Test Directory Structure
```
src/<os>/go/
├── go.mod
├── swtr.go                    # Main source
└── swtr_test.go               # Test file (Go convention: _test suffix)
```

### Build Process
1. **Build**: `go build ./...` — compiles all Go source files.
2. **Test**: `go test ./...` — runs the test suite and outputs results to stdout.
3. **Vet**: `go vet ./...` — performs static analysis.
4. **Clean**: Remove the `lib/` directory and any build artifacts.

### Platform-Specific Considerations
- **macOS**: Use the native Go installation (e.g., Homebrew `go` or official installer). No container support. CGO is enabled by default for file descriptor access.
- **Linux**: Use the platform-appropriate Go package (e.g., `golang-go` on Ubuntu, `go-toolset` on Fedora). CGO is enabled by default.
- **Container builds**: If building in a container, the Dockerfile MUST install Go before running build commands.

### CGO Configuration
The ringbuffer implementation uses file descriptor I/O which requires CGO on some platforms. The common spec assumes CGO is enabled (`CGO_ENABLED=1`). Platform-specific specs may override this if needed.

### Temporary Workspace
- All temporary files MUST be placed in a `tmp/` directory or Go's build cache (`$GOPATH/pkg`).
- Do NOT create temporary files in the project root or source directories.

### Build Process Logging
- Create a directory at `src/<os>/go/logs/`.
- Log build actions to `build.log` in the format: `[YYYY-MM-DD HH:MM:SS +/-HHMM] <Action Description>`.
- Append to existing log files; do NOT overwrite.

### Scope Boundary — Build Phase Only
The purpose of this prompt is to compile the library and produce artifacts in `lib/`. **Your task ends once the library files exist.**

You MUST NOT:
- Run `go test` or any testing workflow
- Generate test data, compile test binaries, or execute any tests
- Proceed to verification, reporting, or test matrix execution

**Directory Scope Restriction:**
- **NEVER create, modify, or delete any files inside the `tests/` directory.** This directory is managed exclusively by testing-related prompts. Build-only prompts must treat it as read-only.

### Excluded Platforms
- **FreeBSD 14**, **FreeBSD 15**, and **ArchLinux** are excluded from active development.
- Do not modify, add content to, or create new files in `prompts/freebsd14/`, `prompts/freebsd15/`, or `prompts/archlinux/`.
