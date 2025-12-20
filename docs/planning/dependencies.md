# Swift Package Dependencies

> Research and specifications for third-party dependencies

## Overview

This document tracks all Swift packages needed for MD Editor, their versions, alternatives considered, and integration notes.

---

## Core Dependencies

### 1. Markdown Parsing

**Selected:** `swift-markdown` (Apple)

| Package | Maintainer | License | Stars | Notes |
|---------|------------|---------|-------|-------|
| swift-markdown | Apple | Apache 2.0 | 2.5k+ | Official Apple package, CommonMark compliant |
| Ink | John Sundell | MIT | 2.3k+ | Lightweight, fast, limited extensions |
| Down | Rob Phillips | MIT | 2.1k+ | Wraps cmark, good performance |
| Markdownosaur | Christian Selig | MIT | 300+ | AttributedString output, iOS focused |

**Rationale:** Apple's swift-markdown provides the best long-term stability, is actively maintained, and integrates well with Swift ecosystem. Supports CommonMark and can be extended for GFM.

**Package.swift:**
```swift
.package(url: "https://github.com/apple/swift-markdown.git", from: "0.3.0")
```

**Integration Notes:**
- Parse markdown to AST with `Document(parsing: text)`
- Walk AST with `MarkupWalker` for custom rendering
- Extend with custom `BlockDirective` for special syntax

---

### 2. Git Operations

**Selected:** `SwiftGit2`

| Package | Maintainer | License | Stars | Notes |
|---------|------------|---------|-------|-------|
| SwiftGit2 | SwiftGit2 | MIT | 1.9k+ | libgit2 wrapper, mature |
| Git (CLI) | System | N/A | N/A | Shell out to git command |
| ObjectiveGit | libgit2 | MIT | 900+ | Objective-C, older |

**Rationale:** SwiftGit2 provides native Swift bindings to libgit2, avoiding CLI dependency and enabling better error handling. Well-tested in production apps.

**Package.swift:**
```swift
.package(url: "https://github.com/SwiftGit2/SwiftGit2.git", from: "1.0.0")
```

**Integration Notes:**
- Requires libgit2 binary framework
- SSH support via libssh2
- Credential callbacks for Keychain integration
- Consider async wrappers for UI responsiveness

**Fallback:** If SwiftGit2 causes issues, can shell out to `git` CLI as backup.

---

### 3. Keychain Access

**Selected:** `KeychainAccess`

| Package | Maintainer | License | Stars | Notes |
|---------|------------|---------|-------|-------|
| KeychainAccess | kishikawa katsumi | MIT | 7.8k+ | Simple API, well maintained |
| Valet | Square | Apache 2.0 | 4k+ | More opinionated, iCloud sync |
| Security.framework | Apple | Built-in | N/A | Low-level, verbose API |

**Rationale:** KeychainAccess provides the simplest API for common operations while still supporting advanced features. Excellent documentation and wide adoption.

**Package.swift:**
```swift
.package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.0")
```

**Integration Notes:**
- Use separate keychain service per credential type
- Store: Git credentials, API keys, webhook secrets
- Enable iCloud sync only for user preference

---

### 4. Code Syntax Highlighting

**Selected:** `Highlightr`

| Package | Maintainer | License | Stars | Notes |
|---------|------------|---------|-------|-------|
| Highlightr | J.P. Illanes | MIT | 1.6k+ | highlight.js wrapper, 190+ languages |
| Splash | John Sundell | MIT | 1.7k+ | Swift-only, limited languages |
| TreeSitter | Tree-sitter | MIT | N/A | Powerful but complex setup |

**Rationale:** Highlightr supports the most languages via highlight.js, making it ideal for a general-purpose editor. Theme support matches our preview theming needs.

**Package.swift:**
```swift
.package(url: "https://github.com/raspu/Highlightr.git", from: "2.1.0")
```

**Integration Notes:**
- Use for code blocks in preview (WKWebView)
- Can generate NSAttributedString for editor
- Bundle only needed language definitions to reduce size
- Themes: atom-one-dark, github, nord, dracula

---

## Optional Dependencies

### 5. AI Integration (v1.0)

**Implemented:** Custom URLSession-based implementation for multi-provider support

**Supported Providers:**
- Claude (Anthropic) - API v2024-06-01
- OpenAI - v1/chat/completions
- Gemini (Google) - v1/v1beta
- Grok (xAI) - v1/chat/completions
- Mistral - v1/chat/completions
- Ollama - Local /api/generate

**Integration Notes:**
- Use async/await streaming with URLSession.shared.bytes
- Handle rate limiting gracefully
- Store API keys in Keychain
- Support multiple providers with unified interface
- SSE (Server-Sent Events) streaming for real-time responses

### 6. StoreKit 2 (v1.0)

**Built-in:** Apple StoreKit 2 framework

**Integration Notes:**
- Use new async/await APIs
- Product identifiers: `pro.monthly`, `pro.yearly`, `pro.lifetime`
- Transaction listener for purchase restoration

---

## Development Dependencies

### Testing

| Package | Purpose |
|---------|---------|
| Swift Testing | Unit tests (@Test, #expect) |
| ViewInspector | SwiftUI view testing |

### Linting & Formatting

| Tool | Purpose |
|------|---------|
| SwiftLint | Code style enforcement |
| SwiftFormat | Auto-formatting |

**SwiftLint Config (.swiftlint.yml):**
```yaml
disabled_rules:
  - line_length
  - function_body_length
opt_in_rules:
  - empty_count
  - closure_spacing
excluded:
  - .build
  - Packages
```

---

## Package.swift Template

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MDEditor",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MDEditor", targets: ["MDEditor"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-markdown.git", from: "0.3.0"),
        .package(url: "https://github.com/SwiftGit2/SwiftGit2.git", from: "1.0.0"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.0"),
        .package(url: "https://github.com/raspu/Highlightr.git", from: "2.1.0"),
    ],
    targets: [
        .executableTarget(
            name: "MDEditor",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown"),
                "SwiftGit2",
                "KeychainAccess",
                "Highlightr",
            ]
        ),
        .testTarget(
            name: "MDEditorTests",
            dependencies: ["MDEditor"]
        ),
    ]
)
```

---

## Dependency Review Checklist

Before adding any dependency:

- [ ] License compatible with App Store distribution
- [ ] Actively maintained (commits in last 6 months)
- [ ] macOS support confirmed
- [ ] No conflicting transitive dependencies
- [ ] Size impact acceptable
- [ ] Security audit (no known vulnerabilities)

---

## Notes

_Update this document when evaluating new dependencies or upgrading versions._

---

**Last Updated:** 2024-12-13
