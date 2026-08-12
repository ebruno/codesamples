# Utility Script Generation Workflow — Ringbuffer

**Objective:** Create or update the authoritative utility scripts in `prompts/common/cpp/utils/bin/` that are deployed to each platform's `tests/utils/bin/` during test environment setup.

**Inputs:**
1. The pattern specification file (see "Pattern Specification" below).
2. Existing scripts in `prompts/common/cpp/utils/bin/` (if any).
3. The common testing specification: `prompts/common/cpp/testing.md`.

## Pattern Specification

The pattern rule is defined in a standalone file under `prompts/common/testing/patterns/`. This file is the single source of truth for test data generation — it contains the template string, line format, Python reference implementation, validation regex, and JUnit test matrix.

**Default pattern:** `prompts/common/testing/patterns/zigzag.md`  
**Custom pattern:** The user may specify a different pattern file path.

When creating or updating scripts, the agent MUST read the pattern specification from this file and use it as the authoritative reference for all generated scripts.

### Pattern File Format

A pattern file MUST contain:
- **Pattern Name** and version.
- **Template String:** The exact 48-character string used in test data lines.
- **Line Format:** Description of prefix, payload, and suffix structure with total line length.
- **Validation Regex:** The regex that every test data line must match.
- **Position Logic:** Algorithm for determining which character in the template is replaced (e.g., zig-zag).
- **Python Reference Implementation:** A complete, runnable Python function that generates a single line. This is the ground truth — all shell variants MUST produce byte-identical output.
- **Test File Line Counts:** Number of lines per test file (T001–T007).
- **JUnit Test Matrix:** Test IDs, descriptions, transform/error modes, and expected exit codes.
- **Sample Output:** First 3 lines of generated data for verification.

## Script Types and Requirements

### 1. `generate_test_data.<ext>` — Data Generation Scripts

Create one script per shell language:
- `generate_test_data.sh` (Bash 5.0+)
- `generate_test_data.zsh` (Zsh 5.8+)
- `generate_test_data.tcsh` (Tcsh 6.22+)
- `generate_test_data_bin_sh.sh` (Bourne shell)

**Requirements:**
- **Shebang:** `#!/usr/bin/env <shell>` — never use absolute paths to the shell binary.
- **Version Check:** Every script MUST implement a version check at the beginning. If the shell version is below the minimum, print an error and exit non-zero.
- **Pattern Implementation:** Translate the Python reference implementation faithfully into each shell language, respecting:
  - Bash/Zsh: 0-based string indexing. Use `(( ... ))` for arithmetic.
  - Zsh: 1-based string indexing by default. Adjust indices accordingly (add +2 for conversion from Python's 0-based).
  - Tcsh/Bourne: May use `expr` and `cut` as a necessary compromise — include a comment noting this limitation.
- **Output Handling:** If an `output_file` argument is provided:
  1. Truncate the file first with `> "$output_file"`.
  2. Append generated lines with `>> "$output_file"`.
  - Do NOT use `exec >` form — it redirects all stdout (including error messages) into the data file.
- **Options:** Support `-l <lines>` (default: 10), `-h` (usage/help), and optional positional `output_file`.
- **Execute Permission:** After creating each script, set permissions to `rwxr-xr-x` (755):
  ```bash
  chmod +x generate_test_data.sh generate_test_data.zsh generate_test_data.tcsh generate_test_data_bin_sh.sh
  ```

### 2. `verify_test_data.<ext>` — Data Validation Scripts

Create one script per shell language:
- `verify_test_data.sh` (Bash 5.0+)
- `verify_test_data.zsh` (Zsh 5.8+)

**Requirements:**
- **Shebang and Version Check:** Same as generate scripts.
- **Validation Logic:** Implement the validation regex provided by the pattern file. Use shell-native string operations where possible (avoid `sed`, `awk`, `grep` for data processing in Bash/Zsh).
- **Exit Codes:** Exit 0 on success, non-zero on failure. Print a clear message indicating which line failed and why (line number, expected vs actual).
- **Execute Permission:** `chmod +x verify_test_data.sh verify_test_data.zsh`

### 3. `generate_junit_report.<ext>` — JUnit XML Generator

Create one script per shell language:
- `generate_junit_report.sh` (Bash 5.0+)

**Requirements:**
- **Shebang and Version Check:** Same as above.
- **Input Parsing:** Read `.exit` files (e.g., `T001.exit`) for pass/fail, `.time` files for execution time. Fall back to log file pattern matching (`grep -q "ERROR:"` / `grep -q "FAIL"`) if companion files are absent.
- **Expected Exit Codes:** Maintain an authoritative mapping of expected exit codes per test ID (from the pattern file's JUnit Test Matrix). Pass/fail is determined by `actual_exit_code == expected_exit_code`. Do NOT treat all non-zero exits as failures.
- **XML Generation:** Produce valid JUnit XML with:
  - `<testsuites>` root element with `tests`, `failures`, `errors`, and `time` attributes.
  - `<testcase>` elements with `name`, `classname`, and `time` (seconds, 3 decimal places) attributes.
  - `<failure>` elements for failed tests with a `message` attribute and optional error output in the element body.
  - `<system-out>` summary with total execution time in milliseconds.
- **Options:** Support `-l <logs_dir>`, `-o <output_file>`, and `-h`.
- **Execute Permission:** `chmod +x generate_junit_report.sh`

## File Permissions Mandate

**ALL scripts created or updated MUST have execute permission set to `rwxr-xr-x` (755).** This is non-negotiable.

After creating or modifying any script file, the agent MUST run:
```bash
chmod 755 <script_path>
```

Verify permissions after creation:
```bash
ls -la prompts/common/cpp/utils/bin/
# All scripts should show: -rwxr-xr-x 1 ... <script_name>
```

If any script lacks execute permission, the generation/update is considered incomplete and MUST be retried.

## Cross-Platform Consistency Requirements

1. **Identical Output:** All language variants of the same script MUST produce byte-identical output for the same input. The Python reference implementation in the pattern file is the ground truth — all shell implementations must match it exactly.
2. **Template String:** The template string (48 characters) MUST be identical across all language variants and match the pattern file exactly.
3. **Line Format:** The line format (prefix, payload, suffix) MUST be identical across all variants.
4. **No Platform-Specific Logic:** The pattern algorithm must not contain platform-specific branches. Shell language differences (indexing, string manipulation) are the only allowed variations.

## Generation Process

1. **Read Pattern Specification:** Read the pattern file from `prompts/common/testing/patterns/<name>.md`. Extract:
   - Template string
   - Validation regex
   - Python reference implementation
   - Test file line counts (T001–T007)
   - JUnit test matrix with expected exit codes

2. **Generate Python Reference (if not provided):** If the pattern file does not include a Python reference implementation, create one from the user's description. This becomes the ground truth for all shell variants.

3. **Generate Shell Scripts:** Create each language variant, translating the Python logic faithfully:
   - `generate_test_data.sh` — Bash 5.0+ with `(( ... ))` arithmetic
   - `generate_test_data.zsh` — Zsh 5.8+ with 1-based string indexing
   - `generate_test_data.tcsh` — Tcsh 6.22+ with `expr`/`cut` compromise
   - `generate_test_data_bin_sh.sh` — Bourne shell with minimal features
   - `verify_test_data.sh` and `.zsh` — validation scripts
   - `generate_junit_report.sh` — JUnit XML generator

4. **Set Permissions:** Run `chmod 755` on every script file in `prompts/common/cpp/utils/bin/`.

5. **Self-Audit:** Verify all scripts:
   - Run each generate script with `-l 5` and compare output against the Python reference implementation (run via `python3 -c "..."`).
   - Run each verify script against the generated data — it MUST exit 0.
   - Verify file permissions with `ls -la` — all scripts must show `-rwxr-xr-x`.
   - Confirm all scripts have valid shebangs (`#!/usr/bin/env ...`) and version checks.

6. **Log Completion:** Record the generation in `src/<os>/cpp/logs/testing.log` with a timestamped entry:
   ```
   [YYYY-MM-DD HH:MM:SS ±HHMM] Created/updated utility scripts in prompts/common/cpp/utils/bin/
   ```

## Update Process

When updating existing scripts:
1. **Read Current Scripts:** Read all existing scripts in `prompts/common/cpp/utils/bin/`.
2. **Read Pattern Specification:** Read the pattern file to get the current authoritative reference.
3. **Compare Against New Spec:** Identify what has changed (pattern rule, validation regex, test matrix).
4. **Apply Targeted Changes:** Update only the affected scripts and sections. Preserve compliant code that is not affected by the change.
5. **Re-verify Permissions:** Ensure `chmod 755` is applied to all updated files.
6. **Re-run Self-Audit:** Repeat the verification steps above.

## Temporary Workspace

- All temporary files, comparison outputs, and intermediate data MUST be placed in `tmp`.
- Do NOT create temporary files in the project root or source directories.

## Tooling and Recovery

- **Invalid Filenames:** If you encounter files or directories with trailing characters after valid extensions (e.g., `` ErrorOps.cpp`} ``, use a Python script with `os.scandir` to identify and recursively remove them using `os.remove()` or `shutil.rmtree()`.
- **Toolchain Errors:** If you experience consistent problems creating or updating files using the provided tools, stop immediately and report the detailed error to the build log and the user.
