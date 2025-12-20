# Keyboard Shortcuts Specification - tibok

> Complete keyboard shortcut reference for tibok

## Design Principles

1. **macOS Native** - Follow Apple HIG, match system apps
2. **Muscle Memory** - Match common editor shortcuts (VS Code, Sublime)
3. **Discoverable** - Show in menus, command palette
4. **Customizable** - Allow user overrides (future)

---

## Global Shortcuts

Available throughout the app.

### File Operations

| Shortcut | Action | Menu |
|----------|--------|------|
| ⌘N | New Document | File → New |
| ⌘O | Open File | File → Open |
| ⌘S | Save | File → Save |
| ⌘⇧S | Save As | File → Save As |
| ⌘W | Close Tab/Window | File → Close |
| ⌘⇧W | Close All | File → Close All |

### View

| Shortcut | Action | Menu |
|----------|--------|------|
| ⌘\ | Toggle Preview | View → Toggle Preview |
| ⌘⇧\ | Toggle Sidebar | View → Toggle Sidebar |
| ⌘⌥P | Preview Only | View → Preview Only |
| ⌘⌥E | Editor Only | View → Editor Only |
| ⌘0 | Focus Sidebar | View → Focus Sidebar |
| ⌘1-9 | Switch to Tab N | View → Tab N |
| ⌘⇧[ | Previous Tab | View → Previous Tab |
| ⌘⇧] | Next Tab | View → Next Tab |
| ⌘+ | Increase Font Size | View → Zoom In |
| ⌘- | Decrease Font Size | View → Zoom Out |
| ⌘0 | Reset Font Size | View → Actual Size |
| ⌃⌘F | Toggle Full Screen | View → Enter Full Screen |

### Navigation

| Shortcut | Action | Menu |
|----------|--------|------|
| ⌘K | Command Palette | Go → Command Palette |
| ⌘P | Quick Open File | Go → Quick Open |
| ⌘G | Go to Line | Go → Go to Line |
| ⌘⇧O | Go to Symbol | Go → Go to Symbol |
| ⌃- | Go Back | Go → Back |
| ⌃⇧- | Go Forward | Go → Forward |

---

## Editor Shortcuts

Available when editor is focused.

### Text Editing

| Shortcut | Action | Notes |
|----------|--------|-------|
| ⌘X | Cut | |
| ⌘C | Copy | |
| ⌘V | Paste | Handles images |
| ⌘A | Select All | |
| ⌘Z | Undo | |
| ⌘⇧Z | Redo | |
| ⌘D | Duplicate Line | |
| ⌘⇧K | Delete Line | |
| ⌥↑ | Move Line Up | |
| ⌥↓ | Move Line Down | |
| ⌘⏎ | Insert Line Below | |
| ⌘⇧⏎ | Insert Line Above | |

### Selection

| Shortcut | Action | Notes |
|----------|--------|-------|
| ⌘L | Select Line | |
| ⌘⇧L | Select All Occurrences | |
| ⌃⇧⌘→ | Expand Selection | |
| ⌃⇧⌘← | Shrink Selection | |
| ⌥⇧↑ | Add Cursor Above | Multi-cursor |
| ⌥⇧↓ | Add Cursor Below | Multi-cursor |
| ⌥Click | Add Cursor | Multi-cursor |
| Esc | Clear Cursors | Return to single |

### Find & Replace

| Shortcut | Action | Notes |
|----------|--------|-------|
| ⌘F | Find | |
| ⌘G | Find Next | |
| ⌘⇧G | Find Previous | |
| ⌘⌥F | Replace | |
| ⌘⇧F | Find in Folder | |
| ⌘⇧H | Replace in Folder | |

### Indentation

| Shortcut | Action | Notes |
|----------|--------|-------|
| Tab | Indent | Or accept completion |
| ⇧Tab | Outdent | |
| ⌘] | Indent Line | |
| ⌘[ | Outdent Line | |

---

## Markdown Formatting

| Shortcut | Action | Markdown |
|----------|--------|----------|
| ⌘B | Toggle Bold | `**text**` |
| ⌘I | Toggle Italic | `*text*` |
| ⌘⇧X | Toggle Strikethrough | `~~text~~` |
| ⌘E | Toggle Inline Code | `` `code` `` |
| ⌘⇧K | Insert Link | `[text](url)` |
| ⌘⇧I | Insert Image | `![alt](url)` |
| ⌘⇧C | Toggle Code Block | ``` |
| ⌘⇧. | Toggle Blockquote | `>` |
| ⌘⇧8 | Toggle Bullet List | `-` |
| ⌘⇧7 | Toggle Numbered List | `1.` |
| ⌘⇧T | Toggle Task List | `- [ ]` |
| ⌘/ | Toggle Comment | `<!-- -->` |

### Heading Shortcuts

| Shortcut | Action | Markdown |
|----------|--------|----------|
| ⌘⌥1 | Heading 1 | `# ` |
| ⌘⌥2 | Heading 2 | `## ` |
| ⌘⌥3 | Heading 3 | `### ` |
| ⌘⌥4 | Heading 4 | `#### ` |
| ⌘⌥5 | Heading 5 | `##### ` |
| ⌘⌥6 | Heading 6 | `###### ` |
| ⌘⌥0 | Paragraph | Remove heading |

---

## Command Palette Shortcuts

When command palette is open.

| Shortcut | Action |
|----------|--------|
| ↑ / ↓ | Navigate items |
| ⏎ | Select item |
| Esc | Close palette |
| ⌘⌫ | Clear input |

---

## Sidebar Shortcuts

When sidebar is focused.

| Shortcut | Action |
|----------|--------|
| ↑ / ↓ | Navigate files |
| ⏎ | Open file |
| Space | Preview file |
| ⌘⇧N | New file |
| ⌘⌥N | New folder |
| ⌫ | Delete (with confirmation) |
| ⏎ | Rename (when selected) |

---

## Git Shortcuts (Pro)

| Shortcut | Action | Menu |
|----------|--------|------|
| ⌘⇧C | Commit | Git → Commit |
| ⌘⇧P | Push | Git → Push |
| ⌘⇧U | Pull | Git → Pull |
| ⌘⌥G | Open Git Panel | View → Git |

---

## AI Shortcuts (Pro)

| Shortcut | Action | Notes |
|----------|--------|-------|
| ⌘⇧A | AI Improve Selection | Requires selection |
| ⌘⌥A | AI Complete | Continue from cursor |
| ⌘⇧⌥A | AI Panel | Open AI sidebar |

---

## Export Shortcuts

| Shortcut | Action | Menu |
|----------|--------|------|
| ⌘⇧E | Export PDF | File → Export → PDF |
| ⌘⌥E | Export HTML | File → Export → HTML |

---

## Slash Commands

Triggered by typing `/` at beginning of line or after space.

| Command | Inserts |
|---------|---------|
| /h1 | `# ` |
| /h2 | `## ` |
| /h3 | `### ` |
| /bold | `****` |
| /italic | `**` |
| /code | Fenced code block |
| /table | Table template |
| /link | `[](url)` |
| /image | `![](url)` |
| /task | `- [ ] ` |
| /quote | `> ` |
| /hr | `---` |
| /date | Current date |
| /time | Current time |
| /toc | Table of contents |

---

## Modifier Key Reference

| Symbol | Key |
|--------|-----|
| ⌘ | Command |
| ⌥ | Option/Alt |
| ⌃ | Control |
| ⇧ | Shift |
| ⏎ | Return/Enter |
| ⌫ | Delete/Backspace |
| Esc | Escape |
| Tab | Tab |

---

## Conflicts & Resolution

### Known Conflicts

| Shortcut | System | tibok Resolution |
|----------|--------|-----------------|
| ⌘H | Hide app | Keep system default |
| ⌘M | Minimize | Keep system default |
| ⌘Q | Quit | Keep system default |
| ⌘, | Preferences | Keep system default |

### Customization (Future)

v1.x will support custom keyboard shortcuts:

```json
{
  "editor.toggleBold": "cmd+b",
  "editor.toggleItalic": "cmd+i",
  "view.togglePreview": "cmd+\\"
}
```

---

## Implementation Notes

### Key Code Reference

```swift
// Common key codes for NSEvent
let keyCodeB: UInt16 = 11      // B
let keyCodeI: UInt16 = 34      // I
let keyCodeK: UInt16 = 40      // K
let keyCodeBackslash: UInt16 = 42  // \
let keyCodeReturn: UInt16 = 36 // Return
let keyCodeTab: UInt16 = 48    // Tab
let keyCodeEscape: UInt16 = 53 // Escape
```

### Menu Integration

All shortcuts should be defined in menu items for discoverability:

```swift
Menu("Edit") {
    Button("Bold") {
        editorViewModel.toggleBold()
    }
    .keyboardShortcut("b", modifiers: .command)
}
```

---

**Last Updated:** 2024-12-13
