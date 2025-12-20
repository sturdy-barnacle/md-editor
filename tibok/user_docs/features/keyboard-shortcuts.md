# Keyboard Shortcuts

Complete reference for all keyboard shortcuts in Tibok.

## File Operations

| Action | Shortcut |
|--------|----------|
| New Document | Cmd+N |
| Open File | Cmd+O |
| Open Folder | Cmd+Shift+O |
| Save | Cmd+S |
| Save As | Cmd+Shift+S |
| Close Tab | Cmd+W |
| Reopen Closed Tab | Cmd+Shift+T |
| Print | Cmd+P |

## View

| Action | Shortcut |
|--------|----------|
| Toggle Sidebar | Cmd+0 |
| Toggle Preview | Cmd+\ |
| Toggle Inspector | Cmd+I |
| Focus Mode | Ctrl+Cmd+. |
| Command Palette | Cmd+K |

### Focus Mode

Focus mode provides a distraction-free writing environment by hiding:
- Title bar and tab bar
- Sidebar
- Preview pane
- Status bar

Press Ctrl+Cmd+. again or Escape to exit focus mode. Your sidebar and preview state is restored when you exit.

## Tab Management

| Action | Shortcut | Notes |
|--------|----------|-------|
| Switch to Tab 1-9 | **Cmd+1** through **Cmd+9** | Jump directly to that tab position |
| Next Tab | Cmd+Shift+] | Move right through open tabs |
| Previous Tab | Cmd+Shift+[ | Move left through open tabs |
| Recent Tab | **Ctrl+Tab** | Toggle between two most recent tabs |
| Close Tab | Cmd+W | Close current tab (prompts if unsaved) |
| Reopen Closed Tab | **Cmd+Shift+T** | Restore last 10 closed tabs (repeat to go back) |
| Close Workspace | Cmd+Shift+W | Close all tabs in workspace |

**Tips for Tab Switching:**
- **Cmd+1 through Cmd+9** are the fastest for frequent switching (most common)
- **Ctrl+Tab** is ideal when switching between just 2 tabs
- **Cmd+Shift+]** and **Cmd+Shift+[** are best for sequential browsing

**For detailed tab management instructions**, see [Tab Management](tab-management.md).

Note: Tab bar is always visible when documents are open for consistent navigation.

## Find

| Action | Shortcut |
|--------|----------|
| Find | Cmd+F |
| Find and Replace | Cmd+Option+F |
| Find Next | Cmd+G |
| Find Previous | Cmd+Shift+G |
| Replace | Cmd+= |

## Edit

| Action | Shortcut | Status |
|--------|----------|--------|
| Undo | Cmd+Z | ✅ Implemented |
| Redo | Cmd+Shift+Z | ✅ Implemented |
| Cut | Cmd+X | ✅ Implemented |
| Copy | Cmd+C | ✅ Implemented |
| Paste | Cmd+V | ✅ Implemented (with image support) |
| Select All | Cmd+A | ✅ Implemented |

### Edit Shortcuts Notes

- **Requires Focus**: All Edit shortcuts require the text editor to be in focus
- **Undo/Redo**: Automatically tracked - no configuration needed
- **Paste Images**: Paste automatically detects images and inserts them as markdown image references
- **Menu Integration**: All Edit operations are available in the Edit menu (Mac standard)

## Formatting

| Action | Shortcut |
|--------|----------|
| Bold | Cmd+B |
| Italic | Cmd+Shift+I |
| Strikethrough | Cmd+Shift+X |
| Inline Code | Cmd+E |
| Link | Cmd+L |

### Cursor Positioning

Formatting shortcuts use intelligent cursor positioning to streamline your workflow:

**With selected text:**
- **Bold, Italic, Strikethrough, Code**: Wrapped text stays selected, enabling chaining
  - Example: Select "text" → Cmd+B → `**text**` selected → Cmd+Shift+I → `***text***` selected
- **Link**: URL placeholder is selected, ready to type/paste
  - Example: Select "README" → Cmd+L → `[README](url)` with "url" selected

**Without selection:**
- All shortcuts insert placeholder text and select it for immediate replacement
  - Cmd+B → `**bold text**` with "bold text" selected
  - Cmd+L → `[link text](url)` with "link text" selected

## Slash Commands

| Action | Key |
|--------|-----|
| Open slash menu | Type `/` at line start |
| Navigate menu | Up/Down arrows |
| Select command | Enter |
| Dismiss menu | Escape |

## Command Palette

| Action | Key |
|--------|-----|
| Open command palette | Cmd+K |
| Navigate commands | Up/Down arrows |
| Execute command | Enter |
| Close palette | Escape |

## Git

| Action | Shortcut |
|--------|----------|
| Commit | Cmd+Shift+K |

## Settings

| Action | Shortcut |
|--------|----------|
| Open Settings | Cmd+, |

## Help

| Action | Shortcut | Notes |
|--------|----------|-------|
| Open Help (Website) | Cmd+? | Opens https://www.tibok.app/support |

## Troubleshooting

### Shortcuts Not Working

**Problem**: A keyboard shortcut (like Cmd+X for Cut) isn't working.

**Solution**: Make sure the text editor is in focus. Click on the editor pane and try again.

**Why**: Shortcuts are context-aware:
- Edit shortcuts (Cut, Copy, Paste, Select All) work only when the text editor is focused
- View shortcuts (Toggle Sidebar, etc.) work throughout the app
- Some system shortcuts (Cmd+,) are handled by macOS

### Paste Not Working as Expected

**Problem**: Pasting seems to have unexpected behavior.

**Solution**:
- If pasting an image, make sure the image is in a supported format (PNG, JPG, GIF, etc.)
- For text paste, ensure the text editor is focused
- Clear the clipboard and try copying/pasting again

### Menu Items Grayed Out

**Problem**: Menu items in Edit menu are grayed out.

**Solution**:
- This is normal behavior - menu items are disabled when not applicable
- Edit operations become available when the text editor is focused
- Cut and Copy become available when text is selected

## Tips

- Most shortcuts follow standard macOS conventions
- Menu items show their shortcuts on the right side
- Slash commands don't use modifier keys - just type `/`
- All Edit menu items are accessible via the menu bar even if shortcuts don't work
- Undo/redo history persists while the document is open
