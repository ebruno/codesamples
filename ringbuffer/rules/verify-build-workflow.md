# Build Verification & Regression Workflow Rules

These rules apply when using `verify_build.md` or `run_regression.md`. They are extracted from `.bionic` for modular loading.

---

### Pre-Modification Re-Read Rule (verify_build.md and run_regression.md)

Before modifying `prompts/common/verify_build.md` or `prompts/common/run_regression.md`, you MUST re-read the Build Verification Workflow section of `.bionic` to ensure all changes comply with the source-of-truth rules.

**Procedure:**
1. Read `.bionic` section "Build vs Test Workflow Pattern (All Languages)" — confirms `verify_build → make all`, `run_regression → tests/Makefile verify`
2. Read `.bionic` section "Remote Build/Testing Workflow (Enforced)" — confirms SSH clean + copy pattern
3. Read `.bionic` section "Shell Script Portability Rule" — confirms tcsh compliance for FreeBSD 14
4. Read `.bionic` section "Container naming is unified per OS" — confirms `ringbuffer_<os>_build` and `ringbuffer_<os>_test` naming
5. Verify your planned changes against all of the above before writing any edits

**If you find yourself about to modify these files without re-reading `.bionic`, STOP — go read it first.**

This rule is self-referential: if you are reading this, you have already read it.

---

### Workflow Execution Discipline

- **When asked to use `verify_build.md` or `run_regression.md`, you MUST follow them exactly with no exceptions.**
- **NEVER skip steps, shortcut the workflow, or execute only a subset of the specified actions.**
- **NEVER assume you know what is needed and bypass the workflow document.** Every step in the workflow must be executed in order.
- **If a workflow says to run `lint_prompts.sh`, run it. If it says to generate a report, generate it. If it says to update `.gen_state.json`, do it.**
- **The workflow documents are the single source of truth for execution order and completeness. If you find yourself about to skip a step, STOP — go back and re-read the workflow.**
- This rule is self-referential: if you are reading this, you have already read it.

---

### Pre-Action Checklist (MANDATORY — Enforces Workflow Discipline)

**Before executing ANY command, script, or workflow step, you MUST state all three items below. If you cannot state all three, STOP and re-read the workflow document.**

1. **Source Document** — Name the exact file and section you're following (e.g., "Following `prompts/common/run_regression.md`, Step 5: Python Test Execution")
2. **Exact Command** — Quote the command verbatim from the document (e.g., `make -C src/common/python/tests verify`)
3. **No Unsolicited Actions** — Explicitly confirm: "No manual checks, no container status verification, no bypassing the Makefile"

**Example — Correct:**
```
Source: prompts/common/run_regression.md, Step 5 (Python Test Execution)
Command: make -C src/common/python/tests verify
No unsolicited actions: Confirmed — Makefile handles container detection and execution
Executing...
```

**Example — Violation (what has happened repeatedly):**
```
Checked container system status  ← NOT in workflow document
Ran container image list         ← NOT in workflow document
Executed container run directly  ← Makefile handles this
```

**This rule is self-referential: if you are reading this, you have already read it.**

---

### Build vs Test Workflow Pattern (All Languages)

Every language follows the same two-step pattern:

1. **`verify_build`** → `<os>/<lang>/Makefile all` (build only, no tests)
   - C/C++: `src/<os>/cpp/Makefile all` → builds static + shared libs, creates symlinks
   - Java: `src/common/java/Makefile all` → runs Maven, creates JAR symlink
   - Python: `src/common/python/Makefile all` → builds C++ shared lib, creates symlink
   - **Never** runs tests — only produces build artifacts and symlinks

2. **`run_regression`** → `tests/Makefile verify` (build + test matrix T001-T007)
   - C/C++: `src/<os>/cpp/tests/Makefile verify` → runs test harness with T001-T007
   - Java: `src/common/java/tests/Makefile verify` → runs TestRingbuffer T001-T007
   - Python: `src/common/python/tests/Makefile verify` → runs Concurrent + Pure Python T001-T007
   - The `tests/Makefile` has a `test: verify` target so `make test` also works

**Golden rule:** Never use `tests/Makefile verify` for build verification. Never use `<os>/<lang>/Makefile all` for regression testing.

**CRITICAL — DO NOT CONFUSE:**
- `verify_build` → **always** uses `make all` (build only, no tests)
- `run_regression` → **always** uses `make verify` in the `tests/` directory (build + T001-T007)
- If you find yourself about to run `make verify` during `verify_build`, STOP — that is wrong.
- If you find yourself about to run `make all` during `run_regression`, STOP — that is wrong.

**SELF-CHECK BEFORE EXECUTING:**
- Am I in `verify_build`? → Must run `make all`, NOT `make verify`
- Am I in `run_regression`? → Must run `make verify`, NOT `make all`
- If unsure, re-read the workflow header to confirm which mode you are in.

---

### Build vs Test Workflow — Pre-Flight Check (MANDATORY)

**Before running ANY `make` command in the build or test workflow, you MUST perform this pre-flight check:**

1. **Identify which workflow mode** you are in:
   - `verify_build` → Build only, no tests
   - `run_regression` → Test matrix T001-T007 (includes build)
2. **State the correct command** for your mode:
   - `verify_build` → Must run `make all` (build only, no tests)
   - `run_regression` → Must run `make verify` in the `tests/` directory (build + T001-T007)
3. **Verify the command matches your mode** — if they don't match, STOP and re-read the workflow header
4. **Verify you are in the correct directory**:
   - `verify_build` → `<os>/<lang>/Makefile all`
   - `run_regression` → `tests/Makefile verify`
5. **If any violation is found**, STOP and re-read the workflow header to confirm which mode you are in

**This check is mandatory — not optional.** Confusing `make all` with `make verify` has caused tests to run during build verification (masking real problems) and builds to be skipped during regression testing. The rule exists in `.bionic` but must be actively verified before each `make` command.

**Example — Pre-Flight Check in Action:**
```bash
# ❌ BEFORE pre-flight check: running make verify during verify_build (wrong!)
cd src/macos/cpp && make verify  # ← This runs tests during build verification

# ✅ AFTER pre-flight check: verify_build → must use make all
cd src/macos/cpp && make all  # ← Build only, no tests

# ❌ BEFORE pre-flight check: running make all during run_regression (wrong!)
cd src/macos/cpp/tests && make all  # ← This skips the test matrix

# ✅ AFTER pre-flight check: run_regression → must use make verify
cd src/macos/cpp/tests && make verify  # ← Build + T001-T007 test matrix
```

---

### Standard Clean + Build Process (When C++ Is Used)

For any language that depends on the C++ shared library (Python, and future languages with C bindings), the standard process before running `make all` in the language directory is:

1. **`make clean`** in `<os>/cpp/` — removes stale C++ library artifacts (`.a`, `.so`, `.dylib`, object files)
2. **`make clean`** in `<os>/<lang>/` (or `src/common/<lang>/`) — removes stale language-specific build artifacts
3. **`make all`** in `<os>/<lang>/` (or `src/common/<lang>/`) — builds C++ library, creates symlinks

**Why this matters:** If the C++ library was previously built for a different platform (e.g., ELF ARM64 inside a container), stale artifacts on the host will cause linker errors (e.g., `archive member not a mach-o file`). Cleaning both the C++ and language directories ensures no stale artifacts remain.

**Example — Python on macOS:**
```bash
cd src/macos/cpp && make clean          # Remove stale C++ library
cd src/common/python && make clean      # Remove stale Python artifacts
cd src/common/python && make all        # Build C++ lib, create symlinks
```

**Example — Python on Fedora (from macOS host):**
```bash
cd src/fedora/cpp && make clean         # Remove stale C++ library
cd src/common/python && make clean      # Remove stale Python artifacts
cd src/common/python && make all        # Builds inside container via Makefile
```

---

### Verification Scripts

The project includes two automated verification scripts in `prompts/common/cpp/utils/bin/`:

1. **`verify_binary_symmetry.sh`** (also `.zsh`) — Compares source files across Linux platforms to ensure byte-identical output. Run after building all Linux platforms:
   ```bash
   ./prompts/common/cpp/utils/bin/verify_binary_symmetry.sh <workspace_root>
   ```
   - Exit 0: All files identical (symmetry verified)
   - Exit 1: Differences found (symmetry violation)

2. **`lint_prompts.sh`** (also `.zsh`) — Validates prompt directory structure, required files, excluded platform cleanliness, and common workflow completeness. Run before or after any generation:
   ```bash
   ./prompts/common/cpp/utils/bin/lint_prompts.sh <workspace_root>
   ```
   - Exit 0: All checks passed
   - Exit 1: Errors found (structural issues)

These scripts are referenced by `verify_build.md` and should be run as part of the build verification workflow.

---

### Lint Script Update Discipline

The lint scripts (`lint_prompts.sh`, `lint_prompts.zsh`) are the **single source of truth for prompt directory validation**. They should only be updated in these cases:

1. **New required structure** — A new prompt file, directory, or convention has been added to the project (e.g., a new language spec, a new OS scaffold). The lint script must be updated to validate the new structure.

2. **Removed/renamed structure** — A prompt file, directory, or convention has been removed or renamed. The lint script must be updated to stop checking for the old structure and check for the new one.

3. **False positive bug** — The lint script incorrectly flags a valid structure as an error (e.g., it checks for `prompts/common/` but the actual path is `common/` relative to PROMPTS_ROOT). Fix the script, not the prompts.

4. **New validation category** — A new type of check is needed (e.g., checking for duplicate step numbers, verifying report format compliance).

**When NOT to update the lint script:**
- **Do not add new entries to `EXCLUDED_PLATFORMS` or `PARTIAL_PLATFORMS`** just because a platform has expected non-standard content. Instead, evaluate whether the platform should be excluded/partial or whether its content needs fixing.
- **Do not silence warnings** for platforms that should be passing checks (e.g., don't add `archlinux` to `EXCLUDED_PLATFORMS` just because it has non-zero content — fix the content or confirm exclusion is correct).
- **Do not change `report_warning` to `report_pass`** (or vice versa) without confirming the underlying state is actually correct. The report level reflects whether a check result is acceptable, not convenience.

**Procedure:**
1. When the lint script reports an error or warning, first determine: is this a **real structural issue** (fix the prompts) or a **script bug** (fix the script)?
2. If fixing the script, update all variants (`.sh`, `.zsh`) consistently.
3. After any lint script change, re-run the full lint check and confirm **111/111 checks pass with 0 warnings and 0 errors** before considering the change complete.
4. Record the change in `prompts/common/CHANGELOG.md` with rationale.

**Automation Modes:**
The lint script supports two automation modes for triage and self-validation:

- **`--triage`** — Runs the full lint check but categorizes each result into one of four categories:
  - `PASS` — Check passed, no action needed
  - `REAL_ISSUE` — Real structural problem in prompts (fix the prompts)
  - `SCRIPT_BUG` — Lint script incorrectly flags valid structure (fix the script)
  - `LEGAL_STATE` — Expected state for excluded/partial platforms
  
  Usage: `./lint_prompts.sh <workspace_root> --triage`
  
  Output includes a summary grouped by category with rationale for each categorization.

- **`--self-audit`** — Validates the lint script's own configuration:
  - Every entry in `EXCLUDED_PLATFORMS` must have zero-length prompt files (or only exclusion messages)
  - Every entry in `PARTIAL_PLATFORMS` must have non-zero content (otherwise it should be excluded or fixed)
  - Every required file path in the check list must exist somewhere in the prompts tree (catches typos)
  - No duplicate check definitions
  
  Usage: `./lint_prompts.sh <workspace_root> --self-audit`
  
  Exit 0: Script configuration is valid. Exit 1: Issues found in script configuration.
