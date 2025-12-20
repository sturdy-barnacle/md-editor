# Plugin Template

This template provides a complete starting point for creating a tibok plugin.

## Quick Start

1. Copy this template to your plugin directory
2. Replace `MyPlugin` with your plugin name (everywhere)
3. Update `manifest.json` with your plugin information
4. Implement your features in the plugin class
5. Test in ThirdParty folder: `~/Library/Application Support/tibok/Plugins/ThirdParty/`

## Template Files

### manifest.json

```json
{
  "identifier": "com.example.myplugin",
  "name": "My Plugin",
  "version": "1.0.0",
  "description": "A brief description of what your plugin does",
  "author": "Your Name",
  "icon": "puzzlepiece.extension",
  "minimumTibokVersion": "0.6.0",
  "capabilities": ["slash-commands", "command-palette"],
  "entryPoint": {
    "className": "MyPlugin"
  }
}
```

**Key points**:
- `identifier`: Use reverse-DNS format (e.g., `com.yourname.pluginname`)
- `version`: Follow semantic versioning (MAJOR.MINOR.PATCH)
- `icon`: Use any SF Symbol name
- `capabilities`: List features your plugin uses

### MyPlugin.swift

```swift
import Foundation
@testable import tibok

/// Example plugin demonstrating basic functionality.
///
/// This plugin shows how to:
/// - Register slash commands
/// - Register command palette commands
/// - Access editor context
/// - Work with documents
final class MyPlugin: TibokPlugin {
    // MARK: - Plugin Metadata

    static let identifier = "com.example.myplugin"
    static let name = "My Plugin"
    static let version = "1.0.0"
    static let description = "A plugin that demonstrates basic functionality"
    static let icon = "puzzlepiece.extension"
    static let author = "Your Name"

    // MARK: - Lifecycle

    init() {
        print("MyPlugin initialized")
    }

    func register(with context: PluginContext) {
        print("MyPlugin registering commands...")

        // Register your slash commands
        registerSlashCommands(with: context)

        // Register your command palette commands
        registerCommandPaletteCommands(with: context)
    }

    func deactivate() {
        print("MyPlugin deactivated")
    }

    // MARK: - Slash Commands

    private func registerSlashCommands(with context: PluginContext) {
        // Example 1: Simple text insertion command
        let simpleCommand = SlashCommand(
            name: "hello",
            description: "Insert a greeting",
            icon: "hand.wave",
            action: { [weak context] in
                context?.insertText("Hello! 👋")
            }
        )
        context.slashCommandService.register(simpleCommand, source: Self.identifier)

        // Example 2: Command with multiple lines
        let templateCommand = SlashCommand(
            name: "template",
            description: "Insert a template",
            icon: "doc.text",
            action: { [weak context] in
                let template = """
                ## Section Title

                Write content here.
                """
                context?.insertText(template)
            }
        )
        context.slashCommandService.register(templateCommand, source: Self.identifier)

        // Example 3: Command that accesses document metadata
        let docCommand = SlashCommand(
            name: "doc-info",
            description: "Insert document information",
            icon: "info.circle",
            action: { [weak context] in
                if let doc = context?.currentDocument {
                    let info = """
                    Document: \(doc.fileURL?.lastPathComponent ?? "Untitled")
                    Length: \(doc.content.count) characters
                    """
                    context?.insertText(info)
                } else {
                    context?.insertText("No document open")
                }
            }
        )
        context.slashCommandService.register(docCommand, source: Self.identifier)
    }

    // MARK: - Command Palette Commands

    private func registerCommandPaletteCommands(with context: PluginContext) {
        // Example 1: Simple command
        let simpleCommand = Command(
            id: "com.example.myplugin.hello",
            title: "My Plugin: Say Hello",
            description: "Inserts a greeting into the document",
            icon: "hand.wave",
            action: { [weak context] in
                context?.insertText("Hello from My Plugin! 👋")
            }
        )
        context.commandRegistry.register(simpleCommand, source: Self.identifier)

        // Example 2: Command with conditional logic
        let conditionalCommand = Command(
            id: "com.example.myplugin.timestamp",
            title: "My Plugin: Insert Timestamp",
            description: "Insert current date and time",
            icon: "clock",
            action: { [weak context] in
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .medium
                let timestamp = dateFormatter.string(from: Date())
                context?.insertText("Last updated: \(timestamp)")
            }
        )
        context.commandRegistry.register(conditionalCommand, source: Self.identifier)

        // Example 3: Command that works with document content
        let contentCommand = Command(
            id: "com.example.myplugin.stats",
            title: "My Plugin: Document Stats",
            description: "Show word and character count",
            icon: "chart.bar",
            action: { [weak context] in
                if let doc = context?.currentDocument {
                    let charCount = doc.content.count
                    let wordCount = doc.content.split(separator: " ").count
                    let stats = """
                    📊 Document Stats
                    Words: \(wordCount)
                    Characters: \(charCount)
                    """
                    context?.insertText(stats)
                }
            }
        )
        context.commandRegistry.register(contentCommand, source: Self.identifier)
    }
}
```

## Common Patterns

### Pattern 1: Insert Simple Text

```swift
let command = SlashCommand(
    name: "example",
    description: "Insert example text",
    icon: "star",
    action: { [weak context] in
        context?.insertText("Example text here")
    }
)
context.slashCommandService.register(command, source: Self.identifier)
```

### Pattern 2: Insert Formatted Template

```swift
let command = SlashCommand(
    name: "section",
    description: "Insert a section",
    icon: "doc.richtext",
    action: { [weak context] in
        let template = """
        ## Section Name

        Paragraph here.
        """
        context?.insertText(template)
    }
)
context.slashCommandService.register(command, source: Self.identifier)
```

### Pattern 3: Access Document Information

```swift
let command = SlashCommand(
    name: "docpath",
    description: "Insert document path",
    icon: "folder",
    action: { [weak context] in
        if let doc = context?.currentDocument,
           let url = doc.fileURL {
            context?.insertText("Document: \(url.path)")
        } else {
            context?.insertText("Document not saved yet")
        }
    }
)
context.slashCommandService.register(command, source: Self.identifier)
```

### Pattern 4: Use Timestamps

```swift
let command = SlashCommand(
    name: "timestamp",
    description: "Insert current time",
    icon: "clock",
    action: { [weak context] in
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let time = formatter.string(from: Date())
        context?.insertText("Time: \(time)")
    }
)
context.slashCommandService.register(command, source: Self.identifier)
```

### Pattern 5: Create Multi-line Insertions with Proper Indentation

```swift
let command = SlashCommand(
    name: "table",
    description: "Insert a table",
    icon: "table",
    action: { [weak context] in
        let table = """
        | Column 1 | Column 2 |
        |----------|----------|
        | Cell 1   | Cell 2   |
        | Cell 3   | Cell 4   |
        """
        context?.insertText(table)
    }
)
context.slashCommandService.register(command, source: Self.identifier)
```

## Testing Your Plugin

### Local Development Setup

1. Create your plugin in the ThirdParty folder:
   ```bash
   mkdir -p ~/Library/Application\ Support/tibok/Plugins/ThirdParty/MyPlugin
   ```

2. Copy your files there:
   ```bash
   cp manifest.json ~/Library/Application\ Support/tibok/Plugins/ThirdParty/MyPlugin/
   cp MyPlugin.swift ~/Library/Application\ Support/tibok/Plugins/ThirdParty/MyPlugin/
   ```

3. Restart tibok and check Settings → Plugins

### Testing Checklist

- [ ] Plugin appears in Settings
- [ ] Plugin can be enabled/disabled
- [ ] All slash commands appear in slash menu
- [ ] All command palette commands appear in Cmd+K
- [ ] Commands insert correct text
- [ ] No crashes or errors in Console
- [ ] Performance is acceptable (< 100ms per command)

### Debugging

Enable debug output in your plugin:

```swift
func register(with context: PluginContext) {
    print("MyPlugin: register() called")

    let command = SlashCommand(
        name: "test",
        description: "Test command",
        icon: "star",
        action: { [weak context] in
            print("MyPlugin: test command executed")
            context?.insertText("Test")
        }
    )
    context.slashCommandService.register(command, source: Self.identifier)
}
```

Then open Console.app and filter for "MyPlugin" to see output.

## Packaging for Distribution

Once your plugin is ready:

1. **Create a GitHub repository**
   ```
   https://github.com/yourname/tibok-myplugin
   ```

2. **Add these files to root**:
   - manifest.json
   - MyPlugin.swift
   - README.md
   - LICENSE
   - CHANGELOG.md

3. **Create a release**:
   ```bash
   git tag v1.0.0
   git push --tags
   ```

4. **Create GitHub release** with release notes

## Example: Full Plugin Structure

```
tibok-myplugin/
├── README.md
├── LICENSE
├── CHANGELOG.md
├── manifest.json
├── MyPlugin.swift
└── Assets/
    └── screenshot.png
```

### README.md Example

```markdown
# My Plugin for tibok

Brief description of what your plugin does.

## Features

- Feature 1
- Feature 2
- Feature 3

## Installation

1. Download release ZIP
2. Extract to `~/Library/Application Support/tibok/Plugins/ThirdParty/`
3. Restart tibok
4. Enable in Settings → Plugins

## Usage

Type `/hello` or use Command Palette (Cmd+K).

## License

MIT
```

## Next Steps

1. Update `manifest.json` with your plugin information
2. Rename `MyPlugin` to your plugin name (in class and filename)
3. Implement your features following the patterns above
4. Test in the Dev folder
5. Create a GitHub repository
6. Share with the community!

## Need Help?

- **API Questions**: Read `/tibok/Plugins/TibokPlugin.swift`
- **Examples**: Check built-in plugins in `/tibok/Plugins/Builtin/`
- **Guide**: Read `plugin-development.md`
- **Community**: Discuss on GitHub Discussions
