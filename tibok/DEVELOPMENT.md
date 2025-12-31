# Tibok Development Guide

## Release Process

This document describes how to create and distribute signed releases of Tibok.

### Prerequisites

- Apple Developer Account with Developer ID Application certificate installed in Keychain
- Your Apple Developer Team ID (found at https://developer.apple.com/account under "Membership")
- `create-dmg` tool: `brew install create-dmg`

### Step 1: Build Signed Release

To build a code-signed release with proper entitlements:

```bash
./scripts/build-release-dmg.sh YOUR_TEAM_ID VERSION
```

**Example:**
```bash
./scripts/build-release-dmg.sh F2PFRMGC9V 1.0.2
```

This script will:
- Build the app in release mode for arm64
- Sign it with your Developer ID Application certificate
- Apply entitlements from `tibok/Resources/tibok-dmg.entitlements`
- Update the build number in Info.plist

**Output:** `.build/release/tibok.app` (signed app bundle)

### Step 2: Create Distributable DMG

To create a professional disk image:

```bash
./scripts/create-dmg.sh VERSION
```

**Example:**
```bash
./scripts/create-dmg.sh 1.0.2
```

This creates a styled DMG with an Application link for easy installation.

**Output:** `.build/release/Tibok-VERSION.dmg`

### Step 3 (Optional): Notarize with Apple

For full Gatekeeper approval and to remove quarantine warnings:

```bash
./scripts/notarize-dmg.sh .build/release/Tibok-VERSION.dmg APPLE_ID TEAM_ID
```

**Example:**
```bash
./scripts/notarize-dmg.sh .build/release/Tibok-1.0.2.dmg user@example.com F2PFRMGC9V
```

This will:
- Submit the DMG to Apple for notarization
- Store your Apple ID password in Keychain for future use
- Poll Apple until notarization completes
- Staple the notarization ticket to the app

**Note:** Notarization takes 5-10 minutes typically.

### Step 4: Publish Release

1. Test the DMG locally by extracting and launching the app
2. Upload to GitHub releases with release notes
3. Update the appcast.xml file for auto-updates (if using Sparkle)

## Testing a Release

To test if a release is properly signed and will work for end users:

1. Extract the DMG:
   ```bash
   hdiutil attach .build/release/Tibok-1.0.2.dmg
   ```

2. Copy the app to Applications:
   ```bash
   cp -r /Volumes/Tibok-1.0.2/tibok.app /Applications/
   ```

3. Launch the app:
   ```bash
   open /Applications/tibok.app
   ```

Should launch without any "damaged" or security warnings.

## Code Signing Details

- **Certificate Type:** Developer ID Application (not development certificate)
- **Entitlements:** `tibok/Resources/tibok-dmg.entitlements`
- **Keychain:** Certificate must be installed in user's Keychain
- **Team ID:** Required to identify which certificate to use

### Finding Your Developer ID Application Certificate

In Keychain Access:
1. Open Keychain Access
2. Search for "Developer ID Application"
3. You should see "Developer ID Application: [Your Name] (YOUR_TEAM_ID)"
4. If missing, download from Apple Developer account

## EdDSA Signature Verification for Sparkle

For additional security, you can sign DMG files with EdDSA (Ed25519) signatures. This allows Sparkle to cryptographically verify downloads before installing them.

### Setup: Generate EdDSA Keys (One-time)

**Step 1: Generate and export the key**

```bash
arch -arm64 ./Frameworks/generate_keys --account ed25519 -x ~/.tibok_sparkle_key.pem
```

This will:
- Show your public key (save this for reference)
- Export your private key to `~/.tibok_sparkle_key.pem`
- May prompt for Keychain access (click "Allow")

**Step 2: Secure the key file**

The private key file should never be committed to git:

```bash
echo ~/.tibok_sparkle_key.pem >> .gitignore
```

**Step 3: Store the public key** (it's already in `Info.plist` as `SUPublicEDKey`)

### Signing a Release DMG

Once you have the key file set up, signing is automated:

```bash
python3 scripts/sign-dmg-ed25519.py .build/release/Tibok-VERSION.dmg
```

This will:
1. Read the private key from `~/.tibok_sparkle_key.pem`
2. Sign the DMG using Ed25519
3. Output the base64-encoded signature
4. Show you exactly what to add to `appcast.xml`

### Example: Complete signing workflow for v1.0.2

```bash
# Build and sign release (code-signing)
./scripts/build-release-dmg.sh F2PFRMGC9V 1.0.2
./scripts/create-dmg.sh 1.0.2

# Add EdDSA signature (Sparkle verification)
SIGNATURE=$(python3 scripts/sign-dmg-ed25519.py .build/release/Tibok-1.0.2.dmg | grep "^[A-Za-z0-9+/=].*==$" | head -1)

# Update appcast.xml with the signature
# (or manually copy-paste from the script output)
```

### How It Works

1. **Key Generation**: Sparkle's `generate_keys` tool creates an Ed25519 key pair
   - Private key: Stored securely in Keychain and exported to `~/.tibok_sparkle_key.pem`
   - Public key: Distributed with the app in `Info.plist` as `SUPublicEDKey`

2. **Signing**: DMG file is signed with the private key
   - Uses Ed25519 (RFC 8032) elliptic curve signature scheme
   - Signature is base64-encoded in `appcast.xml`

3. **Verification**: Sparkle verifies signatures before installing updates
   - Retrieves the public key from app's `Info.plist`
   - Verifies the signature matches the downloaded file
   - Refuses to install if signature is invalid or missing

### Prerequisites

- **macOS Keychain**: Private key stored securely (generated once, used forever)
- **Python 3.9+**: For the signing script
- **cryptography library**: Install with `pip3 install cryptography`

### Key Rotation (If compromised)

If your private key is compromised, you need to:

1. Delete the old key from Keychain
2. Regenerate with `./Frameworks/generate_keys --account ed25519`
3. Update `SUPublicEDKey` in `Info.plist` with the new public key
4. Bump the app version and re-release

## Troubleshooting

### "App is damaged and needs to be put in the trash"

This means the app is not properly code-signed or the signature is invalid. Ensure:
1. You have a valid Developer ID Application certificate in Keychain
2. You used the correct Team ID in the build script
3. The certificate hasn't expired

### "Cannot be opened because it is from an unidentified developer"

The app is signed but not notarized. Users can:
- Control+Click and select "Open" to bypass this once
- Or you can notarize the DMG (Step 3 above)

### Build Script Fails with "identity not found"

The Team ID doesn't match any Developer ID Application certificate in your Keychain. Verify:
1. Your Team ID is correct
2. Your Developer ID Application certificate is installed
3. The certificate is for Developer ID (not development)

## Release History

- **v1.0.4** - Critical git detection fix for production builds - December 30, 2025
- **v1.0.3** - Git UI improvements, NSPanel migration - December 30, 2025
- **v1.0.2** - Bug fixes (keyboard input, WordPress selection) - Code-signed and distributed via DMG
- **v1.0.1** - Previous release
- **v1.0.0** - Initial release

All releases from v1.0.0 onwards are code-signed with Developer ID certificates.

## Development Progress Notes

### December 30, 2025 - Git UI Improvements

**Issues Identified:**
1. Modal flash on all git sheets (commit, branch, diff, history) - content briefly reappears during dismissal
2. Diff preview race condition - sometimes fails to load on first click, requires retry
3. Untracked files showing misleading "View Changes" button that opens empty modal

**Root Causes:**
1. **Modal Flash**: SwiftUI sheet dismissal re-evaluates content during animation - a framework limitation
2. **Race Condition**: Three separate @State updates (selectedDiffFile, isDiffStaged, showDiffSheet) execute out of order due to async batching
3. **Untracked Files**: Diff button shown unconditionally without checking file.status

**Solution Implemented:**
- Migrated all 4 git modals from SwiftUI sheets to AppKit NSPanel
- NSPanel provides instant show/dismiss with zero animation flash
- Pattern based on proven EditorView implementation (slash menu, date picker, emoji picker)

**Files Changed:**
1. **Created**: `tibok/Helpers/GitPanelManager.swift` (213 lines)
   - Centralized NSPanel manager for all 4 git modals
   - Each panel method: show/dismiss with SwiftUI content via NSHostingView
   - Registered in Xcode project via xcodegen

2. **Modified**: `tibok/Views/GitPanelView.swift`
   - Added DiffPresentationState struct for atomic state management
   - Replaced 12 @State variables with panelManager and diffState
   - Updated 4 button handlers to call panelManager methods
   - Removed 70 lines of sheet modifiers
   - Added onChange handler for diff presentation

3. **Modified**: `tibok/Views/GitDiffView.swift`
   - Added onDismiss callback parameter
   - Removed Environment.dismiss dependency
   - Added error logging to loadDiff()

4. **Modified**: `tibok/Views/GitHistoryView.swift`
   - Added onDismiss callback parameter
   - Removed Environment.dismiss dependency
   - Added error logging to loadCommits()

5. **Modified**: `tibok/Services/GitService.swift`
   - Added error logging to getDiff() method
   - Guards for invalid relative paths

**Technical Details:**
- NSPanel pattern: `.makeKeyAndOrderFront(nil)` for instant show, `.close()` for instant dismiss
- Style masks: `[.titled, .closable]` for modal, `[.titled, .closable, .resizable]` for resizable panels
- Atomic state: Single struct instead of 3 separate @State variables prevents race condition
- Error logging: Diagnostic prints for debugging git operations

**Build Status:**
- ✅ Build successful (4.16s)
- ✅ All files compiled without errors
- ✅ Only pre-existing warnings (unrelated to changes)

**Testing Checklist:**
- [ ] Commit panel: No flash on open/close
- [ ] Branch panel: No flash on open/close
- [ ] Diff panel: No flash, no race condition, loads on first click
- [ ] History panel: No flash on open/close
- [ ] ESC key dismisses all panels
- [ ] All git workflows functional

**Documentation Updated:**
- ✅ APP_STORE_RELEASE.md - Added bug fixes to changelog
- ✅ CLAUDE.md - Documented NSPanel pattern and atomic state pattern
- ✅ CLAUDE.md - Updated project structure to include Helpers/
- ✅ DEVELOPMENT.md - Added progress notes

**Next Steps:**
- User testing to verify modal flash elimination
- User testing to verify diff preview reliability
- Consider applying NSPanel pattern to other modals if needed

### December 30, 2025 - Git Detection Fix for Production Builds

**Critical Issue:**
Production builds (both DMG and App Store) showing "git repository not found" for workspaces that previously worked. Debug builds unaffected.

**Root Cause:**
App Sandbox restrictions (introduced in commit 9cc7e96 for App Store compliance) block access to .git directories:
- Production builds: Sandbox strictly enforced, .git access blocked
- Debug builds: Sandbox relaxed, violations logged but not enforced
- Git detection uses `git rev-parse --show-toplevel` which requires reading .git directory

**Solution Implemented:**
Security-scoped resource bookmarks for App Store-compliant .git access:

1. **Request Access on Workspace Open** (AppState.swift:325-366)
   - When user opens workspace, request explicit .git directory access
   - Create security-scoped bookmark for persistent access
   - Store bookmark in UserDefaults keyed by workspace path

2. **Restore Access on App Launch** (AppState.swift:382-415)
   - Restore bookmarks from UserDefaults
   - Handle stale bookmarks gracefully (recreate on next access)
   - Start accessing .git directory before git detection

3. **Cleanup on Close** (AppState.swift + tibokApp.swift:441-447)
   - Stop accessing .git when switching workspaces
   - Stop accessing .git on app termination
   - Proper resource management prevents leaks

**Files Changed:**
1. **Modified**: `tibok/Models/AppState.swift` (~45 lines added)
   - setWorkspace(): Cleanup previous + request new .git access
   - loadWorkspaceState(): Restore bookmarks from UserDefaults

2. **Modified**: `tibok/tibokApp.swift` (~10 lines added)
   - Added cleanupSecurityScopedResources() method
   - Integrated with .onDisappear for proper cleanup

**Technical Details:**
- API: `URL.startAccessingSecurityScopedResource()` / `stopAccessingSecurityScopedResource()`
- Bookmarks: Created with `.withSecurityScope` option for persistence
- Stale handling: Detect stale bookmarks, remove from UserDefaults, recreate on next access
- Error logging: Diagnostic prints for debugging access grants/denials

**Build Status:**
- ✅ Build successful (15.19s release build)
- ✅ DMG created and notarized (Submission ID: 71083ccc-3fb6-4057-ab2f-33492a61bd24)
- ✅ GitHub release v1.0.4 published
- ✅ Only pre-existing warning (await on refreshGitStatus)

**Testing Checklist:**
- [ ] Git panel appears in production DMG for git repositories
- [ ] Git detection works after app restart (bookmark restored)
- [ ] All git operations functional (commit, push, pull, diff)
- [ ] No sandbox violations in Console.app
- [ ] Debug builds continue to work
- [ ] App Store build detects git correctly

**Documentation Updated:**
- ✅ DEVELOPMENT.md - Added v1.0.4 progress notes
- [ ] APP_STORE_RELEASE.md - Update version history
- [ ] CLAUDE.md - Document security-scoped bookmark pattern

**Next Steps:**
- User testing with production DMG
- Monitor for sandbox violations
- Consider applying pattern to other hidden directories if needed
