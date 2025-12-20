# User Story: Multiple Open Files (Tabs)

## Summary
As a user, I want to open multiple markdown files in tabs so that I can quickly switch between documents without losing my place.

## User Value
Writers often work with multiple related documents (e.g., chapters, notes, reference material). Currently, opening a new file replaces the current document, requiring users to re-open files frequently. Tabs would significantly improve workflow efficiency.

## Acceptance Criteria

### Tab Bar
- [ ] Tab bar appears below title bar when multiple files are open
- [ ] Each tab shows filename and close button
- [ ] Modified documents show indicator dot on tab
- [ ] Active tab is visually distinct
- [ ] Tabs can be reordered via drag & drop
- [ ] Tab bar is hidden when only one document is open (optional setting)

### Tab Interactions
- [ ] Click tab to switch documents
- [ ] Click X or middle-click to close tab
- [ ] Double-click tab to rename (if unsaved) or reveal in Finder (if saved)
- [ ] Right-click context menu: Close, Close Others, Close All, Reveal in Finder

### Keyboard Shortcuts
- [ ] ⌘1-9: Switch to tab by position
- [ ] ⌘⇧[ : Previous tab
- [ ] ⌘⇧] : Next tab
- [ ] ⌘W: Close current tab
- [ ] ⌘⇧T: Reopen last closed tab

### Behavior
- [ ] Opening a file adds new tab (doesn't replace current)
- [ ] New Document (⌘N) creates new tab
- [ ] Prompt to save unsaved changes when closing tab
- [ ] Remember open tabs on app quit/relaunch (optional setting)
- [ ] Sidebar file click opens in new tab or switches to existing tab if already open

### State Management
- [ ] Each tab maintains its own:
  - Document content
  - Cursor position
  - Scroll position
  - Undo/redo history
  - Find/replace state

## Technical Considerations

### Architecture Changes
- `AppState` needs to manage array of `Document` instead of single `currentDocument`
- Add `activeDocumentIndex` or `activeDocumentID` to track current tab
- Editor and Preview views need to observe active document changes
- Consider memory management for many open tabs

### UI Components
- New `TabBarView` component
- Tab overflow handling (scroll or dropdown for many tabs)
- Tab minimum/maximum width

### Data Model
```swift
class AppState {
    @Published var documents: [Document] = []
    @Published var activeDocumentID: UUID?

    var activeDocument: Document? {
        documents.first { $0.id == activeDocumentID }
    }
}
```

## Priority
High - Core productivity feature for v1.0

## Estimated Complexity
Large - Requires significant architectural changes

## Dependencies
None

## Related Features
- Session restore (remember open tabs)
- Recent files integration
- Workspace file tree integration
