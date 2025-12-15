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

    /// Apply syntax highlighting to an NSTextStorage, preserving the base font
    static func highlight(_ textStorage: NSTextStorage, baseFont: NSFont, paragraphStyle: NSParagraphStyle?) {
        let fullRange = NSRange(location: 0, length: textStorage.length)

        guard fullRange.length > 0 else { return }

        // Begin editing
        textStorage.beginEditing()

        // Reset to base attributes
        var baseAttributes: [NSAttributedString.Key: Any] = [
            .font: baseFont,
            .foregroundColor: NSColor.labelColor
        ]
        if let style = paragraphStyle {
            baseAttributes[.paragraphStyle] = style
        }
        textStorage.setAttributes(baseAttributes, range: fullRange)

        // Apply patterns in order (code blocks first to protect their content)
        applyCodeBlocks(to: textStorage, baseFont: baseFont)
        applyInlineCode(to: textStorage, baseFont: baseFont)
        applyHeaders(to: textStorage, baseFont: baseFont)
        applyBoldItalic(to: textStorage, baseFont: baseFont)
        applyBold(to: textStorage, baseFont: baseFont)
        applyItalic(to: textStorage, baseFont: baseFont)
        applyStrikethrough(to: textStorage)
        applyLinks(to: textStorage)
        applyBlockquotes(to: textStorage)
        applyListMarkers(to: textStorage)
        applyHorizontalRules(to: textStorage)

        // End editing
        textStorage.endEditing()
    }

    // MARK: - Font Helpers

    private static func boldFont(from baseFont: NSFont) -> NSFont {
        NSFontManager.shared.convert(baseFont, toHaveTrait: .boldFontMask)
    }

    private static func italicFont(from baseFont: NSFont) -> NSFont {
        NSFontManager.shared.convert(baseFont, toHaveTrait: .italicFontMask)
    }

    private static func boldItalicFont(from baseFont: NSFont) -> NSFont {
        let bold = NSFontManager.shared.convert(baseFont, toHaveTrait: .boldFontMask)
        return NSFontManager.shared.convert(bold, toHaveTrait: .italicFontMask)
    }

    // MARK: - Pattern Matchers

    private static func applyHeaders(to storage: NSTextStorage, baseFont: NSFont) {
        let baseSize = baseFont.pointSize
        let patterns: [(String, NSFont)] = [
            ("^#{6}\\s+.*$", NSFont.monospacedSystemFont(ofSize: baseSize, weight: .semibold)),
            ("^#{5}\\s+.*$", NSFont.monospacedSystemFont(ofSize: baseSize, weight: .semibold)),
            ("^#{4}\\s+.*$", NSFont.monospacedSystemFont(ofSize: baseSize, weight: .semibold)),
            ("^#{3}\\s+.*$", NSFont.monospacedSystemFont(ofSize: baseSize + 1, weight: .semibold)),
            ("^#{2}\\s+.*$", NSFont.monospacedSystemFont(ofSize: baseSize + 2, weight: .bold)),
            ("^#{1}\\s+.*$", NSFont.monospacedSystemFont(ofSize: baseSize + 3, weight: .bold)),
        ]

        for (pattern, font) in patterns {
            applyPattern(pattern, to: storage, options: .anchorsMatchLines) { range in
                storage.addAttributes([
                    .foregroundColor: Colors.header,
                    .font: font
                ], range: range)
            }
        }
    }

    private static func applyBoldItalic(to storage: NSTextStorage, baseFont: NSFont) {
        // ***bold italic*** or ___bold italic___
        let patterns = ["\\*\\*\\*[^*]+\\*\\*\\*", "___[^_]+___"]
        let font = boldItalicFont(from: baseFont)
        for pattern in patterns {
            applyPattern(pattern, to: storage) { range in
                storage.addAttributes([
                    .font: font
                ], range: range)
            }
        }
    }

    private static func applyBold(to storage: NSTextStorage, baseFont: NSFont) {
        // **bold** or __bold__
        let patterns = ["\\*\\*[^*]+\\*\\*", "__[^_]+__"]
        let font = boldFont(from: baseFont)
        for pattern in patterns {
            applyPattern(pattern, to: storage) { range in
                storage.addAttributes([
                    .font: font
                ], range: range)
            }
        }
    }

    private static func applyItalic(to storage: NSTextStorage, baseFont: NSFont) {
        // *italic* or _italic_ (but not inside words for underscore)
        let font = italicFont(from: baseFont)
        applyPattern("(?<![\\w\\*])\\*[^*]+\\*(?![\\w\\*])", to: storage) { range in
            storage.addAttributes([
                .font: font,
                .foregroundColor: Colors.italic
            ], range: range)
        }
        applyPattern("(?<![\\w])_[^_]+_(?![\\w])", to: storage) { range in
            storage.addAttributes([
                .font: font,
                .foregroundColor: Colors.italic
            ], range: range)
        }
    }

    private static func applyInlineCode(to storage: NSTextStorage, baseFont: NSFont) {
        // `code`
        applyPattern("`[^`]+`", to: storage) { range in
            storage.addAttributes([
                .foregroundColor: Colors.code,
                .backgroundColor: NSColor.systemGray.withAlphaComponent(0.1)
            ], range: range)
        }
    }

    private static func applyCodeBlocks(to storage: NSTextStorage, baseFont: NSFont) {
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
