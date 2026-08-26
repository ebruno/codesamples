#!/usr/bin/env sh
# version.sh — Reads version.mk and injects values into pom.xml
# This script is the bridge between version.mk (single source of truth) and Maven build config
# POSIX sh only — no bashisms, sed, awk, or grep.
# Called from Makefile recipes, always from the script's own directory.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION_FILE="${SCRIPT_DIR}/version.mk"

# Read version.mk
if [ ! -f "$VERSION_FILE" ]; then
    echo "ERROR: version.mk not found at $VERSION_FILE" >&2
    exit 1
fi

# Parse version.mk (KEY=VALUE format, no spaces around =)
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

# Inject into pom.xml.
# We use ${var%%pattern*} and ${var#*pattern} to split lines around XML tags,
# avoiding bash ${var//pattern/string} which cannot handle patterns containing '/'
# (the '/' in </major> is treated as the pattern/string delimiter).
POM_FILE="${SCRIPT_DIR}/pom.xml"
if [ -f "$POM_FILE" ]; then
    _tmpfile=$(mktemp)
    _version_replaced=0
    # Handle files where the last line has no trailing newline.
    # read returns 1 on the last line without \n, but the variable IS set.
    # The || [ -n "$line" ] ensures we process it.
    while IFS= read -r line || [ -n "$line" ]; do
        # Replace version component properties by splitting around XML tags
        case "$line" in
            *"<major>"*"</major>"*)
                _prefix="${line%%<major>*}"
                _suffix="${line#*</major>}"
                line="${_prefix}<major>${MAJOR}</major>${_suffix}"
                ;;
        esac
        case "$line" in
            *"<minor>"*"</minor>"*)
                _prefix="${line%%<minor>*}"
                _suffix="${line#*</minor>}"
                line="${_prefix}<minor>${MINOR}</minor>${_suffix}"
                ;;
        esac
        case "$line" in
            *"<subversion>"*"</subversion>"*)
                _prefix="${line%%<subversion>*}"
                _suffix="${line#*</subversion>}"
                line="${_prefix}<subversion>${SUBVERSION}</subversion>${_suffix}"
                ;;
        esac
        case "$line" in
            *"<build_id>"*"</build_id>"*)
                _prefix="${line%%<build_id>*}"
                _suffix="${line#*</build_id>}"
                line="${_prefix}<build_id>${BUILD_ID}</build_id>${_suffix}"
                ;;
        esac
        # Replace <version> tags — first 2 occurrences only (artifact + properties).
        # Plugin versions (3rd+ occurrence) must NOT be replaced.
        case "$line" in
            *"<version>"*"</version>"*)
                if [ "$_version_replaced" -lt 2 ]; then
                    _prefix="${line%%<version>*}"
                    _suffix="${line#*</version>}"
                    line="${_prefix}<version>${VERSION}</version>${_suffix}"
                    _version_replaced=$((_version_replaced + 1))
                fi
                ;;
        esac
        printf '%s\n' "$line"
    done < "$POM_FILE" > "$_tmpfile"
    mv "$_tmpfile" "$POM_FILE"
    echo "pom.xml updated with version: $VERSION"
else
    echo "WARNING: pom.xml not found at ${POM_FILE} — version injection skipped" >&2
fi

# Output for logging
echo "[timestamp] Version config created: version.mk (source of truth) + pom.xml properties"
