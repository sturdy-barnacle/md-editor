//
//  MarkdownRenderer.swift
//  tibok
//
//  Converts markdown text to HTML using regex-based parsing.
//

import Foundation

struct MarkdownRenderer {

    /// Renders markdown text to HTML
    static func render(_ markdown: String) -> String {
        var html = markdown

        // Process TOC placeholder - collect headers first
        let tocPlaceholder = "<!--TOC_PLACEHOLDER-->"
        if html.contains("[[toc]]") {
            html = html.replacingOccurrences(of: "[[toc]]", with: tocPlaceholder)
        }

        // Protect math blocks before other processing
        var mathBlocks: [String: String] = [:]

        // Block math: $$...$$ (display mode)
        let blockMathPattern = "\\$\\$([\\s\\S]+?)\\$\\$"
        if let regex = try? NSRegularExpression(pattern: blockMathPattern, options: []) {
            var blockIndex = 0
            let matches = regex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html)).reversed()
            for match in matches {
                if let fullRange = Range(match.range, in: html),
                   let mathRange = Range(match.range(at: 1), in: html) {
                    let math = String(html[mathRange])
                    let placeholder = "<!--MATHBLOCK\(blockIndex)-->"
                    mathBlocks[placeholder] = "<div class=\"math-display\">$$\(math)$$</div>"
                    html.replaceSubrange(fullRange, with: placeholder)
                    blockIndex += 1
                }
            }
        }

        // Inline math: $...$ (not preceded/followed by $)
        let inlineMathPattern = "(?<!\\$)\\$(?!\\$)([^$\\n]+?)(?<!\\$)\\$(?!\\$)"
        if let regex = try? NSRegularExpression(pattern: inlineMathPattern, options: []) {
            var inlineIndex = 0
            let matches = regex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html)).reversed()
            for match in matches {
                if let fullRange = Range(match.range, in: html),
                   let mathRange = Range(match.range(at: 1), in: html) {
                    let math = String(html[mathRange])
                    let placeholder = "<!--MATHINLINE\(inlineIndex)-->"
                    mathBlocks[placeholder] = "<span class=\"math-inline\">$\(math)$</span>"
                    html.replaceSubrange(fullRange, with: placeholder)
                    inlineIndex += 1
                }
            }
        }

        // Protect raw HTML blocks (details, summary, div, etc.)
        var htmlBlocks: [String: String] = [:]
        let htmlBlockPattern = "(<(?:details|summary|div|section|aside|nav|header|footer|article)[^>]*>[\\s\\S]*?</(?:details|summary|div|section|aside|nav|header|footer|article)>)"
        if let regex = try? NSRegularExpression(pattern: htmlBlockPattern, options: [.caseInsensitive]) {
            var blockIndex = 0
            let matches = regex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html)).reversed()
            for match in matches {
                if let fullRange = Range(match.range, in: html) {
                    let block = String(html[fullRange])
                    let placeholder = "<!--HTMLBLOCK\(blockIndex)-->"
                    htmlBlocks[placeholder] = block
                    html.replaceSubrange(fullRange, with: placeholder)
                    blockIndex += 1
                }
            }
        }

        // Process code blocks (to protect their content)
        var codeBlocks: [String: String] = [:]
        let codeBlockPattern = "```(\\w*)\\n([\\s\\S]*?)```"
        if let regex = try? NSRegularExpression(pattern: codeBlockPattern, options: []) {
            let range = NSRange(html.startIndex..., in: html)
            var blockIndex = 0

            let matches = regex.matches(in: html, options: [], range: range).reversed()
            for match in matches {
                if let fullRange = Range(match.range, in: html),
                   let langRange = Range(match.range(at: 1), in: html),
                   let codeRange = Range(match.range(at: 2), in: html) {
                    let language = String(html[langRange])
                    let code = escapeHTML(String(html[codeRange]))
                    let placeholder = "<!--CODEBLOCK\(blockIndex)-->"
                    let langClass = language.isEmpty ? "" : " class=\"language-\(language)\""
                    codeBlocks[placeholder] = "<pre><code\(langClass)>\(code)</code></pre>"
                    html.replaceSubrange(fullRange, with: placeholder)
                    blockIndex += 1
                }
            }
        }

        // Protect inline code
        var inlineCodes: [String: String] = [:]
        let inlineCodePattern = "`([^`]+)`"
        if let regex = try? NSRegularExpression(pattern: inlineCodePattern, options: []) {
            var codeIndex = 0
            var searchRange = html.startIndex..<html.endIndex

            while let match = regex.firstMatch(in: html, options: [], range: NSRange(searchRange, in: html)),
                  let fullRange = Range(match.range, in: html),
                  let codeRange = Range(match.range(at: 1), in: html) {
                let code = escapeHTML(String(html[codeRange]))
                let placeholder = "<!--INLINECODE\(codeIndex)-->"
                inlineCodes[placeholder] = "<code>\(code)</code>"
                html.replaceSubrange(fullRange, with: placeholder)
                codeIndex += 1
                searchRange = html.startIndex..<html.endIndex
            }
        }

        // Process tables
        html = processTables(html)

        // Process definition lists
        html = processDefinitionLists(html)

        // Collect footnote definitions and references
        var footnoteDefinitions: [String: String] = [:]
        let footnoteDefPattern = "^\\[\\^([^\\]]+)\\]:\\s*(.+)$"
        if let regex = try? NSRegularExpression(pattern: footnoteDefPattern, options: [.anchorsMatchLines]) {
            let matches = regex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html)).reversed()
            for match in matches {
                if let fullRange = Range(match.range, in: html),
                   let idRange = Range(match.range(at: 1), in: html),
                   let contentRange = Range(match.range(at: 2), in: html) {
                    let id = String(html[idRange])
                    let content = String(html[contentRange])
                    footnoteDefinitions[id] = content
                    html.replaceSubrange(fullRange, with: "")
                }
            }
        }

        // Process block elements line by line
        let lines = html.components(separatedBy: "\n")
        var processedLines: [String] = []
        var inList = false
        var listType = ""
        var inCallout = false
        var calloutType = ""
        var collectedHeaders: [(level: Int, text: String, id: String)] = []

        for line in lines {
            var processedLine = line

            // Headers
            if processedLine.hasPrefix("######") {
                let text = String(processedLine.dropFirst(6).trimmingCharacters(in: .whitespaces))
                let id = generateHeaderId(text)
                collectedHeaders.append((level: 6, text: text, id: id))
                processedLine = "<h6 id=\"\(id)\">\(processInline(text))</h6>"
            } else if processedLine.hasPrefix("#####") {
                let text = String(processedLine.dropFirst(5).trimmingCharacters(in: .whitespaces))
                let id = generateHeaderId(text)
                collectedHeaders.append((level: 5, text: text, id: id))
                processedLine = "<h5 id=\"\(id)\">\(processInline(text))</h5>"
            } else if processedLine.hasPrefix("####") {
                let text = String(processedLine.dropFirst(4).trimmingCharacters(in: .whitespaces))
                let id = generateHeaderId(text)
                collectedHeaders.append((level: 4, text: text, id: id))
                processedLine = "<h4 id=\"\(id)\">\(processInline(text))</h4>"
            } else if processedLine.hasPrefix("###") {
                let text = String(processedLine.dropFirst(3).trimmingCharacters(in: .whitespaces))
                let id = generateHeaderId(text)
                collectedHeaders.append((level: 3, text: text, id: id))
                processedLine = "<h3 id=\"\(id)\">\(processInline(text))</h3>"
            } else if processedLine.hasPrefix("##") {
                let text = String(processedLine.dropFirst(2).trimmingCharacters(in: .whitespaces))
                let id = generateHeaderId(text)
                collectedHeaders.append((level: 2, text: text, id: id))
                processedLine = "<h2 id=\"\(id)\">\(processInline(text))</h2>"
            } else if processedLine.hasPrefix("#") {
                let text = String(processedLine.dropFirst(1).trimmingCharacters(in: .whitespaces))
                let id = generateHeaderId(text)
                collectedHeaders.append((level: 1, text: text, id: id))
                processedLine = "<h1 id=\"\(id)\">\(processInline(text))</h1>"
            }
            // Horizontal rule (must be only dashes, asterisks, or underscores with optional spaces)
            else if isHorizontalRule(processedLine) {
                if inList {
                    processedLines.append(listType == "ul" ? "</ul>" : "</ol>")
                    inList = false
                }
                processedLine = "<hr>"
            }
            // GitHub-style callouts: > [!NOTE], > [!TIP], > [!WARNING], > [!IMPORTANT], > [!CAUTION]
            else if let calloutMatch = processedLine.range(of: "^>\\s*\\[!(NOTE|TIP|WARNING|IMPORTANT|CAUTION)\\]", options: .regularExpression) {
                // Close any previous callout
                if inCallout {
                    processedLines.append("</div>")
                }
                calloutType = String(processedLine[calloutMatch]).replacingOccurrences(of: "> [!", with: "").replacingOccurrences(of: "]", with: "").lowercased()
                inCallout = true
                processedLine = "<div class=\"callout callout-\(calloutType)\"><strong>\(calloutType.capitalized)</strong>"
            }
            // Blockquote continuation (part of callout or regular blockquote)
            else if processedLine.hasPrefix(">") {
                let content = String(processedLine.dropFirst(1).trimmingCharacters(in: .whitespaces))
                if inCallout {
                    // Continue the callout
                    processedLine = "<p>\(processInline(content))</p>"
                } else {
                    processedLine = "<blockquote>\(processInline(content))</blockquote>"
                }
            }
            // Non-blockquote line - close callout if open
            else if inCallout && !processedLine.trimmingCharacters(in: .whitespaces).isEmpty {
                processedLines.append("</div>")
                inCallout = false
                // Re-process this line
                if processedLine.hasPrefix("- ") || processedLine.hasPrefix("* ") || processedLine.hasPrefix("+ ") {
                    if !inList || listType != "ul" {
                        if inList {
                            processedLines.append(listType == "ul" ? "</ul>" : "</ol>")
                        }
                        processedLines.append("<ul>")
                        inList = true
                        listType = "ul"
                    }
                    let content = String(processedLine.dropFirst(2))
                    processedLine = "<li>\(processInline(content))</li>"
                } else if !processedLine.hasPrefix("<") {
                    processedLine = "<p>\(processInline(processedLine))</p>"
                }
            }
            // Empty line - close callout if open
            else if inCallout && processedLine.trimmingCharacters(in: .whitespaces).isEmpty {
                processedLines.append("</div>")
                inCallout = false
                processedLine = ""
            }
            // Unordered list
            else if processedLine.hasPrefix("- ") || processedLine.hasPrefix("* ") || processedLine.hasPrefix("+ ") {
                if !inList || listType != "ul" {
                    if inList {
                        processedLines.append(listType == "ul" ? "</ul>" : "</ol>")
                    }
                    processedLines.append("<ul>")
                    inList = true
                    listType = "ul"
                }
                let content = String(processedLine.dropFirst(2))
                processedLine = "<li>\(processInline(content))</li>"
            }
            // Ordered list
            else if let match = processedLine.range(of: "^\\d+\\. ", options: .regularExpression) {
                if !inList || listType != "ol" {
                    if inList {
                        processedLines.append(listType == "ul" ? "</ul>" : "</ol>")
                    }
                    processedLines.append("<ol>")
                    inList = true
                    listType = "ol"
                }
                let content = String(processedLine[match.upperBound...])
                processedLine = "<li>\(processInline(content))</li>"
            }
            // Task list
            else if processedLine.hasPrefix("- [ ] ") || processedLine.hasPrefix("- [x] ") || processedLine.hasPrefix("- [X] ") {
                if !inList || listType != "ul" {
                    if inList {
                        processedLines.append(listType == "ul" ? "</ul>" : "</ol>")
                    }
                    processedLines.append("<ul>")
                    inList = true
                    listType = "ul"
                }
                let isChecked = processedLine.hasPrefix("- [x] ") || processedLine.hasPrefix("- [X] ")
                let content = String(processedLine.dropFirst(6))
                let checkbox = isChecked ? "<input type=\"checkbox\" disabled checked>" : "<input type=\"checkbox\" disabled>"
                processedLine = "<li>\(checkbox) \(processInline(content))</li>"
            }
            // Empty line - close list if open
            else if processedLine.trimmingCharacters(in: .whitespaces).isEmpty {
                if inList {
                    processedLines.append(listType == "ul" ? "</ul>" : "</ol>")
                    inList = false
                }
                processedLine = ""
            }
            // Code block placeholder - pass through
            else if processedLine.contains("<!--CODEBLOCK") {
                if inList {
                    processedLines.append(listType == "ul" ? "</ul>" : "</ol>")
                    inList = false
                }
                // Don't wrap in paragraph
            }
            // Regular paragraph
            else if !processedLine.trimmingCharacters(in: .whitespaces).isEmpty {
                if inList {
                    processedLines.append(listType == "ul" ? "</ul>" : "</ol>")
                    inList = false
                }
                if !processedLine.hasPrefix("<") {
                    processedLine = "<p>\(processInline(processedLine))</p>"
                }
            }

            processedLines.append(processedLine)
        }

        // Close any open list
        if inList {
            processedLines.append(listType == "ul" ? "</ul>" : "</ol>")
        }

        // Close any open callout
        if inCallout {
            processedLines.append("</div>")
        }

        html = processedLines.joined(separator: "\n")

        // Generate and insert TOC if placeholder exists
        if html.contains(tocPlaceholder) {
            let toc = generateTOC(from: collectedHeaders)
            html = html.replacingOccurrences(of: "<p>\(tocPlaceholder)</p>", with: toc)
            html = html.replacingOccurrences(of: tocPlaceholder, with: toc)
        }

        // Process footnote references [^id] -> superscript links
        let footnoteRefPattern = "\\[\\^([^\\]]+)\\]"
        if let regex = try? NSRegularExpression(pattern: footnoteRefPattern, options: []) {
            var footnoteIndex = 1
            var usedFootnotes: [(id: String, index: Int)] = []

            while let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
                  let fullRange = Range(match.range, in: html),
                  let idRange = Range(match.range(at: 1), in: html) {
                let id = String(html[idRange])
                let index = footnoteIndex
                usedFootnotes.append((id: id, index: index))
                let replacement = "<sup><a href=\"#fn-\(id)\" id=\"fnref-\(id)\">\(index)</a></sup>"
                html.replaceSubrange(fullRange, with: replacement)
                footnoteIndex += 1
            }

            // Append footnotes section if there are any
            if !usedFootnotes.isEmpty && !footnoteDefinitions.isEmpty {
                var footnotesHTML = "<hr><section class=\"footnotes\"><ol>"
                for (id, _) in usedFootnotes {
                    if let content = footnoteDefinitions[id] {
                        footnotesHTML += "<li id=\"fn-\(id)\">\(processInline(content)) <a href=\"#fnref-\(id)\">↩</a></li>"
                    }
                }
                footnotesHTML += "</ol></section>"
                html += footnotesHTML
            }
        }

        // Restore code blocks
        for (placeholder, code) in codeBlocks {
            html = html.replacingOccurrences(of: placeholder, with: code)
        }

        // Restore inline code
        for (placeholder, code) in inlineCodes {
            html = html.replacingOccurrences(of: placeholder, with: code)
        }

        // Restore HTML blocks
        for (placeholder, block) in htmlBlocks {
            html = html.replacingOccurrences(of: "<p>\(placeholder)</p>", with: block)
            html = html.replacingOccurrences(of: placeholder, with: block)
        }

        // Restore math blocks
        for (placeholder, math) in mathBlocks {
            html = html.replacingOccurrences(of: "<p>\(placeholder)</p>", with: math)
            html = html.replacingOccurrences(of: placeholder, with: math)
        }

        return html
    }

    /// Process markdown tables into HTML
    private static func processTables(_ text: String) -> String {
        let lines = text.components(separatedBy: "\n")
        var processedLines: [String] = []
        var i = 0

        while i < lines.count {
            let line = lines[i]

            // Check if this could be a table header row (contains |)
            if line.contains("|") && i + 1 < lines.count {
                let nextLine = lines[i + 1]

                // Check if next line is a separator row (contains | and -)
                if nextLine.contains("|") && nextLine.contains("-") {
                    // Parse the table
                    var tableHTML = "<table>\n<thead>\n<tr>\n"

                    // Parse header row
                    let headerCells = parseTableRow(line)
                    for cell in headerCells {
                        tableHTML += "<th>\(processInline(cell))</th>\n"
                    }
                    tableHTML += "</tr>\n</thead>\n<tbody>\n"

                    // Skip header and separator rows
                    i += 2

                    // Parse body rows
                    while i < lines.count && lines[i].contains("|") {
                        let bodyCells = parseTableRow(lines[i])
                        tableHTML += "<tr>\n"
                        for cell in bodyCells {
                            tableHTML += "<td>\(processInline(cell))</td>\n"
                        }
                        tableHTML += "</tr>\n"
                        i += 1
                    }

                    tableHTML += "</tbody>\n</table>"
                    processedLines.append(tableHTML)
                    continue
                }
            }

            processedLines.append(line)
            i += 1
        }

        return processedLines.joined(separator: "\n")
    }

    /// Parse a table row into cells
    private static func parseTableRow(_ row: String) -> [String] {
        var cells = row.components(separatedBy: "|")

        // Remove empty first/last elements from leading/trailing |
        if cells.first?.trimmingCharacters(in: .whitespaces).isEmpty == true {
            cells.removeFirst()
        }
        if cells.last?.trimmingCharacters(in: .whitespaces).isEmpty == true {
            cells.removeLast()
        }

        return cells.map { $0.trimmingCharacters(in: .whitespaces) }
    }

    /// Process definition lists (term followed by : definition)
    private static func processDefinitionLists(_ text: String) -> String {
        let lines = text.components(separatedBy: "\n")
        var processedLines: [String] = []
        var i = 0

        while i < lines.count {
            let line = lines[i]

            // Check if next line starts with ": " (definition)
            if i + 1 < lines.count {
                let nextLine = lines[i + 1]
                if nextLine.hasPrefix(": ") && !line.trimmingCharacters(in: .whitespaces).isEmpty &&
                   !line.hasPrefix("#") && !line.hasPrefix("-") && !line.hasPrefix("*") &&
                   !line.hasPrefix(">") && !line.hasPrefix("|") && !line.hasPrefix("```") {
                    // This is a definition list
                    var dlHTML = "<dl>\n"

                    // Process all consecutive term/definition pairs
                    var j = i
                    while j < lines.count {
                        let termLine = lines[j]

                        // Check if this is a term (non-empty, not a definition line)
                        if termLine.trimmingCharacters(in: .whitespaces).isEmpty {
                            break
                        }
                        if termLine.hasPrefix(": ") {
                            // Definition without term - skip
                            break
                        }

                        // Add term
                        dlHTML += "<dt>\(processInline(termLine))</dt>\n"
                        j += 1

                        // Collect all definitions for this term
                        while j < lines.count && lines[j].hasPrefix(": ") {
                            let definition = String(lines[j].dropFirst(2))
                            dlHTML += "<dd>\(processInline(definition))</dd>\n"
                            j += 1
                        }

                        // Check if next line is another term (non-empty, not starting with special chars)
                        if j < lines.count {
                            let nextLine = lines[j]
                            if nextLine.trimmingCharacters(in: .whitespaces).isEmpty {
                                break
                            }
                            // Check if there's a definition line following
                            if j + 1 < lines.count && !lines[j + 1].hasPrefix(": ") {
                                break
                            }
                        }
                    }

                    dlHTML += "</dl>"
                    processedLines.append(dlHTML)
                    i = j
                    continue
                }
            }

            processedLines.append(line)
            i += 1
        }

        return processedLines.joined(separator: "\n")
    }

    /// Generate table of contents HTML from collected headers
    private static func generateTOC(from headers: [(level: Int, text: String, id: String)]) -> String {
        guard !headers.isEmpty else { return "" }

        var toc = "<nav class=\"toc\"><ul>\n"
        var currentLevel = headers.first?.level ?? 1

        for header in headers {
            while currentLevel < header.level {
                toc += "<ul>\n"
                currentLevel += 1
            }
            while currentLevel > header.level {
                toc += "</ul>\n"
                currentLevel -= 1
            }
            toc += "<li><a href=\"#\(header.id)\">\(escapeHTML(header.text))</a></li>\n"
        }

        while currentLevel > (headers.first?.level ?? 1) {
            toc += "</ul>\n"
            currentLevel -= 1
        }

        toc += "</ul></nav>"
        return toc
    }

    /// Generate a URL-safe ID from header text
    private static func generateHeaderId(_ text: String) -> String {
        text.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)
    }

    /// Process inline markdown elements (bold, italic, links, images)
    private static func processInline(_ text: String) -> String {
        var result = text

        // Images: ![alt](src "title") or ![alt](src)
        result = result.replacingOccurrences(
            of: "!\\[([^\\]]*)\\]\\(([^)\"]+)(?:\\s+\"([^\"]+)\")?\\)",
            with: "<img src=\"$2\" alt=\"$1\" title=\"$3\">",
            options: .regularExpression
        )

        // Links: [text](url "title") or [text](url)
        result = result.replacingOccurrences(
            of: "\\[([^\\]]+)\\]\\(([^)\"]+)(?:\\s+\"([^\"]+)\")?\\)",
            with: "<a href=\"$2\" title=\"$3\">$1</a>",
            options: .regularExpression
        )

        // Bold+Italic: ***text*** or ___text___ (must be processed before bold and italic)
        result = result.replacingOccurrences(
            of: "\\*\\*\\*(.+?)\\*\\*\\*",
            with: "<strong><em>$1</em></strong>",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: "___(.+?)___",
            with: "<strong><em>$1</em></strong>",
            options: .regularExpression
        )

        // Bold: **text** or __text__
        result = result.replacingOccurrences(
            of: "\\*\\*(.+?)\\*\\*",
            with: "<strong>$1</strong>",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: "__(.+?)__",
            with: "<strong>$1</strong>",
            options: .regularExpression
        )

        // Italic: *text* or _text_
        result = result.replacingOccurrences(
            of: "(?<!\\*)\\*([^*]+)\\*(?!\\*)",
            with: "<em>$1</em>",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: "(?<![\\w_])_([^_]+)_(?![\\w_])",
            with: "<em>$1</em>",
            options: .regularExpression
        )

        // Strikethrough: ~~text~~
        result = result.replacingOccurrences(
            of: "~~([^~]+)~~",
            with: "<del>$1</del>",
            options: .regularExpression
        )

        // Highlight: ==text==
        result = result.replacingOccurrences(
            of: "==([^=]+)==",
            with: "<mark>$1</mark>",
            options: .regularExpression
        )

        // Subscript: ~text~ (single tilde, not double which is strikethrough)
        result = result.replacingOccurrences(
            of: "(?<!~)~([^~]+)~(?!~)",
            with: "<sub>$1</sub>",
            options: .regularExpression
        )

        // Superscript: ^text^
        result = result.replacingOccurrences(
            of: "\\^([^^]+)\\^",
            with: "<sup>$1</sup>",
            options: .regularExpression
        )

        // Auto-links: <https://url> or <http://url>
        result = result.replacingOccurrences(
            of: "<(https?://[^>]+)>",
            with: "<a href=\"$1\">$1</a>",
            options: .regularExpression
        )

        // Email auto-links: <email@example.com>
        result = result.replacingOccurrences(
            of: "<([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,})>",
            with: "<a href=\"mailto:$1\">$1</a>",
            options: .regularExpression
        )

        // Bare URLs (not already in a link or image)
        result = result.replacingOccurrences(
            of: "(?<![\"(])\\b(https?://[^\\s<>\"'\\)]+)",
            with: "<a href=\"$1\">$1</a>",
            options: .regularExpression
        )

        // Emoji shortcodes: :emoji_name:
        result = processEmojiShortcodes(result)

        return result
    }

    /// Process emoji shortcodes like :smile: to actual emoji
    private static func processEmojiShortcodes(_ text: String) -> String {
        var result = text
        let pattern = ":([a-z0-9_+-]+):"

        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let matches = regex.matches(in: result, options: [], range: NSRange(result.startIndex..., in: result)).reversed()
            for match in matches {
                if let fullRange = Range(match.range, in: result),
                   let codeRange = Range(match.range(at: 1), in: result) {
                    let code = String(result[codeRange])
                    if let emoji = emojiMap[code] {
                        result.replaceSubrange(fullRange, with: emoji)
                    }
                }
            }
        }
        return result
    }

    /// Common emoji shortcode mappings
    private static let emojiMap: [String: String] = [
        // Smileys & Emotion
        "smile": "😄", "grin": "😁", "joy": "😂", "rofl": "🤣", "smiley": "😃",
        "laugh": "😆", "wink": "😉", "blush": "😊", "heart_eyes": "😍", "kissing_heart": "😘",
        "thinking": "🤔", "neutral": "😐", "expressionless": "😑", "unamused": "😒", "sweat": "😓",
        "pensive": "😔", "confused": "😕", "upside_down": "🙃", "money_mouth": "🤑", "astonished": "😲",
        "frowning": "😦", "anguished": "😧", "fearful": "😨", "cold_sweat": "😰", "cry": "😢",
        "sob": "😭", "scream": "😱", "tired": "😫", "sleepy": "😪", "sleeping": "😴",
        "drool": "🤤", "yum": "😋", "sunglasses": "😎", "nerd": "🤓", "monocle": "🧐",
        "worried": "😟", "angry": "😠", "rage": "😡", "triumph": "😤", "skull": "💀",
        "poop": "💩", "clown": "🤡", "ogre": "👹", "ghost": "👻", "alien": "👽",
        "robot": "🤖", "cat": "😺", "heart": "❤️", "broken_heart": "💔", "fire": "🔥",
        "sparkles": "✨", "star": "⭐", "zap": "⚡", "boom": "💥", "100": "💯",

        // Gestures & People
        "wave": "👋", "raised_hand": "✋", "ok_hand": "👌", "pinched": "🤌", "v": "✌️",
        "crossed_fingers": "🤞", "love_you": "🤟", "rock_on": "🤘", "thumbsup": "👍", "thumbsdown": "👎",
        "fist": "👊", "punch": "🤛", "clap": "👏", "raised_hands": "🙌", "open_hands": "👐",
        "palms_up": "🤲", "handshake": "🤝", "pray": "🙏", "writing_hand": "✍️", "muscle": "💪",
        "point_up": "☝️", "point_down": "👇", "point_left": "👈", "point_right": "👉",
        "eyes": "👀", "eye": "👁️", "brain": "🧠", "ear": "👂",

        // Animals & Nature
        "dog": "🐕", "cat_face": "🐱", "mouse": "🐭", "hamster": "🐹", "rabbit": "🐰",
        "fox": "🦊", "bear": "🐻", "panda": "🐼", "koala": "🐨", "tiger": "🐯",
        "lion": "🦁", "cow": "🐮", "pig": "🐷", "frog": "🐸", "monkey": "🐵",
        "chicken": "🐔", "penguin": "🐧", "bird": "🐦", "eagle": "🦅", "duck": "🦆",
        "owl": "🦉", "bat": "🦇", "wolf": "🐺", "horse": "🐴", "unicorn": "🦄",
        "bee": "🐝", "bug": "🐛", "butterfly": "🦋", "snail": "🐌", "shell": "🐚",
        "crab": "🦀", "shrimp": "🦐", "squid": "🦑", "octopus": "🐙", "fish": "🐟",
        "dolphin": "🐬", "whale": "🐳", "shark": "🦈", "snake": "🐍", "dragon": "🐉",
        "tree": "🌲", "palm": "🌴", "cactus": "🌵", "flower": "🌸", "rose": "🌹",
        "sunflower": "🌻", "leaf": "🍃", "maple_leaf": "🍁", "mushroom": "🍄",

        // Food & Drink
        "apple": "🍎", "orange": "🍊", "lemon": "🍋", "banana": "🍌", "watermelon": "🍉",
        "grapes": "🍇", "strawberry": "🍓", "peach": "🍑", "cherry": "🍒", "mango": "🥭",
        "avocado": "🥑", "eggplant": "🍆", "potato": "🥔", "carrot": "🥕", "corn": "🌽",
        "pepper": "🌶️", "broccoli": "🥦", "garlic": "🧄", "onion": "🧅", "tomato": "🍅",
        "bread": "🍞", "croissant": "🥐", "baguette": "🥖", "pretzel": "🥨", "cheese": "🧀",
        "egg": "🥚", "bacon": "🥓", "pancakes": "🥞", "waffle": "🧇", "pizza": "🍕",
        "hamburger": "🍔", "fries": "🍟", "hotdog": "🌭", "sandwich": "🥪", "taco": "🌮",
        "burrito": "🌯", "sushi": "🍣", "ramen": "🍜", "spaghetti": "🍝", "curry": "🍛",
        "cake": "🍰", "cupcake": "🧁", "pie": "🥧", "chocolate": "🍫", "candy": "🍬",
        "lollipop": "🍭", "donut": "🍩", "cookie": "🍪", "ice_cream": "🍨", "coffee": "☕",
        "tea": "🍵", "beer": "🍺", "wine": "🍷", "cocktail": "🍸", "champagne": "🍾",

        // Activities & Objects
        "soccer": "⚽", "basketball": "🏀", "football": "🏈", "baseball": "⚾", "tennis": "🎾",
        "golf": "⛳", "trophy": "🏆", "medal": "🏅", "ticket": "🎫", "guitar": "🎸",
        "piano": "🎹", "drum": "🥁", "microphone": "🎤", "headphones": "🎧", "movie": "🎬",
        "art": "🎨", "game": "🎮", "dice": "🎲", "puzzle": "🧩", "teddy": "🧸",
        "balloon": "🎈", "party": "🎉", "confetti": "🎊", "gift": "🎁", "ribbon": "🎀",
        "computer": "💻", "keyboard": "⌨️", "phone": "📱", "tablet": "📲", "camera": "📷",
        "video": "📹", "tv": "📺", "radio": "📻", "flashlight": "🔦", "bulb": "💡",
        "book": "📖", "books": "📚", "notebook": "📓", "pencil": "✏️", "pen": "🖊️",
        "memo": "📝", "folder": "📁", "clipboard": "📋", "calendar": "📅", "chart": "📊",
        "paperclip": "📎", "scissors": "✂️", "lock": "🔒", "unlock": "🔓", "key": "🔑",
        "hammer": "🔨", "wrench": "🔧", "gear": "⚙️", "link": "🔗", "magnet": "🧲",

        // Symbols & Misc
        "check": "✅", "x": "❌", "question": "❓", "exclamation": "❗", "warning": "⚠️",
        "no_entry": "⛔", "prohibited": "🚫", "recycle": "♻️", "white_check": "✔️",
        "red_circle": "🔴", "orange_circle": "🟠", "yellow_circle": "🟡", "green_circle": "🟢",
        "blue_circle": "🔵", "purple_circle": "🟣", "black_circle": "⚫", "white_circle": "⚪",
        "red_square": "🟥", "orange_square": "🟧", "yellow_square": "🟨", "green_square": "🟩",
        "blue_square": "🟦", "purple_square": "🟪", "black_square": "⬛", "white_square": "⬜",
        "up": "⬆️", "down": "⬇️", "left": "⬅️", "right": "➡️",
        "arrow_up": "⬆️", "arrow_down": "⬇️", "arrow_left": "⬅️", "arrow_right": "➡️",
        "plus": "➕", "minus": "➖", "multiply": "✖️", "divide": "➗", "infinity": "♾️",
        "copyright": "©️", "registered": "®️", "tm": "™️",

        // Weather & Time
        "sun": "☀️", "moon": "🌙", "cloud": "☁️", "rain": "🌧️", "snow": "❄️",
        "lightning": "⚡", "rainbow": "🌈", "umbrella": "☂️", "snowman": "⛄",
        "hourglass": "⏳", "watch": "⌚", "alarm": "⏰", "stopwatch": "⏱️", "timer": "⏲️",

        // Flags & Places
        "flag_white": "🏳️", "flag_black": "🏴", "checkered_flag": "🏁", "triangular_flag": "🚩",
        "house": "🏠", "office": "🏢", "hospital": "🏥", "bank": "🏦", "hotel": "🏨",
        "school": "🏫", "church": "⛪", "mosque": "🕌", "synagogue": "🕍", "temple": "🛕",
        "rocket": "🚀", "airplane": "✈️", "car": "🚗", "bus": "🚌", "train": "🚆",
        "ship": "🚢", "anchor": "⚓", "earth": "🌍", "globe": "🌐", "world_map": "🗺️"
    ]

    /// Escape HTML special characters
    private static func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    /// Check if a line is a horizontal rule (3+ of same char: -, *, or _)
    private static func isHorizontalRule(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 3 else { return false }

        // Check for ---, ***, or ___ patterns (may have spaces between)
        let noSpaces = trimmed.replacingOccurrences(of: " ", with: "")
        guard noSpaces.count >= 3 else { return false }

        // Must be all same character
        let chars = Set(noSpaces)
        guard chars.count == 1 else { return false }

        // Must be one of the valid HR characters
        let validChars: Set<Character> = ["-", "*", "_"]
        return validChars.contains(chars.first!)
    }
}
