# tibok App Store Submission - Quick Reference Card

## Pre-Build Checklist (5 min)

- [ ] Update version in `Info.plist` if new release
- [ ] Verify all 10 icon files exist: `ls tibok/Resources/Assets.xcassets/AppIcon.appiconset/*.png | wc -l`
- [ ] Read commit diffs to verify no sensitive data leaked
- [ ] Code review: Check for obvious bugs or issues

## Build Process (1 command, wait 5-10 min)

### Step 1: Regenerate Project
```bash
cd /Users/kq/md-editor/tibok
xcodegen generate --spec project.yml
```

### Step 2: Restore Entitlements (if wiped)
```bash
# Verify entitlements aren't empty:
cat tibok/Resources/tibok-dmg.entitlements | grep com.apple.security

# If empty/missing, restore from template:
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

### Step 3: Commit and Push
```bash
git add -A
git commit -m "Feature/fix description"
git push origin apple-store-distro
```

**Important**: The `apple-store-distro` branch triggers Xcode Cloud builds for App Store submission. Do NOT push to `development` for App Store builds.

## Xcode Cloud Monitoring (5-10 min)

1. Visit: https://github.com/sturdy-barnacle/md-editor
2. Go to: "Xcode Cloud" tab
3. Wait for build to complete
4. Watch for: "Prepare Build for App Store Connect" **PASS** ✅

## Verification Checklist (1 min)

- [ ] Next Build Number auto-incremented
- [ ] "Prepare Build for App Store Connect" PASSED
- [ ] No ITMS errors in build log
- [ ] Build appears in App Store Connect

## If "Prepare Build for App Store Connect" Fails

### ITMS-90546 (Missing Asset Catalog)
```yaml
# In project.yml, verify:
sources:
  - path: tibok/Resources/Assets.xcassets
    type: file
    buildPhase: resources  # ← THIS MUST EXIST

# In .pbxproj, verify:
# grep "folder.assetcatalog" tibok.xcodeproj/project.pbxproj
# Should return a match
```
**Reference**: See ITMS-90546_FIX_DOCUMENTATION.md

### ITMS-90242 (Missing LSApplicationCategoryType)
```xml
<!-- In Info-AppStore.plist, must have: -->
<key>LSApplicationCategoryType</key>
<string>public.app-category.productivity</string>
```

### ITMS-90296 (Sandbox Not Enabled)
Restore entitlements file (see Step 2 above)

### Build Number Issues
```bash
# Verify ci_post_clone.sh exists and is executable:
ls -la ci_scripts/ci_post_clone.sh
# Should show: -rwxr-xr-x (executable bit set)
```

## Key Files (Don't Forget)

| File | Purpose |
|------|---------|
| `project.yml` | XcodeGen configuration - SINGLE SOURCE OF TRUTH |
| `tibok/Resources/Info-AppStore.plist` | Bundle metadata |
| `tibok/Resources/tibok-dmg.entitlements` | Sandbox permissions |
| `ci_scripts/ci_post_clone.sh` | Build number injection |
| `tibok/Resources/Assets.xcassets/` | Icons (all 10 required) |

## Common Mistakes

❌ Forgetting to restore entitlements after `xcodegen generate`
→ Solution: Always verify entitlements after XcodeGen

❌ Wrong icon name (ASSETCATALOG_COMPILER_APPICON_NAME vs CFBundleIconName mismatch)
→ Solution: Both must be "AppIcon"

❌ Assets.xcassets in `resources` section without buildPhase
→ Solution: Must be in `sources` section with `buildPhase: resources`

❌ Missing one of the 10 icon files
→ Solution: Check all sizes exist before building

❌ Forgetting to push to trigger Xcode Cloud
→ Solution: Always `git push origin apple-store-distro` after changes

## Documentation Reference

- **Full Guide**: `APP_STORE_BUILD_GUIDE.md`
- **Problem Deep Dive**: `ITMS-90546_FIX_DOCUMENTATION.md`
- **Complete Overview**: `v1.0.2_BUILD_SUMMARY.md`
- **This Quick Ref**: `APP_STORE_QUICK_REFERENCE.md` (you are here)

## Emergency Troubleshooting

### Project Won't Generate
```bash
# Check project.yml syntax:
cat project.yml | head -20

# Check for typos in paths:
ls tibok/Resources/Assets.xcassets/
ls tibok/Resources/tibok-dmg.entitlements
ls tibok/Resources/Info-AppStore.plist
```

### Build Fails with "Cannot find in includes"
```bash
# Verify Swift files path:
ls tibok/*.swift | wc -l
# Should be: 47
```

### Assets.car Not in Bundle
```bash
# Verify asset catalog config:
grep -A3 "Assets.xcassets" project.yml

# Verify it's in .pbxproj:
grep "folder.assetcatalog" tibok.xcodeproj/project.pbxproj
```

## Success Indicators

✅ Build #N created in Xcode Cloud
✅ "Prepare Build for App Store Connect" shows PASSED
✅ Build appears in App Store Connect dashboard
✅ No ITMS errors in validation

## Notes for Next Build

- **Version**: v1.0.2 (current - adjust for next release)
- **Team ID**: F2PFRMGC9V (hardcoded in project.yml)
- **Bundle ID**: app.tibok.editor (don't change)
- **Min OS**: 14.0 (Sonoma - adjust if needed)
- **Swift**: 5.9 (update in project.yml if changed)

---

**Quick Reference Created**: 2025-12-22
**For**: All future App Store submissions
**Status**: Ready to use
**Keep this open during builds** 📋
