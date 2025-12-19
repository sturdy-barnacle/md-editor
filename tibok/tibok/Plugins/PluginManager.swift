//
//  PluginManager.swift
//  tibok
//
//  Manages plugin lifecycle: discovery, initialization, and deactivation.
//

import Foundation

/// Manages plugin lifecycle: discovery, initialization, and deactivation.
@MainActor
final class PluginManager: ObservableObject {
    static let shared = PluginManager()

    @Published private(set) var loadedPlugins: [any TibokPlugin] = []
    @Published private(set) var pluginErrors: [String: Error] = [:]
    @Published private(set) var discoveredManifests: [(url: URL, manifest: PluginManifest, source: PluginSource)] = []

    /// All available plugin types (registered at compile time)
    private(set) var availablePluginTypes: [any TibokPlugin.Type] = []

    private var context: PluginContext?
    private var isInitialized = false
    private let stateManager = PluginStateManager.shared

    private init() {}

    /// Initialize the plugin system with required dependencies.
    /// Call this once during app startup after AppState is created.
    func initialize(
        slashCommandService: SlashCommandService,
        commandRegistry: CommandService,
        appState: AppState
    ) {
        guard !isInitialized else { return }
        isInitialized = true

        self.context = PluginContext(
            slashCommandService: slashCommandService,
            commandRegistry: commandRegistry,
            appState: appState
        )

        // Ensure plugin directories exist
        PluginDiscovery.Folders.ensureDirectoriesExist()

        // Register all known plugin types
        registerPluginTypes()

        // Discover plugins from folders
        discoverPluginsFromFolders()

        // Load only enabled plugins
        loadEnabledPlugins()
    }

    /// Register all known plugin types.
    private func registerPluginTypes() {
        availablePluginTypes = [
            CoreSlashCommandsPlugin.self,
            FrontmatterPlugin.self,
            WordPressExportPlugin.self,
        ]
    }

    /// Discover plugins from folders on the file system
    private func discoverPluginsFromFolders() {
        discoveredManifests = PluginDiscovery.discoverAllManifests()
        print("Discovered \(discoveredManifests.count) plugin manifests")
        for manifest in discoveredManifests {
            print("  - \(manifest.manifest.identifier): \(manifest.manifest.name) (\(manifest.source.displayName))")
        }
    }

    /// Load only plugins that are enabled
    private func loadEnabledPlugins() {
        guard let context = context else { return }

        for pluginType in availablePluginTypes {
            if stateManager.isEnabled(pluginType.identifier) {
                loadPlugin(pluginType, context: context)
            }
        }
    }

    private func loadPlugin(_ pluginType: any TibokPlugin.Type, context: PluginContext) {
        let identifier = pluginType.identifier

        // Don't load if already loaded
        guard !isLoaded(identifier) else { return }

        let plugin = pluginType.init()
        plugin.register(with: context)
        loadedPlugins.append(plugin)
        pluginErrors.removeValue(forKey: identifier)
    }

    /// Enable a plugin by identifier
    func enablePlugin(_ identifier: String) {
        guard let context = context else { return }

        stateManager.setEnabled(identifier, true)

        // Find and load the plugin type
        if let pluginType = availablePluginTypes.first(where: { $0.identifier == identifier }) {
            loadPlugin(pluginType, context: context)
        }
    }

    /// Disable a plugin by identifier
    func disablePlugin(_ identifier: String) {
        stateManager.setEnabled(identifier, false)
        unloadPlugin(identifier)
    }

    /// Unload a plugin and remove its contributions
    func unloadPlugin(_ identifier: String) {
        guard let index = loadedPlugins.firstIndex(where: {
            type(of: $0).identifier == identifier
        }) else { return }

        let plugin = loadedPlugins[index]

        // Deactivate and remove from registries
        plugin.deactivate()
        context?.slashCommandService.unregister(source: identifier)
        context?.commandRegistry.unregister(source: identifier)

        loadedPlugins.remove(at: index)
    }

    /// Deactivate all plugins (called on app termination)
    func deactivateAll() {
        for plugin in loadedPlugins {
            plugin.deactivate()
        }
        loadedPlugins.removeAll()
    }

    /// Check if a plugin is loaded
    func isLoaded(_ identifier: String) -> Bool {
        loadedPlugins.contains { type(of: $0).identifier == identifier }
    }

    /// Get info about all loaded plugins
    var pluginInfo: [(identifier: String, name: String, version: String)] {
        loadedPlugins.map { plugin in
            let type = type(of: plugin)
            return (type.identifier, type.name, type.version)
        }
    }

    /// All plugins (loaded or not) for Settings UI - includes both built-in and discovered
    var allPluginInfo: [(type: (any TibokPlugin.Type)?, manifest: PluginManifest?, source: PluginSource, isLoaded: Bool)] {
        var info: [(type: (any TibokPlugin.Type)?, manifest: PluginManifest?, source: PluginSource, isLoaded: Bool)] = []

        // Add built-in plugins
        for pluginType in availablePluginTypes {
            info.append((
                type: pluginType,
                manifest: nil,
                source: .builtin,
                isLoaded: isLoaded(pluginType.identifier)
            ))
        }

        // Add discovered plugins
        for discovered in discoveredManifests {
            info.append((
                type: nil,
                manifest: discovered.manifest,
                source: discovered.source,
                isLoaded: isLoaded(discovered.manifest.identifier)
            ))
        }

        return info
    }

    /// Get a discovered plugin manifest by identifier
    func getDiscoveredPlugin(_ identifier: String) -> PluginManifest? {
        discoveredManifests.first { $0.manifest.identifier == identifier }?.manifest
    }

    /// Check if a plugin is from a discovered manifest
    func isDiscoveredPlugin(_ identifier: String) -> Bool {
        discoveredManifests.contains { $0.manifest.identifier == identifier }
    }

    /// Reload plugin discovery (useful if plugins folder changes)
    func reloadDiscovery() {
        discoverPluginsFromFolders()
    }
}
