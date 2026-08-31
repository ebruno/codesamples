# Go Build — <OS>

**Note:** Go is a platform-insensitive language. Source code is identical across all platforms.
Use `prompts/common/go/build.md` and `prompts/common/go/functional.md` as the primary specifications.
No platform-specific build overrides are needed for Go on <OS>.

## Build Notes
- **Build System**: Go Modules (`go.mod`) — identical across all platforms.
- **Compiler**: Primary target is Go 1.24, with fallback to 1.23/1.22 as needed.
- **Container**: Use `container` (macOS host) or `podman` (Linux host) with image from the per-OS Dockerfile.
  - Arch Linux: Linux-hosts-only (no container images for Apple Silicon).
- **Output**: `lib/libringbuffer.{a|so|dylib}` (via `-buildmode=c-{archive,shared}`).
