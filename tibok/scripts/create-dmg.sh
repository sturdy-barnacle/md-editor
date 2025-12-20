#!/bin/bash
# Create distributable DMG for Tibok
# Usage: ./scripts/create-dmg.sh VERSION
# Example: ./scripts/create-dmg.sh "1.0.0"
#
# Requires: create-dmg (install with: brew install create-dmg)

set -e
set -u

VERSION="${1}"
APP_PATH=".build/release/tibok.app"
DMG_PATH=".build/release/Tibok-${VERSION}.dmg"

cd "$(dirname "$0")/.."

echo "=========================================="
echo "Creating DMG for Tibok v${VERSION}"
echo "=========================================="

# Verify app exists
if [ ! -d "$APP_PATH" ]; then
    echo "Error: App bundle not found at $APP_PATH"
    echo "Run ./scripts/build-release-dmg.sh first"
    exit 1
fi

# Verify app is signed (note: Sparkle framework may cause ambiguous format warning, but app is still signed)
if ! codesign --verify "$APP_PATH" 2>&1 | grep -q "valid"; then
    echo "Warning: App bundle signature may not be valid"
    echo "Run ./scripts/build-release-dmg.sh first"
fi

# Verify create-dmg is installed
if ! command -v create-dmg &> /dev/null; then
    echo "Error: create-dmg not found"
    echo "Install with: brew install create-dmg"
    exit 1
fi

# Clean old DMG
if [ -f "$DMG_PATH" ]; then
    echo "Removing old DMG..."
    rm -f "$DMG_PATH"
fi

echo "Creating DMG with professional styling..."
create-dmg \
    --volname "Tibok ${VERSION}" \
    --volicon "tibok/Resources/AppIcon.icns" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "tibok.app" 150 190 \
    --hide-extension "tibok.app" \
    --app-drop-link 450 190 \
    --no-internet-enable \
    "$DMG_PATH" \
    "$APP_PATH"

# Verify DMG was created
if [ ! -f "$DMG_PATH" ]; then
    echo "Error: DMG creation failed"
    exit 1
fi

# Get file size
DMG_SIZE=$(stat -f%z "$DMG_PATH")
DMG_SIZE_MB=$((DMG_SIZE / 1024 / 1024))

echo ""
echo "=========================================="
echo "✓ DMG Created Successfully"
echo "=========================================="
echo "File: $DMG_PATH"
echo "Size: ${DMG_SIZE_MB} MB"
echo ""
echo "Next step: Notarize with ./scripts/notarize-dmg.sh"
echo ""
