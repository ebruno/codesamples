# Java Testing — <OS>

**Note:** Java is a platform-insensitive language. Source code is identical across all platforms.
Use `prompts/common/java/functional.md` and `prompts/common/java/build.md` as the primary specifications.
No platform-specific overrides are needed for Java on <OS>.

## Execution Notes
- **Build System**: Apache Maven (`pom.xml`) — identical across all platforms.
- **Container**: Use `container` (macOS host) or `podman` (Linux host) with image from the per-OS Dockerfile.
  - If a platform-specific `pom.xml` exists at `src/<os>/java/pom.xml`, mount it to override the common pom.xml.
- **Java version**: Primary target is Java SE 25, with fallback to 24/23/22/21 as needed.
