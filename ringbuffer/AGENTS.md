# AGENTS.md — Ringbuffer Project Instructions

> **Open standard instruction file.** Read this first. Section references point to detailed files in `.bionic.d/`.

---

## Table of Contents

| Section | File | Size |
|---------|------|------|
| Project Structure & Platforms | `.bionic.d/project.md` | 38KB |
| Operational Rules & Workflows | `.bionic.d/rules.md` | 49KB |

---

## Session Startup

1. Read this file (`AGENTS.md`)
2. Read `.bionic.d/project.md` — project structure, platforms, languages, implementation phases
3. Read `.bionic.d/rules.md` — operational rules, pre-flight checks, workflow discipline
4. Context-specific rules in `rules/` are loaded via RULES-LOAD directives embedded in the files above

---

## Critical Rules (Always Enforced)

### Git Discipline
- **NEVER attempt to commit.** The user always handles all commits. Do not run `git add`, `git commit`, or any git write operation.
- **NEVER commit reports, logs, or build artifacts.** These are regenerated on every run. The `.gitignore` covers them.
- If the user asks you to "commit" or "stage," decline and remind them they handle all commits.

### Makefiles Are the CI/CD Contract
- When a Makefile target fails, **do not** manually run the underlying commands to "get past" the failure. Fix the Makefile.
- When asked to build or test, **always** use `make <target>` — never run the equivalent shell commands directly.
- If you find yourself about to bypass a Makefile step, **STOP**.

### Loop Detection and Recovery
- If you detect that you are repeating the same action, explanation, or approach **3 times or more**, this is a sign of looping.
- On the 3rd repeat: **stop immediately** and report the problem to the user.

### Error Handling — Shell Commands
- If you start getting shell errors, report the issue to the user and **stop processing immediately**.

### Read-Before-Write
Always read a file before modifying it. If a write fails due to concurrent modification, re-read and retry once.

---

## File Maintenance Guide

### `AGENTS.md` (this file)
**Scope:** Critical rules that must survive even if modular files fail to load.

**Contains:**
- Session startup instructions
- Critical rules (git discipline, Makefile contract, loop detection)
- Table of contents pointing to detailed files

**Edit this file when:**
- Adding a rule so fundamental it must be visible even if `.bionic.d/` files can't be read
- Changing the load order or TOC

### `.bionic.d/project.md`
**Scope:** Everything that describes *what* the project is — static reference.

**Contains:**
- Project structure and directory layout
- Platform classification and container support models
- Language versions, classification, and build systems
- Implementation phases and current status

**Edit this file when:**
- Adding a new OS, language, or platform
- Updating implementation status (phase completions)
- Changing project structure

### `.bionic.d/rules.md`
**Scope:** Everything that describes *how* to work on the project — operational rules.

**Contains:**
- Makefile discipline (full detail)
- Remote build/testing workflow (SSH, tarball, SCP)
- SSH host resolution and configuration
- Container runtime rules
- Shell script portability and forbidden tools
- Script/Makefile syntax verification
- File writing discipline and chunked write pattern

**Edit this file when:**
- Adding a new pre-flight check or guardrail
- Changing operational workflow (SSH, containers, builds)
- Adding a new shell or platform compatibility rule

---

## Quick Decision Table

| Content type | File |
|-------------|------|
| New OS, language, or platform | `project.md` |
| Implementation phase complete | `project.md` |
| New pre-flight check | `rules.md` |
| Container or SSH workflow change | `rules.md` |
| Shell portability rule | `rules.md` |
| Project directory restructure | `project.md` |
| Build/test pattern change | `project.md` |
| Tool check or session init change | `AGENTS.md` (this file) |

---

## After Any Edit
1. If you edited `project.md` or `rules.md`: verify the changes are reflected in the TOC above
2. If a section was moved between files: verify the old location no longer has stale content

## Removing Content
- If a section is no longer needed, remove it from the appropriate file
- After removal, verify no orphans remain

---

## Session Initialization Checklist
- At the start of every new session, your first response to the user must explicitly begin with: "✅ [AGENTS.md configuration successfully loaded]" before addressing the user's prompt.

## Tool Availability Check — Run at Session Start
- **macOS (zsh host):** `./utils/bin/check_tools.zsh`
- **Linux distributions (bash host):** `./utils/bin/check_tools.sh`

---

**IMPORTANT: This AGENTS.md file was loaded at session startup. Follow the instructions above, then proceed to `.bionic.d/project.md` and `.bionic.d/rules.md`.**
