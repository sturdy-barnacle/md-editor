# Epic: Beta (v0.5) - tibok

> Feature-complete beta - Git, quick actions, and media handling

## Overview

The Beta release adds power-user features: Git integration, command palette, slash commands, and clipboard/media handling. This release targets early adopters and testers.

**Product:** tibok (tibok.app)
**Target:** Public beta for external testing
**Prerequisite:** MVP (v0.1) complete
**Design Mockup:** `design_docs/tibok ui mockups/beta-v0.5.jsx`

---

## Phases

### Phase 1: Command System (P0 - Critical)

Command palette and quick actions infrastructure.

| ID | Feature | Description | Status |
|----|---------|-------------|--------|
| BETA-1.1 | Command registry | Central registry for all app commands | ⬜ Not Started |
| BETA-1.2 | Command palette UI | ⌘K overlay with fuzzy search | ⬜ Not Started |
| BETA-1.3 | Keyboard shortcuts | Configurable shortcut system | ⬜ Not Started |
| BETA-1.4 | Recent commands | Track and prioritize recent commands | ⬜ Not Started |

**Exit Criteria:**
- [ ] Command palette opens in < 100ms
- [ ] Fuzzy search finds commands
- [ ] All app actions accessible via palette

### Phase 2: Slash Commands (P0 - Critical)

In-editor quick insertions.

| ID | Feature | Description | Status |
|----|---------|-------------|--------|
| BETA-2.1 | Slash trigger | Detect / at line start | ⬜ Not Started |
| BETA-2.2 | Command menu | Popup menu with available commands | ⬜ Not Started |
| BETA-2.3 | /table | Insert table template | ⬜ Not Started |
| BETA-2.4 | /code | Insert fenced code block | ⬜ Not Started |
| BETA-2.5 | /link | Insert link with URL prompt | ⬜ Not Started |
| BETA-2.6 | /image | Insert image with file picker | ⬜ Not Started |
| BETA-2.7 | /toc | Insert table of contents | ⬜ Not Started |

**Exit Criteria:**
- [ ] Slash menu appears on / keystroke
- [ ] All slash commands insert correct markdown
- [ ] Menu dismisses on escape or click outside

### Phase 3: Git Integration (P1 - Important)

Basic Git operations within the app.

| ID | Feature | Description | Status |
|----|---------|-------------|--------|
| BETA-3.1 | Git detection | Detect if workspace is a git repo | ⬜ Not Started |
| BETA-3.2 | Status indicator | Show current branch in status bar | ⬜ Not Started |
| BETA-3.3 | File status | Show modified/staged/untracked status | ⬜ Not Started |
| BETA-3.4 | Stage files | Stage selected files | ⬜ Not Started |
| BETA-3.5 | Commit | Commit with message | ⬜ Not Started |
| BETA-3.6 | Push/Pull | Sync with remote | ⬜ Not Started |
| BETA-3.7 | Branch switching | View and switch branches | ⬜ Not Started |
| BETA-3.8 | Credential storage | Store credentials in Keychain | ⬜ Not Started |

**Exit Criteria:**
- [ ] Can commit changes from within app
- [ ] Can push to remote (SSH and HTTPS)
- [ ] Branch name visible in UI

### Phase 4: Clipboard & Media (P1 - Important)

Image handling and clipboard integration.

| ID | Feature | Description | Status |
|----|---------|-------------|--------|
| BETA-4.1 | Image paste | Paste image from clipboard | ⬜ Not Started |
| BETA-4.2 | Image storage | Save pasted images to ./assets/ | ⬜ Not Started |
| BETA-4.3 | Markdown insertion | Auto-insert image markdown link | ⬜ Not Started |
| BETA-4.4 | Drag and drop | Drop images from Finder | ⬜ Not Started |
| BETA-4.5 | Image preview | Preview images in editor gutter | ⬜ Not Started |
| BETA-4.6 | Screenshot capture | Capture and insert screenshot | ⬜ Not Started |

**Exit Criteria:**
- [ ] ⌘V pastes image and inserts markdown
- [ ] Images saved to ./assets/ folder
- [ ] Drag-drop from Finder works

### Phase 5: Editor Enhancements (P2 - Nice to Have)

Quality of life improvements.

| ID | Feature | Description | Status |
|----|---------|-------------|--------|
| BETA-5.1 | Link autocomplete | Suggest internal links | ⬜ Not Started |
| BETA-5.2 | Emoji shortcodes | :emoji: completion | ⬜ Not Started |
| BETA-5.3 | Scroll sync | Bidirectional editor/preview sync | ⬜ Not Started |
| BETA-5.4 | Multiple tabs | Tab bar for multiple documents | ⬜ Not Started |
| BETA-5.5 | Find in folder | Search across all files | ⬜ Not Started |

**Exit Criteria:**
- [ ] Link suggestions appear while typing [[
- [ ] Emoji picker on : keystroke
- [ ] Scroll sync works bidirectionally

---

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| SwiftGit2 | 1.0.0+ | Git operations |
| KeychainAccess | 4.2.0+ | Credential storage |

---

## Acceptance Criteria (Beta Complete)

- [ ] All MVP features stable
- [ ] Command palette fully functional
- [ ] All slash commands working
- [ ] Git commit/push/pull working
- [ ] Image paste and drag-drop working
- [ ] Multiple document tabs
- [ ] No critical bugs

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| SwiftGit2 compatibility | High | Test early with SSH/HTTPS, have CLI fallback |
| Large image handling | Medium | Compress images on paste, configurable quality |
| Slash command conflicts | Low | Escape sequence for literal / |

---

## Notes

_Update this section as development progresses._

---

**Last Updated:** 2024-12-13
**Status:** 🔴 Not Started
