#!/bin/sh
set -e

# CI_WORKSPACE is empty during ci_post_clone, derive from script location
# Script is at: <repo>/ci_scripts/ci_post_clone.sh
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Setting build number to CI_BUILD_NUMBER: $CI_BUILD_NUMBER"
PLIST_FILE="${WORKSPACE}/tibok/Resources/Info-AppStore.plist"

/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $CI_BUILD_NUMBER" "$PLIST_FILE"
echo "Build number set to: $CI_BUILD_NUMBER"
