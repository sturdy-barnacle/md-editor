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
                            onInstall: { installPlugin(plugin) }
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
                        onInstall: { installPlugin(plugin) }
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
                        onInstall: { installPlugin(plugin) }
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
                        onInstall: { installPlugin(plugin) }
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
                            onInstall: { installPlugin(plugin) }
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

    private func colorForRiskLevel(_ level: PermissionRiskLevel) -> Color {
        switch level {
        case .safe: return .green
        case .moderate: return .orange
        case .high: return .red
        }
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
    let onInstall: () -> Void

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
                    Text(plugin.name)
                        .font(.headline)
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
                    Label("Installed", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
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
    let onInstall: () -> Void

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
                }

                if let description = plugin.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Install button
            if isInstalled {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
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

