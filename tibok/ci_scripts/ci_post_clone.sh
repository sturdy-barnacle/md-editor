#!/bin/sh
set -e

echo "Setting build number to CI_BUILD_NUMBER: $CI_BUILD_NUMBER"

PLIST_FILE="${CI_WORKSPACE}/tibok/Resources/Info-AppStore.plist"

# Add CFBundleVersion to Info.plist (after CFBundleShortVersionString)
# Using Add command since the key doesn't exist in the source plist
/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $CI_BUILD_NUMBER" \
  "$PLIST_FILE"

echo "Build number set to: $CI_BUILD_NUMBER"
