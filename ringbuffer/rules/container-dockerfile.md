### Container Dockerfile Location
- **Unified location**: `src/<os>/containers/build/Dockerfile` and `src/<os>/containers/test/Dockerfile`
- **One Dockerfile per OS** — each installs tools for ALL supported languages (C/C++, Java, Python).
- **Build and test Dockerfiles are identical** — same content, no cross-inheritance.
- **Containers inherit ONLY from base OS image** (`fedora:44`, `debian:13`, `ubuntu:24.04`, raspios base) — NEVER from each other.
- **Deprecated**: Old per-language Dockerfiles at `src/common/python/containers/` and `src/common/java/containers/` have been removed.
