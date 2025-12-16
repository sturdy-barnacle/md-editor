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

    /// All available plugin types (registered at compile time)
    private(set) var availablePluginTypes: [any TibokPlugin.Type] = []

    private var context: PluginContext?
    private var isInitialized = false
    private let stateManager = PluginStateManager.shared

    private init() {}

    /// Initialize the plugin system with required dependencies.
    /// Call this once during app startup after AppState is created.
    func initialize(
        slashCommandRegistry: SlashCommandRegistry,
        commandRegistry: CommandRegistry,
        appState: AppState
    ) {
        guard !isInitialized else { return }
        isInitialized = true

        self.context = PluginContext(
            slashCommandRegistry: slashCommandRegistry,
            commandRegistry: commandRegistry,
            appState: appState
        )

        // Register all known plugin types
        registerPluginTypes()

        // Load only enabled plugins
        loadEnabledPlugins()
    }

    /// Register all known plugin types.
    private func registerPluginTypes() {
        availablePluginTypes = [
            CoreSlashCommandsPlugin.self,
            FrontmatterPlugin.self,
        ]
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
        context?.slashCommandRegistry.unregister(source: identifier)
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

    /// All plugins (loaded or not) for Settings UI
    var allPluginInfo: [(type: any TibokPlugin.Type, isLoaded: Bool)] {
        availablePluginTypes.map { ($0, isLoaded($0.identifier)) }
    }
}
