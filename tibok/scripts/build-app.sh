#!/bin/bash
# Build tibok.app bundle from Swift Package Manager build

set -e

cd "$(dirname "$0")/.."

echo "Building tibok..."
swift build

APP_DIR=".build/debug/tibok.app"

echo "Creating app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"
mkdir -p "$APP_DIR/Contents/Frameworks"

# Copy executable
cp .build/debug/tibok "$APP_DIR/Contents/MacOS/"

# Copy Info.plist
cp tibok/Resources/Info.plist "$APP_DIR/Contents/"

# Compile Liquid Glass icon if .icon file exists
if [ -d "tibok/Resources/IconLayers/icon.icon" ]; then
    echo "Compiling Liquid Glass icon..."
    /Applications/Xcode.app/Contents/Developer/usr/bin/actool \
        --compile "$APP_DIR/Contents/Resources" \
        --platform macosx \
        --minimum-deployment-target 14.0 \
        --app-icon icon \
        --output-partial-info-plist /tmp/icon-info.plist \
        tibok/Resources/IconLayers/icon.icon
elif [ -f "tibok/Resources/AppIcon.icns" ]; then
    # Fallback to legacy icns - rename to match Info.plist CFBundleIconFile
    echo "Using legacy .icns icon..."
    cp tibok/Resources/AppIcon.icns "$APP_DIR/Contents/Resources/icon.icns"
fi

# Sparkle framework disabled for debug builds due to code signing complexity
# Debug builds don't include Sparkle; release build handles Sparkle properly
# To enable: Uncomment the if/elif blocks below and rebuild
# if [ -d ".build/arm64-apple-macosx/debug/Sparkle.framework" ]; then
#     echo "Copying Sparkle framework..."
#     cp -r .build/arm64-apple-macosx/debug/Sparkle.framework "$APP_DIR/Contents/Frameworks/"
# elif [ -d ".build/debug/Sparkle.framework" ]; then
#     echo "Copying Sparkle framework..."
#     cp -r .build/debug/Sparkle.framework "$APP_DIR/Contents/Frameworks/"
# fi

# Copy resource bundles
cp -r .build/debug/tibok_tibok.bundle "$APP_DIR/Contents/Resources/" 2>/dev/null || true
cp -r .build/debug/Highlightr_Highlightr.bundle "$APP_DIR/Contents/Resources/" 2>/dev/null || true

# Copy KaTeX for offline math rendering
if [ -d "tibok/Resources/katex" ]; then
    cp -r tibok/Resources/katex "$APP_DIR/Contents/Resources/"
fi

# Copy user documentation for Help menu
if [ -d "user_docs" ]; then
    cp -r user_docs "$APP_DIR/Contents/Resources/"
fi

# Create PkgInfo
echo "APPL????" > "$APP_DIR/Contents/PkgInfo"

# Fix Sparkle framework rpath if it exists (for release builds)
if [ -d "$APP_DIR/Contents/Frameworks/Sparkle.framework" ]; then
    echo "Fixing Sparkle framework install name and rpath..."

    # CRITICAL: Fix the framework's install name FIRST
    # This tells dyld where to find the framework itself
    install_name_tool -id "@executable_path/../Frameworks/Sparkle.framework/Versions/B/Sparkle" \
        "$APP_DIR/Contents/Frameworks/Sparkle.framework/Versions/B/Sparkle"

    # Update the main executable's reference
    install_name_tool -change "@rpath/Sparkle.framework/Versions/B/Sparkle" \
        "@executable_path/../Frameworks/Sparkle.framework/Versions/B/Sparkle" \
        "$APP_DIR/Contents/MacOS/tibok" 2>/dev/null || true

    # Add rpath as fallback for future frameworks
    install_name_tool -add_rpath "@executable_path/../Frameworks" \
        "$APP_DIR/Contents/MacOS/tibok" 2>/dev/null || true
fi

# Sign app bundle (required for macOS security)
echo "Signing app bundle..."
codesign -f -s - --deep "$APP_DIR" 2>/dev/null || true

echo "Done! App bundle created at: $APP_DIR"
echo "Run with: open $APP_DIR"
