# tibok

A native macOS markdown editor built with SwiftUI for Apple Silicon.

**Website:** [tibok.app](https://tibok.app)

## Features

- **Fast & Native** - Built with SwiftUI, optimized for Apple Silicon
- **Live Preview** - Side-by-side editor and rendered preview
- **Local-First** - Your files stay on your machine
- **Git Integration** - Stage, commit, push/pull without leaving the app
- **35+ Slash Commands** - Quick formatting with `/` commands
- **Command Palette** - Access all actions with ⌘K
- **Export Options** - PDF, HTML, and plain text
- **Tabs** - Multiple documents open simultaneously
- **Math/LaTeX** - Offline KaTeX rendering

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
3. Stage changes in the sidebar Git panel
4. Commit with `⌘⇧K`
5. Push to remote


## Development

See [CLAUDE.md](tibok/CLAUDE.md) for development guidelines.

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

**Hybrid Licensing Model**

tibok uses a hybrid licensing approach:

- **Core Application**: Proprietary non-commercial license
  - See [LICENSE](LICENSE) for full terms
  - Non-commercial use only
  - Commercial use requires a separate license
  - Source code available for viewing and non-commercial modification

- **Plugin System**: MIT License
  - See [tibok/tibok/Plugins/LICENSE](tibok/tibok/Plugins/LICENSE)
  - Open source and freely usable
  - Encourages community plugin development

**Commercial Licensing**

For commercial use, distribution, or sale of tibok, please contact k@emberwisp.xyz to obtain a commercial license.
