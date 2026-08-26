## 7. Operational Discipline

### Makefiles Are the CI/CD Contract (All OS, All Languages)

**This is not optional.** At some point this project will run in a CI/CD pipeline with zero LLM support. The Makefiles are the contract — they must be self-contained, idempotent, and handle everything without human or agent intervention. This applies to **every Makefile in the project**, regardless of OS, language, or platform.

**What this means:**
- **Makefiles own the logic** — container detection, image building, test execution, report generation. The agent never bypasses a Makefile with ad-hoc shell commands.
- **No manual pre-checks** — CI/CD won't have an LLM to "check container status first" or "verify the image exists." The Makefile must handle all of that.
- **Fail fast with clear errors** — if a dependency is missing, the Makefile should fail with a helpful message, not a cryptic error.
- **Idempotent** — `make verify` produces the same result every time. No state leakage between runs.
- **Never mask Makefile bugs** — if a command fails, do NOT work around it with manual steps. Fix the Makefile so it works correctly on its own.

**Agent discipline:**
- When a Makefile target fails, **do not** manually run the underlying commands to "get past" the failure. The Makefile is wrong — fix it.
- When asked to build or test, **always** use `make <target>` — never run the equivalent shell commands directly.
- If you find yourself about to bypass a Makefile step, **STOP** — that's exactly what CI/CD will do too.
- Treat every Makefile failure as a bug in the Makefile, not a problem to work around.

**This rule is self-referential: if you are reading this, you have already read it.**

### Read-Before-Write
Always read a file before modifying it. If a write fails due to concurrent modification, re-read and retry once.

### Path Resolution
- **Workspace root:** `ringbuffer/` — all relative paths resolve from here
- **Source directory:** `ringbuffer/src/<os>/cpp/` — this is where generated code lives

### Timestamp Format
All timestamps MUST include timezone offset: `[YYYY-MM-DD HH:MM:SS +/-HHMM]`
- Use `date '+%Y-%m-%d %H:%M:%S %z'` on both Linux and macOS (BSD date supports `%z`)

### Logging
- Every action MUST be logged to `ringbuffer/src/<os>/cpp/logs/build.log` (or platform-specific log)
- Log format: `[timestamp] <action description>`
- Initialize logs at the start of each workflow step

### Scope Boundaries
Each workflow has a defined scope. Do NOT:
- Execute tests from build workflows
- Create test infrastructure from functional workflows
- Modify files outside the declared scope directory

### Remote Build/Testing Workflow (Enforced)
When building or running regression tests on a remote system via SSH, **always** follow this sequence:

1. **Make changes locally.** All source edits happen in the workspace on the local machine (git-tracked, reviewable).
2. **SSH to remote → delete everything:** 
   ```bash
   ssh <host> "rm -rf ~/ringbuffer"
   ```
3. **Create a tarball of the ENTIRE ringbuffer directory from the parent:**
   ```bash
   tar -czf /tmp/ringbuffer_<os>.tar.gz -C .. ringbuffer
   ```
4. **SCP tarball over → unpack on remote at ~/ringbuffer:**
   ```bash
   scp /tmp/ringbuffer_<os>.tar.gz <host>:~/
   ssh <host> "cd ~ ; tar -xzf ringbuffer_<os>.tar.gz"
   ```
5. **Run build/test remotely:**
   - For `verify_build`: `ssh <host> "cd ~/ringbuffer/src/<os>/cpp && make clean && make all"`
   - For `run_regression`: `ssh <host> "cd ~/ringbuffer/src/<os>/cpp && make clean; cd src/<os>/cpp/tests && make clean && make verify"`
   - For Python: build C++ lib first, then run Python tests
   - FreeBSD 14 uses `/bin/sh` or `tcsh` as the shell for make commands (Makefile default)

**Rules:**
- **Never edit files directly on the remote.** All changes start locally.
- **Always delete everything on remote before copying** — this emulates a clean git checkout and prevents stale files from previous builds.
- **Use `tar -czf /tmp/ringbuffer_<os>.tar.gz -C .. ringbuffer`** to create the tarball from the parent directory, preserving the `ringbuffer/` top-level path inside the archive.
- **Use tarball + SCP** (not `scp -r` of individual files) for reliable, atomic transfers.
- **Verify after transfer** — confirm file counts and sizes match between local tarball contents and remote unpacked files.
- **FreeBSD 14:** Default shell is `tcsh`. All inline SSH commands must be tcsh-compliant (use `;` not `&&`, avoid `$()`, avoid `2>&1`). For build/test commands, use a tcsh script: `tcsh /tmp/run_freebsd_native_or_ssh.tcsh ~/ringbuffer <os> <mode>` where `<mode>` is one of: `cpp`, `test-cpp`, `python-build`, `python-test`, `java-build`, `java-test`.
- **Arch Linux:** Default shell is `bash`. Inline `&&` commands are safe.

**SSH Host Configuration (User-Provided):**
The following SSH hosts must be provided by the user before any remote operations. If not provided, STOP and ask the user for them:
- **`<freebsd_host>`** — FreeBSD 14 SSH host (e.g., `<user>@<IP address|FQDN>`)
- **`<archlinux_host>`** — Arch Linux SSH host (e.g., `<user>@<IP address|FQDN>`)

All SSH commands in `verify_build.md` and `run_regression.md` use these placeholders — never hardcode IP addresses or usernames.

### SSH Host Resolution Rule (Session-Only)

SSH host placeholders (`<freebsd_host>`, `<archlinux_host>`) in prompts and scripts must NEVER be replaced with actual values. The agent MUST resolve them at runtime from a local config file.

**Procedure:**
1. When an SSH operation is needed, check for `config/ssh_hosts.json` in the workspace root.
2. If it exists, read the JSON and extract only the value for the target being processed:
   - For FreeBSD 14 → read `freebsd_host` key only
   - For Arch Linux → read `archlinux_host` key only
3. If the config file does NOT exist, or the required key is empty: STOP and ask the user to provide it.
4. If the user provides SSH info verbally (e.g., "use `<user>@<IP address|FQDN>` for Arch Linux"), acknowledge it and create/update `config/ssh_hosts.json` with the value.
5. Use the resolved values ONLY for the current session — never write them back to prompts, scripts, or any tracked files.
6. The config file is gitignored and must never be committed.

**This rule is self-referential: if you are reading this, you have already read it.**

<!-- RULES-LOAD: verify-build -> rules/verify-build-workflow.md -->


### Common Pitfalls
1. **Shell ENOENT after session compaction (cross-platform: macOS + Windows):** If `shell_command` fails instantly with `spawn ... ENOENT`, the harness's default cwd resolution produces a subpath under the scratchpad that was never created. **Diagnosis:** The bug is not about the shell binary being missing — it is about the harness computing a cwd path that does not exist on disk. The spawn error masquerades as a broken Git/zsh/bash install but the shell binary is fine. **Fix:** Pass an explicit `workdir` set to any existing directory (e.g., the project root). This is the primary fix — it should work on the first try. If it still fails, run one sandboxed-Python call that writes an output file first (materializes the scratchpad), then retry with explicit `workdir`. **Remove this note once LM Studio fixes the bug.**
2. **Makefile tabs:** Makefiles require real tab characters, not spaces. Use Python or heredocs with explicit `\t` when generating Makefiles programmatically.
3. **Directory pre-creation:** Always `mkdir -p` before writing to a directory (e.g., `reports/`, `logs/`).
4. **`make clean` loops over all languages:** The main Makefile's `clean` target iterates over C++ (`src/*/cpp/`), Java (`src/common/java/`), and Python (`src/common/python/`) directories, calling `make clean` in each. Per-directory Makefiles handle actual artifact removal (e.g., C++ removes `build/`, `lib/`; Java removes `target/`; Python removes `__pycache__/`, `.egg-info/`, `build/`).
5. **`dist-clean` reports elapsed time:** The top-level `dist-clean` target captures a start timestamp at the beginning of `clean`, then after all dist-work completes, prints `Dist-clean completed in HH:MM:SS`. A `.ringbuffer_start` temp file passes the start time from `clean` to `dist-clean`.
6. **`.ringbuffer_start` is a temp file:** The `.ringbuffer_start` file stores the epoch seconds captured at `clean` start. It is read and deleted by `dist-clean` after computing elapsed time. Do not commit it to git.
7. **`dist-clean` must recurse:** The `dist-clean` target MUST check for and clean the `tests/` directory if it exists.
8. **Version vs OS version:** `version.mk` contains the Ringbuffer library version (e.g., 1.0.0), NOT the OS version.
9. **Script deployment path:** From `tests/`, common utility scripts are at `../../../../prompts/common/cpp/utils/bin/`.
10. **FreeBSD 14 RPATH limitation:** FreeBSD 14's `ld-elf.so.1` does NOT support `$ORIGIN` in RUNPATH — the dynamic linker strips it to empty at runtime. **Dynamic library testing is not possible on FreeBSD 14.** Use static library only (via `make verify` target). See [freebsd-platform-analysis.md](prompts/common/appendices/freebsd-platform-analysis.md) for details.
11. **Container naming is unified per OS, not per language:** There are exactly 2 containers per OS: `ringbuffer_<os>_build` (for verify_build) and `ringbuffer_<os>_test` (for run_regression). Never use per-language container names like `ringbuffer_python_fedora` or `ringbuffer_java_debian_test`. The Makefile variables are `OS_BUILD_IMAGES` and `OS_TEST_IMAGES`.
12. **Dockerfiles are at `src/<os>/containers/`, not in language directories:** The unified Dockerfile for each OS lives at `src/<os>/containers/build/Dockerfile` and `src/<os>/containers/test/Dockerfile`. Old paths like `src/common/python/containers/fedora/build/Dockerfile` no longer exist.
13. **Build and test Dockerfiles are identical:** Both install the full toolset for all languages. There is no inheritance between them — each inherits only from the base OS image.
14. **`make container` in language Makefiles builds both build and test images:** The `container-build-%` target builds `ringbuffer_<os>_build`, and `container-test-%` depends on it to build `ringbuffer_<os>_test`. Both use the same Dockerfile path (`../../$(OS_$*_DIR)/containers/build/Dockerfile` or `test/Dockerfile`).

<!-- RULES-LOAD: container -> rules/container-rules.md -->
<!-- RULES-LOAD: container -> rules/container-naming.md -->
<!-- RULES-LOAD: container -> rules/container-dockerfile.md -->
<!-- RULES-LOAD: archlinux -> rules/archlinux-pinning.md -->
<!-- RULES-LOAD: macos -> rules/container-commands-macos.md -->
### Prompt Changelog Discipline
When modifying any prompt file that affects generated code, record the change in `prompts/common/CHANGELOG.md` using this format:
```markdown
## [YYYY-MM-DD] <short description>
- **File**: `prompts/<path>/functional.md`
- **Change**: <one-line description>
- **Rationale**: <why this change was made>
```
This is a documentation discipline — no automation logic uses the changelog at this time. The `utils/bin/suggest_changelog_entry.sh` script can analyze git diffs and suggest entries for manual review.

### Prompt Deduplication Discipline
Before adding repeated content (container runtime rules, host-target compatibility, spec precedence) to a new or existing prompt file:
1. Check if the content already exists in `prompts/common/session_hints.md` or another shared reference document.
2. If it does, add a relative link instead of duplicating the text.
3. If it doesn't, add it to `prompts/common/session_hints.md` first, then reference it from the platform-specific prompt.

<!-- RULES-LOAD: readme-update -> rules/mermaid-validation.md -->

---

**IMPORTANT: This .bionic file was auto-loaded at session startup. Please acknowledge and follow the instructions above.**

# Session Initialization
- At the start of every new session, your first response to the user must explicitly begin with: "✅ [.bionic configuration successfully loaded]" before addressing the user's prompt.

# Transitory Markers
- `.dockerfile_created_by_step0` is a transitory workflow marker — add it to `.gitignore` and remove from git tracking. It has no functional purpose beyond prompt execution coordination.
- `.required_directory` files are **NOT** transitory — they preserve directory structure in git when directories contain no other tracked files. Do **NOT** add them to `.gitignore`.

# File Writing Discipline — Critical (Learned 2026-08-18)

## When `edit_file_tool` or `replace_file` Fails Silently
If these tools appear to succeed but the file is not actually modified:

1. **The tool may be silently failing** — do NOT retry the same approach
2. **Use `shell_command` with a heredoc** to overwrite: `cat > path/to/file << 'EOF' ... EOF`
3. **For large files (>5KB)**, split into chunks:

### Chunked Write Pattern (Proven to Work)
```
Step 1: run_python → write chunk A to /outputs/chunkA.txt (sandbox)
Step 2: run_python → write chunk B to /outputs/chunkB.txt (sandbox)
Step 3: run_python → write chunk C to /outputs/chunkC.txt (sandbox)
Step 4: shell_command → cat chunkA chunkB chunkC > target/path/file.md (host)
```

- Each `run_python` call writes to `/outputs/` (sandbox filesystem, always works)
- Each chunk should be **under 8KB** to avoid timeouts
- `deliver_file_to_user` can also copy from scratchpad to workspace if needed
- **NEVER** try `edit_file_tool` or `replace_file` more than once on the same file without success

### Why This Works
- `run_python` runs in an isolated sandbox — `/outputs/` is its writable working directory
- `shell_command` runs on the host with full filesystem access
- The sandbox cannot write to host paths directly — that's why we use `shell_command` for the final assembly

### When to Use Each Method
| Situation | Method |
|-----------|--------|
| New file, small (<5KB) | `shell_command` + heredoc (`cat > file << 'EOF'`) |
| New file, large (>5KB) | Chunked `run_python` + `shell_command cat` assembly |
| Modify existing file (first try) | `edit_file_tool` or `replace_file` |
| Modify existing file (second try fails) | Switch to chunked approach or `shell_command` heredoc |
| Write to sandbox only | `run_python` → `/outputs/` |

## Docker vs Container Golden Rule (macOS)
- **macOS host:** NEVER use `docker` or `podman`. Only use the `container` CLI (Apple Container).
- **Linux host:** Use `podman` (preferred) or Docker.
- **Never prepend `localhost/`** to image names with the `container` CLI on macOS.
- **Never use Docker references in macOS context** — even comparison phrases like "(equivalent to docker run)" can mislead agents into using `docker` instead of `container`.

### Docker vs Container — Pre-Flight Check (MANDATORY)

**Before writing or modifying ANY script that invokes a container runtime, you MUST perform this pre-flight check:**

1. **Identify the target host OS** — Is it macOS, Linux (which distro?), or something else?
2. **List every container command** you plan to use in the script (`docker`, `podman`, or `container`)
3. **Verify each command against the host OS:**
   - macOS → must use `container` only. If any `docker` or `podman` appears, STOP and replace.
   - Linux → must use `podman` (preferred) or `docker`. If any `container` appears, STOP and replace.
4. **Verify no `localhost/` prefix** on macOS — image names must be bare (e.g., `fedora:44`, NOT `localhost/fedora:44`)
5. **Verify no Docker references in macOS context** — even comparison phrases like "(equivalent to docker run)" are forbidden
6. **If any violation is found**, STOP and find the correct command for the target host OS

**This check is mandatory — not optional.** Using the wrong container runtime breaks everything on macOS and wastes time debugging. The rule exists in `.bionic` but must be actively verified before each script write.

**Example — Pre-Flight Check in Action:**
```bash
# ❌ BEFORE pre-flight check: uses docker on macOS (will fail)
podman build -t ringbuffer_fedora_build .

# ✅ AFTER pre-flight check: macOS host → use container CLI
container image build -t ringbuffer_fedora_build .
```

**Example — Linux Host:**
```bash
# ❌ BEFORE pre-flight check: uses container on Linux (will fail)
container run --rm ringbuffer_fedora_test make verify

# ✅ AFTER pre-flight check: Linux host → use podman
podman run --rm ringbuffer_fedora_test make verify
```

### Shell Script Portability Rule — No Platform-Dependent External Tools in Bash/Zsh

When creating or modifying shell scripts (`.sh`, `.zsh`), **do not use external tools whose behavior differs across platforms** — rely only on built-in shell features and universally available utilities. This applies to all scripts in the repository, including those in `prompts/`, `utils/bin/`, and any other script directories.

**Supported shells:**
- **Bash (`bash`)** — primary target for all scripts
- **Zsh (`zsh`)** — acceptable alternative (macOS default)

**Restricted shells:**
- **POSIX `sh`** and **`tcsh`** — not feature-rich enough for the project's needs. If a script must run under `sh` or `tcsh`, using external tools is permitted **only if absolutely necessary** and documented with a comment explaining why.

**What counts as a platform-dependent external tool (forbidden in bash/zsh scripts):**
- **`awk`** — behavior and available features vary significantly between `gawk`, `mawk`, BSD `awk`
- **`sed`** — syntax differences between GNU `sed` and BSD `sed` (e.g., `-i` flag, extended regex)
- **`grep`** — feature flags (`-P`, `-E`) and behavior differ between GNU `grep` and BSD `grep`; also, basic regex syntax varies
- **`cut`, `tr`, `sort`, `uniq`** — minor behavioral differences across implementations
- **`find`, `xargs`** — flag syntax and behavior differ between GNU and BSD implementations
- **Any other utility not provided by the shell itself** whose behavior is not guaranteed to be identical across macOS (BSD) and Linux (GNU)

**Permitted CLI tools (explicit allowlist):**
The following external tools are explicitly permitted in bash/zsh scripts because their behavior is consistent across macOS (BSD) and Linux (GNU):
- **`jq`** — JSON parsing, reading `config/toolchains.json` and other JSON config files
- **`date`** — timestamp generation (already used throughout the project)
- **`cat`** — file concatenation and display
- **`mkdir -p`** — directory creation
- **`rm -rf`** — recursive removal
- **`cp`** — file copying
- **`mv`** — file moving/renaming
- **`chmod`** — permission changes

All other external tools are forbidden unless an exception is documented with a comment explaining why no builtin equivalent exists.

**What is permitted (shell builtins only):**
- **Shell builtins**: `echo`, `printf`, `test`/`[`, `[[`, `read`, `export`, `source`, `local`, `declare`, arrays, parameter expansion (`${var//pattern/replacement}`, `${#array[@]}`, `${file%.txt}`, etc.), arithmetic expansion `$((...))`, globbing
- **`echo` and `printf`**: Use `printf` preferentially (more portable than `echo` across shells)

**Rationale:**
- Tools like `grep`, `sed`, and `awk` have different implementations on macOS (BSD) vs. Linux (GNU), leading to subtle bugs when scripts are run across platforms
- Scripts that rely only on builtins and universally available utilities are maximally portable without requiring additional package installations
- Reduces dependency surface — no need to verify that `gawk`, GNU `sed`, or GNU `grep` are installed
- Simpler to reason about — no pipeline complexity, no quoting edge cases with external tool output

**Example — Forbidden:**
```bash
# ❌ Uses platform-dependent tools (awk, sed)
count=$(echo "$data" | awk '{print NF}')
path=$(echo "$file" | sed 's/\.txt$//')
lines=$(grep -c "pattern" file.txt)   # grep -c behavior varies; use builtin instead
```

**Example — Allowed:**
```bash
# ✅ Uses builtins only
read -ra fields <<< "$data"
count=${#fields[@]}
path="${file%.txt}"

# ✅ date is permitted (already used throughout the project)
timestamp=$(date '+%Y-%m-%d %H:%M:%S %z')

# ✅ Standard POSIX utilities with guaranteed behavior
mkdir -p "$dir"
cat file1.txt file2.txt > combined.txt
```

**Exception for `sh`/`tcsh`:**
If a script must target POSIX `sh` or `tcsh`, external tools may be used when the shell lacks native equivalents. Document the reason with a comment:
```bash
# NOTE: Using `grep` here because POSIX sh lacks native regex matching and tcsh has no arrays
matches=$(grep -c "pattern" file.txt)
```

**Exception for Makefile recipes:**
Makefile recipe lines execute under `/bin/sh -c`, which is a restricted POSIX shell environment. Bash/zsh builtins like arrays, `<<<` (here-strings), and `[[ ]]` are **not available**. Makefile recipes may use external tools (`grep`, `sed`, `awk`, etc.) as needed, since the shell is already POSIX sh and cannot support bash/zsh builtins anyway. This exception does **not** apply to standalone shell scripts called *from* Makefiles — those must still follow the rule above.

```makefile
# ✅ Allowed in Makefile recipes (limited /bin/sh environment)
count := $(shell grep -c "pattern" file.txt)   # grep is fine here

# ❌ NOT allowed — bash builtins won't work in Makefile recipes
count := $(shell read -ra fields <<< "$data")   # here-strings don't exist in /bin/sh
```

### Shell Script Portability — Pre-Flight Check (MANDATORY)

**Before writing or modifying ANY shell script (`.sh`, `.zsh`), you MUST perform this pre-flight check:**

1. **List every external tool** you plan to use in the script (anything not a bash/zsh builtin)
2. **Cross-reference against the forbidden list**: `awk`, `sed`, `grep`, `cut`, `tr`, `sort`, `uniq`, `find`, `xargs`
3. **Replace each forbidden tool** with a bash/zsh builtin equivalent:
   - `grep` → `case` pattern matching or `[[ "$var" == *pattern* ]]`
   - `sed 's/old/new/'` → `${var//old/new}` parameter expansion
   - `awk '{print $1}'` → read into array with `read -ra`
   - `wc -l` → count lines using bash arithmetic or array length `${#array[@]}`
   - `head -1` → read first line with `IFS= read -r first_line`
   - `tail -1` → use array indexing `${array[-1]}`
4. **If you cannot find a builtin equivalent**, document why in a comment and use the external tool with an exception note
5. **Verify compliance** — if any forbidden tool remains in the script after this check, STOP and find a builtin replacement

**This check is mandatory — not optional.** The rule exists in `.bionic` but must be actively verified before each script write. Relying on memory alone has led to violations.

**Enforcement:** The step-by-step workflow for this rule is defined in `rules/shell-portability-workflow.md`. You MUST follow that document's Phase 1 (Plan), Phase 2 (Execute with builtin-only, scan for forbidden tools), and Phase 3 (Verify) before proceeding. See `rules/shell-portability-workflow.md` for the full procedure.

**Example — Pre-Flight Check in Action:**
```bash
# ❌ BEFORE pre-flight check: uses grep (forbidden)
count=$(grep -c "pattern" file.txt)

# ✅ AFTER pre-flight check: uses bash builtin
count=0
while IFS= read -r line; do
    case "$line" in
        *pattern*) count=$((count + 1)) ;;
    esac
done < file.txt
```

### Script and Makefile Syntax Verification — Pre-Flight Check (MANDATORY)

**Before committing or using ANY shell script or Makefile, you MUST verify syntax and workflow correctness.** This is not optional — silent failures in scripts and Makefiles cause cascading bugs that are expensive to debug later.

**What must be checked:**
- **All shell scripts** (`.zsh`, `.sh`, `.tcsh`) → run `<shell> -n` for syntax and logic verification
- **BSD Makefiles** (FreeBSD targets) → run `bmake -n` for syntax and workflow verification
- **GNU Makefiles** (macOS, Linux targets) → run `make -n` for syntax and workflow verification

**Procedure:**
1. **List every script/Makefile** you created or modified in the current task
2. **Run syntax check on each:**
   - Shell scripts: `<shell> -n <script>` (use `zsh -n`, `bash -n`, or `tcsh -n` depending on the script's shebang)
   - BSD Makefiles: `bmake -n -f <Makefile>` (in the directory containing the Makefile)
   - GNU Makefiles: `make -n -f <Makefile>` (in the directory containing the Makefile)
3. **If any check fails**, STOP and fix the script/Makefile — do not proceed
4. **If any check produces unexpected output**, review it carefully — `-n` (dry-run) reveals the full execution plan, not just syntax errors
5. **Verify compliance** — if any script or Makefile was modified without a passing syntax check, STOP and run it

**This check is mandatory — not optional.** The rule exists in `.bionic` but has been violated because the syntax check step was skipped. Relying on memory alone has led to broken scripts and Makefiles in production.

**Example — Pre-Flight Check in Action:**
```bash
# ❌ BEFORE pre-flight check: wrote scripts without syntax checking
cat > utils/bin/run_test.zsh << 'EOF'
#!/usr/bin/env zsh
# ... script content ...
EOF
chmod +x utils/bin/run_test.zsh
# ... proceeds to use broken script ...

# ✅ AFTER pre-flight check: verified syntax before using
cat > utils/bin/run_test.zsh << 'EOF'
#!/usr/bin/env zsh
# ... script content ...
EOF
chmod +x utils/bin/run_test.zsh
zsh -n utils/bin/run_test.zsh   # ← MUST pass with exit code 0
bmake -n -f src/freebsd14/cpp/Makefile   # ← BSD Makefile check
make -n -f src/macos/cpp/Makefile         # ← GNU Makefile check
# ... only proceed if all checks pass ...
```

**Shell-to-script mapping:**
| Script extension | Shebang | Syntax check command |
|------------------|---------|---------------------|
| `.zsh` | `#!/usr/bin/env zsh` | `zsh -n <script>` |
| `.sh` | `#!/usr/bin/env bash` or `#!/usr/bin/env sh` | `bash -n <script>` |
| `.tcsh` | `#!/usr/bin/env tcsh` | `tcsh -n <script>` |

**Makefile type detection (verified on the development host):**

The **development host** is always macOS or a Linux distribution — code is written here and then deployed to the target. FreeBSD is only a deployment target, never a development environment.

| Makefile location | Make type | Verify on development host |
|-------------------|-----------|---------------------------|
| `src/macos/`, `src/fedora/`, `src/debian/`, `src/ubuntu/`, `src/raspios/`, `src/archlinux/`, `src/common/` | **GNU Make** | `make -n -f <Makefile>` |
| `src/freebsd14/`, `src/freebsd15/` | **BSD Make** (`.include`, `${.CURDIR}`, `.PHONY:`) | `bmake -n -f <Makefile>` |

**Why `bmake` on the development host:** FreeBSD makefiles use BSD syntax. Since the development host runs GNU make, you need `bmake` (BSD make) to syntax-check them locally before deploying. Install with `brew install bmake` (macOS) or your distro's package manager. On FreeBSD itself, native `make` IS BSD make — `make -n` works directly there — but you should never need to verify on FreeBSD; verify on the development host first, then deploy.

**tcsh script verification (on the development host):**

| Script type | Verify on development host |
|-------------|---------------------------|
| `.tcsh` scripts | `tcsh -n <script>` |

**Why `tcsh -n` on the development host:** `.tcsh` scripts are written on macOS/Linux and deployed to FreeBSD. Verify syntax with `tcsh -n` locally before SCP — catches errors without requiring SSH. Install with `brew install tcsh` (macOS) or your distro's package manager. On FreeBSD, tcsh is the native shell and runs directly — but verification happens on the development host, not on FreeBSD.

**tcsh applicability:** tcsh syntax rules apply in these contexts:
- **Writing `.tcsh` scripts** — verify with `tcsh -n` on the development host before deploying
- **Inline SSH commands to FreeBSD** — the remote shell is tcsh, so commands must follow tcsh syntax regardless of where you SSH from (no `2>&1`, use `;` not `&&`, no `$()`)
- tcsh rules do **NOT** apply to `.sh`/`.zsh` scripts, Makefile recipes, or container commands

**This rule is self-referential: if you are reading this, you have already read it.**

**Enforcement:** The step-by-step workflow for this rule is defined in `rules/golden-workflow.md`. You MUST follow that document's Phase 1 (Plan), Phase 2 (Execute one change at a time, test immediately), and Phase 3 (Verify) before proceeding. See `rules/golden-workflow.md` for the full procedure.

### Host OS Check — Mandatory for All Shell Scripts (MANDATORY)

**Every shell script (`.zsh`, `.sh`) MUST include a host OS check at the top of its execution flow.** This prevents scripts from running on unsupported platforms and failing silently or causing data corruption.

**What must be checked:**
- **All `.zsh` scripts** → verify host is macOS (`uname -s = Darwin`) or bypass with `-N`
- **All `.sh` scripts** → verify host is Linux (`uname -s = Linux`) or bypass with `-N`
- **All `.tcsh` scripts** → verify host is FreeBSD (`uname -s = FreeBSD`) or bypass with `-N`

**Procedure:**
1. **Every script MUST define a `BYPASS_OS_CHECK` flag** (default: `false`) that can be set via `-N` argument
2. **Run the check early** — before any work is done, after argument parsing but before main logic
3. **If the check fails and bypass is not set**, print an error message with the detected OS name and exit 1
4. **If bypass is set**, log that the check was bypassed but continue execution (unsafe — for testing only)

**This check is mandatory — not optional.** The rule exists in `.bionic` but has been violated because scripts were written without host OS checks. Relying on memory alone has led to scripts running on wrong platforms.

**Enforcement:** The step-by-step workflow for this rule is defined in `rules/host-os-check-workflow.md`. You MUST follow that document's Phase 1 (Plan — identify shell and required host OS), Phase 2 (Execute — add check after argument parsing, verify with `uname -s`), and Phase 3 (Verify) before proceeding. See `rules/host-os-check-workflow.md` for the full procedure.

**Example — Pre-Flight Check in Action:**
```bash
# ❌ BEFORE pre-flight check: no host OS check
#!/usr/bin/env bash
set -euo pipefail
# ... script does Linux-specific work ...
# Will fail silently or corrupt data if run on macOS

# ✅ AFTER pre-flight check: host OS check included
#!/usr/bin/env bash
set -euo pipefail
BYPASS_OS_CHECK=false
while getopts ":N" opt; do
    case $opt in
        N) BYPASS_OS_CHECK=true ;;
        *) echo "ERROR: Unknown option -$OPTARG"; exit 1 ;;
    esac
done
shift $((OPTIND - 1))
if [ "$BYPASS_OS_CHECK" = false ]; then
    local_host_os=$(uname -s)
    if [ "$local_host_os" != "Linux" ]; then
        echo "ERROR: Running unsupported operating system ${local_host_os}; script requires Linux."
        exit 1
    fi
fi
# ... rest of script ...
```

**Host OS check template by shell:**
| Shell | Expected host | Check command | Error message |
|-------|--------------|---------------|---------------|
| `.zsh` (macOS) | macOS (`Darwin`) | `uname -s = Darwin` | "Running unsupported operating system <os>; script requires macOS." |
| `.sh` (Linux) | Linux (`Linux`) | `uname -s = Linux` | "Running unsupported operating system <os>; script requires Linux." |
| `.tcsh` (FreeBSD) | FreeBSD (`FreeBSD`) | `uname -s = FreeBSD` | "Running unsupported operating system <os>; script requires FreeBSD." |

**This rule is self-referential: if you are reading this, you have already read it.**

### Cross-Platform Script Execution (MANDATORY)

**When the host OS does not match the script's target shell, you may execute the script if the required shell is available on the host.** This allows running `.sh` scripts on macOS and `.zsh` scripts on Linux distros.

**Rules:**
- **macOS host + bash 5.x or higher available**: You may run `.sh` scripts using `bash`.
- **Linux host + zsh 5.x or higher available**: You may run `.zsh` scripts using `zsh`.
- **Version check required**: Before running a cross-platform script, verify the shell version meets the minimum requirement (bash 5.x or zsh 5.x).
- **Creation/modification**: Always run `<shell> -n <script>` before committing or using a script (covered by the Script and Makefile Syntax Verification rule).
- **Execution**: When a user requests to run a script cross-platform, first run `<shell> -n <script>` as a safety check. If it passes, then execute with `<shell> -N <script>`.
- **User request required**: Cross-platform execution only happens when the user explicitly asks to run a script. You do not automatically invoke cross-platform shells during `run_regression.md` or `verify_build.md` workflows — those use the native shell.

**Procedure:**
1. **User requests**: "run script.sh" (or any command that invokes a `.sh` or `.zsh` script).
2. **Check if native shell is available**: If the script's target shell (bash for `.sh`, zsh for `.zsh`) is available on the host, use it directly.
3. **If native shell not available**, check for cross-platform alternative:
   - macOS host → `bash --version` (must be 5.x or higher)
   - Linux host → `zsh --version` (must be 5.x or higher)
4. **Run syntax check**: `<shell> -n <script>` — if it fails, report errors and stop.
5. **Run actual execution**: `<shell> -N <script>` — the `-N` flag bypasses the script's internal host OS check.
6. **If cross-platform shell not available or version too low**, report that the script cannot be run on this host.

**This rule is self-referential: if you are reading this, you have already read it.**

**Enforcement:** The step-by-step workflow for this rule is defined in `rules/cross-platform-execution-workflow.md`. You MUST follow that document's Phase 1 (Plan — identify host OS and script shell), Phase 2 (Execute — syntax check then run with `-N`), and Phase 3 (Verify) before proceeding. See `rules/cross-platform-execution-workflow.md` for the full procedure.

### Shell Isolation Rule (MANDATORY)

**Scripts may only call other scripts written for the same shell.** This prevents cross-shell invocation bugs caused by syntax differences between shells.

**Rules:**
- **zsh scripts (`.zsh`)** may only call other `.zsh` scripts. They must NOT invoke `.sh` or `.tcsh` scripts via `bash`, `zsh`, or any other shell.
- **bash scripts (`.sh`)** may only call other `.sh` scripts. They must NOT invoke `.zsh` or `.tcsh` scripts via `bash`, `zsh`, or any other shell.
- **Makefile recipes** are exempt from this rule since they execute under `/bin/sh -c` and cannot support bash/zsh builtins anyway.
- **Cross-shell invocation is only allowed for syntax testing** (`<shell> -n <script>`) and **user-requested cross-platform execution** as described in the Cross-Platform Script Execution rule above.

**Procedure:**
1. **Before calling any script**, check its extension and the caller's shell type.
2. **If they match** (zsh→zsh, bash→bash), proceed normally.
3. **If they do not match**, STOP and either:
   - Rewrite the called script in the caller's shell, or
   - Ask the user for guidance on how to proceed.

**This rule is self-referential: if you are reading this, you have already read it.**

**Enforcement:** The step-by-step workflow for this rule is defined in `rules/shell-isolation-workflow.md`. You MUST follow that document's Phase 1 (Plan — list all invocations and their shells), Phase 2 (Execute — verify each call matches the caller's shell), and Phase 3 (Verify) before proceeding. See `rules/shell-isolation-workflow.md` for the full procedure.

### Paired Script Sync — .zsh/.sh Variants (MANDATORY)

This project has 18+ script pairs with the same base name but different shell suffixes (e.g., `run_regression.zsh` + `run_regression.sh`, `generate_test_data.zsh` + `generate_test_data.sh`). Due to the Shell Isolation Rule above, each pair represents **independent implementations of the same contract** — they cannot share code.

**Applicable to ALL paired scripts in the project**, including but not limited to:
- `utils/bin/run_regression.{zsh,sh}`, `run_build.{zsh,sh}`, `check_tools.{zsh,sh}`, `lint_scripts.{zsh,sh}`, `sync-bionic-rules.{zsh,sh}`
- `utils/bin/aggregate_verify_build.{zsh,sh}`, `aggregate_regression.{zsh,sh}`, `aggregate_junit.{zsh,sh}`
- `utils/bin/recover_container_network.{zsh,sh}`
- `knowledge/build_model.{zsh,sh}`, `knowledge/update.{zsh,sh}`
- `prompts/common/cpp/utils/bin/generate_test_data.{zsh,sh}`, `generate_junit_report.{zsh,sh}`, `verify_test_data.{zsh,sh}`, `verify_binary_symmetry.{zsh,sh}`, `lint_prompts.{zsh,sh}`, `archlinux_container.{zsh,sh}`
- All per-OS copies in `src/<os>/cpp/tests/utils/bin/`

**When you modify one variant of any pair, you MUST mirror the change in the other:**
1. Apply the equivalent change to the other variant immediately — do not defer
2. Verify both pass syntax checks: `<shell> -n <script>` for each
3. Test both variants if possible (macOS for .zsh, Linux for .sh)
4. If you cannot test one variant, note the untested change and ask the user to verify
5. **Exception:** If the change is genuinely shell-specific (e.g., macOS-only `container` CLI vs Linux `podman`), document why the other variant should NOT be changed

**This rule exists because the Shell Isolation Rule forces independent implementations.** Without it, paired scripts diverge and one platform silently breaks while the other works.

### tcsh Script Creation — Pre-Flight Check (MANDATORY)

**Before creating or modifying ANY `.tcsh` script, you MUST perform this pre-flight check:**

1. **Load `rules/tcsh-syntax.md`** — read the entire file before writing any tcsh code
2. **Cross-reference every line of your script** against the rules in that file:
   - Control Flow (then/endif, while/end, functions, switch/case)
   - Variables and Arrays (@ arithmetic, no leading underscore, no quoted arrays, foreach quoting)
   - Redirects and I/O (no 2>&1, no here-strings)
   - External Tools and Patterns (grep ---, glob no match)
   - Script Structure and Testing (shebang env, no set -e, temp file testing)
3. **If any rule is violated**, STOP and fix it before proceeding
4. **Verify compliance** — if the script contains any forbidden pattern, STOP and find a tcsh-compatible alternative

**This check is mandatory — not optional.** The rules exist in `rules/tcsh-syntax.md` but have been violated multiple times because the file was not loaded before tcsh script creation. Relying on memory alone has led to broken scripts.

**Example — Pre-Flight Check in Action:**
```tcsh
# ❌ BEFORE pre-flight check: wrote tcsh script without loading rules
#!/bin/tcsh              # ← Violation: hardcoded path, should be env tcsh
set -e                   # ← Violation: set -e not supported
@ x = $(($a + $b))      # ← Violation: no $((...)), use @ x = $a + $b
if ( $cond ) then echo "yes"  # ← Violation: then must be on own line or followed by ;
# ... proceeds to create broken script ...

# ✅ AFTER pre-flight check: loaded rules, verified compliance
cat rules/tcsh-syntax.md  # ← MUST be the first action before any tcsh script work
# ... verify each line against loaded rules ...
#!/usr/bin/env tcsh       # ← Fixed: portable shebang
# no set -e               # ← Fixed: removed unsupported directive
@ x = $a + $b            # ← Fixed: use @ operator
if ( $cond ) then         # ← Fixed: then on own line
  echo "yes"
endif                     # ← Fixed: proper endif
# ... now create the script ...
```

**This rule is self-referential: if you are reading this, you have already read it.**

### Shebang Line Rule — Use `env` for Portability

All shell scripts MUST use a shebang line that invokes the interpreter via `env` rather than a hardcoded path:

```bash
#!/usr/bin/env bash    # ✅ Correct — finds bash in PATH, works on all platforms
#!/usr/bin/env zsh     # ✅ Correct — finds zsh in PATH, works on all platforms
```

**Forbidden patterns:**
```bash
#!/bin/bash            # ❌ Hardcoded — may not exist on all platforms (e.g., Homebrew bash is at /opt/homebrew/bin/bash)
#!/bin/zsh             # ❌ Hardcoded — macOS ships zsh at /usr/bin/zsh, but custom installs may differ
#!/bin/sh              # ❌ Hardcoded — POSIX sh location can vary; use env for consistency
```

**Rationale:**
- Hardcoded paths like `#!/bin/bash` break on macOS when bash is installed via Homebrew (located at `/opt/homebrew/bin/bash` or `/usr/local/bin/bash`)
- `env` resolves the interpreter from `PATH`, which is the standard portable approach
- This rule applies to all `.sh` and `.zsh` files in the repository

**Exception:** Scripts that must run under a specific shell version and are invoked directly by the OS (e.g., githooks installed via `git config core.hookspath`) should still use `env` — the hook runner invokes them as executables, so the shebang is respected.

## README ↔ readme_template.md Sync Rule

**Keep the template in sync with the README.** `prompts/common/templates/readme_template.md` is the outline and template for `README.md` — its Content Structure section must always match the actual README sections.

When you edit `README.md` directly (add a section, change content, restructure):
1. **Immediately update** `readme_template.md` to reflect the change in its Content Structure section
2. The template should describe what the README *actually has*, not what it *should have*
3. If a new section appears in the README that isn't in the template, add it
4. If a section is removed from the README, remove it from the template
5. **Before updating `README.md`**, load and read `rules/mermaid-validation.md` — if the README contains any mermaid diagrams, validate that all diagram syntax follows the rules in that file (quoted parentheses, quoted at-signs, no `direction` inside subgraphs, etc.)

### Mermaid Diagram Validation Rule (README Updates)

**Before updating `README.md`**, you MUST load and read `rules/mermaid-validation.md`. This rule contains critical mermaid syntax validation rules that prevent silent parse failures (blank diagrams in GitHub/GitLab).

**Procedure:**
1. Read `rules/mermaid-validation.md` before making any changes to `README.md`
2. If the README contains mermaid diagrams, validate that all diagram syntax follows the rules:
   - Parentheses in labels must be quoted: `["text (with parens)"]`
   - At-signs in edge labels must be quoted: `-->|"ssh@host"| Node`
   - No `direction` inside subgraphs (use only at top level)
   - Node names must not start with reserved words (`SSH`, `A`, `B`)
3. If any diagram is being added or modified, validate it with `mmdc` before including it in the README
4. Never commit a diagram that hasn't been validated with `mmdc`

**This rule is self-referential: if you are reading this, you have already read it.**

### Mermaid Diagram Validation — Pre-Flight Check (MANDATORY)

**Before updating `README.md`, you MUST perform this pre-flight check:**

1. **Load and read `rules/mermaid-validation.md`** — this file contains the critical syntax rules that prevent silent parse failures (blank diagrams in GitHub/GitLab)
2. **Scan `README.md` for mermaid diagram blocks** — look for lines containing ```mermaid or `mermaid`
3. **If any diagrams exist**, validate each one against the rules in `rules/mermaid-validation.md`:
   - Parentheses in labels must be quoted: `["text (with parens)"]`
   - At-signs in edge labels must be quoted: `-->|"ssh@host"| Node`
   - No `direction` inside subgraphs (use only at top level)
   - Node names must not start with reserved words (`SSH`, `A`, `B`)
4. **If any diagram is being added or modified**, validate it with `mmdc` before including it in the README
5. **If any violation is found**, STOP and fix the diagram syntax before proceeding
6. **Never commit a diagram** that hasn't been validated with `mmdc`

**This check is mandatory — not optional.** The rule exists in `.bionic` but has been violated multiple times because the mermaid validation file was not loaded before README edits. Relying on memory alone has led to broken diagrams in the README.

**Example — Pre-Flight Check in Action:**
```bash
# ❌ BEFORE pre-flight check: edited README.md with mermaid diagram without loading validation rules
echo '```mermaid' >> README.md
echo 'graph TD; A[Start] --> B(End)' >> README.md  # Broken: unquoted parens, reserved node name
# ... proceeds to commit broken diagram ...

# ✅ AFTER pre-flight check: load rules first, then validate
cat rules/mermaid-validation.md  # ← MUST be the first action before any README edit
# ... validate diagram syntax against loaded rules ...
echo '```mermaid' >> README.md
echo 'graph TD; ["Start"] --> ["End (complete)"]' >> README.md  # Fixed: quoted labels, no reserved names
mmdc -i README.md -o /tmp/validate.png  # ← Validate with mmdc before including
```

### Report Directory Conventions (MANDATORY)

All build and regression reports follow a strict directory layout:

```
reports/
├── build_verify_summary.md          # Aggregate build summary (all OS/languages)
├── regression_summary.md           # Aggregate regression summary (all OS/languages)
├── junit/
│   ├── aggregated.xml             # Combined JUnit XML
│   └── aggregated.html            # Combined JUnit HTML
├── <lang>/                         # cpp, java, python
│   └── per_os/
│       ├── <os>_build_verify.md   # Per-OS build verification report
│       ├── <os>_regression.md      # Per-OS regression test report
│       └── junit/
│           └── <os>_regression_report_junit.xml  # Per-OS JUnit XML
```

**Rules:**
- **`.md` reports** go in `reports/<lang>/per_os/<os>_build_verify.md` and `<os>_regression.md`
- **JUnit `.xml`** goes in `reports/<lang>/per_os/junit/<os>_regression_report_junit.xml`
- **Aggregate summaries** are `reports/build_verify_summary.md` (from `aggregate_verify_build`) and `reports/regression_summary.md` (from `aggregate_regression`)
- **Aggregate JUnit** is `reports/junit/aggregated.xml` + `.html` (from `aggregate_junit`)
- Aggregates are auto-generated at the end of each `verify_build` / `run_regression` run

### UNSUPPORTED Platform Contract (MANDATORY)

When an OS/language combination cannot build or test, it must be documented via `UNSUPPORTED.md`:

**Location:** `src/<os>/<lang>/UNSUPPORTED.md`

**Detection by scripts:**
- **`run_build`:** `run_native`/`run_container` capture `make all` output — if it contains "unsupported", `BUILD_STATUS` is set to `UNSUPPORTED`
- **`run_regression`:** `populate_top_reports` checks for `UNSUPPORTED.md` when no test output exists — generates an UNSUPPORTED `.md` report
- **Aggregators** (`aggregate_verify_build`, `aggregate_regression`) grep reports for `UNSUPPORTED`/`unsupported`/`skipped` keywords and count them separately from PASS/FAIL

**Summary displays:** Both `build_verify_summary.md` and `regression_summary.md` show UNSUPPORTED entries in the Per-OS Results table with `UNSUPPORTED` status and a link to the full report.

<!-- RULES-LOAD: freebsd14 -> rules/freebsd-ssh.md --># test hook
