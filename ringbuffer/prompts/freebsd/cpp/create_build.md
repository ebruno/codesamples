# FreeBSD C++ Build Implementation Workflow (14.x / 15.x)

**Objective:**
Deploy the Ringbuffer C++ library to a FreeBSD system (14.x or 15.x) by copying macOS sources, applying FreeBSD-specific adaptations, building on the remote system, and collecting build artifacts back.

## Inputs (provided by caller)
| Parameter | Value | Description |
|-----------|-------|-------------|
| SSH_USER  | `<user>` | Remote username (e.g., `ebruno`) |
| SSH_HOST  | `<hostname_or_ip>` | Remote FreeBSD hostname or IP (e.g., `10.10.41.244`) |
| FREEBSD_VERSION | `14` or `15` | FreeBSD major version (used for path references) |
| SSH_KEY   | (optional) | Path to SSH key file. If not provided, uses default `~/.ssh/id_rsa` or agent harness auth |

**SSH Key Requirement:** The user MUST have SSH keys installed on the remote system before execution. Run `ssh-copy-id <user>@<hostname_or_ip>` from the host first. This prompt uses key-based authentication only — no password prompts.

## Prerequisites
1. macOS source code exists at `src/macos/cpp/` (or the user provides a source directory)
2. SSH key-based access to remote FreeBSD system is configured and working
3. Remote system has `clang++`, `make` (BSD), and `/usr/local/bin/bash` installed

## Workflow Steps

### Step 0: Verify Remote Access
```bash
ssh ${SSH_USER}@${SSH_HOST} "uname -s && uname -r && clang++ --version | head -1"
```
Expected: `FreeBSD`, version string starting with `14.` or `15.`, clang 19.x output.

### Step 1: Copy macOS Sources to FreeBSD
```bash
# Create tarball with relative paths from src/macos/cpp/
cd src && tar czf ../ringbuffer-freebsd-src.tar.gz -C macos/cpp .
# Transfer to remote
scp ../ringbuffer-freebsd-src.tar.gz ${SSH_USER}@${SSH_HOST}:~/ringbuffer-freebsd-src.tar.gz
# Extract on remote to ~/ringbuffer/src/freebsd${FREEBSD_VERSION}/cpp/
ssh ${SSH_USER}@${SSH_HOST} "mkdir -p ~/ringbuffer/src/freebsd${FREEBSD_VERSION}/cpp && cd ~/ringbuffer/src/freebsd${FREEBSD_VERSION}/cpp && tar xzf ~/ringbuffer-freebsd-src.tar.gz"
```

### Step 2: Apply FreeBSD Adaptations (on remote)
The following files need modification. Use Python scripts transferred via SCP to avoid shell escaping issues with tcsh:

| File | Change Required |
|------|-----------------|
| `Threading.cpp` | Replace `std::jthread` with `std::thread` + add `#include <atomic>`, use `stop_flag_` for cooperative cancellation |
| `swtr_ringbuffer_impl.hpp` | Replace `std::jthread` member types with `std::thread`, add `std::atomic<bool> stop_flag_`, update start/stop/wait methods |
| `ReadOps.cpp` | Adapt stop token handling to use atomic flag |
| `WriteOps.cpp` | Adapt stop token handling to use atomic flag |
| `TransformOps.cpp` | Adapt stop token handling to use atomic flag |

**Key code pattern for jthread replacement:**
```cpp
// Instead of: std::jthread write_thread_;
std::thread write_thread_;
std::atomic<bool> stop_flag_{false};

// Instead of: jthread destructor auto-stops
stop_flag_.store(true);
cv_.notify_all();
write_thread_.join();
```

### Step 3: Rewrite Makefiles for BSD make (on remote)
Both `Makefile` and `tests/Makefile` need conversion:

| GNU make (macOS/Linux) | BSD make (FreeBSD) |
|------------------------|-------------------|
| `$(VAR)` | `${VAR}` |
| `ifeq`, `ifdef` | `.if`, `.elif`, `.else`, `.endif` |
| `-dead_strip` (macOS) / `--gc-sections` (Linux) | No equivalent needed for FreeBSD |
| `-install_name @rpath/...` (macOS) | `-Wl,-soname,libswtr_ringbuffer.so` |
| `@rpath/$ORIGIN/../lib` RPATH | `$ORIGIN/../lib` RPATH |
| `lipo -create` (macOS) | Not needed — single arch |
| `libtool -static` (macOS) | `ar rcs` |

**Critical T005 fix:** The fatal error test returns exit code 1. BSD make's default shell (tcsh) doesn't support `{ }` grouping and `$?` is make's automatic variable. Fix:
```makefile
# WRONG (tcsh can't parse { }):
@{ cmd; echo $? > file; }

# WRONG (make expands $?):
@cmd; echo $? > file

# CORRECT:
@/usr/local/bin/bash -c 'cmd; echo $$? > file'
```

### Step 4: Build on Remote (on remote)
```bash
cd ~/ringbuffer/src/freebsd${FREEBSD_VERSION}/cpp
make clean && make 2>&1 | tee ../build.log
cd tests && make verify 2>&1 | tee ../tests_build.log
```

### Step 5: Verify Build (on remote)
Check that all 7 tests pass:
- T001-T004, T006-T007: output match
- T005: exit code 1 (fatal error mode)

### Step 6: Copy Back Artifacts
```bash
# Create tarball of build results (exclude .o files)
ssh ${SSH_USER}@${SSH_HOST} "cd ~/ringbuffer/src/freebsd${FREEBSD_VERSION}/cpp && tar czf ~/ringbuffer-freebsd-build-results.tar.gz --exclude='*.o' Makefile version.mk *.cpp *.hpp lib/ tests/logs/ tests/reports/"

# Transfer back
scp ${SSH_USER}@${SSH_HOST}:~/ringbuffer-freebsd-build-results.tar.gz ~/ringbuffer-freebsd-build-results.tar.gz

# Extract into local src/freebsd${FREEBSD_VERSION}/cpp/
tar xzf ~/ringbuffer-freebsd-build-results.tar.gz -C src/freebsd${FREEBSD_VERSION}/cpp/

# Also SCP individual modified source files for local tracking
scp ${SSH_USER}@${SSH_HOST}:~/ringbuffer/src/freebsd${FREEBSD_VERSION}/cpp/Threading.cpp src/freebsd${FREEBSD_VERSION}/cpp/
scp ${SSH_USER}@${SSH_HOST}:~/ringbuffer/src/freebsd${FREEBSD_VERSION}/cpp/swtr_ringbuffer_impl.hpp src/freebsd${FREEBSD_VERSION}/cpp/
scp ${SSH_USER}@${SSH_HOST}:~/ringbuffer/src/freebsd${FREEBSD_VERSION}/cpp/ReadOps.cpp src/freebsd${FREEBSD_VERSION}/cpp/
scp ${SSH_USER}@${SSH_HOST}:~/ringbuffer/src/freebsd${FREEBSD_VERSION}/cpp/WriteOps.cpp src/freebsd${FREEBSD_VERSION}/cpp/
scp ${SSH_USER}@${SSH_HOST}:~/ringbuffer/src/freebsd${FREEBSD_VERSION}/cpp/TransformOps.cpp src/freebsd${FREEBSD_VERSION}/cpp/
scp ${SSH_USER}@${SSH_HOST}:~/ringbuffer/src/freebsd${FREEBSD_VERSION}/cpp/Makefile src/freebsd${FREEBSD_VERSION}/cpp/
scp ${SSH_USER}@${SSH_HOST}:~/ringbuffer/src/freebsd${FREEBSD_VERSION}/cpp/tests/Makefile src/freebsd${FREEBSD_VERSION}/cpp/tests/
```

### Step 7: Cleanup Remote
```bash
ssh ${SSH_USER}@${SSH_HOST} "rm -f ~/ringbuffer-freebsd-src.tar.gz ~/ringbuffer-freebsd-build-results.tar.gz"
```

## Gotchas (Lessons Learned)
1. **`std::jthread` is NOT available** in FreeBSD clang 19.x — use `std::atomic<bool> stop_flag_` as cooperative cancellation flag
2. **BSD make default shell is tcsh** — no `{ }` grouping, `$?` is make's automatic variable
3. **T005 exit code capture** — use `/usr/local/bin/bash -c '...; echo $$? > file'` (four `$`: two for make → one literal `$`, then `?`)
4. **No g++** — only clang++ available, add `-pthread` for `std::thread`
5. **No zsh** — JUnit report generation must be skipped
6. **ELF `.so` not Mach-O `.dylib`** — use `$ORIGIN/../lib` RPATH, `ar rcs`, `-Wl,-soname,...`
7. **No universal binaries** — single architecture, no `-arch` flags or `lipo`
8. **Use Python scripts for file edits on remote** — tcsh heredocs and `$` escaping are unreliable; SCP a Python script, run it, delete it
