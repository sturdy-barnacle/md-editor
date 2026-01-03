//
//  PluginDownloader.swift
//  tibok
//
//  Downloads and installs plugins from the registry.
//
//  MIT License - See LICENSE file in Plugins directory
//

import Foundation

/// Downloads, verifies, and installs plugins from the registry.
@MainActor
final class PluginDownloader: ObservableObject {
    static let shared = PluginDownloader()

    /// Active downloads
    @Published private(set) var activeDownloads: [String: DownloadProgress] = [:]

    /// URL session for downloads
    private let session: URLSession

    /// Temporary download directory
    private let tempDirectory: URL

    private init() {
        // Configure URL session for downloads
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300  // 5 minutes for large plugins
        self.session = URLSession(configuration: config)

        // Set up temp directory
        self.tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("tibok-plugin-downloads")

        // Ensure temp directory exists
        try? FileManager.default.createDirectory(
            at: tempDirectory,
            withIntermediateDirectories: true
        )
    }

    // MARK: - Download

    /// Download and install a plugin from the registry
    func downloadAndInstall(plugin: RegistryPlugin) async throws -> URL {
        let identifier = plugin.identifier

        // Check if already downloading
        guard activeDownloads[identifier] == nil else {
            throw DownloadError.alreadyDownloading(identifier)
        }

        // Initialize progress
        activeDownloads[identifier] = DownloadProgress(
            identifier: identifier,
            name: plugin.name,
            status: .downloading,
            progress: 0
        )

        defer {
            activeDownloads.removeValue(forKey: identifier)
        }

        do {
            // Download the plugin bundle
            guard let downloadURL = URL(string: plugin.downloadURL) else {
                throw DownloadError.invalidURL(plugin.downloadURL)
            }

            let localURL = try await downloadFile(
                from: downloadURL,
                identifier: identifier,
                expectedSize: plugin.size
            )

            // Update progress
            updateProgress(identifier: identifier, status: .verifying)

            // Verify the download
            try await verifyDownload(
                localURL: localURL,
                plugin: plugin
            )

            // Update progress
            updateProgress(identifier: identifier, status: .installing)

            // Install the plugin
            let installURL = try await installPlugin(
                from: localURL,
                plugin: plugin
            )

            // Update progress
            updateProgress(identifier: identifier, status: .completed)

            // Clean up temp file
            try? FileManager.default.removeItem(at: localURL)

            return installURL

        } catch {
            updateProgress(identifier: identifier, status: .failed(error))
            throw error
        }
    }

    /// Download a file with progress tracking
    private func downloadFile(
        from url: URL,
        identifier: String,
        expectedSize: Int?
    ) async throws -> URL {
        let (asyncBytes, response) = try await session.bytes(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DownloadError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw DownloadError.httpError(statusCode: httpResponse.statusCode)
        }

        let totalSize = expectedSize ?? Int(httpResponse.expectedContentLength)
        let destURL = tempDirectory.appendingPathComponent("\(identifier).zip")

        // Remove existing temp file if present
        try? FileManager.default.removeItem(at: destURL)

        // Create output file
        FileManager.default.createFile(atPath: destURL.path, contents: nil)
        let fileHandle = try FileHandle(forWritingTo: destURL)

        defer {
            try? fileHandle.close()
        }

        var downloadedBytes = 0

        for try await byte in asyncBytes {
            try fileHandle.write(contentsOf: [byte])
            downloadedBytes += 1

            // Update progress periodically (every 10KB)
            if downloadedBytes % 10240 == 0 {
                let progress = totalSize > 0 ? Double(downloadedBytes) / Double(totalSize) : 0
                updateProgress(identifier: identifier, progress: progress)
            }
        }

        // Final progress update
        updateProgress(identifier: identifier, progress: 1.0)

        return destURL
    }

    /// Verify a downloaded plugin
    private func verifyDownload(localURL: URL, plugin: RegistryPlugin) async throws {
        // Check file exists
        guard FileManager.default.fileExists(atPath: localURL.path) else {
            throw DownloadError.fileNotFound
        }

        // Check file size if expected
        if let expectedSize = plugin.size {
            let attrs = try FileManager.default.attributesOfItem(atPath: localURL.path)
            let actualSize = attrs[.size] as? Int ?? 0

            // Allow 5% variance for compression differences
            let variance = Double(expectedSize) * 0.05
            guard abs(Double(actualSize - expectedSize)) <= variance else {
                throw DownloadError.sizeMismatch(expected: expectedSize, actual: actualSize)
            }
        }

        // Verify signature for verified plugins
        if plugin.trustTier == .verified {
            guard let signature = plugin.signature else {
                throw DownloadError.missingSignature
            }

            let data = try Data(contentsOf: localURL)

            // Create a temporary manifest for verification
            let manifest = PluginManifest(
                identifier: plugin.identifier,
                name: plugin.name,
                version: plugin.version,
                description: plugin.description,
                icon: plugin.icon,
                author: plugin.author,
                authorInfo: nil,
                minimumTibokVersion: plugin.minimumTibokVersion,
                pluginType: plugin.pluginType,
                permissions: plugin.permissions,
                trustTier: plugin.trustTier,
                signature: signature,
                capabilities: nil,
                entryPoint: nil,
                configSchema: nil,
                homepage: plugin.homepage,
                repository: plugin.repository,
                license: plugin.license,
                keywords: plugin.keywords
            )

            let verifier = SignatureVerifier.shared
            let result = verifier.verify(manifest: manifest, bundleData: data)

            guard result.isValid else {
                throw DownloadError.signatureVerificationFailed(result.localizedDescription)
            }
        }
    }

    /// Install a downloaded plugin to the plugins directory
    private func installPlugin(from localURL: URL, plugin: RegistryPlugin) async throws -> URL {
        let destDir = PluginDiscovery.Folders.thirdParty
            .appendingPathComponent(plugin.identifier)

        // Remove existing installation if present
        if FileManager.default.fileExists(atPath: destDir.path) {
            try FileManager.default.removeItem(at: destDir)
        }

        // Create destination directory
        try FileManager.default.createDirectory(
            at: destDir,
            withIntermediateDirectories: true
        )

        // Unzip the plugin
        try await unzip(from: localURL, to: destDir)

        // Verify the installation
        let (isValid, errors) = PluginDiscovery.verifyPluginStructure(at: destDir)
        guard isValid else {
            // Clean up failed installation
            try? FileManager.default.removeItem(at: destDir)
            throw DownloadError.invalidPluginStructure(errors)
        }

        return destDir
    }

    /// Unzip a file to a directory
    private func unzip(from source: URL, to destination: URL) async throws {
        // Use Process to run unzip command
        // This is safe since we control the paths
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-q", "-o", source.path, "-d", destination.path]

        let pipe = Pipe()
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw DownloadError.unzipFailed(errorMessage)
        }
    }

    // MARK: - Progress Updates

    private func updateProgress(identifier: String, status: DownloadStatus? = nil, progress: Double? = nil) {
        guard var download = activeDownloads[identifier] else { return }

        if let status = status {
            download.status = status
        }
        if let progress = progress {
            download.progress = progress
        }

        activeDownloads[identifier] = download
    }

    // MARK: - Cancellation

    /// Cancel an active download
    func cancelDownload(_ identifier: String) {
        activeDownloads.removeValue(forKey: identifier)
        // Note: URLSession tasks would need to be tracked and cancelled for true cancellation
    }

    /// Cancel all active downloads
    func cancelAllDownloads() {
        activeDownloads.removeAll()
    }

    // MARK: - Cleanup

    /// Clean up temporary download files
    func cleanupTempFiles() {
        try? FileManager.default.removeItem(at: tempDirectory)
        try? FileManager.default.createDirectory(
            at: tempDirectory,
            withIntermediateDirectories: true
        )
    }
}

// MARK: - Download Progress

/// Progress information for an active download
struct DownloadProgress: Identifiable {
    var id: String { identifier }

    let identifier: String
    let name: String
    var status: DownloadStatus
    var progress: Double  // 0.0 to 1.0
}

/// Status of a download
enum DownloadStatus: Equatable {
    case downloading
    case verifying
    case installing
    case completed
    case failed(Error)

    static func == (lhs: DownloadStatus, rhs: DownloadStatus) -> Bool {
        switch (lhs, rhs) {
        case (.downloading, .downloading),
             (.verifying, .verifying),
             (.installing, .installing),
             (.completed, .completed):
            return true
        case (.failed, .failed):
            return true  // Don't compare error details
        default:
            return false
        }
    }

    var displayName: String {
        switch self {
        case .downloading: return "Downloading..."
        case .verifying: return "Verifying..."
        case .installing: return "Installing..."
        case .completed: return "Completed"
        case .failed: return "Failed"
        }
    }

    var isComplete: Bool {
        switch self {
        case .completed, .failed: return true
        default: return false
        }
    }
}

// MARK: - Download Errors

/// Errors that can occur during download
enum DownloadError: LocalizedError {
    case alreadyDownloading(String)
    case invalidURL(String)
    case invalidResponse
    case httpError(statusCode: Int)
    case fileNotFound
    case sizeMismatch(expected: Int, actual: Int)
    case missingSignature
    case signatureVerificationFailed(String)
    case invalidPluginStructure([String])
    case unzipFailed(String)
    case installationFailed(String)

    var errorDescription: String? {
        switch self {
        case .alreadyDownloading(let id):
            return "Plugin '\(id)' is already being downloaded"
        case .invalidURL(let url):
            return "Invalid download URL: \(url)"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "Server returned status \(statusCode)"
        case .fileNotFound:
            return "Downloaded file not found"
        case .sizeMismatch(let expected, let actual):
            return "File size mismatch (expected \(expected), got \(actual))"
        case .missingSignature:
            return "Verified plugin is missing signature"
        case .signatureVerificationFailed(let reason):
            return "Signature verification failed: \(reason)"
        case .invalidPluginStructure(let errors):
            return "Invalid plugin structure: \(errors.joined(separator: ", "))"
        case .unzipFailed(let message):
            return "Failed to extract plugin: \(message)"
        case .installationFailed(let message):
            return "Installation failed: \(message)"
        }
    }
}
