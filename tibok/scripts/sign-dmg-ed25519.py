#!/usr/bin/env python3

"""
Sign a DMG file with EdDSA (Ed25519) keys for Sparkle updates.
This script properly handles Ed25519 signing which OpenSSL struggles with.
"""

import sys
import os
import base64
import hashlib
from pathlib import Path

def main():
    if len(sys.argv) < 2:
        print("Usage: sign-dmg-ed25519.py <path-to-dmg> [path-to-key-file]")
        print("")
        print("Signs a DMG file with EdDSA private key for Sparkle updates.")
        print("Outputs the signature suitable for appcast.xml")
        print("")
        print("Arguments:")
        print("  <path-to-dmg>       Path to the DMG file to sign")
        print("  [path-to-key-file]  Path to EdDSA private key (default: ~/.tibok_sparkle_key.pem)")
        sys.exit(1)

    dmg_path = sys.argv[1]
    key_file = sys.argv[2] if len(sys.argv) > 2 else os.path.expanduser("~/.tibok_sparkle_key.pem")

    # Verify DMG exists
    if not os.path.isfile(dmg_path):
        print(f"Error: DMG file not found: {dmg_path}")
        sys.exit(1)

    # Verify key file exists
    if not os.path.isfile(key_file):
        print(f"Error: Private key file not found: {key_file}")
        print("")
        print("To generate the key file, run:")
        print("  arch -arm64 ./Frameworks/generate_keys --account ed25519 -x ~/.tibok_sparkle_key.pem")
        print("")
        sys.exit(1)

    print("=" * 42)
    print("Signing DMG with EdDSA Key (Ed25519)")
    print("=" * 42)
    print(f"DMG: {dmg_path}")
    print(f"Key file: {key_file}")
    print("")
    print("Signing DMG...")

    # Import cryptography library
    try:
        from cryptography.hazmat.primitives.asymmetric import ed25519
        from cryptography.hazmat.primitives import serialization
    except ImportError:
        print("Error: cryptography library not found")
        print("")
        print("Install it with:")
        print("  pip3 install cryptography")
        sys.exit(1)

    # Read and decode the private key seed
    with open(key_file, 'r') as f:
        key_seed_b64 = f.read().strip()

    try:
        key_seed = base64.b64decode(key_seed_b64)
    except Exception as e:
        print(f"Error: Failed to decode private key: {e}")
        sys.exit(1)

    if len(key_seed) != 32:
        print(f"Error: Invalid key seed length: {len(key_seed)} (expected 32 bytes)")
        sys.exit(1)

    # Create Ed25519 private key from seed
    try:
        private_key = ed25519.Ed25519PrivateKey.from_private_bytes(key_seed)
    except Exception as e:
        print(f"Error: Failed to create private key: {e}")
        sys.exit(1)

    # Read DMG and sign it
    try:
        with open(dmg_path, 'rb') as f:
            dmg_data = f.read()
    except Exception as e:
        print(f"Error: Failed to read DMG: {e}")
        sys.exit(1)

    # Sign the DMG using Ed25519
    try:
        signature_bytes = private_key.sign(dmg_data)
    except Exception as e:
        print(f"Error: Failed to sign DMG: {e}")
        sys.exit(1)

    # Encode signature as base64
    signature_b64 = base64.b64encode(signature_bytes).decode('ascii')

    # Get file size
    dmg_size = os.path.getsize(dmg_path)

    print("")
    print("=" * 42)
    print("✓ Signature Generated Successfully")
    print("=" * 42)
    print("")
    print("EdDSA Signature (for appcast.xml):")
    print("")
    print(signature_b64)
    print("")
    print("File Information:")
    print(f"  Size: {dmg_size} bytes")
    print(f"  URL: https://github.com/sturdy-barnacle/md-editor/releases/download/v1.0.2/Tibok-1.0.2.dmg")
    print("")
    print("=" * 42)
    print("Update appcast.xml with this signature:")
    print("=" * 42)
    print("")
    print("Replace the enclosure element with:")
    print("")
    print("    <enclosure")
    print(f'        url="https://github.com/sturdy-barnacle/md-editor/releases/download/v1.0.2/Tibok-1.0.2.dmg"')
    print(f'        sparkle:edSignature="{signature_b64}"')
    print(f'        length="{dmg_size}"')
    print('        type="application/octet-stream"')
    print("    />")
    print("")

if __name__ == "__main__":
    main()
