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
    echo "Supported OS: macos, debian, fedora, ubuntu, raspios"
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
    macos|debian|fedora|ubuntu|raspios) ;;
    *) echo "ERROR: Unsupported OS '$TARGET_OS'. Supported: debian, fedora, ubuntu, raspios"; exit 1 ;;
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

# Run natively (host matches target)
run_native() {
    echo "=== Native execution: $ACTION on $TARGET_OS ==="
    
    local os_dir="$WORKSPACE/src/${TARGET_OS}/cpp/tests"
    if [ ! -d "$os_dir" ]; then
        echo "ERROR: $os_dir does not exist."
        exit 1
    fi
    
    (cd "$os_dir" && make "$ACTION" 2>&1)
}

# Run inside container
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
    
    # Run the make command inside container
    $CONTAINER_CMD run --rm \
        -v "$WORKSPACE:$mount_path" \
        -w "$workdir" \
        "$CONTAINER_IMAGE" \
        make "$ACTION" 2>&1
    
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

if [ "$is_native" = true ]; then
    run_native
else
    run_container
fi

exit $?
