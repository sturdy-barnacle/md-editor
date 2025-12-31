#!/bin/sh

echo "CI Post Clone Starting"

# CI_WORKSPACE may be empty in ci_post_clone, derive from script location
# Script is at: <repo>/ci_scripts/ci_post_clone.sh
# So workspace is one directory up from script location
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "SCRIPT_DIR: $SCRIPT_DIR"
echo "WORKSPACE: $WORKSPACE"
echo "CI_BUILD_NUMBER: $CI_BUILD_NUMBER"

PLIST_FILE="${WORKSPACE}/tibok/Resources/Info-AppStore.plist"
echo "PLIST_FILE: $PLIST_FILE"

if [ -f "$PLIST_FILE" ]; then
    echo "Found plist file"
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $CI_BUILD_NUMBER" "$PLIST_FILE"
    echo "Set CFBundleVersion to $CI_BUILD_NUMBER"
else
    echo "ERROR: Plist not found"
    ls -la "$WORKSPACE"
    ls -la "$WORKSPACE/tibok" || true
    exit 1
fi

echo "CI Post Clone Complete"
