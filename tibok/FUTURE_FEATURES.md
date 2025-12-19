# Future Features & Epics

This document tracks planned features and UX improvements for future development.

---

## UX Improvement: Git UI Relocation

**Status:** Design Discussion
**Priority:** Low
**Estimated Effort:** 1-2 days (after design decision)

### Current State

Git panel is located in left sidebar below Workspace/Recent/Favorites sections.

### User Feedback

"we should probably consider moving the git module elsewhere in the UI"

### Design Options

#### Option 1: Keep in Sidebar (Status Quo)
**Pros:**
- Familiar location
- Quick access
- Consistent with VS Code, Xcode patterns

**Cons:**
- Competes for space with file navigation
- Can feel cramped with many changes
- Scrolling required if many sections expanded

#### Option 2: Bottom Panel
**Pros:**
- More horizontal space for file paths
- Common pattern (VS Code, JetBrains IDEs)
- Can show more files without scrolling
- Keeps sidebar focused on navigation

**Cons:**
- Reduces vertical space for editor
- Requires new bottom panel UI component
- More clicks to access if panel closed

#### Option 3: Right Inspector Panel
**Pros:**
- Keeps sidebar for navigation only
- More space for diff views in future
- Consistent with macOS inspector pattern

**Cons:**
- Inspector currently used for Frontmatter
- Would need tabbed interface or multi-panel
- Less discoverable for new users

#### Option 4: Floating Panel
**Pros:**
- Maximum flexibility
- Can be positioned anywhere
- Can be closed completely

**Cons:**
- Window management complexity
- Can obscure editor content
- Not common in markdown editors

#### Option 5: Status Bar Integration
**Pros:**
- Always visible, minimal space
- Quick branch switching
- Lightweight for simple workflows

**Cons:**
- Limited space for file lists
- Hard to see many changes at once
- Doesn't scale for complex operations

### Recommendation

**Preferred:** Option 2 (Bottom Panel)

**Reasoning:**
- Standard pattern in developer tools
- Better use of screen real estate
- Sidebar stays focused on file navigation
- Room for future Git features (diff view, history, blame)

**Implementation phases:**
1. Create BottomPanelView component
2. Move Git section to bottom panel
3. Add panel toggle to view menu
4. Add panel resize drag handle
5. Persist panel height in UserDefaults

### Questions to Answer Before Implementation

1. Should bottom panel be Git-only or support multiple tools (terminal, AI, search)?
2. What's the default panel height? (200px? 300px?)
3. Should panel auto-open when Git operation triggered?
4. Keyboard shortcut for toggle? (Cmd+Shift+G?)
5. Should panel remember open/closed state per workspace?

---

## Future: Plugin Ecosystem Growth

**Status:** Not Planned (Phase 2 completed, evaluate after user adoption)
**Priority:** Low (No immediate community plugins yet)
**Depends On:** First third-party plugins created by community

### Current State

Phase 2 plugin system is complete with:
- Folder-based discovery (`~/Library/Application Support/tibok/Plugins/ThirdParty/`)
- Simple installation (download ZIP, extract folder)
- Plugin registry (`PLUGIN_REGISTRY.md`)
- Complete developer guides

### If Plugin Ecosystem Grows

If community creates 10+ quality plugins, consider:

1. **Plugin Registry Improvements**
   - Better discovery/search mechanism
   - Category/tagging system
   - Community reviews/ratings
   - Download statistics

2. **Automated Distribution**
   - Simple update mechanism (users notified of new versions)
   - One-click installation (rather than manual ZIP extraction)
   - Dependency resolution if plugins depend on each other

3. **Developer Tools**
   - Plugin testing framework
   - CI/CD integration for plugin repos
   - Code signing infrastructure
   - Community development forum

4. **Security Enhancements**
   - Code signing verification
   - Automated security scanning
   - Permission system (plugins declare what they access)
   - Sandbox/capability restrictions

### Recommendation

**Wait and see approach:**
- Monitor community adoption
- Gather feedback from early plugin developers
- Only implement advanced features if demand is high
- Keep it simple unless ecosystem demands complexity

### Notes

- Plugin system is production-ready for individual developers
- Manual installation is fine when plugin count is low
- Complexity should grow only if ecosystem grows
- Community feedback will inform future enhancements
- Current approach (GitHub + registry) is sufficient for MVP
