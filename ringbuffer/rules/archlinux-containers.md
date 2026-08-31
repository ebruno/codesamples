### Arch Linux (Linux-Hosts-Only)
Arch Linux C++ is fully implemented in `prompts/archlinux/cpp/` (9 files, ~32KB). Source code is byte-identical to macOS. Build and test require a Linux host (`ebruno@10.10.41.227`) via SSH; both g++ and clang++ are supported with auto-detection in the Makefile. Arch Linux container images are amd64-only, so on macOS scripts skip gracefully with a logged message.

**CXX override pattern:** The Arch Linux Makefile uses `CXX ?= $(firstword $(AVAILABLE_COMPILERS))` — the `?=` means it respects an already-set CXX. To build with clang++ (default is g++, first alphabetically), use:
```bash
make CXX=clang++ all    # ✅ Works — command-line override respected
```
Do NOT use `export CXX=clang++` before `make` — that does not work because the Makefile's auto-detection runs unconditionally with `:=`. The `?=` fix (applied 2026-08-19) allows command-line override but not environment variable override from the calling shell.
