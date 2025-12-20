# Session Persistence

## Overview

tibok automatically saves your workspace state and restores it when you relaunch the app. This means you can close the app in the middle of a project and pick up exactly where you left off—same files open, same cursor positions, same panel visibility.

## What's Automatically Saved

tibok persists an extensive amount of state about your session:

### Panel Visibility & Layout
- **Preview panel** - Whether markdown preview is shown/hidden
- **Sidebar** - File browser visibility and expansion state
- **Inspector** - Frontmatter editor (YAML/TOML) visibility
- **Panel dividers** - Exact positions where you placed dividers between panels
- **Focus mode** - Whether you were in distraction-free mode (Ctrl+⌘+.)

### Workspace & Documents
- **Last opened workspace** - The folder path you were working in
- **Open documents** - All tabs with their file paths and content
- **Active document** - Which tab was selected when you quit
- **Tab order** - The sequence and position of open tabs

### Sidebar State
- **Folder expansion** - Which folders were expanded in file tree
- **Scroll position** - Where you were scrolled to in file tree
- **Favorites** - Starred files (the ❤️ icon)
- **Recent files** - Last 10 files you opened (auto-managed)

### Editor State (per Document)
- **Cursor position** - Line number and column where cursor was
- **Selection** - What text was selected (if any)
- **Scroll position** - Where you were scrolled vertically in the document
- **Undo history** - Recent edits (during current session only)

## How It Works

### On App Launch

When you open tibok, the following happens automatically (you don't need to do anything):

1. **Restores last workspace** - Opens the folder you were working in
2. **Reopens all tabs** - All documents from your last session appear
3. **Restores panel visibility** - Preview, sidebar, inspector show/hide state
4. **Expands sidebar folders** - Shows the same folder structure you had
5. **Sets cursor positions** - Places cursor at the last position in each document
6. **Selects active document** - The tab you had selected becomes active
7. **Scrolls to last location** - Both file tree and editor scroll to where you were

**Result**: Everything looks exactly as you left it.

### During Your Session

State is saved automatically at multiple points:

- **Every 30 seconds** - Auto-save interval captures any state changes
- **On document save** - When you press Cmd+S, state updates immediately
- **On workspace close** - When you close a folder, state is saved
- **On app quit** - Before tibok closes, final state snapshot is saved
- **On panel resize** - When you drag dividers, new positions are saved

### Storage Location

Your session state is stored in system locations:

| State Type | Storage Location | Notes |
|---|---|---|
| Panel visibility | UserDefaults | Loaded on startup |
| Workspace path | UserDefaults | Last opened folder |
| Tab order & paths | UserDefaults | Which files were open |
| Document content | File system | Auto-saved to actual files |
| Cursor positions | UserDefaults | Per-document cursor state |
| Folder expansion | UserDefaults | Which folders expanded |

These are stored securely in macOS standard locations and included in Time Machine backups.

## Privacy & Data

### What's NOT Saved

Some data is intentionally NOT persisted:

- **Document content** - Only auto-saved if you've saved the document at least once
- **Unsaved "Untitled" documents** - New documents without a filename are lost on quit
- **Passwords & API keys** - Only stored in Keychain (not in session state)
- **Find/replace queries** - Search terms are not saved between sessions
- **Selected text** - Text selections are cleared on app restart
- **Command palette history** - Recent commands are not retained

This is intentional for security—sensitive information is never saved to disk.

### Clearing Session State

If you want to start completely fresh:

**Option 1: Manual clear (Nuclear Option)**
```bash
# Quit tibok first
# Then in Terminal:
defaults delete com.tibok.app persistedState

# Relaunch tibok—it will open with no workspace
```

**Option 2: Close workspace before quitting**
1. File > Close Workspace (Cmd+Shift+W)
2. Quit tibok (Cmd+Q)
3. Next launch starts with no workspace open
4. State is still saved, but workspace is empty

**Option 3: Future feature (not yet available)**
- Hold Option key while launching tibok
- Would start with clean slate while preserving state for future

## Use Cases

### Daily Workflow

You're working on a blog post:
1. Open tibok with `~/my-blog/` workspace (or it opens automatically)
2. You have 5 documents open: `index.md`, `post-1.md`, `post-2.md`, `draft.md`, `notes.md`
3. Cursor is in `post-1.md` at line 47
4. Preview panel is hidden; sidebar is expanded

**Later that day:**
- Close tibok (Cmd+Q)
- Few hours pass...
- Open tibok again
- Everything restored: same 5 documents, cursor at line 47, preview hidden, sidebar expanded
- You continue editing without missing a beat

### Context Switching

You're context-switching between Project A and Project B:

**Project A state saved:**
- Workspace: `~/projects/blog/`
- Open tabs: 10 files from blog
- Active: `post-draft.md`

**Switch to Project B:**
1. Close workspace (Cmd+Shift+W)
2. Open different workspace: `~/projects/app/` (Cmd+Shift+O)
3. Project B tabs open automatically

**Later, return to Project A:**
1. Close Project B workspace (Cmd+Shift+W)
2. Open Project A workspace (Cmd+Shift+O)
3. **All 10 blog tabs reappear in same order with same cursor positions**
4. Cursor in `post-draft.md` is at the exact position you left it

This works because each workspace has its own saved state.

### Crash Recovery

If tibok crashes unexpectedly:
1. Last saved state is still preserved
2. Relaunch tibok
3. Everything restores to last known good state
4. Unsaved changes from last 30 seconds (since last auto-save) may be lost
5. Actual file content is safe (auto-saved when you hit Cmd+S)

**To minimize data loss**: Save your work frequently with Cmd+S. The file itself is saved immediately; session state is auto-saved every 30 seconds.

## Settings & Preferences

### Current Behavior (Always Enabled)

Session persistence is always enabled—you can't disable it. This is by design for best user experience.

### Future Customization (Planned)

These features would allow more control (not yet implemented):

- **Option to disable session restoration** - Start with blank workspace on every launch
- **Choose what to persist** - Enable/disable specific state categories
- **Session history** - Restore to previous points in time
- **per-workspace preferences** - Different settings for different projects
- **Auto-save interval** - Customize how often state is saved (currently 30 seconds)

## Troubleshooting

### State Not Restoring

**Problem**: You quit with files open, but they don't reappear on restart.

**Possible causes & solutions:**

1. **Workspace folder no longer exists** - If you moved/deleted the workspace folder:
   - Open it again manually (File > Open Workspace)
   - State will restore if folder still contains files

2. **Files were deleted** - If files were deleted from disk:
   - Tabs reference deleted files and can't restore
   - Solution: File > Open to navigate to other files

3. **Workspace was never saved** - If you never saved a workspace:
   - Open a workspace and save a document in it
   - On next launch, workspace will restore

4. **Corrupted UserDefaults** (very rare) - Clear with:
   ```bash
   defaults delete com.tibok.app persistedState
   ```

### State Restoring Slowly

**Problem**: App takes a long time to restore all tabs.

**Possible causes & solutions:**

1. **Too many tabs open** - > 20 tabs slow down restoration:
   - Close unused tabs before quitting
   - Consider organizing into multiple workspaces

2. **Very large files** - Files > 10 MB are slow to restore:
   - Limit to < 5 files of this size
   - Split large documents into multiple files

3. **Slow disk** - Network drives or external disks:
   - Consider keeping workspace on internal drive
   - Performance depends on disk speed

### Undo History Lost

**Problem**: Undo (Cmd+Z) doesn't work for old changes.

**Expected behavior** - Undo history is session-only. When you quit and relaunch:
- Old undo history is cleared
- New undo history starts fresh
- This is intentional for memory efficiency

**Solution**: If you need to recover old changes, use Git:
- `git diff` shows what changed
- `git log` shows change history
- This is more reliable than app-level undo

### Cursor Position Wrong

**Problem**: Cursor doesn't appear at the saved position.

**Possible causes:**
1. **File was edited externally** - Character counts changed
2. **Large file with different encoding** - Line counts differ
3. **Undo/redo after quit** - Previous edits changed structure

**Solution**: Manually position cursor where needed. Perfect position restoration is very hard across file changes.

## What State Survives App Updates?

When tibok updates to a new version:

| State | Survives | Notes |
|---|---|---|
| Tab paths | ✅ Yes | File paths are stable |
| Workspace path | ✅ Yes | Folder paths unchanged |
| Cursor position | ✅ Yes | Unless file structure changed |
| Panel visibility | ✅ Yes | Layout preferences stable |
| Preferences | ✅ Yes | Settings are compatible |
| Recent files | ✅ Yes | Auto-managed list |
| Undo history | ❌ No | Cleared on update (expected) |
| Plugin state | ✅ Yes | Plugin on/off status |

**Important**: Always save your work before updating. Cursor positions might shift if the app or file format changes significantly.

## Best Practices

1. **Save regularly** - Cmd+S writes both file and updates session state
2. **Close unused tabs** - Reduces startup time and memory usage
3. **Use multiple workspaces** - For separate projects/contexts
4. **Backup important files** - Use Git for version control
5. **Check file sync** - If using cloud storage, ensure files sync before quitting

## Technical Details

### Session State Format

Session data is stored as JSON in UserDefaults (encrypted on secure machines):

```json
{
  "lastWorkspacePath": "/Users/username/projects/blog",
  "openDocuments": [
    {
      "path": "/Users/username/projects/blog/post-1.md",
      "cursorPosition": { "line": 47, "column": 12 },
      "scrollPosition": 1234
    }
  ],
  "activePath": "/Users/username/projects/blog/post-1.md",
  "panelStates": {
    "previewVisible": false,
    "sidebarVisible": true,
    "inspectorVisible": false
  }
}
```

### Performance Impact

Session persistence has minimal performance impact:
- Saving state: ~10-50ms every 30 seconds (background)
- Restoring state: 100-500ms on app launch (depends on file count)
- Memory overhead: <1 MB for typical session

Most users won't notice any performance difference.
