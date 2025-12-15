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
