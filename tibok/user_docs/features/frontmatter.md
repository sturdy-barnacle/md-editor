# Frontmatter Editor

Tibok includes a built-in frontmatter editor for Jekyll and Hugo static site generators. The inspector panel lets you edit frontmatter metadata through a form-based interface.

## Opening the Inspector

- **Keyboard**: Cmd+I
- **Menu**: View > Toggle Inspector
- **Command Palette**: Cmd+K, then search "inspector"

## Supported Formats

| Generator | Format | Delimiter |
|-----------|--------|-----------|
| Jekyll | YAML | `---` |
| Hugo | YAML | `---` |
| Hugo | TOML | `+++` |
| WordPress | YAML | `---` |

### WordPress Publishing Fields

When WordPress Export plugin is enabled, frontmatter supports publishing metadata:

| Field | Description | Behavior |
|-------|-------------|----------|
| `title` | Post title | Overrides document title |
| `description` | Post excerpt/summary | Used as WordPress excerpt |
| `categories` | Array of category names | Auto-created if missing on WordPress |
| `tags` | Array of tag names | Auto-created if missing on WordPress |
| `draft` | Boolean (`true`/`false`) | `true` = draft, `false` = publish |
| `author` | Author display name | Falls back to authenticated user if not found |

**Note**: The `layout` field is ignored by WordPress (used by Jekyll/Hugo for page templates).

See [WordPress Publishing](wordpress-publishing.md) for full publishing documentation.

## Creating Frontmatter

When you open the inspector on a document without frontmatter:

1. Choose your static site generator (Jekyll, Hugo, or WordPress)
2. Click "Add Frontmatter"
3. The frontmatter block is added with your default settings

## Editing Fields

The inspector provides form controls for common frontmatter fields:

### Status
- **Draft**: Toggle switch to mark document as unpublished

### Document
- **Title**: Document title
- **Description**: Brief summary or excerpt
- **Date**: Publication date picker
- **Time**: Optional time with timezone (toggle "Date & Time" mode)

### Metadata
- **Author**: Author name
- **Layout**: Template name (e.g., "post", "page")

### Taxonomy
- **Tags**: Comma-separated list of tags
- **Categories**: Comma-separated list of categories

### Custom Fields
Add any additional key-value pairs your site needs.

## Date and Time

When "Date & Time" mode is enabled:
- A time picker appears with your configured timezone
- Dates are formatted as ISO 8601 with timezone offset
- Example: `2025-01-15T10:30:00-08:00`

When in "Date only" mode:
- Dates are formatted as `2025-01-15`

## Timezone Configuration

Set your preferred timezone in Settings > Frontmatter:

1. Open Settings (Cmd+,)
2. Go to the Frontmatter tab
3. Select your timezone from the dropdown
4. All date/time values will use this timezone

Common timezones included:
- UTC
- US timezones (Eastern, Central, Mountain, Pacific, Alaska, Hawaii)
- European timezones (London, Paris, Berlin)
- Asian timezones (Tokyo, Shanghai, Singapore, India)
- Pacific timezones (Sydney, Auckland)

## Default Values

Configure default values for new frontmatter in Settings > Frontmatter:

### Jekyll Defaults
- Author
- Layout (default: "post")
- Draft status
- Default tags
- Default categories

### Hugo Defaults
- Frontmatter format (YAML or TOML)
- Author
- Layout
- Draft status
- Default tags
- Default categories

## Live Sync

Changes in the inspector are immediately reflected in your document's frontmatter. The sync works both ways:
- Edit in inspector → document updates
- Edit document directly → inspector updates

## Removing Frontmatter

Click "Remove Frontmatter" at the bottom of the inspector to strip the frontmatter block from your document.

## Preview Behavior

Frontmatter is automatically hidden from the preview pane. Only the document body is rendered, so you see your content as readers will.

## Tips

- Use the command palette (Cmd+K) to quickly toggle the inspector
- Set up defaults in Settings to save time on new posts
- The inspector remembers your Jekyll/Hugo selection
- Custom fields support any string value
