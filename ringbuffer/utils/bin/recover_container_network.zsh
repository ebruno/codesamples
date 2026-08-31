#!/usr/bin/env zsh
# recover_container_network.zsh — Network recovery for Apple Container (macOS)
# Usage: ./utils/bin/recover_container_network.zsh [--force]
#   --force  Skip the "sole container" guard (use when you know it's safe)

set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")/../.." && pwd)"
FORCE=false

if [ "${1:-}" = "--force" ]; then
    FORCE=true
fi

echo "=== Container Network Recovery (macOS) ==="

# Step 1: Check running containers
CONTAINER_LIST=$(container list 2>/dev/null || echo "")
# Exclude infrastructure containers (buildkit, etc.) from the count
USER_CONTAINERS=$(echo "$CONTAINER_LIST" | grep -v "buildkit" || echo "")
RUNNING_COUNT=$(echo "$USER_CONTAINERS" | grep -c "running" 2>/dev/null || echo "0")
RINGBUFFER_COUNT=$(echo "$USER_CONTAINERS" | grep -c "ringbuffer" 2>/dev/null || echo "0")

if [ "$RUNNING_COUNT" -eq 0 ]; then
    echo "No containers running — no containers to stop."
else
    if [ "$FORCE" = true ]; then
        echo "Force mode: stopping ringbuffer containers regardless of other containers."
    elif [ "$RUNNING_COUNT" -ne "$RINGBUFFER_COUNT" ]; then
        echo "ERROR: ${RUNNING_COUNT} container(s) running, but only ${RINGBUFFER_COUNT} are ringbuffer."
        echo "  Non-ringbuffer containers are running — refusing to restart system."
        echo "  Use --force to override, or stop other containers manually."
        exit 1
    fi

    # Step 2: Stop ringbuffer containers — Makefile targets first, CLI fallback
    echo "Stopping ringbuffer containers..."
    for os in fedora debian ubuntu raspios; do
        if [ -f "${WORKSPACE}/src/${os}/cpp/Makefile" ]; then
            make -C "${WORKSPACE}/src/${os}/cpp" TARGET_OS="$os" stop_container 2>/dev/null || true
            make -C "${WORKSPACE}/src/${os}/cpp" TARGET_OS="$os" remove_container 2>/dev/null || true
        fi
    done
    # CLI fallback for any remaining ringbuffer containers
    container list --all 2>/dev/null | grep "ringbuffer" | while read -r line; do
        cid=$(echo "$line" | awk '{print $1}')
        [ -n "$cid" ] && container stop "$cid" 2>/dev/null || true
        [ -n "$cid" ] && container rm -f "$cid" 2>/dev/null || true
    done
    echo "  Containers stopped."
fi

# Step 3: Stop container system
echo "Stopping container system..."
container system stop 2>&1
sleep 2

# Step 4: Start container system
echo "Starting container system..."
container system start 2>&1
sleep 3

# Step 5: Verify
echo "Verifying container system..."
if container system status 2>/dev/null | grep -q "running"; then
    echo "  Container system is running."
else
    echo "ERROR: Container system failed to start."
    container system status 2>&1
    exit 1
fi

echo "Container network recovery complete."
