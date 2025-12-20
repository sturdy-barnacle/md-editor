//
//  FrontmatterTests.swift
//  tibokTests
//
//  Tests for Jekyll/Hugo frontmatter parsing (YAML and TOML).
//

import Testing
import Foundation
@testable import tibok

@Suite("Frontmatter Tests")
struct FrontmatterTests {

    // MARK: - YAML Parsing Tests

    @Test("Parse simple YAML frontmatter")
    func parseSimpleYAML() {
        let content = """
        ---
        title: My Blog Post
        date: 2025-01-15
        draft: false
        ---

        # Hello World
        """

        let (frontmatter, body) = Frontmatter.parse(from: content)

        #expect(frontmatter != nil)
        #expect(frontmatter?.format == .yaml)
        #expect(frontmatter?.title == "My Blog Post")
        #expect(frontmatter?.draft == false)
        #expect(body.trimmingCharacters(in: .whitespacesAndNewlines) == "# Hello World")
    }

    @Test("Parse YAML frontmatter with arrays")
    func parseYAMLWithArrays() {
        let content = """
        ---
        title: Test Post
        tags: [swift, testing, ci]
        categories:
          - Technology
          - Development
        ---

        Content here.
        """

        let (frontmatter, _) = Frontmatter.parse(from: content)

        #expect(frontmatter != nil)
        #expect(frontmatter?.tags.count == 3)
        #expect(frontmatter?.tags.contains("swift") == true)
        #expect(frontmatter?.tags.contains("testing") == true)
        #expect(frontmatter?.categories.count == 2)
        #expect(frontmatter?.categories.contains("Technology") == true)
    }

    @Test("Parse YAML frontmatter with date and time")
    func parseYAMLWithDateTime() {
        let content = """
        ---
        title: Time Test
        date: 2025-01-15T10:30:00-08:00
        ---

        Content.
        """

        let (frontmatter, _) = Frontmatter.parse(from: content)

        #expect(frontmatter != nil)
        #expect(frontmatter?.date != nil)
    }

    @Test("Parse YAML frontmatter with quoted strings")
    func parseYAMLWithQuotes() {
        let content = """
        ---
        title: "A Title: With Colon"
        description: 'Single quoted string'
        ---

        Body
        """

        let (frontmatter, _) = Frontmatter.parse(from: content)

        #expect(frontmatter != nil)
        #expect(frontmatter?.title == "A Title: With Colon")
        #expect(frontmatter?.description == "Single quoted string")
    }

    @Test("Parse YAML frontmatter with numbers")
    func parseYAMLWithNumbers() {
        let content = """
        ---
        title: Test
        count: 42
        percentage: 95.5
        ---

        Body
        """

        let (frontmatter, _) = Frontmatter.parse(from: content)

        #expect(frontmatter != nil)
        #expect(frontmatter?.fields["count"]?.numberValue == 42)
        #expect(frontmatter?.fields["percentage"]?.numberValue == 95.5)
    }

    @Test("Parse YAML frontmatter with boolean values")
    func parseYAMLWithBooleans() {
        let content = """
        ---
        draft: true
        published: false
        ---

        Body
        """

        let (frontmatter, _) = Frontmatter.parse(from: content)

        #expect(frontmatter != nil)
        #expect(frontmatter?.draft == true)
        #expect(frontmatter?.fields["published"]?.boolValue == false)
    }

    @Test("Parse YAML with comments")
    func parseYAMLWithComments() {
        let content = """
        ---
        # This is a comment
        title: Test Post
        # Another comment
        date: 2025-01-15
        ---

        Body
        """

        let (frontmatter, _) = Frontmatter.parse(from: content)

        #expect(frontmatter != nil)
        #expect(frontmatter?.title == "Test Post")
    }

    @Test("Parse YAML with custom fields")
    func parseYAMLWithCustomFields() {
        let content = """
        ---
        title: Test
        customField1: value1
        customField2: value2
        ---

        Body
        """

        let (frontmatter, _) = Frontmatter.parse(from: content)

        #expect(frontmatter != nil)
        #expect(frontmatter?.fields["customField1"]?.stringValue == "value1")
        #expect(frontmatter?.fields["customField2"]?.stringValue == "value2")
    }

    // MARK: - TOML Parsing Tests

    @Test("Parse simple TOML frontmatter")
    func parseSimpleTOML() {
        let content = """
        +++
        title = "My Hugo Post"
        date = "2025-01-15"
        draft = false
        +++

        # Content
        """

        let (frontmatter, body) = Frontmatter.parse(from: content)

        #expect(frontmatter != nil)
        #expect(frontmatter?.format == .toml)
        #expect(frontmatter?.title == "My Hugo Post")
        #expect(frontmatter?.draft == false)
        #expect(body.trimmingCharacters(in: .whitespacesAndNewlines) == "# Content")
    }

    @Test("Parse TOML frontmatter with arrays")
    func parseTOMLWithArrays() {
        let content = """
        +++
        title = "Test"
        tags = ["hugo", "toml", "testing"]
        categories = ["Tech"]
        +++

        Body
        """

        let (frontmatter, _) = Frontmatter.parse(from: content)

        #expect(frontmatter != nil)
        #expect(frontmatter?.tags.count == 3)
        #expect(frontmatter?.tags.contains("hugo") == true)
    }

    @Test("Parse TOML frontmatter with booleans")
    func parseTOMLWithBooleans() {
        let content = """
        +++
        draft = true
        published = false
        +++

        Body
        """

        let (frontmatter, _) = Frontmatter.parse(from: content)

        #expect(frontmatter != nil)
        #expect(frontmatter?.draft == true)
        #expect(frontmatter?.fields["published"]?.boolValue == false)
    }

    @Test("Parse TOML with comments")
    func parseTOMLWithComments() {
        let content = """
        +++
        # TOML comment
        title = "Test"
        # Another comment
        +++

        Body
        """

        let (frontmatter, _) = Frontmatter.parse(from: content)

        #expect(frontmatter != nil)
        #expect(frontmatter?.title == "Test")
    }

    // MARK: - Edge Cases

    @Test("Parse content without frontmatter")
    func parseContentWithoutFrontmatter() {
        let content = """
        # Just a heading

        Regular content without frontmatter.
        """

        let (frontmatter, body) = Frontmatter.parse(from: content)

        #expect(frontmatter == nil)
        #expect(body == content)
    }

    @Test("Parse content with incomplete frontmatter")
    func parseIncompleteYAML() {
        let content = """
        ---
        title: Test
        # Missing closing delimiter

        Content
        """

        let (frontmatter, body) = Frontmatter.parse(from: content)

        // Should fail gracefully and return original content
        #expect(frontmatter == nil)
        #expect(body == content)
    }

    @Test("Parse empty frontmatter")
    func parseEmptyFrontmatter() {
        let content = """
        ---
        ---

        Body
        """

        let (frontmatter, body) = Frontmatter.parse(from: content)

        #expect(frontmatter != nil)
        #expect(frontmatter?.fields.isEmpty == true)
        #expect(body.trimmingCharacters(in: .whitespacesAndNewlines) == "Body")
    }

    @Test("Parse frontmatter with empty lines")
    func parseFrontmatterWithEmptyLines() {
        let content = """
        ---
        title: Test

        date: 2025-01-15

        ---

        Body
        """

        let (frontmatter, _) = Frontmatter.parse(from: content)

        #expect(frontmatter != nil)
        #expect(frontmatter?.title == "Test")
    }

    // MARK: - Serialization Tests

    @Test("Serialize YAML frontmatter")
    func serializeYAML() {
        var frontmatter = Frontmatter(format: .yaml)
        frontmatter.title = "Test Post"
        frontmatter.date = Date(timeIntervalSince1970: 1705334400) // 2025-01-15
        frontmatter.tags = ["swift", "testing"]
        frontmatter.draft = false

        let yaml = frontmatter.toString()

        #expect(yaml.contains("---"))
        #expect(yaml.contains("title: Test Post"))
        #expect(yaml.contains("draft: false"))
        #expect(yaml.contains("tags: [swift, testing]") || yaml.contains("tags: [testing, swift]"))
    }

    @Test("Serialize TOML frontmatter")
    func serializeTOML() {
        var frontmatter = Frontmatter(format: .toml)
        frontmatter.title = "Hugo Post"
        frontmatter.draft = true

        let toml = frontmatter.toString()

        #expect(toml.contains("+++"))
        #expect(toml.contains("title = \"Hugo Post\""))
        #expect(toml.contains("draft = true"))
    }

    @Test("Serialize frontmatter with special characters")
    func serializeWithSpecialCharacters() {
        var frontmatter = Frontmatter(format: .yaml)
        frontmatter.title = "Title: With Colon"
        frontmatter.description = "Description with \"quotes\""

        let yaml = frontmatter.toString()

        #expect(yaml.contains("title: \"Title: With Colon\""))
        #expect(yaml.contains("description:"))
    }

    @Test("Serialize and parse round-trip YAML")
    func roundTripYAML() {
        var original = Frontmatter(format: .yaml)
        original.title = "Round Trip Test"
        original.date = Date(timeIntervalSince1970: 1705334400)
        original.tags = ["test"]
        original.draft = false

        let yaml = original.toString()
        let content = "\(yaml)\n\nBody content"

        let (parsed, _) = Frontmatter.parse(from: content)

        #expect(parsed != nil)
        #expect(parsed?.title == "Round Trip Test")
        #expect(parsed?.tags.contains("test") == true)
        #expect(parsed?.draft == false)
    }

    @Test("Serialize and parse round-trip TOML")
    func roundTripTOML() {
        var original = Frontmatter(format: .toml)
        original.title = "TOML Round Trip"
        original.draft = true
        original.tags = ["hugo"]

        let toml = original.toString()
        let content = "\(toml)\n\nContent"

        let (parsed, _) = Frontmatter.parse(from: content)

        #expect(parsed != nil)
        #expect(parsed?.title == "TOML Round Trip")
        #expect(parsed?.draft == true)
    }

    // MARK: - Date Formatting Tests

    @Test("Format date with time and timezone")
    func formatDateWithTimeAndTimezone() {
        var frontmatter = Frontmatter(format: .yaml)
        frontmatter.includeDateWithTime = true
        frontmatter.timezoneIdentifier = "America/Los_Angeles"
        frontmatter.date = Date(timeIntervalSince1970: 1705334400) // 2025-01-15

        let yaml = frontmatter.toString()

        // Should contain ISO 8601 format with timezone
        #expect(yaml.contains("date: 2025-01-15T"))
    }

    @Test("Format date without time")
    func formatDateWithoutTime() {
        var frontmatter = Frontmatter(format: .yaml)
        frontmatter.includeDateWithTime = false
        frontmatter.date = Date(timeIntervalSince1970: 1705334400)

        let yaml = frontmatter.toString()

        // Should contain date-only format
        #expect(yaml.contains("date: 2025-01-15"))
        #expect(!yaml.contains("T"))  // No time separator
    }

    // MARK: - Apply to Document Tests

    @Test("Apply frontmatter to document")
    func applyFrontmatterToDocument() {
        var frontmatter = Frontmatter(format: .yaml)
        frontmatter.title = "New Title"

        let originalContent = """
        # Old Content

        Body text.
        """

        let newContent = frontmatter.apply(to: originalContent)

        #expect(newContent.contains("---"))
        #expect(newContent.contains("title: New Title"))
        #expect(newContent.contains("# Old Content"))
    }

    @Test("Apply frontmatter replaces existing")
    func applyFrontmatterReplacesExisting() {
        var newFrontmatter = Frontmatter(format: .yaml)
        newFrontmatter.title = "Updated Title"

        let originalContent = """
        ---
        title: Old Title
        ---

        Body
        """

        let newContent = newFrontmatter.apply(to: originalContent)

        #expect(newContent.contains("title: Updated Title"))
        #expect(!newContent.contains("Old Title"))
        #expect(newContent.contains("Body"))
    }

    @Test("Create document with frontmatter")
    func createDocumentWithFrontmatter() {
        var frontmatter = Frontmatter(format: .yaml)
        frontmatter.title = "New Document"
        frontmatter.date = Date()

        let body = "# Hello\n\nWorld"
        let document = Frontmatter.createDocument(frontmatter: frontmatter, body: body)

        #expect(document.contains("---"))
        #expect(document.contains("title: New Document"))
        #expect(document.contains("# Hello"))
    }
}
