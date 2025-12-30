# tibok markdown editor

<img style="float:right;" width="256" height="256" alt="tibok markdown editor app icon" src="https://github.com/user-attachments/assets/e3896bd3-594f-4dfd-bfdb-cbc07e505241" />

A native macOS markdown editor built with SwiftUI for Apple Silicon. Fast, local-first, and extensible. 
**Website:** [tibok.app](https://www.tibok.app)

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

Coming soon to the App Store.

### Download the latest release here on GitHub

[![Latest Release](https://img.shields.io/github/v/release/sturdy-barnacle/md-editor?style=flat-square)](https://github.com/sturdy-barnacle/md-editor/releases/latest)     

### Build from Source
(I highly recommend you download the latest release rather than build from source, but hey, you do you.)

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

### Git Workflow
1. Open a folder that's a Git repository
2. Edit your markdown files
3. Stage changes in the sidebar Git panel
4. Commit with `⌘⇧K`
5. Push to remote

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
