# tibok User Documentation

Welcome to the tibok documentation. tibok is a native macOS markdown editor built for writers who love simplicity.

## Quick Start

1. **Create a document**: Cmd+N or File > New Document
2. **Write markdown**: Just start typing
3. **Use slash commands**: Type `/` at line start for quick formatting
4. **Open command palette**: Cmd+K for quick actions (grouped by category)
5. **Toggle preview**: Cmd+\ to see rendered output
6. **Edit frontmatter**: Cmd+I to open the inspector panel
7. **Save your work**: Cmd+S

## Interface

tibok features a clean, distraction-free interface:

- **Tab bar**: Always visible when documents are open
- **Sidebar**: Workspace, Favorites, Recent files, plus collapsible Git panel
- **Editor**: Full-width writing area (no header for maximum space)
- **Preview**: Live-updating rendered markdown
- **Inspector**: Frontmatter editor for Jekyll/Hugo metadata (Cmd+I)
- **Status bar**: Document stats, Git branch, and helpful shortcuts

## Documentation

### General
- [FAQ](FAQ.md) - Frequently asked questions
- [Brand Guidelines](brand-guidelines.md) - Visual identity and voice guidelines

### Features - Core
- [Slash Commands](features/slash-commands.md) - Quick formatting with `/` commands
- [Tab Management](features/tab-management.md) - Working with multiple open documents
- [Frontmatter Editor](features/frontmatter.md) - Jekyll/Hugo metadata editing
- [Image Handling](features/image-handling.md) - Drag, drop, and paste images
- [Workspace & Files](features/workspace.md) - File and folder management
- [Git Integration](features/git-integration.md) - Version control with Git
- [Preview](features/preview.md) - Live markdown preview
- [Find and Replace](features/find-replace.md) - Search and replace text
- [WordPress Publishing](features/wordpress-publishing.md) - Publish to WordPress via API or email
- [Plugins](features/plugins.md) - Enable/disable editor extensions
- [Webhooks](features/webhooks.md) - HTTP notifications on events
- [Keyboard Shortcuts](features/keyboard-shortcuts.md) - Complete shortcut reference

### Features - Advanced Topics
- [Session Persistence](features/session-persistence.md) - Automatic state restoration
- [Performance Optimizations](features/performance-optimizations.md) - Smart filtering and caching

### For Plugin Developers
- [Plugin Development Guide](features/plugin-development.md) - Complete guide to creating plugins
- [Plugin Template](features/plugin-template.md) - Starter template for plugin development
- [Plugin Security](features/plugin-security.md) - Security best practices for plugins

## Favorites

Mark important files for quick access:
- Right-click any file and select "Add to Favorites"
- Favorites appear in a dedicated sidebar section
- Remove with right-click > "Remove from Favorites"

## Getting Help

If you can't find an answer in these docs:
1. Check the [FAQ](FAQ.md)
2. Look for your feature in the sidebar
3. Report issues on GitHub

## Version

This documentation covers **tibok v1.0.2** - the current stable release.

### Release Notes

**v1.0.2** (2025-12-22) - Bug fixes and security improvements:
- Fixed keyboard input routing bug
- Fixed WordPress selection reverting to Jekyll
- Implemented EdDSA signature verification for secure auto-updates
- All releases now code-signed and notarized

For detailed changelog, see [CHANGELOG.md](../CHANGELOG.md)

### System Requirements

- **macOS 14.0 (Sonoma)** or later
- **Apple Silicon (ARM64)** processor
- **Internet connection** for auto-updates (Sparkle)
