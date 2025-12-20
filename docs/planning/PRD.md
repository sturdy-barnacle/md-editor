# Product Requirements Document: tibok

## Product Overview

**Product Name:** tibok
**Platform:** macOS (Apple Silicon)
**Version:** 1.0
**Website:** tibok.app
**Repository:** github.com/sturdy-barnacle/md-editor

tibok is a native macOS markdown editor designed for writers, developers, and content creators who need a fast, distraction-free writing environment with powerful publishing integrations.

---

## Problem Statement

Existing markdown editors either:
- Lack native macOS performance and integration (Electron-based)
- Miss critical publishing workflows (Jekyll, GitHub, webhooks)
- Require constant internet connectivity (cloud-first)
- Overwhelm users with features they don't need

**Our solution:** A local-first, native markdown editor that feels like it belongs on macOS while providing seamless paths to publish content anywhere.

---

## Target Users

### Primary: Technical Writers & Developers
- Write documentation, READMEs, blog posts
- Use Git for version control
- Value keyboard-driven workflows
- Need code syntax highlighting

### Secondary: Content Creators & Bloggers
- Publish to Jekyll/Hugo/static sites
- Want simple export options
- Prefer local file storage
- Need occasional AI writing assistance

---

## Core Features

### 1. Editor (P0 - Must Have)

| Feature | Description |
|---------|-------------|
| Markdown editing | Full CommonMark + GFM support |
| Syntax highlighting | Real-time markdown syntax colors |
| Line numbers | Optional, toggleable |
| Auto-save | Debounced save every 500ms |
| Find/Replace | Includes regex support |
| Multiple tabs | Work on multiple documents |
| Keyboard shortcuts | Standard macOS + custom bindings |

**Acceptance Criteria:**
- [ ] Opens .md files from Finder
- [ ] Typing latency < 16ms
- [ ] Undo/redo with ⌘Z / ⌘⇧Z
- [ ] Word count in status bar

### 2. Preview (P0 - Must Have)

| Feature | Description |
|---------|-------------|
| Live preview | Updates as you type |
| Split view | Horizontal or vertical split |
| Synced scrolling | Preview follows cursor position |
| Themes | Light/dark, customizable CSS |
| Separate window | Pop-out preview option |

**Acceptance Criteria:**
- [ ] Preview renders within 50ms of edit
- [ ] Toggle split view with ⌘\
- [ ] Code blocks have syntax highlighting
- [ ] Images render from relative paths

### 3. File Management (P0 - Must Have)

| Feature | Description |
|---------|-------------|
| Sidebar file tree | Browse folder contents |
| Recent files | Quick access to recent documents |
| Folder workspaces | Open entire folders |
| File operations | Create, rename, delete, move |
| Search in folder | Find files by name or content |

**Acceptance Criteria:**
- [ ] Drag folders onto app to open
- [ ] Security-scoped bookmarks persist access
- [ ] File tree updates on external changes

### 4. Quick Actions & Suggestions (P1 - Should Have)

| Feature | Description |
|---------|-------------|
| Command palette | ⌘K to access all actions |
| Slash commands | /table, /code, /link, /image |
| Link autocomplete | Suggests files, headings, URLs |
| Emoji picker | :emoji: shortcode completion |
| Snippet insertion | Custom reusable text blocks |

**Acceptance Criteria:**
- [ ] Command palette opens in < 100ms
- [ ] Fuzzy search for commands
- [ ] Recently used commands appear first

### 5. Export (P1 - Should Have)

| Feature | Description |
|---------|-------------|
| PDF export | Styled PDF with configurable margins |
| HTML export | Standalone HTML file |
| .md export | Copy with/without frontmatter |
| Batch export | Export entire folder |

**Acceptance Criteria:**
- [ ] PDF preserves code highlighting
- [ ] HTML includes embedded CSS
- [ ] Export dialog remembers last location

### 6. Git Integration (P1 - Should Have)

| Feature | Description |
|---------|-------------|
| Clone repository | Clone from URL |
| Commit changes | Stage and commit from app |
| Push/Pull | Sync with remote |
| Branch switching | View and switch branches |
| Diff view | See changes before commit |

**Acceptance Criteria:**
- [ ] SSH and HTTPS authentication
- [ ] Credentials stored in Keychain
- [ ] Commit message templates

### 7. Jekyll/Blog Publishing (P1 - Should Have)

| Feature | Description |
|---------|-------------|
| Frontmatter editor | GUI for YAML frontmatter |
| Jekyll export | Proper _posts format |
| PR creation | Push branch and open PR |
| Asset handling | Copy images to assets folder |

**Acceptance Criteria:**
- [ ] Auto-generates Jekyll filename format
- [ ] Frontmatter includes date, title, categories
- [ ] PR links directly to GitHub

### 8. Cloud Sync (P2 - Nice to Have)

| Feature | Description |
|---------|-------------|
| iCloud Drive | Automatic sync |
| Conflict resolution | Prompt on conflicts |
| Sync status | Visual indicator |

**Acceptance Criteria:**
- [ ] Works with iCloud Drive folder
- [ ] Shows sync status per file
- [ ] Offline editing works seamlessly

### 9. AI Assistance (P2 - Nice to Have)

| Feature | Description |
|---------|-------------|
| Writing suggestions | Grammar, style, clarity |
| Text completion | Continue writing from cursor |
| Summarization | Generate summary of document |
| Translation | Translate selected text |
| Custom prompts | User-defined AI actions |

**Acceptance Criteria:**
- [ ] API key stored in Keychain
- [ ] Streaming responses show progressively
- [ ] Works offline (graceful degradation)

### 10. Clipboard & Media (P1 - Should Have)

| Feature | Description |
|---------|-------------|
| Paste images | Clipboard → file → markdown |
| Screenshot capture | ⌘⇧4 integration |
| Drag and drop | Drop images into editor |
| Image compression | Optional size reduction |

**Acceptance Criteria:**
- [ ] Images saved to ./assets/ relative to document
- [ ] Automatic markdown link insertion
- [ ] Supports PNG, JPG, GIF, WebP

### 11. Webhooks (P2 - Nice to Have)

| Feature | Description |
|---------|-------------|
| Custom webhooks | HTTP calls on events |
| Triggers | Save, export, publish |
| Templates | Variable substitution in payload |
| Authentication | Bearer tokens, API keys |

**Acceptance Criteria:**
- [ ] Test webhook button
- [ ] Logs show success/failure
- [ ] Retry on failure (optional)

---

## Non-Functional Requirements

### Performance
- App launch: < 500ms
- File open (1MB): < 100ms
- Preview render: < 50ms
- Typing latency: < 16ms
- Memory (idle): < 100MB

### Security
- App Sandbox enabled
- Hardened Runtime for notarization
- Credentials in Keychain only
- No telemetry without consent

### Compatibility
- macOS 14 (Sonoma) minimum
- Apple Silicon native (Universal binary)
- Retina display support

### Accessibility
- Full VoiceOver support
- Keyboard navigation
- High contrast themes
- Adjustable font sizes

---

## User Interface

### Main Window Layout
```
┌─────────────────────────────────────────────────────────────┐
│  ◉ ◉ ◉  │  Document.md           │  ⚙️  │  Sync: ✓  │  📤  │
├─────────┼───────────────────────────────┼───────────────────┤
│         │                               │                   │
│  Files  │      Editor                   │    Preview        │
│         │                               │                   │
│  > src  │  # Hello World                │  Hello World      │
│    > _  │                               │  ═══════════      │
│  README │  This is **bold**             │  This is bold     │
│         │                               │                   │
├─────────┴───────────────────────────────┴───────────────────┤
│  Ln 1, Col 1  │  Words: 42  │  UTF-8  │  Markdown  │  main  │
└─────────────────────────────────────────────────────────────┘
```

### Command Palette
```
┌─────────────────────────────────────┐
│  🔍 Type a command...               │
├─────────────────────────────────────┤
│  📄 New Document            ⌘N      │
│  📂 Open Folder             ⌘O      │
│  💾 Save                    ⌘S      │
│  📤 Export as PDF           ⌘⇧E     │
│  🔀 Git: Commit             ⌘⇧C     │
│  🤖 AI: Improve Writing             │
└─────────────────────────────────────┘
```

---

## Release Milestones

### MVP (v0.1)
- Basic editor with syntax highlighting
- Live preview with split view
- Local file management
- PDF and HTML export

### Beta (v0.5)
- Git integration
- Command palette
- Slash commands
- Image paste/drop

### v1.0
- Jekyll publishing
- AI assistance
- Cloud sync
- Webhooks

---

## Success Metrics

| Metric | Target |
|--------|--------|
| Daily active users | 1,000 (6 months post-launch) |
| Crash-free sessions | > 99.5% |
| App Store rating | > 4.5 stars |
| Export success rate | > 99% |

---

## Decisions

### Platform Strategy
**Decision:** macOS-only

Focus exclusively on native macOS experience using SwiftUI. This allows:
- Full optimization for Apple Silicon
- Native macOS integrations (Keychain, iCloud, Shortcuts)
- Faster development without cross-platform compromises
- Best-in-class performance and UX

Cross-platform support is out of scope for the foreseeable future.

### Pricing Model
**Decision:** Freemium

| Tier | Price | Features |
|------|-------|----------|
| Free | $0 | Editor, preview, local storage, basic export (MD, HTML) |
| Pro | $29/year or $49 lifetime | AI assistance, Git integration, Jekyll publishing, webhooks, PDF export, themes |

This model allows:
- Low barrier to entry for new users
- Revenue from power users who need advanced features
- Sustainable development via recurring revenue option

### AI Features
**Decision:** Hybrid (bundled credits + BYOK)

- **Bundled credits:** Pro tier includes monthly AI credits for casual users (simpler onboarding)
- **BYOK (Bring Your Own Key):** Power users can add their own Claude/OpenAI API key for unlimited usage

Implementation:
- API keys stored securely in Keychain
- Usage tracking for bundled credits
- Graceful fallback when credits exhausted (prompt to add own key or upgrade)

### Plugin System
**Decision:** Include in v1.0

Build extensibility from the start to enable:
- Community-contributed exporters (Hugo, Notion, etc.)
- Custom themes and syntax highlighting
- Additional AI providers
- Workflow integrations

Plugin architecture will be documented in ARCHITECTURE.md.

---

## Appendix

### Keyboard Shortcuts (Default)

| Action | Shortcut |
|--------|----------|
| New document | ⌘N |
| Open | ⌘O |
| Save | ⌘S |
| Close tab | ⌘W |
| Toggle preview | ⌘\ |
| Command palette | ⌘K |
| Find | ⌘F |
| Find and replace | ⌘⇧F |
| Bold | ⌘B |
| Italic | ⌘I |
| Link | ⌘K (with selection) |
| Export | ⌘⇧E |
| Git commit | ⌘⇧C |

### Supported Markdown Extensions
- GitHub Flavored Markdown (GFM)
- Tables
- Task lists
- Strikethrough
- Autolinks
- Footnotes
- Math (KaTeX)
- Mermaid diagrams
