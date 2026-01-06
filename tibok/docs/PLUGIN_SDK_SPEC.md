# Tibok Plugin SDK Technical Specification

**Version:** 1.0.0
**Status:** Draft
**Last Updated:** January 2026

> **For Plugin Developers:** Tibok plugins are written in **JavaScript**. This guide covers everything you need to create, test, and publish plugins to the Tibok marketplace.

## Overview

The Tibok Plugin SDK enables developers to extend the markdown editor with custom functionality using **JavaScript plugins** that run in a secure JavaScriptCore sandbox.

Plugins can:
- Add slash commands (e.g., `/table`, `/date`)
- Add commands to the command palette (Cmd+K)
- Read and insert text in the editor
- Access document metadata

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         TIBOK APP                               │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    PLUGIN MANAGER                        │   │
│  │                                                          │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │   │
│  │  │ Permission   │  │  Signature   │  │   Plugin     │   │   │
│  │  │ Validator    │  │  Verifier    │  │   Loader     │   │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│                              ▼                                  │
│                  ┌──────────────────┐                          │
│                  │  SCRIPT RUNTIME  │                          │
│                  │  (JSContext)     │                          │
│                  │                  │                          │
│                  │  • Sandboxed     │                          │
│                  │  • Safe APIs     │                          │
│                  │  • .js files     │                          │
│                  └──────────────────┘                          │
│                              │                                  │
│                              ▼                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    PLUGIN CONTEXT                        │   │
│  │                                                          │   │
│  │  • SlashCommandService  • CommandService  • AppState    │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Trust Tiers

### Tier 1: Official

- **Definition:** Plugins compiled into the Tibok app binary
- **Trust Level:** Implicit (your code)
- **Permissions:** All permissions automatically granted
- **Signature:** Not required
- **Distribution:** Shipped with app updates

### Tier 2: Verified

- **Definition:** Third-party plugins that have undergone security audit
- **Trust Level:** High (cryptographically signed)
- **Permissions:** Granted without user prompt (for safe permissions)
- **Signature:** Required (Ed25519)
- **Distribution:** Tibok Plugin Marketplace

### Tier 3: Community

- **Definition:** User-installed plugins without verification
- **Trust Level:** User discretion
- **Permissions:** Require explicit user approval
- **Signature:** Not required
- **Distribution:** Direct install or community sources

## Plugin Manifest

### Schema

```json
{
  "identifier": "com.example.my-plugin",
  "name": "My Plugin",
  "version": "1.0.0",
  "description": "A description of what the plugin does",
  "icon": "sparkle",
  "author": "Author Name",
  "author_info": {
    "name": "Author Name",
    "email": "author@example.com",
    "url": "https://example.com"
  },
  "minimum_tibok_version": "1.2.0",
  "plugin_type": "script",
  "permissions": [
    "slash-commands",
    "command-palette",
    "read-current-document"
  ],
  "trust_tier": "community",
  "signature": {
    "algorithm": "ed25519",
    "public_key_id": "tibok-2026",
    "signature": "base64...",
    "signed_at": "2026-01-03T12:00:00Z",
    "content_hash": "sha256..."
  },
  "entry_point": {
    "script": "main.js",
    "framework": null,
    "className": null
  },
  "homepage": "https://github.com/author/plugin",
  "repository": "https://github.com/author/plugin",
  "license": "MIT",
  "keywords": ["markdown", "productivity"]
}
```

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `identifier` | String | Unique reverse-DNS identifier |
| `name` | String | Human-readable display name |
| `version` | String | Semantic version (MAJOR.MINOR.PATCH) |

### Optional Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `description` | String | null | Plugin description |
| `icon` | String | "puzzlepiece.extension" | SF Symbol name |
| `author` | String | null | Author name (simple) |
| `author_info` | Object | null | Detailed author info |
| `minimum_tibok_version` | String | null | Required Tibok version |
| `plugin_type` | Enum | "script" | Plugin type (always "script" for marketplace) |
| `permissions` | Array | [] | Required permissions |
| `trust_tier` | Enum | "community" | Set by marketplace |
| `signature` | Object | null | Cryptographic signature |
| `entry_point` | Object | null | Entry point configuration |
| `homepage` | String | null | Documentation URL |
| `repository` | String | null | Source code URL |
| `license` | String | null | License identifier |
| `keywords` | Array | null | Discovery keywords |

## Permissions

Plugins declare the permissions they need in `manifest.json`. Users approve permissions before installation.

| Permission | Description |
|------------|-------------|
| `slash-commands` | Register slash commands (e.g., /table) |
| `command-palette` | Add commands to Cmd+K palette |
| `read-current-document` | Read current document content |
| `insert-text` | Insert text at cursor |
| `read-selection` | Access selected text |
| `read-document-metadata` | Read filename, path, frontmatter |

### Permission Enforcement

- **Community plugins:** All permissions require user approval before install
- **Verified plugins:** Permissions auto-approved (plugin has been security audited)
- **Official plugins:** All permissions auto-approved (built into Tibok)

## Plugin Development

### Directory Structure

```
com.example.my-script-plugin/
├── manifest.json
├── main.js
└── lib/
    └── helpers.js
```

### JavaScript API

#### Global Object: `tibok`

```javascript
tibok.version        // "1.0.0"
tibok.pluginId       // "com.example.my-plugin"
tibok.slashCommands  // Slash command registration API
tibok.commands       // Command palette API
tibok.editor         // Editor manipulation API
tibok.document       // Document info API
tibok.log            // Logging API
```

#### Slash Commands API

```javascript
// Register a single slash command
tibok.slashCommands.register({
    name: "hello",
    description: "Insert a greeting",
    icon: "hand.wave",
    insert: "Hello, world!",  // Static insert
    keywords: ["greeting", "hi"],
    category: "general"
});

// Register with dynamic execution
tibok.slashCommands.register({
    name: "date",
    description: "Insert current date",
    icon: "calendar",
    execute: function() {
        const date = new Date().toISOString().split('T')[0];
        tibok.editor.insertText(date);
    }
});

// Register multiple commands
tibok.slashCommands.registerMany([
    { name: "cmd1", description: "...", insert: "..." },
    { name: "cmd2", description: "...", insert: "..." }
]);
```

#### Command Palette API

```javascript
tibok.commands.register({
    id: "my-command",
    title: "My Command",
    subtitle: "Does something",
    icon: "sparkle",
    category: "general",
    action: function() {
        tibok.log.info("Command executed!");
    }
});
```

#### Editor API

```javascript
// Insert text at cursor (requires: insert-text)
tibok.editor.insertText("Hello");

// Get selected text (requires: read-selection)
const selection = tibok.editor.getSelectedText();

// Get document content (requires: read-current-document)
const content = tibok.editor.getContent();

// Get cursor position (requires: read-selection)
const pos = tibok.editor.getCursorPosition();
// Returns: { position: 123 }
```

#### Document API

```javascript
// Get filename (requires: read-document-metadata)
const filename = tibok.document.getFilename();

// Get file path
const path = tibok.document.getPath();

// Get frontmatter as object
const frontmatter = tibok.document.getFrontmatter();

// Get word count
const words = tibok.document.getWordCount();
```

#### Logging API

```javascript
tibok.log.info("Information message");
tibok.log.warn("Warning message");
tibok.log.error("Error message");

// Also available via console
console.log("Message");
console.warn("Warning");
console.error("Error");
```

### Example Script Plugin

**manifest.json:**
```json
{
  "identifier": "com.example.lorem-plugin",
  "name": "Lorem Ipsum Generator",
  "version": "1.0.0",
  "description": "Insert lorem ipsum placeholder text",
  "icon": "text.word.spacing",
  "plugin_type": "script",
  "permissions": ["slash-commands", "insert-text"],
  "entry_point": {
    "script": "main.js"
  }
}
```

**main.js:**
```javascript
// Lorem ipsum text
const LOREM = "Lorem ipsum dolor sit amet, consectetur adipiscing elit.";

// Register slash command
tibok.slashCommands.register({
    name: "lorem",
    description: "Insert lorem ipsum paragraph",
    icon: "text.word.spacing",
    keywords: ["placeholder", "dummy", "text"],
    category: "general",
    execute: function(args) {
        const count = parseInt(args) || 1;
        const text = Array(count).fill(LOREM).join("\n\n");
        tibok.editor.insertText(text);
    }
});

tibok.log.info("Lorem Ipsum plugin loaded!");
```

## Signature Verification

### Signature Format

```json
{
  "algorithm": "ed25519",
  "public_key_id": "tibok-2026",
  "signature": "BASE64_SIGNATURE",
  "signed_at": "2026-01-03T12:00:00Z",
  "content_hash": "SHA256_HEX"
}
```

### Message Format

The signed message is constructed as:
```
tibok-plugin-v1:<identifier>:<version>:<content_hash>
```

Example:
```
tibok-plugin-v1:com.example.plugin:1.0.0:a3f2b1c9...
```

### Verification Process

1. Compute SHA256 hash of plugin bundle
2. Compare with `content_hash` in signature
3. Construct message string
4. Verify Ed25519 signature against message
5. Check signature age (max 30 days)
6. Verify public key is trusted

## File Locations

### Plugin Directories

| Directory | Purpose |
|-----------|---------|
| `~/Library/Application Support/tibok/Plugins/BuiltIn/` | Built-in plugins |
| `~/Library/Application Support/tibok/Plugins/ThirdParty/` | User-installed plugins |

### Configuration

| File | Purpose |
|------|---------|
| `~/Library/Preferences/com.kquinones.tibok.plist` | Plugin enable/disable state |

## Security Considerations

### Plugin Sandbox

JavaScriptCore provides a secure sandbox with:
- No file system access
- No network access
- No process execution
- No access to system APIs

Only the explicitly exposed `tibok.*` APIs are available to plugins.

### Permission Transparency

All permissions are:
- Declared in manifest
- Shown to user before install
- Stored in user preferences
- Revocable at any time

## API Reference

### SlashCommand

```swift
struct SlashCommand {
    let id: String
    let name: String
    let description: String
    let icon: String
    let insert: String
    let source: String
    let keywords: [String]
    let category: SlashCommandCategory
}
```

### Command

```swift
struct Command {
    let id: String
    let title: String
    let subtitle: String?
    let icon: String?
    let shortcut: KeyboardShortcut?
    let category: CommandCategory
    let source: String
    let action: () -> Void
}
```

### SlashCommandCategory

```swift
enum SlashCommandCategory: String {
    case headings, blocks, links, lists
    case formatting, math, structure
    case datetime, frontmatter, general
}
```

### CommandCategory

```swift
enum CommandCategory: String {
    case file, edit, view, insert
    case export, git, general
}
```

## Changelog

### Version 1.0.0 (January 2026)

- Initial specification
- JavaScript plugin support with JavaScriptCore sandbox
- Three-tier trust model (Official, Verified, Community)
- Ed25519 signature verification for verified plugins
- Permission-based security model
