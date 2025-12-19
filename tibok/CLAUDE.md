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

### Model Recommendations

For cost optimization with Claude Code:

- **Haiku (Default)**: Routine edits, building, testing, file operations, code search
- **Sonnet**: Architecture decisions, large refactors, performance optimization, debugging
- **Opus**: Only for very complex problems blocking development

**Cost tip**: Using Haiku for routine work and Sonnet for complex tasks saves ~60-70% vs. Sonnet-only.

### Key Directories
- `tibok/` - Main app source code
  - `Services/` - Service layer (DocumentManager, WorkspaceService, etc.)
  - `Views/` - SwiftUI views
  - `Models/` - Data models and AppState
  - `Plugins/` - Plugin system
- `tibokTests/` - Unit tests
- `user_docs/` - User-facing documentation
- `FUTURE_FEATURES.md` - Planned features and design docs

## Architecture

### Tech Stack
- Swift 5.9+ with SwiftUI
- AppKit integration via NSViewRepresentable (for NSTextView editor)
- macOS 14.0+ (Sonoma) minimum
- Swift Package Manager for dependencies

### Core Components
- `AppState` - Main orchestrator (~1230 lines after Phase 2 refactoring, down from ~1606)
- **Service Layer** (Phase 2 refactoring):
  - `DocumentManager` - Document/tab management (265 lines, ObservableObject)
  - `WorkspaceService` - Workspace, recents, favorites (120 lines, ObservableObject)
  - `CommandService` - Command palette & slash commands (175 lines, ObservableObject)
  - `UIStateService` - Toast notifications (32 lines, ObservableObject)
  - `ExportService` - PDF/HTML/RTF/print exports (700+ lines, static)
  - `FileOperationsService` - File I/O operations (110 lines, static)
  - `GitService` - Git command execution (static)
  - `WordPressExporter` - WordPress REST API publishing (250 lines, singleton @MainActor)
- `MarkdownDocument` - Document model with content, metadata
- `SlashTextView` - Custom NSTextView with slash commands, drag/drop
- `PreviewView` - WebKit-based markdown rendering
- **Combine integration** - Service objectWillChange forwarding for SwiftUI reactivity

### File Locations
| File | Purpose |
|------|---------|
| `tibokApp.swift` | App entry, menu commands |
| `ContentView.swift` | Main 3-pane layout |
| `Views/EditorView.swift` | Editor with slash commands |
| `Views/PreviewView.swift` | Markdown preview |
| `Views/SidebarView.swift` | File browser |
| `Views/GitPanelView.swift` | Git status & operations |
| `Models/AppState.swift` | Main orchestrator, delegates to services |
| `Services/` | **Service layer** - DocumentManager, WorkspaceService, CommandService, UIStateService, ExportService, FileOperationsService, GitService, WordPressExporter |
| `Plugins/` | Plugin system and built-in plugins: PluginManager, TibokPlugin protocol, PluginManifest, PluginDiscovery, PluginContext, built-in plugins |
| `Plugins/Builtin/WordPressExportPlugin.swift` | WordPress publishing plugin |
| `Helpers/KeychainHelper.swift` | Secure credential storage |
| `Models/WordPressModels.swift` | WordPress API data structures |
| `Views/WordPressSettingsView.swift` | WordPress settings UI |

### Plugin Architecture

**Core Components:**
- `TibokPlugin` - Protocol that all plugins implement
- `PluginManager` - Singleton managing plugin lifecycle
- `PluginManifest` - Codable structure describing plugins via JSON
- `PluginDiscovery` - Scans folders and discovers plugin manifests
- `PluginContext` - API provided to plugins (access to editor, commands, state)
- `PluginStateManager` - Persists plugin enable/disable state

**Plugin Locations:**
- `~/Library/Application Support/tibok/Plugins/BuiltIn/` - Built-in plugins (compiled into app)
- `~/Library/Application Support/tibok/Plugins/ThirdParty/` - Community plugins (user-installed)

**Plugin Discovery:**
1. App initialization creates folders if needed
2. `PluginManager.initialize()` calls `PluginDiscovery.discoverAllManifests()`
3. Discovered plugins appear in Settings → Plugins
4. Users enable/disable plugins; state is persisted

**Plugin Lifecycle:**
1. Discovery - Manifests found in plugin folders
2. Registration - Plugin implements TibokPlugin protocol
3. Initialization - Plugin's `init()` called
4. Registration - Plugin's `register(with:)` called to register commands
5. Active - Plugin registered, commands available
6. Deactivation - Plugin's `deactivate()` called when disabled
7. Unload - Plugin removed from memory

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
    ├── plugins.md               # Plugin management for users
    ├── plugin-development.md    # Plugin development guide
    ├── plugin-template.md       # Plugin starter template
    ├── plugin-security.md       # Plugin security & best practices
    └── webhooks.md              # HTTP webhook notifications
```

**Plugin-related root files:**
- `PLUGIN_REGISTRY.md` - Central registry of community-created plugins

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
- File/folder workspace with sidebar and **nested folder expansion** (unlimited depth)
- **Smart workspace filtering** - Only shows folders containing markdown files, automatically hides node_modules, .git, images, etc.
- **Smart section management**: Recent/Favorites auto-collapse when workspace opens, Git auto-expands
- Favorites system for quick access (heart icon 💖)
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
- Commit with message editor (Cmd+Shift+K) with **auto-prefilled messages** based on staged files
- Push/pull
- **Branch management**: Create, switch, and delete branches from Git panel
- **Stash management**: Create, apply, pop, and delete stashes
- **Smart branch switching**: Options to stash or bring uncommitted changes when switching
- Status tracking in sidebar with **auto-refresh** on document save
- **Manual refresh button** in Git section heading
- Smooth commit modal (no flicker)

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

### WordPress Publishing
- **REST API v2 integration** - Direct publishing to WordPress sites (5.6+)
- **Application Password authentication** - Secure, revocable credentials stored in macOS Keychain
- **Command palette integration** (⌘⇧P) - "Publish to WordPress" command
- **Built-in plugin** - Enable/disable from Settings > Plugins
- **Frontmatter support** - Override defaults with document metadata:
  - title, categories, draft status, description (excerpt)
- **Settings > WordPress tab**:
  - Site URL and credentials (password in Keychain)
  - Default post status (draft/publish/pending/private)
  - Default categories and author
  - Test connection button
- **Browser integration** - Opens published post automatically
- **Webhook trigger** - Fires document.export event with format "wordpress"
- **Markdown to HTML** - Automatic conversion via MarkdownRenderer

### Interface
- **Sidebar toolbar** with icon-only buttons (Open Workspace, Open Document, New Document) with keyboard shortcut tooltips
- Command palette (⌘K) with grouped commands
- Find and replace (Cmd+F, Cmd+Option+F)
- Focus mode (Ctrl+⌘+.) - hides all UI for distraction-free writing
- Toggle preview (Cmd+\)
- Toggle sidebar (Cmd+0)
- Toggle inspector/frontmatter (Cmd+I)
- Translucent macOS sidebar styling
- Status bar with document stats, Git branch, shortcuts

### Planned (see FUTURE_FEATURES.md)
- Git branch management (create, delete, switch branches)
- Git UI relocation (considering bottom panel)
- Cloud sync

## Notes for Claude

- This is a macOS-only app - no iOS/iPadOS support
- The editor uses NSTextView (AppKit) wrapped in SwiftUI for full text editing features
- Markdown preview uses WebKit (WKWebView)
- User preferences are stored with @AppStorage (UserDefaults)
- The app uses a document-based architecture but is not a true NSDocument app
