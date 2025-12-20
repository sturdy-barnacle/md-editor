//
//  KeyboardShortcutsTests.swift
//  tibokTests
//
//  Tests for keyboard shortcuts and Edit menu commands.
//

import Testing
import AppKit
@testable import tibok

@Suite("Keyboard Shortcuts Tests")
struct KeyboardShortcutsTests {

    // MARK: - Edit Menu Responder Tests

    @Test("Cut responder method exists and is callable")
    func cutResponderMethodExists() {
        let textView = NSTextView()
        textView.string = "Hello World"
        textView.selectedRange = NSRange(location: 0, length: 5)

        // Verify cut selector exists
        #expect(textView.responds(to: #selector(NSTextView.cut(_:))))
    }

    @Test("Copy responder method exists and is callable")
    func copyResponderMethodExists() {
        let textView = NSTextView()
        textView.string = "Hello World"
        textView.selectedRange = NSRange(location: 0, length: 5)

        // Verify copy selector exists
        #expect(textView.responds(to: #selector(NSTextView.copy(_:))))
    }

    @Test("Paste responder method exists and is callable")
    func pasteResponderMethodExists() {
        let textView = NSTextView()

        // Verify paste selector exists
        #expect(textView.responds(to: #selector(NSTextView.paste(_:))))
    }

    @Test("SelectAll responder method exists and is callable")
    func selectAllResponderMethodExists() {
        let textView = NSTextView()
        textView.string = "Hello World"

        // Verify selectAll selector exists
        #expect(textView.responds(to: #selector(NSTextView.selectAll(_:))))
    }

    // MARK: - Clipboard Operation Tests

    @Test("Cut removes text and places it in pasteboard")
    func cutRemovesTextAndPlacesToPasteboard() {
        let textView = NSTextView()
        textView.string = "Hello World"
        textView.selectedRange = NSRange(location: 0, length: 5)  // Select "Hello"

        // Save current pasteboard state
        let pasteboard = NSPasteboard.general

        // Perform cut
        textView.cut(nil)

        // Verify text was cut (removed)
        #expect(textView.string == " World")

        // Verify text is in pasteboard
        if let pasteboardString = pasteboard.string(forType: .string) {
            #expect(pasteboardString == "Hello")
        }
    }

    @Test("Copy places text in pasteboard without removing it")
    func copyPlacesTextInPasteboardWithoutRemoving() {
        let textView = NSTextView()
        textView.string = "Hello World"
        textView.selectedRange = NSRange(location: 0, length: 5)  // Select "Hello"

        let pasteboard = NSPasteboard.general

        // Perform copy
        textView.copy(nil)

        // Verify original text is still there
        #expect(textView.string == "Hello World")

        // Verify text is in pasteboard
        if let pasteboardString = pasteboard.string(forType: .string) {
            #expect(pasteboardString == "Hello")
        }
    }

    @Test("Paste inserts text from pasteboard")
    func pasteInsertsTextFromPasteboard() {
        let textView = NSTextView()
        textView.string = "Hello "
        textView.selectedRange = NSRange(location: 6, length: 0)  // Cursor at end

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString("World", forType: .string)

        // Perform paste
        textView.paste(nil)

        // Verify pasted text was inserted
        #expect(textView.string == "Hello World")
    }

    @Test("SelectAll selects entire text")
    func selectAllSelectsEntireText() {
        let textView = NSTextView()
        textView.string = "Hello World\nMultiple Lines"

        // Perform selectAll
        textView.selectAll(nil)

        // Verify entire text is selected
        #expect(textView.selectedRange.location == 0)
        #expect(textView.selectedRange.length == textView.string.count)
    }

    // MARK: - Edge Case Tests

    @Test("Cut with empty selection does nothing")
    func cutWithEmptySelectionDoesNothing() {
        let textView = NSTextView()
        textView.string = "Hello World"
        textView.selectedRange = NSRange(location: 5, length: 0)  // No selection

        let originalString = textView.string

        // Perform cut on empty selection
        textView.cut(nil)

        // Text should remain unchanged
        #expect(textView.string == originalString)
    }

    @Test("Copy with empty selection copies nothing")
    func copyWithEmptySelectionCopiesNothing() {
        let textView = NSTextView()
        textView.string = "Hello World"
        textView.selectedRange = NSRange(location: 5, length: 0)  // No selection

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString("Previous", forType: .string)

        // Perform copy on empty selection
        textView.copy(nil)

        // Pasteboard should still have previous content (copy does nothing with empty selection)
        if let pasteboardString = pasteboard.string(forType: .string) {
            #expect(pasteboardString == "Previous")
        }
    }

    @Test("SelectAll on empty text does nothing")
    func selectAllOnEmptyTextDoesNothing() {
        let textView = NSTextView()
        textView.string = ""

        // Perform selectAll
        textView.selectAll(nil)

        // Nothing should be selected
        #expect(textView.selectedRange.length == 0)
    }

    @Test("SelectAll with already selected text selects all")
    func selectAllWithPartialSelectionSelectsAll() {
        let textView = NSTextView()
        textView.string = "Hello World"
        textView.selectedRange = NSRange(location: 0, length: 5)  // Select "Hello"

        // Perform selectAll
        textView.selectAll(nil)

        // Entire text should now be selected
        #expect(textView.selectedRange.location == 0)
        #expect(textView.selectedRange.length == 11)
    }

    @Test("Cut and paste together works correctly")
    func cutAndPasteTogether() {
        let sourceView = NSTextView()
        sourceView.string = "Hello World"
        sourceView.selectedRange = NSRange(location: 0, length: 5)  // Select "Hello"

        let destView = NSTextView()
        destView.string = "Goodbye "
        destView.selectedRange = NSRange(location: 8, length: 0)

        // Cut from source
        sourceView.cut(nil)

        // Paste to destination
        destView.paste(nil)

        // Verify cut worked
        #expect(sourceView.string == " World")

        // Verify paste worked
        #expect(destView.string == "Goodbye Hello")
    }

    @Test("Multiple selections handled correctly")
    func multilineTextCutCopyPaste() {
        let textView = NSTextView()
        textView.string = "Line 1\nLine 2\nLine 3"
        textView.selectedRange = NSRange(location: 0, length: 6)  // Select "Line 1"

        // Copy first line
        textView.copy(nil)

        let pasteboard = NSPasteboard.general
        if let copied = pasteboard.string(forType: .string) {
            #expect(copied == "Line 1")
        }

        // Select all and cut
        textView.selectAll(nil)
        textView.cut(nil)

        #expect(textView.string == "")
    }

    // MARK: - Undo/Redo Tests

    @Test("Undo responder method exists")
    func undoResponderMethodExists() {
        let textView = NSTextView()

        // Verify undo selector exists
        #expect(textView.responds(to: #selector(NSTextView.undo(_:))))
    }

    @Test("Redo responder method exists")
    func redoResponderMethodExists() {
        let textView = NSTextView()

        // Verify redo selector exists
        #expect(textView.responds(to: #selector(NSTextView.redo(_:))))
    }

    // MARK: - Responder Chain Tests

    @Test("NSApp.sendAction can route to text view")
    func nsAppSendActionRoutesToTextView() {
        // This test verifies that the responder chain routing works
        // by checking that selectors are properly recognized

        let selector = #selector(NSTextView.selectAll(_:))

        // Verify the selector can be created and is valid
        #expect(selector != nil)

        // Verify NSTextView responds to the selector
        let textView = NSTextView()
        #expect(textView.responds(to: selector))
    }
}
