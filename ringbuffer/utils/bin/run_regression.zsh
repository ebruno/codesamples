#!/usr/bin/env zsh
# run_regression.zsh — Execute regression tests for a target OS inside its container
# Usage: ./utils/bin/run_regression.zsh <os> verify|build [image_override]
# macOS host version (zsh)

set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT_NAME="run_regression.zsh"

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
    *) echo "ERROR: Unsupported OS '$TARGET_OS'. Supported: macos, debian, fedora, ubuntu, raspios"; exit 1 ;;
esac

# Validate action
case "$ACTION" in
    verify|build) ;;
    *) echo "ERROR: Unsupported action '$ACTION'. Use 'verify' or 'build'"; exit 1 ;;
esac

# Detect host OS (macOS only for this script)
HOST_OS="macos"
CONTAINER_CMD="container"

# Select container image based on action (not used for macOS)
if [ "$ACTION" = "verify" ]; then
    CONTAINER_IMAGE="ringbuffer_${TARGET_OS}_test"
else
    CONTAINER_IMAGE="ringbuffer_${TARGET_OS}_build"
fi

# Check Apple Container service status and start if needed
ensure_container_service() {
    echo "Checking Apple Container service..."
    
    local status_output
    if ! status_output=$($CONTAINER_CMD system status 2>&1); then
        echo "Starting Apple Container service..."
        $CONTAINER_CMD system start 2>&1 || { echo "ERROR: Failed to start container service"; exit 1; }
        sleep 5
        
        if ! $CONTAINER_CMD system status 2>&1 | grep -q "running"; then
            echo "ERROR: Container service failed to start after 5 seconds."
            exit 1
        fi
    fi
    
    if echo "$status_output" | grep -q "running"; then
        echo "Apple Container service is running."
    else
        echo "Starting Apple Container service..."
        $CONTAINER_CMD system start 2>&1 || { echo "ERROR: Failed to start container service"; exit 1; }
        sleep 5
        
        if ! $CONTAINER_CMD system status 2>&1 | grep -q "running"; then
            echo "ERROR: Container service failed to start."
            exit 1
        fi
    fi
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

# Run natively (macOS is native-only)
run_native() {
    echo "=== Native execution: $ACTION on $TARGET_OS ==="
    
    local os_dir="$WORKSPACE/src/${TARGET_OS}/cpp/tests"
    if [ ! -d "$os_dir" ]; then
        echo "ERROR: $os_dir does not exist."
        exit 1
    fi
    
    (cd "$os_dir" && make "$ACTION" 2>&1)
}

# Run inside container (Linux targets from macOS host)
run_container() {
    echo "=== Container execution: $ACTION on $TARGET_OS ==="
    
    # Ensure container service is running
    ensure_container_service
    
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
    
    # Run the make command inside container (macOS: omit localhost/ prefix)
    $CONTAINER_CMD run --rm \
        -m 3g \
        -v "$WORKSPACE:$mount_path" \
        -w "$workdir" \
        "$CONTAINER_IMAGE" \
        make "$ACTION" 2>&1
    
    return $?
}

# Main execution
echo "============================================="
echo "Ringbuffer Regression Runner (macOS)"
echo "  Host OS:    $HOST_OS"
echo "  Target OS:  $TARGET_OS"
echo "  Action:     $ACTION"
echo "============================================="

# macOS is native-only — always run natively
run_native

exit $?
