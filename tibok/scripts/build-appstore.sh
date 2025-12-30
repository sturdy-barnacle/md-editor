#!/bin/bash
set -e

# Build script for Mac App Store distribution
# Usage: ./scripts/build-appstore.sh <version>

VERSION=${1:-"1.0.3"}

echo "🏗️  Building Tibok v${VERSION} for Mac App Store..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check for required certificates
echo ""
echo "📋 Checking code signing certificates..."

# Look for Mac App Store distribution certificate
APP_STORE_CERT=$(security find-identity -v -p codesigning | grep "3rd Party Mac Developer Application\|Apple Distribution" | head -1 | awk -F'"' '{print $2}')
INSTALLER_CERT=$(security find-identity -v -p codesigning | grep "3rd Party Mac Developer Installer\|Mac Installer Distribution" | head -1 | awk -F'"' '{print $2}')

if [ -z "$APP_STORE_CERT" ]; then
    echo -e "${RED}❌ Mac App Store distribution certificate not found!${NC}"
    echo ""
    echo "You need to create a Mac App Store distribution certificate:"
    echo "1. Go to https://developer.apple.com/account/resources/certificates/list"
    echo "2. Click '+' to create a new certificate"
    echo "3. Select 'Mac App Distribution'"
    echo "4. Download and install the certificate"
    echo ""
    echo "Then run this script again."
    exit 1
fi

if [ -z "$INSTALLER_CERT" ]; then
    echo -e "${RED}❌ Mac Installer Distribution certificate not found!${NC}"
    echo ""
    echo "You need to create a Mac Installer Distribution certificate:"
    echo "1. Go to https://developer.apple.com/account/resources/certificates/list"
    echo "2. Click '+' to create a new certificate"
    echo "3. Select 'Mac Installer Distribution'"
    echo "4. Download and install the certificate"
    echo ""
    echo "Then run this script again."
    exit 1
fi

echo -e "${GREEN}✓ App certificate: $APP_STORE_CERT${NC}"
echo -e "${GREEN}✓ Installer certificate: $INSTALLER_CERT${NC}"

# Update version in Info.plist
echo ""
echo "📝 Updating version to ${VERSION}..."
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION}" tibok/Resources/Info.plist
BUILD_NUMBER=$(date +%s)
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${BUILD_NUMBER}" tibok/Resources/Info.plist

# Clean previous builds
echo ""
echo "🧹 Cleaning previous builds..."
rm -rf .build/appstore
mkdir -p .build/appstore

# Build with Swift Package Manager
echo ""
echo "🔨 Building release binary..."
swift build \
    -c release \
    --arch arm64 \
    --product tibok

# Copy app bundle
echo ""
echo "📦 Copying app bundle..."
cp -R .build/release/tibok.app .build/appstore/tibok.app

# Update Info.plist in the copied bundle
echo ""
echo "📝 Updating bundle Info.plist..."
cp tibok/Resources/Info.plist .build/appstore/tibok.app/Contents/Info.plist

# Sign with App Store entitlements
echo ""
echo "✍️  Signing with App Store entitlements..."
codesign \
    --force \
    --sign "$APP_STORE_CERT" \
    --entitlements tibok/Resources/tibok-appstore.entitlements \
    --options runtime \
    --timestamp \
    .build/appstore/tibok.app

# Verify signature
echo ""
echo "🔍 Verifying signature..."
codesign --verify --deep --strict --verbose=2 .build/appstore/tibok.app

# Create pkg installer
echo ""
echo "📦 Creating .pkg installer..."
productbuild \
    --component .build/appstore/tibok.app /Applications \
    --sign "$INSTALLER_CERT" \
    .build/appstore/Tibok-${VERSION}.pkg

# Verify pkg
echo ""
echo "🔍 Verifying package..."
pkgutil --check-signature .build/appstore/Tibok-${VERSION}.pkg

PKG_SIZE=$(du -h .build/appstore/Tibok-${VERSION}.pkg | awk '{print $1}')
echo ""
echo -e "${GREEN}✅ Package created successfully!${NC}"
echo "📦 Size: $PKG_SIZE"
echo "📍 Location: .build/appstore/Tibok-${VERSION}.pkg"
echo ""
echo "Next steps:"
echo "1. Validate the package: xcrun altool --validate-app -f .build/appstore/Tibok-${VERSION}.pkg -t macos -u <your-apple-id> -p <app-specific-password>"
echo "2. Upload to App Store: xcrun altool --upload-app -f .build/appstore/Tibok-${VERSION}.pkg -t macos -u <your-apple-id> -p <app-specific-password>"
echo ""
echo "Or use Transporter app from the Mac App Store for a GUI upload experience."
