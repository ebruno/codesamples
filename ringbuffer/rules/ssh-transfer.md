### SSH Remote Transfer Rule (All Platforms)
When testing on a remote system via SSH, the following files must be transferred to the remote host **before** running `verify_build.md` or `run_regression.md`:
- **C++ source files**: Copy the target-host-specific C++ directory (e.g., `src/archlinux/cpp/` for the archlinux remote). These files are per-OS — only copy the directory matching the target OS.
- **Python source files**: Copy `src/common/python/` (the common Python implementation).
- **Java source files**: Copy `src/common/java/` (the common Java implementation).
- **Clean first**: Remove any existing files in the destination on the remote host before copying from the host. Use `ssh <host> "rm -rf <dest>/src/<os>/cpp/*"`, `ssh <host> "rm -rf <dest>/src/common/python/*"`, and `ssh <host> "rm -rf <dest>/src/common/java/*"` before the transfer.
- **Transfer**: Use `scp -r` or `rsync -avz` to copy the cleaned directories from the host to the remote.
- **Verify**: After transfer, confirm file counts and sizes match between host and remote.
