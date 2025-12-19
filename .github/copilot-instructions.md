# Copilot Instructions for tibok

## Repository Summary

**tibok** is a native macOS markdown editor built with SwiftUI for Apple Silicon and Intel Macs. It provides a clean, distraction-free writing experience with live preview, slash commands, Git integration, and offline KaTeX math rendering. The app is designed for writers who love simplicity.

**Website**: https://tibok.app

## Repository Information

- **Size**: ~64MB (includes dependencies and KaTeX assets)
- **Lines of Code**: ~30,000 Swift lines
- **Project Type**: macOS-only application (no iOS/iPadOS support)
- **Languages**: Swift 5.9+
- **Framework**: SwiftUI with AppKit integration
- **Package Manager**: Swift Package Manager (SPM)
- **Minimum macOS**: 14.0 (Sonoma)
- **Build System**: Swift Package Manager + custom build script

## Build and Test Instructions

### ⚠️ CRITICAL: macOS-Only Project

This project **CANNOT be built on Linux or Windows**. It requires:
- macOS 14.0+ (Sonoma or later)
- Xcode 15+ installed
- JavaScriptCore framework (macOS-only)
- AppKit framework (macOS-only)

**If you are running on Linux/CI**: Do not attempt to build or test this project. The `swift build` command will fail with "no such module 'JavaScriptCore'" errors. This is expected and cannot be fixed - the project fundamentally requires macOS.

### Building the App

**ALWAYS use the build script, NOT `swift build` directly:**

```bash
cd tibok
./scripts/build-app.sh
```

**Why the build script is required:**
- Compiles the Liquid Glass icon (macOS 15+ style) from `tibok/Resources/IconLayers/icon.icon`
- Creates the proper `.app` bundle structure with Contents/MacOS and Contents/Resources
- Copies Info.plist with correct bundle configuration
- Copies resource bundles (tibok_tibok.bundle, Highlightr_Highlightr.bundle)
- Copies KaTeX assets for offline math rendering
- Copies user documentation for Help menu
- Creates PkgInfo file

**Build time**: ~30-60 seconds on first build, ~10-20 seconds on subsequent builds (depending on changes)

Running `swift build` alone will compile but NOT create a functional app bundle and will NOT include the app icon.

### Running the App

After building:
```bash
open .build/debug/tibok.app
```

The app will launch on your Mac. Test by creating or opening a markdown file.

### Running Tests

```bash
cd tibok
swift test
```

**Test files location**: `tibokTests/`
- DocumentTests.swift
- KeychainHelperTests.swift
- MarkdownRendererTests.swift

**Note**: Tests can also be run from Xcode using the test navigator (⌘6).

### Clean Build

If you encounter build issues:
```bash
cd tibok
rm -rf .build
./scripts/build-app.sh
```

## Project Layout and Architecture

### Directory Structure

```
md-editor/
├── .github/workflows/claude.yml    # Claude Code workflow
├── tibok/                          # Main project
│   ├── Package.swift               # Dependencies
│   ├── scripts/build-app.sh        # Build script (REQUIRED)
│   ├── tibok/                      # Source code
│   │   ├── tibokApp.swift          # Entry point
│   │   ├── ContentView.swift       # Main layout
│   │   ├── Models/                 # AppState, Document, Frontmatter
│   │   ├── Views/                  # EditorView, PreviewView, SidebarView, etc.
│   │   ├── Services/               # GitService, MarkdownRenderer, etc.
│   │   ├── Plugins/                # Plugin system
│   │   └── Resources/              # Info.plist, icons, KaTeX
│   ├── tibokTests/                 # Unit tests
│   ├── user_docs/                  # User documentation (UPDATE for features)
│   ├── CLAUDE.md                   # Dev guidelines
│   └── CHANGELOG.md                # Version history
└── README.md
```

### Core Architecture

**Tech Stack:**
- Swift 5.9+ with SwiftUI for UI
- AppKit integration via NSViewRepresentable (for NSTextView editor with full text editing features)
- WebKit (WKWebView) for markdown preview
- macOS 14.0+ (Sonoma) minimum target
- Swift Package Manager for dependencies

**Key Dependencies** (from Package.swift):
- `apple/swift-markdown` (0.3.0+) - Markdown parsing
- `raspu/Highlightr` (2.1.0+) - Syntax highlighting for code blocks (requires JavaScriptCore)

**State Management:**
- `AppState` - Centralized app state, shared via `@EnvironmentObject`
- `@AppStorage` for user preferences (UserDefaults)
- Not a true NSDocument app, but uses document-based architecture patterns

**Key Components:**
- `tibokApp.swift` - App entry point with WindowGroup and menu bar commands
- `AppState` - Manages current document, open files, workspace, Git state, plugins
- `MarkdownDocument` - Document model with content, file URL, modification tracking
- `SlashTextView` - Custom NSTextView subclass with slash commands and drag/drop support
- `PreviewView` - WebKit-based markdown rendering with KaTeX, syntax highlighting

## CI/CD and Validation

### GitHub Actions

**Workflow file**: `.github/workflows/claude.yml`

**Triggers**:
- Issue comments containing `@claude`
- PR comments containing `@claude`
- New issues with `@claude` in title or body
- PR reviews containing `@claude`

**Required Secret**: `CLAUDE_CODE_OAUTH_TOKEN` must be configured in repository Settings → Secrets and variables → Actions. The linter warning about this secret is **expected and can be ignored** - secrets are only available at runtime.

### Pre-Commit Checks

**No automated linting or formatting is configured.** Follow Swift standard naming conventions:
- Use camelCase for variables and functions
- Use PascalCase for types and protocols
- Use descriptive names

### Manual Validation Steps

Before completing any task:

1. **Build the app**: `./scripts/build-app.sh` (must succeed)
2. **Run tests**: `swift test` (all tests must pass)
3. **Launch the app**: `open .build/debug/tibok.app`
4. **Test your changes**: Actually use the app to verify behavior
5. **Check for regressions**: Test related features to ensure nothing broke

**For feature changes**: Always update user documentation in `user_docs/` (see "User Documentation Maintenance" below).

## Development Guidelines

### Code Style

- Follow Swift standard naming conventions
- Use SwiftUI when possible, AppKit only when necessary (e.g., NSTextView for rich text editing)
- Keep views small and composable
- Use `@AppStorage` for user preferences
- Don't add comments unless they match existing comment style or explain complex logic

### User Documentation Maintenance

**CRITICAL**: When changing features, ALWAYS update user documentation in `tibok/user_docs/`.

**Update mapping**:
- New feature → Create/update feature doc in `user_docs/features/` + FAQ
- New slash command → `features/slash-commands.md`
- New keyboard shortcut → `features/keyboard-shortcuts.md`
- Changed behavior → Update relevant feature doc
- Bug fix → Update FAQ if common issue

**Writing style**: End-user focused, clear language, include examples.

### Current Features

**Key features**: Markdown editor with NSTextView, live preview, 35+ slash commands, tabs, Git integration, image drag/drop, frontmatter editor, offline KaTeX, plugins, webhooks. See `CHANGELOG.md` for complete list.

## Common Issues and Workarounds

### Build Fails with "no such module 'JavaScriptCore'"

**Cause**: Running on Linux or attempting to build without macOS.

**Solution**: This project requires macOS. Cannot be built on Linux/Windows. If you're testing in CI, skip build steps or use macOS runners.

### App Icon Not Showing

**Cause**: Using `swift build` instead of `./scripts/build-app.sh`.

**Solution**: Always use `./scripts/build-app.sh` to build the app. The script compiles the icon using `actool`.

### Changes Not Reflected in Running App

**Cause**: Old app instance still running.

**Solution**: 
1. Quit the running tibok app (⌘Q)
2. Rebuild: `./scripts/build-app.sh`
3. Relaunch: `open .build/debug/tibok.app`

### Tests Fail to Run

**Cause**: Dependencies not resolved or stale build cache.

**Solution**:
```bash
rm -rf .build
swift test
```

## Important Files Reference

### Configuration Files

- `tibok/Package.swift` - Swift package manifest, dependencies, build settings
- `tibok/tibok/Resources/Info.plist` - App bundle configuration (bundle ID, version, file types)
- `tibok/tibok/Resources/tibok.entitlements` - App entitlements (if any)
- `.gitignore` - Excludes `.build/`, xcuserdata, .DS_Store, planning/, progress/

### Key Files

- `README.md`, `tibok/CLAUDE.md` (dev guidelines), `tibok/CHANGELOG.md`
- `tibok/scripts/build-app.sh` - **REQUIRED** build script
- `tibok/tibok/tibokApp.swift` - Entry point
- `tibok/tibok/Models/AppState.swift` - State management
- `tibok/tibok/Views/EditorView.swift` - Main editor

## Trust These Instructions

The information in this document has been validated by building and testing the project. If you encounter a discrepancy:

1. **First**, re-read these instructions carefully
2. **Then**, check if the repository has been updated since these instructions were written
3. **Only then**, explore the codebase to understand changes

**Do not waste time searching** for information that is already documented here. These instructions are designed to save you time and reduce errors.

## Quick Reference Commands

```bash
# Navigate to project
cd /path/to/md-editor/tibok

# Build app (REQUIRED - don't use swift build alone)
./scripts/build-app.sh

# Run app
open .build/debug/tibok.app

# Run tests
swift test

# Clean build
rm -rf .build && ./scripts/build-app.sh

# Check Swift version
swift --version  # Should be 5.9+

# View build output directory
ls -la .build/debug/
```

---

**Last Updated**: December 2024 (Beta v0.6)  
**Validated On**: macOS 14+ with Xcode 15+
