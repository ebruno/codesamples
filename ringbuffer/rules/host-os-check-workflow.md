# Host OS Check Workflow — Mandatory Procedure

## Purpose
Enforces the rule that every shell script must include a host OS check at the top of its execution flow.

## When to Use
Every time you create or modify a shell script.

## The Workflow

### Phase 1 — Plan
Before writing any script, state:
1. **What shell** the script uses (zsh, bash, tcsh)
2. **Which host OS** it requires (Darwin/macos, Linux, FreeBSD)

### Phase 2 — Execute
1. Add the host OS check as the first executable code after argument parsing:

   **zsh scripts (macOS):**
   ```zsh
   if [ "$BYPASS_OS_CHECK" = false ]; then
       local_host_os=$(uname -s)
       if [ "$local_host_os" != "Darwin" ]; then
           echo "ERROR: Running unsupported operating system ${local_host_os}; script requires macOS."
           exit 1
       fi
   fi
   ```

   **bash scripts (Linux):**
   ```bash
   if [ "$BYPASS_OS_CHECK" = false ]; then
       local_host_os=$(uname -s)
       if [ "$local_host_os" != "Linux" ]; then
           echo "ERROR: Running unsupported operating system ${local_host_os}; script requires Linux."
           exit 1
       fi
   fi
   ```

   **tcsh scripts (FreeBSD):**
   ```tcsh
   if (! $?BYPASS_OS_CHECK) then
       set local_host_os = `uname -s`
       if ($local_host_os != "FreeBSD") then
           echo "ERROR: Running unsupported operating system ${local_host_os}; script requires FreeBSD." >&2
           exit 1
       endif
   endif
   ```

2. **STOP** — verify the check is present and uses `uname -s`
3. Run syntax check: `<shell> -n <script>`

### Phase 3 — Verify
1. Confirm the host OS check exists in every script you modified
2. If any was modified without a passing check → STOP and fix it

## Self-Check
- Does every script have a host OS check?
- Does the check use `uname -s` and compare against the correct value?
- Is it placed after argument parsing (so `-N` can bypass it)?
