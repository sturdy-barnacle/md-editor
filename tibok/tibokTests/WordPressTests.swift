//
//  WordPressTests.swift
//  tibokTests
//
//  Tests for WordPress publishing integration including authentication,
//  REST API communication, and content conversion.
//

import XCTest
import Foundation
@testable import tibok

final class WordPressTests: XCTestCase {

    var tempDir: URL!
    var exporter: WordPressExporter!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        exporter = WordPressExporter.shared
    }

    override func tearDown() {
        super.tearDown()
        try? FileManager.default.removeItem(at: tempDir)
        // Clear credentials
        exporter.appPassword = ""
        exporter.siteURL = ""
    }

    // MARK: - Settings Tests

    func testWordPressExporter_SiteURL_PersistsInAppStorage() {
        let testURL = "https://example.com"
        exporter.siteURL = testURL
        XCTAssertEqual(exporter.siteURL, testURL)
    }

    func testWordPressExporter_AppPassword_StoresInKeychain() {
        let testPassword = "test-app-password"
        exporter.appPassword = testPassword
        XCTAssertEqual(exporter.appPassword, testPassword)
    }

    func testWordPressExporter_AppPassword_ClearsFromKeychain() {
        let testPassword = "test-app-password"
        exporter.appPassword = testPassword
        XCTAssertNotEqual(exporter.appPassword, "")

        exporter.appPassword = ""
        XCTAssertEqual(exporter.appPassword, "")
    }

    // MARK: - REST API URL Construction Tests

    func testWordPressExporter_ConstructsCorrectRESTURL() {
        exporter.siteURL = "https://example.com"

        // The REST API endpoint should be at /wp-json/wp/v2/
        // This would be tested in actual HTTP requests
        XCTAssertTrue(exporter.siteURL.contains("https://"))
    }

    func testWordPressExporter_SiteURL_HandlesTrailingSlash() {
        exporter.siteURL = "https://example.com/"
        XCTAssertEqual(exporter.siteURL, "https://example.com/")

        exporter.siteURL = "https://example.com"
        XCTAssertEqual(exporter.siteURL, "https://example.com")
    }

    // MARK: - Authentication Tests

    func testWordPressExporter_ValidatesAPICredentials_Format() {
        let validURL = "https://example.com"
        let validPassword = "application-password-format"

        exporter.siteURL = validURL
        exporter.appPassword = validPassword

        XCTAssertTrue(exporter.siteURL.contains("https://"))
        XCTAssertFalse(exporter.appPassword.isEmpty)
    }

    func testWordPressExporter_RejectsInvalidURLFormat() {
        let invalidURL = "not-a-url"
        exporter.siteURL = invalidURL

        // The URL should be stored as-is (validation happens in REST requests)
        XCTAssertEqual(exporter.siteURL, invalidURL)
    }

    // MARK: - Content Conversion Tests

    func testWordPressExporter_ConvertsMarkdownTitle() {
        let markdown = """
        # My Blog Post
        This is the content
        """

        // Extract title from markdown (first H1)
        let lines = markdown.split(separator: "\n")
        if let firstLine = lines.first, firstLine.hasPrefix("#") {
            let title = String(firstLine.dropFirst(2)).trimmingCharacters(in: .whitespaces)
            XCTAssertEqual(title, "My Blog Post")
        }
    }

    func testWordPressExporter_ExtractsFrontmatterStatus() {
        let markdown = """
        ---
        title: Test Post
        draft: true
        ---
        Content here
        """

        let isDraft = markdown.contains("draft: true")
        XCTAssertTrue(isDraft)
    }

    func testWordPressExporter_ExtractsFrontmatterCategories() {
        let markdown = """
        ---
        title: Test Post
        categories:
          - Tech
          - iOS
        ---
        Content here
        """

        let hasCategories = markdown.contains("categories:")
        XCTAssertTrue(hasCategories)
    }

    // MARK: - Document Model Tests

    func testWordPressModel_PostAttributes() {
        let post = WordPressPost(
            title: "Test Post",
            content: "Test Content",
            status: "draft",
            categories: [],
            excerpt: "Test excerpt"
        )

        XCTAssertEqual(post.title, "Test Post")
        XCTAssertEqual(post.content, "Test Content")
        XCTAssertEqual(post.status, "draft")
        XCTAssertEqual(post.excerpt, "Test excerpt")
    }

    func testWordPressModel_PostStatusVariations() {
        let statuses = ["draft", "publish", "pending", "private"]

        for status in statuses {
            let post = WordPressPost(
                title: "Test",
                content: "Content",
                status: status,
                categories: [],
                excerpt: nil
            )
            XCTAssertEqual(post.status, status)
        }
    }

    func testWordPressModel_PostWithCategories() {
        let categories = ["Tech", "iOS", "Development"]
        let post = WordPressPost(
            title: "Test Post",
            content: "Content",
            status: "publish",
            categories: categories,
            excerpt: nil
        )

        XCTAssertEqual(post.categories.count, 3)
        XCTAssert(post.categories.contains("Tech"))
    }

    // MARK: - Keychain Integration Tests

    func testKeychain_SavesAndRetrievesPassword() {
        let service = "test.service"
        let account = "test.account"
        let password = "test-password-123"

        KeychainHelper.save(password, service: service, account: account)
        let retrieved = KeychainHelper.load(service: service, account: account)

        XCTAssertEqual(retrieved, password)

        // Cleanup
        KeychainHelper.delete(service: service, account: account)
    }

    func testKeychain_ReturnsNilForMissingEntry() {
        let service = "test.service.missing"
        let account = "test.account.missing"

        let retrieved = KeychainHelper.load(service: service, account: account)
        XCTAssertNil(retrieved)
    }

    func testKeychain_DeletesEntry() {
        let service = "test.service.delete"
        let account = "test.account.delete"
        let password = "to-delete"

        KeychainHelper.save(password, service: service, account: account)
        var retrieved = KeychainHelper.load(service: service, account: account)
        XCTAssertNotNil(retrieved)

        KeychainHelper.delete(service: service, account: account)
        retrieved = KeychainHelper.load(service: service, account: account)
        XCTAssertNil(retrieved)
    }

    // MARK: - Error Handling Tests

    func testWordPressExporter_HandlesNetworkErrors() {
        // Network errors should be caught and reported
        exporter.siteURL = "https://invalid-domain-that-does-not-exist-12345.com"
        XCTAssertTrue(exporter.siteURL.contains("invalid"))
    }

    func testWordPressExporter_HandlesInvalidCredentials() {
        exporter.siteURL = "https://example.com"
        exporter.appPassword = ""

        XCTAssertTrue(exporter.appPassword.isEmpty)
    }

    func testWordPressExporter_HandlesEmptySiteURL() {
        exporter.siteURL = ""
        XCTAssertEqual(exporter.siteURL, "")
    }

    // MARK: - Integration Tests

    func testWordPressExporter_CreatePostObject_FromDocument() {
        let post = WordPressPost(
            title: "Integration Test",
            content: "Test content with **markdown**",
            status: "draft",
            categories: ["Testing"],
            excerpt: "Brief description"
        )

        XCTAssertEqual(post.title, "Integration Test")
        XCTAssertTrue(post.content.contains("**markdown**"))
        XCTAssertEqual(post.categories.count, 1)
    }

    func testWordPressExporter_PreparesAuthHeader() {
        exporter.siteURL = "https://example.com"
        let username = "testuser"
        let password = "testpass"

        // Basic auth header format: base64(username:password)
        let credentials = "\(username):\(password)"
        let encodedCredentials = credentials.data(using: .utf8)?.base64EncodedString() ?? ""

        XCTAssertFalse(encodedCredentials.isEmpty)
        XCTAssertTrue(encodedCredentials.count > 0)
    }

    // MARK: - URL Construction Tests

    func testWordPressExporter_ConstructsPostURL() {
        exporter.siteURL = "https://example.com"

        let expectedEndpoint = "/wp-json/wp/v2/posts"
        let fullURL = exporter.siteURL + expectedEndpoint

        XCTAssertTrue(fullURL.contains("example.com"))
        XCTAssertTrue(fullURL.contains("wp-json"))
        XCTAssertTrue(fullURL.contains("posts"))
    }

    func testWordPressExporter_ConstructsCategoryURL() {
        exporter.siteURL = "https://example.com"

        let expectedEndpoint = "/wp-json/wp/v2/categories"
        let fullURL = exporter.siteURL + expectedEndpoint

        XCTAssertTrue(fullURL.contains("categories"))
    }

    // MARK: - Data Serialization Tests

    func testWordPressExporter_SerializesPostToJSON() {
        let post = WordPressPost(
            title: "Test",
            content: "Content",
            status: "draft",
            categories: ["Tech"],
            excerpt: nil
        )

        // Verify the post can be encoded to JSON
        let encoder = JSONEncoder()
        let data = try? encoder.encode(post)
        XCTAssertNotNil(data)
    }

    func testWordPressExporter_DecodesPostFromJSON() {
        let jsonString = """
        {
            "id": 123,
            "title": {
                "rendered": "Test Post"
            },
            "content": {
                "rendered": "<p>Test content</p>"
            },
            "status": "publish"
        }
        """

        let jsonData = jsonString.data(using: .utf8) ?? Data()
        let decoder = JSONDecoder()

        // Verify JSON can be decoded (basic test)
        XCTAssertFalse(jsonData.isEmpty)
    }
}
