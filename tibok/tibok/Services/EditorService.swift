//
//  EditorService.swift
//  tibok
//
//  Provides editor operations for plugins.
//  Exposes text insertion, selection, and cursor APIs.
//
//  MIT License
//

import Foundation
import AppKit

/// Protocol for editor operations that plugins can invoke.
protocol EditorDelegate: AnyObject {
    /// Insert text at the current cursor position
    func insertText(_ text: String)

    /// Replace the current selection with text
    func replaceSelection(with text: String)

    /// Get the currently selected text
    func getSelectedText() -> String

    /// Get the cursor position (character offset from start)
    func getCursorPosition() -> Int

    /// Set the cursor position
    func setCursorPosition(_ position: Int)

    /// Get the selection range
    func getSelectionRange() -> NSRange

    /// Set the selection range
    func setSelectionRange(_ range: NSRange)

    /// Get all text content
    func getContent() -> String

    /// Set all text content
    func setContent(_ content: String)

    /// Scroll to make the cursor visible
    func scrollToCursor()
}

/// Shared service for editor operations.
/// The active editor registers itself here for plugin access.
@MainActor
final class EditorService: ObservableObject {
    static let shared = EditorService()

    /// The currently active editor delegate
    private weak var activeDelegate: EditorDelegate?

    /// Whether an editor is currently available
    @Published private(set) var isEditorAvailable = false

    private init() {}

    // MARK: - Registration

    /// Register the active editor delegate
    func register(_ delegate: EditorDelegate) {
        activeDelegate = delegate
        isEditorAvailable = true
    }

    /// Unregister the editor delegate
    func unregister(_ delegate: EditorDelegate) {
        if activeDelegate === delegate {
            activeDelegate = nil
            isEditorAvailable = false
        }
    }

    // MARK: - Plugin APIs

    /// Insert text at the current cursor position
    func insertText(_ text: String) {
        guard let delegate = activeDelegate else {
            print("EditorService: No active editor")
            return
        }
        delegate.insertText(text)
    }

    /// Replace the current selection with text
    func replaceSelection(with text: String) {
        guard let delegate = activeDelegate else {
            print("EditorService: No active editor")
            return
        }
        delegate.replaceSelection(with: text)
    }

    /// Get the currently selected text
    func getSelectedText() -> String {
        return activeDelegate?.getSelectedText() ?? ""
    }

    /// Get the cursor position
    func getCursorPosition() -> Int {
        return activeDelegate?.getCursorPosition() ?? 0
    }

    /// Set the cursor position
    func setCursorPosition(_ position: Int) {
        activeDelegate?.setCursorPosition(position)
    }

    /// Get the selection range
    func getSelectionRange() -> NSRange {
        return activeDelegate?.getSelectionRange() ?? NSRange(location: 0, length: 0)
    }

    /// Set the selection range
    func setSelectionRange(_ range: NSRange) {
        activeDelegate?.setSelectionRange(range)
    }

    /// Get all text content
    func getContent() -> String {
        return activeDelegate?.getContent() ?? ""
    }

    /// Set all text content
    func setContent(_ content: String) {
        activeDelegate?.setContent(content)
    }

    /// Scroll to make the cursor visible
    func scrollToCursor() {
        activeDelegate?.scrollToCursor()
    }
}

// MARK: - NSTextView Extension

extension NSTextView: EditorDelegate {
    func insertText(_ text: String) {
        // Insert at current selection, replacing any selected text
        let range = selectedRange()
        if shouldChangeText(in: range, replacementString: text) {
            replaceCharacters(in: range, with: text)
            didChangeText()

            // Move cursor to end of inserted text
            setSelectedRange(NSRange(location: range.location + text.count, length: 0))
        }
    }

    func replaceSelection(with text: String) {
        insertText(text)
    }

    func getSelectedText() -> String {
        guard let textStorage = textStorage else { return "" }
        let range = selectedRange()
        guard range.length > 0,
              range.location + range.length <= textStorage.length else {
            return ""
        }
        return textStorage.string.substring(with: range)
    }

    func getCursorPosition() -> Int {
        return selectedRange().location
    }

    func setCursorPosition(_ position: Int) {
        let safePosition = max(0, min(position, textStorage?.length ?? 0))
        setSelectedRange(NSRange(location: safePosition, length: 0))
    }

    func getSelectionRange() -> NSRange {
        return selectedRange()
    }

    func setSelectionRange(_ range: NSRange) {
        guard let length = textStorage?.length else { return }
        let safeLocation = max(0, min(range.location, length))
        let safeLength = min(range.length, length - safeLocation)
        setSelectedRange(NSRange(location: safeLocation, length: safeLength))
    }

    func getContent() -> String {
        return string
    }

    func setContent(_ content: String) {
        string = content
    }

    func scrollToCursor() {
        scrollRangeToVisible(selectedRange())
    }
}

// MARK: - String Extension

private extension String {
    func substring(with range: NSRange) -> String {
        guard let swiftRange = Range(range, in: self) else { return "" }
        return String(self[swiftRange])
    }
}
