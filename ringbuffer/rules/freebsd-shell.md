**FreeBSD 14 Shell & Make — Critical for Remote Builds:**
- **Default shell is tcsh** (`/bin/tcsh`), NOT bash or sh. This affects how SSH commands are interpreted.
- **`make` on FreeBSD uses tcsh** for recipe execution (not bash/sh). Shell redirects like `2>&1`, `> file`, `|` may not work as expected in interactive SSH sessions.
- **When running commands via SSH on FreeBSD 14, wrap shell redirects in `bash -c "..."`:**
  ```bash
  ssh ebruno@10.10.41.244 'bash -c "cd ~/ringbuffer/src/freebsd14/cpp && make all 2>&1"'
  ```
- **`gmake` is NOT installed** on FreeBSD 14. Only BSD make is available — all Makefiles MUST use BSD syntax (`${VAR}`, `.include`, `.if/.endif`, explicit file lists — no `$(wildcard)`, no `ifeq/else`).
- **`version.mk` on FreeBSD must use `${VAR}` syntax**, not GNU `$(VAR)`, because it is included by BSD make.
- **Available shells on FreeBSD 14:** tcsh (default), bash (`/usr/local/bin/bash`), sh (`/bin/sh`). zsh is NOT installed.
- **Makefile recipe shell:** `make` on FreeBSD invokes `/bin/sh -c` for recipes. On FreeBSD 14, `/bin/sh` is the BSD `sh` (not bash). Bash builtins (arrays, `<<<`, `[[ ]]`) are **not available** in Makefile recipes on FreeBSD.
- See [freebsd-platform-analysis.md](prompts/common/appendices/freebsd-platform-analysis.md) for full shell availability details.
- **macOS local testing of FreeBSD Makefiles:** macOS ships with GNU make 3.81, not BSD make. To test FreeBSD Makefiles locally on macOS, you MUST use `bmake` (BSD make installed via Homebrew). Never use `make` or `gmake` for FreeBSD Makefile testing on macOS — GNU make syntax is incompatible and will produce misleading errors. If `bmake` is not found, report an error: `ERROR: bmake (BSD make) is required for testing FreeBSD Makefiles locally. Install with: brew install bmake`.

**Critical tcsh Syntax Rules (Learned 2026-08-21):**
- **`then` must be on its own line or followed by `;`:** `if ( cond ) then\naction` or `if ( cond ) then; action`. Never `if ( cond ) then action` on one line — produces "Improper then" error.
- **`endif` closes the most recent unmatched `if`:** Each nested if must have its own endif. Do not put multiple one-line if/then/endif on separate lines without proper nesting — the final endif will close the wrong block.
- **`while` uses `end`, NOT `then/endif`:** `while ( expr ) ... end`
- **`shift` only shifts by 1**, not by N like bash: need `shift; shift` for "shift 2"
- **`switch` case labels are glob patterns**, not quoted strings: use `case -l:` not `case "-l":`
- **Inside foreach, tcsh switch case labels are glob patterns** — use `if/else` instead of `switch/case` for numeric comparisons
- **Arithmetic uses `@` operator**, not `$((...))` bash syntax: `@ x = $a + $b`, NOT `set x = $(($a + $b))`
- **String comparison needs quotes:** `$test_num == "001"` not `$test_num == 001` (tcsh treats `001` as variable name)
- **`==` in tcsh expressions does string comparison**, not numeric
- **tcsh `case` labels must be at column 0** (no leading spaces)
- **tcsh `while` and `end` must appear alone on their input lines**
- **`-n` test checks if value is a non-zero NUMBER**, NOT if string is non-empty. Use `$#var > 0` to check for non-empty strings.
- **`${var//pattern/replacement}` is a bash-ism**, NOT supported in tcsh. Use external tools (sed) for string replacement — this is allowed per the .bionic tcsh exception rule.
- **`<<<` (here-string) is a bash-ism**, NOT available in tcsh. Use `echo "$var" | sed ...` instead.
- **Backtick command substitution** (`set var = \`cmd\``) can cause "Missing '}'" false positives in `tcsh -n` syntax check, but works correctly when run from a file. Always test tcsh scripts as files, not with `-c`.
- **When running tcsh scripts via SSH on FreeBSD**, always use `tcsh /path/to/script.tcsh` — never inline tcsh code via SSH `-c`.
