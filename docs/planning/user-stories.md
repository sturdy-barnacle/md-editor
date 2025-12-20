# User Stories - tibok

> Living document of user stories derived from PRD and technical requirements

## Overview

This document captures user stories for **tibok** (tibok.app) organized by persona and epic. Update as requirements evolve and feedback is gathered.

---

## Personas

### Developer Dave
Technical writer, writes documentation and README files, uses Git daily, values keyboard shortcuts.

### Blogger Beth
Content creator, publishes to Jekyll blog, needs simple export options, occasional AI help.

### Writer Will
Long-form writer, values distraction-free editing, uses multiple documents, wants local storage.

---

## Epic: MVP (v0.1)

### Editor

| ID | Story | Persona | Priority | Status |
|----|-------|---------|----------|--------|
| US-001 | As a writer, I want to open .md files by double-clicking in Finder so I can start editing immediately | Will | P0 | ⬜ |
| US-002 | As a developer, I want syntax highlighting for markdown so I can visually parse the document structure | Dave | P0 | ⬜ |
| US-003 | As a writer, I want auto-save so I never lose my work if the app crashes | Will | P0 | ⬜ |
| US-004 | As a developer, I want line numbers so I can reference specific lines in documentation | Dave | P1 | ⬜ |
| US-005 | As a writer, I want to see word count so I can track my writing progress | Will | P1 | ⬜ |
| US-006 | As a writer, I want undo/redo so I can experiment with changes safely | Will | P0 | ⬜ |
| US-007 | As a developer, I want find and replace so I can refactor text quickly | Dave | P1 | ⬜ |

### Preview

| ID | Story | Persona | Priority | Status |
|----|-------|---------|----------|--------|
| US-008 | As a blogger, I want live preview so I can see how my post will look while writing | Beth | P0 | ⬜ |
| US-009 | As a writer, I want split view so I can see editor and preview side by side | Will | P0 | ⬜ |
| US-010 | As a developer, I want code blocks to be syntax highlighted in preview | Dave | P1 | ⬜ |
| US-011 | As a blogger, I want preview themes so I can match my blog's styling | Beth | P2 | ⬜ |

### File Management

| ID | Story | Persona | Priority | Status |
|----|-------|---------|----------|--------|
| US-012 | As a developer, I want to open a project folder so I can work on multiple related files | Dave | P1 | ⬜ |
| US-013 | As a writer, I want a file sidebar so I can navigate between documents | Will | P1 | ⬜ |
| US-014 | As a blogger, I want to create new .md files from within the app | Beth | P1 | ⬜ |
| US-015 | As a writer, I want recent files so I can quickly resume work | Will | P1 | ⬜ |

### Export

| ID | Story | Persona | Priority | Status |
|----|-------|---------|----------|--------|
| US-016 | As a blogger, I want to export to PDF so I can share formatted documents | Beth | P1 | ⬜ |
| US-017 | As a developer, I want to export to HTML so I can embed docs in websites | Dave | P1 | ⬜ |

---

## Epic: Beta (v0.5)

### Quick Actions

| ID | Story | Persona | Priority | Status |
|----|-------|---------|----------|--------|
| US-018 | As a developer, I want a command palette so I can access all actions via keyboard | Dave | P0 | ⬜ |
| US-019 | As a blogger, I want slash commands so I can quickly insert tables and code blocks | Beth | P0 | ⬜ |
| US-020 | As a writer, I want emoji shortcodes so I can add emoji without leaving the keyboard | Will | P2 | ⬜ |
| US-021 | As a developer, I want link autocomplete so I can quickly reference other files | Dave | P2 | ⬜ |

### Git Integration

| ID | Story | Persona | Priority | Status |
|----|-------|---------|----------|--------|
| US-022 | As a developer, I want to see git status so I know which files have changed | Dave | P1 | ⬜ |
| US-023 | As a developer, I want to commit changes without leaving the editor | Dave | P1 | ⬜ |
| US-024 | As a developer, I want to push/pull so I can sync with my team | Dave | P1 | ⬜ |
| US-025 | As a developer, I want to switch branches so I can work on different features | Dave | P1 | ⬜ |
| US-026 | As a developer, I want credentials stored in Keychain so I don't re-enter them | Dave | P1 | ⬜ |

### Clipboard & Media

| ID | Story | Persona | Priority | Status |
|----|-------|---------|----------|--------|
| US-027 | As a blogger, I want to paste images from clipboard so I can add screenshots easily | Beth | P1 | ⬜ |
| US-028 | As a blogger, I want images saved to an assets folder so my posts are portable | Beth | P1 | ⬜ |
| US-029 | As a writer, I want to drag-drop images from Finder | Will | P1 | ⬜ |
| US-030 | As a developer, I want to capture screenshots directly into the editor | Dave | P2 | ⬜ |

### Editor Enhancements

| ID | Story | Persona | Priority | Status |
|----|-------|---------|----------|--------|
| US-031 | As a writer, I want multiple tabs so I can work on several documents at once | Will | P2 | ⬜ |
| US-032 | As a developer, I want scroll sync between editor and preview | Dave | P2 | ⬜ |
| US-033 | As a developer, I want to search across all files in a folder | Dave | P2 | ⬜ |

---

## Epic: v1.0

### AI Assistance

| ID | Story | Persona | Priority | Status |
|----|-------|---------|----------|--------|
| US-034 | As a blogger, I want AI to suggest improvements to my writing | Beth | P0 | ⬜ |
| US-035 | As a writer, I want AI to help me continue writing when I'm stuck | Will | P0 | ⬜ |
| US-036 | As a blogger, I want to generate summaries of my posts | Beth | P1 | ⬜ |
| US-037 | As a developer, I want to use my own API key for unlimited AI usage | Dave | P1 | ⬜ |
| US-038 | As a writer, I want to create custom AI prompts for my workflow | Will | P2 | ⬜ |

### Jekyll Publishing

| ID | Story | Persona | Priority | Status |
|----|-------|---------|----------|--------|
| US-039 | As a blogger, I want to edit frontmatter with a GUI so I don't make YAML errors | Beth | P0 | ⬜ |
| US-040 | As a blogger, I want to publish posts with one click | Beth | P0 | ⬜ |
| US-041 | As a blogger, I want a PR created automatically so my post goes through review | Beth | P1 | ⬜ |
| US-042 | As a blogger, I want images copied to the Jekyll assets folder automatically | Beth | P1 | ⬜ |

### Cloud Sync

| ID | Story | Persona | Priority | Status |
|----|-------|---------|----------|--------|
| US-043 | As a writer, I want my files synced to iCloud so I can access them from any Mac | Will | P1 | ⬜ |
| US-044 | As a writer, I want to see sync status so I know my work is backed up | Will | P1 | ⬜ |
| US-045 | As a writer, I want to resolve conflicts when the same file is edited on two devices | Will | P2 | ⬜ |

### Webhooks

| ID | Story | Persona | Priority | Status |
|----|-------|---------|----------|--------|
| US-046 | As a developer, I want to trigger webhooks on save so I can automate workflows | Dave | P1 | ⬜ |
| US-047 | As a blogger, I want to notify my CMS when I publish a post | Beth | P1 | ⬜ |
| US-048 | As a developer, I want to test webhooks before enabling them | Dave | P2 | ⬜ |

### Plugins

| ID | Story | Persona | Priority | Status |
|----|-------|---------|----------|--------|
| US-049 | As a developer, I want to install plugins to extend functionality | Dave | P1 | ⬜ |
| US-050 | As a blogger, I want to install a Hugo exporter plugin for my blog | Beth | P1 | ⬜ |
| US-051 | As a writer, I want custom themes from the plugin gallery | Will | P2 | ⬜ |
| US-052 | As a developer, I want to add alternative AI providers via plugins | Dave | P2 | ⬜ |

### Freemium

| ID | Story | Persona | Priority | Status |
|----|-------|---------|----------|--------|
| US-053 | As a new user, I want to use the free tier to evaluate the app | Will | P0 | ⬜ |
| US-054 | As a power user, I want to upgrade to Pro for advanced features | Dave | P0 | ⬜ |
| US-055 | As a subscriber, I want to manage my subscription within the app | Beth | P1 | ⬜ |

---

## Future (v1.x)

| ID | Story | Persona | Priority | Status |
|----|-------|---------|----------|--------|
| US-056 | As a writer, I want collaborative editing so I can work with my editor in real-time | Will | P2 | ⬜ |
| US-057 | As a developer, I want Obsidian vault compatibility so I can migrate easily | Dave | P2 | ⬜ |
| US-058 | As a writer, I want an iPad app so I can write on my tablet | Will | P2 | ⬜ |

---

## Story Status Legend

| Symbol | Meaning |
|--------|---------|
| ⬜ | Not Started |
| 🟡 | In Progress |
| ✅ | Complete |
| ❌ | Blocked |
| 🔄 | Needs Revision |

---

## Change Log

| Date | Change | Stories Affected |
|------|--------|------------------|
| 2024-12-13 | Initial user stories created from PRD | All |

---

**Last Updated:** 2024-12-13
