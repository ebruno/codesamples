#!/usr/bin/env bash
# probe_targets.sh — Probe compiler availability and version for a given OS + language
# Usage:
#   probe_targets.sh <os> <lang>          — Probe a single target
#   probe_targets.sh --all <lang>         — Probe all targets for current host
# Reads config/toolchains.json. Checks each compiler on the current host.
# Exit 0 if any compiler passes, exit 1 if none do. No makefiles, no builds.

set -e

# ── Parse arguments ────────────────────────────────────────────────
ALL_MODE=false
TARGET_OS="${1:-}"
LANG="${2:-}"
COMPILER_FILTER="${3:-}"  # Optional: if set, probe only this compiler

while [ $# -gt 0 ]; do
    case "$1" in
        --all) ALL_MODE=true; shift ;;
        *)     shift ;;
    esac
done

if [ -z "$LANG" ]; then
    echo "ERROR: Usage: probe_targets.sh [--all] <os> <lang>" >&2
    echo "  Supported languages: cpp, c, java, python, go, rust" >&2
    exit 1
fi

# ── Resolve paths ──────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../../" 2>/dev/null && pwd || echo "$SCRIPT_DIR")"
REGISTRY="$WORKSPACE_ROOT/config/toolchains.json"

if [ ! -f "$REGISTRY" ]; then
    echo "ERROR: Registry not found at $REGISTRY" >&2
    exit 1
fi

# ── Detect current host OS ────────────────────────────────────────
HOST_OS=$(uname -s)
case "$HOST_OS" in
    Darwin) HOST_OS="macos" ;;
    Linux)  HOST_OS=$(grep '^ID=' /etc/os-release 2>/dev/null | cut -d= -f2 || echo "linux") ;;
    FreeBSD) HOST_OS="freebsd14" ;;
esac

# ── Version comparison helpers (semver) ────────────────────────────
extract_version() {
    _output="$1"
    echo "$_output" | sed -n 's/.*version \([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\).*/\1/p' | head -1
}

version_gte() {
    _v1="$1"
    _v2="$2"

    if [ -z "$_v1" ] || [ -z "$_v2" ]; then
        return 1
    fi

    _v1_major=$(echo "$_v1" | cut -d. -f1)
    _v1_minor=$(echo "$_v1" | cut -d. -f2)
    _v1_patch=$(echo "$_v1" | cut -d. -f3)
    _v2_major=$(echo "$_v2" | cut -d. -f1)
    _v2_minor=$(echo "$_v2" | cut -d. -f2)
    _v2_patch=$(echo "$_v2" | cut -d. -f3)

    _v1_major=${_v1_major:-0}
    _v1_minor=${_v1_minor:-0}
    _v1_patch=${_v1_patch:-0}
    _v2_major=${_v2_major:-0}
    _v2_minor=${_v2_minor:-0}
    _v2_patch=${_v2_patch:-0}

    if [ "$_v1_major" -gt "$_v2_major" ] 2>/dev/null; then return 0; fi
    if [ "$_v1_major" -lt "$_v2_major" ] 2>/dev/null; then return 1; fi
    if [ "$_v1_minor" -gt "$_v2_minor" ] 2>/dev/null; then return 0; fi
    if [ "$_v1_minor" -lt "$_v2_minor" ] 2>/dev/null; then return 1; fi
    if [ "$_v1_patch" -ge "$_v2_patch" ] 2>/dev/null; then return 0; fi
    return 1
}

# ── Probe a single target — exit 0 if any compiler passes, 1 otherwise ──
probe_target() {
    os="$1"

    # Read all compiler entries from registry
    if command -v jq >/dev/null 2>&1; then
        _entries=$(jq -r ".[\"${LANG}\"][\"${os}\"][] | .name + \"|\" + .min_version" "$REGISTRY" 2>/dev/null || true)
    elif command -v python3 >/dev/null 2>&1; then
        _entries=$(python3 -c "
import json, sys
with open('${REGISTRY}') as f:
    data = json.load(f)
for c in data.get('${LANG}', {}).get('${os}', []):
    print(c['name'] + '|' + c.get('min_version', '?'))
" 2>/dev/null || true)
    else
        echo "ERROR: Neither jq nor python3 available to read registry" >&2
        return 1
    fi

    echo "$_entries" | while IFS='|' read -r _name _min_ver; do
        [ -z "$_name" ] && continue

        # If COMPILER_FILTER is set, only check that specific compiler
        if [ -n "$COMPILER_FILTER" ] && [ "$_name" != "$COMPILER_FILTER" ]; then
            continue
        fi

        if ! command -v "$_name" >/dev/null 2>&1; then
            echo "FAIL: ${_name} — not installed (required >= ${_min_ver})" >&2
            continue
        fi

        _ver_output=$($_name --version 2>&1 || $_name -v 2>&1 || true)
        _actual_ver=$(echo "$_ver_output" | sed -n 's/.*version \([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\).*/\1/p' | head -1)

        # Fallback: extract version from end of first line (e.g., "g++-16 (Homebrew GCC 16.1.0) 16.1.0")
        if [ -z "$_actual_ver" ]; then
            _actual_ver=$(echo "$_ver_output" | head -1 | sed 's/.* \([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\)\s*$/\1/')
        fi

        if [ -z "$_actual_ver" ]; then
            echo "FAIL: ${_name} — version unknown (required >= ${_min_ver})" >&2
            continue
        fi

        if version_gte "$_actual_ver" "$_min_ver"; then
            echo "PASS: ${_name} (${_actual_ver} >= ${_min_ver})" >&2
            echo "PASS" > /tmp/probe_targets_${os}_${LANG}_result
        else
            echo "FAIL: ${_name} (${_actual_ver} < required ${_min_ver})" >&2
        fi
    done

    # Check result file (subshell from pipe loses variables)
    if [ -f "/tmp/probe_targets_${os}_${LANG}_result" ]; then
        rm -f "/tmp/probe_targets_${os}_${LANG}_result"
        return 0
    fi

    echo "No supported compilers found for ${os}/${LANG}" >&2
    return 1
}

# ── Main ───────────────────────────────────────────────────────────
if [ "$ALL_MODE" = true ]; then
    # Get list of all OS names from toolchains.json (unique across all languages)
    if command -v jq >/dev/null 2>&1; then
        targets=$(jq -r ".[\"${LANG}\"] | keys[]" "$REGISTRY" 2>/dev/null)
    elif command -v python3 >/dev/null 2>&1; then
        targets=$(python3 -c "
import json, sys
with open('${REGISTRY}') as f:
    data = json.load(f)
for k in sorted(data.get('${LANG}', {}).keys()):
    print(k)
" 2>/dev/null)
    else
        echo "ERROR: Neither jq nor python3 available to read registry" >&2
        exit 1
    fi

    if [ -z "$targets" ]; then
        echo "ERROR: No targets found for language ${LANG} in $REGISTRY" >&2
        exit 1
    fi

    _overall=0
    for target_os in $targets; do
        probe_target "$target_os" || _overall=1
    done
    exit $_overall
else
    if [ -z "$TARGET_OS" ]; then
        echo "ERROR: Usage: probe_targets.sh [--all] <os> <lang>" >&2
        exit 1
    fi

    probe_target "$TARGET_OS"
    exit $?
fi
