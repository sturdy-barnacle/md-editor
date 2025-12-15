# Tibok - Claude Code Guidelines

## Project Summary
Tibok is a native macOS markdown editor built with SwiftUI. It provides a clean, distraction-free writing experience with live preview, slash commands, and workspace support.

## Quick Reference

### Build & Test
```bash
./scripts/build-app.sh    # Build app bundle (REQUIRED for app icon)
open .build/debug/tibok.app  # Run the app
swift test                # Run tests
```

**IMPORTANT**: Always use `./scripts/build-app.sh` instead of just `swift build`. The build script:
- Compiles the Liquid Glass icon (macOS 15+ style)
- Creates the proper `.app` bundle structure
- Copies Info.plist and resources correctly

Running `swift build` alone will NOT include the app icon.

### Key Directories
- `tibok/` - Main app source code
- `tibokTests/` - Unit tests
- `user_docs/` - User-facing documentation
- `planning/` - Development planning documents

## Architecture

### Tech Stack
- Swift 5.9+ with SwiftUI
- AppKit integration via NSViewRepresentable (for NSTextView editor)
- macOS 14.0+ (Sonoma) minimum
- Swift Package Manager for dependencies

### Core Components
- `AppState` - Centralized app state (@EnvironmentObject)
- `MarkdownDocument` - Document model with content, metadata
- `SlashTextView` - Custom NSTextView with slash commands, drag/drop
- `PreviewView` - WebKit-based markdown rendering

### File Locations
| File | Purpose |
|------|---------|
| `tibokApp.swift` | App entry, menu commands |
| `ContentView.swift` | Main 3-pane layout |
| `Views/EditorView.swift` | Editor with slash commands |
| `Views/PreviewView.swift` | Markdown preview |
| `Views/SidebarView.swift` | File browser |
| `Models/AppState.swift` | Shared state |

## Development Guidelines

### Code Style
- Follow Swift standard naming conventions
- Use SwiftUI when possible, AppKit when necessary
- Keep views small and composable
- Use @AppStorage for user preferences

### When Making Changes
1. Read relevant existing code first
2. Follow established patterns in the codebase
3. Test changes build successfully
4. Update user documentation (see below)

## User Documentation Maintenance

**CRITICAL**: Always update user docs when changing features.

### Documentation Location
All user-facing documentation lives in `/user_docs`:
```
user_docs/
├── README.md                    # Documentation index
├── FAQ.md                       # Frequently asked questions
└── features/
    ├── slash-commands.md        # Slash command reference
    ├── image-handling.md        # Image drag/drop/paste
    ├── workspace.md             # File/folder management
    ├── preview.md               # Preview features
    ├── find-replace.md          # Find and replace
    └── keyboard-shortcuts.md    # Shortcut reference
```

### When to Update Docs

| Change Type | Update |
|-------------|--------|
| New feature | Create/update feature doc + FAQ if needed |
| New slash command | `features/slash-commands.md` |
| New shortcut | `features/keyboard-shortcuts.md` |
| Changed behavior | Update relevant feature doc |
| Bug fix | Update FAQ if addresses common issue |
| New setting | Update relevant doc + FAQ |

### Documentation Checklist
Before completing any feature work, verify:
- [ ] Feature behavior is documented
- [ ] Keyboard shortcuts are listed
- [ ] FAQ updated if feature has common questions
- [ ] README.md links to new docs if applicable

### Writing Style for Docs
- Write for end users (not developers)
- Use clear, simple language
- Include examples and use cases
- Add tables for reference info
- Include troubleshooting tips
- Show keyboard shortcuts

## Current Features

### Implemented
- Markdown editing with NSTextView
- Live preview with syntax highlighting
- Command palette (⌘K)
- Slash commands (35+ commands)
- Image drag & drop with assets folder
- Image paste from clipboard
- File/folder workspace support
- Multiple open files (tabs)
- Git integration (staging, commits, push/pull)
- Find and replace
- Auto-save
- Dark/light mode support
- Print support (⌘P)
- Math/LaTeX rendering (bundled KaTeX)

### Planned (see planning/ folder)
- Cloud sync
- Plugin system

## Notes for Claude

- This is a macOS-only app - no iOS/iPadOS support
- The editor uses NSTextView (AppKit) wrapped in SwiftUI for full text editing features
- Markdown preview uses WebKit (WKWebView)
- User preferences are stored with @AppStorage (UserDefaults)
- The app uses a document-based architecture but is not a true NSDocument app
