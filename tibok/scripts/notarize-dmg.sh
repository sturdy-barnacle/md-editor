#!/bin/bash
# Notarize DMG with Apple's notary service
# Usage: ./scripts/notarize-dmg.sh DMG_PATH APPLE_ID TEAM_ID
# Example: ./scripts/notarize-dmg.sh ".build/release/Tibok-1.0.0.dmg" "you@email.com" "ABC123DEF4"
#
# Requirements:
#  - Xcode Command Line Tools 13+
#  - Credentials stored via: xcrun notarytool store-credentials TIBOK_NOTARIZATION ...

set -e
set -u

DMG_PATH="${1}"
APPLE_ID="${2}"
TEAM_ID="${3}"

cd "$(dirname "$0")/.."

echo "=========================================="
echo "Notarizing DMG with Apple"
echo "=========================================="
echo "DMG: $DMG_PATH"
echo "Apple ID: $APPLE_ID"
echo "Team ID: $TEAM_ID"
echo ""

# Verify DMG exists
if [ ! -f "$DMG_PATH" ]; then
    echo "Error: DMG not found at $DMG_PATH"
    exit 1
fi

# Verify DMG is signed
echo "Verifying DMG signature..."
if ! codesign --verify "$DMG_PATH" 2>/dev/null; then
    echo "Warning: DMG may not be properly signed"
fi

echo ""
echo "Submitting to Apple notary service..."
echo "(This may take 5-15 minutes)"
echo ""

# Submit for notarization with --wait flag (blocks until complete)
if ! xcrun notarytool submit "$DMG_PATH" \
    --keychain-profile "TIBOK_NOTARIZATION" \
    --wait \
    --timeout 30m; then

    echo ""
    echo "ERROR: Notarization failed!"
    echo ""
    echo "To troubleshoot:"
    echo "1. Get the most recent submission ID:"
    echo "   xcrun notarytool history --apple-id $APPLE_ID --team-id $TEAM_ID --password @keychain:TIBOK_NOTARIZATION"
    echo ""
    echo "2. View detailed error log with submission ID:"
    echo "   xcrun notarytool log SUBMISSION_ID --apple-id $APPLE_ID --team-id $TEAM_ID --password @keychain:TIBOK_NOTARIZATION"
    echo ""
    exit 1
fi

echo ""
echo "Notarization successful! Stapling ticket to DMG..."
xcrun stapler staple "$DMG_PATH"

echo ""
echo "Verifying notarization staple..."
xcrun stapler validate "$DMG_PATH"

echo ""
echo "Note: DMG file itself does not require Gatekeeper assessment."
echo "The notarized app inside will be verified by Gatekeeper when mounted and executed."

echo ""
echo "=========================================="
echo "✓ Notarization Complete!"
echo "=========================================="
echo "File: $DMG_PATH"
echo "Status: Notarized and stapled"
echo ""
echo "✓ Ready for distribution!"
echo "Users can download and open without Gatekeeper warnings."
echo ""
