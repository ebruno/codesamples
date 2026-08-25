# Cross-Platform Script Execution Workflow — Mandatory Procedure

## Purpose
Enforces the rule for running scripts on a host OS that doesn't match the script's target shell (e.g., bash on macOS, zsh on Linux).

## When to Use
Every time you execute a script whose shell doesn't match the host OS.

## The Workflow

### Phase 1 — Plan
Before executing a script:
1. **Identify the host OS**: `uname -s` → Darwin (macOS), Linux, FreeBSD
2. **Identify the script's shell**: read shebang → `.zsh` (macOS), `.sh` (Linux), `.tcsh` (FreeBSD)
3. **If they match** → execute normally, skip to Phase 2 step 4
4. **If they don't match** → verify the required shell is installed on the host:
   - macOS host running `.sh` → `bash --version` (must be 5.x+)
   - Linux host running `.zsh` → `zsh --version` (must be 5.x+)
   - If not available or version too low → STOP, report error

### Phase 2 — Execute
1. **Run syntax check**: `<shell> -n <script>` — if it fails, report errors and STOP
2. **Run actual execution**: `<shell> -N <script>` — the `-N` flag bypasses the script's internal host OS check
3. If execution fails → report errors, STOP

### Phase 3 — Verify
1. Confirm the syntax check passed before execution
2. If any script was executed without a passing `-n` check → STOP and fix it

## Self-Check
- Did I run `<shell> -n` before executing?
- Did I use `-N` when running cross-platform?
- Is the required shell available on this host?
