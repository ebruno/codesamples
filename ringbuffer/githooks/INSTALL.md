# Git Hooks — Installation

> **Multi-project repo**: This repository contains multiple projects. The hook is scoped to `ringbuffer/prompts/` only — changes to `prompts/` in other projects are ignored.

## Overview

The Ringbuffer project includes a post-commit hook that analyzes changes to `prompts/` files and suggests changelog entries. The hook is stored in the repository under `githooks/` as a sample — each developer installs it locally.

## Prerequisites

- The suggestion script must exist and be executable: `utils/bin/suggest_changelog_entry.sh`
- The changelog file should exist (or the script creates it on first apply): `prompts/common/CHANGELOG.md`

## Installation (One-Time)

```bash
# From the repository root:
cp githooks/post-commit .git/hooks/post-commit
chmod +x .git/hooks/post-commit
```

That's it. The hook will now run after every commit.

## How It Works

1. After each `git commit`, the hook checks if any files under `prompts/` were changed.
2. If no prompt files changed, it exits silently — zero noise on unrelated commits.
3. If prompt files did change, it analyzes the diff and prints a suggested CHANGELOG entry to your terminal.
4. You choose: **apply** (append to `CHANGELOG.md`), **edit** (open in `$EDITOR`, then apply/edit/discard loop), or **skip**.

## Uninstalling

```bash
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

That's it — the hook will then work in a standalone repo without any other changes.

## Troubleshooting

**Hook not running?** Verify it's installed and executable:
```bash
ls -la .git/hooks/post-commit
# Should show: -rwxr-xr-x  ... post-commit
```

**Script not found?** The hook looks for `utils/bin/suggest_changelog_entry.sh` relative to the repository root. Make sure you're running commits from within the repo.

**Editor not opening?** The script uses `$EDITOR` (defaults to `vi`). Set it explicitly:
```bash
export EDITOR=vim   # or nano, code, etc.
```
