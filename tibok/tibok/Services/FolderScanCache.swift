//
//  FolderScanCache.swift
//  tibok
//
//  Caches results of folder scans to determine if folders contain markdown files.
//  Provides instant lookups and persistent storage across app launches.
//

import Foundation

class FolderScanCache {
    static let shared = FolderScanCache()

    private var cache: [String: FolderScanResult] = [:]
    private let cacheKey = "folderScanCache"
    private let maxCacheSize = 10000  // Prevent unbounded growth
    private let cacheLock = NSLock()

    struct FolderScanResult: Codable {
        let containsMarkdown: Bool
        let scannedAt: Date
        let depth: Int  // How deep we scanned (for future depth limiting)

        var isExpired: Bool {
            // Cache expires after 1 hour
            Date().timeIntervalSince(scannedAt) > 3600
        }
    }

    private init() {
        loadCache()
    }

    // MARK: - Cache Operations

    /// Check if a folder contains markdown files (from cache)
    func containsMarkdown(at url: URL) -> Bool? {
        cacheLock.lock()
        defer { cacheLock.unlock() }

        let key = url.path
        guard let result = cache[key], !result.isExpired else {
            return nil  // Not in cache or expired
        }
        return result.containsMarkdown
    }

    /// Store scan result for a folder
    func storeResult(url: URL, containsMarkdown: Bool, depth: Int = 0) {
        cacheLock.lock()
        defer { cacheLock.unlock() }

        let key = url.path
        cache[key] = FolderScanResult(
            containsMarkdown: containsMarkdown,
            scannedAt: Date(),
            depth: depth
        )

        // Trim cache if too large
        if cache.count > maxCacheSize {
            trimCache()
        }

        saveCache()
    }

    /// Clear cache for a specific folder and its children
    func invalidate(url: URL) {
        cacheLock.lock()
        defer { cacheLock.unlock() }

        let prefix = url.path
        cache = cache.filter { !$0.key.hasPrefix(prefix) }
        saveCache()
    }

    /// Clear entire cache
    func clearAll() {
        cacheLock.lock()
        defer { cacheLock.unlock() }

        cache.removeAll()
        saveCache()
    }

    // MARK: - Scanning

    /// Scan a folder to check if it contains markdown files (with depth limit)
    nonisolated func scanFolder(at url: URL, maxDepth: Int = 3) async -> Bool {
        // Check cache first
        if let cached = Self.shared.containsMarkdown(at: url) {
            return cached
        }

        // Perform scan in background
        let result = scanFolderRecursive(url: url, currentDepth: 0, maxDepth: maxDepth)
        Self.shared.storeResult(url: url, containsMarkdown: result, depth: maxDepth)
        return result
    }

    private nonisolated func scanFolderRecursive(url: URL, currentDepth: Int, maxDepth: Int) -> Bool {
        // Depth limit reached - assume contains markdown to avoid filtering
        if currentDepth > maxDepth {
            return true
        }

        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return false
        }

        // Skip common non-documentation directories
        let skipDirs = ["node_modules", ".build", "build", "dist", "target",
                       "Pods", ".git", ".svn", ".hg", "vendor", "__pycache__",
                       ".venv", "venv", ".next", ".nuxt", "coverage", "tmp"]

        var filesChecked = 0
        let maxFilesToCheck = 1000  // Safety limit

        for case let fileURL as URL in enumerator {
            filesChecked += 1
            if filesChecked > maxFilesToCheck {
                return true  // Too many files, assume contains markdown
            }

            // Check if we should skip this directory
            let lastComponent = fileURL.lastPathComponent
            if skipDirs.contains(lastComponent) {
                enumerator.skipDescendants()
                continue
            }

            // Found a markdown file!
            if fileURL.pathExtension == "md" {
                return true
            }
        }

        return false
    }

    // MARK: - Persistence

    private func loadCache() {
        // Called only from init, no lock needed
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let decoded = try? JSONDecoder().decode([String: FolderScanResult].self, from: data) else {
            return
        }

        // Filter out expired entries
        cache = decoded.filter { !$0.value.isExpired }
    }

    private func saveCache() {
        // Must be called with lock held
        guard let data = try? JSONEncoder().encode(cache) else { return }
        UserDefaults.standard.set(data, forKey: cacheKey)
    }

    private func trimCache() {
        // Must be called with lock held
        // Remove oldest entries first
        let sorted = cache.sorted { $0.value.scannedAt < $1.value.scannedAt }
        let toKeep = sorted.suffix(maxCacheSize * 3 / 4)  // Keep 75%
        cache = Dictionary(uniqueKeysWithValues: toKeep.map { ($0.key, $0.value) })
    }

    // MARK: - Debug

    func getCacheStats() -> (size: Int, expired: Int) {
        cacheLock.lock()
        defer { cacheLock.unlock() }

        let expired = cache.values.filter { $0.isExpired }.count
        return (cache.count, expired)
    }
}
