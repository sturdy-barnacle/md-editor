# Tibok - App Store Release Information

## Current Version: 1.0.4

Last updated: 2025-12-30

---

## App Store Promotional Text
(170 character maximum)

**Native Markdown editor with git integration. Write, organize, and version control your docs—all in one elegant macOS app.**

---

## App Store Description

**Tibok** is a native macOS markdown editor designed for developers, writers, and anyone who values simplicity and power in their writing tools.

### Why Tibok?

**Native Performance**
Built in Swift for macOS, Tibok feels fast and responsive. No Electron bloat—just pure native macOS performance.

**Workspace Organization**
Manage entire folders of markdown files with a native file browser. Create, move, copy, rename, and organize your documents with drag-and-drop simplicity.

**Git Integration**
Version control built right in. Commit changes, switch branches, push to remote, and view commit history—all without leaving your editor. Visual diff viewer shows exactly what changed with syntax highlighting.

**Distraction-Free Writing**
Clean, focused interface lets you concentrate on your writing. Markdown preview updates in real-time as you type.

**Keyboard-First Design**
Comprehensive keyboard shortcuts for every action. Navigate, edit, and manage files without touching your mouse.

### Key Features

**Workspace Management**
- Browse and edit multiple markdown files
- Drag-and-drop file operations
- Multi-select for bulk actions
- Create folders and organize your content
- Native macOS file system integration

**Git Version Control**
- Commit and push directly from the app
- Branch creation and switching
- Visual commit history browser
- Syntax-highlighted diff viewer
- Stage and commit changes with one click

**Markdown Editing**
- Live preview as you type
- Syntax highlighting
- Native text editing experience
- Auto-save support

**Developer-Friendly**
- Built with Swift and SwiftUI
- Lightweight and fast
- Keyboard shortcuts for power users
- Clean, native macOS design

### Perfect For

- Developers documenting projects
- Writers managing collections of articles
- Students organizing notes
- Anyone who prefers plain text and version control

### Privacy First

Tibok runs entirely on your Mac. No accounts, no tracking. Your documents stay on your machine, under your control.

---

## App Store Keywords
(100 character maximum, comma-separated)

markdown,editor,git,version control,writing,developer,text editor,documentation,notes,macOS

---

## Changelog

### Version 1.0.4 (Current Release)

#### Critical Bug Fix

- **Git Repository Detection in Production Builds**: Fixed critical issue where production builds (DMG and App Store) failed to detect git repositories due to App Sandbox restrictions
  - Implemented security-scoped bookmark access for .git directories
  - Fixes "git repository not found" error in workspaces that previously worked
  - Sandbox-compliant solution using persistent bookmarks
  - Proper cleanup on workspace close and app termination
  - Technical: Uses `URL.startAccessingSecurityScopedResource()` with UserDefaults bookmark persistence

**Note**: This fix only affects production builds. Debug builds were unaffected as they have relaxed sandbox enforcement.

---

### Version 1.0.3

#### Workspace & File Management
- **Workspace Folder Operations**: Browse and manage entire folders of markdown files with native file browser
- **Drag & Drop File Operations**: Move and copy files between folders with intuitive drag-and-drop
- **Multi-Select Support**: Select multiple files for bulk operations (delete, move, etc.)
- **File Operations**: Create new files and folders, rename, move, copy, and delete with native dialogs
- **Workspace Monitoring**: Real-time file system monitoring detects external changes

#### Git Integration
- **Branch Management UI**: Create new branches, switch between branches, and view current branch status
- **Commit History Browser**: Browse commit history with author, date, message, and file statistics
- **Visual Diff Viewer**: Syntax-highlighted diff viewer shows line-by-line changes
- **Enhanced Git Panel**: Improved UI for staging, committing, and pushing changes
- **Git Status Indicators**: Real-time status updates showing modified, staged, and untracked files

#### Keyboard Shortcuts
- **Git Operations**: ⌘G (commit), ⌘⇧P (push), ⌘⇧B (branches), ⌘⇧H (history)
- **File Operations**: ⌘N (new file), ⌘⇧N (new folder), ⌘R (rename), ⌘⌫ (delete)
- **Navigation**: ⌘1 (editor), ⌘2 (preview), ⌘3 (git panel)
- **Complete keyboard-first workflow** for all major operations

#### User Experience
- **Native macOS Design**: Built entirely with SwiftUI for native look and feel
- **Performance Improvements**: Optimized file operations and git commands
- **Error Handling**: Better error messages and user feedback
- **App Sandbox Compliance**: Full Mac App Store sandboxing support

#### Bug Fixes (December 30, 2025)
- **Git Modal Flash Eliminated**: Migrated all git modals (commit, branch, diff, history) from SwiftUI sheets to NSPanel for instant, flash-free dismissal
- **Diff Preview Race Condition Fixed**: Implemented atomic state management to prevent diff previews from failing to load on first click
- **Untracked File Diff Button Hidden**: Removed misleading "View Changes" button from untracked files that would open empty modals
- **Enhanced Error Logging**: Added diagnostic logging to git operations for easier debugging

#### Developer Features
- **Swift Package Manager**: Full SPM support for dependencies
- **Code Signing**: Automatic signing for App Store distribution
- **Xcode Cloud**: CI/CD integration for automated builds
- **Modular Architecture**: Clean separation of concerns (Models, Views, Services, Extensions)

---

## App Store Metadata Checklist

When submitting to App Store, ensure you have:

- [ ] App icon (1024x1024px)
- [ ] Screenshots (macOS - minimum 3 required)
  - [ ] Workspace view showing file browser
  - [ ] Git integration (commit history or diff viewer)
  - [ ] Markdown editing with preview
  - [ ] Optional: Branch management UI
  - [ ] Optional: Keyboard shortcuts reference
- [ ] Privacy Policy URL (if collecting any data)
- [ ] Support URL
- [ ] Marketing URL (optional)
- [ ] Age rating (likely 4+)
- [ ] Category: Productivity or Developer Tools
- [ ] Pricing: Free or Paid (decide)
- [ ] Export compliance documentation
- [ ] Build uploaded via Xcode Cloud or Transporter

---

## Release Workflow

### App Store Distribution (via Xcode Cloud)

#### 1. Prepare Release
```bash
# Update version number in Info.plist
# Update this file (APP_STORE_RELEASE.md) with new changelog

# Commit version bump
git add tibok/Resources/Info.plist APP_STORE_RELEASE.md
git commit -m "Bump version to X.Y.Z"
git push origin main
```

#### 2. Trigger App Store Build
```bash
# Merge to apple-store-distro to trigger Xcode Cloud build
git checkout apple-store-distro
git pull origin apple-store-distro
git merge main
git push origin apple-store-distro
```

#### 3. Monitor Build
- Check App Store Connect → Xcode Cloud → Builds
- Wait for build to complete and upload to TestFlight

#### 4. TestFlight Testing
- Download from TestFlight
- Test all major features
- Verify version number and build number

#### 5. Submit for Review
- Go to App Store Connect → Tibok → App Store tab
- Add build from TestFlight
- Update "What's New" with changelog highlights
- Submit for review

---

### GitHub Release Distribution (Direct Download)

For distributing DMG files outside the Mac App Store (e.g., GitHub releases), you MUST complete the full notarization workflow to avoid Gatekeeper warnings.

#### Complete Notarization Workflow

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

#### Why Each Step Matters

1. **Build & Sign**: Signs app with Developer ID certificate (required for notarization)
2. **Create DMG**: Packages signed app into distributable disk image
3. **Notarize**: Apple scans for malware and approves the app (prevents Gatekeeper warnings)
4. **Staple**: Attaches notarization ticket to DMG (works offline)
5. **Verify**: Confirms notarization succeeded
6. **Upload**: Makes notarized DMG available for download

#### What Happens If You Skip Notarization?

Users will see this error when trying to open the app:
```
"Apple could not verify 'tibok' is free of malware that may harm your Mac
or compromise your privacy."
```

The app will be blocked by macOS Gatekeeper and won't run.

#### Troubleshooting Notarization

**Check notarization status:**
```bash
xcrun notarytool history --keychain-profile "TIBOK_NOTARIZATION"
```

**View detailed logs if notarization fails:**
```bash
xcrun notarytool log <submission-id> --keychain-profile "TIBOK_NOTARIZATION"
```

**Common issues:**
- App not signed with Developer ID certificate → Re-run step 1
- Invalid entitlements → Check tibok-dmg.entitlements
- Hardened runtime issues → Ensure --options runtime flag in codesign

---

## Version History

### 1.0.3 (2025-12-30)
- Initial App Store release
- Workspace management with drag & drop
- Complete git integration
- Keyboard-first workflow

---

## Notes for Future Releases

### Marketing Copy Updates
When updating promotional text or description:
- Keep promotional text under 170 characters
- Highlight 1-2 key differentiators
- Focus on benefits, not just features
- Test keywords in App Store search

### Changelog Guidelines
- Group related changes by category
- Lead with user-facing features
- Technical details go last
- Be specific and clear
- Use active voice

### Screenshot Ideas
- Capture at native macOS resolution
- Use light mode for consistency
- Show real content (sample markdown documents)
- Highlight unique features (git integration, workspace)
- Include captions explaining each screenshot

---

**Ready for App Store submission!**

Check App Store Connect for build status: https://appstoreconnect.apple.com
