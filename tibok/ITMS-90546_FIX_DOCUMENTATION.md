# ITMS-90546 Fix Documentation

**Issue**: Missing Asset Catalog (Build #10 Failure)
**Solution**: XcodeGen configuration for asset catalog compilation
**Status**: ✅ RESOLVED in Build #11
**Project**: tibok v1.0.2
**Date**: 2025-12-22

---

## Executive Summary

ITMS-90546 was caused by Assets.xcassets not being compiled into Assets.car during the Xcode build. The root cause was incorrect XcodeGen configuration. Two fix attempts were made:

1. **Attempt 1 (Failed)**: Changed asset catalog type in `resources` section
2. **Attempt 2 (Success)**: Moved asset catalog to `sources` section with explicit build phase

**Key Insight**: XcodeGen must be explicitly told which build phase should contain the asset catalog. Simply changing the file type was insufficient.

---

## Problem Statement

### Error Message

```
Error ITMS-90546: Missing asset catalog - Your app is missing the
asset catalog file in "app.tibok.editor". For details, visit:
https://developer.apple.com/documentation/xcode/managing-assets-with-asset-catalogs.
```

### Build Context

- Xcode Cloud: Build #10 (v1.0.2)
- Previous error (ITMS-90546 from Build #9) was supposedly fixed
- Build #10 failed at "Prepare Build for App Store Connect" validation step
- Error reported via email from Apple: "ITMS-90546: Missing asset catalog"

### Timeline

- **Build #9**: CFBundleVersion mismatch fixed via ci_post_clone.sh, progressed to new error
- **Build #10**: Attempted fix with `type: file` in resources section → FAILED
- **Build #11**: Applied alternative fix with sources section + buildPhase → SUCCEEDED ✅

---

## Root Cause Analysis

### The Real Problem

App Store expects compiled asset catalog (`Assets.car`) in the app bundle:
```
app.tibok.editor.app/Contents/Resources/Assets.car
```

When Xcode builds, it runs `actool` (asset catalog compiler) which compiles:
```
Assets.xcassets → Assets.car
```

**But this wasn't happening.** The app bundle had no Assets.car file.

### Why Asset Catalog Wasn't Being Compiled

Assets.xcassets is a **special Xcode resource type** that requires:

1. **Recognition**: Build system must identify it as `.assetcatalog` type
2. **Compilation**: Must be added to build phase with special handling
3. **Output**: Must produce `Assets.car` in final bundle

When configured incorrectly, the asset catalog was treated as a **regular folder** instead of a **compilable resource**, so:
- `actool` was never invoked
- No `Assets.car` was generated
- App bundle was missing the required asset catalog file
- App Store validation failed

---

## Failed Attempt #1: Type Change in Resources Section

### Configuration Applied

**File**: `project.yml` (lines 31-37)

```yaml
resources:
  - path: tibok/Resources/Assets.xcassets
    type: folder    # ← Original: folder
    # Changed to:
    type: file      # ← Attempt 1: Simple type change
  - path: tibok/Resources/AppIcon.icns
    type: file
  - path: tibok/Resources/katex
    type: folder
```

### What Was Expected

Based on initial research, changing from `folder` to `file` should:
1. Tell XcodeGen to treat it as a compilable resource
2. Have XcodeGen add it to Copy Bundle Resources build phase
3. Allow Xcode to invoke `actool` during compilation

### What Actually Happened

❌ Asset catalog was still not being compiled

**Investigation Results**:

Generated .pbxproj contained:
```
ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
```

But NO reference to Assets.xcassets in build phases:
```bash
$ grep "Assets.xcassets" tibok.xcodeproj/project.pbxproj
# Empty result - no references found
```

**Why It Failed**:

`type: file` in the `resources` section told XcodeGen to treat it as a file, but without explicit build phase assignment, XcodeGen didn't add it to any actual build phase. The setting was present but the asset catalog wasn't included in the Xcode project's build configuration.

### Key Learning

Simply changing the type is not sufficient for XcodeGen. The asset catalog needs explicit instructions about which build phase it should be part of.

---

## Successful Attempt #2: Sources Section with Build Phase

### Configuration Applied

**File**: `project.yml` (lines 24-38)

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
    buildPhase: resources  # ← THE KEY FIX
resources:
  - path: tibok/Resources/AppIcon.icns
    type: file
  - path: tibok/Resources/katex
    type: folder
```

### Why This Works

1. **Moved to `sources` section**: Signals that this is a special source that needs build phase handling
2. **Added `buildPhase: resources`**: Explicitly tells XcodeGen to add it to the "Copy Bundle Resources" build phase
3. **Type remains `file`**: Ensures it's treated as a compilable resource (not just copied)

### Verification

After regenerating Xcode project, the .pbxproj now contains:

```
E8CBC6EBE9EE37E4E032D61B /* Assets.xcassets */ = {
    isa = PBXFileReference;
    lastKnownFileType = folder.assetcatalog;  # ← CORRECT TYPE
    path = Assets.xcassets;
    sourceTree = "<group>";
};

4023395F79A02BA2CCB8B90F /* Assets.xcassets in Resources */ = {
    isa = PBXBuildFile;
    fileRef = E8CBC6EBE9EE37E4E032D61B;
};
```

**Key differences**:
- `lastKnownFileType = folder.assetcatalog` ← Xcode recognizes it as asset catalog
- Entry in "Assets in Resources" build phase ← Will be processed by actool

### Build Results

✅ Build #11 succeeded
- Xcode Cloud completed "Prepare Build for App Store Connect" step
- No ITMS-90546 error
- Build accepted by App Store Connect

---

## What Makes This Different

### Comparison: Failed vs. Successful Approach

| Aspect | Failed (Attempt 1) | Successful (Attempt 2) |
|--------|-------------------|----------------------|
| **Location** | `resources:` section | `sources:` section |
| **Build Phase** | Implicit/None | Explicit `buildPhase: resources` |
| **Type** | `file` | `file` |
| **XcodeGen Output** | No .pbxproj entry | `lastKnownFileType = folder.assetcatalog` |
| **Result** | Asset catalog ignored | Asset catalog compiled → Assets.car |

### Why Sources Section + Build Phase Works

The `sources` section in XcodeGen is designed for resources that need build phase processing:
- Swift source files (included in Compile Sources)
- Asset catalogs (included in specified build phase)
- Other compilable/processed resources

By moving Assets.xcassets to `sources` with explicit `buildPhase: resources`, we're telling XcodeGen:
> "This is a source-like resource that should be processed and included in the 'Copy Bundle Resources' build phase"

This ensures:
1. XcodeGen recognizes the special type (folder.assetcatalog)
2. Asset catalog is added to proper build phase
3. Xcode invokes `actool` during compilation
4. Assets.car is generated and included in bundle

---

## Critical Details That Matter

### Icon Name Consistency

During this fix, icon name consistency was also corrected:

**Before**:
```yaml
# project.yml
ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon

# Info.plist
CFBundleIconName: icon  # ❌ MISMATCH
```

**After**:
```yaml
# project.yml
ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon

# Info.plist
CFBundleIconName: AppIcon  # ✅ MATCH
```

While not the direct cause of ITMS-90546, this consistency is important for proper icon resolution.

### XcodeGen's Entitlements Behavior

**Important Gotcha**: When running `xcodegen generate`, the entitlements file can be cleared:

```bash
$ xcodegen generate --spec project.yml
# tibok/Resources/tibok-dmg.entitlements now empty/minimized
```

**Why**: XcodeGen doesn't manage entitlements content (it's referenced by path in project.yml, not defined in project.yml). If the template file gets overwritten, you must manually restore it:

```bash
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

**Process for Future Builds**:
1. Edit project.yml as needed
2. Run `xcodegen generate`
3. Verify entitlements file is intact
4. Restore if necessary

---

## Asset Catalog Structure Verification

The asset catalog structure itself was correct throughout:

```
tibok/Resources/Assets.xcassets/
├── Contents.json  # ✅ Present
└── AppIcon.appiconset/
    ├── Contents.json  # ✅ Present
    ├── icon_16x16.png
    ├── icon_16x16@2x.png
    ├── icon_32x32.png
    ├── icon_32x32@2x.png
    ├── icon_128x128.png
    ├── icon_128x128@2x.png
    ├── icon_256x256.png
    ├── icon_512x512.png
    ├── icon-iOS-Default-512x512@1x.png
    └── icon-iOS-Default-1024x1024@1x.png  # ✅ All 10 sizes present
```

The structure wasn't the issue. The issue was entirely in how XcodeGen was **configuring** the asset catalog in the Xcode project.

---

## Lessons Learned

### For XcodeGen Configuration

1. **Asset catalogs require explicit build phase assignment**
   - Simply changing `type` is insufficient
   - Must use `buildPhase: resources` in sources section

2. **Sources section is for compilable/processed resources**
   - Swift source files
   - Asset catalogs
   - Other resources requiring build system processing

3. **Resources section is for static files**
   - Plain files to be copied (AppIcon.icns)
   - Directories to be bundled (katex)
   - No special processing needed

4. **Always verify generated .pbxproj**
   - Check for `folder.assetcatalog` type
   - Verify build phase includes the asset catalog
   - Don't assume the configuration is correct

### For App Store Builds

1. **ITMS-90546 = Asset catalog compilation failure**
   - Check XcodeGen configuration (not asset catalog structure)
   - Verify asset catalog appears in .pbxproj with correct type
   - Look at build phases in generated project

2. **Configuration changes require project regeneration**
   - Edit project.yml
   - Run `xcodegen generate`
   - Verify and restore sensitive files
   - Commit and push

3. **Icon consistency matters**
   - ASSETCATALOG_COMPILER_APPICON_NAME in project.yml
   - CFBundleIconName in Info.plist
   - Both should match and reference the asset catalog set

---

## Testing This Fix

The fix was verified through:

1. **Xcode Project Inspection**:
   ```bash
   grep "folder.assetcatalog" tibok.xcodeproj/project.pbxproj
   # Confirmed: lastKnownFileType = folder.assetcatalog
   ```

2. **Build Phase Verification**:
   - Asset catalog added to "Copy Bundle Resources" phase
   - No build errors reported
   - Xcode successfully archived

3. **App Store Validation**:
   - Build #11 submitted successfully
   - Passed "Prepare Build for App Store Connect" step
   - No ITMS-90546 error
   - Build accepted by App Store Connect

---

## Commits Related to This Fix

### Attempt 1 (Failed)
```
Commit: 0f29b09
Message: "Fix ITMS-90546: Configure Assets.xcassets as compilable asset catalog"
Changes:
  - project.yml: type: folder → type: file
  - Info.plist: CFBundleIconName: icon → AppIcon

Result: Build #10 still failed with ITMS-90546
```

### Attempt 2 (Success)
```
Commit: 7c7d2d4
Message: "Fix ITMS-90546: Move Assets.xcassets to sources with explicit build phase"
Changes:
  - project.yml: Moved Assets.xcassets from resources to sources
  - project.yml: Added buildPhase: resources to asset catalog entry

Result: Build #11 succeeded ✅
```

---

## Future Reference

If ITMS-90546 appears again in future versions:

1. **First check**: Does project.yml have this configuration?
   ```yaml
   sources:
     - path: tibok/Resources/Assets.xcassets
       type: file
       buildPhase: resources
   ```

2. **Second check**: Does generated .pbxproj contain?
   ```
   lastKnownFileType = folder.assetcatalog
   ```

3. **Third check**: Are all 10 icon files present?
   ```bash
   ls tibok/Resources/Assets.xcassets/AppIcon.appiconset/*.png | wc -l
   # Should be: 10
   ```

4. **If still failing**: Try the alternatives documented in APP_STORE_BUILD_GUIDE.md

---

## References

- [Apple: Managing Assets with Asset Catalogs](https://developer.apple.com/documentation/xcode/managing-assets-with-asset-catalogs)
- [XcodeGen GitHub: Project Spec](https://github.com/yonaskolb/XcodeGen/blob/master/Docs/ProjectSpec.md)
- [XcodeGen: Sources Configuration](https://github.com/yonaskolb/XcodeGen/blob/master/Docs/ProjectSpec.md#sources)
- [Xcode Build Phases](https://developer.apple.com/documentation/xcode/organizing-and-editing-your-sources)

---

**Documentation Completed**: 2025-12-22
**For**: tibok v1.0.2
**Status**: Reference for all future App Store submissions
