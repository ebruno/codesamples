# Prompt Health Check - Ringbuffer

**Objective:** Validate prompt consistency across all supported operating systems and verify the integrity of generated state files.

**Scope:** This meta-prompt checks all C++ prompts across `common`, `macos`, `fedora`, `debian`, and `ubuntu` directories.

## Checks to Perform

### 1. Structural Consistency
For each OS (macos, fedora, debian, ubuntu), verify that the following prompt files exist:
- `build.md`
- `create_build.md`
- `functional.md`
- `testing.md`
- `update_build.md`
- `update_functional.md`
- `update_testing.md`

Report any missing files.

### 2. Section Presence Check
For each `build.md`, `testing.md`, and update prompt, verify the presence of these required sections:
- **Temporary Workspace** — Centralized storage directive for `tmp`
- **Spec Precedence Rule** (common specs only) — Clarifies platform-specific override behavior
- **Container Runtime Pre-flight** (Linux targets only) — Validates `container` command availability on macOS hosts
- **Architecture Changes** (update prompts only) — Guidance for handling source tree changes
- **Tooling and Recovery** — Error recovery instructions

### 3. Spec Hash Verification
For each OS directory in `src/<os>/cpp/`, check the `.gen_state.json` file:
- Verify that `spec_hashes` contains entries for `functional.md`, `build.md`, and `testing.md`.
- Verify that each hash is a non-empty SHA-256 hex string (64 characters).
- Report any empty or missing hashes.

### 4. Cross-Reference Validation
For each OS-specific `build.md` and `testing.md`:
- Verify that the file contains a reference to its corresponding common spec (e.g., `[prompts/common/cpp/build.md](../../common/cpp/build.md)`).
- Verify that the file contains a "Platform Specifics" or equivalent section.

### 5. Container Runtime Consistency
For each Linux OS (fedora, debian, ubuntu):
- Verify that `build.md` and `testing.md` contain the Container Runtime Pre-flight section.
- Verify that the error message includes the correct URL: `https://github.com/apple/container`.

### 6. Makefile Consistency
For each OS in `src/<os>/cpp/`:
- Verify that the Makefile contains a `.PHONY` declaration listing all declared targets.
- Verify that `CXX ?=` is used (allowing command-line override).
- Report any missing or inconsistent targets.

## Output Format

Generate a report at `tmp/health_check_report.md` with the following structure:

```markdown
# Prompt Health Check Report
**Date:** [YYYY-MM-DD HH:MM:SS ±HHMM]

## Summary
- **Total Checks:** [N]
- **Passed:** [N]
- **Failed:** [N]
- **Warnings:** [N]

## File Existence Check
| OS | build.md | functional.md | testing.md | update_build.md | update_testing.md |
|----|----------|---------------|------------|-----------------|-------------------|
| macos | OK/MISSING | OK/MISSING | ... | ... | ... |
| fedora | OK/MISSING | ... | ... | ... | ... |
| debian | OK/MISSING | ... | ... | ... | ... |
| ubuntu | OK/MISSING | ... | ... | ... | ... |

## Section Presence Check
| File | Temporary Workspace | Spec Precedence | Container Pre-flight | Architecture Changes | Tooling/Recovery |
|------|--------------------|-----------------|---------------------|---------------------|------------------|
| common/cpp/build.md | OK/MISSING | OK/MISSING | N/A | N/A | OK/MISSING |
| ... | ... | ... | ... | ... | ... |

## Spec Hash Verification
| OS | functional.md hash | build.md hash | testing.md hash |
|----|--------------------|---------------|-----------------|
| macos | OK/EMPTY/MISSING | ... | ... |
| fedora | OK/EMPTY/MISSING | ... | ... |
| debian | OK/EMPTY/MISSING | ... | ... |
| ubuntu | OK/EMPTY/MISSING | ... | ... |

## Recommendations
1. [Actionable recommendation based on findings]
2. [Next steps]
```

## Cleanup
After generating the report, delete the `tmp` directory and all its contents.
