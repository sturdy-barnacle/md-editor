#!/bin/sh
set -e

echo "Setting build number to CI_BUILD_NUMBER: $CI_BUILD_NUMBER"

PLIST_FILE="${CI_WORKSPACE}/tibok/Resources/Info-AppStore.plist"

# Set CFBundleVersion in Info.plist
# Using Set command since the key already exists
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $CI_BUILD_NUMBER" \
  "$PLIST_FILE"

echo "Build number set to: $CI_BUILD_NUMBER"
