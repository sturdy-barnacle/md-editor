# tibok v1.0.2 Release Notes

**Release Date**: December 22, 2025
**Status**: ✅ Production Release
**Download**: [GitHub Releases](https://github.com/sturdy-barnacle/md-editor/releases/tag/v1.0.2)

---

## What's New in v1.0.2

This release focuses on **stability, security, and reliability** with two critical bug fixes and comprehensive infrastructure improvements.

### Critical Bug Fixes

#### 1. 🔧 Fixed Keyboard Input Routing

**Problem**: Text typed in the editor would appear in other applications (browser, terminal, etc.) instead of in tibok.

**What was happening**:
- The app window was visible and responsive
- Buttons and UI elements worked fine
- But the keyboard focus wasn't properly registered with macOS
- Result: Input routed to whatever application was "active" at the system level

**How we fixed it**:
- Ensured tibok properly registers as a foreground application with macOS
- Added aggressive window activation and focus management
- Implemented proper first responder chain for text input

**Impact**: ✅ You can now type normally in the editor

---

#### 2. 🔧 Fixed WordPress Selection Reverting to Jekyll

**Problem**: When converting a document from Jekyll to WordPress, the editor would automatically switch back to Jekyll.

**What was happening**:
- User selects "WordPress" in the Frontmatter Inspector
- User clicks "Convert"
- UI briefly shows "Converting to WordPress..."
- Then immediately reverts to "Jekyll"
- Frontmatter structure changed but UI showed wrong selection

**How we fixed it**:
- Added intelligent auto-detection bypass
- When user explicitly chooses a format, that choice is preserved
- Auto-detection only runs when discovering format from existing frontmatter
- Respects user intent 100%

**Impact**: ✅ You can reliably convert between Jekyll and WordPress

---

### Security Improvements

#### 3. 🔐 Code Signing & Notarization

All releases are now:
- ✅ **Code-signed** with Apple Developer ID
  - Proves the app comes from a trusted developer
  - Allows Gatekeeper to verify app integrity

- ✅ **Notarized** by Apple
  - Checked by Apple's automated security analysis
  - Removes "unidentified developer" warnings
  - Users can install without security concerns

#### 4. 🔐 EdDSA Signature Verification

Updates are now cryptographically signed:
- ✅ **Ed25519 signatures** on all DMG files
- ✅ **Sparkle verification** before installation
- ✅ **Tamper protection** - ensures updates haven't been modified
- ✅ **Completely transparent** - happens automatically

**Why this matters**: Even if someone intercepts your download, the signature proves it's authentic.

---

## Installation & Upgrade

### New Users

1. Download `Tibok-1.0.2.dmg` from [releases page](https://github.com/sturdy-barnacle/md-editor/releases/tag/v1.0.2)
2. Mount the DMG (double-click)
3. Drag `tibok.app` to the Applications folder
4. Launch tibok from Applications

No security warnings - everything is properly signed! ✓

### Existing Users (Auto-Update)

If you have auto-updates enabled (Sparkle), you'll see:
- "New version available" notification
- Click to download and install v1.0.2
- Installation is automatic in the background

The new version launches when you restart the app.

---

## Technical Details

### Changes Under the Hood

**Build Process**:
- Proper macOS app bundle structure
- Native code signing with Developer ID
- Apple notarization integration
- EdDSA signature generation

**Application**:
- NSApplication foreground registration
- Window focus management improvements
- First responder keyboard routing
- Frontmatter detection bypass logic

**Release Infrastructure**:
- Automated code signing script
- Notarization workflow
- EdDSA signature verification
- Appcast feed with signatures

### System Requirements

- **macOS 14.0 (Sonoma)** or later
- **Apple Silicon (ARM64)**
- **~5 MB** disk space
- **macOS Keychain** (for update verification - automatic)

### Known Issues

None reported in v1.0.2.

---

## Feedback & Support

### Report Issues

Found a problem? Help us improve:
1. Search [existing issues](https://github.com/sturdy-barnacle/md-editor/issues)
2. Create a [new issue](https://github.com/sturdy-barnacle/md-editor/issues/new) with:
   - What you were doing
   - What you expected to happen
   - What actually happened
   - Your macOS version

### Feature Requests

Have an idea? Share it:
1. Check [discussions](https://github.com/sturdy-barnacle/md-editor/discussions)
2. Start a new discussion
3. Describe the feature and why it would be helpful

### Security Issues

Found a security vulnerability? **Don't** open a public issue:
1. Email the maintainer directly
2. Include technical details
3. Allow time for a fix before public disclosure

---

## Version History

| Version | Date | Status | Download |
|---------|------|--------|----------|
| **1.0.2** | Dec 22, 2025 | ✅ Current | [Release](https://github.com/sturdy-barnacle/md-editor/releases/tag/v1.0.2) |
| 1.0.1 | Dec 19, 2025 | ✅ Previous | [Release](https://github.com/sturdy-barnacle/md-editor/releases/tag/v1.0.1) |
| 1.0.0 | Dec 19, 2025 | ✅ Initial | [Release](https://github.com/sturdy-barnacle/md-editor/releases/tag/v1.0.0) |

All releases from v1.0.0 onwards are code-signed and notarized.

---

## Developer Information

### Building v1.0.2 Yourself

Instructions for developers:
1. Clone the repository
2. See [DEVELOPMENT.md](DEVELOPMENT.md) for build instructions
3. Follow the code-signing and notarization process

### Release Process Documentation

Complete documentation:
- **[DEVELOPMENT.md](DEVELOPMENT.md)** - Building, signing, notarizing, and releasing
- **[PROJECT_STATUS.md](PROJECT_STATUS.md)** - Overall project status and roadmap
- **[CHANGELOG.md](CHANGELOG.md)** - Complete version history

---

## Thank You

Thanks for using tibok! We appreciate:
- Your feedback and bug reports
- Feature requests and suggestions
- Spreading the word about tibok

---

**tibok v1.0.2** - Built for writers who love simplicity.

**More info**: [GitHub](https://github.com/sturdy-barnacle/md-editor) | [User Docs](user_docs/README.md) | [FAQ](user_docs/FAQ.md)
