//
//  WordPressExporter.swift
//  tibok
//
//  Service for publishing markdown documents to WordPress via REST API v2
//  Uses Application Password authentication and Keychain for secure storage
//

import Foundation
import SwiftUI
import AppKit

@MainActor
final class WordPressExporter {

    // MARK: - Singleton

    static let shared = WordPressExporter()

    private init() {}

    // MARK: - Settings (Non-sensitive in UserDefaults)

    @AppStorage("plugin.wordpress.siteURL") var siteURL: String = ""
    @AppStorage("plugin.wordpress.username") private var username: String = ""
    @AppStorage("plugin.wordpress.defaultStatus") private var defaultStatus: String = "draft"
    @AppStorage("plugin.wordpress.defaultCategories") private var defaultCategories: String = ""
    @AppStorage("plugin.wordpress.defaultAuthor") private var defaultAuthor: String = ""
    @AppStorage("plugin.wordpress.defaultDescription") private var defaultDescription: String = ""

    // Multi-blog support (WordPress.com)
    @AppStorage("plugin.wordpress.sites") private var sitesJSON: String = "[]"
    @AppStorage("plugin.wordpress.activeSiteID") var activeSiteID: Int = 0

    // MARK: - Keychain Constants

    private let keychainService = "com.tibok.wordpress"
    private let keychainAccount = "application-password"

    // MARK: - Password (Sensitive, stored in Keychain)

    var appPassword: String {
        get {
            KeychainHelper.load(service: keychainService, account: keychainAccount) ?? ""
        }
        set {
            if newValue.isEmpty {
                KeychainHelper.delete(service: keychainService, account: keychainAccount)
            } else {
                KeychainHelper.save(newValue, service: keychainService, account: keychainAccount)
            }
        }
    }

    // MARK: - Multi-Blog Computed Properties

    var sites: [WordPressSite] {
        guard let data = sitesJSON.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([WordPressSite].self, from: data) else {
            return []
        }
        return decoded
    }

    var isWordPressDotCom: Bool {
        guard let url = URL(string: siteURL),
              let host = url.host?.lowercased() else {
            return false
        }
        return host == "wordpress.com" || host.hasSuffix(".wordpress.com")
    }

    // MARK: - Public Methods

    /// Publish a document to WordPress
    func publish(document: Document, appState: AppState) async {
        LogService.shared.info("Starting WordPress publish for document: \(document.title)")

        // 1. Cache credentials FIRST (read keychain only once)
        let cachedSiteURL = siteURL
        let cachedUsername = username
        let cachedPassword = appPassword

        // 2. Validate settings using cached values
        guard !cachedSiteURL.isEmpty && !cachedUsername.isEmpty && !cachedPassword.isEmpty else {
            NSLog("❌ WordPress settings validation failed")
            showSettingsError()
            return
        }

        // 3. Parse frontmatter
        let (frontmatter, body) = Frontmatter.parse(from: document.content)
        NSLog("   Frontmatter: \(frontmatter != nil ? "found" : "none")")

        // 4. Merge settings: frontmatter overrides defaults
        let title = frontmatter?.title ?? document.title
        let categories = frontmatter?.categories.isEmpty == false
            ? frontmatter!.categories
            : parseCategoriesFromSettings()
        let tags = frontmatter?.tags ?? []
        let status = frontmatter?.draft == true
            ? "draft"
            : defaultStatus
        let excerpt = frontmatter?.description ?? (defaultDescription.isEmpty ? nil : defaultDescription)
        let author = frontmatter?.author ?? (defaultAuthor.isEmpty ? nil : defaultAuthor)

        NSLog("   Title: \(title)")
        NSLog("   Categories: \(categories)")
        NSLog("   Tags: \(tags)")
        NSLog("   Status: \(status)")
        NSLog("   Excerpt: \(excerpt ?? "nil")")
        NSLog("   Author: \(author ?? "nil")")

        // 4. Convert markdown → HTML
        let html = MarkdownRenderer.render(body)

        // 5. Upload images and update paths
        let (processedHTML, uploadResults) = await ImageUploadService.shared.processImagesForWordPress(
            html: html,
            siteURL: cachedSiteURL,
            username: cachedUsername,
            appPassword: cachedPassword
        )

        // Show upload status if images were processed
        if !uploadResults.isEmpty {
            let successCount = uploadResults.filter { $0.success }.count
            let failCount = uploadResults.count - successCount

            if failCount == 0 {
                UIStateService.shared.showToast(
                    "Uploaded \(successCount) \(successCount == 1 ? "image" : "images")",
                    icon: "photo"
                )
            } else {
                UIStateService.shared.showToast(
                    "Uploaded \(successCount)/\(uploadResults.count) images (\(failCount) failed)",
                    icon: "photo.badge.exclamationmark"
                )
            }
        }

        // 6. Convert category/tag names to IDs
        var categoryIDs: [Int] = []
        for categoryName in categories {
            do {
                let id = try await getCategoryID(name: categoryName, siteURL: cachedSiteURL, username: cachedUsername, appPassword: cachedPassword)
                categoryIDs.append(id)
                NSLog("✅ WordPress: Resolved category '\(categoryName)' to ID \(id)")
            } catch {
                NSLog("⚠️ WordPress: Could not resolve category '\(categoryName)': \(error)")
                // Continue without this category
            }
        }

        var tagIDs: [Int] = []
        for tagName in tags {
            do {
                let id = try await getTagID(name: tagName, siteURL: cachedSiteURL, username: cachedUsername, appPassword: cachedPassword)
                tagIDs.append(id)
                NSLog("✅ WordPress: Resolved tag '\(tagName)' to ID \(id)")
            } catch {
                NSLog("⚠️ WordPress: Could not resolve tag '\(tagName)': \(error)")
                // Continue without this tag
            }
        }

        // 7. Call WordPress API
        do {
            let result = try await sendToWordPress(
                title: title,
                content: processedHTML,
                categories: categoryIDs,
                tags: tagIDs,
                status: status,
                excerpt: excerpt,
                author: author,
                siteURL: cachedSiteURL,
                username: cachedUsername,
                appPassword: cachedPassword
            )

            // 7. Success handling
            UIStateService.shared.showToast(
                "Published: \(result.link)",
                icon: "checkmark.circle.fill",
                duration: 10.0  // Longer duration to read URL
            )

            // Copy URL to clipboard
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(result.link, forType: .string)

            // Store publish info for status indicator
            storePublishInfo(
                documentPath: document.fileURL?.path ?? document.title,
                url: result.link,
                timestamp: Date()
            )

            // Open post in browser
            if let url = URL(string: result.link) {
                NSWorkspace.shared.open(url)
            }

            // 8. Trigger webhook
            await WebhookService.shared.triggerDocumentExport(
                filename: document.title,
                title: title,
                path: document.fileURL?.path ?? "",
                exportFormat: "wordpress"
            )
        } catch {
            handleError(error)
        }
    }

    /// Test connection to WordPress site
    func testConnection() async -> ConnectionTestResult {
        // Validate credentials
        guard validateSettings() else {
            return ConnectionTestResult(
                success: false,
                message: "Please fill in all required fields",
                siteName: nil
            )
        }

        // Try a simple API call
        let endpoint = "\(siteURL)/wp-json/wp/v2/posts?per_page=1"
        guard let url = URL(string: endpoint) else {
            return ConnectionTestResult(
                success: false,
                message: "Invalid site URL",
                siteName: nil
            )
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // Add Basic Auth
        let credentials = "\(username):\(appPassword)"
        if let credentialsData = credentials.data(using: .utf8) {
            let base64Credentials = credentialsData.base64EncodedString()
            request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return ConnectionTestResult(
                    success: false,
                    message: "Invalid response from server",
                    siteName: nil
                )
            }

            if (200...299).contains(httpResponse.statusCode) {
                return ConnectionTestResult(
                    success: true,
                    message: "Connection successful!",
                    siteName: siteURL
                )
            } else if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                return ConnectionTestResult(
                    success: false,
                    message: "Authentication failed. Check username and password.",
                    siteName: nil
                )
            } else {
                return ConnectionTestResult(
                    success: false,
                    message: "Server returned error: \(httpResponse.statusCode)",
                    siteName: nil
                )
            }
        } catch {
            return ConnectionTestResult(
                success: false,
                message: "Network error: \(error.localizedDescription)",
                siteName: nil
            )
        }
    }

    /// Discover blogs for WordPress.com account
    func discoverBlogs() async -> DiscoveryResult {
        // Only works for WordPress.com
        guard isWordPressDotCom else {
            return .notWordPressCom
        }

        // Validate credentials
        guard !username.isEmpty && !appPassword.isEmpty else {
            return .authenticationFailed
        }

        // WordPress.com REST API v1.1 endpoint
        let endpoint = "https://public-api.wordpress.com/rest/v1.1/me/sites"
        guard let url = URL(string: endpoint) else {
            return .networkError("Invalid API URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // Add Basic Auth
        let credentials = "\(username):\(appPassword)"
        if let credentialsData = credentials.data(using: .utf8) {
            let base64Credentials = credentialsData.base64EncodedString()
            request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return .networkError("Invalid response from server")
            }

            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                return .authenticationFailed
            }

            if (200...299).contains(httpResponse.statusCode) {
                let sitesResponse = try JSONDecoder().decode(WordPressSitesResponse.self, from: data)

                // Store sites
                if let encoded = try? JSONEncoder().encode(sitesResponse.sites),
                   let jsonString = String(data: encoded, encoding: .utf8) {
                    sitesJSON = jsonString
                }

                // Set first site as active if none selected
                if activeSiteID == 0, let firstSite = sitesResponse.sites.first {
                    activeSiteID = firstSite.id
                    siteURL = firstSite.url
                }

                return .success(count: sitesResponse.sites.count)
            } else {
                return .networkError("Server returned error: \(httpResponse.statusCode)")
            }
        } catch {
            return .networkError(error.localizedDescription)
        }
    }

    /// Switch to a different blog
    func switchBlog(to siteID: Int) {
        guard let site = sites.first(where: { $0.id == siteID }) else { return }
        activeSiteID = siteID
        siteURL = site.url
    }

    // MARK: - Private Methods

    /// Get or create category by name and return its ID
    private func getCategoryID(name: String, siteURL: String, username: String, appPassword: String) async throws -> Int {
        // First, try to find existing category
        let searchEndpoint = "\(siteURL)/wp-json/wp/v2/categories?search=\(name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name)"
        guard let searchURL = URL(string: searchEndpoint) else {
            throw WordPressError.invalidURL
        }

        var request = URLRequest(url: searchURL)
        request.httpMethod = "GET"

        // Add Basic Auth
        let credentials = "\(username):\(appPassword)"
        if let credentialsData = credentials.data(using: .utf8) {
            let base64Credentials = credentialsData.base64EncodedString()
            request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WordPressError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let responseText = String(data: data, encoding: .utf8) ?? "(unable to decode)"
            NSLog("❌ WordPress API error (status \(httpResponse.statusCode)) for category search:")
            NSLog("Response: \(responseText)")

            throw NSError(
                domain: "WordPressAPI",
                code: httpResponse.statusCode,
                userInfo: [
                    NSLocalizedDescriptionKey: "WordPress API error (\(httpResponse.statusCode)): \(responseText.prefix(200))..."
                ]
            )
        }

        let terms: [WordPressTerm]
        do {
            terms = try JSONDecoder().decode([WordPressTerm].self, from: data)
        } catch {
            let responseText = String(data: data, encoding: .utf8) ?? "(unable to decode)"
            NSLog("❌ Failed to decode category search response:")
            NSLog("Raw response: \(responseText)")

            // Create a more helpful error that includes the response
            let helpfulError = NSError(
                domain: "WordPressAPI",
                code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey: "Failed to decode category list. Response: \(responseText.prefix(200))..."
                ]
            )
            throw helpfulError
        }

        // If found, return its ID
        if let term = terms.first(where: { $0.name.lowercased() == name.lowercased() }) {
            return term.id
        }

        // Otherwise, create new category
        let createEndpoint = "\(siteURL)/wp-json/wp/v2/categories"
        guard let createURL = URL(string: createEndpoint) else {
            throw WordPressError.invalidURL
        }

        var createRequest = URLRequest(url: createURL)
        createRequest.httpMethod = "POST"
        createRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let credentialsData = credentials.data(using: .utf8) {
            let base64Credentials = credentialsData.base64EncodedString()
            createRequest.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        }

        let createBody = ["name": name]
        createRequest.httpBody = try JSONEncoder().encode(createBody)

        let (createData, createResponse) = try await URLSession.shared.data(for: createRequest)

        guard let createHTTPResponse = createResponse as? HTTPURLResponse,
              (200...299).contains(createHTTPResponse.statusCode) else {
            throw WordPressError.invalidResponse
        }

        let newTerm = try JSONDecoder().decode(WordPressTerm.self, from: createData)
        return newTerm.id
    }

    /// Get or create tag by name and return its ID
    private func getTagID(name: String, siteURL: String, username: String, appPassword: String) async throws -> Int {
        // First, try to find existing tag
        let searchEndpoint = "\(siteURL)/wp-json/wp/v2/tags?search=\(name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name)"
        guard let searchURL = URL(string: searchEndpoint) else {
            throw WordPressError.invalidURL
        }

        var request = URLRequest(url: searchURL)
        request.httpMethod = "GET"

        // Add Basic Auth
        let credentials = "\(username):\(appPassword)"
        if let credentialsData = credentials.data(using: .utf8) {
            let base64Credentials = credentialsData.base64EncodedString()
            request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw WordPressError.invalidResponse
        }

        let terms = try JSONDecoder().decode([WordPressTerm].self, from: data)

        // If found, return its ID
        if let term = terms.first(where: { $0.name.lowercased() == name.lowercased() }) {
            return term.id
        }

        // Otherwise, create new tag
        let createEndpoint = "\(siteURL)/wp-json/wp/v2/tags"
        guard let createURL = URL(string: createEndpoint) else {
            throw WordPressError.invalidURL
        }

        var createRequest = URLRequest(url: createURL)
        createRequest.httpMethod = "POST"
        createRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let credentialsData = credentials.data(using: .utf8) {
            let base64Credentials = credentialsData.base64EncodedString()
            createRequest.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        }

        let createBody = ["name": name]
        createRequest.httpBody = try JSONEncoder().encode(createBody)

        let (createData, createResponse) = try await URLSession.shared.data(for: createRequest)

        guard let createHTTPResponse = createResponse as? HTTPURLResponse,
              (200...299).contains(createHTTPResponse.statusCode) else {
            throw WordPressError.invalidResponse
        }

        let newTerm = try JSONDecoder().decode(WordPressTerm.self, from: createData)
        return newTerm.id
    }

    /// Send post to WordPress API
    private func sendToWordPress(
        title: String,
        content: String,
        categories: [Int],
        tags: [Int],
        status: String,
        excerpt: String?,
        author: String?,
        siteURL: String,
        username: String,
        appPassword: String
    ) async throws -> WordPressPostResponse {
        // Build endpoint URL - remove trailing slash from siteURL to avoid double slashes
        let cleanSiteURL = siteURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let endpoint = "\(cleanSiteURL)/wp-json/wp/v2/posts"
        guard let url = URL(string: endpoint) else {
            throw WordPressError.invalidURL
        }

        // Build request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add Basic Auth
        let credentials = "\(username):\(appPassword)"
        guard let credentialsData = credentials.data(using: .utf8) else {
            throw WordPressError.authenticationFailed
        }
        let base64Credentials = credentialsData.base64EncodedString()
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")

        // Build body
        let body = WordPressPostRequest(
            title: title,
            content: content,
            status: status,
            categories: categories.isEmpty ? nil : categories,
            excerpt: excerpt,
            tags: tags.isEmpty ? nil : tags,
            author: author
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let bodyData = try encoder.encode(body)
        request.httpBody = bodyData

        // Log request body
        if let bodyString = String(data: bodyData, encoding: .utf8) {
            LogService.shared.info("WordPress POST request to \(endpoint)")
            LogService.shared.debug("Request body: \(bodyString)")
        }

        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Handle response
        guard let httpResponse = response as? HTTPURLResponse else {
            LogService.shared.error("Invalid HTTP response (not HTTPURLResponse)")
            throw WordPressError.invalidResponse
        }

        let responseText = String(data: data, encoding: .utf8) ?? "(unable to decode)"
        LogService.shared.info("WordPress response status: \(httpResponse.statusCode)")
        LogService.shared.debug("WordPress response body: \(responseText)")

        if (200...299).contains(httpResponse.statusCode) {
            // Check if response is HTML instead of JSON (authentication redirect)
            if responseText.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("<!DOCTYPE") ||
               responseText.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("<html") {

                LogService.shared.error("Received HTML response instead of JSON - likely authentication failure")

                // Check for specific P2 private site message
                if responseText.contains("This P2 is private") || responseText.contains("p2020-private") {
                    LogService.shared.error("Detected Private P2 site")
                    throw NSError(
                        domain: "WordPressAPI",
                        code: -1,
                        userInfo: [
                            NSLocalizedDescriptionKey: "This is a Private P2 site. P2 sites don't support Application Password authentication. To post to P2, use email posting instead (configure in Settings > WordPress > Email Settings)."
                        ]
                    )
                }

                // Generic HTML response error
                throw NSError(
                    domain: "WordPressAPI",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "WordPress returned an HTML page instead of API response. This usually means authentication failed or the REST API is not accessible. Check your site URL and credentials."
                    ]
                )
            }

            do {
                let postResponse = try JSONDecoder().decode(WordPressPostResponse.self, from: data)
                LogService.shared.info("Successfully decoded WordPressPostResponse")
                return postResponse
            } catch {
                LogService.shared.error("Failed to decode successful response as WordPressPostResponse")
                LogService.shared.error(error, context: "Decoding WordPressPostResponse")
                LogService.shared.debug("Full response that failed to decode: \(responseText)")

                // Re-throw with more context
                throw NSError(
                    domain: "WordPressAPI",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "WordPress returned unexpected response format. Response: \(responseText.prefix(500))..."
                    ]
                )
            }
        } else if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            LogService.shared.error("Authentication failed (status \(httpResponse.statusCode))")
            throw WordPressError.authenticationFailed
        } else {
            LogService.shared.error("WordPress API error (\(httpResponse.statusCode)): \(responseText)")
            let error = try? JSONDecoder().decode(WordPressErrorResponse.self, from: data)
            throw WordPressError.apiError(
                code: httpResponse.statusCode,
                message: error?.message ?? "Unknown error"
            )
        }
    }

    /// Validate that all required settings are configured
    private func validateSettings() -> Bool {
        let hasURL = !siteURL.isEmpty
        let hasUsername = !username.isEmpty
        let hasPassword = !appPassword.isEmpty

        return hasURL && hasUsername && hasPassword
    }

    /// Show error toast when settings are not configured
    private func showSettingsError() {
        UIStateService.shared.showToast(
            "WordPress not configured. Go to Settings > WordPress.",
            icon: "exclamationmark.triangle"
        )
    }

    /// Parse comma-separated categories from settings
    private func parseCategoriesFromSettings() -> [String] {
        return defaultCategories
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    /// Handle errors during publishing
    private func handleError(_ error: Error) {
        LogService.shared.error(error, context: "WordPress publish failed")

        let message: String
        if let wpError = error as? WordPressError {
            message = wpError.errorDescription ?? "Unknown WordPress error"
        } else if let nsError = error as? NSError {
            // Cast to NSError for detailed logging (domain, code)
            // Use localized description from NSError which includes our custom messages
            message = nsError.localizedDescription
            LogService.shared.error("NSError - domain: \(nsError.domain), code: \(nsError.code)")
        } else if let decodingError = error as? DecodingError {
            LogService.shared.error(decodingError, context: "WordPress JSON Decoding Error")
            message = "WordPress returned unexpected data format. Check logs at ~/Library/Logs/tibok/tibok.log"
        } else {
            message = error.localizedDescription
        }

        LogService.shared.error("Showing error toast: \(message)")
        UIStateService.shared.showToast(
            message,
            icon: "xmark.circle.fill",
            duration: 10.0  // Longer duration for error messages
        )
    }

    // MARK: - Publish Status Tracking

    /// Store publish info for a document
    private func storePublishInfo(documentPath: String, url: String, timestamp: Date) {
        var publishedDocs = UserDefaults.standard.dictionary(forKey: "plugin.wordpress.publishedDocs") as? [String: [String: Any]] ?? [:]
        publishedDocs[documentPath] = [
            "url": url,
            "timestamp": timestamp.timeIntervalSince1970
        ]
        UserDefaults.standard.set(publishedDocs, forKey: "plugin.wordpress.publishedDocs")
    }

    /// Get publish info for a document
    static func getPublishInfo(for documentPath: String) -> (url: String, date: Date)? {
        guard let publishedDocs = UserDefaults.standard.dictionary(forKey: "plugin.wordpress.publishedDocs") as? [String: [String: Any]],
              let info = publishedDocs[documentPath],
              let url = info["url"] as? String,
              let timestamp = info["timestamp"] as? TimeInterval else {
            return nil
        }
        return (url: url, date: Date(timeIntervalSince1970: timestamp))
    }
}
