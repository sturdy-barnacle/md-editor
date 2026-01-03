//
//  PluginRegistry.swift
//  tibok
//
//  In-memory cache and coordinator for plugin registry operations.
//
//  MIT License - See LICENSE file in Plugins directory
//

import Foundation

/// Coordinates plugin registry operations and maintains in-memory cache.
@MainActor
final class PluginRegistry: ObservableObject {
    static let shared = PluginRegistry()

    // MARK: - Published State

    /// All available plugins from registry
    @Published private(set) var availablePlugins: [RegistryPlugin] = []

    /// Featured plugin identifiers
    @Published private(set) var featuredPluginIds: [String] = []

    /// Categories for browsing
    @Published private(set) var categories: [PluginCategory] = []

    /// Whether the registry is currently loading
    @Published private(set) var isLoading = false

    /// Last error encountered
    @Published private(set) var lastError: Error?

    /// When the registry was last refreshed
    @Published private(set) var lastRefreshed: Date?

    // MARK: - Dependencies

    private let client = RegistryClient.shared
    private let downloader = PluginDownloader.shared
    private let permissionValidator = PermissionValidator.shared

    private init() {}

    // MARK: - Loading

    /// Load or refresh the plugin registry
    func loadRegistry(forceRefresh: Bool = false) async {
        guard !isLoading else { return }

        isLoading = true
        lastError = nil

        do {
            let registryData = try await client.fetchRegistry(forceRefresh: forceRefresh)

            availablePlugins = registryData.plugins
            featuredPluginIds = registryData.featured ?? []
            categories = registryData.categories ?? []
            lastRefreshed = Date()

        } catch {
            lastError = error
            print("Failed to load plugin registry: \(error)")
        }

        isLoading = false
    }

    /// Refresh the registry in the background
    func refreshInBackground() {
        Task {
            await loadRegistry(forceRefresh: true)
        }
    }

    // MARK: - Querying

    /// Get a plugin by identifier
    func plugin(withId identifier: String) -> RegistryPlugin? {
        availablePlugins.first { $0.identifier == identifier }
    }

    /// Get featured plugins
    var featuredPlugins: [RegistryPlugin] {
        featuredPluginIds.compactMap { id in
            availablePlugins.first { $0.identifier == id }
        }
    }

    /// Search plugins
    func search(query: String) -> [RegistryPlugin] {
        guard !query.isEmpty else { return availablePlugins }

        let lowercaseQuery = query.lowercased()

        return availablePlugins.filter { plugin in
            plugin.name.lowercased().contains(lowercaseQuery) ||
            plugin.identifier.lowercased().contains(lowercaseQuery) ||
            (plugin.description?.lowercased().contains(lowercaseQuery) ?? false) ||
            plugin.keywords.contains { $0.lowercased().contains(lowercaseQuery) }
        }.sorted { lhs, rhs in
            // Sort by relevance (name match > description match > keyword match)
            let lhsNameMatch = lhs.name.lowercased().contains(lowercaseQuery)
            let rhsNameMatch = rhs.name.lowercased().contains(lowercaseQuery)

            if lhsNameMatch && !rhsNameMatch { return true }
            if !lhsNameMatch && rhsNameMatch { return false }

            // Secondary sort by downloads
            return (lhs.downloads ?? 0) > (rhs.downloads ?? 0)
        }
    }

    /// Filter plugins by category
    func plugins(inCategory category: String) -> [RegistryPlugin] {
        availablePlugins.filter { $0.keywords.contains(category) }
    }

    /// Filter plugins by trust tier
    func plugins(withTier tier: PluginTrustTier) -> [RegistryPlugin] {
        availablePlugins.filter { $0.trustTier == tier }
    }

    /// Filter plugins by type
    func plugins(ofType type: PluginType) -> [RegistryPlugin] {
        availablePlugins.filter { $0.pluginType == type }
    }

    /// Get popular plugins (sorted by downloads)
    func popularPlugins(limit: Int = 10) -> [RegistryPlugin] {
        Array(
            availablePlugins
                .sorted { ($0.downloads ?? 0) > ($1.downloads ?? 0) }
                .prefix(limit)
        )
    }

    /// Get recently updated plugins
    func recentlyUpdatedPlugins(limit: Int = 10) -> [RegistryPlugin] {
        Array(
            availablePlugins
                .filter { $0.updatedAt != nil }
                .sorted { ($0.updatedAt ?? .distantPast) > ($1.updatedAt ?? .distantPast) }
                .prefix(limit)
        )
    }

    /// Get highly rated plugins
    func highlyRatedPlugins(minRating: Double = 4.0, limit: Int = 10) -> [RegistryPlugin] {
        Array(
            availablePlugins
                .filter { ($0.rating ?? 0) >= minRating }
                .sorted { ($0.rating ?? 0) > ($1.rating ?? 0) }
                .prefix(limit)
        )
    }

    // MARK: - Installation

    /// Install a plugin from the registry
    func install(plugin: RegistryPlugin) async throws {
        // Check permissions
        let validationResult = permissionValidator.validateForLoading(
            manifest: createManifest(from: plugin)
        )

        switch validationResult {
        case .approved:
            break
        case .needsApproval(let permissions):
            // Store pending approval - UI will show approval dialog
            permissionValidator.requestApproval(for: plugin.identifier, permissions: permissions)
            throw InstallError.needsPermissionApproval
        case .denied(let reason):
            throw InstallError.permissionDenied(reason.localizedDescription)
        }

        // Download and install
        _ = try await downloader.downloadAndInstall(plugin: plugin)

        // Reload plugin discovery
        PluginManager.shared.reloadDiscovery()
    }

    /// Create a manifest from a registry plugin
    private func createManifest(from plugin: RegistryPlugin) -> PluginManifest {
        PluginManifest(
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
            signature: plugin.signature,
            capabilities: nil,
            entryPoint: nil,
            configSchema: nil,
            homepage: plugin.homepage,
            repository: plugin.repository,
            license: plugin.license,
            keywords: plugin.keywords
        )
    }

    // MARK: - Update Checking

    /// Check if a plugin has an update available
    func hasUpdate(for installedPlugin: PluginManifest) -> RegistryPlugin? {
        guard let registryPlugin = plugin(withId: installedPlugin.identifier) else {
            return nil
        }

        // Compare versions
        if compareVersions(registryPlugin.version, installedPlugin.version) > 0 {
            return registryPlugin
        }

        return nil
    }

    /// Check all installed plugins for updates
    func checkForUpdates(installedPlugins: [PluginManifest]) -> [RegistryPlugin] {
        installedPlugins.compactMap { hasUpdate(for: $0) }
    }

    /// Simple semantic version comparison
    /// Returns: positive if v1 > v2, negative if v1 < v2, 0 if equal
    private func compareVersions(_ v1: String, _ v2: String) -> Int {
        let parts1 = v1.split(separator: ".").compactMap { Int($0) }
        let parts2 = v2.split(separator: ".").compactMap { Int($0) }

        for i in 0..<max(parts1.count, parts2.count) {
            let p1 = i < parts1.count ? parts1[i] : 0
            let p2 = i < parts2.count ? parts2[i] : 0

            if p1 > p2 { return 1 }
            if p1 < p2 { return -1 }
        }

        return 0
    }
}

// MARK: - Installation Errors

enum InstallError: LocalizedError {
    case needsPermissionApproval
    case permissionDenied(String)
    case alreadyInstalled
    case downloadFailed(Error)
    case installationFailed(Error)

    var errorDescription: String? {
        switch self {
        case .needsPermissionApproval:
            return "Plugin requires permission approval"
        case .permissionDenied(let reason):
            return "Permission denied: \(reason)"
        case .alreadyInstalled:
            return "Plugin is already installed"
        case .downloadFailed(let error):
            return "Download failed: \(error.localizedDescription)"
        case .installationFailed(let error):
            return "Installation failed: \(error.localizedDescription)"
        }
    }
}
