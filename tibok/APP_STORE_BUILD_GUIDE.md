# tibok App Store Build Guide

## Overview

This document records the definitive process for building and submitting tibok to the Apple App Store. It captures lessons learned from v1.0.2 development, particularly the fix for ITMS-90546 (Missing Asset Catalog error).

**Status**: ✅ Verified working as of Build #11 (v1.0.2)

---

## Critical Configuration: Asset Catalog in XcodeGen

### The Problem (ITMS-90546)

App Store Connect rejected builds with error:
```
ITMS-90546: Missing asset catalog - Your app is missing the asset catalog
file in "app.tibok.editor". For details, visit:
https://developer.apple.com/documentation/xcode/managing-assets-with-asset-catalogs.
```

**Root Cause**: Assets.xcassets was not being compiled into `Assets.car` during the Xcode build.

### What Didn't Work

❌ **Attempt 1**: Change type in resources section
```yaml
resources:
  - path: tibok/Resources/Assets.xcassets
    type: file  # Changed from folder
```

**Why it failed**: XcodeGen didn't add the asset catalog to the "Copy Bundle Resources" build phase, so Xcode's `actool` (asset catalog compiler) never ran.

### What Did Work ✅

**Correct Configuration** (`project.yml` lines 31-33):
```yaml
sources:
  - path: tibok
    includes:
      - "**/*.swift"
    excludes:
      - Resources/tibok.entitlements
      - Resources/IconLayers
  - path: tibok/Resources/Assets.xcassets
    type: file
    buildPhase: resources  # ← CRITICAL: Explicit build phase assignment
```

**Key Points**:
1. **Asset catalog is in `sources` section** (not `resources`)
2. **Explicit `buildPhase: resources`** tells XcodeGen to add it to Copy Bundle Resources
3. **`type: file`** ensures it's treated as a compilable resource
4. Result: XcodeGen generates .pbxproj with `lastKnownFileType = folder.assetcatalog`
5. Xcode then runs `actool` to compile Assets.xcassets → Assets.car

---

## Complete project.yml Configuration (Working)

```yaml
name: tibok
organizationName: Kristina Quinones

settings:
  SWIFT_VERSION: 5.9
  MACOSX_DEPLOYMENT_TARGET: 14.0
  CODE_SIGN_STYLE: Automatic
  CODE_SIGN_IDENTITY: Apple Development
  DEVELOPMENT_TEAM: F2PFRMGC9V

packages:
  swift-markdown:
    url: https://github.com/apple/swift-markdown.git
    from: 0.3.0
  Highlightr:
    url: https://github.com/raspu/Highlightr.git
    from: 2.1.0

targets:
  tibok:
    type: application
    platform: macOS
    deploymentTarget: "14.0"
    sources:
      - path: tibok
        includes:
          - "**/*.swift"
        excludes:
          - Resources/tibok.entitlements
          - Resources/IconLayers
      - path: tibok/Resources/Assets.xcassets
        type: file
        buildPhase: resources  # ← THIS IS THE KEY FIX
    resources:
      - path: tibok/Resources/AppIcon.icns
        type: file
      - path: tibok/Resources/katex
        type: folder
    infoPlist:
      path: tibok/Resources/Info-AppStore.plist
      useBaseLocalizationAsDefault: true
    entitlements:
      path: tibok/Resources/tibok-dmg.entitlements
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: app.tibok.editor
      ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon  # Must match CFBundleIconName
      EXECUTABLE_NAME: tibok
    dependencies:
      - package: swift-markdown
        product: Markdown
      - package: Highlightr
        product: Highlightr

  tibokTests:
    type: bundle.unit-test
    platform: macOS
    deploymentTarget: "14.0"
    sources:
      - path: tibokTests
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: app.tibok.editor.Tests
    dependencies:
      - target: tibok
      - package: swift-markdown
        product: Markdown
      - package: Highlightr
        product: Highlightr

schemes:
  tibok:
    build:
      targets:
        tibok: all
    run:
      config: Debug
      executable: tibok
    test:
      config: Debug
      gatherCoverageData: false
      targets:
        - tibokTests
    profile:
      config: Release
      executable: tibok
    analyze:
      config: Debug
    archive:
      config: Release
```

---

## Critical Info.plist Settings

**File**: `tibok/Resources/Info-AppStore.plist`

### Icon Configuration (Lines 32-35)

```xml
<key>CFBundleIconFile</key>
<string>icon</string>
<key>CFBundleIconName</key>
<string>AppIcon</string>
```

**Important**:
- `CFBundleIconName` must match `ASSETCATALOG_COMPILER_APPICON_NAME` in project.yml (line 46)
- Both should be set to `AppIcon` for asset catalog-based icons
- Do NOT omit CFBundleIconName or leave it as a different value

### Version Configuration (Lines 44-47)

```xml
<key>CFBundleShortVersionString</key>
<string>1.0.2</string>
<key>CFBundleVersion</key>
<string>9</string>  <!-- This WILL be overridden by ci_post_clone.sh -->
```

**Important**:
- CFBundleVersion will be dynamically set by Xcode Cloud's `ci_post_clone.sh`
- Local value is used for local builds only
- Xcode Cloud injects actual build number (10, 11, etc.)

### Required Keys (App Store Compliance)

```xml
<key>LSApplicationCategoryType</key>
<string>public.app-category.productivity</string>

<key>LSMinimumSystemVersion</key>
<string>14.0</string>

<key>NSHighResolutionCapable</key>
<true/>

<key>NSSupportsSuddenTermination</key>
<false/>
```

**Do NOT omit these** - they are checked by App Store validation.

---

## Sandbox Entitlements

**File**: `tibok/Resources/tibok-dmg.entitlements`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.app-sandbox</key>
	<true/>
	<key>com.apple.security.files.user-selected.read-write</key>
	<true/>
	<key>com.apple.security.network.client</key>
	<true/>
</dict>
</plist>
```

**Purpose**:
- `app-sandbox`: Required for App Store
- `files.user-selected.read-write`: Allow file open/save dialogs
- `network.client`: Required for WordPress API calls

**⚠️ Important**: XcodeGen sometimes clears this file. Always restore it after running `xcodegen generate`.

---

## Asset Catalog Structure Requirements

### Directory Layout

```
tibok/Resources/Assets.xcassets/
├── Contents.json (root metadata)
└── AppIcon.appiconset/
    ├── Contents.json (icon set metadata)
    ├── icon_16x16.png
    ├── icon_16x16@2x.png
    ├── icon_32x32.png
    ├── icon_32x32@2x.png
    ├── icon_128x128.png
    ├── icon_128x128@2x.png
    ├── icon_256x256.png
    ├── icon_512x512.png
    ├── icon-iOS-Default-512x512@1x.png
    └── icon-iOS-Default-1024x1024@1x.png
```

### All 10 Icon Sizes Must Exist

macOS App Store requires all 10 sizes (5 logical sizes × 2 for Retina):
- 16×16 @1x and @2x
- 32×32 @1x and @2x
- 128×128 @1x and @2x
- 256×256 @1x and @2x
- 512×512 @1x and @2x

**Verification Command**:
```bash
ls -la tibok/Resources/Assets.xcassets/AppIcon.appiconset/ | grep -E "icon_.*\.png|Contents"
```

---

## Xcode Cloud Build Number Injection

**File**: `ci_scripts/ci_post_clone.sh`

```bash
#!/bin/sh
set -e

echo "Setting build number to CI_BUILD_NUMBER: $CI_BUILD_NUMBER"

PLIST_FILE="${CI_WORKSPACE}/tibok/Resources/Info-AppStore.plist"

# Add CFBundleVersion to Info.plist
/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $CI_BUILD_NUMBER" \
  "$PLIST_FILE"

echo "Build number set to: $CI_BUILD_NUMBER"
```

**Purpose**: Dynamically sets CFBundleVersion to Xcode Cloud's CI_BUILD_NUMBER (9, 10, 11, etc.)

**Must be executable**:
```bash
chmod +x ci_scripts/ci_post_clone.sh
```

---

## Build and Submit Process

### 1. Make Code Changes

Update Swift source files as needed. Commit to `development` branch.

### 2. Update Version Numbers (If New Release)

Edit `tibok/Resources/Info-AppStore.plist`:
```xml
<key>CFBundleShortVersionString</key>
<string>1.0.3</string>  <!-- Update if new version -->
```

### 3. Regenerate Xcode Project

```bash
cd /Users/kq/md-editor/tibok
xcodegen generate --spec project.yml
```

**⚠️ Important**: After running XcodeGen, verify entitlements file is intact:
```bash
cat tibok/Resources/tibok-dmg.entitlements | grep "com.apple.security"
```

If empty/missing, restore it from the template above.

### 4. Commit and Push

```bash
git add -A
git commit -m "Fix ITMS-90546 description..."
git push origin apple-store-distro
```

**Note**: Push to `apple-store-distro` branch to trigger Xcode Cloud builds for App Store submission.

### 5. Monitor Xcode Cloud Build

- Go to https://github.com/sturdy-barnacle/md-editor
- Check "Xcode Cloud" tab
- Watch build progress
- Next Build Number will auto-increment (9→10→11, etc.)

### 6. Expected Build Steps

```
ℹ️ Prepare build for App Store Connect
ℹ️ Build and test
ℹ️ Archive
ℹ️ Upload to App Store Connect
✅ Prepare Build for App Store Connect (should PASS now)
```

If "Prepare Build for App Store Connect" fails, check error details:
- ITMS-90546 = Asset catalog issue
- ITMS-90242 = Missing LSApplicationCategoryType
- ITMS-90296 = Sandbox not enabled

---

## Verification Checklist

Before submitting to App Store, verify:

- ✅ All 10 icon files exist in AppIcon.appiconset
- ✅ Assets.xcassets has Contents.json files (root and AppIcon.appiconset)
- ✅ project.yml has Assets.xcassets in `sources` section with `buildPhase: resources`
- ✅ ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon (line 46)
- ✅ CFBundleIconName = AppIcon (Info.plist line 35)
- ✅ LSApplicationCategoryType = public.app-category.productivity (Info.plist)
- ✅ Sandbox entitlements enabled with app-sandbox = true
- ✅ ci_post_clone.sh is executable and present in ci_scripts/
- ✅ CFBundleVersion removed from Info.plist (will be injected by ci_post_clone.sh)
- ✅ Build #N (next number) appears in Xcode Cloud successfully

---

## Troubleshooting

### ITMS-90546 Appears Again

**Symptoms**: Build rejected with "Missing asset catalog"

**Fix**:
1. Verify all 10 icons exist:
   ```bash
   ls tibok/Resources/Assets.xcassets/AppIcon.appiconset/ | wc -l
   # Should output: 13 (10 PNGs + 2 Contents.json + 1 directory)
   ```

2. Verify Assets.xcassets configuration in project.yml:
   ```yaml
   sources:
     - path: tibok/Resources/Assets.xcassets
       type: file
       buildPhase: resources
   ```

3. Regenerate project:
   ```bash
   xcodegen generate --spec project.yml
   rm -rf tibok.xcodeproj  # Clean old project
   xcodegen generate --spec project.yml  # Regenerate
   ```

4. Verify asset catalog appears in .pbxproj:
   ```bash
   grep "folder.assetcatalog" tibok.xcodeproj/project.pbxproj
   # Should output a match
   ```

### XcodeGen Clears Entitlements

**Symptoms**: After running `xcodegen generate`, entitlements file is empty

**Why**: XcodeGen regenerates files from project.yml; entitlements aren't in project.yml (they're referenced by path)

**Fix**:
```bash
# After running xcodegen generate:
cat > tibok/Resources/tibok-dmg.entitlements <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.app-sandbox</key>
	<true/>
	<key>com.apple.security.files.user-selected.read-write</key>
	<true/>
	<key>com.apple.security.network.client</key>
	<true/>
</dict>
</plist>
EOF
```

### Build #N Never Increments

**Symptoms**: Same build number submitted repeatedly

**Why**: Xcode Cloud's Next Build Number might be disabled

**Fix**: In Xcode Cloud settings, ensure "Automatically increment next build number" is enabled

---

## GitHub Release Distribution (Direct Download)

For distributing DMG files outside the Mac App Store (e.g., GitHub releases), you must complete the full notarization workflow to avoid Gatekeeper warnings.

### Complete Notarization Workflow

**IMPORTANT**: Always run ALL steps in order. Skipping notarization will cause "malware" warnings on user machines.

```bash
# 1. Build and sign the app bundle
./scripts/build-release-dmg.sh F2PFRMGC9V <version>

# 2. Create DMG from signed app
./scripts/create-dmg.sh <version>

# 3. Notarize with Apple (THIS STEP IS CRITICAL - DO NOT SKIP)
xcrun notarytool submit .build/release/Tibok-<version>.dmg \
  --keychain-profile "TIBOK_NOTARIZATION" \
  --wait

# 4. Staple notarization ticket to DMG
xcrun stapler staple .build/release/Tibok-<version>.dmg

# 5. Verify notarization
xcrun stapler validate .build/release/Tibok-<version>.dmg

# 6. Upload to GitHub release
gh release upload v<version> .build/release/Tibok-<version>.dmg
```

### Why Each Step Matters

1. **Build & Sign**: Code signs app with Developer ID certificate (required for notarization)
2. **Create DMG**: Packages signed app into distributable disk image
3. **Notarize**: Apple scans for malware and approves the app (prevents Gatekeeper warnings)
4. **Staple**: Attaches notarization ticket to DMG (works offline)
5. **Verify**: Confirms notarization succeeded
6. **Upload**: Makes notarized DMG available for download

### What Happens If You Skip Notarization?

Users will see this error when trying to open the app:
```
"Apple could not verify 'tibok' is free of malware that may harm your Mac
or compromise your privacy."
```

The app will be blocked by macOS Gatekeeper and won't run. Users would need to:
- Right-click → Open (override Gatekeeper)
- Or go to System Settings → Privacy & Security → "Allow anyway"

This creates a terrible user experience. **Always complete the full notarization workflow.**

### Notarization Troubleshooting

**Check notarization history:**
```bash
xcrun notarytool history --keychain-profile "TIBOK_NOTARIZATION"
```

**View detailed logs if notarization fails:**
```bash
xcrun notarytool log <submission-id> --keychain-profile "TIBOK_NOTARIZATION"
```

**Common notarization failures:**
- **Not signed with Developer ID**: Must use Developer ID Application certificate (not Mac App Store cert)
- **Invalid entitlements**: Check `tibok/Resources/tibok-dmg.entitlements`
- **Missing hardened runtime**: Verify `--options runtime` in codesign command
- **Unsigned frameworks**: All embedded frameworks must be signed

**Verify app signature before notarizing:**
```bash
codesign --verify --deep --strict --verbose=2 .build/release/tibok.app
```

---

## Summary

The key to successful builds for tibok:

### For App Store Distribution (Xcode Cloud)

1. **Assets.xcassets in `sources` section** with `buildPhase: resources`
2. **Icon name consistency**: ASSETCATALOG_COMPILER_APPICON_NAME and CFBundleIconName both = "AppIcon"
3. **All 10 icon files** present in AppIcon.appiconset
4. **Sandbox entitlements** enabled with necessary permissions
5. **Dynamic build number injection** via ci_post_clone.sh
6. **Entitlements file restoration** after each XcodeGen run

### For Direct Distribution (GitHub Releases)

1. **Sign with Developer ID Application certificate**
2. **Create DMG** from signed app
3. **Notarize with Apple** (CRITICAL - prevents Gatekeeper warnings)
4. **Staple notarization ticket** to DMG
5. **Verify notarization** succeeded
6. **Upload to GitHub** release

**Never skip notarization for direct distribution.**

This configuration has been validated through v1.0.3 and beyond.

---

## References

- [Apple Asset Catalogs Documentation](https://developer.apple.com/documentation/xcode/managing-assets-with-asset-catalogs)
- [XcodeGen GitHub](https://github.com/yonaskolb/XcodeGen)
- [XcodeGen Project Spec](https://github.com/yonaskolb/XcodeGen/blob/master/Docs/ProjectSpec.md)
- [App Store Connect Help - ITMS-90546](https://developer.apple.com/documentation/xcode/managing-assets-with-asset-catalogs)

---

**Last Updated**: 2025-12-22 (tibok v1.0.2, Build #11)
**Status**: ✅ Verified Working
**Next Steps**: Use this configuration for all future App Store submissions
