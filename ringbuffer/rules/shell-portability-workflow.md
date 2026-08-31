# Shell Script Portability Workflow — Mandatory Procedure

## Purpose
Enforces the rule that shell scripts may only use bash/zsh builtins — no `awk`, `sed`, `grep`, `cut`, `tr`, `sort`, `uniq`, `find`, or `xargs`.

## When to Use
Every time you create or modify a `.sh` or `.zsh` script.

## The Workflow

### Phase 1 — Plan
Before writing any script, state:
1. **What** the script does (purpose)
2. **Every external tool** you plan to use — if any, STOP and replace with builtins first

### Phase 2 — Execute
1. Write the script using only bash/zsh builtins:
   - `grep` → `case "$var" in *pattern*) ... ;; esac` or `[[ "$var" == *pattern* ]]`
   - `sed 's/old/new/'` → `${var//old/new}` parameter expansion
   - `awk '{print $1}'` → `read -r field _ <<< "$line"` or `${var%% *}`
   - `cut -d: -f1` → `${var%%:*}` parameter expansion
2. **STOP** — scan the entire script for any of these forbidden words: `awk`, `sed`, `grep`, `cut`, `tr`, `sort`, `uniq`, `find`, `xargs`
3. If any appear → **STOP**, replace with builtin equivalent, re-scan
4. Run syntax check: `bash -n <script>` or `zsh -n <script>`

### Phase 3 — Verify
1. Confirm no forbidden tools appear anywhere in the script (including comments)
2. If any was modified without a passing scan → STOP and fix it

## Self-Check
- Did I use `grep`, `sed`, `awk`, or any forbidden tool? If yes → STOP and replace.
- Did I scan the entire script after writing it?
- Does `bash -n` / `zsh -n` pass?
