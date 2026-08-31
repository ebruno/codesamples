# Shell Isolation Workflow — Mandatory Procedure

## Purpose
Enforces the rule that scripts may only call other scripts written for the same shell (zsh calls zsh, bash calls bash, tcsh calls tcsh).

## When to Use
Every time you create a script that invokes another script, or modify an existing call.

## The Workflow

### Phase 1 — Plan
Before writing any script that calls another:
1. **List every script** this one will invoke (full paths)
2. **For each**, note the shell: `.zsh` → zsh, `.sh` (bash shebang) → bash, `.tcsh` → tcsh
3. **Verify all match** the caller's shell — if any mismatch, STOP and plan a rewrite

### Phase 2 — Execute
1. Write the script with only same-shell invocations
2. **STOP** — scan every `exec`, `source`, `. `, or direct call to another script
3. For each call, verify the target's shebang matches the caller's shell
4. If any mismatch → **STOP**, rewrite the target or change the call

### Phase 3 — Verify
1. List every script invocation and confirm shell match
2. If any was modified without a passing scan → STOP and fix it

## Self-Check
- Does every called script use the same shell as the caller?
- Did I scan all invocations after writing?
