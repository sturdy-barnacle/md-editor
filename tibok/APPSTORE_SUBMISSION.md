# tibok - Apple App Store Submission Guide

**Last Updated**: December 20, 2025
**Current Version**: 1.0.1 (GitHub releases only)
**Target App Store Release**: v1.1+

## Overview

This guide documents the process, requirements, and gotchas for submitting tibok to the Apple App Store after successful GitHub release with Developer ID distribution.

## Current Status

### What's Working (v1.0.1)
- ✅ Direct distribution via GitHub releases (DMG file)
- ✅ Developer ID code signing and notarization
- ✅ macOS 14.0+ (Sonoma) support
- ✅ Apple Silicon (M1/M2/M3/M4+) builds
- ✅ All features: WordPress, plugins, Git, frontmatter, webhooks
- ✅ App launches without crashes (fixed Sparkle issue)

### What Needs Changes for App Store
- ❌ App Store Distribution certificate (different from Developer ID)
- ❌ Sandbox entitlements (tibok-app-store.entitlements needed)
- ❌ Privacy manifest (PrivacyInfo.xcprivacy)
- ❌ Provisioning profile (App Store specific)
- ❌ Build scripts for App Store (separate from DMG build)
- ❌ Testing in sandbox environment

## Key Differences: Developer ID vs App Store

### Current Setup (Developer ID)
```bash
# Signing with Developer ID Application certificate
codesign --force --sign "Developer ID Application: ..." \
  --entitlements tibok/Resources/tibok-dmg.entitlements \
  --options runtime \
  ./app.app

# Notarization required by Apple (security requirement)
xcrun notarytool submit dmg-file.dmg ...

# Distribution: Direct download from GitHub
```

### App Store Setup (Required)
```bash
# Signing with App Store Distribution certificate
codesign --force --sign "3rd Party Mac Developer Application: ..." \
  --entitlements tibok/Resources/tibok-app-store.entitlements \
  ./app.app

# Notarization: NOT required (App Store handles)
# Submission: Via Transporter or App Store Connect web interface

# Distribution: App Store only (auto-updates handled by App Store)
```

## Technical Checklist

### 1. Certificates and Provisioning

**To Complete Before Submission**:
- [ ] Request "App Store Distribution" certificate from Apple Developer Portal
- [ ] Create "Mac App Store" provisioning profile
- [ ] Ensure profile is downloaded and installed in Keychain
- [ ] Verify certificate CN matches signing identity

**Commands**:
```bash
# List available signing identities
security find-identity -v -p codesigning

# Should show both:
# - Developer ID Application
# - 3rd Party Mac Developer Application (for App Store)
```

### 2. Entitlements

**Current Entitlements** (`tibok-dmg.entitlements`):
- ✅ Hardened runtime enabled
- ✅ Code signing enforced
- ✅ Library validation disabled (needed for WebKit, KaTeX)
- ✅ Allow unsigned executables (for plugins)
- ✅ Network client/server for webhooks

**Required Changes for App Store** (new file: `tibok-app-store.entitlements`):
- May need to disable certain entitlements due to sandbox
- Keep network entitlements for webhooks
- Verify file access permissions (documents, temp folders)
- May need to request specific sandbox exceptions

**Entitlements to Verify**:
```xml
<!-- Check these are compatible with sandbox -->
<key>com.apple.security.files.user-selected.read-write</key>
<true/>

<key>com.apple.security.network.client</key>
<true/>

<key>com.apple.security.network.server</key>
<true/>

<key>com.apple.security.device.microphone</key>
<true/> <!-- May be prompted at runtime -->
```

### 3. Privacy Manifest

**Required for App Store** (iOS 17.4+, but Apple extends to macOS):
- Create `PrivacyInfo.xcprivacy` file
- Declare all third-party API usage
- Document SDK integrations

**What tibok Needs to Declare**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>NSPrivacyTracking</key>
  <false/>

  <key>NSPrivacyTrackingDomains</key>
  <array/>

  <key>NSPrivacyAccessedAPITypes</key>
  <array>
    <!-- Highlightr (syntax highlighting) -->
    <!-- swift-markdown (parsing) -->
    <!-- WebKit (preview rendering) -->
  </array>
</dict>
</plist>
```

### 4. Build Scripts

**Create New**: `scripts/build-app-store.sh`
```bash
#!/bin/bash
# Build tibok for App Store submission
# Usage: ./scripts/build-app-store.sh TEAM_ID VERSION

# Similar to build-release-dmg.sh but:
# - Sign with App Store Distribution certificate
# - Use tibok-app-store.entitlements instead of tibok-dmg.entitlements
# - DO NOT copy Sparkle framework
# - DO NOT run notarization
# - Output to .build/app-store/tibok.app
```

### 5. Sandbox Testing

**Before Submission**:
- [ ] Test file operations (open, save, export)
- [ ] Test network features (webhooks, WordPress publishing)
- [ ] Test Git operations (requires terminal access?)
- [ ] Test plugin loading
- [ ] Test document drag & drop
- [ ] Test image paste/drag operations

**Potential Issues**:
- Git operations may require Terminal.app or special permissions
- File access outside ~/Documents might be restricted
- Webhooks require network entitlements

### 6. Submission Process

**Step 1: Prepare Build**
```bash
./scripts/build-app-store.sh F2PFRMGC9V 1.1.0
```

**Step 2: Create App Store Connect Record**
- Go to App Store Connect
- Create new app entry
- Fill in app name, description, categories
- Add screenshots and artwork
- Set privacy policy URL

**Step 3: Upload Binary**
```bash
# Option A: Use Transporter (recommended)
open /Applications/Transporter.app

# Option B: Use xcrun (command line)
xcrun altool --upload-app \
  --file /path/to/app.pkg \
  --type osx \
  --apple-id your@email.com \
  --password app-specific-password \
  --team-id F2PFRMGC9V
```

**Step 4: Wait for Review**
- Apple reviews submission (1-3 days typical)
- May request changes
- Be ready to provide documentation for features

**Step 5: Release**
- Approve for release in App Store Connect
- Select release strategy (immediate or phased)

## Known Issues to Address

### 1. Sparkle Auto-Updates
**Status**: Disabled for v1.0/v1.1

**Impact on App Store**:
- Not allowed on App Store (uses native App Store updates)
- Remove check for updates menu item ✅ (already done in v1.0.1)
- App Store handles all updates automatically

**Future**:
- v1.1+: Keep Sparkle disabled
- Developer ID release: Can enable Sparkle in separate build
- App Store release: Never enable Sparkle

### 2. Git Integration
**Potential Issue**: Git operations via shell commands may not work in sandbox

**Investigation Needed**:
- Test `git status`, `git commit`, `git push` in sandbox
- May require special exceptions
- Consider bundling git binary if needed

### 3. File Access
**Current**: App uses UserDefaults + file system directly

**Sandbox Restrictions**:
- Documents folder: ✅ Allowed (user selected)
- Temp folder: ⚠️ May need exception
- Home directory: ❌ Restricted (but might work with user selection)

**Required Changes**:
- Use proper file access APIs
- Implement file permissions requests
- May need to ask for user document folder access upfront

### 4. Plugin System
**Status**: Works in Developer ID build

**App Store Concerns**:
- Plugins load dynamic libraries (may violate sandbox)
- Code injection concerns
- May need to restrict plugin capabilities

**Options**:
1. Disable plugin system in App Store version
2. Implement sandboxed plugin loader
3. Request specific exemptions from Apple

## Testing Checklist

### Pre-Submission Testing
- [ ] Build with App Store certificate succeeds
- [ ] App signs correctly
- [ ] Privacy manifest validates
- [ ] Entitlements are correct
- [ ] App launches without errors
- [ ] All features work in sandbox
- [ ] No console errors in Console.app
- [ ] Keyboard shortcuts work
- [ ] Markdown rendering works
- [ ] WordPress publishing works (check network)
- [ ] Git operations work
- [ ] File open/save/export works
- [ ] Frontmatter editor works
- [ ] Webhooks work (network access)
- [ ] Plugin loading works (or disabled)

### App Store Review Concerns
- [ ] App follows Apple's design guidelines
- [ ] No rejection reasons from previous rejections
- [ ] Privacy policy included and accurate
- [ ] No external links that bypass App Store
- [ ] Screenshots are clear and professional
- [ ] App description is accurate

## Timeline

**Realistic Schedule** (from first App Store submission):
- **Day 1**: Prepare certificates and build scripts
- **Day 2**: Build, sign, and prepare submission
- **Day 3**: Create App Store Connect record and upload
- **Days 4-7**: Apple review (typically 1-3 days, but can take longer)
- **Day 8+**: Respond to any review feedback or publish if approved

## Important Notes for Future Work

### For v1.1 (App Store Ready)
1. ✅ Resolve Sparkle framework issues (DONE - removed for v1.0.1)
2. ⏳ Create App Store specific build scripts
3. ⏳ Create PrivacyInfo.xcprivacy manifest
4. ⏳ Create tibok-app-store.entitlements
5. ⏳ Test all features in sandbox
6. ⏳ Document any feature limitations in App Store version
7. ⏳ Prepare screenshots and marketing materials

### Maintenance Strategy
- Keep two build variants:
  - **Developer ID**: Full features (GitHub releases)
  - **App Store**: Potentially limited features (Mac App Store)
- Use build-time flags to disable unavailable features
- Maintain two sets of entitlements files
- Document differences in README

### Support Differences
- **Developer ID users**: Can update directly or wait for new build
- **App Store users**: Automatic updates via App Store

## Resources

- [Apple App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/macos/)
- [Code Signing Guide](https://developer.apple.com/documentation/technotes/tn3127-inside-code-signing/)
- [Sandbox Overview](https://developer.apple.com/documentation/security/sandbox)
- [Privacy Manifest Guide](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)

---

**Last Updated**: December 20, 2025
**Prepared by**: Claude Code during v1.0.1 release
**Status**: Ready for v1.1 planning phase
