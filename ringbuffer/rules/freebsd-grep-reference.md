# FreeBSD 14 grep Reference

**Source:** `man grep | col -b` on FreeBSD 14 (ebruno@10.10.41.244)

## Version
```
grep (BSD grep, GNU compatible) 2.6.0-FreeBSD
```

## Synopsis
```
grep [-abcdDEFGHhIiLlmnOopqRSsUVvwxz] [-A num] [-B num] [-C num]
     [-e pattern] [-f file] [--binary-files=value] [--color=when]
     [--context=num] [--directories=action] [--label] [--line-buffered]
     [--null] [pattern] [file ...]
```

## Key Flags Used in lint_prompts.sh

### `grep -qi "pattern" file`
- **Status:** ✅ WORKS on FreeBSD 14
- `-q`: Quiet mode — suppresses output, only sets exit code (0 = match found, 1 = no match)
- `-i`: Case-insensitive matching
- **Exit codes:** 0 = match found, 1 = no match, 2 = error
- **Tested:** `echo "test" | grep -qi "TEST"` → exit=0 (match)
- **Tested:** `echo "test" | grep -qi "nomatch"` → exit=1 (no match)

## Flags NOT Available on FreeBSD (GNU-only)

### `grep -P` (Perl regex)
- **Status:** ❌ NOT AVAILABLE on FreeBSD 14
- Error: `grep: invalid option -- P`
- **BSD equivalent:** Use `-E` for extended regular expressions (ERE)

## Flags Available on FreeBSD
| Flag | Description | GNU Compatible? |
|------|-------------|-----------------|
| `-q` | Quiet mode | ✅ Yes |
| `-i` | Case-insensitive | ✅ Yes |
| `-c` | Count matching lines | ✅ Yes (returns count) |
| `-E` | Extended regex (ERE) | ✅ Yes |
| `-F` | Fixed strings | ✅ Yes |
| `-G` | Basic regex (BRE, default) | ✅ Yes |
| `-n` | Line numbers | ✅ Yes |
| `-v` | Invert match | ✅ Yes |
| `-l` | List matching files | ✅ Yes |
| `-h` | Suppress filename prefix | ✅ Yes |
| `-H` | Always print filename | ✅ Yes |
| `-r` / `-R` | Recursive search | ✅ Yes |
| `-e pattern` | Specify pattern | ✅ Yes |
| `-f file` | Read patterns from file | ✅ Yes |
| `--color=when` | Color output | ✅ Yes (values: never, always, auto) |
| `--binary-files=value` | Binary file handling | ✅ Yes |

## Notes for Script Writers
1. **Use `grep -qi`** — works correctly on FreeBSD 14 for case-insensitive quiet matching
2. **Do NOT use `grep -P`** — not available; use `-E` for extended regex instead
3. **`grep -c`** returns the count on stdout (same as GNU)
4. **Exit codes are consistent:** 0 = match, 1 = no match, 2 = error
5. **BSD grep is GNU-compatible** for basic flags but lacks some advanced features like `-P`
