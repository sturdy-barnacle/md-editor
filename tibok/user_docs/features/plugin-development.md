# Plugin Development Guide

Tibok supports community-created plugins that extend the editor with new commands, slash commands, and integrations. This guide explains how to create and distribute plugins for Tibok.

## Table of Contents

- [Overview](#overview)
- [Plugin Structure](#plugin-structure)
- [Creating a Plugin](#creating-a-plugin)
- [Plugin Manifest](#plugin-manifest)
- [Available APIs](#available-apis)
- [Slash Commands](#slash-commands)
- [Command Palette Integration](#command-palette-integration)
- [Example: Creating Your First Plugin](#example-creating-your-first-plugin)
- [Security](#security)
- [Publishing Your Plugin](#publishing-your-plugin)
- [Troubleshooting](#troubleshooting)

## Overview

Tibok plugins allow developers to:

- Add **slash commands** (triggered with `/`)
- Register **command palette commands** (Cmd+K palette)
- Access editor context and document metadata
- Extend Tibok with custom functionality

Plugins are written in **Swift** and packaged with a manifest file. Tibok discovers plugins from:

1. **Built-in** (`~/Library/Application Support/tibok/Plugins/BuiltIn/`)
   - Included with Tibok
   - Core plugins: Slash Commands, Frontmatter, WordPress Export

2. **Community** (`~/Library/Application Support/tibok/Plugins/ThirdParty/`)
   - User-installed plugins created by developers like you
   - Share your plugins with the community

## Plugin Structure

A minimal plugin has this structure:

```
MyPlugin/
├── manifest.json           # Plugin metadata
├── MyPlugin.swift          # Plugin implementation
└── README.md               # Documentation
```

### Recommended Structure

For more complex plugins, use this structure:

```
MyPlugin/
├── manifest.json           # Plugin metadata
├── Sources/
│   └── MyPlugin/
│       ├── MyPlugin.swift  # Main plugin class
│       ├── Commands/       # Slash command implementations
│       └── Services/       # Helper services
├── Tests/
│   └── MyPluginTests.swift # Unit tests
├── README.md               # User documentation
├── LICENSE                 # License file
└── CHANGELOG.md            # Version history
```

## Creating a Plugin

### Step 1: Create the Manifest

Every plugin needs a `manifest.json` file in its root directory describing the plugin:

```json
{
  "identifier": "com.example.myplugin",
  "name": "My Plugin",
  "version": "1.0.0",
  "description": "A plugin that does amazing things",
  "author": "Your Name",
  "minimumTibokVersion": "0.6.0",
  "icon": "sparkles",
  "capabilities": ["slash-commands", "command-palette"],
  "entryPoint": {
    "className": "MyPlugin"
  }
}
```

### Step 2: Implement the Plugin Class

Create a Swift file that implements the `TibokPlugin` protocol:

```swift
import Foundation
@testable import tibok

final class MyPlugin: TibokPlugin {
    static let identifier = "com.example.myplugin"
    static let name = "My Plugin"
    static let version = "1.0.0"
    static let description = "A plugin that does amazing things"
    static let icon = "sparkles"
    static let author = "Your Name"

    func register(with context: PluginContext) {
        // Register slash commands
        registerSlashCommands(with: context)

        // Register command palette commands
        registerCommandPaletteCommands(with: context)
    }

    private func registerSlashCommands(with context: PluginContext) {
        // Example: Register a /hello command
        let command = SlashCommand(
            name: "hello",
            description: "Inserts a greeting",
            icon: "hand.wave",
            action: { [weak context] in
                let greeting = "Hello! 👋 Welcome to my plugin."
                context?.insertText(greeting)
            }
        )

        context.slashCommandService.register(command, source: Self.identifier)
    }

    private func registerCommandPaletteCommands(with context: PluginContext) {
        // Example: Register a command palette command
        let command = Command(
            id: "com.example.myplugin.greet",
            title: "Greet User",
            description: "Say hello",
            icon: "hand.wave",
            action: { [weak context] in
                let greeting = "Hello! 👋 Welcome to my plugin."
                context?.insertText(greeting)
            }
        )

        context.commandRegistry.register(command, source: Self.identifier)
    }

    func deactivate() {
        // Clean up when plugin is disabled or app terminates
    }
}
```

## Plugin Manifest

The `manifest.json` file describes your plugin to Tibok:

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `identifier` | ✅ | string | Unique plugin ID (reverse-DNS style: `com.company.plugin`) |
| `name` | ✅ | string | Display name in settings |
| `version` | ✅ | string | Semantic version (e.g., `1.0.0`) |
| `description` | | string | What the plugin does |
| `author` | | string | Plugin creator |
| `icon` | | string | SF Symbol icon (e.g., `sparkles`) |
| `minimumTibokVersion` | | string | Minimum required Tibok version |
| `capabilities` | | array | Features used: `["slash-commands", "command-palette", "export"]` |
| `entryPoint` | | object | Plugin entry point configuration |

### Entry Point

The `entryPoint` object specifies how to load your plugin:

```json
{
  "entryPoint": {
    "className": "MyPlugin"
  }
}
```

For future versions supporting different plugin types:

```json
{
  "entryPoint": {
    "framework": "MyPlugin",
    "className": "MyPluginClass"
  }
}
```

## Available APIs

Plugins receive a `PluginContext` object with access to:

### PluginContext Methods

```swift
protocol PluginContext {
    /// Insert text at current cursor position
    func insertText(_ text: String)

    /// Get current document
    var currentDocument: MarkdownDocument? { get }

    /// Get app state
    var appState: AppState? { get }

    /// Register services and commands
    var slashCommandService: SlashCommandService { get }
    var commandRegistry: CommandService { get }
}
```

### Working with Documents

```swift
if let doc = context.currentDocument {
    // Get document content
    let content = doc.content

    // Get document metadata
    let frontmatter = doc.frontmatter

    // Get document path
    let filePath = doc.fileURL

    // Modify content
    context.insertText("Hello from plugin!")
}
```

### Working with Git

```swift
// Access git information through AppState
if let appState = context.appState {
    let branch = appState.currentBranch
    let stagedFiles = appState.stagedFiles
    let unstagedFiles = appState.unstagedFiles
}
```

## Slash Commands

Slash commands are triggered by typing `/` at the start of a line:

### Creating a Slash Command

```swift
let command = SlashCommand(
    name: "quote",
    description: "Insert a blockquote",
    icon: "quote.opening",
    action: { [weak context] in
        context?.insertText("> ")
    }
)

context.slashCommandService.register(command, source: Self.identifier)
```

### Command Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | String | Command trigger word (no `/` prefix) |
| `description` | String | Help text shown in slash menu |
| `icon` | String | SF Symbol icon name |
| `action` | Closure | Called when command is selected |
| `category` | String? | Organize into categories (e.g., "Formatting") |

### Example: Markdown Template Command

```swift
let templateCommand = SlashCommand(
    name: "article",
    description: "Insert article template",
    icon: "doc.text",
    action: { [weak context] in
        let template = """
        ---
        title:
        date:
        draft: true
        ---

        # Article Title

        Write your article here.
        """
        context?.insertText(template)
    }
)

context.slashCommandService.register(templateCommand, source: Self.identifier)
```

## Command Palette Integration

Register commands that appear in the command palette (Cmd+K):

### Creating a Command Palette Command

```swift
let command = Command(
    id: "com.example.myplugin.action",
    title: "Do Something Amazing",
    description: "Performs an amazing action",
    icon: "sparkles",
    action: { [weak context] in
        // Perform action
        context?.insertText("✨")
    }
)

context.commandRegistry.register(command, source: Self.identifier)
```

### Command Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | String | Unique command ID |
| `title` | String | Display name in palette |
| `description` | String | Help text |
| `icon` | String | SF Symbol icon |
| `action` | Closure | Executed when selected |
| `category` | String? | Organize commands (e.g., "Formatting") |

## Example: Creating Your First Plugin

Let's create a "Daily Journal" plugin that adds journal-related commands:

### 1. Create Manifest (`manifest.json`)

```json
{
  "identifier": "com.example.journalplugin",
  "name": "Daily Journal",
  "version": "1.0.0",
  "description": "Quick commands for daily journaling",
  "author": "Jane Developer",
  "icon": "book",
  "minimumTibokVersion": "0.6.0",
  "capabilities": ["slash-commands", "command-palette"],
  "entryPoint": {
    "className": "DailyJournalPlugin"
  }
}
```

### 2. Implement Plugin (`DailyJournalPlugin.swift`)

```swift
import Foundation
@testable import tibok

final class DailyJournalPlugin: TibokPlugin {
    static let identifier = "com.example.journalplugin"
    static let name = "Daily Journal"
    static let version = "1.0.0"
    static let description = "Quick commands for daily journaling"
    static let icon = "book"
    static let author = "Jane Developer"

    func register(with context: PluginContext) {
        // Register slash commands
        registerSlashCommands(with: context)

        // Register command palette commands
        registerCommands(with: context)
    }

    private func registerSlashCommands(with context: PluginContext) {
        // Today's entry
        let todayCommand = SlashCommand(
            name: "journal-today",
            description: "Start today's journal entry",
            icon: "calendar",
            action: { [weak context] in
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "EEEE, MMMM d, yyyy"
                let today = dateFormatter.string(from: Date())

                let entry = """
                # \(today)

                """
                context?.insertText(entry)
            }
        )

        context.slashCommandService.register(todayCommand, source: Self.identifier)

        // Mood tracker
        let moodCommand = SlashCommand(
            name: "mood",
            description: "Log today's mood",
            icon: "face.smiling",
            action: { [weak context] in
                let moods = """
                ## Mood
                - [ ] Happy 😊
                - [ ] Calm 😌
                - [ ] Energetic ⚡
                - [ ] Focused 🎯
                - [ ] Tired 😴
                - [ ] Stressed 😰
                """
                context?.insertText(moods)
            }
        )

        context.slashCommandService.register(moodCommand, source: Self.identifier)
    }

    private func registerCommands(with context: PluginContext) {
        let todayCommand = Command(
            id: "com.example.journalplugin.today",
            title: "Journal: Today's Entry",
            description: "Create today's journal entry",
            icon: "calendar",
            action: { [weak context] in
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "EEEE, MMMM d, yyyy"
                let today = dateFormatter.string(from: Date())

                let entry = """
                # \(today)

                """
                context?.insertText(entry)
            }
        )

        context.commandRegistry.register(todayCommand, source: Self.identifier)
    }

    func deactivate() {
        // Clean up if needed
    }
}
```

### 3. Installation

1. Create a folder: `~/Library/Application Support/tibok/Plugins/ThirdParty/DailyJournal`
2. Copy your files into that folder
3. Restart Tibok
4. Go to Settings → Plugins and enable "Daily Journal"

## Security

### Best Practices

1. **Keep dependencies minimal**: Use only standard Swift and Foundation frameworks
2. **Validate input**: Don't trust user input or document content
3. **Avoid system access**: Don't make unnecessary file system or network calls
4. **Use proper error handling**: Gracefully handle errors without crashing the editor
5. **Document permissions**: Clearly explain what your plugin accesses

### Code Signing (Future)

In a future release, Tibok will require plugins to be code-signed for distribution. This ensures:

- Plugin authenticity (you are who you claim to be)
- Plugin integrity (code hasn't been modified)
- User security (plugins come from trusted developers)

For now, develop and test locally. We'll update this guide when code signing is required.

## Publishing Your Plugin

### Share on GitHub

1. **Create a GitHub repository**
   - Naming: `tibok-plugin-name` (recommended)
   - Example: `tibok-daily-journal`, `tibok-word-stats`

2. **Add plugin files**
   - `manifest.json` - Plugin metadata
   - `PluginName.swift` - Plugin implementation
   - `README.md` - User-facing documentation
   - `LICENSE` - License file (MIT recommended)
   - `CHANGELOG.md` - Version history

3. **Create a release**
   ```bash
   git tag v1.0.0
   git push --tags
   ```
   - Create GitHub Release with release notes
   - Include ZIP download of your plugin folder

4. **Add to Plugin Registry**
   - Open issue/PR on [Tibok repository](https://github.com/tibok/tibok)
   - Include: plugin name, repo link, description
   - We'll add it to [PLUGIN_REGISTRY.md](../../PLUGIN_REGISTRY.md)

### Installation Instructions for Users

Users will:
1. Find your plugin in [PLUGIN_REGISTRY.md](../../PLUGIN_REGISTRY.md)
2. Download the ZIP from your GitHub release
3. Extract to `~/Library/Application Support/tibok/Plugins/ThirdParty/`
4. Restart Tibok
5. Enable in Settings > Plugins

### README Template

```markdown
# Daily Journal Plugin for Tibok

Quick commands for daily journaling in Tibok.

## Features

- Quick-start journal entries with today's date
- Mood tracker with emoji support
- Reflection prompts
- Works with Tibok 0.6.0+

## Installation

1. Download from latest release
2. Extract to `~/Library/Application Support/tibok/Plugins/ThirdParty/`
3. Restart Tibok
4. Go to Settings → Plugins and enable "Daily Journal"

## Usage

- Type `/journal-today` to start today's entry
- Type `/mood` to log your mood
- Or use Command Palette (Cmd+K) to search for commands

## License

MIT - See LICENSE file

## Support

- Issues: [GitHub Issues](https://github.com/yourname/tibok-daily-journal/issues)
- Questions: [GitHub Discussions](https://github.com/yourname/tibok-daily-journal/discussions)
```

## Troubleshooting

### Plugin not appearing in Settings

**Check**:
1. Plugin folder is in correct location: `~/Library/Application Support/tibok/Plugins/`
2. Manifest file is valid JSON: `manifest.json`
3. All required fields are present (identifier, name, version)
4. Plugin identifier is unique

**Fix**:
```bash
# Verify manifest is valid JSON
json manifest.json

# Check file permissions
ls -la ~/Library/Application Support/tibok/Plugins/

# Restart Tibok and check Console output (Cmd+Shift+C)
```

### Plugin crashes Tibok

**Debug**:
1. Open Console.app
2. Filter for "tibok"
3. Check for error messages
4. Add debug print statements to your plugin

**Common issues**:
- Unwrapping optional that's nil
- Thread safety issues (access UI from wrong thread)
- Memory leaks (retain cycles in closures)

### Slash command not appearing

**Check**:
1. Plugin is enabled in Settings
2. Slash command is properly registered in `register(with:)`
3. Command name doesn't conflict with built-in commands

### Plugin performance

**Optimize**:
1. Keep closures lightweight
2. Defer heavy work to background threads
3. Cache expensive computations
4. Use `@MainActor` for UI access

## Getting Help

- **Documentation**: Read this guide
- **Examples**: Check built-in plugins (CoreSlashCommandsPlugin, FrontmatterPlugin)
- **Community**: Discuss on GitHub Discussions
- **Issues**: Report bugs on GitHub Issues

## API Stability

The Tibok plugin API is currently in **beta** and may change. Plugin developers should:

1. Monitor release notes for API changes
2. Test plugins with each Tibok release
3. Update manifests with `minimumTibokVersion` when needed
4. Communicate breaking changes to users

We commit to:
- Maintaining backward compatibility where possible
- Providing migration guides for breaking changes
- Notifying plugin developers of upcoming changes
