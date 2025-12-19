//
//  WordPressModels.swift
//  tibok
//
//  Data structures for WordPress REST API v2 integration
//

import Foundation

// MARK: - Request Models

/// Request body for creating a WordPress post
struct WordPressPostRequest: Codable {
    let title: String
    let content: String
    let status: String
    let categories: [Int]?
    let excerpt: String?
    let tags: [Int]?
    let author: String?

    enum CodingKeys: String, CodingKey {
        case title
        case content
        case status
        case categories
        case excerpt
        case tags
        case author
    }
}

// MARK: - Response Models

/// Response from WordPress API after creating a post
struct WordPressPostResponse: Codable {
    let id: Int
    let link: String
    let status: String
    let title: RenderedContent

    struct RenderedContent: Codable {
        let rendered: String
    }
}

/// Error response from WordPress API
struct WordPressErrorResponse: Codable {
    let code: String
    let message: String
}

// MARK: - Category/Tag Models

/// WordPress category or tag (taxonomy term)
struct WordPressTerm: Codable {
    let id: Int
    let name: String
    let slug: String
}

// MARK: - Post Status

/// WordPress post status options
enum WordPressPostStatus: String, CaseIterable, Identifiable {
    case draft = "draft"
    case publish = "publish"
    case pending = "pending"
    case `private` = "private"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .draft:
            return "Draft"
        case .publish:
            return "Publish"
        case .pending:
            return "Pending Review"
        case .private:
            return "Private"
        }
    }
}

// MARK: - Errors

/// Errors that can occur during WordPress operations
enum WordPressError: LocalizedError {
    case notConfigured
    case invalidURL
    case invalidResponse
    case authenticationFailed
    case apiError(code: Int, message: String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "WordPress not configured. Go to Settings > WordPress."
        case .invalidURL:
            return "Invalid WordPress site URL"
        case .invalidResponse:
            return "Invalid response from WordPress"
        case .authenticationFailed:
            return "Authentication failed. Check username and password."
        case .apiError(let code, let message):
            return "WordPress error (\(code)): \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Connection Test Result

/// Result from testing a WordPress connection
struct ConnectionTestResult {
    let success: Bool
    let message: String
    let siteName: String?
}

// MARK: - Multi-Blog Support (WordPress.com)

/// WordPress.com site/blog information
struct WordPressSite: Codable, Identifiable {
    let id: Int
    let name: String
    let url: String
    let icon: WordPressSiteIcon?

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case name
        case url = "URL"
        case icon
    }

    var displayName: String {
        // Clean URL for display (remove https://, www., trailing slash)
        var display = url
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "www.", with: "")

        if display.hasSuffix("/") {
            display = String(display.dropLast())
        }

        return display
    }
}

/// WordPress.com site icon
struct WordPressSiteIcon: Codable {
    let img: String?
}

/// Response from WordPress.com sites discovery API
struct WordPressSitesResponse: Codable {
    let sites: [WordPressSite]
}

/// Result from blog discovery
enum DiscoveryResult {
    case success(count: Int)
    case notWordPressCom
    case authenticationFailed
    case networkError(String)
}
