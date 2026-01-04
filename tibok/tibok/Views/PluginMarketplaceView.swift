//
//  PluginMarketplaceView.swift
//  tibok
//
//  Browse and install plugins from the Tibok plugin registry.
//
//  MIT License - See LICENSE file in Plugins directory
//

import SwiftUI

/// Browse and install plugins from the marketplace.
struct PluginMarketplaceView: View {
    @StateObject private var registry = PluginRegistry.shared
    @StateObject private var pluginManager = PluginManager.shared
    @State private var searchText = ""
    @State private var selectedCategory: String?
    @State private var selectedTier: PluginTrustTier?
    @State private var showingPermissionApproval = false
    @State private var pluginToInstall: RegistryPlugin?
    @State private var installError: String?
    @State private var showingError = false
    @State private var showingUninstallConfirmation = false
    @State private var pluginToUninstall: RegistryPlugin?

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            searchBar

            Divider()

            if registry.isLoading && registry.availablePlugins.isEmpty {
                loadingView
            } else if let error = registry.lastError {
                errorView(error)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Active downloads
                        if !PluginDownloader.shared.activeDownloads.isEmpty {
                            downloadsSection
                        }

                        // Featured section
                        if !registry.featuredPlugins.isEmpty && searchText.isEmpty {
                            featuredSection
                        }

                        // Search results or browsing sections
                        if !searchText.isEmpty {
                            searchResultsSection
                        } else {
                            // Popular plugins
                            if !registry.popularPlugins().isEmpty {
                                popularSection
                            }

                            // Recently updated
                            if !registry.recentlyUpdatedPlugins().isEmpty {
                                recentSection
                            }

                            // All plugins
                            allPluginsSection
                        }
                    }
                    .padding()
                }
            }
        }
        .task {
            await registry.loadRegistry()
        }
        .sheet(isPresented: $showingPermissionApproval) {
            if let plugin = pluginToInstall {
                permissionApprovalSheet(for: plugin)
            }
        }
        .alert("Installation Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(installError ?? "Unknown error occurred")
        }
        .alert("Uninstall Plugin", isPresented: $showingUninstallConfirmation) {
            Button("Cancel", role: .cancel) {
                pluginToUninstall = nil
            }
            Button("Uninstall", role: .destructive) {
                if let plugin = pluginToUninstall {
                    uninstallPlugin(plugin)
                }
                pluginToUninstall = nil
            }
        } message: {
            if let plugin = pluginToUninstall {
                Text("Are you sure you want to uninstall \"\(plugin.name)\"? This will remove the plugin and all its data.")
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search plugins...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(.textBackgroundColor))
            .cornerRadius(8)

            // Filters
            filterMenus
        }
        .padding()
    }

    private var filterMenus: some View {
        HStack(spacing: 8) {
            // Category filter
            Menu {
                Button("All Categories") { selectedCategory = nil }
                Divider()
                ForEach(registry.categories) { category in
                    Button {
                        selectedCategory = category.slug
                    } label: {
                        Label(category.name, systemImage: category.icon ?? "folder")
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    if let slug = selectedCategory,
                       let category = registry.categories.first(where: { $0.slug == slug }) {
                        Image(systemName: category.icon ?? "folder")
                        Text(category.name)
                    } else {
                        Image(systemName: "square.grid.2x2")
                        Text("Category")
                    }
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(selectedCategory != nil ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)

            // Trust tier filter
            Menu {
                Button("All Tiers") { selectedTier = nil }
                Divider()
                ForEach([PluginTrustTier.verified, .community], id: \.self) { tier in
                    Button {
                        selectedTier = tier
                    } label: {
                        Label(tier.displayName, systemImage: tier.icon)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    if let tier = selectedTier {
                        Image(systemName: tier.icon)
                        Text(tier.displayName)
                    } else {
                        Image(systemName: "shield")
                        Text("Trust")
                    }
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(selectedTier != nil ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)

            // Clear filters button (only show if filters are active)
            if selectedCategory != nil || selectedTier != nil {
                Button {
                    selectedCategory = nil
                    selectedTier = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Clear filters")
            }
        }
    }

    // MARK: - Loading & Error Views

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading plugin registry...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text("Failed to load registry")
                .font(.headline)
            Text(error.localizedDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task {
                    await registry.loadRegistry(forceRefresh: true)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Downloads Section

    private var downloadsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Installing")
                .font(.headline)

            ForEach(Array(PluginDownloader.shared.activeDownloads.values)) { download in
                DownloadProgressRow(download: download)
            }
        }
    }

    // MARK: - Featured Section

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("Featured")
                    .font(.headline)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(registry.featuredPlugins) { plugin in
                        FeaturedPluginCard(
                            plugin: plugin,
                            isInstalled: isInstalled(plugin),
                            canUninstall: canUninstall(plugin),
                            hasUpdate: hasUpdate(plugin),
                            category: primaryCategory(for: plugin),
                            onInstall: { installPlugin(plugin) },
                            onUninstall: { requestUninstall(plugin) },
                            onUpdate: { updatePlugin(plugin) }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Popular Section

    private var popularSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("Popular")
                    .font(.headline)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280))], spacing: 12) {
                ForEach(filteredPlugins(from: registry.popularPlugins())) { plugin in
                    PluginCard(
                        plugin: plugin,
                        isInstalled: isInstalled(plugin),
                        canUninstall: canUninstall(plugin),
                        hasUpdate: hasUpdate(plugin),
                        category: primaryCategory(for: plugin),
                        onInstall: { installPlugin(plugin) },
                        onUninstall: { requestUninstall(plugin) },
                        onUpdate: { updatePlugin(plugin) }
                    )
                }
            }
        }
    }

    // MARK: - Recent Section

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.blue)
                Text("Recently Updated")
                    .font(.headline)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280))], spacing: 12) {
                ForEach(filteredPlugins(from: registry.recentlyUpdatedPlugins())) { plugin in
                    PluginCard(
                        plugin: plugin,
                        isInstalled: isInstalled(plugin),
                        canUninstall: canUninstall(plugin),
                        hasUpdate: hasUpdate(plugin),
                        category: primaryCategory(for: plugin),
                        onInstall: { installPlugin(plugin) },
                        onUninstall: { requestUninstall(plugin) },
                        onUpdate: { updatePlugin(plugin) }
                    )
                }
            }
        }
    }

    // MARK: - All Plugins Section

    private var allPluginsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Plugins")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280))], spacing: 12) {
                ForEach(filteredPlugins(from: registry.availablePlugins)) { plugin in
                    PluginCard(
                        plugin: plugin,
                        isInstalled: isInstalled(plugin),
                        canUninstall: canUninstall(plugin),
                        hasUpdate: hasUpdate(plugin),
                        category: primaryCategory(for: plugin),
                        onInstall: { installPlugin(plugin) },
                        onUninstall: { requestUninstall(plugin) },
                        onUpdate: { updatePlugin(plugin) }
                    )
                }
            }
        }
    }

    // MARK: - Search Results

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            let results = filteredPlugins(from: registry.search(query: searchText))

            if results.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No plugins found")
                        .font(.headline)
                    Text("Try different search terms")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                Text("\(results.count) result\(results.count == 1 ? "" : "s")")
                    .font(.headline)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 280))], spacing: 12) {
                    ForEach(results) { plugin in
                        PluginCard(
                            plugin: plugin,
                            isInstalled: isInstalled(plugin),
                            canUninstall: canUninstall(plugin),
                            hasUpdate: hasUpdate(plugin),
                            category: primaryCategory(for: plugin),
                            onInstall: { installPlugin(plugin) },
                            onUninstall: { requestUninstall(plugin) },
                            onUpdate: { updatePlugin(plugin) }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Permission Approval Sheet

    private func permissionApprovalSheet(for plugin: RegistryPlugin) -> some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: plugin.icon ?? "puzzlepiece.extension")
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)
                Text(plugin.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                if let author = plugin.author {
                    Text("by \(author)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top)

            Divider()

            // Permissions
            VStack(alignment: .leading, spacing: 12) {
                Text("This plugin requires the following permissions:")
                    .font(.subheadline)

                let perms: [PluginPermission] = plugin.parsedPermissions
                ForEach(perms, id: \.self) { permission in
                    permissionRow(for: permission)
                }
            }
            .padding(.horizontal)

            Spacer()

            // Actions
            HStack(spacing: 12) {
                Button("Cancel") {
                    showingPermissionApproval = false
                    pluginToInstall = nil
                }
                .buttonStyle(.bordered)

                Button("Install") {
                    showingPermissionApproval = false
                    performInstall(plugin)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 400, height: 500)
    }

    // MARK: - Helpers

    private func filteredPlugins(from plugins: [RegistryPlugin]) -> [RegistryPlugin] {
        plugins.filter { plugin in
            // Apply tier filter
            if let tier = selectedTier, plugin.trustTier != tier {
                return false
            }
            // Apply category filter (matches against plugin keywords)
            if let category = selectedCategory {
                let hasCategory = plugin.keywords.contains { keyword in
                    keyword.lowercased().contains(category.lowercased())
                }
                if !hasCategory {
                    return false
                }
            }
            return true
        }
    }

    private func isInstalled(_ plugin: RegistryPlugin) -> Bool {
        pluginManager.isLoaded(plugin.identifier) ||
        pluginManager.discoveredManifests.contains { $0.manifest.identifier == plugin.identifier }
    }

    private func installPlugin(_ plugin: RegistryPlugin) {
        // Check if needs permission approval
        if !plugin.parsedPermissions.isEmpty {
            pluginToInstall = plugin
            showingPermissionApproval = true
        } else {
            performInstall(plugin)
        }
    }

    private func performInstall(_ plugin: RegistryPlugin) {
        Task {
            do {
                try await registry.install(plugin: plugin)
            } catch {
                installError = error.localizedDescription
                showingError = true
            }
        }
    }

    private func requestUninstall(_ plugin: RegistryPlugin) {
        pluginToUninstall = plugin
        showingUninstallConfirmation = true
    }

    private func uninstallPlugin(_ plugin: RegistryPlugin) {
        pluginManager.uninstallPlugin(plugin.identifier)
    }

    private func canUninstall(_ plugin: RegistryPlugin) -> Bool {
        pluginManager.canUninstall(plugin.identifier)
    }

    /// Check if an installed plugin has an update available
    private func hasUpdate(_ plugin: RegistryPlugin) -> Bool {
        // Find the installed manifest
        guard let installed = pluginManager.discoveredManifests.first(where: { $0.manifest.identifier == plugin.identifier }) else {
            return false
        }
        // Compare versions (registry version > installed version)
        return compareVersions(plugin.version, installed.manifest.version) > 0
    }

    /// Update an installed plugin to the latest version
    private func updatePlugin(_ plugin: RegistryPlugin) {
        Task {
            do {
                // Uninstall first, then install new version
                pluginManager.uninstallPlugin(plugin.identifier)
                try await registry.install(plugin: plugin)
            } catch {
                installError = "Update failed: \(error.localizedDescription)"
                showingError = true
            }
        }
    }

    /// Simple semantic version comparison (returns positive if v1 > v2)
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

    private func colorForRiskLevel(_ level: PermissionRiskLevel) -> Color {
        switch level {
        case .safe: return .green
        case .moderate: return .orange
        case .high: return .red
        }
    }

    /// Find the primary category for a plugin based on its keywords
    private func primaryCategory(for plugin: RegistryPlugin) -> PluginCategory? {
        for category in registry.categories {
            if plugin.keywords.contains(where: { $0.lowercased().contains(category.slug.lowercased()) }) {
                return category
            }
        }
        return nil
    }

    @ViewBuilder
    private func permissionRow(for permission: PluginPermission) -> some View {
        HStack(spacing: 12) {
            Image(systemName: permission.icon)
                .foregroundColor(colorForRiskLevel(permission.riskLevel))
                .frame(width: 24)
            VStack(alignment: .leading) {
                Text(permission.displayName)
                    .font(.subheadline)
                Text(permission.userDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(8)
        .background(Color(.textBackgroundColor))
        .cornerRadius(6)
    }
}

// MARK: - Featured Plugin Card

private struct FeaturedPluginCard: View {
    let plugin: RegistryPlugin
    let isInstalled: Bool
    let canUninstall: Bool
    let hasUpdate: Bool
    let category: PluginCategory?
    let onInstall: () -> Void
    let onUninstall: () -> Void
    let onUpdate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: plugin.icon ?? "puzzlepiece.extension")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 40, height: 40)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(8)

                VStack(alignment: .leading) {
                    HStack(spacing: 6) {
                        Text(plugin.name)
                            .font(.headline)
                        if let category = category {
                            CategoryBadge(category: category)
                        }
                        if hasUpdate {
                            UpdateBadge()
                        }
                    }
                    if let author = plugin.author {
                        Text(author)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                TrustTierBadge(tier: plugin.trustTier)
            }

            // Description
            if let description = plugin.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            // Stats and install button
            HStack {
                if let downloads = plugin.downloads {
                    Label(formatDownloads(downloads), systemImage: "arrow.down.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let rating = plugin.rating {
                    Label(String(format: "%.1f", rating), systemImage: "star.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isInstalled {
                    HStack(spacing: 8) {
                        if hasUpdate {
                            Button("Update", action: onUpdate)
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                        } else {
                            Label("Installed", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        if canUninstall {
                            Button(action: onUninstall) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                            .help("Uninstall plugin")
                        }
                    }
                } else {
                    Button("Install", action: onInstall)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }
            }
        }
        .padding()
        .frame(width: 320)
        .background(Color(.textBackgroundColor))
        .cornerRadius(12)
    }

    private func formatDownloads(_ count: Int) -> String {
        if count >= 1000 {
            return "\(count / 1000)k"
        }
        return "\(count)"
    }
}

// MARK: - Plugin Card

private struct PluginCard: View {
    let plugin: RegistryPlugin
    let isInstalled: Bool
    let canUninstall: Bool
    let hasUpdate: Bool
    let category: PluginCategory?
    let onInstall: () -> Void
    let onUninstall: () -> Void
    let onUpdate: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: plugin.icon ?? "puzzlepiece.extension")
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 36, height: 36)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(8)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(plugin.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TrustTierBadge(tier: plugin.trustTier)
                    if let category = category {
                        CategoryBadge(category: category)
                    }
                    if hasUpdate {
                        UpdateBadge()
                    }
                }

                if let description = plugin.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Install/Update/Uninstall buttons
            if isInstalled {
                HStack(spacing: 8) {
                    if hasUpdate {
                        Button("Update", action: onUpdate)
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    if canUninstall {
                        Button(action: onUninstall) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                        .help("Uninstall plugin")
                    }
                }
            } else {
                Button("Install", action: onInstall)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .padding(10)
        .background(Color(.textBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Download Progress Row

private struct DownloadProgressRow: View {
    let download: DownloadProgress

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(download.name)
                    .font(.subheadline)
                Text(download.status.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if !download.status.isComplete {
                ProgressView(value: download.progress)
                    .frame(width: 100)
            }
        }
        .padding(10)
        .background(Color(.textBackgroundColor))
        .cornerRadius(8)
    }

    private var statusIcon: String {
        switch download.status {
        case .downloading: return "arrow.down.circle"
        case .verifying: return "checkmark.shield"
        case .installing: return "square.and.arrow.down"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }

    private var statusColor: Color {
        switch download.status {
        case .completed: return .green
        case .failed: return .red
        default: return .accentColor
        }
    }
}

// MARK: - Category Badge

private struct CategoryBadge: View {
    let category: PluginCategory

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: category.icon ?? "folder")
                .font(.system(size: 8))
            Text(category.name)
                .font(.system(size: 9))
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(Color.purple.opacity(0.15))
        .foregroundColor(.purple)
        .cornerRadius(4)
    }
}

// MARK: - Update Badge

private struct UpdateBadge: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 8))
            Text("Update")
                .font(.system(size: 9))
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(Color.orange.opacity(0.15))
        .foregroundColor(.orange)
        .cornerRadius(4)
    }
}
