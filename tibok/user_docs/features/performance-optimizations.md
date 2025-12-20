# Performance Optimizations

## Overview

tibok includes several performance optimizations to ensure fast workspace opening and smooth editing, even with large folder structures (5,000+ files). These optimizations work automatically in the background without requiring any configuration.

## Smart Filtering Performance

### What It Does

Smart filtering automatically identifies and skips folders that don't contain markdown files, dramatically reducing the time needed to scan and display your workspace. This means folders full of images, build artifacts, or dependencies won't slow down your workflow.

### How It Works

When you open or expand a workspace folder, tibok:
1. **Scans folders for markdown files** - Checks folder contents to determine if they contain `.md` files
2. **Caches results** - Remembers results for 1 hour
3. **Skips empty folders** - Folders without markdown are hidden in the sidebar
4. **Updates cache** - Cache invalidates automatically when files change

### Skipped Folders

The following folder types are automatically skipped and hidden:
- **Package managers**: `node_modules/`, `vendor/`, `Pods/`
- **Version control**: `.git/`, `.svn/`, `.hg/`
- **Build outputs**: `dist/`, `build/`, `.build/`, `target/`
- **Python environments**: `__pycache__/`, `.venv/`, `venv/`
- **Frameworks**: `.next/`, `.nuxt/`, `coverage/`
- **Hidden folders**: Any folder starting with `.` (`.env`, `.config`, etc.)

### Performance Impact

Smart filtering provides dramatic performance improvements:

| Workspace Size | First Scan | Subsequent Opens | Impact |
|---|---|---|---|
| 100 files | Instant | <10ms | Minimal |
| 1,000 files | <100ms | <50ms | Negligible |
| 5,000+ files | 1-2 seconds | <100ms | 80-90% faster |
| 10,000+ files | 2-3 seconds | <100ms | Dramatic improvement |

**The first time you open a large workspace, tibok scans it once and caches the results. Every subsequent open is nearly instant.**

### Settings

Smart filtering is **always enabled** by default. Currently, there are no settings to disable it (it's fundamental to performance).

**Future versions may allow:**
- Custom folder skip list
- Cache duration configuration
- Manual refresh button
- Per-workspace settings

## Caching System

### Folder Scan Cache

tibok maintains an intelligent cache of folder scan results:

- **Duration**: 1 hour time-to-live (TTL)
- **Storage**: Persists across app restarts (stored in UserDefaults)
- **Thread-safe**: Multiple tabs can open simultaneously without conflicts
- **Automatic invalidation**: Cache is cleared when files are added/removed via Git operations
- **Memory efficient**: Caches only folder scan results, not file contents

### When Cache Is Used

The cache is automatically consulted when:
- Opening workspace folders
- Expanding folders in the sidebar
- Refreshing the file tree view
- Launching the app and restoring the last workspace

### Manual Cache Control

**Clear cache by closing and reopening the workspace:**
1. **Close workspace**: Cmd+Shift+W or File > Close Workspace
2. **Reopen workspace**: Cmd+Shift+O or File > Open Workspace
3. Cache will rebuild automatically

**Force refresh the cache:**
- Use the **refresh button** in the Git panel heading (also triggers folder rescan)
- This ensures cache is up to date after bulk file operations

## Tips for Large Projects

### Optimize for Performance

1. **First open is slower** - Initial scan builds cache for future opens (1-2 seconds typical for 5,000+ file workspaces)
2. **Keep workspace focused** - Open only folders you're actively working with
   - Instead of opening entire projects, open `docs/` or `content/` subfolder
   - This reduces initial scan time and focuses sidebar on relevant files
3. **Use favorites** - Quick access to frequently used files without opening entire folders
   - Star important files with the ❤️ icon for instant access

### Tips for Monorepo Structures

If you're working with a monorepo (multiple projects in one folder):

- **Open individual workspaces** - Open `packages/my-package/` instead of root
- **Use search** - Cmd+F to find files instead of browsing entire structure
- **Bookmark workspaces** - Keep multiple workspaces open in separate windows

### Git-Tracked Folders

Git operations trigger smart cache invalidation:
- **git add/commit** - Cache invalidates for affected folders
- **git branch/switch** - Full cache invalidation (file structure may have changed)
- **git pull** - Cache invalidated after changes are applied

This ensures the sidebar always shows current state without manual refresh.

## Technical Details (Optional Reading)

### How Smart Filtering Works

The `FolderScanCache` service:
1. Recursively scans folders up to 3 levels deep
2. Stops scanning as soon as one `.md` file is found (early termination)
3. Limits checks to 1,000 files per scan (safety limit)
4. Stores results with 1-hour expiration timestamp
5. Persists to UserDefaults for app restart recovery

### Thread Safety

All cache operations are protected by NSLock, ensuring:
- Multiple tabs can scan different folders simultaneously
- No race conditions when cache expires
- Safe concurrent access from background threads

### What Happens If Cache is Wrong

If the cache becomes out of sync (rare):
1. Cache expires after 1 hour automatically
2. Next access rebuilds cache with fresh scan
3. Or manually trigger refresh via Git panel

In practice, Git operations invalidate cache proactively, so stale data is very rare.

## Performance Comparison

**Without smart filtering** (if it were disabled):
```
Open large workspace (5,933 files):
- Scan all 5,933 files: 8-10 seconds
- Load all in sidebar: 2-3 seconds
- Total: 10-13 seconds of UI freeze
- Repeat on every workspace open
```

**With smart filtering** (current):
```
First open (cache miss):
- Scan folders for markdown: 1-2 seconds (background, non-blocking)
- Load filtered sidebar: <100ms
- Total: Instant, no freeze

Subsequent opens (cache hit):
- Load from cache: <50ms
- Display sidebar: <50ms
- Total: <100ms
```

**Result: 100-130x faster on cached opens, no UI freeze even on first open**

## Troubleshooting

### Workspace opens slowly on first time

**Expected behavior** - First scan takes 1-2 seconds for large workspaces. This is normal and only happens once. Subsequent opens use the cache.

**To speed up:**
- Open a subfolder instead of the entire project root
- Use Favorites for quick access to frequently used files

### A folder is hidden that should be visible

**Likely cause** - The folder doesn't contain any `.md` files (even recursively).

**Solutions:**
1. Add a markdown file to the folder (e.g., `README.md`)
2. Open a subfolder that contains markdown files
3. Use search to find files instead of browsing sidebar

### Files appear/disappear when switching branches

**Expected behavior** - Git branch switches invalidate the cache, so sidebar may briefly show old state, then refresh.

**This is correct** - Cache invalidation ensures accuracy when file structure changes across branches.

## Future Improvements

Planned features for even better performance:

- **File system events** - Real-time cache invalidation without Git dependency
- **SQLite indexing** - Sub-second scans for 10,000+ file workspaces
- **Customizable skip list** - Settings to hide additional folder patterns
- **Per-workspace settings** - Different caching behavior for different projects
