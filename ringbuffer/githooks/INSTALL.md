# Git Hooks — Installation

> **Multi-project repo**: These hooks are scoped to `ringbuffer/` only — changes in other projects are ignored.

## Overview

The Ringbuffer project includes two git hooks stored under `githooks/` as samples — each developer installs them locally:

| Hook | When it runs | Purpose |
|------|-------------|---------|
| **pre-commit** | Before each commit | Ensures `README.md` and `prompts/common/generate_toplevel_readme.md` stay in sync |
| **post-commit** | After each commit | Analyzes prompt changes and suggests CHANGELOG entries |

## Prerequisites

### Pre-commit hook
- No external scripts required — self-contained.

### Post-commit hook
- The suggestion script must exist and be executable: `utils/bin/suggest_changelog_entry.sh`
- The changelog file should exist (or the script creates it on first apply): `prompts/common/CHANGELOG.md`

## Installation (One-Time)

The pre-commit hook is a three-file package: a POSIX `sh` wrapper that detects the host OS and delegates to either `pre-commit.bash` (Linux) or `pre-commit.zsh` (macOS). All three must be copied together.

```bash
# From the repository root:

# Pre-commit hook — blocks commits if README and prompt drift apart
cp githooks/pre-commit .git/hooks/pre-commit
cp githooks/pre-commit.bash .git/hooks/pre-commit.bash
cp githooks/pre-commit.zsh .git/hooks/pre-commit.zsh
chmod +x .git/hooks/pre-commit .git/hooks/pre-commit.bash .git/hooks/pre-commit.zsh

# Post-commit hook — suggests CHANGELOG entries for prompt changes
cp githooks/post-commit .git/hooks/post-commit
chmod +x .git/hooks/post-commit
```

## How the Pre-Commit Hook Works

The pre-commit hook enforces three rules:

### Rule 1: Both-or-None (Hard Block)
If `README.md` is staged but `prompts/common/generate_toplevel_readme.md` is not (or vice versa), the commit is **blocked**. This ensures the prompt always describes what the README actually contains.

### Rule 2: Section Alignment (Warning)
If both files are staged, the hook compares their section headers (`##` and `###`). If sections exist in one file but not the other, a **warning** is printed — the commit still proceeds. This catches drift before it compounds.

### Rule 3: .bionic.d/* → CLAUDE.md Sync (Hard Block)
If `.bionic.d/project.md` or `.bionic.d/rules.md` is staged, `CLAUDE.md` must be in sync (CLAUDE.md = cat .bionic.d/project.md .bionic.d/rules.md). This ensures the LM Studio Bionic agent always has the latest rules. Run `cat .bionic.d/project.md .bionic.d/rules.md > CLAUDE.md` to fix.

## How the Post-Commit Hook Works

1. After each `git commit`, the hook checks if any files under `prompts/` were changed.
2. If no prompt files changed, it exits silently — zero noise on unrelated commits.
3. If prompt files did change, it analyzes the diff and prints a suggested CHANGELOG entry to your terminal.
4. You choose: **apply** (append to `CHANGELOG.md`), **edit** (open in `$EDITOR`, then apply/edit/discard loop), or **skip**.

## Uninstalling

```bash
rm .git/hooks/pre-commit .git/hooks/pre-commit.bash .git/hooks/pre-commit.zsh
rm .git/hooks/post-commit
```

## Moving to a Standalone Repository

If you move `ringbuffer/` out of the multi-project repo into its own standalone repository, change one line in `utils/bin/suggest_changelog_entry.sh`:

```bash
# Change this line (line 14):
PROJECT_PREFIX="ringbuffer/"
# To this:
PROJECT_PREFIX=""
```

That's it — the hooks will then work in a standalone repo without any other changes.

## Troubleshooting

### Pre-commit hook not running?
Verify it's installed and executable:
```bash
ls -la .git/hooks/pre-commit
# Should show: -rwxr-xr-x  ... pre-commit
```

### Pre-commit hook blocks a commit I want to make?
- **If the README change is real**: Also stage `prompts/common/generate_toplevel_readme.md` and retry.
- **If `.bionic` was modified but CLAUDE.md is out of sync**: Run `make sync-claude`, then re-stage `CLAUDE.md` and retry.
- **If the README change was accidental**: Revert it, or use `git commit --no-verify` (bypasses all hooks — use sparingly).

### Post-commit hook not running?
Verify it's installed and executable:
```bash
ls -la .git/hooks/post-commit
# Should show: -rwxr-xr-x  ... post-commit
```

**Script not found?** The hook looks for `utils/bin/suggest_changelog_entry.sh` relative to the repository root. Make sure you're running commits from within the repo.

**Editor not opening?** The script uses `$EDITOR` (defaults to `vi`). Set it explicitly:
```bash
export EDITOR=vim   # or nano, code, etc.