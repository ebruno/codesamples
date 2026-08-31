**macOS Shell & Make — Critical for Local Builds:**
- **Default shell is zsh** (since macOS Catalina 10.15), NOT bash. Scripts should use `#!/usr/bin/env zsh` or `#!/usr/bin/env bash`.
- **`make` on macOS is BSD make** (not GNU make). Same syntax constraints as FreeBSD: `${VAR}`, `.include`, explicit file lists — no `$(wildcard)`, no `ifeq/else`.
- **GNU make must be installed via Homebrew** as `gmake`. Do NOT assume `make` is GNU make on macOS.
- **Homebrew paths differ by CPU architecture:**
  - Apple Silicon (M1/M2/M3): `/opt/homebrew/bin/`
  - Intel: `/usr/local/bin/`
- **`date` on macOS is BSD date** — supports `%z` for timezone offset (same as FreeBSD). Use `date '+%Y-%m-%d %H:%M:%S %z'`.
- **No `lipo`/`otool` equivalent on FreeBSD** — use `readelf`, `file`, `nm` instead.
- **Universal binaries:** macOS supports fat/universal binaries (`lipo -create`) combining arm64 + x86_64. FreeBSD and Linux do not.
- **Makefile recipe shell:** `make` on macOS invokes `/bin/sh -c` for recipes. On macOS, `/bin/sh` is a compatibility shim that invokes `zsh` in POSIX mode. Bash builtins (arrays, `<<<`, `[[ ]]`) are **not available** in Makefile recipes on macOS — same restriction as Linux.

## 5. Language Standards and Classification
