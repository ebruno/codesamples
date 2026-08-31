# Code Samples

[![License: BSD 3-Clause](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](LICENSE)
[![GitHub Actions](https://github.com/ebruno/codesamples/actions/workflows/publish-rb-docs.yml/badge.svg)](https://github.com/ebruno/codesamples/actions)

Coding samples in various languages and tools.

## Contents

- [Quick Start](#quick-start)
- [Directory Overview](#directory-overview)
- [Samples with LLM Support](#samples-with-llm-support)
  - [Prompt-Equipped Directories](#prompt-equipped-directories)
  - [LLM-Generated Samples](#llm-generated-samples)
- [Git Client-Side Hooks](#git-client-side-hooks)
  - [Enabling Hooks](#enabling-hooks)
  - [Available Hooks](#available-hooks)
- [CI/CD Runners](#cicd-runners)
- [Utility Scripts](#utility-scripts)
- [Other Directories](#other-directories)

## Quick Start

```bash
# Clone from GitHub
git clone https://github.com/ebruno/codesamples.git
cd codesamples
```

```bash
# Or clone from GitLab
git clone https://gitlab.com/evbruno/codesamples.git
cd codesamples
```

> **Note:** These mirrors are synced from a private GitLab instance and are
> configured to **force-overwrite** — any divergent changes on the mirrors will be
> replaced on the next sync. To contribute, open an issue or submit a pull request
> on either mirror.

Each directory contains self-contained samples. Browse the [Directory Overview](#directory-overview) for details on what's inside.

To enable the git hooks:

```bash
./utils/bin/merge_githooks.sh       # Linux
./utils/bin/merge_githooks.zsh      # macOS
git config core.hooksPath .githooks/hooks
```

## Directory Overview

| Directory | Description |
|-----------|-------------|
| [`bash/`](bash/README.md) | Shell scripting samples |
| [`c/`](c/README.md) | C language samples |
| [`c++/`](c++/README.md) | C++ language samples |
| [`go/`](go/README.md) | Go language samples |
| [`k8s_kind/`](k8s_kind/README.md) | Kubernetes (kind) cluster demo |
| [`linker_example/`](linker_example/README.md) | Function sections & dead code elimination demo |
| [`lua/`](lua/README.md) | Lua samples (LLM-generated from bash) |
| [`macro-11/`](macro-11/README.md) | DEC PDP-11 assembler (FizzBuzz) |
| [`openvox/`](openvox/README.md) | OpenVox (open-source Puppet replacement) |
| [`packer/`](packer/README.md) | HashiCorp Packer image builds |
| [`powershell/`](powershell/README.md) | PowerShell samples (LLM-generated from bash) |
| [`python/`](python/README.md) | Python samples and utilities |
| [`ringbuffer/`](ringbuffer/README.md) | Multi-language ringbuffer library (C, C++, Java, Go, Python, Rust) |
| [`tcl/`](tcl/README.md) | Tcl samples (LLM-generated from bash) |
| [`terraform/`](terraform/README.md) | Infrastructure-as-code (AWS, Azure, GCP) |
| [`zsh/`](zsh/README.md) | Z shell scripting samples |

> **Note:** Lua, PowerShell, and Tcl examples were generated using an LLM based on the `bash/` directory.

## Samples with LLM Support

Some directories include LLM prompt infrastructure for code generation and refactoring.

### Prompt-Equipped Directories

**`c/`** — C language
- `senior-c-dev`: Expert in ANSI C23 and C Core Guidelines. Focuses on memory alignment, cache locality,
  and minimal overhead. Prioritizes C23 features (`nullptr`, `auto`, `constexpr`) with C17/C18 fallback.
- `refactor`: Code refactoring template with input/output examples.

**`c++/`** — C++ language
- `senior-cpp-dev`: Expert in C++20/23 and C++ Core Guidelines. Emphasizes RAII, smart pointers,
  bounds-checked access, and modern C++20 features (concepts, ranges, `std::format`).
- `refactor`: Code refactoring template with input/output examples.

**`ringbuffer/`** — Multi-language ringbuffer library
- Per-OS roles: `debian-dev`, `ubuntu-dev`, `macos-dev`, `fedora-dev`
- Languages targeted: C, C++, Java, Go, Python, Rust
- Workflows: functional implementation, build creation, regression testing, build verification

### LLM-Generated Samples

- **`lua/`** — FizzBuzz and whitespace trimming, generated from `bash/` counterparts
- **`powershell/`** — FizzBuzz, generated from `bash/` counterparts

## Git Client-Side Hooks

This repository supports two levels of git hooks:

| Level | Location | Purpose |
|-------|----------|---------|
| **Root** | `.githooks/hooks/` | YAML tab-check (`pre-commit`). Also acts as a dispatcher for sub-project hooks. |
| **Sub-project** | `<subdir>/githooks/` | Per-project hooks (e.g., `ringbuffer/githooks/` has README-template sync and CHANGELOG suggestions). |

### Enabling Hooks

Git only supports a single `core.hooksPath`. To use both root and sub-project hooks together, run the merge script first:

```bash
# Merge sub-project hooks into .githooks/hooks/
./utils/bin/merge_githooks.sh       # Linux
./utils/bin/merge_githooks.zsh      # macOS
```

Then activate:

```bash
git config core.hooksPath .githooks/hooks
```

The merge script is **idempotent** — re-run it after adding or removing sub-project `githooks/` directories. The root `pre-commit` and `post-commit` are regenerated as dispatchers that delegate to each sub-project's hooks only when its files are staged or committed.

### Available Hooks

**Root:**
- `pre-commit` — Ensures YAML files (`.yml`, `.yaml`) use 4 spaces instead of tabs. Dispatches to sub-project hooks.
- `post-commit` — Dispatches to sub-project `post-commit` hooks.

**Sub-project (ringbuffer):**
- `pre-commit` — Ensures `README.md` and `prompts/common/templates/readme_template.md` stay in sync.
- `post-commit` — Analyzes prompt changes and suggests CHANGELOG entries.

## CI/CD Runners

This repository supports GitLab and GitHub self-hosted runners for CI/CD.
See **[docs/runners.md](docs/runners.md)** for full installation and configuration instructions covering:

- Installing Podman or Docker CE
- GitLab Runner setup (shell, Docker, and Podman executors)
- GitHub Actions self-hosted runner setup

## Utility Scripts

Scripts in `utils/bin/` help maintain the repository.

| Script | Shell | Purpose |
|--------|-------|---------|
| `generate_docs_index.sh` | bash | Generates `docs/index.html` (GitHub Pages) or `pages/index.html` (GitLab Pages) by scanning each subdirectory's `README.md` for its description. |
| `generate_docs_index.zsh` | zsh | Same as above, for macOS hosts. |
| `merge_githooks.sh` | bash | Merges sub-project `githooks/` directories into `.githooks/hooks/` with prefixed names. Regenerates root dispatcher hooks (`pre-commit`, `post-commit`). Idempotent. |
| `merge_githooks.zsh` | zsh | Same as above, for macOS hosts. |

**Usage:**

```bash
# Generate GitHub Pages index
./utils/bin/generate_docs_index.sh github

# Generate GitLab Pages index
./utils/bin/generate_docs_index.zsh gitlab
```

## Other Directories

| Directory | Description |
|-----------|-------------|
| `utils/` | Utility and helper scripts |
