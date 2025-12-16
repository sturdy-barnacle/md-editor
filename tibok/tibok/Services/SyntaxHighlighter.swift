//
//  SyntaxHighlighter.swift
//  tibok
//
//  Applies syntax highlighting to markdown text in the editor.
//

import AppKit

struct SyntaxHighlighter {

    // MARK: - Colors

    struct Colors {
        static let header = NSColor.systemBlue
        static let bold = NSColor.labelColor
        static let italic = NSColor.secondaryLabelColor
        static let code = NSColor.systemPurple
        static let codeBlock = NSColor.systemPurple
        static let link = NSColor.systemBlue
        static let linkURL = NSColor.systemTeal
        static let blockquote = NSColor.systemGray
        static let listMarker = NSColor.systemOrange
        static let horizontalRule = NSColor.systemGray
        static let strikethrough = NSColor.secondaryLabelColor
        static let highlight = NSColor.systemYellow
    }

    // MARK: - Highlighting (in-place on NSTextStorage)

    /// Apply syntax highlighting to an NSTextStorage using in-place attribute modification.
    /// Only modifies colors, not fonts, to prevent any layout recalculation or flicker.
    static func highlight(_ textStorage: NSTextStorage, baseFont: NSFont, paragraphStyle: NSParagraphStyle?) {
        let fullRange = NSRange(location: 0, length: textStorage.length)

        guard fullRange.length > 0 else { return }

        textStorage.beginEditing()

        // Reset to base colors only - NO font changes to prevent flicker
        textStorage.addAttributes([
            .foregroundColor: NSColor.labelColor,
            .backgroundColor: NSColor.clear
        ], range: fullRange)

        if let style = paragraphStyle {
            textStorage.addAttribute(.paragraphStyle, value: style, range: fullRange)
        }

        // Remove strikethrough from all text before reapplying
        textStorage.removeAttribute(.strikethroughStyle, range: fullRange)

        // Apply color-only highlighting patterns
        applyHeaders(to: textStorage)
        applyCodeBlocks(to: textStorage)
        applyInlineCode(to: textStorage)
        applyStrikethrough(to: textStorage)
        applyLinks(to: textStorage)
        applyBlockquotes(to: textStorage)
        applyListMarkers(to: textStorage)
        applyHorizontalRules(to: textStorage)

        textStorage.endEditing()
    }

    // MARK: - Pattern Matchers

    private static func applyHeaders(to storage: NSTextStorage) {
        // Color-only highlighting for headers (no font changes to prevent flicker)
        applyPattern("^#{1,6}\\s+.*$", to: storage, options: .anchorsMatchLines) { range in
            storage.addAttribute(.foregroundColor, value: Colors.header, range: range)
        }
    }

    private static func applyInlineCode(to storage: NSTextStorage) {
        // `code`
        applyPattern("`[^`]+`", to: storage) { range in
            storage.addAttributes([
                .foregroundColor: Colors.code,
                .backgroundColor: NSColor.systemGray.withAlphaComponent(0.1)
            ], range: range)
        }
    }

    private static func applyCodeBlocks(to storage: NSTextStorage) {
        // ```code blocks```
        applyPattern("```[\\s\\S]*?```", to: storage) { range in
            storage.addAttributes([
                .foregroundColor: Colors.codeBlock,
                .backgroundColor: NSColor.systemGray.withAlphaComponent(0.1)
            ], range: range)
        }
    }

    private static func applyStrikethrough(to storage: NSTextStorage) {
        // ~~strikethrough~~
        applyPattern("~~[^~]+~~", to: storage) { range in
            storage.addAttributes([
                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                .foregroundColor: Colors.strikethrough
            ], range: range)
        }
    }

    private static func applyLinks(to storage: NSTextStorage) {
        // [text](url)
        applyPattern("\\[([^\\]]+)\\]\\(([^)]+)\\)", to: storage) { range in
            storage.addAttribute(.foregroundColor, value: Colors.link, range: range)
        }

        // Just the URL part
        applyPattern("(?<=\\]\\()[^)]+(?=\\))", to: storage) { range in
            storage.addAttribute(.foregroundColor, value: Colors.linkURL, range: range)
        }
    }

    private static func applyBlockquotes(to storage: NSTextStorage) {
        // > blockquote
        applyPattern("^>\\s*.*$", to: storage, options: .anchorsMatchLines) { range in
            storage.addAttribute(.foregroundColor, value: Colors.blockquote, range: range)
        }
    }

    private static func applyListMarkers(to storage: NSTextStorage) {
        // - item, * item, + item, 1. item
        applyPattern("^\\s*[-*+]\\s", to: storage, options: .anchorsMatchLines) { range in
            storage.addAttribute(.foregroundColor, value: Colors.listMarker, range: range)
        }
        applyPattern("^\\s*\\d+\\.\\s", to: storage, options: .anchorsMatchLines) { range in
            storage.addAttribute(.foregroundColor, value: Colors.listMarker, range: range)
        }
    }

    private static func applyHorizontalRules(to storage: NSTextStorage) {
        // ---, ***, ___
        applyPattern("^(---+|\\*\\*\\*+|___+)\\s*$", to: storage, options: .anchorsMatchLines) { range in
            storage.addAttribute(.foregroundColor, value: Colors.horizontalRule, range: range)
        }
    }

    // MARK: - Helper

    private static func applyPattern(
        _ pattern: String,
        to storage: NSTextStorage,
        options: NSRegularExpression.Options = [],
        handler: (NSRange) -> Void
    ) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return }
        let fullRange = NSRange(location: 0, length: storage.length)
        let matches = regex.matches(in: storage.string, options: [], range: fullRange)

        for match in matches {
            handler(match.range)
        }
    }
}
