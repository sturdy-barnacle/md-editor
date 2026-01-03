# Tibok Plugin Examples

This directory contains example plugins demonstrating how to extend Tibok.

## Plugin Types

### Script Plugins (JavaScript)

Script plugins run in a sandboxed JavaScriptCore environment. They can only use safe permissions and are ideal for:

- Simple text insertions
- Slash commands
- Command palette actions
- Reading document content

**Advantages:**
- Easy to develop (just JavaScript)
- Safe by design (sandboxed)
- No compilation needed
- Quick iteration

**Limitations:**
- Limited to safe permissions only
- No network or file system access
- Can't execute processes

### Native Plugins (Swift)

Native plugins are compiled Swift frameworks with full access to Tibok's capabilities. They're ideal for:

- Complex integrations
- Network-connected features
- File system operations
- Advanced document manipulation

**Advantages:**
- Full permission access
- Native performance
- Rich API access
- Complex logic support

**Limitations:**
- Requires Swift knowledge
- Must be compiled
- Needs code signing for distribution

## Examples

### lorem-ipsum-plugin (Script)

A JavaScript plugin that adds lorem ipsum text generation.

**Features:**
- `/lorem` - Insert 1 paragraph
- `/lorem3` - Insert 3 paragraphs
- `/lorem5` - Insert 5 paragraphs
- `/loremshort` - Insert one sentence
- Command palette integration

**Installation:**
```bash
cp -r lorem-ipsum-plugin ~/Library/Application\ Support/tibok/Plugins/ThirdParty/
```

### swift-plugin-template (Native)

A template for creating native Swift plugins.

**Features:**
- Example slash commands
- Example command palette commands
- Demonstrates plugin lifecycle
- Shows how to use PluginContext

**Building:**
1. Create a Swift Package with framework target
2. Copy the source file
3. Build: `swift build -c release`
4. Package framework with manifest.json

## Creating Your Own Plugin

### Script Plugin

1. Create a directory: `my-plugin/`
2. Create `manifest.json` with plugin metadata
3. Create `main.js` with your plugin code
4. Copy to `~/Library/Application Support/tibok/Plugins/ThirdParty/`

### Native Plugin

1. Create a Swift Package
2. Implement the `TibokPlugin` protocol
3. Build the framework
4. Create `manifest.json`
5. Package and distribute

## Permissions

### Safe Permissions (Script-compatible)

- `slash-commands` - Register slash commands
- `command-palette` - Add palette commands
- `read-current-document` - Read document content
- `insert-text` - Insert at cursor
- `read-selection` - Access selected text
- `read-document-metadata` - Read filename, path, frontmatter

### Elevated Permissions (Native only)

- `write-document` - Modify document directly
- `workspace-access` - Access workspace files
- `network-access` - Make HTTP requests
- `filesystem-access` - Read/write any files
- `execute-process` - Run shell commands

## Documentation

For complete documentation, see:
- [Plugin SDK Specification](../../docs/PLUGIN_SDK_SPEC.md)
