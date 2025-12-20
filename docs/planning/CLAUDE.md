# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**tibok** is a native macOS markdown editor built with SwiftUI targeting Apple Silicon. The app emphasizes local-first storage, seamless Git/Jekyll publishing workflows, and AI-assisted writing.

- **Website:** tibok.app
- **Repo:** github.com/sturdy-barnacle/md-editor

## Tech Stack

- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI
- **Target:** macOS 14 (Sonoma)+, Apple Silicon native
- **Architecture:** MVVM with Observable

## Build & Run

```bash
# Open in Xcode
open tibok.xcodeproj

# Build from command line
xcodebuild -scheme tibok -configuration Debug build

# Run tests
xcodebuild -scheme tibok -configuration Debug test

# Build for release
xcodebuild -scheme tibok -configuration Release build
```

## Project Structure

```
md-editor/
├── App/                 # App entry point, AppDelegate
├── Features/            # Feature modules (Editor, Preview, Sidebar, QuickActions)
├── Services/            # Business logic (Storage, Git, Export, AI, Webhook)
├── Models/              # Data models
├── Utilities/           # Helpers and extensions
└── Resources/           # Assets, themes
```

## Key Architecture Decisions

- **Editor uses NSTextView** (wrapped in NSViewRepresentable) for performance, not native SwiftUI TextEditor
- **Preview uses WKWebView** for HTML rendering with custom CSS themes
- **Local storage first** - files stored on filesystem, Core Data only for metadata/indexing
- **Security-scoped bookmarks** for persistent folder access permissions

## Dependencies

- `swift-markdown` - Markdown parsing
- `SwiftGit2` - Git operations via libgit2
- `KeychainAccess` - Secure credential storage
- `Highlightr` - Code syntax highlighting

## Code Conventions

- Use Swift's async/await for all asynchronous operations
- ViewModels are `@Observable` classes
- Services are injected via environment
- File paths use `URL` not `String`

## Progress Tracking

**Important:** Create daily progress notes in the `progress/` folder.

- Format: `YYYY-MM-DD_progress_notes.md`
- Update throughout the day as progress is made
- Include: completed tasks, blockers, next steps

## Planning Documentation

**Important:** Keep planning docs updated as development progresses.

### Planning Files (`planning/`)
- `epic-mvp-v0.1.md` - MVP planning (Phase 1-5, P0-P1 features)
- `epic-beta-v0.5.md` - Beta planning (Git, quick actions, media)
- `epic-v1.0.md` - v1.0 planning (AI, publishing, plugins)
- `user-stories.md` - All user stories by epic and persona

### When to Update Planning Docs

1. **Starting a feature:** Mark status as 🟡 In Progress
2. **Completing a feature:** Mark status as ✅ Complete
3. **Encountering blockers:** Update Risks section, mark ❌ Blocked
4. **Making decisions:** Document in Notes section
5. **Scope changes:** Update feature list and acceptance criteria

### User Stories Updates

- Mark story status (⬜ → 🟡 → ✅)
- Add new stories as requirements emerge
- Log changes in the Change Log section

## Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) - Technical architecture and system design
- [PRD.md](PRD.md) - Product requirements and feature specifications
- [README.md](README.md) - Project overview and usage
- [planning/](planning/) - Epic planning docs and user stories
