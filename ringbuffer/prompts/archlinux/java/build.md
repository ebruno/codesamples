# Java Build — <OS>

**Note:** Java is a platform-insensitive language. Source code is identical across all platforms.
Use `prompts/common/java/build.md` and `prompts/common/java/functional.md` as the primary specifications.
No platform-specific build overrides are needed for Java on <OS>.

## Build Notes
- **Build System**: Apache Maven (`pom.xml`) — identical across all platforms.
- **Container**: Use `container` (macOS host) or `podman` (Linux host) with image from the per-OS Dockerfile.
  - If a platform-specific `pom.xml` exists at `src/<os>/java/pom.xml`, mount it to override the common pom.xml (required when platform JDK version differs from common spec).
- **Java version**: Primary target is Java SE 25, with fallback to 24/23/22/21 as needed.
