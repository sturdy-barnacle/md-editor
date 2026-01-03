//
//  RegistryClient.swift
//  tibok
//
//  Client for fetching plugin registry from the marketplace.
//
//  MIT License - See LICENSE file in Plugins directory
//

import Foundation

/// Client for fetching and parsing the plugin registry from the marketplace.
@MainActor
final class RegistryClient: ObservableObject {
    static let shared = RegistryClient()

    /// Default registry URL (can be overridden for testing or custom registries)
    static let defaultRegistryURL = URL(string: "https://plugins.tibok.app/api/v1/registry.json")!

    /// Current registry URL
    var registryURL: URL

    /// Last fetch timestamp
    @Published private(set) var lastFetched: Date?

    /// Whether a fetch is in progress
    @Published private(set) var isFetching = false

    /// Last error encountered
    @Published private(set) var lastError: RegistryError?

    /// Cache duration (1 hour)
    private let cacheDuration: TimeInterval = 3600

    /// Cached registry data
    private var cachedRegistry: PluginRegistryData?

    /// URL session for network requests
    private let session: URLSession

    private init() {
        self.registryURL = Self.defaultRegistryURL

        // Configure URL session with reasonable timeouts
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: config)
    }

    // MARK: - Configuration

    /// Set a custom registry URL (for testing or alternative registries)
    func setRegistryURL(_ url: URL) {
        self.registryURL = url
        self.cachedRegistry = nil
        self.lastFetched = nil
    }

    /// Reset to default registry URL
    func resetToDefaultRegistry() {
        setRegistryURL(Self.defaultRegistryURL)
    }

    // MARK: - Fetching

    /// Fetch the plugin registry, using cache if available and fresh
    func fetchRegistry(forceRefresh: Bool = false) async throws -> PluginRegistryData {
        // Return cached if fresh and not forcing refresh
        if !forceRefresh, let cached = cachedRegistry, let lastFetched = lastFetched {
            let age = Date().timeIntervalSince(lastFetched)
            if age < cacheDuration {
                return cached
            }
        }

        // Fetch from network
        isFetching = true
        lastError = nil

        defer {
            isFetching = false
        }

        do {
            let registry = try await fetchFromNetwork()
            cachedRegistry = registry
            lastFetched = Date()
            return registry
        } catch {
            let registryError = error as? RegistryError ?? .networkError(error)
            lastError = registryError
            throw registryError
        }
    }

    /// Fetch registry from network
    private func fetchFromNetwork() async throws -> PluginRegistryData {
        let (data, response) = try await session.data(from: registryURL)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw RegistryError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw RegistryError.httpError(statusCode: httpResponse.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let registry = try decoder.decode(PluginRegistryData.self, from: data)

            // Validate registry signature if present
            if let signature = registry.registrySignature {
                try validateRegistrySignature(data: data, signature: signature)
            }

            return registry
        } catch let error as DecodingError {
            throw RegistryError.parseError(error)
        }
    }

    /// Validate the registry's cryptographic signature
    private func validateRegistrySignature(data: Data, signature: String) throws {
        // For now, just verify the signature format is valid
        // Full verification will be implemented when signing infrastructure is ready
        guard !signature.isEmpty else {
            throw RegistryError.invalidSignature("Empty signature")
        }

        // TODO: Implement full Ed25519 signature verification
        // let verifier = SignatureVerifier.shared
        // try verifier.verifyRegistrySignature(data: data, signature: signature)
    }

    // MARK: - Search

    /// Search plugins by query
    func searchPlugins(query: String, in registry: PluginRegistryData) -> [RegistryPlugin] {
        guard !query.isEmpty else {
            return registry.plugins
        }

        let lowercaseQuery = query.lowercased()

        return registry.plugins.filter { plugin in
            plugin.name.lowercased().contains(lowercaseQuery) ||
            plugin.identifier.lowercased().contains(lowercaseQuery) ||
            (plugin.description?.lowercased().contains(lowercaseQuery) ?? false) ||
            plugin.keywords.contains { $0.lowercased().contains(lowercaseQuery) }
        }
    }

    /// Filter plugins by trust tier
    func filterByTier(_ tier: PluginTrustTier, in registry: PluginRegistryData) -> [RegistryPlugin] {
        registry.plugins.filter { $0.trustTier == tier }
    }

    /// Filter plugins by type
    func filterByType(_ type: PluginType, in registry: PluginRegistryData) -> [RegistryPlugin] {
        registry.plugins.filter { $0.pluginType == type }
    }

    // MARK: - Cache Management

    /// Clear the cached registry
    func clearCache() {
        cachedRegistry = nil
        lastFetched = nil
    }

    /// Check if cache is stale
    var isCacheStale: Bool {
        guard let lastFetched = lastFetched else { return true }
        return Date().timeIntervalSince(lastFetched) >= cacheDuration
    }
}

// MARK: - Registry Data Models

/// The root registry data structure
struct PluginRegistryData: Codable {
    /// Registry format version
    let version: String

    /// When the registry was generated
    let generatedAt: Date

    /// Cryptographic signature of the registry
    let registrySignature: String?

    /// All available plugins
    let plugins: [RegistryPlugin]

    /// Featured plugin IDs (for homepage)
    let featured: [String]?

    /// Categories for browsing
    let categories: [PluginCategory]?

    enum CodingKeys: String, CodingKey {
        case version
        case generatedAt = "generated_at"
        case registrySignature = "registry_signature"
        case plugins
        case featured
        case categories
    }
}

/// A plugin entry in the registry
struct RegistryPlugin: Codable, Identifiable {
    var id: String { identifier }

    /// Unique plugin identifier
    let identifier: String

    /// Display name
    let name: String

    /// Plugin version
    let version: String

    /// Description
    let description: String?

    /// SF Symbol icon
    let icon: String?

    /// Author name
    let author: String?

    /// Plugin type
    let pluginType: PluginType

    /// Trust tier
    let trustTier: PluginTrustTier

    /// Required permissions
    let permissions: [String]

    /// Download count
    let downloads: Int?

    /// Average rating (1-5)
    let rating: Double?

    /// Number of ratings
    let ratingCount: Int?

    /// Minimum required Tibok version
    let minimumTibokVersion: String?

    /// Download URL for the plugin bundle
    let downloadURL: String

    /// Size in bytes
    let size: Int?

    /// Homepage URL
    let homepage: String?

    /// Repository URL
    let repository: String?

    /// License identifier
    let license: String?

    /// Discovery keywords
    let keywords: [String]

    /// Plugin signature (for verified plugins)
    let signature: PluginSignature?

    /// When the plugin was last updated
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case identifier
        case name
        case version
        case description
        case icon
        case author
        case pluginType = "plugin_type"
        case trustTier = "trust_tier"
        case permissions
        case downloads
        case rating
        case ratingCount = "rating_count"
        case minimumTibokVersion = "minimum_tibok_version"
        case downloadURL = "download_url"
        case size
        case homepage
        case repository
        case license
        case keywords
        case signature
        case updatedAt = "updated_at"
    }

    /// Parse permissions to PluginPermission enum
    var parsedPermissions: [PluginPermission] {
        permissions.compactMap { PluginPermission(rawValue: $0) }
    }

    /// Get the permission set
    var permissionSet: PluginPermissionSet {
        PluginPermissionSet(parsedPermissions)
    }
}

/// A category for browsing plugins
struct PluginCategory: Codable, Identifiable {
    var id: String { slug }

    /// URL-safe slug
    let slug: String

    /// Display name
    let name: String

    /// Description
    let description: String?

    /// SF Symbol icon
    let icon: String?

    /// Number of plugins in this category
    let count: Int?
}

// MARK: - Registry Errors

/// Errors that can occur when fetching the registry
enum RegistryError: LocalizedError {
    case networkError(Error)
    case httpError(statusCode: Int)
    case invalidResponse
    case parseError(Error)
    case invalidSignature(String)
    case registryUnavailable

    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .httpError(let statusCode):
            return "Server returned status \(statusCode)"
        case .invalidResponse:
            return "Invalid response from server"
        case .parseError(let error):
            return "Failed to parse registry: \(error.localizedDescription)"
        case .invalidSignature(let reason):
            return "Invalid registry signature: \(reason)"
        case .registryUnavailable:
            return "Plugin registry is currently unavailable"
        }
    }
}
