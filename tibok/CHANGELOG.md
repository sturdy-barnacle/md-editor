# Changelog

## Beta v0.6 (In Progress)

### Multiple Open Files (Tabs)
- Tab bar always visible when documents are open
- Keyboard navigation: ⌘1-9 to switch tabs, ⌘⇧[ / ⌘⇧] for prev/next
- Close tab (⌘W) and reopen last closed tab (⌘⇧T)
- Drag and drop to reorder tabs
- Right-click context menu on tabs

### Git Integration
- Git status indicators in sidebar (modified, added, deleted files)
- Stage/unstage files and hunks
- Commit with message (⌘⇧K)
- Push and pull from remote
- Git menu in menu bar
- Branch indicator in status bar

### Plugin System Phase 1
- Plugin protocol with lifecycle management
- Enable/disable plugins from Settings > Plugins
- Core Slash Commands as built-in plugin
- Command source tracking for clean unregistration
- Plugin state persists across app restarts (UserDefaults)
- Plugin metadata: name, version, author, icon
- PluginManager with reload functionality

### Frontmatter Editor
- Visual inspector panel for Jekyll/Hugo metadata (⌘I)
- **YAML format** support with `---` delimiters (Jekyll/Hugo)
- **TOML format** support with `+++` delimiters (Hugo)
- Common fields: title, date, author, layout, draft, description, tags, categories
- Custom field support (any key-value pairs)
- **Date & Time mode** with timezone support
  - Timezone configuration in Settings > Frontmatter
  - ISO 8601 format with timezone offset: `2025-01-15T10:30:00-08:00`
  - Date-only mode: `2025-01-15`
- Default values configurable in Settings
- Live sync between inspector and document
- Frontmatter automatically hidden in preview

### Webhooks
- HTTP request triggers on document events
- **Supported events**: Document Save, Document Export, Git Push
- **Configurable HTTP methods**: GET, POST, PUT, DELETE
- **Template variables** for dynamic payloads:
  - `{{event}}` - Event type (e.g., `document.save`)
  - `{{filename}}` - Document filename
  - `{{title}}` - Document title (from frontmatter or filename)
  - `{{path}}` - Full file path
  - `{{timestamp}}` - ISO 8601 timestamp
  - `{{content}}` - Document content (JSON-escaped)
- Custom headers support (authentication, content-type)
- Test button for validation before deployment
- Enable/disable individual webhooks
- 30-second timeout for requests
- Settings > Webhooks for management

### Markdown Formatting Shortcuts
- **Cmd+B**: Bold text (`**text**`)
- **Cmd+Shift+I**: Italic text (`*text*`)
- **Cmd+E**: Inline code (`` `code` ``)
- **Cmd+Shift+X**: Strikethrough (`~~text~~`)
- **Cmd+L**: Link (`[text](url)`)
- Auto-wraps selected text or inserts placeholder when no selection
- **Intelligent cursor positioning**:
  - With selection: Wrapped text stays selected for chaining (e.g., bold → italic)
  - Link shortcut: Selects URL placeholder for immediate editing
  - No selection: Placeholder text selected for quick replacement
- Accessible via Format menu

### Image Handling Improvements
- **Multi-format paste support**: Preserves GIF, PNG, JPEG when copying files from Finder
- **Smart format detection**: Automatically detects and preserves original image format
- **TIFF conversion**: Converts TIFF to PNG for better web compatibility
- **Cursor positioning**: Automatically places cursor in alt text field `![|](path)` for accessibility
- **Visual feedback**: Toast notifications for all image operations
  - Success: "Image saved to assets/filename"
  - Warnings: "Save document to paste images", "Using absolute path"
  - Errors: "Failed to save image" with specific error details
- **Export notifications**: Contextual warnings for PDF/HTML exports with images
- **Assets folder notification**: Alerts when assets folder is created

### Nested Lists
- Support for up to 3 levels of nesting (parent → child → grandchild)
- 2-space indentation per level
- Mix ordered and unordered lists at any level
- Task lists can be nested
- Proper HTML rendering with correct tag nesting
- CSS styling for nested list spacing

### Other Improvements
- Print support (⌘P) with styled output
- Offline math/LaTeX rendering with bundled KaTeX
- Emoji picker with `:shortcode:` syntax (fixed crash with UTF-16 surrogate pairs)
- **Package.swift cleanup** - Fixed KaTeX resource warnings (23 files)
- Syntax highlighting performance fix (color-only attributes)

---

## Beta v0.5

### Phase 1: Command System
- Command palette accessible via ⌘K
- Fuzzy search with word boundary bonuses
- Recent command tracking
- 12 registered commands across File, View, Edit, and Export categories
- Keyboard navigation (↑↓ arrows, Enter to execute, Esc to cancel)
- Fixed scroll behavior when navigating to bottom items

### Phase 2: Slash Commands
- 25 slash commands triggered by `/` at start of line
- Floating menu with keyboard navigation (↑↓ arrows, Enter to select)
- Intelligent cursor positioning with {{CURSOR}} placeholders
- Dynamic date/time formatting with {{DATE:format}} and {{TIME:format}}
- Date picker with calendar UI (`/pickdate`)
- Hover and click selection support

**Available Commands:**
- Headings: h1, h2, h3
- Blocks: table, code, quote, callout, collapse
- Links & Media: link, image, footnote
- Lists: list, numbered, task
- Inline: bold, italic, strikethrough, inlinecode, highlight
- Structure: hr, toc
- Date/Time: date, datelong, time, datetime, pickdate

### Preview Rendering
- HTML passthrough for `<details>`, `<summary>`, and other block elements
- GitHub-style callouts: `> [!NOTE]`, `> [!TIP]`, `> [!WARNING]`, `> [!IMPORTANT]`, `> [!CAUTION]`
  - Renders as cohesive blocks with proper styling
- Highlight syntax: `==text==`
- Dark mode support for all new elements
- **Table support** - Full markdown table parsing with header/body rows
- **Footnotes** - `[^ref]` references with linked footnotes section
- **Table of Contents** - `[[toc]]` generates navigable TOC from headers
- **H5/H6 headers** - Complete heading support (h1-h6)

### Image Handling
- Drag & drop images into editor
- Paste images from clipboard
- Automatic `assets` folder creation next to document
- Unique filename generation to avoid conflicts
- Relative paths for portability: `![](./assets/image.png)`
- Supported formats: PNG, JPG, JPEG, GIF, WEBP, SVG, BMP, TIFF

### Sidebar Improvements
- Collapsible sections (Workspace, Recent) with persistent state
- **Open File button** between Workspace and Recent sections
- Right-click context menus for all files and folders:
  - Open, Rename, Reveal in Finder, Copy Path, Move to Trash
- Remove individual items from Recent files list
- Clear all recent files option
- Workspace folder context menu with Reveal in Finder

### UI Polish
- **Custom title bar** replacing SwiftUI toolbar for cleaner appearance
- Borderless toolbar icons with hover effects
- Dark mode toggle in title bar (System/Light/Dark)
- Dark mode setting persists across launches
- Dynamic window title: "tibok — filename.md"
- Settings > General > Appearance picker

### Help Menu
- **tibok Help** (⌘?) - Opens main documentation
- **Keyboard Shortcuts** - Opens keyboard shortcuts reference
- **Slash Commands Reference** - Opens slash commands guide
- **Report an Issue...** - Links to GitHub issues

### App Icon
- **Liquid Glass icon** with macOS Tahoe style
- Multi-layer design with translucent glass effects
- Fallback `.icns` for older macOS versions

## MVP v0.1 (Complete)

### Core Editor
- NSTextView-based editor with monospace font
- Real-time markdown preview using swift-markdown and Highlightr
- Native find/replace (⌘F, ⌘⌥F)
- Document state management with modification tracking

### File Management
- New document (⌘N)
- Open file (⌘O)
- Open folder (⌘⇧O) with sidebar file tree
- Save (⌘S) and Save As (⌘⇧S)
- Auto-expand markdown files on folder open

### Export
- Export as PDF
- Export as HTML
- Copy as Markdown

### UI
- Three-pane layout: Sidebar, Editor, Preview
- Toggle preview (⌘\)
- Status bar with line/column, word count, character count
- Settings panel (appearance, font size, tab width)
