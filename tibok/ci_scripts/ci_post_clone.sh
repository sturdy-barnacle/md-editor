#!/bin/sh
set -e

echo "=== CI Post Clone Script ==="
echo "CI_WORKSPACE: $CI_WORKSPACE"
echo "CI_BUILD_NUMBER: $CI_BUILD_NUMBER"

PLIST_FILE="${CI_WORKSPACE}/tibok/Resources/Info-AppStore.plist"
echo "PLIST_FILE: $PLIST_FILE"

# Check if file exists
if [ -f "$PLIST_FILE" ]; then
    echo "✅ Plist file exists"
else
    echo "❌ Plist file NOT found at: $PLIST_FILE"
    echo "Listing CI_WORKSPACE contents:"
    ls -la "$CI_WORKSPACE"
    echo "Listing tibok directory:"
    ls -la "$CI_WORKSPACE/tibok" || echo "tibok dir not found"
    exit 1
fi

# Show current value
echo "Current CFBundleVersion:"
/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$PLIST_FILE" || echo "Key not found"

# Set the build number
echo "Setting CFBundleVersion to: $CI_BUILD_NUMBER"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $CI_BUILD_NUMBER" "$PLIST_FILE"

# Verify
echo "New CFBundleVersion:"
/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$PLIST_FILE"

echo "=== CI Post Clone Complete ==="
