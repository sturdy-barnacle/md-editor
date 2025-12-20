# Testing Strategy - tibok

> Comprehensive testing approach for tibok

## Overview

This document defines the testing strategy for tibok, ensuring quality across all releases from MVP through v1.0.

---

## Testing Pyramid

```
                    ┌─────────┐
                   ╱    E2E    ╲        ~10%
                  ╱─────────────╲
                 ╱  Integration   ╲      ~20%
                ╱─────────────────╲
               ╱     Unit Tests     ╲    ~70%
              ╱───────────────────────╲
```

| Layer | Coverage Target | Tools |
|-------|-----------------|-------|
| Unit | 70%+ | Swift Testing |
| Integration | Critical paths | XCTest + Swift Testing |
| E2E | Happy paths | XCUITest |

---

## Testing Framework

### Primary: Swift Testing (Xcode 16+)

```swift
import Testing

@Test("Document loads from valid markdown file")
func documentLoadsFromFile() async throws {
    let url = URL(fileURLWithPath: "/tmp/test.md")
    try "# Hello".write(to: url, atomically: true, encoding: .utf8)

    let doc = try await Document.load(from: url)

    #expect(doc.content == "# Hello")
    #expect(doc.title == "Hello")
}

@Test("Syntax highlighter identifies headings", arguments: [
    ("# H1", 1),
    ("## H2", 2),
    ("### H3", 3),
])
func headingLevels(markdown: String, expectedLevel: Int) {
    let highlighter = MarkdownHighlighter()
    let result = highlighter.parse(markdown)

    #expect(result.headings.first?.level == expectedLevel)
}
```

### Secondary: XCTest (UI Testing)

```swift
import XCTest

class tibokUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    func testToggleBoldWithKeyboardShortcut() throws {
        let editor = app.textViews["EditorTextView"]
        editor.click()
        editor.typeText("hello")
        editor.typeKey("a", modifierFlags: .command) // Select all
        editor.typeKey("b", modifierFlags: .command) // Bold

        XCTAssertTrue(editor.value as? String == "**hello**")
    }
}
```

---

## Test Categories

### 1. Unit Tests

#### Models

| Test Suite | Coverage |
|------------|----------|
| DocumentTests | Load, save, metadata extraction |
| WorkspaceTests | File tree, watched directories |
| PreferencesTests | Settings persistence |

```swift
@Suite("Document Model")
struct DocumentTests {
    @Test func extractsTitleFromFirstHeading() {
        let doc = Document(content: "# My Title\n\nContent here")
        #expect(doc.title == "My Title")
    }

    @Test func calculatesWordCount() {
        let doc = Document(content: "One two three four five")
        #expect(doc.wordCount == 5)
    }

    @Test func detectsModifiedState() {
        var doc = Document(content: "Original")
        doc.content = "Modified"
        #expect(doc.isModified == true)
    }
}
```

#### ViewModels

| Test Suite | Coverage |
|------------|----------|
| EditorViewModelTests | Text operations, undo/redo |
| PreviewViewModelTests | HTML generation, scroll sync |
| SidebarViewModelTests | File tree operations |

```swift
@Suite("Editor ViewModel")
struct EditorViewModelTests {
    @Test func toggleBoldWrapsSelection() {
        let vm = EditorViewModel()
        vm.content = "hello world"
        vm.selectedRange = NSRange(location: 0, length: 5)

        vm.toggleBold()

        #expect(vm.content == "**hello** world")
    }

    @Test func toggleBoldRemovesExistingBold() {
        let vm = EditorViewModel()
        vm.content = "**hello** world"
        vm.selectedRange = NSRange(location: 2, length: 5)

        vm.toggleBold()

        #expect(vm.content == "hello world")
    }
}
```

#### Services

| Test Suite | Coverage |
|------------|----------|
| StorageServiceTests | File read/write, bookmarks |
| GitServiceTests | Status, commit, push (mocked) |
| ExportServiceTests | PDF, HTML generation |
| AIServiceTests | API calls (mocked) |

```swift
@Suite("Export Service")
struct ExportServiceTests {
    @Test func generatesValidHTML() async throws {
        let service = ExportService()
        let doc = Document(content: "# Title\n\nParagraph")

        let html = try await service.exportHTML(doc)

        #expect(html.contains("<h1>Title</h1>"))
        #expect(html.contains("<p>Paragraph</p>"))
    }
}
```

#### Utilities

| Test Suite | Coverage |
|------------|----------|
| MarkdownParserTests | Parsing correctness |
| MarkdownHighlighterTests | Syntax highlighting |
| KeychainHelperTests | Credential storage |

### 2. Integration Tests

Test component interactions without mocking.

```swift
@Suite("Document Lifecycle Integration")
struct DocumentLifecycleTests {
    @Test func saveAndReloadPreservesContent() async throws {
        let storage = LocalStorageService()
        let url = FileManager.default.temporaryDirectory.appending(path: "test.md")

        // Save
        let original = Document(content: "# Test\n\nContent")
        try await storage.save(original, to: url)

        // Reload
        let loaded = try await storage.load(from: url)

        #expect(loaded.content == original.content)
    }
}
```

### 3. UI Tests (E2E)

Test complete user workflows.

```swift
class EditorWorkflowTests: XCTestCase {
    func testCreateEditSaveDocument() throws {
        let app = XCUIApplication()
        app.launch()

        // Create new document
        app.menuItems["New"].click()

        // Type content
        let editor = app.textViews.firstMatch
        editor.typeText("# My Document\n\nHello, world!")

        // Save
        app.typeKey("s", modifierFlags: .command)

        // Verify save dialog or saved indicator
        XCTAssertTrue(app.staticTexts["Saved"].waitForExistence(timeout: 2))
    }
}
```

---

## Performance Testing

### Benchmarks

```swift
@Suite("Performance")
struct PerformanceTests {
    @Test func largeFileOpenTime() async throws {
        // Generate 1MB markdown file
        let content = String(repeating: "# Heading\n\nParagraph content here.\n\n", count: 10000)
        let url = FileManager.default.temporaryDirectory.appending(path: "large.md")
        try content.write(to: url, atomically: true, encoding: .utf8)

        let start = Date()
        let _ = try await Document.load(from: url)
        let elapsed = Date().timeIntervalSince(start)

        #expect(elapsed < 1.0, "Large file should open in < 1s")
    }

    @Test func syntaxHighlightingPerformance() {
        let content = String(repeating: "**bold** and *italic* and `code`\n", count: 1000)
        let highlighter = MarkdownHighlighter()

        let start = Date()
        _ = highlighter.highlight(content)
        let elapsed = Date().timeIntervalSince(start)

        #expect(elapsed < 0.1, "Highlighting should complete in < 100ms")
    }
}
```

### Performance Targets

| Metric | Target | Test |
|--------|--------|------|
| App launch | < 500ms | Measure in XCUITest |
| File open (1MB) | < 1s | Unit test |
| Preview render | < 50ms | Unit test |
| Typing latency | < 16ms | Manual profiling |

---

## Mocking Strategy

### Protocol-Based Mocks

```swift
protocol GitServiceProtocol {
    func status() async throws -> GitStatus
    func commit(message: String) async throws
    func push() async throws
}

class MockGitService: GitServiceProtocol {
    var statusToReturn: GitStatus = .clean
    var commitCalled = false
    var pushCalled = false

    func status() async throws -> GitStatus {
        return statusToReturn
    }

    func commit(message: String) async throws {
        commitCalled = true
    }

    func push() async throws {
        pushCalled = true
    }
}
```

### Usage in Tests

```swift
@Test func commitButtonDisabledWhenClean() {
    let mockGit = MockGitService()
    mockGit.statusToReturn = .clean

    let vm = GitViewModel(gitService: mockGit)

    #expect(vm.canCommit == false)
}
```

---

## Test Data

### Fixtures Directory

```
Tests/
├── Fixtures/
│   ├── Documents/
│   │   ├── simple.md
│   │   ├── complex.md
│   │   ├── with-images.md
│   │   └── large-file.md
│   ├── Git/
│   │   └── sample-repo/
│   └── Export/
│       ├── expected-output.html
│       └── expected-output.pdf
```

### Loading Fixtures

```swift
extension XCTestCase {
    func loadFixture(_ name: String) throws -> String {
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: name, withExtension: "md", subdirectory: "Fixtures/Documents") else {
            throw TestError.fixtureNotFound(name)
        }
        return try String(contentsOf: url)
    }
}
```

---

## CI/CD Integration

### GitHub Actions Workflow

```yaml
name: Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_16.app

      - name: Build
        run: xcodebuild build -scheme tibok -destination 'platform=macOS'

      - name: Unit Tests
        run: xcodebuild test -scheme tibok -destination 'platform=macOS' -only-testing:tibokTests

      - name: UI Tests
        run: xcodebuild test -scheme tibok -destination 'platform=macOS' -only-testing:tibokUITests
```

---

## Coverage Requirements

| Epic | Minimum Coverage |
|------|------------------|
| MVP | 60% |
| Beta | 70% |
| v1.0 | 80% |

### Coverage Exclusions

- SwiftUI View code (test via UI tests)
- Third-party wrapper code
- Debug/development utilities

---

## Testing Checklist

### Before Each PR

- [ ] All unit tests pass
- [ ] No new compiler warnings
- [ ] Test coverage maintained or improved
- [ ] New features have tests

### Before Each Release

- [ ] All tests pass (unit + integration + UI)
- [ ] Performance benchmarks pass
- [ ] Manual smoke test on clean install
- [ ] Test on minimum supported macOS version

---

## Manual Testing

### Smoke Test Script

1. [ ] Launch app (fresh install)
2. [ ] Create new document
3. [ ] Type markdown with formatting
4. [ ] Verify preview renders correctly
5. [ ] Save document
6. [ ] Close and reopen document
7. [ ] Export to PDF
8. [ ] Export to HTML

### Accessibility Testing

1. [ ] Enable VoiceOver, navigate app
2. [ ] Verify all controls are labeled
3. [ ] Test keyboard-only navigation
4. [ ] Check high contrast mode

---

**Last Updated:** 2024-12-13
