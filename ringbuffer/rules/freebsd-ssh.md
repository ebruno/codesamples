### FreeBSD 14 SSH Execution — tcsh Script Rule (Permanent)

**FreeBSD 14 default shell is `tcsh`, NOT bash or sh.** This has critical implications for SSH execution:

- **NEVER use `bash -c` on FreeBSD 14** — bash is forbidden per the .bionic rules
- **NEVER use `2>&1` redirects in tcsh** — produces "Ambiguous output redirect" error
- **NEVER use double-quoted `*` globs in tcsh** — tcsh expands them before running, causing "No match" errors
- **Always use single quotes around paths with `*`** to prevent glob expansion: `'${path}/'*`

**Correct workflow for FreeBSD 14 SSH execution:**

1. **Create a local tcsh script** at `utils/bin/run_freebsd_ssh.tcsh` that runs ON THE REMOTE host
2. **The tcsh script handles all remote operations:**
   - Clean workspace: `/bin/rm -rf '${os_dir}/'*` (single quotes prevent glob expansion)
   - Extract tarball: `/bin/tar -xzf ringbuffer_${TARGET_OS}.tar.gz`
   - Run make: `/usr/bin/make clean` and `/usr/bin/make verify`
3. **From the host script (run_regression.sh/zsh):**
   - Step 1: Create tarball of source code
   - Step 2: SCP both the tarball AND the tcsh script to remote (`/tmp/run_freebsd_ssh.tcsh`)
   - Step 3: SSH to remote and run `tcsh /tmp/run_freebsd_ssh.tcsh '${remote_base}' '${TARGET_OS}' '<mode>'` where `<mode>` is one of: `cpp`, `test-cpp`, `python-build`, `python-test`, `java-build`, `java-test`
   - Step 4: Clean up remote temp files (`rm -f /tmp/run_freebsd_ssh.tcsh`)

**Key tcsh syntax rules:**
- Use `set var = "value"` for variable assignment
- Use `${var}` for variable expansion (no `$var` without braces in paths)
- Use `if ( condition ) then ... endif` for conditionals
- Use `$status` to capture exit codes
- Use single quotes around any path containing `*`: `'${path}/'*`
- No `2>&1` — use separate stderr capture if needed

**This rule is permanent.** Any future FreeBSD 14 SSH work MUST use the tcsh script approach — never inline bash or sh commands via SSH.
