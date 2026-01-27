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
    
    @Test("Preview is supported for markdown files")
    func previewIsSupportedForMarkdownFiles() {
        let mdURL = URL(fileURLWithPath: "/path/to/file.md")
        let doc = Document(fileURL: mdURL)
        #expect(doc.isPreviewSupported == true)
    }
    
    @Test("Preview is supported for all markdown extensions")
    func previewIsSupportedForAllMarkdownExtensions() {
        let extensions = ["md", "markdown", "mdown", "mkd"]
        for ext in extensions {
            let url = URL(fileURLWithPath: "/path/to/file.\(ext)")
            let doc = Document(fileURL: url)
            #expect(doc.isPreviewSupported == true, ".\(ext) files should be previewable")
        }
    }
    
    @Test("Preview is not supported for non-markdown files")
    func previewIsNotSupportedForNonMarkdownFiles() {
        let tsxURL = URL(fileURLWithPath: "/path/to/file.tsx")
        let doc = Document(fileURL: tsxURL)
        #expect(doc.isPreviewSupported == false)
    }
    
    @Test("Preview is not supported for common text files")
    func previewIsNotSupportedForCommonTextFiles() {
        let extensions = ["txt", "tsx", "jsx", "js", "ts", "py", "swift"]
        for ext in extensions {
            let url = URL(fileURLWithPath: "/path/to/file.\(ext)")
            let doc = Document(fileURL: url)
            #expect(doc.isPreviewSupported == false, ".\(ext) files should not be previewable")
        }
    }
    
    @Test("Preview is supported for untitled documents")
    func previewIsSupportedForUntitledDocuments() {
        let doc = Document.new()
        #expect(doc.isPreviewSupported == true)
    }
    
    @Test("Preview support is case insensitive")
    func previewSupportIsCaseInsensitive() {
        let upperURL = URL(fileURLWithPath: "/path/to/file.MD")
        let mixedURL = URL(fileURLWithPath: "/path/to/file.Markdown")
        
        let upperDoc = Document(fileURL: upperURL)
        let mixedDoc = Document(fileURL: mixedURL)
        
        #expect(upperDoc.isPreviewSupported == true)
        #expect(mixedDoc.isPreviewSupported == true)
    }
    
    @Test("Preview is not supported for files without extensions")
    func previewIsNotSupportedForFilesWithoutExtensions() {
        let readmeURL = URL(fileURLWithPath: "/path/to/README")
        let licenseURL = URL(fileURLWithPath: "/path/to/LICENSE")
        
        let readmeDoc = Document(fileURL: readmeURL)
        let licenseDoc = Document(fileURL: licenseURL)
        
        #expect(readmeDoc.isPreviewSupported == false)
        #expect(licenseDoc.isPreviewSupported == false)
    }
}
