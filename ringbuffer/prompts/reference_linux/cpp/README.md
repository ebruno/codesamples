# Reference Linux — Canonical Cross-Platform Verification Spec

## Purpose

This directory contains the **canonical reference set** for Linux distributions used in cross-platform verification. It is **not an operating system target** — no source code, Makefiles, or Dockerfiles are generated here.

## Role in the Project

The `reference_linux` directory serves as the authoritative specification against which other Linux platforms (Fedora, Debian, Ubuntu) are compared for **binary symmetry**. When source code is generated independently from the common spec (`prompts/common/cpp/functional.md`), the `verify_binary_symmetry.sh` script compares outputs against this reference to confirm byte-identical results.

## Contents

| File | Purpose |
|------|---------|
| `create_regression.md` | Reference test infrastructure setup workflow for Linux platforms |

## How It Works

1. Each Linux platform (Fedora, Debian, Ubuntu) generates its source code independently from `prompts/common/cpp/functional.md`
2. The generated source is compared against the reference in this directory
3. `verify_binary_symmetry.sh` reports any differences — if all files match, binary symmetry is verified

## Platform Classification

Per `.bionic` Section 4:

| Category | Platforms | Container Support |
|----------|-----------|-------------------|
| Linux distributions | Fedora, Debian, Ubuntu, **reference_linux** | Yes — `container` on macOS hosts, `podman` on Linux hosts |

## Related Documentation

- **`.bionic` Section 4** — Platform classification and cross-platform generation mandate
- **`prompts/common/cpp/functional.md`** — Common functional spec (source of truth for all platforms)
- **`prompts/common/cpp/build.md`** — Common build spec (source of truth for all platforms)
- **`prompts/common/cpp/utils/bin/verify_binary_symmetry.sh`** — Automated binary symmetry verification script
