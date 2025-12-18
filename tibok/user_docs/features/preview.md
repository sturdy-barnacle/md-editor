# Markdown Preview

Tibok provides a live preview pane that renders your markdown as you type.

## Showing/Hiding Preview

- **Menu**: View > Toggle Preview
- **Shortcut**: Cmd+\

## Features

### Live Updates
The preview updates in real-time as you type, with no delay or manual refresh needed.

### Rendered Elements

The preview supports standard markdown elements:

| Element | Markdown | Preview |
|---------|----------|---------|
| Headings | `# H1` to `###### H6` | Styled headings |
| Bold | `**text**` | **Bold text** |
| Italic | `*text*` | *Italic text* |
| Strikethrough | `~~text~~` | ~~Strikethrough~~ |
| Links | `[text](url)` | Clickable links |
| Images | `![alt](url)` | Rendered images |
| Code | `` `code` `` | Inline code |
| Code blocks | ` ```lang ``` ` | Syntax highlighted |
| Blockquotes | `> quote` | Styled quotes |
| Lists | `- item` or `1. item` | Formatted lists |
| Nested lists | 2-space indentation | Up to 3 levels deep |
| Task lists | `- [ ] task` | Checkboxes |
| Tables | Pipe syntax | Formatted tables |
| Horizontal rule | `---` | Divider line |
| Footnotes | `[^ref]` | Linked footnotes |
| Table of Contents | `[[toc]]` | Navigable TOC |
| Highlight | `==text==` | Highlighted text |
| Callouts | `> [!NOTE]` | Styled callout boxes |

### Footnotes

Add footnote references in your text with `[^1]` or `[^name]`, then define them anywhere in the document:

```markdown
This is a sentence with a footnote[^1].

[^1]: This is the footnote content.
```

Footnotes are rendered at the bottom of the preview with back-links.

### Table of Contents

Insert `[[toc]]` anywhere in your document to generate a navigable table of contents based on your headings. The TOC updates automatically as you add or modify headers.

### Callouts

GitHub-style callouts are supported:

```markdown
> [!NOTE]
> This is a note callout.

> [!TIP]
> This is a tip callout.

> [!WARNING]
> This is a warning callout.
```

Available types: NOTE, TIP, WARNING, IMPORTANT, CAUTION

### Nested Lists

Create nested lists using 2-space indentation per level. Mix ordered and unordered lists freely:

```markdown
- Parent item
  - Child item
  - Another child
    - Grandchild (level 3)
- Second parent

1. Ordered parent
   - Unordered child
   - Another child
2. Second ordered item
```

**Features:**
- Up to 3 levels of nesting (parent → child → grandchild)
- Mix ordered (`1.`) and unordered (`-`, `*`, `+`) at any level
- Task lists can be nested too:
  ```markdown
  - [ ] Parent task
    - [x] Completed subtask
    - [ ] Pending subtask
  ```

**Indentation rules:**
- Use exactly 2 spaces per nesting level
- Level 1 (root): No indentation
- Level 2: 2 spaces
- Level 3: 4 spaces

**Note:** Empty lines close all open lists. For multi-paragraph list items, avoid blank lines within the list structure.

### Code Syntax Highlighting

Fenced code blocks with language identifiers are syntax highlighted:

```swift
let greeting = "Hello, World!"
print(greeting)
```

Supported languages include: Swift, JavaScript, Python, HTML, CSS, JSON, and many more.

## Layout

### Split View
By default, the editor and preview are shown side by side:
- Editor on the left
- Preview on the right
- Both scroll independently

### Editor Only
Hide the preview (Cmd+\) to focus on writing with maximum editor space.

## Styling

The preview uses clean, readable styling:
- System fonts for body text
- Monospace fonts for code
- Proper spacing and line height
- Respects system light/dark mode

## Tips

- **Focus mode**: Hide the preview when drafting, show it for review
- **Check formatting**: Use preview to verify tables and code blocks render correctly
- **Image verification**: Preview shows if image paths are correct
- **Link testing**: Links in preview are clickable (opens in browser)
