# Git Integration

tibok includes built-in Git integration for workspaces that are Git repositories. Track changes, stage files, and commit directly from the editor.

## Overview

When you open a folder that's a Git repository, tibok automatically detects it and shows:
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

The Git panel appears in the sidebar when a Git repository is open (collapsed by default for a distraction-free experience). Click the "Git" section header to expand it. It includes sections for:
- **Branches** - View and manage local branches
- **Stashes** - Temporary storage for uncommitted changes
- **Changes** - Staged and unstaged file modifications
- **Quick actions** - Commit, push, pull operations

### Branch Management

The Git panel includes a collapsible Branches section where you can:

**View Branches**
- See all local branches in a list
- Current branch marked with checkmark ✓
- Branch names displayed clearly

**Create New Branch**
1. Click "New Branch" button in Branches section
2. Enter branch name (alphanumeric, hyphens, underscores, forward slashes allowed)
3. Real-time validation ensures name is valid and unique
4. New branch is created from current HEAD

**Switch Branches**
1. Click on any branch name to switch
2. If you have uncommitted changes, you'll see options:
   - **Stash & Switch** - Saves changes to stash before switching branches
   - **Bring With Me** - Attempts to switch while keeping uncommitted changes
   - **Cancel** - Abort the switch
3. Git status refreshes automatically after successful switch

**Delete Branches**
1. Click trash icon next to the branch you want to delete
2. Confirmation dialog appears with the branch name
3. **Protected branches** (main, master) require extra confirmation
4. Cannot delete the currently active branch

**Safety Features**
- Real-time validation of branch names
- Protected branch warnings for main/master
- Uncommitted changes detection before switching
- Toast notifications for all operations success/failure

### Stash Management

The Git panel includes a collapsible Stashes section for temporary storage of uncommitted changes:

**View Stashes**
- See all stashes with timestamps
- Stash message shown if one was provided
- List shows most recent stashes first

**Create Stash**
1. Click "New Stash" button in Stashes section
2. Optionally enter a descriptive message
3. All uncommitted changes are saved to stash
4. Working directory becomes clean (all changes saved)

**Apply Stash**
- Click "Apply" button to restore stashed changes
- Stash remains in the list for reuse or reference
- Changes are applied to your current branch

**Pop Stash**
- Click "Pop" button to apply and remove stash in one action
- Changes are restored and stash is permanently deleted
- Useful for one-time application of changes

**Drop Stash**
- Click trash icon to delete a stash without applying it
- Confirmation required before permanent deletion
- Useful for removing unwanted stashes

**Common Use Cases**
- Temporarily save work before switching branches
- Experiment with changes without committing them
- Transfer uncommitted changes between branches
- Clean working directory for Git operations (merge, rebase, etc.)

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

tibok uses your system's Git installation (`/usr/bin/git`) to execute commands. This means:

- **Authentication**: Uses your existing SSH keys and credentials
- **Configuration**: Respects your `.gitconfig` settings
- **Compatibility**: Works with any Git remote (GitHub, GitLab, Bitbucket, etc.)

If `git push` works in Terminal, it will work in tibok.

## Requirements

- Git must be installed on your system (included with Xcode Command Line Tools)
- For push/pull: Git credentials configured (SSH keys or credential helper)

## Tips

- The Git panel is collapsed by default - click the header to expand
- Branch name is shown in the status bar (no longer duplicated in sidebar)
- Status indicators update automatically when files change
- Use `Cmd+K` and type "git" to quickly access Git commands (grouped under GIT category)
- Refresh status manually with Git > Refresh Status if needed
