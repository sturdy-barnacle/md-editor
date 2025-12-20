//
//  ImageUploadService.swift
//  tibok
//
//  Service for handling image uploads to WordPress and path rewriting for static sites
//  Processes HTML/Markdown to replace local image paths with remote URLs
//

import Foundation
import AppKit

@MainActor
final class ImageUploadService {

    // MARK: - Singleton

    static let shared = ImageUploadService()

    private init() {}

    // MARK: - Types

    struct ImageUploadResult {
        let originalPath: String
        let uploadedURL: String?
        let success: Bool
        let error: String?
    }

    // MARK: - WordPress Image Upload

    /// Process HTML images for WordPress - upload local images to Media Library
    func processImagesForWordPress(
        html: String,
        siteURL: String,
        username: String,
        appPassword: String
    ) async -> (processedHTML: String, results: [ImageUploadResult]) {
        var processedHTML = html
        var results: [ImageUploadResult] = []

        // Find all <img> tags using regex
        let pattern = #"<img[^>]+src=["\']([^"\']+)["\'][^>]*>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return (html, [])
        }

        let nsString = html as NSString
        let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))

        // Process matches in reverse order to maintain string indices
        for match in matches.reversed() {
            guard match.numberOfRanges >= 2 else { continue }

            let srcRange = match.range(at: 1)
            let imagePath = nsString.substring(with: srcRange)

            // Skip if already a remote URL
            if imagePath.hasPrefix("http://") || imagePath.hasPrefix("https://") {
                continue
            }

            // Skip data URIs
            if imagePath.hasPrefix("data:") {
                continue
            }

            // Try to upload image
            do {
                let uploadedURL = try await uploadToWordPressMedia(
                    imagePath: imagePath,
                    siteURL: siteURL,
                    username: username,
                    appPassword: appPassword
                )

                // Replace in HTML
                let fullMatchRange = match.range(at: 0)
                let fullMatch = nsString.substring(with: fullMatchRange)
                let replacedMatch = fullMatch.replacingOccurrences(of: imagePath, with: uploadedURL)

                let swiftRange = Range(fullMatchRange, in: processedHTML)!
                processedHTML.replaceSubrange(swiftRange, with: replacedMatch)

                results.append(ImageUploadResult(
                    originalPath: imagePath,
                    uploadedURL: uploadedURL,
                    success: true,
                    error: nil
                ))
            } catch {
                results.append(ImageUploadResult(
                    originalPath: imagePath,
                    uploadedURL: nil,
                    success: false,
                    error: error.localizedDescription
                ))
            }
        }

        return (processedHTML, results)
    }

    /// Process markdown images for static sites - rewrite paths to remote base URL
    func processImagesForStaticSite(
        markdown: String,
        remoteBaseURL: String
    ) async -> (processedMarkdown: String, results: [ImageUploadResult]) {
        var processedMarkdown = markdown
        var results: [ImageUploadResult] = []

        // Ensure remoteBaseURL doesn't end with /
        let baseURL = remoteBaseURL.hasSuffix("/") ? String(remoteBaseURL.dropLast()) : remoteBaseURL

        // Find all markdown image syntax: ![alt](path)
        let pattern = #"!\[([^\]]*)\]\(([^\)]+)\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return (markdown, [])
        }

        let nsString = markdown as NSString
        let matches = regex.matches(in: markdown, options: [], range: NSRange(location: 0, length: nsString.length))

        // Process matches in reverse order to maintain string indices
        for match in matches.reversed() {
            guard match.numberOfRanges >= 3 else { continue }

            let pathRange = match.range(at: 2)
            let imagePath = nsString.substring(with: pathRange)

            // Skip if already a remote URL
            if imagePath.hasPrefix("http://") || imagePath.hasPrefix("https://") {
                continue
            }

            // Extract filename from path
            let filename = (imagePath as NSString).lastPathComponent

            // Build remote URL
            let remoteURL = "\(baseURL)/assets/\(filename)"

            // Replace in markdown
            let fullMatchRange = match.range(at: 0)
            let fullMatch = nsString.substring(with: fullMatchRange)
            let replacedMatch = fullMatch.replacingOccurrences(of: imagePath, with: remoteURL)

            let swiftRange = Range(fullMatchRange, in: processedMarkdown)!
            processedMarkdown.replaceSubrange(swiftRange, with: replacedMatch)

            results.append(ImageUploadResult(
                originalPath: imagePath,
                uploadedURL: remoteURL,
                success: true,
                error: nil
            ))
        }

        return (processedMarkdown, results)
    }

    // MARK: - Private Methods

    /// Upload single image to WordPress Media API
    private func uploadToWordPressMedia(
        imagePath: String,
        siteURL: String,
        username: String,
        appPassword: String
    ) async throws -> String {
        // Resolve file path
        let fileURL = try resolveImagePath(imagePath)

        // Read image data
        guard let imageData = try? Data(contentsOf: fileURL) else {
            throw ImageUploadError.fileNotFound(imagePath)
        }

        // Check file size (warn if > 10MB)
        let fileSizeMB = Double(imageData.count) / 1_048_576
        if fileSizeMB > 10 {
            throw ImageUploadError.fileTooLarge(fileSizeMB)
        }

        // Validate file format
        let mimeType = try detectMimeType(from: fileURL)

        // Build endpoint URL
        let endpoint = "\(siteURL)/wp-json/wp/v2/media"
        guard let url = URL(string: endpoint) else {
            throw ImageUploadError.invalidURL
        }

        // Build request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Add Basic Auth
        let credentials = "\(username):\(appPassword)"
        guard let credentialsData = credentials.data(using: .utf8) else {
            throw ImageUploadError.authenticationFailed
        }
        let base64Credentials = credentialsData.base64EncodedString()
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")

        // Set content type and disposition
        request.setValue(mimeType, forHTTPHeaderField: "Content-Type")
        request.setValue("attachment; filename=\"\(fileURL.lastPathComponent)\"", forHTTPHeaderField: "Content-Disposition")

        // Set body as raw image data
        request.httpBody = imageData

        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Handle response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ImageUploadError.invalidResponse
        }

        if (200...299).contains(httpResponse.statusCode) {
            // Parse response to get source_url
            struct MediaResponse: Codable {
                let source_url: String
            }

            let mediaResponse = try JSONDecoder().decode(MediaResponse.self, from: data)
            return mediaResponse.source_url
        } else if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw ImageUploadError.authenticationFailed
        } else {
            throw ImageUploadError.uploadFailed(httpResponse.statusCode)
        }
    }

    /// Resolve image path to file URL
    private func resolveImagePath(_ path: String) throws -> URL {
        // Remove leading ./
        var cleanPath = path
        if cleanPath.hasPrefix("./") {
            cleanPath = String(cleanPath.dropFirst(2))
        }

        // Build absolute URL and standardize it
        let absoluteURL: URL
        if path.hasPrefix("/") {
            // Already absolute path
            absoluteURL = URL(fileURLWithPath: path).standardizedFileURL
        } else {
            // Try relative to current directory
            let currentDirectory = FileManager.default.currentDirectoryPath
            absoluteURL = URL(fileURLWithPath: currentDirectory)
                .appendingPathComponent(cleanPath)
                .standardizedFileURL
        }

        // Define allowed directories (security sandbox)
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let allowedDirs = [
            homeDir.appendingPathComponent("Downloads").path,
            homeDir.appendingPathComponent("Pictures").path,
            homeDir.appendingPathComponent("Documents").path,
            homeDir.appendingPathComponent("Desktop").path
        ]

        // Validate path is within allowed directories
        let absolutePath = absoluteURL.path
        guard allowedDirs.contains(where: { absolutePath.hasPrefix($0) }) else {
            NSLog("⚠️ ImageUpload: Blocked upload attempt from restricted path: \(absolutePath)")
            throw ImageUploadError.fileNotFound(path)
        }

        // Verify file exists
        guard FileManager.default.fileExists(atPath: absolutePath) else {
            throw ImageUploadError.fileNotFound(path)
        }

        return absoluteURL
    }

    /// Detect MIME type from file extension
    private func detectMimeType(from url: URL) throws -> String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "png":
            return "image/png"
        case "jpg", "jpeg":
            return "image/jpeg"
        case "gif":
            return "image/gif"
        case "webp":
            return "image/webp"
        case "svg":
            return "image/svg+xml"
        default:
            throw ImageUploadError.unsupportedFormat(ext)
        }
    }
}

// MARK: - Errors

enum ImageUploadError: LocalizedError {
    case fileNotFound(String)
    case fileTooLarge(Double)
    case unsupportedFormat(String)
    case invalidURL
    case authenticationFailed
    case invalidResponse
    case uploadFailed(Int)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "Image file not found: \(path)"
        case .fileTooLarge(let sizeMB):
            return String(format: "Image too large: %.1f MB (max 10 MB)", sizeMB)
        case .unsupportedFormat(let ext):
            return "Unsupported image format: .\(ext)"
        case .invalidURL:
            return "Invalid WordPress site URL"
        case .authenticationFailed:
            return "Authentication failed. Check credentials."
        case .invalidResponse:
            return "Invalid response from WordPress"
        case .uploadFailed(let code):
            return "Upload failed with status code: \(code)"
        }
    }
}
