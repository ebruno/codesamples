#!/bin/bash
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
MAJOR=$(grep '^MAJOR=' "$VERSION_FILE" | cut -d'=' -f2)
MINOR=$(grep '^MINOR=' "$VERSION_FILE" | cut -d'=' -f2)
SUBVERSION=$(grep '^SUBVERSION=' "$VERSION_FILE" | cut -d'=' -f2)
BUILD_ID=$(grep '^BUILD_ID=' "$VERSION_FILE" | cut -d'=' -f2)

if [ -z "$MAJOR" ] || [ -z "$MINOR" ] || [ -z "$SUBVERSION" ] || [ -z "$BUILD_ID" ]; then
    echo "ERROR: Invalid version.mk format. Expected MAJOR, MINOR, SUBVERSION, BUILD_ID" >&2
    exit 1
fi

# Compute VERSION string
VERSION="${MAJOR}.${MINOR}.${SUBVERSION}-${BUILD_ID}"

echo "Version: $VERSION (major=$MAJOR, minor=$MINOR, subversion=$SUBVERSION, build_id=$BUILD_ID)"

# Inject into pom.xml using sed
POM_FILE="${SCRIPT_DIR}/pom.xml"
if [ -f "$POM_FILE" ]; then
    # Replace placeholder values with actual version components
    sed -i.bak "s|<major>[0-9]*</major>|<major>${MAJOR}</major>|g" "$POM_FILE"
    sed -i.bak "s|<minor>[0-9]*</minor>|<minor>${MINOR}</minor>|g" "$POM_FILE"
    sed -i.bak "s|<subversion>[0-9]*</subversion>|<subversion>${SUBVERSION}</subversion>|g" "$POM_FILE"
    sed -i.bak "s|<build_id>[0-9]*</build_id>|<build_id>${BUILD_ID}</build_id>|g" "$POM_FILE"
    sed -i.bak "s|<version>[^<]*</version>|<version>${VERSION}</version>|g" "$POM_FILE"
    rm -f "${POM_FILE}.bak"
    echo "pom.xml updated with version: $VERSION"
else
    echo "WARNING: pom.xml not found at $POM_FILE — version injection skipped" >&2
fi

# Output for logging
echo "[timestamp] Version config created: version.mk (source of truth) + pom.xml properties"
