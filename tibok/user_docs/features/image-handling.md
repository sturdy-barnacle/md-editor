# Image Handling

tibok makes it easy to add images to your markdown documents with drag & drop, paste, and slash commands.

## Adding Images

### Drag & Drop

1. Drag an image file from Finder into the editor
2. The image is automatically copied to an `assets` folder
3. Markdown syntax is inserted at the cursor position

**Supported formats**: PNG, JPG, JPEG, GIF, WEBP, SVG, BMP, TIFF

### Paste from Clipboard

1. Copy an image (from any app or screenshot)
2. Press Cmd+V in the editor
3. The image is saved to the `assets` folder with a timestamp filename
4. Markdown syntax is inserted with cursor in the alt text field

**Format Detection:**
- Copying image **files** (Cmd+C in Finder): Preserves original format (GIF, PNG, JPEG, etc.)
- Copying from **apps/screenshots**: Uses PNG for screenshots, preserves format when possible
- TIFF images are automatically converted to PNG for better web compatibility

### Slash Command

1. Type `/image` at the start of a line
2. Press Enter to insert: `![](image-url)`
3. Replace `image-url` with your image path or URL

## Cursor Positioning

After inserting an image (drag or paste), the cursor is automatically placed in the **alt text field** for accessibility:

```
![|](./assets/image.png)
```

This encourages adding descriptive alt text for screen readers and SEO. Type your description, then press Tab or click to move to the next position.

## Visual Feedback

tibok provides toast notifications for all image operations:

| Action | Notification | Icon | Duration |
|--------|-------------|------|----------|
| Image pasted (unsaved doc) | "Save document to paste images" | ⚠️ | 3s |
| Assets folder created | "Created assets folder" | 📁 | 1.5s |
| Image saved successfully | "Image saved to assets/filename" | ✅ | 2s |
| Image save failed | "Failed to save image: error" | ❌ | 3s |
| Drag without save | "Save document for relative paths" | ⚠️ | 3s |
| Copy failed (fallback) | "Using absolute path (copy failed)" | ⚠️ | 2.5s |

### Export & Copy Notifications

When exporting or copying documents with images:

- **PDF Export**: "Note: Relative image paths may not work in PDF" (if images present)
- **HTML Export**: "Images use relative paths - keep assets folder" (if images present)
- **Copy Markdown**: "Copied (images not included)" (reminds you images aren't on clipboard)

## Assets Folder

When you drag or paste images, tibok automatically:

1. Creates an `assets` folder next to your document (if it doesn't exist)
2. Copies the image to this folder
3. Generates a unique filename if one already exists
4. Inserts a relative path: `![](./assets/filename.png)`

### Folder Structure Example

```
my-project/
  document.md
  assets/
    screenshot.png
    diagram.png
    image-1702567890.png  (pasted images get timestamps)
```

## Unsaved Documents

For documents that haven't been saved yet:

- **Dragged files**: Uses absolute file paths (e.g., `![](file:///Users/.../image.png)`)
- **Pasted images**: Shows placeholder text prompting you to save the document first

**Tip**: Save your document before adding images to ensure proper relative paths.

## Path Formats

| Source | Path Format | Example |
|--------|-------------|---------|
| Drag/paste (saved doc) | Relative | `![](./assets/photo.png)` |
| Drag (unsaved doc) | Absolute | `![](file:///path/to/photo.png)` |
| Remote URL | Full URL | `![](https://example.com/image.png)` |

## Preview

Images in the preview pane are rendered when:
- Using relative paths that exist on disk
- Using absolute file:// paths
- Using remote https:// URLs

## Tips

- **Organize images**: Keep all images in the `assets` folder for portability
- **Descriptive names**: Rename images before dragging for better organization
- **Alt text**: Add descriptions in the `[]` for accessibility: `![A sunset photo](./assets/sunset.png)`
- **Multiple images**: Drag multiple files at once to insert them all

## Troubleshooting

### Image not showing in preview
- Check the file path is correct
- Ensure the image file exists at the specified location
- For remote images, check your internet connection

### "Save document first" message
- Save your document with Cmd+S before pasting images
- This allows tibok to create the assets folder in the right location

### Duplicate filenames
- tibok automatically appends numbers to avoid conflicts
- `photo.png` becomes `photo-1.png`, `photo-2.png`, etc.
