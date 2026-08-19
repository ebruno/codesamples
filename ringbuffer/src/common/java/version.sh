#!/usr/bin/env bash
# version.sh — Reads version.mk and injects values into pom.xml
# This script is the bridge between version.mk (single source of truth) and Maven build config

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION_FILE="${SCRIPT_DIR}/version.mk"

# Read version.mk
if [ ! -f "$VERSION_FILE" ]; then
    echo "ERROR: version.mk not found at $VERSION_FILE" >&2
    exit 1
fi

# Parse version.mk (KEY=VALUE format, no spaces around =)
# Bash builtins only — no grep/cut
while IFS= read -r line; do
    case "$line" in
        MAJOR=*) MAJOR="${line#MAJOR=}" ;;
        MINOR=*) MINOR="${line#MINOR=}" ;;
        SUBVERSION=*) SUBVERSION="${line#SUBVERSION=}" ;;
        BUILD_ID=*) BUILD_ID="${line#BUILD_ID=}" ;;
    esac
done < "$VERSION_FILE"

if [ -z "$MAJOR" ] || [ -z "$MINOR" ] || [ -z "$SUBVERSION" ] || [ -z "$BUILD_ID" ]; then
    echo "ERROR: Invalid version.mk format. Expected MAJOR, MINOR, SUBVERSION, BUILD_ID" >&2
    exit 1
fi

# Compute VERSION string
VERSION="${MAJOR}.${MINOR}.${SUBVERSION}-${BUILD_ID}"

echo "Version: $VERSION (major=$MAJOR, minor=$MINOR, subversion=${SUBVERSION}, build_id=${BUILD_ID})"

# Inject into pom.xml using bash parameter expansion (no sed)
POM_FILE="${SCRIPT_DIR}/pom.xml"
if [ -f "$POM_FILE" ]; then
    _tmpfile=$(mktemp)
    _version_replaced=0
    while IFS= read -r line; do
        # Replace placeholder values with actual version components
        line="${line//<major>[0-9]*</major>/<major>${MAJOR}</major>}"
        line="${line//<minor>[0-9]*</minor>/<minor>${MINOR}</minor>}"
        line="${line//<subversion>[0-9]*</subversion>/<subversion>${SUBVERSION}</subversion>}"
        line="${line//<build_id>[0-9]*</build_id>/<build_id>${BUILD_ID}</build_id>}"
        # Replace <version> tags (first two occurrences only — artifact and properties versions)
        if [[ "$line" =~ \<version\>[^\<]*\</version\> ]] && (( _version_replaced < 2 )); then
            line="${line/\<version\>*/<version>${VERSION}</version>}"
            (( _version_replaced++ )) || true
        fi
        printf '%s\n' "$line"
    done < "$POM_FILE" > "$_tmpfile"
    mv "$_tmpfile" "$POM_FILE"
    echo "pom.xml updated with version: $VERSION"
else
    echo "WARNING: pom.xml not found at ${POM_FILE} — version injection skipped" >&2
fi

# Output for logging
echo "[timestamp] Version config created: version.mk (source of truth) + pom.xml properties"