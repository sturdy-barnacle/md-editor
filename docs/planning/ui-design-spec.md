# UI/UX Design Specification

> Visual design, layout, and interaction patterns for tibok

## Design Mockups

Interactive React/JSX mockups are available in the `/design_docs` folder:

| Mockup | Path | Release |
|--------|------|---------|
| MVP | `design_docs/tibok ui mockups/mvp-v0.1.jsx` | v0.1 |
| Beta | `design_docs/tibok ui mockups/beta-v0.5.jsx` | v0.5 |
| Full Release | `design_docs/tibok ui mockups/v1.0.jsx` | v1.0 |

See `planning/design-assets.md` for detailed component specifications extracted from these mockups.

---

## Design Principles

1. **Native Feel** - Look and behave like a first-party macOS app
2. **Content First** - Minimize chrome, maximize writing space
3. **Progressive Disclosure** - Simple by default, powerful when needed
4. **Keyboard Driven** - Every action accessible via keyboard
5. **Dark Mode Ready** - Full support for light and dark appearances

---

## Color Palette

### System Colors (Preferred)

Use semantic system colors for automatic dark mode support:

| Usage | Light | Dark | SwiftUI |
|-------|-------|------|---------|
| Background | White | #1E1E1E | `.background` |
| Secondary BG | #F5F5F5 | #2D2D2D | `.secondarySystemBackground` |
| Text | #000000 | #FFFFFF | `.primary` |
| Secondary Text | #6B6B6B | #8E8E93 | `.secondary` |
| Accent | System Blue | System Blue | `.accentColor` |
| Border | #E5E5E5 | #3D3D3D | `.separator` |

### Syntax Highlighting (Editor)

| Element | Light Mode | Dark Mode |
|---------|------------|-----------|
| Heading | #1A1A1A bold | #FFFFFF bold |
| Bold | #1A1A1A bold | #FFFFFF bold |
| Italic | #1A1A1A italic | #FFFFFF italic |
| Code | #D73A49 | #F97583 |
| Link | #0366D6 | #58A6FF |
| Link URL | #6A737D | #8B949E |
| Blockquote | #6A737D | #8B949E |
| List marker | #0366D6 | #58A6FF |

---

## Typography

### Primary Font: Open Sans

**Source:** https://fonts.google.com/specimen/Open+Sans
**License:** Open Font License (OFL)

Open Sans is the primary UI font for tibok, providing a clean, modern, and highly readable experience.

### Editor Font

| Property | Value |
|----------|-------|
| Default Font | SF Mono |
| Fallback | Fira Code, Menlo, Monaco |
| Size | 14px (user configurable: 10-24px) |
| Line Height | 1.6 |
| Letter Spacing | 0 |

*Note: Editor uses monospace font for code editing; Open Sans is used in editor chrome (toolbar, status bar).*

### Preview Font

| Property | Value |
|----------|-------|
| Body Font | Open Sans |
| Fallback | -apple-system, sans-serif |
| Code Font | SF Mono, Fira Code |
| H1 Size | 32px (Bold 700) |
| H2 Size | 24px (SemiBold 600) |
| H3 Size | 20px (SemiBold 600) |
| Body Size | 16px (Regular 400) |
| Line Height | 1.7 |

### UI Font

Open Sans throughout the interface:

| Element | Weight | Size |
|---------|--------|------|
| Window title | SemiBold (600) | 13px |
| Menu items | Regular (400) | 13px |
| Toolbar buttons | SemiBold (600) | 12px |
| Sidebar items | Regular (400) | 13px |
| Status bar | Regular (400) | 11px |
| Dialogs | Regular (400) | 13px |
| Buttons | SemiBold (600) | 13px |

### Font Bundling

Bundle Open Sans with the app:

```
Resources/
└── Fonts/
    ├── OpenSans-Light.ttf
    ├── OpenSans-Regular.ttf
    ├── OpenSans-Medium.ttf
    ├── OpenSans-SemiBold.ttf
    └── OpenSans-Bold.ttf
```

Register in Info.plist:
```xml
<key>ATSApplicationFontsPath</key>
<string>Fonts</string>
```

### SwiftUI Usage

```swift
extension Font {
    static let tibokBody = Font.custom("OpenSans-Regular", size: 13)
    static let tibokHeadline = Font.custom("OpenSans-SemiBold", size: 13)
    static let tibokCaption = Font.custom("OpenSans-Regular", size: 11)
}
```

---

## Layout

### Main Window

```
┌─────────────────────────────────────────────────────────────────┐
│ ● ● ●                    Document.md                      ⚙ 📤  │  ← Title Bar (28px)
├─────────┬───────────────────────────────────────────────────────┤
│         │ Tab Bar (optional)                                    │  ← Tab Bar (28px)
│         ├───────────────────────────┬───────────────────────────┤
│         │                           │                           │
│  Side   │                           │                           │
│  bar    │        Editor             │       Preview             │
│         │                           │                           │
│  220px  │        flex               │       flex                │
│  min    │                           │                           │
│         │                           │                           │
│         │                           │                           │
├─────────┴───────────────────────────┴───────────────────────────┤
│ Ln 42, Col 15  │  1,234 words  │  UTF-8  │  main  │  Synced ✓   │  ← Status Bar (22px)
└─────────────────────────────────────────────────────────────────┘
```

### Dimensions

| Element | Size | Notes |
|---------|------|-------|
| Window min | 800 x 600 | Comfortable minimum |
| Window default | 1200 x 800 | Good for split view |
| Sidebar | 220px default | Resizable 180-400px |
| Divider | 1px | Draggable |
| Status bar | 22px | Fixed |
| Tab bar | 28px | Hidden if single doc |

### Split View Ratios

| Mode | Editor | Preview |
|------|--------|---------|
| Default | 50% | 50% |
| Editor Focus | 70% | 30% |
| Preview Focus | 30% | 70% |
| Editor Only | 100% | 0% |
| Preview Only | 0% | 100% |

---

## Components

### Sidebar

```
┌─────────────────────┐
│ 🔍 Search...        │  ← Search field
├─────────────────────┤
│ WORKSPACE           │  ← Section header
│ ▼ 📁 my-blog        │
│   ▼ 📁 _posts       │
│     📄 2024-01-15.. │  ← File (truncated)
│     📄 2024-01-10.. │
│   ▶ 📁 _drafts      │  ← Collapsed folder
│   📄 README.md      │
├─────────────────────┤
│ RECENT              │  ← Section header
│ 📄 notes.md         │
│ 📄 ideas.md         │
└─────────────────────┘
```

**File Status Indicators:**
- 🔵 Modified (unsaved)
- 🟢 Staged (git)
- 🟡 Untracked (git)
- ☁️ Syncing (iCloud)

### Command Palette

```
┌─────────────────────────────────────────────────┐
│ 🔍 Search commands...                           │
├─────────────────────────────────────────────────┤
│ ⏱ Recent                                        │
│   📄 New Document                        ⌘N     │
│   💾 Save                                ⌘S     │
├─────────────────────────────────────────────────┤
│ 📝 Editor                                       │
│   🔤 Toggle Bold                         ⌘B     │
│   🔤 Toggle Italic                       ⌘I     │
│   🔗 Insert Link                         ⌘K     │
├─────────────────────────────────────────────────┤
│ 📤 Export                                       │
│   📑 Export as PDF                       ⌘⇧E    │
│   🌐 Export as HTML                             │
└─────────────────────────────────────────────────┘
```

**Dimensions:** 500px wide, max 400px tall, centered horizontally

### Slash Command Menu

```
        ┌──────────────────────────┐
        │ /table                   │
        ├──────────────────────────┤
/ta│    │ 📊 Table      Insert...  │ ← Selected
        │ 📋 Task List  Insert...  │
        │ 🏷️ Tags       Insert...  │
        └──────────────────────────┘
```

**Behavior:**
- Appears below cursor after typing `/`
- Filters as user types
- Arrow keys to navigate
- Enter to select
- Escape to dismiss

### Status Bar

```
┌─────────────────────────────────────────────────────────────────┐
│ Ln 42, Col 15  │  1,234 words  │  UTF-8  │  main ▼  │  ✓ Saved  │
└─────────────────────────────────────────────────────────────────┘
  └─ Position      └─ Word count   └─ Encoding └─ Git   └─ Save status
```

**Click Actions:**
- Position: Go to line dialog
- Word count: Show detailed stats
- Encoding: Change encoding menu
- Git branch: Branch switcher
- Save status: Force save / sync details

---

## Interactions

### Keyboard Navigation

| Context | Key | Action |
|---------|-----|--------|
| Global | ⌘K | Command palette |
| Global | ⌘\ | Toggle preview |
| Global | ⌘⇧\ | Toggle sidebar |
| Global | ⌘1-9 | Switch to tab N |
| Editor | ⌘B | Bold |
| Editor | ⌘I | Italic |
| Editor | ⌘⇧K | Insert link |
| Editor | Tab | Indent / accept completion |
| Palette | ↑↓ | Navigate |
| Palette | Enter | Select |
| Palette | Esc | Dismiss |

### Drag and Drop

| Source | Target | Action |
|--------|--------|--------|
| Finder folder | App icon | Open as workspace |
| Finder .md file | Editor | Open file |
| Finder image | Editor | Insert image |
| Sidebar file | Tab bar | Open in new tab |
| Sidebar file | Another folder | Move file |

### Context Menus

**Editor Context Menu:**
- Cut / Copy / Paste
- ---
- Bold / Italic / Code
- Insert Link
- Insert Image
- ---
- AI: Improve Selection
- AI: Explain Selection

**Sidebar Context Menu:**
- Open
- Open in New Tab
- ---
- New File
- New Folder
- ---
- Rename
- Delete
- ---
- Reveal in Finder
- Copy Path

---

## Animations

| Element | Animation | Duration | Easing |
|---------|-----------|----------|--------|
| Sidebar toggle | Slide | 200ms | easeInOut |
| Preview toggle | Slide | 200ms | easeInOut |
| Command palette | Fade + Scale | 150ms | easeOut |
| Slash menu | Fade | 100ms | easeOut |
| Tab switch | Crossfade | 150ms | easeInOut |
| File tree expand | Height | 200ms | easeInOut |

---

## Responsive Behavior

### Narrow Window (< 900px)
- Hide sidebar by default
- Single pane (editor or preview, not split)
- Compact status bar

### Wide Window (> 1400px)
- Allow wider sidebar
- Comfortable split view
- Full status bar

---

## Accessibility

### VoiceOver
- All interactive elements labeled
- Logical focus order
- Announce: file status, word count, sync status
- Editor: Read line by line

### Keyboard
- Full keyboard navigation
- Visible focus indicators
- No keyboard traps
- Standard macOS shortcuts

### Visual
- Minimum 4.5:1 contrast ratio
- No color-only indicators (always include icon/text)
- Respect reduced motion preference
- Support increased contrast mode

---

## Dark Mode

All components automatically adapt using system colors. Custom colors defined with both light and dark variants in asset catalog.

**Preview Theme Switching:**
- Match system appearance by default
- Option to lock to light or dark
- Custom CSS themes override

---

## Notes

_Update this document as UI decisions are made during development._

---

**Last Updated:** 2024-12-13
