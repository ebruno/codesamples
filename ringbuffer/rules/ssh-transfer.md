### SSH Remote Transfer Rule (All Platforms)
When testing on a remote system via SSH, the following files must be transferred to the remote host **before** running `verify_build.md` or `run_regression.md`:

1. **SSH to remote → delete everything:**
   ```bash
   ssh <host> "rm -rf ~/ringbuffer"
   ```

2. **Create a tarball of the ENTIRE ringbuffer directory from the parent:**
   ```bash
   tar -czf /tmp/ringbuffer_<os>.tar.gz -C .. ringbuffer
   ```

3. **SCP tarball over → unpack on remote at ~/ringbuffer:**
   ```bash
   scp /tmp/ringbuffer_<os>.tar.gz <host>:~/
   ssh <host> "cd ~ ; tar -xzf ringbuffer_<os>.tar.gz"
   ```

4. **Run build/test remotely:**
   - FreeBSD 14: use tcsh script (`tcsh /tmp/run_freebsd_ssh.tcsh ~/ringbuffer <os> <mode>` where `<mode>` is one of: `cpp`, `test-cpp`, `python-build`, `python-test`, `java-build`, `java-test`)
   - Arch Linux: inline bash commands with `&&`

**Rules:**
- **Never edit files directly on the remote.** All changes start locally.
- **Always delete everything on remote before copying** — this emulates a clean git checkout and prevents stale files from previous builds.
- **Use `tar -czf /tmp/ringbuffer_<os>.tar.gz -C .. ringbuffer`** to create the tarball from the parent directory, preserving the `ringbuffer/` top-level path inside the archive.
- **All inline SSH commands must be tcsh-compliant** (use `;` not `&&`, avoid `$()`, avoid `2>&1`).
- **FreeBSD 14:** Default shell is tcsh — use `tcsh /tmp/run_freebsd_ssh.tcsh` script with mode parameter (`cpp`, `test-cpp`, `python-build`, `python-test`, `java-build`, `java-test`) for build/test commands.
- **Arch Linux:** Default shell is bash — inline `&&` commands are safe.

**SSH Host Configuration (User-Provided):**
The following SSH hosts are resolved from `config/ssh_hosts.json` at runtime. If the file does not exist, STOP and ask the user to create it:
- **`<freebsd_host>`** — FreeBSD 14 SSH host (resolved from `config/ssh_hosts.json.freebsd_host`)
- **`<archlinux_host>`** — Arch Linux SSH host (resolved from `config/ssh_hosts.json.archlinux_host`)

All SSH commands in `verify_build.md` and `run_regression.md` use these placeholders — the agent resolves them from the config file at runtime. Never hardcode IP addresses or usernames in prompts or scripts.
