# Technical Architecture: tibok

## Overview

**tibok** is a native macOS markdown editor built with SwiftUI targeting Apple Silicon. The app emphasizes simplicity, local-first storage, and seamless integrations for publishing workflows.

- **Website:** tibok.app
- **Repository:** github.com/sturdy-barnacle/md-editor

---

## Technology Stack

| Layer | Technology |
|-------|------------|
| UI Framework | SwiftUI |
| Language | Swift 5.9+ |
| Minimum Target | macOS 14 (Sonoma) |
| Architecture | MVVM with Observable |
| Storage | Local filesystem + Core Data (metadata) |
| Networking | URLSession + async/await |

---

## Core Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        App Layer                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Editor    │  │   Preview   │  │   File Browser      │  │
│  │   View      │  │   View      │  │   Sidebar           │  │
│  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘  │
└─────────┼────────────────┼────────────────────┼─────────────┘
          │                │                    │
┌─────────▼────────────────▼────────────────────▼─────────────┐
│                     ViewModel Layer                         │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              DocumentViewModel                       │    │
│  │  • Document state    • Undo/redo stack              │    │
│  │  • Parse markdown    • Sync status                  │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────┬───────────────────────────────┘
                              │
┌─────────────────────────────▼───────────────────────────────┐
│                      Service Layer                          │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌──────────┐  │
│  │  Storage   │ │    Git     │ │   Export   │ │    AI    │  │
│  │  Service   │ │  Service   │ │  Service   │ │ Service  │  │
│  └────────────┘ └────────────┘ └────────────┘ └──────────┘  │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐               │
│  │   Cloud    │ │  Webhook   │ │  Clipboard │               │
│  │   Sync     │ │  Service   │ │  Service   │               │
│  └────────────┘ └────────────┘ └────────────┘               │
└─────────────────────────────────────────────────────────────┘
```

---

## Module Breakdown

### 1. Editor Module

**EditorView.swift**
- NSTextView wrapped in NSViewRepresentable for performance
- Syntax highlighting using NSAttributedString
- Line numbers gutter
- Vim keybindings (optional)

**Key features:**
- Real-time markdown parsing
- Custom keyboard shortcuts
- Drag-and-drop image support
- Find/replace with regex

### 2. Preview Module

**PreviewView.swift**
- WKWebView for rendered HTML preview
- Split view (horizontal/vertical) or separate window
- Synchronized scrolling with editor
- Custom CSS themes

**Rendering pipeline:**
```
Markdown Text → Parser (swift-markdown) → AST → HTML Generator → WKWebView
```

### 3. Storage Module

**LocalStorageService.swift**
- File system access via FileManager
- Security-scoped bookmarks for folder access
- Auto-save with debouncing (500ms)
- File watching via DispatchSource

**DocumentMetadata (Core Data):**
```swift
@Entity
class DocumentMetadata {
    var id: UUID
    var filePath: String
    var lastModified: Date
    var wordCount: Int
    var tags: [String]
    var syncStatus: SyncStatus
}
```

### 4. Git Integration

**GitService.swift**
- libgit2 via SwiftGit2 wrapper
- Clone, pull, push, commit operations
- Branch management
- Credential storage in Keychain

**Workflows:**
- Open repo as workspace
- Commit on save (optional)
- Push to remote
- Jekyll blog deployment via PR

### 5. Cloud Sync

**CloudSyncService.swift**
- iCloud Drive via FileManager.ubiquityContainer
- Conflict resolution (last-write-wins or prompt)
- Sync status indicators

**Sync states:** `local` | `syncing` | `synced` | `conflict`

### 6. Export Module

**ExportService.swift**

| Format | Implementation |
|--------|----------------|
| PDF | WKWebView.createPDF() or PDFKit |
| HTML | Template + rendered content |
| .md | Raw file copy with frontmatter |

**Jekyll Export:**
- Frontmatter injection (title, date, categories)
- Asset copying to Jekyll assets folder
- PR creation via GitHub API

### 7. AI Integration

**AIService.swift**
- Multi-provider AI support via custom URLSession implementation
- Streaming responses for real-time suggestions
- Supported providers:
  - **Claude** (Anthropic) - API v2024-06-01, Claude 3.5 Sonnet/Opus/Haiku
  - **OpenAI** - GPT-4o, GPT-4o-mini, GPT-4 Turbo, GPT-3.5 Turbo
  - **Gemini** (Google) - Gemini 1.5 Pro/Flash, API v1/v1beta
  - **Grok** (xAI) - Grok-2, Grok-2-mini
  - **Mistral** - Pixtral Large, Mistral Large/Medium/Small
  - **Ollama** - Local models (Llama, Mistral, Mixtral, etc.)

**Features:**
- Writing suggestions (grammar, style, clarity)
- Text completion
- Summarization
- Translation
- Custom prompts
- Quick actions (Improve, Continue, Summarize)

**Implementation:**
```swift
protocol AIProvider {
    func streamResponse(
        config: AIRequestConfig,
        model: String,
        onChunk: @escaping (String) -> Void,
        onComplete: @escaping (Result<Void, AIError>) -> Void
    ) -> Task<Void, Never>
}
```

### 8. Suggestions & Quick Actions

**SuggestionEngine.swift**
- Command palette (⌘K)
- Slash commands (/table, /code, /link)
- Autocomplete for:
  - Links (recent files, headings)
  - Emoji shortcodes
  - @mentions (from git config)

**QuickAction types:**
```swift
enum QuickAction {
    case insertSnippet(String)
    case formatSelection(FormatType)
    case exportAs(ExportFormat)
    case gitCommit
    case aiSuggest(SuggestionType)
    case webhook(WebhookConfig)
}
```

### 9. Clipboard & Media

**ClipboardService.swift**
- Image paste → save to document folder → insert markdown link
- Screenshot capture via screencapture CLI
- Drag-and-drop from Finder
- Image compression options

**Storage pattern:**
```
document-folder/
├── my-post.md
└── assets/
    ├── screenshot-2024-01-15.png
    └── pasted-image-001.png
```

### 10. Webhook Integration

**WebhookService.swift**
- Custom HTTP endpoints
- Trigger on: save, export, publish
- Configurable payload templates
- Authentication (Bearer, API key)

```swift
struct WebhookConfig: Codable {
    var name: String
    var url: URL
    var method: HTTPMethod
    var trigger: WebhookTrigger
    var headers: [String: String]
    var bodyTemplate: String  // Supports {{title}}, {{content}}, etc.
}
```

---

## Data Flow

### Document Editing Flow
```
User Input → EditorView → DocumentViewModel → StorageService → File System
                ↓                                    ↓
           PreviewView                        CloudSyncService
                ↓                                    ↓
           WKWebView                            iCloud Drive
```

### Jekyll Publish Flow
```
Export Action → ExportService → GitService → Create Branch
                     ↓              ↓
              Generate HTML    Commit Files
                                   ↓
                            GitHub API → Create PR
                                   ↓
                            Webhook (optional)
```

---

## File Structure

### Current Implementation (MVP)

```
tibok/
├── tibok.xcodeproj/             # Xcode project file
├── tibok/
│   ├── tibokApp.swift           # @main app entry, menu commands, URL handling
│   ├── ContentView.swift        # Main layout with HSplitView
│   ├── Models/
│   │   ├── Document.swift       # Document struct (content, metadata, stats)
│   │   └── AppState.swift       # Central state, file ops, auto-save
│   ├── Views/
│   │   ├── SidebarView.swift    # File sidebar with recent files
│   │   ├── EditorView.swift     # NSTextView with syntax highlighting
│   │   ├── PreviewView.swift    # WKWebView markdown preview
│   │   ├── StatusBarView.swift  # Word count, save status
│   │   └── SettingsView.swift   # Preferences window
│   ├── Services/
│   │   ├── MarkdownRenderer.swift   # Regex-based markdown → HTML
│   │   └── SyntaxHighlighter.swift  # NSAttributedString highlighting
│   └── Resources/
│       ├── Info.plist           # Bundle config, document types
│       └── tibok.entitlements   # App sandbox permissions
└── tibokTests/
    └── DocumentTests.swift      # Document model unit tests
```

### Planned Structure (v1.0)

```
tibok/
├── App/
│   ├── tibokApp.swift
│   └── AppDelegate.swift
├── Features/
│   ├── Editor/
│   │   ├── EditorView.swift
│   │   ├── EditorViewModel.swift
│   │   ├── SyntaxHighlighter.swift
│   │   └── TextStorage.swift
│   ├── Preview/
│   │   ├── PreviewView.swift
│   │   └── PreviewTheme.swift
│   ├── Sidebar/
│   │   ├── FileTreeView.swift
│   │   └── FileTreeViewModel.swift
│   └── QuickActions/
│       ├── CommandPalette.swift
│       └── SlashCommands.swift
├── Services/
│   ├── Storage/
│   │   ├── LocalStorageService.swift
│   │   └── CloudSyncService.swift
│   ├── Git/
│   │   └── GitService.swift
│   ├── Export/
│   │   ├── ExportService.swift
│   │   ├── PDFExporter.swift
│   │   └── HTMLExporter.swift
│   ├── AI/
│   │   ├── AIService.swift
│   │   └── ClaudeProvider.swift
│   ├── Clipboard/
│   │   └── ClipboardService.swift
│   └── Webhook/
│       └── WebhookService.swift
├── Models/
│   ├── Document.swift
│   ├── Workspace.swift
│   └── Preferences.swift
├── Utilities/
│   ├── MarkdownParser.swift
│   └── KeychainHelper.swift
└── Resources/
    ├── Assets.xcassets
    └── preview-themes/
```

---

## Dependencies

| Package | Purpose |
|---------|---------|
| swift-markdown | Apple's markdown parser |
| SwiftGit2 | Git operations via libgit2 |
| KeychainAccess | Secure credential storage |
| Highlightr | Code syntax highlighting |

---

## Security Considerations

- **Keychain**: Store Git credentials, API keys, webhook secrets
- **App Sandbox**: Enabled with file access entitlements
- **Hardened Runtime**: Required for notarization
- **Security-scoped bookmarks**: Persist folder access permissions

---

## Performance Targets

| Metric | Target |
|--------|--------|
| App launch | < 500ms |
| File open (1MB) | < 100ms |
| Preview render | < 50ms |
| Typing latency | < 16ms |
| Memory (idle) | < 100MB |

---

## Plugin System

The plugin system enables extensibility for exporters, themes, AI providers, and custom actions.

### Plugin Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Plugin Host                            │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              PluginManager                           │    │
│  │  • Load/unload plugins    • Sandbox enforcement     │    │
│  │  • Version compatibility  • Lifecycle management    │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────┬───────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│   Exporter    │   │    Theme      │   │  AI Provider  │
│   Plugins     │   │   Plugins     │   │   Plugins     │
├───────────────┤   ├───────────────┤   ├───────────────┤
│ • Hugo        │   │ • Nord        │   │ • OpenAI      │
│ • Notion      │   │ • Dracula     │   │ • Ollama      │
│ • Ghost       │   │ • Custom CSS  │   │ • Local LLM   │
└───────────────┘   └───────────────┘   └───────────────┘
```

### Plugin Types

#### 1. Exporter Plugins
Convert markdown to external formats/platforms.

```swift
protocol ExporterPlugin: Plugin {
    var supportedFormats: [ExportFormat] { get }
    func export(document: Document, options: ExportOptions) async throws -> ExportResult
}
```

#### 2. Theme Plugins
Custom preview and editor themes.

```swift
protocol ThemePlugin: Plugin {
    var previewCSS: String { get }
    var editorColors: EditorColorScheme { get }
    var syntaxHighlighting: SyntaxTheme { get }
}
```

#### 3. AI Provider Plugins
Alternative AI backends.

```swift
protocol AIProviderPlugin: Plugin {
    func complete(prompt: String, context: String) async throws -> AsyncStream<String>
    func suggest(text: String, type: SuggestionType) async throws -> [Suggestion]
    var requiresAPIKey: Bool { get }
}
```

#### 4. Action Plugins
Custom commands for the command palette.

```swift
protocol ActionPlugin: Plugin {
    var actions: [PluginAction] { get }
    func execute(action: PluginAction, context: ActionContext) async throws
}
```

### Plugin Manifest

Each plugin includes a `plugin.json` manifest:

```json
{
    "id": "com.example.hugo-exporter",
    "name": "Hugo Exporter",
    "version": "1.0.0",
    "minAppVersion": "1.0.0",
    "type": "exporter",
    "entryPoint": "HugoExporter",
    "permissions": ["filesystem", "network"],
    "author": "Example Dev",
    "description": "Export markdown to Hugo static site format"
}
```

### Plugin Security

- **Sandboxed execution:** Plugins run in restricted environment
- **Permission system:** Declare required permissions in manifest
- **Code signing:** Optional signing for verified plugins
- **User approval:** First-run permission prompt for sensitive operations

### Plugin Distribution

- **Built-in:** Core plugins bundled with app
- **Plugin Gallery:** In-app discovery and installation
- **Manual install:** Drag `.mdplugin` bundle to app

### Plugin Developer Resources

**SDK Repository:** github.com/sturdy-barnacle/tibok-plugin-sdk

The Plugin SDK provides:
- Protocol definitions and base classes
- Xcode project templates
- Sample plugins (exporter, theme, AI provider, action)
- Documentation and guides
- Testing utilities

**Developer Portal:** tibok.app/developers

### Plugin Storage

```
~/Library/Application Support/tibok/
└── Plugins/
    ├── app.tibok.hugo-exporter/
    │   ├── plugin.json
    │   └── HugoExporter.swift (compiled)
    └── app.tibok.nord-theme/
        ├── plugin.json
        └── theme.css
```

---

## Future Considerations

- iPad companion app via native SwiftUI (not Catalyst)
- Collaborative editing via CloudKit or CRDT
- Obsidian vault compatibility
- Plugin marketplace with revenue sharing
