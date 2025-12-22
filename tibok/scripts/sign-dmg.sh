#!/bin/bash

# Sign a DMG file with EdDSA keys for Sparkle updates
# Usage: ./sign-dmg.sh <path-to-dmg> [path-to-key-file]
# Key file defaults to ~/.tibok_sparkle_key.pem if not specified

if [ $# -lt 1 ]; then
    echo "Usage: $0 <path-to-dmg> [path-to-key-file]"
    echo ""
    echo "Signs a DMG file with EdDSA private key for Sparkle updates."
    echo "Outputs the signature suitable for appcast.xml"
    echo ""
    echo "Arguments:"
    echo "  <path-to-dmg>       Path to the DMG file to sign"
    echo "  [path-to-key-file]  Path to EdDSA private key (default: ~/.tibok_sparkle_key.pem)"
    exit 1
fi

DMG_PATH="$1"
KEY_FILE="${2:-$HOME/.tibok_sparkle_key.pem}"

if [ ! -f "$DMG_PATH" ]; then
    echo "Error: DMG file not found: $DMG_PATH"
    exit 1
fi

echo "=========================================="
echo "Signing DMG with EdDSA Key"
echo "=========================================="
echo "DMG: $DMG_PATH"
echo "Key file: $KEY_FILE"
echo ""

# Check if key file exists
if [ ! -f "$KEY_FILE" ]; then
    echo "Error: Private key file not found: $KEY_FILE"
    echo ""
    echo "To generate the key file, run:"
    echo "  arch -arm64 ./Frameworks/generate_keys --account ed25519 -x ~/.tibok_sparkle_key.pem"
    echo ""
    exit 1
fi

# Create a temporary file for the decoded private key
TEMP_KEY=$(mktemp)
trap "rm -f $TEMP_KEY" EXIT

echo "Decoding private key and signing DMG..."

# Decode the base64-encoded private key from the file
cat "$KEY_FILE" | base64 -D > "$TEMP_KEY" 2>/dev/null

if [ ! -s "$TEMP_KEY" ]; then
    echo "Error: Failed to decode private key from file"
    echo "The key file might be corrupted or in an invalid format."
    exit 1
fi

# Sign the DMG using the private key
# OpenSSL signs with SHA256 and outputs base64
SIGNATURE=$(openssl dgst -sha256 -sign "$TEMP_KEY" "$DMG_PATH" | openssl base64 -A)

if [ -z "$SIGNATURE" ]; then
    echo "Error: Failed to sign DMG with private key"
    exit 1
fi

echo ""
echo "=========================================="
echo "✓ Signature Generated Successfully"
echo "=========================================="
echo ""
echo "EdDSA Signature (for appcast.xml):"
echo ""
echo "$SIGNATURE"
echo ""
echo "File Information:"
FILE_SIZE=$(stat -f%z "$DMG_PATH")
echo "  Size: $FILE_SIZE bytes"
echo "  URL: https://github.com/sturdy-barnacle/md-editor/releases/download/v1.0.2/Tibok-1.0.2.dmg"
echo ""
echo "========================================"
echo "Update appcast.xml with this signature:"
echo "========================================"
echo ""
echo "Replace the enclosure element with:"
echo ""
echo "    <enclosure"
echo "        url=\"https://github.com/sturdy-barnacle/md-editor/releases/download/v1.0.2/Tibok-1.0.2.dmg\""
echo "        sparkle:edSignature=\"$SIGNATURE\""
echo "        length=\"$FILE_SIZE\""
echo "        type=\"application/octet-stream\""
echo "    />"
echo ""
