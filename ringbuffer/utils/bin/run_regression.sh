#!/usr/bin/env bash
# run_regression.sh — Execute regression tests for a target OS inside its container
# Usage: ./utils/bin/run_regression.sh <os> verify|build [image_override]
# Linux host version (bash)

set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT_NAME="run_regression.sh"

usage() {
    echo "Usage: $0 <os> verify|build [image_override]"
    echo ""
    echo "Actions:"
    echo "  verify   — Run full regression test matrix (T001-T007) using ringbuffer_<os>_test"
    echo "  build    — Build library only using ringbuffer_<os>_build"
    echo ""
    echo "Supported OS: macos, debian, fedora, ubuntu, raspios, archlinux, freebsd14"
    exit 1
}

# Parse arguments
if [ $# -lt 2 ]; then
    usage
fi

TARGET_OS="$1"
ACTION="$2"
IMAGE_OVERRIDE="${3:-}"

# Validate OS
case "$TARGET_OS" in
    macos|debian|fedora|ubuntu|raspios|archlinux|freebsd14) ;;
    *) echo "ERROR: Unsupported OS '$TARGET_OS'. Supported: macos, debian, fedora, ubuntu, raspios, archlinux, freebsd14"; exit 1 ;;
esac

# Validate action
case "$ACTION" in
    verify|build) ;;
    *) echo "ERROR: Unsupported action '$ACTION'. Use 'verify' or 'build'"; exit 1 ;;
esac

# Detect host OS and pick container CLI
detect_host() {
    local uname_s
    uname_s=$(uname -s)
    if [ "$uname_s" = "Darwin" ]; then
        HOST_OS="macos"
    else
        HOST_OS=$(grep '^ID=' /etc/os-release 2>/dev/null | cut -d= -f2 || echo "linux")
    fi
}

detect_host

# Select container CLI
if [ "$HOST_OS" = "macos" ]; then
    CONTAINER_CMD="container"
else
    CONTAINER_CMD="podman"
fi

# Select container image based on action
if [ "$ACTION" = "verify" ]; then
    CONTAINER_IMAGE="ringbuffer_${TARGET_OS}_test"
else
    CONTAINER_IMAGE="ringbuffer_${TARGET_OS}_build"
fi

# Check if host matches target (native execution)
is_native=false
if [ "$HOST_OS" = "macos" ] && [ "$TARGET_OS" = "macos" ]; then
    is_native=true
elif [ "$HOST_OS" != "macos" ] && [ "$TARGET_OS" = "$HOST_OS" ]; then
    is_native=true
fi

# Detect available C++ compilers inside a container image
detect_compilers_in_container() {
    local img="$1"
    AVAILABLE_COMPILERS=()
    for c in g++ clang++; do
        if $CONTAINER_CMD run --rm "$img" bash -c "command -v $c" >/dev/null 2>&1; then
            AVAILABLE_COMPILERS+=("$c")
        fi
    done
}

# Detect available C++ compilers on the host
detect_compilers_on_host() {
    AVAILABLE_COMPILERS=()
    for c in g++ clang++; do
        if command -v "$c" >/dev/null 2>&1; then
            AVAILABLE_COMPILERS+=("$c")
        fi
    done
}

# Check if a compiler supports C++20 <format> header inside a container
check_format_support_in_container() {
    local img="$1"
    local compiler="$2"
    $CONTAINER_CMD run --rm "$img" bash -c "echo '#include <format>' | $compiler -std=c++20 -x c++ -fsyntax-only - 2>&1" >/dev/null 2>&1
}

# Check if a compiler supports C++20 <format> header on the host
check_format_support_on_host() {
    local compiler="$1"
    echo '#include <format>' | $compiler -std=c++20 -x c++ -fsyntax-only - 2>&1 >/dev/null
}

# Get compiler major version inside a container
get_compiler_version_in_container() {
    local img="$1"
    local compiler="$2"
    $CONTAINER_CMD run --rm "$img" bash -c "$compiler --version | grep -oP '(\d+)\.\d+\.\d+' | head -1"
}

# Get compiler major version on the host
get_compiler_version_on_host() {
    local compiler="$1"
    $compiler --version | grep -oP '(\d+)\.\d+\.\d+' | head -1
}

# Generate UNSUPPORTED.md report for a platform
generate_unsupported_report() {
    local os_name="$1"
    local report_path="$2"

    cat > "$report_path" << EOF
# ${os_name} C++ — UNSUPPORTED

**Date:** \$(date '+%Y-%m-%d %H:%M:%S %z')
**Reason:** No available C++ compiler supports required C++20 features.

| Compiler | Version | <format> Support |
|----------|---------|-----------------|
EOF

    # Add compiler details from the probe results
    for c in g++ clang++; do
        local ver=""
        if [ -f "${report_path}.versions" ]; then
            ver=$(grep "^${c}:" "${report_path}.versions" | cut -d: -f2)
        fi
        if [ -n "$ver" ]; then
            echo "| ${c} | ${ver} | ❌ Requires GCC 13+ / Clang 15+ for <format> header |" >> "$report_path"
        fi
    done

    cat >> "$report_path" << EOF

**Required Minimum Versions:**
- **GCC 13+** or **Clang 15+** for C++20 \`<format>\` support

**Options to Enable Support:**
1. Upgrade the base image to one with newer compilers (e.g., Debian 13, Ubuntu 24.04, Fedora)
2. Remove \`<format>\` dependency from source code (replace with printf/snprintf or third-party library)
3. Use a different platform that has supported compilers

**Build Error Details:**
\`\`\`
fatal error: 'format' file not found
#include <format>
         ^~~~~~~~
\`\`\`

**Notes:**
- This is a **toolchain limitation**, not a source code bug
- The same source builds successfully on: macOS (Apple clang 21), Fedora, Debian, Ubuntu, Arch Linux
EOF

    rm -f "${report_path}.versions"
}

# Build container image if needed
build_image() {
    echo "Building container image: $CONTAINER_IMAGE"

    # Check if image already exists
    local images
    images=$($CONTAINER_CMD images --quiet 2>/dev/null | grep "$CONTAINER_IMAGE" || true)
    if [ -n "$images" ]; then
        echo "Image $CONTAINER_IMAGE already exists, skipping build."
        return 0
    fi

    local os_dir="$WORKSPACE/src/${TARGET_OS}/cpp"

    # For verify action, we need the test image. Build build first if needed, then test.
    if [ "$ACTION" = "verify" ]; then
        # Build build image first (test depends on it)
        if ! $CONTAINER_CMD images --quiet 2>/dev/null | grep -q "ringbuffer_${TARGET_OS}_build"; then
            echo "Building build image first..."
            (cd "$os_dir" && make container 2>&1) || { echo "ERROR: Failed to build build image"; exit 1; }
        fi

        # Build test image from tests/ directory
        if [ -d "$os_dir/tests" ] && [ -f "$os_dir/tests/Makefile" ]; then
            echo "Building test image..."
            (cd "$os_dir/tests" && make container 2>&1) || { echo "ERROR: Failed to build test image"; exit 1; }
        fi
    else
        (cd "$os_dir" && make container 2>&1) || { echo "ERROR: Failed to build image"; exit 1; }
    fi
}

# Run natively (host matches target) — loop over available compilers
run_native() {
    echo "=== Native execution: $ACTION on $TARGET_OS ==="

    # Detect available compilers
    detect_compilers_on_host
    if [ ${#AVAILABLE_COMPILERS[@]} -eq 0 ]; then
        echo "ERROR: No C++ compiler found on host."
        exit 1
    fi
    echo "Detected compilers: ${AVAILABLE_COMPILERS[*]}"

    local os_dir="$WORKSPACE/src/${TARGET_OS}/cpp"
    if [ ! -d "$os_dir/tests" ]; then
        echo "ERROR: $os_dir/tests does not exist."
        exit 1
    fi

    for CXX in "${AVAILABLE_COMPILERS[@]}"; do
        echo ""
        echo "============================================="
        echo "Compiler: $CXX"
        echo "============================================="

        # Check compiler version and feature support
        local ver
        ver=$(get_compiler_version_on_host "$CXX")
        echo "Version: $ver"

        if ! check_format_support_on_host "$CXX"; then
            echo "UNSUPPORTED: $CXX does not support C++20 <format> header"
            echo "  Required: GCC 13+ or Clang 15+"

            # Generate UNSUPPORTED.md if no compilers work
            local all_unsupported=true
            for c2 in "${AVAILABLE_COMPILERS[@]}"; do
                if [ "$c2" != "$CXX" ] && check_format_support_on_host "$c2"; then
                    all_unsupported=false
                fi
            done

            if [ "$all_unsupported" = true ]; then
                generate_unsupported_report "$(echo $TARGET_OS | sed 's/^./\U&/')" "$os_dir/UNSUPPORTED.md"
                echo "Generated: $os_dir/UNSUPPORTED.md"
            fi

            continue
        fi

        # Clean parent dir (library)
        make -C "$os_dir" clean 2>&1

        # Clean tests dir
        make -C "$os_dir/tests" clean 2>&1

        # Run verify with this compiler
        CXX="$CXX" make -C "$os_dir/tests" verify 2>&1
    done
}

# Run inside container — loop over available compilers
run_container() {
    echo "=== Container execution: $ACTION on $TARGET_OS ==="

    # Pre-flight check for container CLI
    if ! command -v "$CONTAINER_CMD" &>/dev/null; then
        echo "ERROR: '$CONTAINER_CMD' command not found in PATH."
        if [ "$HOST_OS" = "macos" ]; then
            echo "Install Apple Container from: https://github.com/apple/container"
        else
            echo "Install podman with your package manager."
        fi
        exit 1
    fi

    # Build image if needed
    build_image

    local os_dir="$WORKSPACE/src/${TARGET_OS}/cpp"

    # Detect compilers available inside the container image
    detect_compilers_in_container "$CONTAINER_IMAGE"
    if [ ${#AVAILABLE_COMPILERS[@]} -eq 0 ]; then
        echo "ERROR: No C++ compiler found in $CONTAINER_IMAGE."
        exit 1
    fi
    echo "Detected compilers inside container: ${AVAILABLE_COMPILERS[*]}"

    # Mount workspace and run make inside container
    local mount_path="/app/ringbuffer"
    local workdir="${mount_path}/src/${TARGET_OS}/cpp/tests"

    # For verify action, ensure build image exists first (test depends on it)
    if [ "$ACTION" = "verify" ]; then
        local build_image_name="ringbuffer_${TARGET_OS}_build"
        if ! $CONTAINER_CMD images --quiet 2>/dev/null | grep -q "$build_image_name"; then
            echo "Building build image (required by test image)..."
            (cd "$os_dir" && make container 2>&1) || { echo "ERROR: Failed to build build image"; exit 1; }
        fi
    fi

    # Track which compilers support <format>
    local supported_compilers=()
    local unsupported_info=""

    for CXX in "${AVAILABLE_COMPILERS[@]}"; do
        echo ""
        echo "============================================="
        echo "Compiler: $CXX"
        echo "============================================="

        # Check compiler version and feature support inside container
        local ver
        ver=$(get_compiler_version_in_container "$CONTAINER_IMAGE" "$CXX")
        echo "Version: $ver"

        if check_format_support_in_container "$CONTAINER_IMAGE" "$CXX"; then
            echo "SUPPORTED: $CXX supports C++20 <format> header"
            supported_compilers+=("$CXX")
        else
            echo "UNSUPPORTED: $CXX does not support C++20 <format> header"
            echo "  Required: GCC 13+ or Clang 15+"
            unsupported_info="${unsupported_info}${CXX}:${ver}\n"
        fi
    done

    # Generate UNSUPPORTED.md if no compilers support <format>
    if [ ${#supported_compilers[@]} -eq 0 ]; then
        echo ""
        echo "=== ALL COMPILERS UNSUPPORTED ==="

        # Save version info for report generation
        echo -e "$unsupported_info" > "${os_dir}/UNSUPPORTED.md.versions"

        # Run the first unsupported compiler to capture error details
        local first_unsupported="${AVAILABLE_COMPILERS[0]}"
        echo "Running $first_unsupported to capture build error..."

        # Run make clean + verify with first unsupported compiler to trigger UNSUPPORTED.md generation
        $CONTAINER_CMD run --rm \
            -v "$WORKSPACE:$mount_path" \
            -w "$workdir" \
            "$CONTAINER_IMAGE" \
            bash -c "make -C .. clean && make clean && CXX=$first_unsupported make verify" 2>&1 || true

        # Generate the UNSUPPORTED.md report
        generate_unsupported_report "$(echo $TARGET_OS | sed 's/^./\U&/')" "$os_dir/UNSUPPORTED.md"
        echo "Generated: $os_dir/UNSUPPORTED.md"

        exit 0
    fi

    # Run tests with supported compilers only
    for CXX in "${supported_compilers[@]}"; do
        echo ""
        echo "============================================="
        echo "Compiler: $CXX"
        echo "============================================="

        # Run clean + verify inside container for this compiler
        $CONTAINER_CMD run --rm \
            -v "$WORKSPACE:$mount_path" \
            -w "$workdir" \
            "$CONTAINER_IMAGE" \
            bash -c "make -C .. clean && make clean && CXX=$CXX make verify" 2>&1
    done

    return $?
}

# SSH execution for FreeBSD 14 (remote host, /bin/sh wrapper)
run_ssh() {
    echo "=== SSH execution: $ACTION on $TARGET_OS ==="

    local ssh_host="ebruno@10.10.41.244"
    local remote_base="~/source_code/codesamples/ringbuffer"
    local os_dir="$WORKSPACE/src/${TARGET_OS}/cpp"

    if [ ! -d "$os_dir/tests" ]; then
        echo "ERROR: $os_dir/tests does not exist."
        exit 1
    fi

    # Step 1: Create tarball of needed files
    local tarball="/tmp/ringbuffer_${TARGET_OS}.tar.gz"
    echo "Creating tarball..."
    tar -czf "$tarball" -C "$WORKSPACE/src" "${TARGET_OS}/cpp"

    # Step 2: SSH to remote -> clean workspace (delete old files)
    echo "Cleaning remote workspace..."
    ssh "$ssh_host" "rm -rf ${remote_base}/src/${TARGET_OS}/cpp/*"

    # Step 3: SCP tarball over -> unpack on remote
    echo "Syncing files to remote..."
    scp "$tarball" "${ssh_host}:${remote_base}/"
    ssh "$ssh_host" "cd ${remote_base} && tar -xzf ringbuffer_${TARGET_OS}.tar.gz"
    rm -f "$tarball"

    # Step 4: Run make clean in parent dir, make clean in tests dir, then make verify
    echo "Running regression on remote..."
    ssh "$ssh_host" "/bin/sh -c 'cd ${remote_base}/src/${TARGET_OS}/cpp && make clean 2>&1'"
    ssh "$ssh_host" "/bin/sh -c 'cd ${remote_base}/src/${TARGET_OS}/cpp/tests && make clean 2>&1'"
    ssh "$ssh_host" "/bin/sh -c 'cd ${remote_base}/src/${TARGET_OS}/cpp/tests && make verify 2>&1'"

    return $?
}

# Main execution
echo "============================================="
echo "Ringbuffer Regression Runner"
echo "  Host OS:    $HOST_OS"
echo "  Target OS:  $TARGET_OS"
echo "  Action:     $ACTION"
echo "  Container:  $CONTAINER_IMAGE"
echo "============================================="

if [ "$TARGET_OS" = "freebsd14" ]; then
    run_ssh
elif [ "$is_native" = true ]; then
    run_native
else
    run_container
fi

exit $?
