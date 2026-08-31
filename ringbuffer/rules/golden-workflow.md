# Golden Workflow — Mandatory Change Procedure

## Purpose
This document enforces the golden rules by requiring a strict step-by-step workflow. **You must acknowledge each checkpoint before proceeding.** Skipping steps is not allowed.

## When to Use
Every time you create or modify:
- Shell scripts (`.zsh`, `.sh`, `.tcsh`)
- Makefiles (`Makefile` in any directory)

## The Workflow

### Phase 1 — Plan
Before making any changes, state:
1. **What** you are changing (file paths)
2. **Why** (the goal)
3. **Which checks** will run after each change

### Phase 2 — Execute (One Change at a Time)
For **each** file you are modifying:

1. Make the change
2. Run the appropriate check:
   - Shell scripts → `<shell> -n <script>` (zsh, bash, tcsh per shebang)
   - GNU Makefiles → `make -n` (in the directory containing the Makefile)
   - BSD Makefiles → `bmake -n` (in the directory containing the Makefile)
3. **STOP** — review the output carefully
4. If it passes → proceed to next file
5. If it fails → **STOP**, fix the error, re-test from step 2

**You must NOT make a second change until the current file's check passes.**

### Phase 3 — Verify
After all files pass their checks:
1. List every file you modified and confirm each passed its check
2. If any was modified without a passing check → STOP, run the check now

## Checkpoint Acknowledgment
Before starting any task that involves file changes, you must state:

> "I will follow the golden-workflow. I will make one change, test it, fix if needed, then proceed to the next file."

## Examples

### Correct
```
1. Edit src/fedora/cpp/tests/Makefile → add probe-os rule
2. Run: make -n (in src/fedora/cpp/tests/) → PASS ✓
3. Edit src/debian/cpp/tests/Makefile → add probe-os rule
4. Run: make -n (in src/debian/cpp/tests/) → PASS ✓
5. Edit src/ubuntu/cpp/tests/Makefile → add probe-os rule
6. Run: make -n (in src/ubuntu/cpp/tests/) → PASS ✓
...repeat for each file
```

### Incorrect (what happened)
```
1. Edit all 8 Makefiles at once
2. Run make -n on fedora → FAIL (wrong path)
3. Fix all 8 paths at once
4. Run make -n on remaining → some pass, some fail
```

## Self-Check Before Finishing
Ask yourself:
- Did I test each file immediately after editing it?
- Did any check fail that I didn't fix before moving on?
- Is there any file I modified without running a check?

If the answer to #2 or #3 is "yes" → STOP and fix it.
