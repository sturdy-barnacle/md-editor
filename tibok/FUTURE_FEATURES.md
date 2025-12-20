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

---

## ARCHIVED: Completed Features

The following features were planned and have been successfully shipped:

### Epic: Git Branch Management ✅
**Status:** Shipped in Beta v0.6 (December 18, 2024)

Complete Git branch operations integrated into the app:
- View all local branches in sidebar (collapsible list)
- Create new branches with validation
- Switch branches with smart uncommitted changes handling
- Delete branches with safety confirmations
- Protected branch detection (main/master)
- Smart switching: options to stash or bring changes when switching branches

**Documentation:** See CHANGELOG.md v0.6 and user_docs/features/git-integration.md

### Epic: Stash Management ✅
**Status:** Shipped in Beta v0.6 (December 18, 2024)

Complete stash workflow for temporary change storage:
- View all stashes in collapsible list with messages
- Create stash with optional message
- Apply stash (keep in list) or Pop stash (apply and remove)
- Drop/delete stashes
- Integrated with branch switching

**Documentation:** See CHANGELOG.md v0.6 and user_docs/features/git-integration.md

### Epic: Smart Workspace Filtering ✅
**Status:** Shipped in Beta v0.7 (December 19, 2024)

Performance optimization with intelligent folder filtering:
- FolderScanCache service (183 lines) with 1-hour TTL
- Smart folder scanning with depth limiting and early termination
- Automatic skip list: node_modules, .git, .build, images, etc.
- 95% faster workspace opening with caching
- Lazy evaluation: folders scanned only when expanded
- Thread-safe with NSLock protection

**Documentation:** See CHANGELOG.md v0.7 and user_docs/features/performance-optimizations.md

### Epic: Service Layer Refactoring (Phase 2) ✅
**Status:** Shipped in Beta v0.7 (December 19, 2024)

Architectural improvement with 9 focused service classes:
- DocumentManager (265 lines) - Tab/document lifecycle
- WorkspaceService (120 lines) - Workspace management
- CommandService (175 lines) - Command palette
- UIStateService (32 lines) - Notifications
- ExportService (700+ lines) - PDF/HTML/RTF exports
- FileOperationsService (110 lines) - File I/O
- FolderScanCache (183 lines) - Performance caching
- FrontmatterCacheService - Metadata caching
- LogService - Centralized logging
- ImageUploadService (330 lines) - WordPress image uploads

**Result:** AppState simplified from 1606 to 1230 lines (23% reduction)

**Documentation:** See CHANGELOG.md v0.7

### Epic: WordPress Publishing ✅
**Status:** Shipped in Beta v0.6 (December 18, 2024)

Direct publishing to WordPress via REST API v2:
- Application Password authentication (secure, revocable)
- Keychain storage for credentials
- Frontmatter integration (title, categories, draft status, excerpt)
- Image upload to WordPress Media Library (PNG, JPG, GIF, WebP, SVG)
- Smart defaults configurable in Settings
- Test connection button for validation
- Browser integration (opens published post)
- Command palette integration ("Publish to WordPress")

**Documentation:** See CHANGELOG.md v0.6 and user_docs/features/wordpress-publishing.md

### Test Coverage Expansion ✅
**Status:** Shipped in Beta v0.7 (December 19, 2024)

Massive increase in automated test coverage:
- **115 automated tests** (up from 21, 447% increase)
- Swift Testing framework for new tests
- 6 new test suites: GitServiceTests, ServiceLayerTests, WordPressTests, FolderScanCacheTests, KeyboardShortcutsTests, DocumentTests
- CI/CD infrastructure with GitHub Actions

**Documentation:** See CHANGELOG.md v0.7 and TEST_REPORT.md

### CI/CD Infrastructure ✅
**Status:** Shipped in Beta v0.7 (December 19, 2024)

Automated testing pipeline:
- GitHub Actions workflow on every push/PR
- macOS 15 runner with Xcode 15.4
- Automated `swift build` and `swift test`
- Test artifact archiving
- Regression detection

**Documentation:** See CHANGELOG.md v0.7 and .github/workflows/test.yml

### UX Polish: Tab Width Stabilization ✅
**Status:** Shipped in Beta v0.7 (December 19, 2024)

Professional UI refinement for document tabs:
- **Fixed tab width** - Tabs no longer shift when documents become modified or hovered
- **Reserved space** - Save indicator always reserves 6pt, close button reserves 14pt
- **Smooth transitions** - 150ms easeInOut fade animations for save dot and close button
- **Prevented clicks** - Invisible close button disabled with `.allowsHitTesting(false)` to prevent accidental closes
- **Implementation** - Changed from conditional rendering (`if` statements) to conditional visibility (`.opacity()` modifiers)
- **Code quality** - Minimal surgical change (15 lines in 1 file), no breaking changes

**Result:** Professional UX matching macOS design patterns (Safari, Xcode) with smooth, responsive tab interactions

**Documentation:** See CHANGELOG.md v0.7

---

**Note:** This document contains only future work. For completed features and recent changes, see CHANGELOG.md.
