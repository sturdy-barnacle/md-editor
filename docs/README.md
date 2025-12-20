# tibok Internal Documentation

This directory contains all internal documentation for the tibok project, organized by purpose.

## Directory Structure

### `planning/`
Planning documents, epics, user stories, and design specifications.

- **Epic Planning**: `epic-mvp-v0.1.md`, `epic-beta-v0.5.md`, `epic-v1.0.md`
- **User Stories**: `user-stories.md`
- **Architecture**: `ARCHITECTURE.md`, `technical-considerations.md`
- **Design**: `ui-design-spec.md`, `branding.md`, `design-assets.md`
- **Plugin Planning**: `plugins/` subdirectory
  - `plugin-api-specification.md` - Complete API reference
  - `plugin-security-model.md` - Security architecture
  - `dynamic-plugin-loading-roadmap.md` - Plugin system roadmap

### `releases/`
Release-related documentation.

- `CHANGELOG.md` - Version history and release notes
- `FUTURE_FEATURES.md` - Planned features and design discussions
- `APPSTORE_SUBMISSION.md` - App Store submission guide

### `development/`
Development guidelines and session notes.

- `CLAUDE.md` - Development guidelines for AI assistants
- `llms.txt` - LLM context file
- `sessions/` - Development session notes (historical)

### `architecture/`
Technical architecture and performance documentation.

- `PERFORMANCE_PLAN.md` - Performance optimization plans and results

### `registry/`
Plugin registry and community resources.

- `PLUGIN_REGISTRY.md` - Central registry of community-created plugins

### `progress/`
Daily progress notes (gitignored - not tracked in version control).

- Format: `YYYY-MM-DD_progress_notes.md`
- Updated throughout the day as work progresses

### `archive/`
Archived and completed documents (gitignored - not tracked in version control).

- Completed phase summaries
- Historical session notes
- Outdated test reports

## User Documentation

User-facing documentation is located in `tibok/user_docs/` (separate from internal docs).

## Documentation Conventions

### When Creating New Documentation

1. **User-facing docs** → `tibok/user_docs/`
   - Feature guides, FAQs, tutorials
   - Written for end users

2. **Planning docs** → `docs/planning/`
   - Epics, user stories, design specs
   - Plugin planning → `docs/planning/plugins/`

3. **Release docs** → `docs/releases/`
   - CHANGELOG updates
   - Future features planning
   - Release guides

4. **Development docs** → `docs/development/`
   - Development guidelines
   - Session notes (move to archive when outdated)

5. **Architecture docs** → `docs/architecture/`
   - Technical specifications
   - Performance plans

6. **Progress notes** → `docs/progress/`
   - Daily work logs
   - Format: `YYYY-MM-DD_progress_notes.md`

7. **Completed/outdated docs** → `docs/archive/`
   - Phase summaries
   - Historical session notes
   - Old test reports

### Path References

When referencing documentation in markdown files:

- **From user docs**: Use `../../../docs/` to reference internal docs
- **From planning docs**: Use relative paths within `docs/`
- **From release docs**: Use `../../tibok/user_docs/` for user docs
- **Plugin API docs**: Always reference `docs/planning/plugins/plugin-api-specification.md`

### Gitignore

The following directories are gitignored (not tracked):
- `docs/progress/` - Daily progress notes
- `docs/archive/` - Archived documents

All other documentation is tracked in version control.

