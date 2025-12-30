# Changelog

All notable changes to tibok are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.3] - 2025-12-29

### Fixed
- **Undo/Redo Character Loss**: Fixed critical bug where entire undo steps were lost when typing fast then using undo/redo
  - Root cause: Syntax highlighting was disabling undo registration globally, creating race condition where user edits weren't registered in undo stack
  - Solution: Removed redundant `disableUndoRegistration()` / `enableUndoRegistration()` calls; added safety check to prevent highlighting during undo/redo operations
  - Impact: Undo/redo now works reliably without losing any characters

### Improved
- **Undo Granularity**: Enhanced undo behavior to break typing into reasonable chunks
  - Added intelligent undo grouping based on 1-second typing pauses
  - Users can now undo text in smaller, more manageable segments instead of entire typing sessions
  - Improves editor UX by providing more predictable and useful undo/redo behavior

## [1.0.2] - 2025-12-22

### Added
- EdDSA (Ed25519) signature verification for Sparkle auto-updates
- Comprehensive developer documentation for release process
- `.gitignore` for security best practices
- **App Store Build Documentation** (5 comprehensive guides, 1,959 lines)
  - `APP_STORE_BUILD_GUIDE.md` - Complete reference guide for App Store submissions
  - `APP_STORE_QUICK_REFERENCE.md` - One-page checklist for every build
  - `ITMS-90546_FIX_DOCUMENTATION.md` - Technical deep dive into asset catalog fix
  - `v1.0.2_BUILD_SUMMARY.md` - Build pipeline overview and timeline
  - `APP_STORE_DOCUMENTATION_INDEX.md` - Navigation guide and issue resolution map

### Fixed
- **Keyboard Input Routing**: Fixed critical issue where keyboard input was routed to other applications instead of the editor
  - Root cause: App wasn't properly registered as foreground application
  - Solution: Proper macOS app bundle registration with NSApplication activation policy
  - Impact: Users can now type in the editor without text appearing in other apps

- **WordPress Selection Revert**: Fixed bug where WordPress selection automatically reverted to Jekyll
  - Root cause: `detectSSGType()` was called after user-initiated conversion, overriding explicit choice
  - Solution: Added `autoDetectType` parameter to prevent auto-detection from overriding user selection
  - Impact: Users can reliably convert and maintain their chosen static site generator

- **ITMS-90546 - Missing Asset Catalog**: Fixed App Store validation error preventing build submission
  - Root cause: Assets.xcassets not compiled into Assets.car during Xcode build
  - Solution: Moved asset catalog to sources section with explicit `buildPhase: resources` in XcodeGen configuration
  - Impact: Build #11 successfully passed App Store Connect validation

### Security
- Implemented code signing with Developer ID Application certificate
- Added Apple notarization for Gatekeeper approval
- Set up EdDSA signature verification for safe auto-updates
- Secured release process with comprehensive documentation

### Changed
- Build and release process now requires code signing (see [DEVELOPMENT.md](DEVELOPMENT.md))
- Updated Info.plist with proper version tracking

## [1.0.1] - 2025-12-19

### Fixed
- Previous bug fixes and improvements

### Security
- Code-signed releases with Developer ID Application certificate
- Apple notarization applied

## [1.0.0] - 2025-12-19

### Added
- Initial public release of tibok markdown editor
- Clean, distraction-free markdown editor with live preview
- 35+ slash commands for markdown formatting and structure
- Integrated Git workflow (stage, commit, push, pull, branch management)
- Direct WordPress publishing support
- Plugin system for extensibility
- Math/LaTeX rendering with bundled KaTeX
- Workspace and file management with smart filtering
- Dark/light mode with system preference support
- Customizable editor fonts, line height, and preview width
- Keyboard shortcuts for all major functions
- Tab-based multi-document editing
- Frontmatter inspector for Jekyll/Hugo metadata
- Image drag-and-drop support
- Find and replace functionality
- Webhooks for HTTP notifications
- Session persistence with automatic state restoration

### Requirements
- macOS 14.0 (Sonoma) or later
- Apple Silicon (ARM64) processor

---

## Release Process

### For Developers

See [DEVELOPMENT.md](DEVELOPMENT.md) for detailed instructions on:
- Building code-signed releases
- Creating notarized DMG files
- Setting up and using EdDSA signatures for Sparkle updates
- Managing keys and certificates
- Troubleshooting common issues

### For Users

- Automatic updates via Sparkle
- Cryptographically verified downloads (EdDSA signatures)
- Code-signed and notarized releases (no security warnings)
- Direct download from [GitHub Releases](https://github.com/sturdy-barnacle/md-editor/releases)

## Versioning

tibok follows [Semantic Versioning](https://semver.org/):
- **MAJOR** version for incompatible API changes
- **MINOR** version for backwards-compatible functionality
- **PATCH** version for backwards-compatible bug fixes

All releases from v1.0.0 onwards are:
- ✓ Code-signed with Developer ID Application certificate
- ✓ Notarized by Apple
- ✓ EdDSA-signed for Sparkle verification
