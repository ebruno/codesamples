# Go Functional — FreeBSD 14

**Note:** Go is a platform-insensitive language. Source code is identical across all platforms.
Use `prompts/common/go/functional.md` as the primary specification for functional requirements.
No platform-specific functional overrides are needed for Go on FreeBSD 14.

## Functional Notes
- The Go implementation follows the common spec exactly: three-stage pipeline (read → transform → write) with status-driven coordination.
- Error handling uses Go channels and goroutines for cooperative cancellation.
- Version reporting: detect `go version` at runtime, log to functional.log and build.log.
