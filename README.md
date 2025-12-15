# tibok

A native macOS markdown editor built with SwiftUI for Apple Silicon.

**Website:** [tibok.app](https://tibok.app)

## Features

- **Fast & Native** - Built with SwiftUI, optimized for Apple Silicon
- **Live Preview** - Split view with synchronized scrolling
- **Local-First** - Your files stay on your machine, with optional iCloud sync
- **Git Integration** - Clone, commit, push without leaving the app
- **Jekyll Publishing** - Export to Jekyll format and create PRs directly
- **AI Assistance** - Writing suggestions powered by Claude
- **Quick Actions** - Command palette (⌘K) and slash commands
- **Export Options** - PDF, HTML, and Markdown with frontmatter

## Requirements

- macOS 14 (Sonoma) or later
- Apple Silicon (M1/M2/M3) or Intel Mac

## Installation

Coming soon to the Mac App Store.

### Build from Source

```bash
git clone https://github.com/sturdy-barnacle/md-editor.git
cd md-editor
open tibok.xcodeproj
```

```bash
cd tibok && ./scripts/build-app.sh && open .build/debug/tibok.app
```

Build with Xcode 15+ and run on your Mac.

## Usage

### Basic Editing
- Open any `.md` file or create a new document
- Toggle preview with `⌘\`
- Access all commands with `⌘K`

### Quick Commands
- `/table` - Insert table template
- `/code` - Insert code block
- `/link` - Insert link
- `/image` - Insert image

### Git Workflow
1. Open a folder that's a Git repository
2. Edit your markdown files
3. Commit with `⌘⇧C`
4. Push to remote

### Jekyll Publishing
1. Write your post
2. Export → Jekyll Post
3. Select target repository
4. Create PR automatically

## Documentation

- [Architecture](ARCHITECTURE.md) - Technical design and system architecture
- [PRD](PRD.md) - Product requirements and feature specifications

## Development

See [CLAUDE.md](CLAUDE.md) for development guidelines and [progress/](progress/) for daily progress notes.

### GitHub Actions Setup

This repository uses GitHub Actions for CI/CD and Claude Code integration. To enable the Claude Code workflow:

1. **Configure the OAuth Token Secret:**
   - Go to your repository Settings → Secrets and variables → Actions
   - Click "New repository secret"
   - Name: `CLAUDE_CODE_OAUTH_TOKEN`
   - Value: Your Claude Code OAuth token (obtain from [code.claude.com](https://code.claude.com))
   - Click "Add secret"

2. **Workflow Files:**
   - Workflow files in `.github/workflows/` should be tracked in git (not in `.gitignore`)
   - The linter warning about `CLAUDE_CODE_OAUTH_TOKEN` is expected and can be safely ignored
   - Secrets are only available at runtime, so the linter cannot validate their existence

3. **Using Claude Code:**
   - Tag `@claude` in issue comments, PR comments, or issue descriptions
   - Claude will automatically respond and help with code changes

## License

Core: MIT
Premium: Proprietary