#!/usr/bin/env bash
# clean_stale_locks.sh — Remove stale run locks from tmp/.run_lock/
# A lock is stale if the PID it references is no longer alive,
# or if it has been held longer than STALE_TIMEOUT_MIN (default 15).

set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")/../.." && pwd)"
LOCK_DIR="${WORKSPACE}/tmp/.run_lock"
STALE_TIMEOUT_MIN="${STALE_TIMEOUT_MIN:-15}"
STALE_TIMEOUT_SEC=$((STALE_TIMEOUT_MIN * 60))

if [ ! -d "$LOCK_DIR" ]; then
    exit 0
fi

pid=$(cat "${LOCK_DIR}/pid" 2>/dev/null || echo "")
started=$(cat "${LOCK_DIR}/started" 2>/dev/null || echo "0")
mode=$(cat "${LOCK_DIR}/mode" 2>/dev/null || echo "unknown")

removed=false

# Check if PID is alive
if [ -n "$pid" ] && ! kill -0 "$pid" 2>/dev/null; then
    echo "Removing stale lock: PID $pid is dead (was running $mode since $(date -r "$started" 2>/dev/null || echo "epoch $started"))."
    rm -rf "$LOCK_DIR"
    removed=true
fi

# Check if lock is too old
if [ "$removed" = false ] && [ -n "$started" ] && [ "$started" != "0" ]; then
    now=$(date +%s)
    age=$((now - started))
    if [ "$age" -gt "$STALE_TIMEOUT_SEC" ]; then
        echo "Removing stale lock: PID $pid held for ${age}s (> ${STALE_TIMEOUT_MIN} min) running $mode."
        rm -rf "$LOCK_DIR"
        removed=true
    fi
fi

if [ "$removed" = false ] && [ -d "$LOCK_DIR" ]; then
    if [ -n "$pid" ]; then
        echo "Lock is active: PID $pid running $mode (started $(date -r "$started" 2>/dev/null || echo "epoch $started"))."
    else
        echo "Lock exists but is malformed — removing."
        rm -rf "$LOCK_DIR"
    fi
fi
