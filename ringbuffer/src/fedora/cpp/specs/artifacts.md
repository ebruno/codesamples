# Build Artifacts — Fedora

## Library Artifacts
| Artifact | Path | Description |
|----------|------|-------------|
| Static Library | `lib/libswtr_ringbuffer-<MAJOR>.<MINOR>.<SUBVERSION>-<BUILD_ID>.a` | Static archive built with `ar` |
| Shared Library | `lib/libswtr_ringbuffer-<MAJOR>.<MINOR>.<SUBVERSION>-<BUILD_ID>.so` | Shared object built with `-shared` |
| Static Link | `lib/libswtr_ringbuffer.a` → versioned static library | Relative symlink for linking |
| Shared Link | `lib/libswtr_ringbuffer.so` → versioned shared library | Relative symlink for linking |
