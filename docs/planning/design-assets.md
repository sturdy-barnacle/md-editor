# Design Assets Reference

> Visual design mockups and icon specifications for tibok

## Overview

This document serves as the central reference for all design assets located in the `/design_docs` folder. These React/JSX mockups define the visual specifications for tibok across all release milestones.

---

## Asset Inventory

| Asset | Path | Purpose |
|-------|------|---------|
| Icon Set | `design_docs/tibok icons logos.jsx` | App icons and logo variants |
| MVP Mockup | `design_docs/tibok ui mockups/mvp-v0.1.jsx` | MVP UI design |
| Beta Mockup | `design_docs/tibok ui mockups/beta-v0.5.jsx` | Beta UI design |
| v1.0 Mockup | `design_docs/tibok ui mockups/v1.0.jsx` | Full release UI design |

---

## App Icons (`tibok icons logos.jsx`)

### Icon Variants

| Variant | Design | Usage |
|---------|--------|-------|
| **Primary** | `#` muted + `t` bold | App icon, dock, marketing |
| **One Color** | `#t` solid | Monochrome contexts, favicons |
| **Accent (Open)** | `<t>` | Documentation, alternate branding |
| **Accent (Close)** | `</t>` | Documentation, alternate branding |

### Technical Specifications

| Property | Value |
|----------|-------|
| Font | Open Sans SemiBold (600) |
| Available Sizes | 16, 24, 32, 48, 64, 96, 128px |
| ViewBox | 0 0 512 512 |
| Corner Radius | 113px (~22%) |
| Shadow | drop-shadow(0 4px 12px rgba(0,0,0,0.1)) |

### Color Specifications

**Light Mode:**
| Element | Color | Hex |
|---------|-------|-----|
| Background | Warm White | #FAFAFA |
| Primary Text | Charcoal | #333333 |
| Muted Text (`#`) | Light Gray | #BBBBBB |

**Dark Mode:**
| Element | Color | Hex |
|---------|-------|-----|
| Background | Dark Gray | #2D2D2D |
| Primary Text | White | #FFFFFF |
| Muted Text (`#`) | Medium Gray | #666666 |

### Icon with Logotype

The icon pairs with the "tibok" wordmark:
- Font: Open Sans SemiBold (600)
- Size: 24px (2x icon size at 48px)
- Style: All lowercase

---

## MVP UI Mockup (`mvp-v0.1.jsx`)

**Release Target:** v0.1 - Core editing experience

### Layout Structure

```
┌─────────────────────────────────────────────────────────────────┐
│ ● ● ●     filename.md — workspace        [Sidebar][Preview][Export][Settings]  │  Title Bar (48px)
├──────────┬──────────────────────────────┬───────────────────────┤
│ Search   │  Editor                      │  Preview              │
│ ──────── │  ┌────┬───────────────────┐  │  ┌─────────────────┐  │
│ WORKSPACE│  │ Ln │ # Heading         │  │  │ Heading         │  │
│ ▼ docs/  │  │ 1  │ Content here...   │  │  │ Content here... │  │
│   file.md│  │ 2  │                   │  │  │                 │  │
│ ▼ _posts/│  │ 3  │                   │  │  │                 │  │
│   post.md│  └────┴───────────────────┘  │  └─────────────────┘  │
│ RECENT   │                              │                       │
│ recent.md│                              │                       │
│ ──────── │                              │                       │
│[+ New Doc]│                              │                       │
├──────────┴──────────────────────────────┴───────────────────────┤
│ Ln 1, Col 1 │ words │ chars │ UTF-8 │ Markdown │ ● Saved        │  Status Bar (24px)
└─────────────────────────────────────────────────────────────────┘
```

### Components Defined

| Component | Specifications |
|-----------|---------------|
| **Title Bar** | 48px height, traffic lights, file name, toolbar buttons |
| **Sidebar** | 220px width, search field, file tree, recent files, new document button |
| **File Tree** | Expandable folders, file icons, modified indicator (blue dot) |
| **Editor** | Line numbers gutter (40px), monospace font, syntax highlighting |
| **Preview** | Rendered HTML, max-width 672px (2xl), 24px padding |
| **Status Bar** | 24px height, position, word count, char count, encoding, language, save status |
| **Export Menu** | Dropdown: PDF, HTML, Copy as Markdown |

### Syntax Highlighting (Editor)

| Element | Style |
|---------|-------|
| H1 (`# `) | Bold, text-gray-900 |
| H2 (`## `) | SemiBold, text-gray-800 |
| Blockquote (`> `) | text-gray-500 |
| List markers | text-blue-600 |
| Code fence | text-purple-600 |
| Horizontal rule | text-gray-400 |
| Bold (`**`) | font-bold text-gray-900 |
| Italic (`*`) | italic text-gray-800 |
| Inline code | text-pink-600 bg-pink-50 |
| Links | text-blue-600 |

---

## Beta UI Mockup (`beta-v0.5.jsx`)

**Release Target:** v0.5 - Power user features

### New Components (Additions to MVP)

#### Tab Bar
- Height: 36px
- Tab styling: rounded-t-md, active tab has white bg with border
- Modified indicator: blue dot after filename
- Close button (X) on each tab
- Plus button for new tab

#### Command Palette (⌘K)
- Dimensions: 500px wide, max 400px tall
- Centered horizontally, 96px from top
- Search input with icon
- Grouped by category: Recent, Editor, View, Git, Export
- Each command shows: icon, label, keyboard shortcut
- Keyboard hint: `esc` to dismiss

**Commands Defined:**
| Category | Commands |
|----------|----------|
| Recent | New Document (⌘N), Save (⌘S) |
| Editor | Toggle Bold (⌘B), Toggle Italic (⌘I), Insert Link (⌘K), Insert Image (⌘⇧I) |
| View | Toggle Preview (⌘\\), Toggle Sidebar (⌘⇧\\) |
| Git | Commit Changes (⌘⇧C), Push (⌘⇧P), Pull (⌘⇧U) |
| Export | Export as PDF (⌘⇧E), Export as HTML |

#### Slash Command Menu
- Width: 256px, max height 320px
- Appears at cursor position after typing `/`
- Filter input at top
- First item auto-selected (blue highlight)
- Shows: icon, label, command

**Slash Commands Defined:**
| Command | Label | Insert |
|---------|-------|--------|
| /h1 | Heading 1 | `# ` |
| /h2 | Heading 2 | `## ` |
| /h3 | Heading 3 | `### ` |
| /table | Table | Table template |
| /code | Code Block | Fenced code block |
| /link | Link | `[text](url)` |
| /image | Image | `![alt](url)` |
| /list | Bullet List | List template |
| /task | Task List | Checkbox list |
| /quote | Blockquote | `> ` |
| /hr | Divider | `---` |
| /date | Date | ISO date string |
| /emoji | Emoji | `:emoji:` |

#### Git Panel
- Width: 288px (w-72)
- Header: "Source Control" with close button
- Branch selector with dropdown
- Pull/Push buttons
- Staged changes section with count
- Unstaged changes section with count
- Commit message input
- Commit button with shortcut (⌘⇧C)

**Git Status Colors:**
| Status | Color | Indicator |
|--------|-------|-----------|
| Modified | Blue (#3B82F6) | M |
| Staged | Green (#22C55E) | (in staged section) |
| Untracked | Yellow (#EAB308) | U |

#### Status Bar Additions
- Git branch indicator (purple, GitBranch icon)

---

## v1.0 UI Mockup (`v1.0.jsx`)

**Release Target:** v1.0 - Full release

### New Components (Additions to Beta)

#### AI Panel
- Width: 50% when preview open, 320px otherwise
- Gradient background: purple-50 to white
- Header: "AI Assistant" with Pro badge
- Action buttons grid (2x2):
  - Improve (purple, primary)
  - Continue
  - Summarize
  - Translate
- Suggestions list with type indicators:
  - Clarity (blue dot)
  - Style (purple dot)
  - Structure (green dot)
- Each suggestion shows: location, text, chevron
- Custom prompt input at bottom
- Credit counter: "47 credits remaining • Add API Key"

#### AI Suggestion Detail
- Shows original text (red, strikethrough)
- Shows suggested text (green)
- Explanation text
- Apply/Dismiss buttons

#### Frontmatter Bar
- Background: amber-50, border: amber-200
- Shows: FileCode icon, "Frontmatter" label
- Date with Calendar icon
- Tags with Tag icon
- "Edit →" button

#### Cloud Sync Status (Title Bar)
| Status | Icon | Color | Text |
|--------|------|-------|------|
| Synced | Cloud | Green | "Synced" |
| Syncing | RefreshCw (animated) | Blue | "Syncing" |
| Conflict | AlertCircle | Orange | "Conflict" |
| Offline | CloudOff | Gray | "Offline" |

#### Pro Badge
- Gradient: amber-400 to orange-500
- Crown icon + "Pro" text
- Rounded full (pill shape)

#### Publish Button
- Green background (#16A34A)
- Send icon + "Publish" text

#### Jekyll Publish Modal
- Width: 500px
- Header: Send icon + "Publish to Jekyll"
- Form fields:
  - Post Title (text input)
  - Date (date picker)
  - Category (select)
  - Tags (removable chips + input)
- Repository info section (gray-50 background)
- "Create Pull Request" checkbox
- Webhook indicator (yellow-50 background)
- Actions: Cancel, "Publish & Create PR"

#### Sidebar Additions
**Quick Actions Section:**
- AI Improve Writing (Sparkles icon, purple)
- Publish to Jekyll (Globe icon, green)
- Run Webhook (Zap icon, yellow)

**iCloud Drive Section:**
- Cloud icon in header
- Per-file sync status: Check (synced), RefreshCw (syncing), AlertCircle (conflict)

**Plugins Section:**
- Puzzle icon in header
- Installed plugins with icon squares
- "Browse Plugins..." button

#### Status Bar Additions
- AI Ready indicator (Sparkles icon, purple)
- Cloud sync status (Cloud icon, green)

---

## Implementation Notes

### When to Reference These Mockups

- **MVP Development**: Reference `mvp-v0.1.jsx` for all Phase 1-5 features
- **Beta Development**: Reference `beta-v0.5.jsx` for command palette, slash commands, git integration, tabs
- **v1.0 Development**: Reference `v1.0.jsx` for AI, publishing, cloud sync, plugins

### Color System Alignment

The mockups use Tailwind CSS classes which map to:
- `gray-50`: #F9FAFB (backgrounds)
- `gray-100`: #F3F4F6 (title bar, status bar)
- `gray-200`: #E5E7EB (borders)
- `gray-400`: #9CA3AF (muted text, icons)
- `gray-600`: #4B5563 (secondary text)
- `gray-700`: #374151 (primary text)
- `blue-500/600`: #3B82F6/#2563EB (accent, links)
- `purple-500/600`: #8B5CF6/#7C3AED (AI features)
- `green-500/600`: #22C55E/#16A34A (success, publish)

### Font Stack

Mockups specify:
```css
font-family: '-apple-system, BlinkMacSystemFont, sans-serif'
```

For production, use Open Sans as documented in branding.md, falling back to system fonts.

---

**Last Updated:** 2024-12-13
