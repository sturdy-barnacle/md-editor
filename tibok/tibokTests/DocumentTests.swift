//
//  DocumentTests.swift
//  tibokTests
//
//  Tests for the Document model.
//

import Testing
@testable import tibok

@Suite("Document Tests")
struct DocumentTests {

    @Test("New document has default values")
    func newDocumentHasDefaultValues() {
        let doc = Document.new()

        #expect(doc.title == "Untitled")
        #expect(doc.content.contains("# New Document"))
        #expect(doc.fileURL == nil)
        #expect(doc.isModified == false)
    }

    @Test("Word count is accurate")
    func wordCountIsAccurate() {
        let doc = Document(content: "Hello world, this is a test")
        #expect(doc.wordCount == 6)
    }

    @Test("Word count handles empty content")
    func wordCountHandlesEmptyContent() {
        let doc = Document(content: "")
        #expect(doc.wordCount == 0)
    }

    @Test("Character count is accurate")
    func characterCountIsAccurate() {
        let doc = Document(content: "Hello")
        #expect(doc.characterCount == 5)
    }

    @Test("Line count is accurate")
    func lineCountIsAccurate() {
        let doc = Document(content: "Line 1\nLine 2\nLine 3")
        #expect(doc.lineCount == 3)
    }

    @Test("Line count handles single line")
    func lineCountHandlesSingleLine() {
        let doc = Document(content: "Just one line")
        #expect(doc.lineCount == 1)
    }
}
