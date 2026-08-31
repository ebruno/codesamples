# FreeBSD 14 awk Reference

**Source:** `man awk | col -b` on FreeBSD 14 (ebruno@10.10.41.244)

## Version
```
awk version 20250116
```

**Note:** This is the BSD awk (not gawk or mawk). The version date indicates it was released January 16, 2025.

## Available awk Implementations
```
/usr/bin/awk    → BSD awk (default, version 20250116)
```

**Not installed:** gawk, mawk — only the default BSD awk is available.

## Synopsis
```
awk [-F ere] [-v var=value] [--] program-text file ...
```

## Key Flags Used in lint_prompts.sh

### `awk '{print $1}'` (field extraction)
- **Status:** ✅ WORKS on FreeBSD 14
- Standard POSIX awk behavior — field splitting by whitespace (default) or `-F` separator
- **Tested:** Available at `/usr/bin/awk`, version 20250116

## Flags Available on FreeBSD
| Flag | Description | GNU Compatible? |
|------|-------------|-----------------|
| `-F ere` | Field separator (regex) | ✅ Yes |
| `-v var=value` | Assign variable before program execution | ✅ Yes |
| `--` | End of options marker | ⚠️ May not be supported in all BSD awk versions |

## Flags NOT Available on FreeBSD (GNU gawk-only)
| Flag | Description | FreeBSD Equivalent? |
|------|-------------|---------------------|
| `--version` | Print version and exit | ❌ Not available (use `awk --help` → "unknown option") |
| `--help` | Print help and exit | ❌ Not available (outputs "unknown option --help ignored") |
| `--posix` | Enable POSIX mode | ❌ Not available |
| `--re-interval` | Enable interval expressions | ⚠️ May differ from GNU behavior |
| `--source program` | Read program from file | ⚠️ Use `-f` instead (POSIX standard) |
| `--lint` | Enable lint warnings | ❌ Not available (gawk-specific) |
| `--lint=nonstop` | Lint without stopping | ❌ Not available (gawk-specific) |
| `--dump-variables[=file]` | Dump variables to file | ❌ Not available (gawk-specific) |
| `--exec program` | Execute program before file processing | ❌ Not available (gawk-specific) |
| `--include path` | Include file in search path | ❌ Not available (gawk-specific) |
| `--module name` | Load module | ❌ Not available (gawk-specific) |
| `--characters-as-bytes` | Treat characters as bytes | ❌ Not available (gawk-specific) |
| `--fatal-warnings` | Treat warnings as errors | ❌ Not available (gawk-specific) |
| `--named-patterns` | Named patterns feature | ❌ Not available (gawk-specific) |
| `--pretty-print` | Pretty print program | ❌ Not available (gawk-specific) |
| `--profile[=file]` | Profile awk program | ❌ Not available (gawk-specific) |
| `--regexp` | Set regexp type | ❌ Not available (gawk-specific) |
| `--sandbox` | Enable sandbox mode | ❌ Not available (gawk-specific) |
| `--source program` | Read program from file | ⚠️ Use `-f` instead (POSIX standard) |
| `--traditional` | Traditional awk mode | ❌ Not available (gawk-specific) |
| `--use-lr-automata` | Use LR automata | ❌ Not available (gawk-specific) |
| `--warn[=category]` | Enable warnings | ❌ Not available (gawk-specific) |
| `--word-regexp` | Word regexp mode | ❌ Not available (gawk-specific) |

## POSIX awk Features Available on FreeBSD
| Feature | Status | Notes |
|---------|--------|-------|
| Standard field splitting (`$1`, `$2`, etc.) | ✅ Yes | Default: whitespace; use `-F` for custom separator |
| `NF`, `NR`, `FILENAME`, `FS`, `OFS`, `ORS` | ✅ Yes | Standard POSIX variables |
| `BEGIN`, `END` blocks | ✅ Yes | Standard POSIX |
| `print`, `printf` | ✅ Yes | Standard POSIX |
| `sub()`, `gsub()` | ✅ Yes | Standard POSIX string functions |
| `split()`, `substr()`, `length()` | ✅ Yes | Standard POSIX string functions |
| `sin()`, `cos()`, `sqrt()`, `exp()`, `log()` | ✅ Yes | Standard POSIX math functions |
| `system()`, `getline` | ✅ Yes | Standard POSIX I/O |
| Associative arrays | ✅ Yes | Standard POSIX awk feature |
| `delete array[index]` | ✅ Yes | Standard POSIX |
| `for (key in array)` | ✅ Yes | Standard POSIX |

## Notes for Script Writers
1. **Use `awk '{print $1}'`** — works correctly on FreeBSD 14 (standard POSIX awk)
2. **Do NOT use `awk --help` or `awk --version`** — not available on FreeBSD; use `man awk` instead
3. **BSD awk is POSIX-compliant** — all standard features work; gawk-specific extensions do not
4. **For cross-platform scripts:** Avoid gawk-specific features (arrays of arrays, `@include`, `PROCINFO`, etc.)
5. **The lint script does NOT use awk** — it uses bash builtins exclusively (per Shell Script Portability Rule)
6. **If awk is needed in tcsh scripts:** Use `awk '{print $1}'` with standard POSIX syntax only
