//
//  FrontmatterCacheService.swift
//  tibok
//
//  Service for efficiently checking if markdown files have frontmatter
//  Uses file modification date validation for cache invalidation
//

import Foundation

@MainActor
final class FrontmatterCacheService {

    // MARK: - Singleton

    static let shared = FrontmatterCacheService()

    private init() {}

    // MARK: - Cache Entry

    private struct CacheEntry {
        let hasFrontmatter: Bool
        let lastModified: Date
    }

    // MARK: - Cache Storage

    private var cache: [String: CacheEntry] = [:]

    // MARK: - Public Methods

    /// Check if a file has frontmatter (YAML or TOML)
    /// - Parameter url: File URL to check
    /// - Returns: True if file has valid frontmatter delimiters
    func hasFrontmatter(url: URL) -> Bool {
        let path = url.path

        // Get file modification date
        guard let modificationDate = getFileModificationDate(url: url) else {
            // File doesn't exist or can't be accessed
            return false
        }

        // Check cache validity
        if let entry = cache[path] {
            // Cache hit - validate modification date
            if entry.lastModified == modificationDate {
                return entry.hasFrontmatter
            }
            // Cache stale, will reparse
        }

        // Parse file to detect frontmatter
        let result = detectFrontmatter(url: url)

        // Store in cache
        cache[path] = CacheEntry(
            hasFrontmatter: result,
            lastModified: modificationDate
        )

        return result
    }

    /// Invalidate cache entry for a specific file
    /// - Parameter url: File URL to invalidate
    func invalidate(url: URL) {
        let path = url.path
        cache.removeValue(forKey: path)
    }

    /// Clear entire cache
    func clearCache() {
        cache.removeAll()
    }

    // MARK: - Private Methods

    /// Get file modification date
    private func getFileModificationDate(url: URL) -> Date? {
        let fileManager = FileManager.default
        guard let attributes = try? fileManager.attributesOfItem(atPath: url.path),
              let modificationDate = attributes[.modificationDate] as? Date else {
            return nil
        }
        return modificationDate
    }

    /// Detect frontmatter by parsing first 200 bytes
    /// Supports both YAML (---) and TOML (+++) delimiters
    private func detectFrontmatter(url: URL) -> Bool {
        guard let fileHandle = try? FileHandle(forReadingFrom: url) else {
            return false
        }

        defer {
            try? fileHandle.close()
        }

        // Read first 200 bytes for performance
        guard let data = try? fileHandle.read(upToCount: 200),
              let content = String(data: data, encoding: .utf8) else {
            return false
        }

        // Check for YAML frontmatter (---)
        if content.hasPrefix("---\n") || content.hasPrefix("---\r\n") {
            // Look for closing delimiter
            let lines = content.components(separatedBy: .newlines)
            if lines.count >= 2 {
                // Check if there's a closing --- after the first line
                for i in 1..<lines.count {
                    let trimmed = lines[i].trimmingCharacters(in: .whitespaces)
                    if trimmed == "---" {
                        return true
                    }
                }
            }
        }

        // Check for TOML frontmatter (+++)
        if content.hasPrefix("+++\n") || content.hasPrefix("+++\r\n") {
            // Look for closing delimiter
            let lines = content.components(separatedBy: .newlines)
            if lines.count >= 2 {
                // Check if there's a closing +++ after the first line
                for i in 1..<lines.count {
                    let trimmed = lines[i].trimmingCharacters(in: .whitespaces)
                    if trimmed == "+++" {
                        return true
                    }
                }
            }
        }

        return false
    }
}
