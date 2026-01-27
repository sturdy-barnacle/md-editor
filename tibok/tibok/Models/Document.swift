//
//  Document.swift
//  tibok
//
//  Represents a markdown document with content and metadata.
//

import Foundation
import CoreGraphics

struct Document: Identifiable, Equatable {
    let id: UUID
    var title: String
    var content: String
    var fileURL: URL?
    var isModified: Bool
    var lastSaved: Date?
    var isActive: Bool  // True if user has started working (created new doc or opened file)

    // Editor state for tab switching
    var cursorPosition: Int
    var scrollOffset: CGFloat

    init(
        id: UUID = UUID(),
        title: String = "Untitled",
        content: String = "",
        fileURL: URL? = nil,
        isModified: Bool = false,
        lastSaved: Date? = nil,
        isActive: Bool = false,
        cursorPosition: Int = 0,
        scrollOffset: CGFloat = 0
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.fileURL = fileURL
        self.isModified = isModified
        self.lastSaved = lastSaved
        self.isActive = isActive
        self.cursorPosition = cursorPosition
        self.scrollOffset = scrollOffset
    }

    /// Creates a new document with starter content
    static func new() -> Document {
        Document(content: "# New Document\n\nStart writing here...", isActive: true)
    }

    /// Creates an empty document (no file open state - shows empty UI)
    static func empty() -> Document {
        Document(content: "", isActive: false)
    }

    /// Whether the document shows empty state (not active, no file)
    /// Active documents never show empty state, even if content is cleared
    var isEmpty: Bool {
        !isActive && content.isEmpty && fileURL == nil
    }

    /// Word count for the document
    var wordCount: Int {
        content.split { $0.isWhitespace || $0.isNewline }.count
    }

    /// Character count for the document
    var characterCount: Int {
        content.count
    }

    /// Line count for the document
    var lineCount: Int {
        content.components(separatedBy: .newlines).count
    }
    
    /// Whether the document can be previewed as markdown
    /// Only markdown files and untitled documents can be previewed
    var isPreviewSupported: Bool {
        // If no file URL, it's a new untitled document - support preview
        guard let fileURL = fileURL else {
            return true
        }
        
        // Check file extension
        let ext = fileURL.pathExtension.lowercased()
        let supportedExtensions = ["md", "markdown", "mdown", "mkd"]
        return supportedExtensions.contains(ext)
    }
}
