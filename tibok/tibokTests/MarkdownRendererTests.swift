//
//  MarkdownRendererTests.swift
//  tibokTests
//
//  Tests for the MarkdownRenderer.
//

import Testing
@testable import tibok

@Suite("Markdown Renderer Tests")
struct MarkdownRendererTests {

    @Test("Render heading")
    func renderHeading() {
        let markdown = "# Hello World"
        let html = MarkdownRenderer.render(markdown)
        #expect(html.contains("<h1>"))
        #expect(html.contains("Hello World"))
    }

    @Test("Render paragraph")
    func renderParagraph() {
        let markdown = "This is a paragraph."
        let html = MarkdownRenderer.render(markdown)
        #expect(html.contains("<p>"))
        #expect(html.contains("This is a paragraph."))
    }

    @Test("Render bold")
    func renderBold() {
        let markdown = "**bold text**"
        let html = MarkdownRenderer.render(markdown)
        #expect(html.contains("<strong>"))
    }

    @Test("Render italic")
    func renderItalic() {
        let markdown = "*italic text*"
        let html = MarkdownRenderer.render(markdown)
        #expect(html.contains("<em>"))
    }

    @Test("Render link")
    func renderLink() {
        let markdown = "[Link](https://example.com)"
        let html = MarkdownRenderer.render(markdown)
        #expect(html.contains("<a"))
        #expect(html.contains("href"))
    }

    @Test("Render code block")
    func renderCodeBlock() {
        let markdown = """
        ```swift
        let x = 1
        ```
        """
        let html = MarkdownRenderer.render(markdown)
        #expect(html.contains("<pre>") || html.contains("<code>"))
    }

    @Test("Render bullet list")
    func renderBulletList() {
        let markdown = """
        - Item 1
        - Item 2
        - Item 3
        """
        let html = MarkdownRenderer.render(markdown)
        #expect(html.contains("<ul>"))
        #expect(html.contains("<li>"))
    }

    @Test("Render numbered list")
    func renderNumberedList() {
        let markdown = """
        1. First
        2. Second
        3. Third
        """
        let html = MarkdownRenderer.render(markdown)
        #expect(html.contains("<ol>"))
        #expect(html.contains("<li>"))
    }

    @Test("Render blockquote")
    func renderBlockquote() {
        let markdown = "> This is a quote"
        let html = MarkdownRenderer.render(markdown)
        #expect(html.contains("<blockquote>"))
    }

    @Test("Render horizontal rule")
    func renderHorizontalRule() {
        let markdown = "---"
        let html = MarkdownRenderer.render(markdown)
        #expect(html.contains("<hr"))
    }

    @Test("Render table")
    func renderTable() {
        let markdown = """
        | Column 1 | Column 2 |
        |----------|----------|
        | Cell 1   | Cell 2   |
        """
        let html = MarkdownRenderer.render(markdown)
        #expect(html.contains("<table>"))
        #expect(html.contains("<th>") || html.contains("<td>"))
    }

    @Test("Render task list")
    func renderTaskList() {
        let markdown = """
        - [ ] Todo item
        - [x] Done item
        """
        let html = MarkdownRenderer.render(markdown)
        #expect(html.contains("checkbox") || html.contains("type=\"checkbox\""))
    }

    @Test("Empty input returns valid output")
    func emptyInput() {
        let markdown = ""
        let html = MarkdownRenderer.render(markdown)
        // Should return empty or minimal HTML
        #expect(html != nil)
    }
}
