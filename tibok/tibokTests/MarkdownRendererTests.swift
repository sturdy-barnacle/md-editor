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

    @Test func renderNestedUnorderedList() {
        let markdown = """
        - Parent 1
          - Child 1a
          - Child 1b
        - Parent 2
        """
        let html = MarkdownRenderer.render(markdown)
        #expect(html.contains("<ul>"))
        #expect(html.contains("<li>Parent 1"))
        #expect(html.contains("<ul>"))
        #expect(html.contains("<li>Child 1a"))
        #expect(html.contains("<li>Child 1b"))
        #expect(html.contains("<li>Parent 2"))
        #expect(html.contains("</ul>"))
    }

    @Test func renderMixedNestedLists() {
        let markdown = """
        1. Ordered parent
           - Unordered child
        2. Second ordered
        """
        let html = MarkdownRenderer.render(markdown)
        #expect(html.contains("<ol>"))
        #expect(html.contains("<li>Ordered parent"))
        #expect(html.contains("<ul>"))
        #expect(html.contains("<li>Unordered child"))
        #expect(html.contains("<li>Second ordered"))
    }

    @Test func renderThreeLevelNestedList() {
        let markdown = """
        - Level 1
          - Level 2
            - Level 3
        """
        let html = MarkdownRenderer.render(markdown)
        #expect(html.contains("<li>Level 1"))
        #expect(html.contains("<li>Level 2"))
        #expect(html.contains("<li>Level 3"))
        // Should have 3 opening <ul> tags
        let ulCount = html.components(separatedBy: "<ul>").count - 1
        #expect(ulCount == 3)
    }

    @Test func renderNestedTaskList() {
        let markdown = """
        - [ ] Parent task
          - [x] Completed child
          - [ ] Pending child
        """
        let html = MarkdownRenderer.render(markdown)
        #expect(html.contains("checkbox"))
        #expect(html.contains("checked"))
        #expect(html.contains("<li>"))
        #expect(html.contains("Parent task"))
        #expect(html.contains("Completed child"))
        #expect(html.contains("Pending child"))
    }

    @Test func switchListTypesAtSameLevel() {
        let markdown = """
        - Unordered item
        1. Ordered item
        """
        let html = MarkdownRenderer.render(markdown)
        #expect(html.contains("<ul>"))
        #expect(html.contains("<ol>"))
        #expect(html.contains("</ul>"))
        #expect(html.contains("</ol>"))
    }

    @Test func complexNestedStructure() {
        let markdown = """
        - First item
          1. Nested ordered
          2. Another ordered
        - Second item
          - Nested unordered
            - Deep nested
        """
        let html = MarkdownRenderer.render(markdown)
        #expect(html.contains("<ul>"))
        #expect(html.contains("<ol>"))
        #expect(html.contains("<li>First item"))
        #expect(html.contains("<li>Nested ordered"))
        #expect(html.contains("<li>Second item"))
        #expect(html.contains("<li>Nested unordered"))
        #expect(html.contains("<li>Deep nested"))
    }
}
