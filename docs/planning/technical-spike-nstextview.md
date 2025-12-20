# Technical Spike: NSTextView Wrapper

> Research and implementation approach for the core editor component

## Objective

Design and validate the approach for wrapping NSTextView in SwiftUI for use as tibok's primary editor component.

---

## Why NSTextView?

SwiftUI's `TextEditor` is insufficient for a professional markdown editor:

| Feature | TextEditor | NSTextView |
|---------|------------|------------|
| Syntax highlighting | ❌ | ✅ NSAttributedString |
| Line numbers | ❌ | ✅ NSRulerView |
| Custom key bindings | Limited | ✅ Full control |
| Performance (large files) | Poor | ✅ Optimized |
| Undo/redo control | Basic | ✅ NSUndoManager |
| Text storage hooks | ❌ | ✅ NSTextStorage |

---

## Architecture

### Component Hierarchy

```
EditorView (SwiftUI)
└── NSViewRepresentable
    └── EditorScrollView (NSScrollView)
        ├── LineNumberRulerView (NSRulerView)
        └── EditorTextView (NSTextView)
            └── MarkdownTextStorage (NSTextStorage)
```

### Key Classes

#### 1. EditorTextView (NSTextView subclass)

```swift
class EditorTextView: NSTextView {
    // Custom text view with markdown-specific behavior

    var onTextChange: ((String) -> Void)?
    var onSelectionChange: ((NSRange) -> Void)?

    override func keyDown(with event: NSEvent) {
        // Handle custom shortcuts
        // Tab indentation
        // Auto-pair brackets
    }

    override func paste(_ sender: Any?) {
        // Handle image paste
    }
}
```

#### 2. MarkdownTextStorage (NSTextStorage subclass)

```swift
class MarkdownTextStorage: NSTextStorage {
    private let backingStore = NSMutableAttributedString()
    private let highlighter = MarkdownHighlighter()

    override func replaceCharacters(in range: NSRange, with str: String) {
        beginEditing()
        backingStore.replaceCharacters(in: range, with: str)
        edited(.editedCharacters, range: range, changeInLength: str.count - range.length)
        endEditing()
    }

    override func processEditing() {
        // Apply syntax highlighting to affected paragraphs only
        let paragraphRange = (string as NSString).paragraphRange(for: editedRange)
        highlighter.highlight(in: self, range: paragraphRange)
        super.processEditing()
    }
}
```

#### 3. LineNumberRulerView (NSRulerView subclass)

```swift
class LineNumberRulerView: NSRulerView {
    var font: NSFont = .monospacedSystemFont(ofSize: 12, weight: .regular)
    var textColor: NSColor = .secondaryLabelColor

    override func drawHashMarksAndLabels(in rect: NSRect) {
        // Draw line numbers aligned with text lines
    }

    func updateLineNumbers() {
        needsDisplay = true
    }
}
```

#### 4. NSViewRepresentable Wrapper

```swift
struct EditorViewRepresentable: NSViewRepresentable {
    @Binding var text: String
    @Binding var selectedRange: NSRange
    var configuration: EditorConfiguration

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = EditorTextView()

        // Configure scroll view
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = configuration.showLineNumbers

        // Set up text view
        textView.textStorage?.setAttributedString(
            NSAttributedString(string: text)
        )

        // Set up callbacks
        textView.onTextChange = { newText in
            DispatchQueue.main.async {
                self.text = newText
            }
        }

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        // Handle SwiftUI state changes
        guard let textView = nsView.documentView as? EditorTextView else { return }

        if textView.string != text {
            textView.string = text
        }
    }
}
```

---

## Syntax Highlighting

### Approach: Incremental Highlighting

Only re-highlight affected paragraphs on edit, not the entire document.

```swift
class MarkdownHighlighter {
    private let theme: HighlightTheme

    // Regex patterns for markdown elements
    private lazy var patterns: [(regex: NSRegularExpression, style: TextStyle)] = [
        (try! NSRegularExpression(pattern: "^#{1,6}\\s.*$", options: .anchorsMatchLines), .heading),
        (try! NSRegularExpression(pattern: "\\*\\*[^*]+\\*\\*", options: []), .bold),
        (try! NSRegularExpression(pattern: "\\*[^*]+\\*", options: []), .italic),
        (try! NSRegularExpression(pattern: "`[^`]+`", options: []), .inlineCode),
        (try! NSRegularExpression(pattern: "\\[([^\\]]+)\\]\\(([^)]+)\\)", options: []), .link),
        // ... more patterns
    ]

    func highlight(in textStorage: NSTextStorage, range: NSRange) {
        // Reset to default style
        textStorage.setAttributes(theme.defaultAttributes, range: range)

        // Apply each pattern
        for (regex, style) in patterns {
            regex.enumerateMatches(in: textStorage.string, options: [], range: range) { match, _, _ in
                guard let matchRange = match?.range else { return }
                textStorage.addAttributes(theme.attributes(for: style), range: matchRange)
            }
        }
    }
}
```

### Performance Considerations

1. **Debounce highlighting** - Don't highlight on every keystroke
2. **Paragraph-scoped** - Only process affected paragraphs
3. **Background queue** - Highlight in background, apply on main
4. **Caching** - Cache parsed structure for unchanged regions

---

## Key Bindings

### Default Bindings

| Key | Action |
|-----|--------|
| ⌘B | Toggle bold |
| ⌘I | Toggle italic |
| ⌘K | Insert link (or command palette if no selection) |
| ⌘] | Indent |
| ⌘[ | Outdent |
| Tab | Insert tab or accept completion |
| ⇧Tab | Outdent |
| Enter | Smart newline (continue list) |
| ⌘/ | Toggle comment |

### Implementation

```swift
extension EditorTextView {
    override func keyDown(with event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        switch (event.keyCode, flags) {
        case (11, .command): // ⌘B
            toggleBold()
        case (34, .command): // ⌘I
            toggleItalic()
        case (40, .command): // ⌘K
            if selectedRange().length > 0 {
                insertLink()
            } else {
                openCommandPalette()
            }
        case (36, []): // Enter
            handleSmartNewline()
        default:
            super.keyDown(with: event)
        }
    }
}
```

---

## Undo/Redo

Use NSTextView's built-in NSUndoManager with grouping:

```swift
extension EditorTextView {
    func performEdit(_ edit: () -> Void) {
        undoManager?.beginUndoGrouping()
        edit()
        undoManager?.endUndoGrouping()
    }

    func toggleBold() {
        performEdit {
            // Apply bold formatting
        }
    }
}
```

---

## Scroll Synchronization

For editor-preview scroll sync:

```swift
class EditorTextView: NSTextView {
    var onScroll: ((CGFloat) -> Void)?

    override func scrollWheel(with event: NSEvent) {
        super.scrollWheel(with: event)

        // Calculate scroll percentage
        let visibleRect = enclosingScrollView?.documentVisibleRect ?? .zero
        let contentHeight = bounds.height - visibleRect.height
        let scrollPercent = contentHeight > 0 ? visibleRect.origin.y / contentHeight : 0

        onScroll?(scrollPercent)
    }
}
```

---

## Testing Plan

### Unit Tests

1. MarkdownTextStorage - text manipulation, highlighting triggers
2. MarkdownHighlighter - pattern matching, attribute application
3. Key bindings - each shortcut produces correct output

### Performance Tests

1. Large file (10MB) - open time < 1s
2. Typing latency - < 16ms per keystroke
3. Scroll performance - 60fps

### Integration Tests

1. SwiftUI binding updates
2. Undo/redo across operations
3. Cut/copy/paste with formatting

---

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Highlighting performance | Medium | High | Incremental updates, profiling |
| SwiftUI binding sync | Medium | Medium | Careful coordinator implementation |
| Memory with large files | Low | High | Lazy loading, memory profiling |

---

## Spike Deliverables

1. [ ] Basic NSTextView wrapper in SwiftUI
2. [ ] Bidirectional text binding working
3. [ ] Simple syntax highlighting (headers, bold, italic)
4. [ ] Line numbers display
5. [ ] ⌘B/⌘I shortcuts working
6. [ ] Performance test with 1MB file

---

## References

- [NSTextView Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/TextEditing/TextEditing.html)
- [Text System Storage Layer](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/TextStorageLayer/TextStorageLayer.html)
- [NSViewRepresentable](https://developer.apple.com/documentation/swiftui/nsviewrepresentable)

---

**Last Updated:** 2024-12-13
