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
    ├── keyboard-shortcuts.md    # Shortcut reference
    ├── git-integration.md       # Git version control
    ├── frontmatter.md           # Jekyll/Hugo metadata editor
    ├── plugins.md               # Plugin management
    └── webhooks.md              # HTTP webhook notifications
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

### Core Editing
- Markdown editing with NSTextView (AppKit integration)
- Live preview with syntax highlighting (WebKit-based)
- **Markdown formatting shortcuts**: Cmd+B (bold), Cmd+Shift+I (italic), Cmd+E (code), Cmd+Shift+X (strikethrough), Cmd+L (link)
- Slash commands (35+ commands) - headings, lists, tables, links, dates, formatting, etc.
- Emoji picker with :shortcode: syntax (e.g., :smile:, :heart:)
- Smart lists (auto-continue bullet/numbered lists)
- Auto-pairs (auto-close brackets, quotes, markdown syntax)
- Spell checking
- Syntax highlighting in editor

### Document Management
- Multiple open files with tab support (Cmd+1-9 to switch)
- Tab management (Cmd+W close, Cmd+Shift+T reopen, Cmd+Shift+] / [ navigate)
- File/folder workspace with sidebar
- Favorites system for quick access
- Recent files list
- Auto-save with manual save override
- Print support (⌘P)

### Markdown Features
- **Nested lists**: Up to 3 levels, 2-space indentation, mixed ordered/unordered
- Footnotes with bi-directional linking
- Table of Contents generation (`[[toc]]`)
- GitHub-style callouts (NOTE, TIP, WARNING, IMPORTANT, CAUTION)
- Definition lists
- Task lists / checkboxes
- Tables with pipe syntax
- Collapsible sections (`<details>`)
- Math/LaTeX rendering with bundled KaTeX ($inline$ and $$display$$)
- Horizontal rules
- Code blocks with syntax highlighting
- Images with drag & drop and paste support (auto-copy to assets folder)

### Git Integration
- Stage/unstage files
- Commit with message editor (Cmd+Shift+K)
- Push/pull
- Branch display
- Status tracking in sidebar

### Customization & Settings
- Dark/light mode with system preference support
- Font family and size customization
- Line height adjustment
- Preview font size and max width settings
- Code theme selection (atom-one-dark, github, monokai, vs, xcode, dracula)
- Frontmatter editor (⌘I) for Jekyll/Hugo metadata (YAML/TOML)
- Timezone settings for frontmatter dates
- Plugin system with enable/disable support
- Webhook system for HTTP notifications on events
- WordPress export settings

### Interface
- Command palette (⌘K) with grouped commands
- Find and replace (Cmd+F, Cmd+Option+F)
- Focus mode (Ctrl+⌘+.) - hides all UI for distraction-free writing
- Toggle preview (Cmd+\)
- Toggle sidebar (Cmd+0)
- Toggle inspector/frontmatter (Cmd+I)
- Translucent macOS sidebar styling
- Status bar with document stats, Git branch, shortcuts

### Planned (see planning/ folder)
- Cloud sync

## Notes for Claude

- This is a macOS-only app - no iOS/iPadOS support
- The editor uses NSTextView (AppKit) wrapped in SwiftUI for full text editing features
- Markdown preview uses WebKit (WKWebView)
- User preferences are stored with @AppStorage (UserDefaults)
- The app uses a document-based architecture but is not a true NSDocument app
