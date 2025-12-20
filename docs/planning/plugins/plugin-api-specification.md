# tibok Plugin API Specification

> Stable API definition for tibok plugins (v1.0)

**Status:** Stable (v1.0)  
**Last Updated:** 2025-01-XX  
**Version:** 1.0.0

## Overview

This document defines the **stable Plugin API** for tibok. Plugins implementing this API will be compatible with tibok v1.0 and future versions that maintain backward compatibility.

## API Stability Guarantee

**v1.0 API Promise:**
- All APIs defined in this document are **stable** and will not change in breaking ways
- New APIs may be added in future versions
- Deprecated APIs will be marked with `@available` and removed only after a deprecation period
- Breaking changes will result in a major version bump (v2.0, v3.0, etc.)

## Plugin Protocol

### TibokPlugin Protocol

All plugins must implement the `TibokPlugin` protocol:

```swift
@MainActor
protocol TibokPlugin {
    /// Unique identifier (reverse-DNS style: com.company.plugin)
    static var identifier: String { get }
    
    /// Human-readable name shown in UI
    static var name: String { get }
    
    /// Semantic version (e.g., "1.0.0")
    static var version: String { get }
    
    /// Optional description
    static var description: String? { get }
    
    /// SF Symbol icon name
    static var icon: String { get }
    
    /// Optional author name
    static var author: String? { get }
    
    /// Initialize plugin (called once at startup)
    init()
    
    /// Register plugin contributions
    func register(with context: PluginContext)
    
    /// Cleanup when plugin is disabled
    func deactivate()
}
```

**Default Implementations:**
- `description`: `nil`
- `icon`: `"puzzlepiece.extension"`
- `author`: `nil`
- `deactivate()`: Empty (no-op)

## PluginContext API

The `PluginContext` provides access to tibok's services and state:

```swift
@MainActor
final class PluginContext {
    /// Registry for slash commands (editor inline commands)
    let slashCommandService: SlashCommandService
    
    /// Registry for command palette commands
    let commandRegistry: CommandService
    
    /// App state (read-only access)
    weak var appState: AppState?
}
```

### SlashCommandService API

**Purpose:** Register slash commands that appear when user types `/` at line start.

```swift
@MainActor
final class SlashCommandService: ObservableObject {
    /// Register a single slash command
    func register(_ command: SlashCommand)
    
    /// Register multiple slash commands
    func register(_ commands: [SlashCommand])
    
    /// Unregister command by ID
    func unregister(id: String)
    
    /// Unregister all commands from a source/plugin
    func unregister(source: String)
}
```

**SlashCommand Structure:**
```swift
struct SlashCommand: Identifiable, Hashable {
    let id: String                    // Unique command ID
    let name: String                  // Display name
    let description: String           // Help text
    let icon: String                  // SF Symbol name
    let insert: String                 // Text to insert
    let source: String                // Plugin identifier
    let keywords: [String]            // Search keywords
    let category: SlashCommandCategory
}
```

**SlashCommandCategory:**
```swift
enum SlashCommandCategory: String, CaseIterable {
    case headings = "Headings"
    case blocks = "Blocks"
    case links = "Links & Media"
    case lists = "Lists"
    case formatting = "Formatting"
    case math = "Math"
    case structure = "Structure"
    case datetime = "Date & Time"
    case frontmatter = "Frontmatter"
    case general = "General"
}
```

### CommandService API

**Purpose:** Register commands for the command palette (Cmd+K).

```swift
@MainActor
final class CommandService: ObservableObject {
    /// Register a command
    func register(_ command: Command)
    
    /// Register multiple commands
    func register(_ commands: [Command])
    
    /// Unregister command by ID
    func unregister(id: String)
    
    /// Unregister all commands from a source/plugin
    func unregister(source: String)
}
```

**Command Structure:**
```swift
struct Command: Identifiable, Hashable {
    let id: String                    // Unique command ID
    let title: String                  // Display name
    let subtitle: String?             // Optional description
    let icon: String?                 // SF Symbol name
    let shortcut: KeyboardShortcut?   // Optional keyboard shortcut
    let category: CommandCategory     // Grouping category
    let source: String                // Plugin identifier
    let action: () -> Void            // Command handler
}
```

**CommandCategory:**
```swift
enum CommandCategory: String, CaseIterable {
    case file = "File"
    case edit = "Edit"
    case view = "View"
    case insert = "Insert"
    case export = "Export"
    case git = "Git"
    case general = "General"
}
```

### AppState API (Read-Only)

Plugins receive **read-only** access to `AppState` via `weak var appState: AppState?`.

**Available Properties:**
```swift
@MainActor
class AppState: ObservableObject {
    // Document state
    var activeDocument: Document?     // Current document
    var documents: [Document]         // All open documents
    var activeDocumentID: UUID?       // Active document ID
    
    // Workspace
    var workspaceURL: URL?            // Current workspace folder
    var workspaceFiles: [FileItem]   // Workspace file tree
    var recentFiles: [URL]             // Recent files list
    var favoriteFiles: [URL]           // Favorite files list
    
    // Git state
    var isGitRepository: Bool         // Is workspace a Git repo?
    var currentBranch: String?        // Current Git branch
    var gitFileStatuses: [URL: GitFileStatus]  // File statuses
    var stagedFiles: [GitChangedFile] // Staged changes
    var unstagedFiles: [GitChangedFile] // Unstaged changes
}
```

**Document Model:**
```swift
struct Document: Identifiable, Codable {
    let id: UUID
    var content: String               // Markdown content
    var fileURL: URL?                 // File location (nil if unsaved)
    var frontmatter: Frontmatter?     // YAML/TOML frontmatter
    var isModified: Bool              // Has unsaved changes
    var title: String                 // Document title
}
```

**Important:** AppState is provided as a **weak reference** and may be `nil`. Always check before accessing.

## Plugin Lifecycle

### 1. Discovery
- Plugins are discovered from `~/Library/Application Support/tibok/Plugins/ThirdParty/`
- Manifest files (`manifest.json`) are read and validated
- Built-in plugins are registered at compile time

### 2. Initialization
```swift
// Called once during app startup
let plugin = MyPlugin()
```

### 3. Registration
```swift
// Called after init, before plugin features are used
plugin.register(with: context)
```

During registration, plugins should:
- Register slash commands via `context.slashCommandService`
- Register palette commands via `context.commandRegistry`
- Set up any event listeners or observers

### 4. Active
- Plugin is loaded and registered
- Commands are available to users
- Plugin can respond to user actions

### 5. Deactivation
```swift
// Called when plugin is disabled or app terminates
plugin.deactivate()
```

During deactivation, plugins should:
- Unregister all commands (automatic via `unregister(source:)`)
- Cancel timers and observers
- Release resources
- Clean up temporary files

## Best Practices

### 1. Error Handling
Always handle optional values:
```swift
guard let doc = context.appState?.activeDocument else {
    // No document open - handle gracefully
    return
}
```

### 2. Thread Safety
All plugin code runs on `@MainActor`:
```swift
@MainActor
final class MyPlugin: TibokPlugin {
    // All code here runs on main thread
}
```

### 3. Resource Cleanup
Implement proper cleanup:
```swift
func deactivate() {
    timer?.invalidate()
    NotificationCenter.default.removeObserver(self)
    // Unregister commands (automatic, but can do manually)
    context?.slashCommandService.unregister(source: Self.identifier)
}
```

### 4. Command IDs
Use reverse-DNS style IDs:
```swift
let command = SlashCommand(
    id: "\(Self.identifier).my-command",
    // ...
)
```

### 5. Performance
- Keep command execution fast (< 100ms)
- Defer heavy work to background queues
- Use `DispatchQueue.main.async` for UI updates from background

## API Versioning

### Version Requirements
Plugins declare minimum tibok version in `manifest.json`:
```json
{
  "minimumTibokVersion": "1.0.0"
}
```

### Compatibility
- Plugins built for v1.0 will work with v1.x (backward compatible)
- New APIs added in v1.1+ are optional
- Breaking changes will result in v2.0

### Deprecation Policy
- Deprecated APIs marked with `@available(*, deprecated)`
- Deprecation period: 2 major versions
- Example: API deprecated in v1.0 removed in v3.0

## Future API Additions

These APIs are **planned** but not yet available:

- **File System Access**: Restricted file read/write APIs
- **Network Access**: HTTP request APIs (with user permission)
- **Settings Access**: Plugin-specific settings storage
- **Event System**: Document save, open, close events
- **Export APIs**: Custom export format registration

These will be added in future versions with proper security controls.

## Migration Guide

### From Beta to v1.0
If you have plugins built for beta versions:

1. **Update protocol conformance**: Ensure you implement all required `TibokPlugin` members
2. **Update command registration**: Use new `SlashCommand` and `Command` structures
3. **Update AppState access**: Use `context.appState` instead of direct access
4. **Test thoroughly**: Verify all commands work correctly

## Support

- **API Questions**: See [Plugin Development Guide](../user_docs/features/plugin-development.md)
- **Security Questions**: See [Plugin Security](../user_docs/features/plugin-security.md)
- **Issues**: Report on GitHub

---

**This API is stable as of tibok v1.0. Breaking changes will be announced in advance.**

