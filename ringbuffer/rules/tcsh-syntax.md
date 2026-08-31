**Critical tcsh Syntax Rules (Learned 2026-08-21)**

---

## Control Flow

- **`then` must be on its own line or followed by `;`:** `if ( cond ) then\naction` or `if ( cond ) then; action`. Never `if ( cond ) then action` on one line — produces "Improper then" error.
- **`endif` closes the most recent unmatched `if`:** Each nested if must have its own endif. Do not put multiple one-line if/then/endif on separate lines without proper nesting — the final endif will close the wrong block.
- **`while` uses `end`, NOT `then/endif`:** `while ( expr ) ... end`
- **tcsh `while` and `end` must appear alone on their input lines**
- **No functions at all:** tcsh has zero function support — no `proc`, no `name() {}`. Error: `"Command not found"` or `"Badly placed ()'s"`. **Fix:** Use `goto` + labels for code blocks, or inline all logic.
- **switch case labels are glob patterns**, not quoted strings: use `case -l:` not `case "-l":`
- **Inside foreach, tcsh switch case labels are glob patterns** — use `if/else` instead of `switch/case` for numeric comparisons
- **tcsh `case` labels must be at column 0** (no leading spaces)

## Variables and Arrays

- **Arithmetic uses `@` operator**, not `$((...))` bash syntax: `@ x = $a + $b`, NOT `set x = $(($a + $b))`
- **String comparison needs quotes:** `$test_num == "001"` not `$test_num == 001` (tcsh treats `001` as variable name)
- **`==` in tcsh expressions does string comparison**, not numeric
- **No leading underscore in variable names:** tcsh requires variables to start with a letter. `_var` fails with `"Variable name must begin with a letter"`. **Fix:** Use `var_name` (underscore in middle/end only), never `_var`.
- **Array definitions must NOT be quoted:** `set var = ("item1" "item2")` produces `"Badly placed ()'s"`. **Fix:** `set var = (item1 item2)` — no quotes around items.
- **foreach with quoted variable treats as single item:** `foreach x ("$VAR")` iterates once with the entire string. **Fix:** `foreach x ($VAR)` — unquoted splits on whitespace.
- **`-n` test checks if value is a non-zero NUMBER**, NOT if string is non-empty. Use `$#var > 0` to check for non-empty strings.
- **`${var//pattern/replacement}` is a bash-ism**, NOT supported in tcsh. Use external tools (sed) for string replacement — this is allowed per the .bionic tcsh exception rule.
- **`shift` only shifts by 1**, not by N like bash: need `shift; shift` for "shift 2"

## Redirects and I/O

- **No `2>&1` redirect syntax:** tcsh produces `"Ambiguous output redirect"` or `"Invalid null command"`. **Fix:** Use `grep -ci pattern file` and check count, or `>& /dev/null` (tcsh combined redirect).
- **`<<<` (here-string) is a bash-ism**, NOT available in tcsh. Use `echo "$var" | sed ...` instead.

## External Tools and Patterns

- **grep pattern starting with `---` interpreted as option:** macOS/BSD grep throws `"unrecognized option"` for `grep -c '--- pattern'`. **Fix:** Use `grep -c -e 'pattern'` to force pattern interpretation.
- **Glob `/*/` throws "No match" if no subdirectories:** tcsh produces `"foreach: No match"` when glob has no results. **Fix:** Use `find ... -type d` and check if empty before foreach.

## Script Structure and Testing

- **Shebang must be portable:** `#!/bin/tcsh` fails if tcsh not at `/bin/`. **Fix:** Always use `#!/usr/bin/env tcsh`.
- **`set -e` not supported:** tcsh parses `-e` as a variable name, producing `"Variable name must begin with a letter"`. **Fix:** Remove `set -e`; handle errors manually.
- **Backtick command substitution** (`set var = \`cmd\``) can cause "Missing '}'" false positives in `tcsh -n` syntax check, but works correctly when run from a file. Always test tcsh scripts as files, not with `-c`.
- **Test via temp files, not inline:** `tcsh -c 'code'` and `tcsh -n` are unreliable for tcsh (false positives, silent failures). **Fix:** Write to temp file in scratchpad, run with `tcsh /path/to/file.tcsh`.
- **When running tcsh scripts via SSH on FreeBSD**, always use `tcsh /path/to/script.tcsh` — never inline tcsh code via SSH `-c`.
