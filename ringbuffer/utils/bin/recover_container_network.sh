#!/usr/bin/env bash
# recover_container_network.sh — Network recovery for container runtimes (Linux)
# Usage: ./utils/bin/recover_container_network.sh [--force]
#   --force  Skip the "sole container" guard

set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")/../.." && pwd)"
FORCE=false

if [ "${1:-}" = "--force" ]; then
    FORCE=true
fi

# Detect container runtime
if command -v podman &>/dev/null; then
    CONTAINER_CMD="podman"
elif command -v docker &>/dev/null; then
    CONTAINER_CMD="docker"
else
    echo "ERROR: No container runtime found (podman or docker)."
    exit 1
fi

echo "=== Container Network Recovery (Linux / ${CONTAINER_CMD}) ==="

# Step 1: Check running containers
RUNNING_COUNT=$($CONTAINER_CMD ps -q 2>/dev/null | wc -l | tr -d ' ')
RINGBUFFER_COUNT=$($CONTAINER_CMD ps --format '{{.Names}}' 2>/dev/null | grep -c "ringbuffer" || echo "0")

if [ "$RUNNING_COUNT" -eq 0 ]; then
    echo "No containers running — no containers to stop."
else
    if [ "$FORCE" = true ]; then
        echo "Force mode: stopping ringbuffer containers regardless of other containers."
    elif [ "$RUNNING_COUNT" -ne "$RINGBUFFER_COUNT" ]; then
        echo "ERROR: ${RUNNING_COUNT} container(s) running, but only ${RINGBUFFER_COUNT} are ringbuffer."
        echo "  Non-ringbuffer containers are running — refusing to restart."
        echo "  Use --force to override, or stop other containers manually."
        exit 1
    fi

    # Step 2: Stop ringbuffer containers
    echo "Stopping ringbuffer containers..."
    for os in fedora debian ubuntu raspios; do
        if [ -f "${WORKSPACE}/src/${os}/cpp/Makefile" ]; then
            make -C "${WORKSPACE}/src/${os}/cpp" TARGET_OS="$os" stop_container 2>/dev/null || true
            make -C "${WORKSPACE}/src/${os}/cpp" TARGET_OS="$os" remove_container 2>/dev/null || true
        fi
    done
    # CLI fallback
    $CONTAINER_CMD ps --format '{{.Names}}' 2>/dev/null | grep "ringbuffer" | while read -r c; do
        [ -n "$c" ] && $CONTAINER_CMD stop "$c" 2>/dev/null || true
        [ -n "$c" ] && $CONTAINER_CMD rm -f "$c" 2>/dev/null || true
    done
    echo "  Containers stopped."
fi

# Step 3: Restart podman socket/service (Linux-specific)
if [ "$CONTAINER_CMD" = "podman" ]; then
    echo "Restarting podman socket..."
    systemctl --user restart podman.socket 2>/dev/null || \
        sudo systemctl restart podman.socket 2>/dev/null || \
        echo "  Could not restart podman socket (may not use systemd)."
elif [ "$CONTAINER_CMD" = "docker" ]; then
    echo "Restarting docker service..."
    sudo systemctl restart docker 2>/dev/null || \
        echo "  Could not restart docker (may not use systemd)."
fi

sleep 2
echo "Container network recovery complete."
