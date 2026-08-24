# Regression Test Runner Scripts — Specification

## Purpose

`run_regression.<sh|zsh|tcsh>` is the **single entry point** for executing regression tests (T001–T007) on any target OS. It handles:
- Host/target detection (native vs container)
- Container lifecycle management (start, exec, stop/remove)
- Compiler loop from registry
- Delegation to Makefile for actual test execution

## Script Variants

| Script | Platform | Shell |
|--------|----------|-------|
| `run_regression.sh` | Linux hosts (bash) | bash |
| `run_regression.zsh` | macOS hosts (Apple Container) | zsh |
| `run_regression.tcsh` | FreeBSD 14 hosts (SSH) | tcsh |

## Usage

```bash
./utils/bin/run_regression.<sh|zsh|tcsh> <os> verify|build [image_override]
```

**Arguments:**
- `<os>` — Target OS: `macos`, `debian`, `fedora`, `ubuntu`, `raspios`, `archlinux`, `freebsd14`
- `verify|build` — Action: run full regression matrix or build only
- `[image_override]` — Optional container image override

## Behavior

### 1. Host/Target Detection
- Detect host OS (`uname -s` → Darwin = macOS, else read `/etc/os-release`)
- Determine if native execution is possible (host matches target OS)
- Select container CLI: `container` on macOS, `podman` on Linux

### 2. Registry Lookup
- Read `config/toolchains.json` for supported toolchains per OS + language
- Loop over each compiler in priority order

### 3. Container Management (if needed)
- **Build image** if not present: `make container` in `<os>/cpp/`
- **Start container** with workspace volume mounted
- **Exec into container**: run `make clean; make verify CXX=<compiler>` for each compiler
- **Stop/remove container** when done (image remains)

### 4. Native Execution (if host matches target)
- Run `make clean; make verify CXX=<compiler>` directly in `<os>/cpp/tests/`

### 5. Compiler Loop
For each compiler from registry:
```bash
make clean
make verify CXX=<compiler>
```

## Makefile Contract

The Makefile (`tests/Makefile`) receives `CXX` as a variable and must:
- Use the passed compiler for all build/test steps
- Produce reports in `reports/cpp/per_os/<os>_regression_report_junit.xml`
- Log results to `logs/build.log`

## Error Handling
- If any compiler fails, STOP and report the error
- Do NOT continue to next compiler on failure
- Record full error output in `logs/build.log`

## Self-Check Before Executing
- Am I running `run_regression.sh/zsh/tcsh`? → Must use the script, NOT raw `make verify`
- If unsure, re-read this spec to confirm which mode you are in.

## Self-Referential Rule
If you are reading this, you have already read it.
