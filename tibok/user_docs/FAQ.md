# Tibok FAQ

## General

### What is Tibok?
Tibok is a native macOS markdown editor built for writers who love simplicity. It provides a clean, distraction-free writing environment with live preview and essential markdown features.

### What does "Tibok" mean?
"Tibok" is a Filipino word meaning "heartbeat" or "pulse," reflecting the app's goal to be the heart of your writing workflow.

### What macOS versions are supported?
Tibok requires macOS 14.0 (Sonoma) or later.

---

## Documents & Files

### Where are my documents saved?
Documents are saved wherever you choose when using Save As. Tibok doesn't enforce a specific location.

### Does Tibok auto-save my work?
Yes, auto-save is enabled by default. You can toggle this in Settings > General.

### What file formats does Tibok support?
Tibok works with `.md` (Markdown), `.txt` (plain text), and other text-based files like `.csv`.

### Can I open a folder of markdown files?
Yes, use File > Open Folder (Cmd+Shift+O) to open a workspace. The sidebar will show all markdown files in the folder.

---

## Editor

### How do I use slash commands?
Type `/` at the beginning of a line to open the slash command menu. Use arrow keys to navigate and Enter to select. Available commands include headings, lists, code blocks, tables, and more.

### What slash commands are available?
- `/h1`, `/h2`, `/h3` - Headings
- `/table` - Insert table
- `/code` - Code block
- `/quote` - Blockquote
- `/link` - Hyperlink
- `/image` - Image
- `/list` - Bullet list
- `/numbered` - Numbered list
- `/task` - Task/checkbox list
- `/bold`, `/italic`, `/strikethrough` - Text formatting
- `/date`, `/time`, `/datetime` - Insert current date/time
- `/pickdate` - Date picker

### How do I add images?
Three ways to add images:
1. **Drag & drop**: Drag image files directly into the editor
2. **Paste**: Copy an image and paste with Cmd+V (preserves GIF, PNG, JPEG formats)
3. **Slash command**: Type `/image` and enter the URL

When you drag or paste images:
- They're automatically copied to an `assets` folder next to your document
- The cursor is placed in the alt text field: `![|](path)` for accessibility
- You'll see toast notifications confirming the save
- **Tip**: Save your document first to enable relative paths

### What image formats are supported?
Tibok supports all common web image formats:
- **Animated**: GIF (preserves animation when copying from Finder)
- **Photos**: PNG, JPG, JPEG
- **Graphics**: SVG, WEBP
- **Other**: BMP, TIFF (converted to PNG for web compatibility)

**Format detection**: When pasting, Tibok detects the original format and preserves it when possible. Images copied from apps may be converted to standard formats.

### Can I use Find and Replace?
Yes, use Cmd+F for Find and Cmd+Option+F for Find and Replace.

### Are there keyboard shortcuts for markdown formatting?
Yes! Use these shortcuts to quickly format selected text:
- **Cmd+B**: Bold (`**text**`)
- **Cmd+Shift+I**: Italic (`*text*`)
- **Cmd+E**: Inline code (`` `code` ``)
- **Cmd+Shift+X**: Strikethrough (`~~text~~`)
- **Cmd+L**: Link (`[text](url)`)

If no text is selected, placeholder text is inserted and selected for easy replacement. You can also find these in the Format menu.

---

## Preview

### How do I show/hide the preview pane?
Use View > Toggle Preview or press Cmd+\.

### Does the preview update in real-time?
Yes, the preview updates as you type.

### How do I create nested lists?
Use 2-space indentation per nesting level:
```markdown
- Parent item
  - Child item (2 spaces)
    - Grandchild item (4 spaces)
```

You can mix ordered and unordered lists, and nest up to 3 levels deep. Task lists can also be nested. See [Preview Features](features/preview.md#nested-lists) for more details.

---

## Appearance

### How do I switch between light and dark mode?
Click the appearance icon in the title bar (sun/moon icon) to choose between System, Light, or Dark mode. You can also change this in Settings > General > Appearance.

### Does my appearance preference persist?
Yes, your choice is saved and applied automatically when you reopen the app.

---

## Sidebar

### How do I show/hide the sidebar?
Use View > Toggle Sidebar or press Cmd+0.

### What does the sidebar show?
The sidebar displays:
- **Search field** with inline results for finding content across files
- **Workspace** section (file tree when a folder is open)
- **Favorites** for quick access to important files
- **Recent** files list
- **Git** panel (collapsed by default, shows when in a git repo)

### How do I expand collapsed sections?
Click on the section header (Git) to expand or collapse it. The sections remember their state.

### How do I add files to Favorites?
Right-click any file in the workspace, recent files, or open tabs and select "Add to Favorites".

---

## Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| New Document | Cmd+N |
| Open File | Cmd+O |
| Open Folder | Cmd+Shift+O |
| Save | Cmd+S |
| Save As | Cmd+Shift+S |
| Toggle Sidebar | Cmd+0 |
| Toggle Preview | Cmd+\ |
| Toggle Inspector | Cmd+I |
| Command Palette | Cmd+K |
| Find | Cmd+F |
| Find and Replace | Cmd+Option+F |
| Find Next | Cmd+G |
| Find Previous | Cmd+Shift+G |

---

## Frontmatter (Inspector)

### How do I edit frontmatter metadata?
Open the Inspector panel with Cmd+I. If your document doesn't have frontmatter yet, choose Jekyll or Hugo and click "Add Frontmatter".

### What frontmatter formats are supported?
- Jekyll: YAML (`---` delimiters)
- Hugo: YAML (`---`) or TOML (`+++`)

### How do I set the timezone for dates?
Go to Settings > Frontmatter and select your timezone from the dropdown. When using "Date & Time" mode, dates are formatted as ISO 8601 with the timezone offset.

### Is frontmatter shown in the preview?
No, frontmatter is automatically stripped from the preview so you see your content as readers will.

See [Frontmatter Editor](features/frontmatter.md) for more details.

---

## Plugins

### What are plugins?
Plugins are extensions that add commands and features to Tibok. You can enable or disable them from Settings > Plugins.

### Where are the slash commands?
Slash commands are provided by the "Core Slash Commands" plugin. If slash commands aren't working, check Settings > Plugins to ensure it's enabled.

See [Plugins](features/plugins.md) for more details.

---

## Webhooks

### What are webhooks?
Webhooks send HTTP requests to external services when events occur (like saving a document). This is useful for triggering builds or notifications.

### How do I create a webhook?
Go to Settings > Webhooks, click "Add Webhook", and configure the URL, events, and payload.

See [Webhooks](features/webhooks.md) for more details.

---

## Troubleshooting

### The preview isn't showing my images
Check the toast notifications when adding images - they indicate success or errors:
- ✅ "Image saved to assets/filename" means it worked
- ⚠️ "Save document to paste images" means you need to save first (Cmd+S)
- ❌ "Failed to save image" shows the specific error

Common issues:
- **Document not saved**: Pasted images require a saved document for relative paths
- **Wrong path format**: Images in `assets` folder use `./assets/image.png` format
- **File doesn't exist**: Verify the image file is in the specified location
- **Remote images**: Check your internet connection for https:// URLs

### My document won't save
- Check that you have write permissions to the folder
- Try Save As to choose a different location
- Ensure the disk isn't full

### Slash commands aren't appearing
- Make sure you type `/` at the start of a line
- The menu only appears when there are matching commands
- Press Escape to dismiss and try again

---

## Planned Features

### What features are coming next?
See our roadmap for planned features:
- **Future**: Cloud sync, publishing integrations
