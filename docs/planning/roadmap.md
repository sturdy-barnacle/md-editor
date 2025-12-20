# tibok Roadmap

## Current: Beta v0.6 (In Progress)

### Completed Features
- Command palette (⌘K)
- Slash commands (35+ commands)
- Image drag & drop and paste
- Custom title bar with borderless icons
- Dark mode toggle
- Help menu with in-app documentation
- Liquid Glass app icon
- Sidebar improvements (collapsible sections, context menus, content search)
- Preview enhancements (tables, footnotes, TOC, callouts, math/LaTeX)
- Print support (⌘P)
- Offline math rendering (bundled KaTeX)
- **Multiple Open Files (Tabs)** - Tab bar, keyboard shortcuts (⌘1-9, ⌘⇧[/]), close/reopen tabs
- **Git Integration** - Status indicators, staging, commits, push/pull, Git menu
- **Plugin System Phase 1** - Enable/disable plugins, command source tracking, persistence
- **Frontmatter Editor** - Jekyll/Hugo YAML/TOML support with timezone-aware dates
- **Webhooks** - HTTP triggers on document events with template variables

### Before Release
- [x] Update placeholder URLs in `SettingsView.swift` (AppURLs enum) and `tibokApp.swift`:
  - Issues: `https://github.com/sturdy-barnacle/md-editor/issues`
  - Website: `https://tibok.app`
- [ ] Address KaTeX resource warnings in Package.swift
- [ ] QA testing for plugin, webhook, and frontmatter features

## Next: v0.7 - Quick Wins

### Short-term Enhancements
- [ ] Built-in Plugin: Table of Contents Generator
  - Auto-generate TOC from document headings
  - Insert at cursor or top of document
  - Configurable heading depth (H1-H6)
- [ ] Built-in Plugin: Word Count & Reading Time
  - Live statistics in status bar
  - Selection word count
  - Estimated reading time
- [ ] Webhook: Git Commit Event
  - Trigger webhooks on Git commits
  - Include commit hash, message, files changed
- [ ] Frontmatter: Blog Post Templates
  - Quick insert templates for common post types
  - Customizable template library
- [ ] Export: Copy as Rich Text
  - Preserve formatting when copying to other apps
  - Useful for emails, Notion, etc.

## Future: v1.x+

### Plugin System Phase 1 (Completed)
- [x] Plugin protocol and lifecycle management
- [x] Enable/disable plugins from Settings
- [x] Core Slash Commands as built-in plugin
- [x] Command source tracking and unregistration

### Plugin System Phase 2
- [ ] Plugin discovery from `~/Library/Application Support/tibok/Plugins/`
- [ ] JSON manifest for plugin metadata
- [ ] External plugin loading (sandboxed)
- [ ] Plugin API versioning
- [ ] Plugin developer documentation
- [ ] Sample plugin templates

### Plugin System Security & Architecture
- [ ] Plugin sandboxing (separate process or XPC service)
- [ ] Permission system for file/network access
- [ ] Code signing verification for external plugins
- [ ] API stability guarantees
- [ ] Migration strategy for plugin state/settings

### Cloud Sync
- [ ] Sync documents across devices
- [ ] Conflict resolution
- [ ] Offline support

### Publishing
- [x] Jekyll/Hugo frontmatter editor
- [x] Webhooks for build triggers
- [ ] Direct publish to GitHub Pages
- [ ] Blog post templates
- [ ] One-click deployment workflows

### Additional Features
- [ ] Split editor view
- [ ] Focus mode (highlight current paragraph)
- [ ] Custom themes
- [ ] Export to more formats (DOCX, EPUB)
