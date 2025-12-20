# Workspace & File Management

tibok supports working with individual files or entire folders of markdown documents.

## Opening Files

### Single File
- **Menu**: File > Open (Cmd+O)
- **Drag & drop**: Drag a `.md` or `.txt` file onto the app icon or window

### Folder/Workspace
- **Menu**: File > Open Folder (Cmd+Shift+O)
- Opens a folder and displays all markdown files in the sidebar

## Sidebar

The sidebar provides quick access to your files when working with a workspace.

### Showing/Hiding
- **Menu**: View > Toggle Sidebar
- **Shortcut**: Cmd+0

### Sections

1. **Search**: Filter files by name
2. **File Tree**: Hierarchical view of all markdown files in the workspace
3. **Recent Files**: Quick access to recently opened documents

### File Tree Features
- Click a file to open it
- Files are organized by folder structure
- Only `.md` and `.txt` files are shown

### Smart Folder Filtering

tibok automatically hides empty folders to keep your workspace clean and navigable.

#### How it Works
- Folders without markdown files are automatically hidden
- The app scans folders as you expand them (lazy evaluation)
- Results are cached for 1 hour to keep performance fast
- Common non-documentation folders are skipped (node_modules, .git, .build, etc.)

#### Performance
- **Workspace opens instantly** - No scanning on startup
- **Folders scan on demand** - Only when you expand them
- **Caching** - Same folders scan 10-100x faster on subsequent opens
- **Ideal for large workspaces** - Works smoothly with 1000+ files

#### Disabling Smart Filtering
If you prefer to see all folders:
1. Open Settings (⌘,)
2. Go to General tab
3. Toggle off "Smart folder filtering"
4. Workspace will reload showing all folders

## Creating Documents

### New Document
- **Menu**: File > New Document (Cmd+N)
- Creates a new untitled document
- Use Save As to choose location and filename

## Saving Documents

### Save
- **Menu**: File > Save (Cmd+S)
- Saves to the current file location
- For new documents, opens Save As dialog

### Save As
- **Menu**: File > Save As (Cmd+Shift+S)
- Choose a new location or filename
- Useful for creating copies or renaming

## Auto-Save

tibok automatically saves your work as you type.

### Settings
- **Location**: Settings > General
- **Toggle**: "Auto-save documents" checkbox
- **Default**: Enabled

### How it Works
- Changes are saved after you stop typing
- Only works for documents that have been saved at least once
- Modified indicator in status bar shows unsaved changes

## Status Bar

The bottom status bar shows document information:

| Indicator | Description |
|-----------|-------------|
| Word count | Total words in document |
| Character count | Total characters |
| Save status | "Saved", "Modified", or "Not Saved" |

### Save Status Colors
- **Green**: Document is saved
- **Blue**: Document has unsaved modifications
- **Gray**: Document has never been saved

## Supported File Types

| Extension | Type |
|-----------|------|
| `.md` | Markdown |
| `.txt` | Plain text |

## Tips

- **Quick switching**: Use the sidebar to quickly switch between files
- **Keyboard navigation**: Use Cmd+O for files, Cmd+Shift+O for folders
- **Search filter**: Type in the sidebar search to find files quickly
- **Status awareness**: Check the status bar to see if changes are saved
