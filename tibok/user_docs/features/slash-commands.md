# Slash Commands

Slash commands provide quick access to markdown formatting and content insertion without memorizing syntax.

## How to Use

1. Place your cursor at the beginning of a new line
2. Type `/` to open the command menu
3. Continue typing to filter commands (e.g., `/tab` filters to "Table")
4. Use arrow keys to navigate the menu
5. Press Enter to insert the selected command
6. Press Escape to dismiss the menu

## Available Commands

### Headings

| Command | Description | Output |
|---------|-------------|--------|
| `/h1` | Large heading | `# Heading` |
| `/h2` | Medium heading | `## Heading` |
| `/h3` | Small heading | `### Heading` |
| `/h4` | Smaller heading | `#### Heading` |
| `/h5` | Small heading | `##### Heading` |
| `/h6` | Smallest heading | `###### Heading` |

### Block Elements

| Command | Description | Output |
|---------|-------------|--------|
| `/table` | Insert a 3-column table | Full table markdown |
| `/code` | Fenced code block | ` ```code``` ` |
| `/quote` | Blockquote | `> Quote` |
| `/callout` | Note/warning block | `> [!NOTE]` |
| `/collapse` | Collapsible section | `<details>` HTML |

### Links & Media

| Command | Description | Output |
|---------|-------------|--------|
| `/link` | Hyperlink | `[text](url)` |
| `/image` | Image | `![alt](url)` |
| `/footnote` | Footnote reference | `[^ref]` |

### Lists

| Command | Description | Output |
|---------|-------------|--------|
| `/list` | Bullet list | `- Item` |
| `/numbered` | Numbered list | `1. Item` |
| `/task` | Checkbox list | `- [ ] Task` |

### Inline Formatting

| Command | Description | Output |
|---------|-------------|--------|
| `/bold` | Bold text | `**text**` |
| `/italic` | Italic text | `*text*` |
| `/bolditalic` | Bold and italic | `***text***` |
| `/strikethrough` | Strikethrough | `~~text~~` |
| `/underline` | Underlined text | `<u>text</u>` |
| `/inlinecode` | Inline code | `` `code` `` |
| `/highlight` | Highlighted text | `==text==` |
| `/subscript` | Subscript (H₂O) | `~text~` |
| `/superscript` | Superscript (x²) | `^text^` |

### Math

| Command | Description | Output |
|---------|-------------|--------|
| `/math` | Inline LaTeX formula | `$formula$` |
| `/mathblock` | Display LaTeX formula | `$$formula$$` |

### Structure

| Command | Description | Output |
|---------|-------------|--------|
| `/hr` | Horizontal rule | `---` |
| `/toc` | Table of contents | `[[toc]]` |
| `/definition` | Definition list | `Term` + `: Definition` |

### Date & Time

| Command | Description | Example Output |
|---------|-------------|----------------|
| `/date` | Today's date (ISO) | `2024-12-14` |
| `/datelong` | Today's date (long) | `December 14, 2024` |
| `/time` | Current time | `14:30` |
| `/datetime` | Full timestamp | `2024-12-14 14:30` |
| `/pickdate` | Open date picker | Opens calendar UI |

## Cursor Placement

After inserting a command, the cursor is automatically placed at the most useful position:
- For headings: After the `#` symbols
- For links: Inside the `[]` for the link text
- For code blocks: Inside the block, ready to type
- For tables: In the first cell

## Tips

- **Quick filtering**: Type just the first few letters (e.g., `/ta` shows Table and Task)
- **Mouse support**: Click any command in the menu to insert it
- **Hover preview**: Hover over commands to see their descriptions
- **Keyboard navigation**: Up/Down arrows move selection, Enter inserts
