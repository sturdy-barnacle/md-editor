# Git Integration

Tibok includes built-in Git integration for workspaces that are Git repositories. Track changes, stage files, and commit directly from the editor.

## Overview

When you open a folder that's a Git repository, Tibok automatically detects it and shows:
- Branch name in the status bar
- Change count indicator
- Status indicators on files in the sidebar
- Git panel with staged/unstaged changes

## Status Bar

The status bar (bottom of window) shows:
- **Branch name** - Current Git branch (e.g., "main")
- **Change count** - Number of modified files (e.g., "• 3")

## File Status Indicators

Files in the sidebar show colored dots indicating their Git status:

| Color | Status |
|-------|--------|
| Blue | Modified (unstaged changes) |
| Green | Staged (ready to commit) |
| Yellow | Untracked (new file not in Git) |
| Red | Conflict (merge conflict) |
| Gray | Deleted |

## Git Panel

The Git panel appears in the sidebar when a Git repository is open (collapsed by default for a distraction-free experience). Click the "Git" section header to expand it. It shows:

### Staged Changes
Files that are staged and ready to commit. Click the minus (-) button to unstage.

### Changes (Unstaged)
Modified files that haven't been staged yet. Click:
- **Plus (+)** to stage the file
- **Arrow** to discard changes (revert to last commit)

### Quick Actions
- **Stage All** - Stage all unstaged changes
- **Unstage All** - Unstage all staged files
- **Commit** - Open commit dialog (when files are staged)

## Committing Changes

1. Stage the files you want to commit
2. Click **Commit** button or press `Cmd+Shift+K`
3. Enter a commit message
4. Click **Commit**

## Push and Pull

Use the Git menu to sync with remote:
- **Git > Push** - Push commits to remote repository
- **Git > Pull** - Pull changes from remote repository

These use your existing Git credentials (SSH keys or stored passwords).

## Context Menu

Right-click any file in the sidebar to access Git actions:
- **Stage** - Add file to staging area
- **Unstage** - Remove file from staging area
- **Discard Changes** - Revert to last committed version

## Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Commit | Cmd+Shift+K |

## Command Palette

All Git commands are available in the command palette (Cmd+K):
- Stage All Changes
- Unstage All
- Commit...
- Push
- Pull
- Refresh Git Status

## Git Menu

The Git menu provides access to all Git operations:
- Stage All
- Unstage All
- Commit...
- Push
- Pull
- Refresh Status

## How It Works

Tibok uses your system's Git installation (`/usr/bin/git`) to execute commands. This means:

- **Authentication**: Uses your existing SSH keys and credentials
- **Configuration**: Respects your `.gitconfig` settings
- **Compatibility**: Works with any Git remote (GitHub, GitLab, Bitbucket, etc.)

If `git push` works in Terminal, it will work in Tibok.

## Requirements

- Git must be installed on your system (included with Xcode Command Line Tools)
- For push/pull: Git credentials configured (SSH keys or credential helper)

## Tips

- The Git panel is collapsed by default - click the header to expand
- Branch name is shown in the status bar (no longer duplicated in sidebar)
- Status indicators update automatically when files change
- Use `Cmd+K` and type "git" to quickly access Git commands (grouped under GIT category)
- Refresh status manually with Git > Refresh Status if needed
