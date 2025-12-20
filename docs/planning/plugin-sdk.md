# Plugin SDK - tibok

> Developer resources for building tibok extensions

**Note:** This document describes a **future enhanced SDK** (v2.0+). For the current stable plugin API (v1.0), see:
- **[Plugin API Specification](plugins/plugin-api-specification.md)** - Current stable API
- **[Plugin Security Model](plugins/plugin-security-model.md)** - Security architecture

## Overview

The tibok Plugin SDK enables developers to extend tibok's functionality through plugins. This document outlines the **future SDK structure** for v2.0+, including enhanced plugin types and capabilities.

**Current System (v1.0):**
- Simple protocol-based plugins (`TibokPlugin`)
- Slash commands and command palette registration
- Read-only AppState access
- See [Plugin API Specification](plugins/plugin-api-specification.md) for details

**Future System (v2.0+):**
- Enhanced plugin types (Exporters, Themes, AI Providers, Actions)
- Separate SDK package
- Advanced capabilities (file system, network, settings)
- Code signing and marketplace

---

## Repositories

### Main App
- **Repository:** github.com/sturdy-barnacle/md-editor
- **Visibility:** Private (until v1.0 launch)

### Plugin SDK
- **Repository:** github.com/sturdy-barnacle/tibok-plugin-sdk
- **Visibility:** Public
- **License:** MIT

### Community Plugins
- **Repository:** github.com/sturdy-barnacle/tibok-plugins
- **Visibility:** Public
- **Purpose:** Official and community-contributed plugins

---

## SDK Contents

```
tibok-plugin-sdk/
├── README.md
├── LICENSE (MIT)
├── Package.swift
├── Sources/
│   └── tibokPluginSDK/
│       ├── Protocols/
│       │   ├── Plugin.swift
│       │   ├── ExporterPlugin.swift
│       │   ├── ThemePlugin.swift
│       │   ├── AIProviderPlugin.swift
│       │   └── ActionPlugin.swift
│       ├── Models/
│       │   ├── Document.swift
│       │   ├── PluginContext.swift
│       │   ├── ExportOptions.swift
│       │   └── ActionContext.swift
│       ├── Utilities/
│       │   ├── MarkdownParser.swift
│       │   └── HTMLRenderer.swift
│       └── Testing/
│           └── PluginTestCase.swift
├── Templates/
│   ├── ExporterTemplate/
│   ├── ThemeTemplate/
│   ├── AIProviderTemplate/
│   └── ActionTemplate/
├── Examples/
│   ├── HugoExporter/
│   ├── NordTheme/
│   ├── OllamaProvider/
│   └── WordCountAction/
└── Documentation/
    ├── GettingStarted.md
    ├── PluginTypes.md
    ├── APIReference.md
    ├── Security.md
    └── Publishing.md
```

---

## Plugin Types

### 1. Exporter Plugins

Export markdown to external formats or platforms.

**Use cases:**
- Static site generators (Hugo, Gatsby, Eleventy)
- CMS platforms (Notion, Ghost, WordPress)
- Document formats (DOCX, EPUB, LaTeX)

**SDK Protocol:**
```swift
public protocol ExporterPlugin: Plugin {
    var exporterInfo: ExporterInfo { get }
    var supportedFormats: [ExportFormat] { get }
    var configurationView: AnyView? { get }

    func export(
        document: Document,
        options: ExportOptions,
        context: PluginContext
    ) async throws -> ExportResult

    func validate(document: Document) -> [ValidationIssue]
}
```

### 2. Theme Plugins

Custom visual themes for editor and preview.

**Use cases:**
- Color schemes (Nord, Dracula, Solarized)
- Typography presets
- Custom preview CSS

**SDK Protocol:**
```swift
public protocol ThemePlugin: Plugin {
    var themeInfo: ThemeInfo { get }
    var previewCSS: String { get }
    var editorColorScheme: EditorColorScheme { get }
    var syntaxTheme: SyntaxTheme { get }

    func previewHTML(for document: Document) -> String?
}
```

### 3. AI Provider Plugins

Alternative AI backends for writing assistance.

**Use cases:**
- OpenAI GPT models
- Local LLMs (Ollama, LM Studio)
- Custom AI services

**SDK Protocol:**
```swift
public protocol AIProviderPlugin: Plugin {
    var providerInfo: AIProviderInfo { get }
    var requiresAPIKey: Bool { get }
    var configurationView: AnyView? { get }

    func complete(
        prompt: String,
        context: AIContext
    ) async throws -> AsyncStream<String>

    func suggest(
        text: String,
        type: SuggestionType
    ) async throws -> [Suggestion]

    func isAvailable() async -> Bool
}
```

### 4. Action Plugins

Custom commands for the command palette.

**Use cases:**
- Text transformations
- External tool integration
- Workflow automation

**SDK Protocol:**
```swift
public protocol ActionPlugin: Plugin {
    var actionInfo: ActionInfo { get }
    var actions: [PluginAction] { get }

    func execute(
        action: PluginAction,
        context: ActionContext
    ) async throws -> ActionResult

    func isEnabled(for context: ActionContext) -> Bool
}
```

---

## Getting Started

### Prerequisites

- macOS 14+
- Xcode 16+
- Swift 5.9+
- tibok (for testing)

### Create a New Plugin

```bash
# Clone the SDK
git clone https://github.com/sturdy-barnacle/md-editor-plugin-sdk.git

# Use a template
cp -r tibok-plugin-sdk/Templates/ExporterTemplate MyExporter
cd MyExporter

# Update Package.swift with your plugin name
# Implement your plugin
# Build and test
swift build
swift test
```

### Package.swift Example

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyExporter",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "MyExporter", type: .dynamic, targets: ["MyExporter"])
    ],
    dependencies: [
        .package(url: "https://github.com/sturdy-barnacle/md-editor-plugin-sdk.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "MyExporter",
            dependencies: [
                .product(name: "tibokPluginSDK", package: "tibok-plugin-sdk")
            ]
        ),
        .testTarget(
            name: "MyExporterTests",
            dependencies: ["MyExporter"]
        )
    ]
)
```

---

## Plugin Manifest

Every plugin requires a `plugin.json` manifest:

```json
{
    "id": "com.yourname.my-exporter",
    "name": "My Exporter",
    "version": "1.0.0",
    "minAppVersion": "1.0.0",
    "type": "exporter",
    "entryPoint": "MyExporter",
    "author": {
        "name": "Your Name",
        "email": "you@example.com",
        "url": "https://yoursite.com"
    },
    "description": "Export markdown to my custom format",
    "permissions": ["filesystem", "network"],
    "repository": "https://github.com/yourname/my-exporter",
    "license": "MIT",
    "keywords": ["export", "custom"],
    "screenshots": [
        "screenshots/preview.png"
    ]
}
```

### Permissions

| Permission | Description | When Required |
|------------|-------------|---------------|
| `filesystem` | Read/write files outside document | Exporters saving to disk |
| `network` | Make HTTP requests | API integrations |
| `keychain` | Store credentials | AI providers, authenticated services |
| `clipboard` | Access clipboard | Copy/paste operations |
| `notifications` | Show system notifications | Background tasks |

---

## Testing Plugins

### Unit Testing

```swift
import XCTest
import tibokPluginSDK

final class MyExporterTests: XCTestCase {
    var plugin: MyExporter!

    override func setUp() {
        plugin = MyExporter()
    }

    func testExportSimpleDocument() async throws {
        let doc = Document(content: "# Hello\n\nWorld")
        let options = ExportOptions()
        let context = PluginContext.mock()

        let result = try await plugin.export(
            document: doc,
            options: options,
            context: context
        )

        XCTAssertTrue(result.success)
        XCTAssertNotNil(result.outputURL)
    }
}
```

### Integration Testing

Install your plugin in tibok's development mode:

```bash
# Build plugin bundle
swift build -c release

# Copy to tibok plugins folder
cp -r .build/release/MyExporter.bundle \
    ~/Library/Application\ Support/tibok/Plugins/

# Restart tibok to load the plugin
```

---

## Publishing

### Plugin Gallery Submission

1. **Prepare your plugin:**
   - Complete plugin.json with all metadata
   - Add screenshots and README
   - Ensure all tests pass
   - Sign your plugin (optional but recommended)

2. **Submit for review:**
   - Fork github.com/sturdy-barnacle/tibok-plugins
   - Add your plugin to the `plugins/` directory
   - Create a pull request with:
     - Plugin description
     - Test results
     - Screenshots

3. **Review process:**
   - Automated security scan
   - Code review by tibok team
   - Testing on latest tibok version

4. **Publication:**
   - Merged plugins appear in tibok's Plugin Gallery
   - Listed on tibok.app/plugins

### Self-Distribution

You can also distribute plugins directly:
- Host on GitHub Releases
- Provide `.tibokplugin` bundle download
- Users install via drag-and-drop

---

## Security Guidelines

### Required Practices

- [ ] Declare all permissions in manifest
- [ ] Never hardcode credentials
- [ ] Use Keychain for sensitive data
- [ ] Validate all user input
- [ ] Handle errors gracefully

### Prohibited Actions

- ❌ Accessing files outside sandbox without permission
- ❌ Making network requests without `network` permission
- ❌ Collecting user data without disclosure
- ❌ Obfuscating malicious code
- ❌ Circumventing tibok's security model

### Code Signing

Optional but recommended for trust:

```bash
# Sign your plugin bundle
codesign --sign "Developer ID Application: Your Name" \
    --options runtime \
    MyExporter.tibokplugin
```

---

## Developer Portal

**URL:** tibok.app/developers

### Resources

- Plugin SDK documentation
- API reference
- Sample plugins
- Video tutorials
- Community forum

### Developer Program

Free tier:
- SDK access
- Plugin Gallery submission
- Community support

Verified Developer ($99/year):
- Priority review
- Featured placement
- Revenue sharing (future)
- Direct support

---

## Community

### GitHub Discussions

github.com/sturdy-barnacle/tibok-plugin-sdk/discussions

- Q&A for plugin development
- Share plugins and ideas
- Request features

### Discord

discord.gg/tibok (future)

- #plugin-dev channel
- Real-time help
- Plugin announcements

---

## Roadmap

### v1.0 (Launch)
- Core SDK protocols
- 4 plugin types
- Basic documentation
- 5+ example plugins

### v1.1
- Plugin settings UI framework
- Inter-plugin communication
- Enhanced testing utilities

### v1.2
- Plugin marketplace in-app
- Revenue sharing for paid plugins
- Analytics for developers

---

## License

The tibok Plugin SDK is released under the MIT License.

Plugins you create are yours - choose any license you prefer.

---

**Last Updated:** 2024-12-13
