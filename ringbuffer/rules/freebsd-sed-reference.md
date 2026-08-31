# FreeBSD 14 sed Reference

**Source:** `man sed | col -b` on FreeBSD 14 (ebruno@10.10.41.244)

## Version
```
sed: illegal option -- -
usage: sed script [-Ealnru] [-i extension] [file ...]
	sed [-Ealnu] [-i extension] [-e script] ... [-f script_file] ... [file ...]
```

**Note:** FreeBSD sed does NOT support `--version` or `--help`. It is the BSD implementation.

## Synopsis
```
sed [-Ealnru] [-i extension] [file ...]
sed [-Ealnu] [-i extension] [-e script] ... [-f script_file] ... [file ...]
```

## Key Flags Used in lint_prompts.sh

### `sed -i '' 's/old/new/' file` (in-place edit with no backup)
- **Status:** ⚠️ DIFFERENT from GNU sed on FreeBSD 14
- `-i` requires an **extension argument** on FreeBSD: `sed -i '' 'script' file`
- The empty string `''` means "no backup file" (in-place edit)
- **GNU sed equivalent:** `sed -i 's/old/new/' file` (no extension argument needed)
- **FreeBSD syntax:** `sed -i '' 's/old/new/' file` (extension argument REQUIRED)

## Flags Available on FreeBSD
| Flag | Description | GNU Compatible? |
|------|-------------|-----------------|
| `-i extension` | In-place edit with backup extension | ⚠️ Different syntax (requires extension arg) |
| `-E` | Extended regex (ERE) | ✅ Yes |
| `-a` | Append mode | ⚠️ BSD-specific |
| `-l n` | Specify line length (BSD) | ❌ GNU uses different syntax |
| `-n` | Suppress automatic printing | ✅ Yes (same as GNU) |
| `-r` | Extended regex (BSD synonym for -E) | ⚠️ GNU uses `-E` instead of `-r` |
| `-u` | Unbuffered output (BSD) | ⚠️ GNU uses `--unbuffered` |
| `-e script` | Add editing command | ✅ Yes (same as GNU) |
| `-f file` | Read commands from file | ✅ Yes (same as GNU) |

## Critical Differences: FreeBSD sed vs GNU sed

### 1. In-place editing (`-i`)
```bash
# ❌ GNU sed (Linux/macOS with GNU coreutils)
sed -i 's/old/new/' file

# ✅ FreeBSD sed (BSD)
sed -i '' 's/old/new/' file    # No backup
sed -i '.bak' 's/old/new/' file  # Create .bak backup
```

### 2. Extended regex flag
```bash
# Both work on FreeBSD (BSD accepts both -E and -r)
sed -E 's/(pattern)/replacement/' file
sed -r 's/(pattern)/replacement/' file

# GNU sed only accepts -E (not -r)
sed -E 's/(pattern)/replacement/' file    # ✅ GNU
sed -r 's/(pattern)/replacement/' file    # ❌ GNU (deprecated)
```

### 3. Line length (`-l`)
```bash
# BSD sed: -l specifies line length for wrapping
sed -l 72 file

# GNU sed: no equivalent flag (uses --line-length with some versions)
```

## Notes for Script Writers
1. **For tcsh scripts on FreeBSD:** Use `sed -i '' 's/old/new/' file` for in-place edits
2. **For cross-platform scripts:** Detect OS and use conditional syntax:
   ```bash
   if uname -s | grep -q Darwin; then
       sed -i '' 's/old/new/' file    # macOS/BSD
   else
       sed -i 's/old/new/' file        # GNU/Linux
   fi
   ```
3. **`-E` flag works on both FreeBSD and GNU sed** — use `-E` for extended regex in cross-platform scripts
4. **No `--version` or `--help`** on FreeBSD sed — use `man sed` for documentation
5. **The lint script uses `grep -qi`** (not sed) for case-insensitive matching, which works correctly on FreeBSD
