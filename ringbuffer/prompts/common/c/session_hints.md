# C Session Hints — Ringbuffer Project

**When to read:** When working on C source code, Makefiles, or build configurations.
This file provides a quick-reference card with cross-links to detailed specs.

> **Read first:** `prompts/common/session_hints.md` for host OS detection, macOS/Linux versioning,
> container runtime, and memory calculation. This file covers C-specific toolchain, binary formats,
> linking flags, and Makefile gotchas.

---

## Quick Reference Index

| Topic | Detailed Spec |
|-------|--------------|
| Source file organization, naming conventions, include discipline | `prompts/common/c/functional.md` |
| Build flags, Makefile targets, artifact naming, optimization goals | `prompts/common/c/build.md` |

---

## 1. Conditional Compilation Rule

When a platform lacks a C feature available on other platforms, use `#ifdef` blocks to provide an alternative implementation for that OS **only**. Never modify the common code path or "down-rev" features for all other platforms.

- **Full rule**: [prompts/common/conditional_compilation_rule.md](../conditional_compilation_rule.md)
- **Golden Rule reference**: `prompts/common/templates/readme_template.md` — Part A.2
- **Key principle**: The non-conditional code path remains byte-identical across all platforms. Conditional blocks are the exception, not the rule.

---

## 2. Cross-Reference Summary

> **Host OS detection, macOS versioning, Linux /etc/os-release, container runtime** → `prompts/common/session_hints.md`
> **Source organization, naming conventions, include discipline** → `prompts/common/c/functional.md`
> **Build flags, Makefile targets, artifact naming** → `prompts/common/c/build.md`
> **Conditional compilation rule** → `prompts/common/conditional_compilation_rule.md`
