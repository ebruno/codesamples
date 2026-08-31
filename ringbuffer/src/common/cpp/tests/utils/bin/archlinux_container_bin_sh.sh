#!/usr/bin/env sh
# archlinux_container_bin_sh.sh - Find and pull a pinned Arch Linux container image from Docker Hub.
# Uses datestamp-based tags (rolling release) — calculates a target date N months back
# and queries the Docker Hub API for the closest matching base-devel tag.
#
# Usage: archlinux_container_bin_sh.sh [-m months] [--pull] [--quiet] [-h]
#   -m months    Months back to target (default: 3)
#   --pull       Actually pull the image after finding it
#   --quiet      Suppress informational output
#   -h           Show this help message
#
# Examples:
#   archlinux_container_bin_sh.sh                          # Find base-devel from 3 months ago
#   archlinux_container_bin_sh.sh -m 6                     # Find base-devel from 6 months ago
#   archlinux_container_bin_sh.sh --pull                   # Find and pull base-devel

set -e

# ── Defaults ───────────────────────────────────────────────────────────────
VARIANT="base-devel"
MONTHS_BACK=3
PULL=false
QUIET=false

# ── Argument parsing ───────────────────────────────────────────────────────
while [ $# -gt 0 ]; do
    case "$1" in
        -m)      MONTHS_BACK="$2"; shift 2 ;;
        --pull)  PULL=true;          shift   ;;
        --quiet) QUIET=true;         shift   ;;
        -h)      echo "# archlinux_container_bin_sh.sh - Find and pull a pinned Arch Linux container image"
                 echo "Usage: archlinux_container_bin_sh.sh [-m months] [--pull] [--quiet] [-h]"
                 exit 0 ;;
        *)       echo "Error: Unknown option $1" >&2; exit 1 ;;
    esac
done

# ── Helpers ────────────────────────────────────────────────────────────────
log() {
    if [ "$QUIET" = false ]; then
        echo "[archlinux_container] $*"
    fi
}

die() {
    echo "Error: $*" >&2
    exit 1
}

# ── Cross-platform date calculation ────────────────────────────────────────
if date -d "-${MONTHS_BACK} months" +%Y%m >/dev/null 2>&1; then
    TARGET_MONTH=$(date -d "-${MONTHS_BACK} months" +%Y%m)
else
    TARGET_MONTH=$(date -v-${MONTHS_BACK}m +%Y%m)
fi

log "Target: variant=${VARIANT}, months_back=${MONTHS_BACK}, prefix=${TARGET_MONTH}"

# ── Docker Hub API query ───────────────────────────────────────────────────
DOCKERHUB_API="https://hub.docker.com/v2/repositories/library/archlinux/tags"

ALL_TAGS=""
PAGE=1
PAGE_SIZE=100

while true; do
    URL="${DOCKERHUB_API}?page_size=${PAGE_SIZE}&name=${VARIANT}&page=${PAGE}"
    RESPONSE=$(curl -s --max-time 30 "$URL") || die "Failed to fetch tags from Docker Hub (page ${PAGE})"

    # Extract tag names and pagination marker using Python as a JSON parser
    PAGE_TAGS=$(echo "$RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for t in data.get('results', []):
    print(t['name'])
has_next = data.get('next') is not None
print('__HAS_NEXT__' if has_next else '__NO_MORE__')
" 2>/dev/null) || die "Failed to parse Docker Hub API response (page ${PAGE})"

    ALL_TAGS="${ALL_TAGS}${PAGE_TAGS}"$'\n'

    if echo "$PAGE_TAGS" | grep -q "__HAS_NEXT__"; then
        PAGE=$((PAGE + 1))
    else
        break
    fi

    # Safety: don't loop forever
    if [ "$PAGE" -gt 50 ]; then
        die "Too many pages fetching tags — API may be rate-limited"
    fi
done

# ── Find the closest matching tag ──────────────────────────────────────────
MATCHING_TAG=""
BEST_DATE="0"

while IFS= read -r tag; do
    [ -z "$tag" ] && continue

    # Skip the plain variant tag (e.g., "base-devel" without date)
    [ "$tag" = "$VARIANT" ] && continue

    # Only consider tags that start with exactly base-devel-
    case "$tag" in
        ${VARIANT}-*) ;;  # matches: base-devel-20260531.0.xxxx
        *) continue ;;    # skip: base-20260531.0.xxxx when searching for "base-devel"
    esac

    # Extract the date portion (YYYYMMDD) from the tag name
    TAG_DATE=$(echo "$tag" | grep -oE '[0-9]{8}' | head -1 || true)
    [ -z "$TAG_DATE" ] && continue

    # Only consider tags from the target month or earlier (never future)
    if [ "$TAG_DATE" \> "${TARGET_MONTH}31" ] 2>/dev/null; then
        continue
    fi

    # Keep the latest (closest to target month) matching tag
    if [ "$TAG_DATE" \> "$BEST_DATE" ]; then
        BEST_DATE="$TAG_DATE"
        MATCHING_TAG="$tag"
    fi
done <<< "$ALL_TAGS"

if [ -z "$MATCHING_TAG" ]; then
    die "No matching ${VARIANT} tag found for time window ${TARGET_MONTH}."
fi

log "Found target container: archlinux:${MATCHING_TAG} (date: ${BEST_DATE})"

# ── Pull the image if requested ────────────────────────────────────────────
if [ "$PULL" = true ]; then
    log "Pulling archlinux:${MATCHING_TAG} ..."

    # Detect container runtime (container on macOS, podman/docker on Linux)
    if command -v container >/dev/null 2>&1; then
        log "Using 'container' (Apple Container) on macOS host"
        container pull archlinux:"${MATCHING_TAG}" || die "Failed to pull image via 'container'"
    elif command -v podman >/dev/null 2>&1; then
        log "Using 'podman' on Linux host"
        podman pull archlinux:"${MATCHING_TAG}" || die "Failed to pull image via 'podman'"
    elif command -v docker >/dev/null 2>&1; then
        log "Using 'docker' on Linux host"
        docker pull archlinux:"${MATCHING_TAG}" || die "Failed to pull image via 'docker'"
    else
        die "No container runtime found (need 'container', 'podman', or 'docker')"
    fi

    log "Successfully pulled archlinux:${MATCHING_TAG}"
fi

# ── Output the result (for use by calling scripts) ────────────────────────
echo "archlinux:${MATCHING_TAG}"
exit 0
