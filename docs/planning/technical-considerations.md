# Technical Considerations

This document tracks architectural decisions, technical debt, and considerations for future development.

## Current Technical Debt

### Build System
- **KaTeX Resource Warnings** (Priority: Low)
  - 23 KaTeX font/CSS files trigger SPM "unhandled files" warnings
  - **Solution**: Add `.process("Resources/katex/")` to Package.swift
  - **Impact**: None on functionality, just noisy warnings
  - **Estimated effort**: 5 minutes

### Plugin System

#### Phase 1 (Completed)
- ✅ Compile-time plugin registration
- ✅ Enable/disable functionality
- ✅ Command source tracking
- ✅ State persistence via UserDefaults

#### Phase 2 (Planned)
- [ ] External plugin loading
- [ ] Plugin manifest (JSON)
- [ ] Plugin discovery from `~/Library/Application Support/tibok/Plugins/`

#### Security & Sandboxing Considerations

**Current State:**
- Plugins run in-process with full app permissions
- No sandboxing or isolation
- Suitable for built-in plugins only

**Future Requirements for External Plugins:**

1. **Sandboxing Strategy**
   - **Option A**: XPC Service per plugin
     - Pros: Strong isolation, OS-level security
     - Cons: Complex IPC, performance overhead
   - **Option B**: App Sandbox extensions
     - Pros: Simpler, faster
     - Cons: Limited isolation
   - **Recommendation**: Start with App Sandbox extensions, evaluate XPC for v2.0

2. **Permission System**
   ```swift
   enum PluginPermission {
       case filesystem(scope: FileScope)  // read-only, write, specific paths
       case network(scope: NetworkScope)  // outbound only, specific domains
       case clipboard                     // read/write clipboard
       case ai                           // access AI providers
   }
   ```

3. **Plugin API Versioning**
   - Semantic versioning for plugin API
   - `minAppVersion` in plugin manifest
   - Backward compatibility guarantees for minor versions
   - Breaking changes only in major versions

4. **Code Signing**
   - Optional for beta
   - Required for public plugin marketplace
   - Developer ID signing + notarization
   - Revocation list for compromised plugins

5. **Plugin State Migration**
   - Version plugin settings with plugin version
   - Provide migration hooks in plugin protocol
   - Fallback to defaults on migration failure

#### Plugin Developer Experience

**SDK Requirements:**
- Protocol definitions (TibokPlugin, PluginContext)
- Base classes for common plugin types
- Xcode project templates
- Sample plugins (3-5 examples)
- Documentation and guides
- Testing utilities

**Developer Portal:**
- Plugin submission workflow
- Review guidelines
- API documentation
- Community forum

## Architecture Strengths

### Current Wins
1. **Clean separation** between core and plugins
2. **Well-documented** user features with comprehensive docs
3. **Flexible frontmatter parsing** supporting multiple formats
4. **Extensible webhook system** with good abstraction
5. **SwiftUI + AppKit hybrid** leverages strengths of both

### Future-Proofing

#### Settings Migration
- Current: UserDefaults for all settings
- Future: Consider Settings bundle + iCloud sync
- Migration path: Codable settings struct with version field

#### Document Model Evolution
- Current: Simple MarkdownDocument struct
- Future: May need document packages for complex content
- Consider: Document bundle format (.mdpkg) for v2.0

#### Performance Optimization Targets

| Operation | Current | Target | Notes |
|-----------|---------|--------|-------|
| File open (1MB) | ~100ms | <50ms | Consider lazy loading |
| Preview render | ~50ms | <30ms | Debounce optimization |
| Syntax highlight | ~20ms | <16ms | Already good |
| Plugin load | N/A | <100ms | For external plugins |

## Testing Strategy

### Current Coverage
- Unit tests for Document model
- Manual testing for UI features

### Needed Coverage
- [ ] Plugin lifecycle tests
- [ ] Webhook delivery tests
- [ ] Frontmatter parser tests (edge cases)
- [ ] Git integration tests (mock repository)
- [ ] Syntax highlighting performance tests

### QA Checklist (v0.6 Beta)

#### Plugin System
- [ ] Enable/disable plugin persists across restarts
- [ ] Disabling plugin removes all its commands
- [ ] Re-enabling plugin restores commands
- [ ] Multiple plugins can be disabled simultaneously
- [ ] Settings UI shows correct plugin metadata

#### Webhooks
- [ ] Webhook fires on document save
- [ ] Webhook fires on document export
- [ ] Webhook fires on Git push
- [ ] Template variables correctly substituted
- [ ] Test button sends valid request
- [ ] Failed webhooks don't block UI
- [ ] Multiple webhooks can fire for same event

#### Frontmatter
- [ ] YAML parsing handles all test cases
- [ ] TOML parsing handles all test cases
- [ ] Date-only mode formats correctly
- [ ] Date+time mode includes timezone
- [ ] Timezone changes update existing dates
- [ ] Inspector syncs with manual edits
- [ ] Custom fields persist correctly
- [ ] Removing frontmatter doesn't corrupt document

#### Cross-Feature Integration
- [ ] Plugin commands work with frontmatter editor
- [ ] Webhooks fire when using plugin commands
- [ ] Git commits include frontmatter changes
- [ ] Multiple tabs with different frontmatter formats

## Decision Log

### 2025-12-15: Plugin Architecture
- **Decision**: Phase 1 compile-time plugins only
- **Rationale**: Faster iteration, defer security complexity
- **Trade-off**: Limited extensibility until Phase 2
- **Revisit**: After v0.6 release, evaluate external plugin demand

### 2025-12-15: Frontmatter Timezone Handling
- **Decision**: Use configurable timezone in Settings
- **Rationale**: Better UX than per-document timezone
- **Trade-off**: All documents use same timezone
- **Alternative considered**: Per-document timezone (too complex)

### 2025-12-14: Syntax Highlighting Fix
- **Decision**: Color-only attributes instead of font changes
- **Rationale**: Prevents layout recalculation ("shudder")
- **Impact**: Improved typing performance
- **Technical detail**: Use `addAttributes()` not `setAttributes()`

## Future Considerations

### v1.0 and Beyond

#### iPad Companion App
- Native SwiftUI (not Catalyst)
- Shared document sync via CloudKit
- Simplified UI for touch interface
- Full keyboard support for iPad Pro

#### Collaborative Editing
- Operational Transform or CRDT for conflict resolution
- WebSocket-based real-time sync
- User presence indicators
- Comment/review system

#### Obsidian Vault Compatibility
- Support `[[wikilinks]]` syntax
- Graph view of linked documents
- Backlinks panel
- Dataview-style queries

#### Plugin Marketplace
- In-app discovery and installation
- Revenue sharing for paid plugins (70/30 split)
- Curated collections
- User reviews and ratings

## Notes

- Keep this document updated as architectural decisions are made
- Link to specific code locations for complex decisions
- Include migration strategies when changing core systems
- Document trade-offs for future reference
