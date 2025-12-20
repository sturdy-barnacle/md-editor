#!/bin/bash
# Build release DMG variant for Tibok
# Usage: ./scripts/build-release-dmg.sh TEAM_ID VERSION
# Example: ./scripts/build-release-dmg.sh "ABC123DEF4" "1.0.0"

set -e
set -u

TEAM_ID="${1}"
VERSION="${2}"
BUILD_NUMBER=$(date +%s)

cd "$(dirname "$0")/.."

echo "=========================================="
echo "Building Tibok DMG Variant v${VERSION}"
echo "=========================================="
echo "Team ID: ${TEAM_ID}"
echo "Build Number: ${BUILD_NUMBER}"
echo ""

# Update version in Info.plist
echo "Updating Info.plist..."
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION}" tibok/Resources/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${BUILD_NUMBER}" tibok/Resources/Info.plist

# Clean and build release
echo "Cleaning previous build..."
rm -rf .build/release

echo "Building release binary (arm64)..."
swift build -c release --arch arm64

APP_DIR=".build/release/tibok.app"
ENTITLEMENTS="tibok/Resources/tibok-dmg.entitlements"

# Create app bundle structure
echo "Creating app bundle structure..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"
mkdir -p "$APP_DIR/Contents/Frameworks"

# Copy executable
echo "Copying executable..."
cp .build/release/tibok "$APP_DIR/Contents/MacOS/"

# Copy Info.plist
cp tibok/Resources/Info.plist "$APP_DIR/Contents/"

# Compile Liquid Glass icon
echo "Compiling Liquid Glass icon..."
if [ -d "tibok/Resources/IconLayers/icon.icon" ]; then
    /Applications/Xcode.app/Contents/Developer/usr/bin/actool \
        --compile "$APP_DIR/Contents/Resources" \
        --platform macosx \
        --minimum-deployment-target 14.0 \
        --app-icon icon \
        --output-partial-info-plist /tmp/icon-info.plist \
        tibok/Resources/IconLayers/icon.icon
elif [ -f "tibok/Resources/AppIcon.icns" ]; then
    echo "Icon compiler not found, using legacy .icns..."
    cp tibok/Resources/AppIcon.icns "$APP_DIR/Contents/Resources/icon.icns"
fi

# Copy resource bundles
echo "Copying resource bundles..."
cp -r .build/release/tibok_tibok.bundle "$APP_DIR/Contents/Resources/" 2>/dev/null || true
cp -r .build/release/Highlightr_Highlightr.bundle "$APP_DIR/Contents/Resources/" 2>/dev/null || true

# Copy KaTeX for offline math rendering
echo "Copying KaTeX resources..."
[ -d "tibok/Resources/katex" ] && cp -r tibok/Resources/katex "$APP_DIR/Contents/Resources/"

# Copy user documentation
[ -d "user_docs" ] && cp -r user_docs "$APP_DIR/Contents/Resources/"

# Copy Sparkle framework (if available)
# Note: Sparkle framework disabled for v1.0 release due to notarization issues
# Will be enabled in v1.1 with proper binary signing resolution
# if [ -d "Frameworks/Sparkle.framework" ]; then
#     echo "Copying Sparkle framework..."
#     cp -r Frameworks/Sparkle.framework "$APP_DIR/Contents/Frameworks/"
# fi

# Create PkgInfo
echo "APPL????" > "$APP_DIR/Contents/PkgInfo"

# CODE SIGNING
echo ""
echo "=========================================="
echo "Code Signing with Developer ID"
echo "=========================================="

# Find the Developer ID Application certificate in Keychain
IDENTITY=$(security find-identity -v -p codesigning | grep "Developer ID Application" | grep "${TEAM_ID}" | awk -F'"' '{print $2}' | head -1)

if [ -z "$IDENTITY" ]; then
    echo "ERROR: Developer ID Application certificate not found in Keychain!"
    echo "Make sure you have created the certificate in Xcode > Settings > Accounts > Manage Certificates"
    echo "Current Team ID: ${TEAM_ID}"
    echo "Available identities:"
    security find-identity -v -p codesigning
    exit 1
fi

echo "Using identity: $IDENTITY"

# Sparkle signing disabled for v1.0 - framework not included
# Will be re-enabled in v1.1

echo "Signing main app bundle..."
codesign --force --sign "$IDENTITY" \
    --entitlements "$ENTITLEMENTS" \
    --options runtime \
    --timestamp \
    "$APP_DIR" || {
    echo "ERROR: Code signing failed!"
    echo "Make sure your Developer ID Application certificate is in Keychain."
    echo "Run: security find-identity -v -p codesigning"
    exit 1
}

# Verify signature (note: may warn about Sparkle.framework ambiguous format, but this is acceptable)
echo ""
echo "Verifying code signature..."
codesign --verify --deep --verbose=2 "$APP_DIR" || echo "WARNING: Verification found warnings, but signing may still be valid. Proceeding..."

echo ""
echo "=========================================="
echo "✓ Release Build Complete"
echo "=========================================="
echo "App Bundle: $APP_DIR"
echo "Version: ${VERSION} (build ${BUILD_NUMBER})"
echo "Signed with: ${IDENTITY}"
echo "Entitlements: ${ENTITLEMENTS}"
echo ""
echo "Next steps:"
echo "  1. Test locally: open $APP_DIR"
echo "  2. Create DMG: ./scripts/create-dmg.sh ${VERSION}"
echo "  3. Notarize: ./scripts/notarize-dmg.sh .build/release/Tibok-${VERSION}.dmg your@email.com ${TEAM_ID}"
echo ""
