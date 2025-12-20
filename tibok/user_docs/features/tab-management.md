# Tab Management

## Overview

tibok supports multiple open documents using a tab interface. This allows you to quickly switch between files, compare content, and work on multiple projects simultaneously without opening multiple windows.

The tab bar appears below the title bar whenever you have 2 or more documents open.

## Opening Files in Tabs

### From Sidebar

The sidebar shows your workspace files. You can open them in different ways:

| Action | Result | Keyboard |
|---|---|---|
| **Single click** | Opens file in tab (or switches if already open) | Click |
| | If already open, tab becomes active | |
| **Cmd+Click** | Opens in background tab (focus stays on current tab) | Cmd+Click |
| **Double-click** | Opens and immediately focuses the tab | Double-click |

### From Recent Files

The "Recent" section in the sidebar shows your 10 most recently opened files:
- Click any recent file → Opens in new tab
- Works across all workspaces (recent list is global)

### From Favorites

Files you starred with the ❤️ icon appear in "Favorites" section:
- Click any favorite → Opens in new tab
- Quick access without browsing folder structure

### Drag & Drop

You can drag files from Finder into tibok:
- **Single file drag** → Opens in new tab
- **Multiple file drag** → Opens each in separate tab
- Already existing tabs will be switched to (not duplicated)

### From Command Palette

Use the command palette (Cmd+K) to quickly search and open files:
1. Press **Cmd+K** to open command palette
2. Type filename or path
3. Press Enter to open in tab

## Understanding the Tab Bar

### Location & Appearance

The tab bar appears **below the title bar** when 2+ documents are open:

```
tibok — tibok
┌─────────────────────────────────────────────────────┐
│ [📄 Document.md] [✱ Untitled]     [🔍] [⊕] [≡]    │
└─────────────────────────────────────────────────────┘
│ # Document.md                                       │
│ This is my document                                 │
│                                                     │
```

### Tab Components

Each tab shows:

| Component | Meaning | Example |
|---|---|---|
| **Icon** | File type indicator | 📄 (document) or 📁 (folder) |
| **Name** | Filename | `Document.md` or `Untitled` |
| **Dot** | Unsaved changes | ● appears before name if changed |
| **Close button** | Appears on hover/active tab | [×] to close |

### Tab States

Tabs can be in different states:

| State | Appearance | Meaning |
|---|---|---|
| **Active** | Blue/highlighted background | Currently visible in editor |
| **Inactive** | Gray background | Open but not visible |
| **Modified** | Dot before filename (●) | Has unsaved changes |
| **Unsaved** | "Untitled" name | Never been saved to disk |

## Switching Between Tabs

### Keyboard Shortcuts

These are the fastest ways to switch tabs:

| Shortcut | Action |
|---|---|
| **Cmd+1 ... Cmd+9** | Switch to tab by position (1st, 2nd, 3rd, etc., up to 9th) |
| **Cmd+Shift+]** | Next tab (move right) |
| **Cmd+Shift+[** | Previous tab (move left) |
| **Ctrl+Tab** | Recent tab (like browser back/forward) |

**Examples:**
- If you have 5 tabs open: `Cmd+1` opens 1st tab, `Cmd+5` opens 5th tab
- `Cmd+2` then `Cmd+2` again cycles through tabs when there are < 9 tabs
- `Ctrl+Tab` toggles between two most recently used tabs

### Mouse & Trackpad

| Action | Effect |
|---|---|
| **Click tab** | Switch to that document |
| **Scroll on tab bar** | Scroll left/right through many tabs |
| **Scroll wheel on tab** | (If too many tabs to fit) |

### Tab Switching Tips

- Use **Cmd+1-9** for muscle memory—very fast once learned
- Use **Ctrl+Tab** if you frequently switch between two documents
- Use **Cmd+Shift+]** and **Cmd+Shift+[** for sequential browsing

## Closing Tabs

### Close Single Tab

| Method | Shortcut | Steps |
|---|---|---|
| **Click close button** | Mouse | Hover over tab, click [×] |
| **Keyboard** | **Cmd+W** | Works on active tab |
| **Middle-click** | Mouse (trackpad) | Click with mouse middle button |

### Unsaved Changes

If a document has unsaved changes, you'll see a prompt:

```
┌─────────────────────────────────┐
│ Do you want to save changes     │
│ to "document.md"?              │
│                                 │
│ [Don't Save] [Cancel] [Save]   │
└─────────────────────────────────┘
```

- **Save** - Writes changes to disk and closes tab
- **Don't Save** - Closes tab without saving (changes lost)
- **Cancel** - Keeps tab open

### Close Multiple Tabs

| Action | Result |
|---|---|
| **Close workspace** | Cmd+Shift+W closes all tabs in current workspace |
| | (Prompts for unsaved changes) |
| **Close all** | Quit app (Cmd+Q) saves state and closes all tabs |
| | (Or closes without saving if you choose Don't Save) |

## Reopening Closed Tabs

### Reopen Last Closed Tab

Accidentally closed a tab? Quickly restore it:

| Method | Shortcut |
|---|---|
| **Keyboard** | **Cmd+Shift+T** |
| **Menu** | File > Reopen Closed Tab |

**Works for the last 10 closed tabs** - Keep pressing Cmd+Shift+T to go further back.

### What Restores

When you reopen a closed tab:
- ✅ File path
- ✅ Cursor position
- ✅ Scroll position
- ✅ Undo history (if within session)
- ❌ Changes made after closing (they're gone)

## Tab Restoration & Persistence

### On App Launch

All tabs from your last session are restored automatically:

- Same documents open
- Same tab order
- Same active tab (which one was selected)
- Same cursor positions
- Same content (if saved)

See [Session Persistence](session-persistence.md) for details.

### After Crash

If tibok crashes:
- Tabs from last session restore
- Content reflects last auto-save (every 30 seconds)
- Any edits since last save are lost (unless auto-saved to file)

## Tab Context Menu (Right-Click)

Right-click on any tab to see options:

```
┌──────────────────────────────┐
│ Close Tab            ⌘W      │
│ Close Other Tabs             │
│ Close Tabs to the Right      │
└──────────────────────────────┘
```

**Planned future options** (not yet available):
- Copy File Path
- Reveal in Sidebar
- Duplicate Tab
- Pin Tab (keep at start of tab bar)
- Split View (show 2 tabs side-by-side)

## Tab Overflow Management

### When Tabs Don't Fit

If you have many tabs that don't fit in the window width:

- **Scroll arrows appear** - ◀ ▶ buttons at edges of tab bar
- **Click arrows** - Navigate through tabs
- **Scroll wheel** - Scroll through tab bar (if supported)

**Recommended**: Close unused tabs to keep < 10 visible at once

### Performance with Many Tabs

| Tab Count | Performance | Recommendation |
|---|---|---|
| 1-5 | Optimal | Normal workflow |
| 6-10 | Excellent | Comfortable for most users |
| 11-20 | Good | Still responsive, slower restoration |
| 20+ | Noticeable lag | Consider closing unused tabs |

**Tips for managing many tabs:**
- Close tabs you're not actively using
- Use Favorites for quick re-opening
- Organize into multiple workspaces if working on 20+ files
- Save and close at end of day to reset

## Tab Customization

### Current Behavior

- Tab bar position: Always below title bar (fixed)
- Tab close button: Always visible on active/hover (fixed)
- Tab width: Auto-sized (fixed)

### Future Customization (Planned)

These features would provide more control (not yet implemented):

| Feature | When Available |
|---|---|
| **Tab position** | Move tab bar to bottom (future) |
| **Tab close button** | Customize when shown (always/hover/never) |
| **Maximum tab width** | Fixed width for long filenames |
| **Tab previews** | Hover to see file content |
| **Drag to reorder** | Reorganize tabs by dragging |
| **Tab grouping** | Group related tabs together |
| **Multiple tab bars** | Separate bars for different workspaces |

## Keyboard-First Workflow

If you prefer keyboard over mouse:

1. **Open file**
   - Cmd+O → type filename → Enter
   - Or Cmd+K for command palette

2. **Switch between tabs**
   - Cmd+1...9 (fastest for up to 9 tabs)
   - Ctrl+Tab (for switching between 2 files)
   - Cmd+Shift+]/[ (sequential browsing)

3. **Edit**
   - Type and edit normally
   - Cmd+S to save

4. **Close**
   - Cmd+W to close current tab

5. **Undo/Redo**
   - Cmd+Z to undo
   - Cmd+Shift+Z to redo

6. **Close & Reopen**
   - Cmd+W to close
   - Cmd+Shift+T to reopen last

**Result**: Never touch the mouse! Complete power-user workflow.

## Tab Behavior Examples

### Example 1: Documentation Writing

You're writing documentation with multiple sections:
- **Tab 1**: `index.md` (overview) - being read
- **Tab 2**: `getting-started.md` (in progress)
- **Tab 3**: `api-reference.md` (quick reference)

**Workflow**:
1. Click Tab 2 (or press Cmd+2) to edit Getting Started
2. Reference Tab 3 (click or Cmd+3) to check API details
3. Back to Tab 2 (Cmd+2) to continue writing
4. Save (Cmd+S) - updates Getting Started file

### Example 2: Code & Blog Cross-Reference

You're writing a blog post about code:
- **Tab 1**: `draft-post.md` (your writing)
- **Tab 2**: `component.swift` (code being discussed)
- **Tab 3**: `example-usage.swift` (usage example)

**Workflow**:
1. Main work in Tab 1 (blog post)
2. Quick jump to Tab 2 (Cmd+2) to reference code
3. Jump to Tab 3 (Cmd+3) to see how it's used
4. Back to Tab 1 (Cmd+1) to write about both examples

### Example 3: Comparing Two Versions

You want to compare similar files:
- **Tab 1**: `old-version.md`
- **Tab 2**: `new-version.md`

**Workflow**:
1. Open both in tabs
2. Use Cmd+1 and Cmd+2 to quickly flip between
3. Or use Ctrl+Tab to toggle between the two
4. Edit one, switch to see the other

## Comparison to Other Editors

How tibok's tabs compare to other markdown editors:

| Feature | tibok | VS Code | Obsidian | Notion |
|---|---|---|---|---|
| **Unlimited tabs** | ✅ | ✅ | ❌ Panes only | ❌ Single doc |
| **Cmd+1-9 switching** | ✅ | ✅ | ❌ | ❌ |
| **Reopen closed** | ✅ | ✅ | ❌ | ❌ |
| **Tab persistence** | ✅ | ✅ | ✅ | N/A |
| **Drag to reorder** | 🔄 Planned | ✅ | N/A | N/A |
| **Split view** | 🔄 Planned | ✅ | ✅ | ✅ |
| **Tab context menu** | ✅ Basic | ✅ Full | N/A | N/A |

**tibok advantages**: Blazing fast switching, persistent state, clean interface
**tibok gaps**: Drag reorder and split view (planned for future)

## Troubleshooting

### Too Many Tabs Open

**Problem**: App is slow or tab bar is cluttered.

**Solutions**:
1. **Close unused tabs** - Cmd+W to close current tab
2. **Use Favorites** - Instead of keeping tabs open, star files (❤️)
3. **Use Multiple Workspaces** - Close all, then open different workspace
4. **Search Instead** - Use Cmd+F or Cmd+K to find files

### Tab Order Not Restored

**Problem**: You quit with tabs in order A→B→C, but they reopen as B→A→C.

**Possible causes**:
1. You closed/reopened tabs in different order
2. Files were moved on disk
3. Session state corrupted (rare)

**Solution**: Manually reorder by closing/reopening in desired order, then quit cleanly.

### Tabs All Close Unexpectedly

**Problem**: All tabs closed and you didn't mean to.

**Recovery**:
1. **Immediately use Cmd+Shift+T** (reopen closed tab)
2. Keep pressing to restore all tabs
3. This works for last 10 closed tabs

If that doesn't work:
- Relaunch app - tabs restore from session state
- Last session is always saved on quit

### Tabs Won't Open/Respond

**Problem**: Clicking tabs does nothing; they don't switch.

**Solutions**:
1. **Try keyboard shortcut** - Cmd+1, Cmd+2, etc.
2. **Try double-click** - Sometimes single-click needs double-click focus
3. **Restart app** - Cmd+Q then relaunch
4. **Check file exists** - If file was deleted, tab can't switch to it

### Performance Degradation with Many Tabs

**Problem**: App gets slower as you open more tabs.

**This is expected** with 20+ tabs. Solutions:

1. **Close unused tabs** - You only need the active ones
2. **Use Favorites** - Quick reopening beats leaving tabs open
3. **Split into workspaces** - Keep related files in one workspace
4. **Save/quit at day end** - Start fresh next day

## Tips & Tricks

1. **Power move**: Cmd+Shift+T then Cmd+1 to reopen and activate
2. **Quick switch**: Hold Ctrl+Tab for 1 second to cycle through open tabs
3. **Zero mouse**: Open, edit, save, close—all keyboard shortcuts
4. **Compare docs**: Use Cmd+1/Cmd+2 rapid switching to compare files
5. **Backup workflow**: Frequently used files as Favorites (❤️)
