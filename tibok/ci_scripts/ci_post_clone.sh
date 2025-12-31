#!/bin/sh

echo "CI Post Clone Starting"
echo "CI_WORKSPACE: $CI_WORKSPACE"
echo "CI_BUILD_NUMBER: $CI_BUILD_NUMBER"

# Find the plist file
PLIST_FILE="${CI_WORKSPACE}/tibok/Resources/Info-AppStore.plist"

# List workspace to debug
ls -la "$CI_WORKSPACE" || true
ls -la "$CI_WORKSPACE/tibok" || true
ls -la "$CI_WORKSPACE/tibok/Resources" || true

# Try to set build number if file exists
if [ -f "$PLIST_FILE" ]; then
    echo "Found plist at: $PLIST_FILE"
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $CI_BUILD_NUMBER" "$PLIST_FILE"
    echo "Set CFBundleVersion to $CI_BUILD_NUMBER"
else
    echo "Plist not found at expected path"
    # Try alternate path
    ALT_PLIST="${CI_WORKSPACE}/Resources/Info-AppStore.plist"
    if [ -f "$ALT_PLIST" ]; then
        echo "Found at alternate path: $ALT_PLIST"
        /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $CI_BUILD_NUMBER" "$ALT_PLIST"
    fi
fi

echo "CI Post Clone Complete"
exit 0
