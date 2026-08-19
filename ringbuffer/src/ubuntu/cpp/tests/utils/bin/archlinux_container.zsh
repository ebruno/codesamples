#!/usr/bin/env zsh

# archlinux_container.zsh
# Purpose: Find and pull a pinned Arch Linux container image from Docker Hub.
#          Uses datestamp-based tags (rolling release) — calculates a target date
#          N months back and queries the Docker Hub API for the closest matching tag.
#
# Usage: archlinux_container.zsh [OPTIONS]
#   -m, --months N     Months back to target (default: 3)
#   -p, --pull         Actually pull the image after finding it (default: no)
#   -q, --quiet        Suppress informational output
#   -h, --help         Show this help message
#
# Examples:
#   archlinux_container.zsh                          # Find base-devel from 3 months ago
#   archlinux_container.zsh -m 6                     # Find base-devel from 6 months ago
#   archlinux_container.zsh --pull                   # Find base-devel from 3 months ago and pull

set -euo pipefail

# ── Defaults ───────────────────────────────────────────────────────────────
# Only base-devel is supported — it includes compilers and build tools needed
# for the ringbuffer C++ project. base is too minimal; devel lacks some deps.
VARIANT="base-devel"
MONTHS_BACK=3
PULL=false
QUIET=false

# ── Argument parsing ───────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        -m|--months)   MONTHS_BACK="$2"; shift 2 ;;
        -p|--pull)     PULL=true;        shift   ;;
        -q|--quiet)    QUIET=true;       shift   ;;
        -h|--help)
            # Extract help text from script comments (zsh builtins, no sed)
            _help_started=false
            while IFS= read -r line; do
                if [[ "$line" == "#"* ]]; then
                    _help_started=true
                    # Remove leading '# ' or '#' and print
                    line="${line#\# }"
                    line="${line#\#}"
                    [[ -z "$line" ]] && break
                    echo "$line"
                elif [[ "$_help_started" == true ]]; then
                    break
                fi
            done < "$0"
            exit 0
            ;;
        *) echo "Error: Unknown option $1" >&2; exit 1 ;;
    esac
done

# ── Helpers ────────────────────────────────────────────────────────────────
log() {
    if [[ "$QUIET" == false ]]; then
        echo "[archlinux_container] $*"
    fi
}

die() {
    echo "Error: $*" >&2
    exit 1
}

# ── macOS Detection ────────────────────────────────────────────────────────
# Arch Linux container images are amd64-only. On Apple Silicon (M-series) Macs,
# there is no ARM64 Arch Linux container available. We detect macOS early so
# we can skip gracefully when --pull is requested.
IS_MACOS=false
if [[ "$(uname -s)" == "Darwin" ]]; then
    IS_MACOS=true
fi

# ── Cross-platform date calculation ────────────────────────────────────────
# Calculate the target month prefix (YYYYMM) from N months ago.
# Works on both GNU date (Linux) and BSD date (macOS).

if date -d "-${MONTHS_BACK} months" +%Y%m >/dev/null 2>&1; then
    # GNU date (Linux)
    TARGET_MONTH=$(date -d "-${MONTHS_BACK} months" +%Y%m)
else
    # BSD date (macOS)
    TARGET_MONTH=$(date -v-${MONTHS_BACK}m +%Y%m)
fi

TARGET_PREFIX="${VARIANT}-${TARGET_MONTH}"

log "Target: variant=${VARIANT}, months_back=${MONTHS_BACK}, prefix=${TARGET_PREFIX}"

# ── Docker Hub API query ───────────────────────────────────────────────────
DOCKERHUB_API="https://hub.docker.com/v2/repositories/library/archlinux/tags"

# Fetch all matching tags (handle pagination — max 100 per page)
ALL_TAGS=""
PAGE=1
PAGE_SIZE=100

while true; do
    URL="${DOCKERHUB_API}?page_size=${PAGE_SIZE}&name=${VARIANT}&page=${PAGE}"
    RESPONSE=$(curl -s --max-time 30 "$URL") || die "Failed to fetch tags from Docker Hub (page ${PAGE})"

    # Extract tag names and pagination marker from JSON
    PAGE_TAGS=$(echo "$RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for t in data.get('results', []):
    print(t['name'])
has_next = data.get('next') is not None
print('__HAS_NEXT__' if has_next else '__NO_MORE__')
" 2>/dev/null) || die "Failed to parse Docker Hub API response (page ${PAGE})"

    # Separate tag list from pagination marker
    ALL_TAGS="${ALL_TAGS}${PAGE_TAGS}"$'\n'

    if [[ "$PAGE_TAGS" == *"__HAS_NEXT__"* ]]; then
        ((PAGE++))
    else
        break
    fi

    # Safety: don't loop forever
    if (( PAGE > 50 )); then
        die "Too many pages fetching tags — API may be rate-limited"
    fi
done

# ── Find the closest matching tag ──────────────────────────────────────────
# Tags look like: base-devel-20260809.0.570793
# We want the tag whose date is closest to (but not after) the target month.

MATCHING_TAG=""
BEST_DATE="0"

while IFS= read -r tag; do
    [[ -z "$tag" ]] && continue

    # Skip the plain variant tag (e.g., "base-devel" without date)
    [[ "$tag" == "$VARIANT" ]] && continue

    # Only consider tags that start with exactly ${VARIANT}- (not "base-devel" when searching for "base")
    case "$tag" in
        ${VARIANT}-*) ;;  # matches: base-devel-20260531.0.xxxx
        *) continue ;;    # skip: base-20260531.0.xxxx when searching for "base-devel"
    esac

    # Extract the date portion (YYYYMMDD) from the tag name (zsh regex, no grep/head)
    TAG_DATE=""
    if [[ "$tag" =~ ([0-9]{8}) ]]; then
        TAG_DATE="$match[1]"
    fi
    [[ -z "$TAG_DATE" ]] && continue

    # Only consider tags from the target month or earlier (never future)
    if [[ "$TAG_DATE" > "${TARGET_MONTH}31" ]] 2>/dev/null; then
        continue
    fi

    # Keep the latest (closest to target month) matching tag
    if [[ "$TAG_DATE" > "$BEST_DATE" ]]; then
        BEST_DATE="$TAG_DATE"
        MATCHING_TAG="$tag"
    fi
done <<< "$ALL_TAGS"

if [[ -z "$MATCHING_TAG" ]]; then
    # Extract unique dates from tags for error message (zsh builtins, no grep/sort/head/tr)
    _dates=""
    declare -A _seen_dates
    while IFS= read -r _tag_line; do
        [[ -z "$_tag_line" ]] && continue
        if [[ "$_tag_line" =~ ([0-9]{8}) ]]; then
            _d="$match[1]"
            if [[ -z "${_seen_dates[$_d]:-}" ]]; then
                _seen_dates["$_d"]=1
                _dates="${_dates}${_dates:+ }${_d}"
            fi
        fi
    done <<< "$ALL_TAGS"
    die "No matching ${VARIANT} tag found for time window ${TARGET_MONTH}. Available tags: ${_dates}..."
fi

log "Found target container: archlinux:${MATCHING_TAG} (date: ${BEST_DATE})"

# ── Pull the image if requested ────────────────────────────────────────────
if [[ "$PULL" == true ]]; then
    # macOS Skip Logic: Arch Linux container images are amd64-only.
    # On Apple Silicon (M-series) Macs, there is no ARM64 Arch Linux container available.
    if [[ "$IS_MACOS" == true ]]; then
        log "Arch Linux container pull SKIPPED on macOS (Apple Silicon)"
        echo "[archlinux_container] Arch Linux container images are amd64-only." >&2
        echo "[archlinux_container] No ARM64 Arch Linux container is available on Docker Hub." >&2
        echo "[archlinux_container] Source code identification works; build/test requires a Linux host with podman/docker." >&2
        # Exit successfully — this is expected behavior, not an error
        echo "archlinux:${MATCHING_TAG}"
        exit 0
    fi

    log "Pulling archlinux:${MATCHING_TAG} ..."

    # Detect container runtime (podman/docker on Linux)
    if command -v podman >/dev/null 2>&1; then
        # Linux: Podman (preferred on Linux hosts)
        log "Using 'podman' on Linux host"
        podman pull archlinux:"${MATCHING_TAG}" || die "Failed to pull image via 'podman'"
    elif command -v docker >/dev/null 2>&1; then
        # Fallback: Docker
        log "Using 'docker' on Linux host"
        docker pull archlinux:"${MATCHING_TAG}" || die "Failed to pull image via 'docker'"
    else
        die "No container runtime found (need 'podman' or 'docker')"
    fi

    log "Successfully pulled archlinux:${MATCHING_TAG}"
fi

# ── Output the result (for use by calling scripts) ────────────────────────
# Always output the full image name (e.g., "archlinux:base-devel-20260531.0.538839")
echo "archlinux:${MATCHING_TAG}"
exit 0
