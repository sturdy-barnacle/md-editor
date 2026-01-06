//
//  PluginManager.swift
//  tibok
//
//  Manages plugin lifecycle: discovery, initialization, and deactivation.
//
//  MIT License - See LICENSE file in Plugins directory
//

import Foundation

/// Manages plugin lifecycle: discovery, initialization, and deactivation.
@MainActor
final class PluginManager: ObservableObject {
    static let shared = PluginManager()

    @Published private(set) var loadedPlugins: [any TibokPlugin] = []
    @Published private(set) var loadedScriptPlugins: [String] = []  // Identifiers of loaded script plugins
    @Published private(set) var pluginErrors: [String: Error] = [:]
    @Published private(set) var discoveredManifests: [(url: URL, manifest: PluginManifest, source: PluginSource)] = []

    /// Pending permission approval requests
    @Published var pendingApprovalRequest: PermissionApprovalRequest?

    /// All available plugin types (registered at compile time)
    private(set) var availablePluginTypes: [any TibokPlugin.Type] = []

    private var context: PluginContext?
    private var isInitialized = false
    private let stateManager = PluginStateManager.shared
    private let dynamicLoader = DynamicPluginLoader()
    private let scriptLoader = ScriptPluginLoader.shared
    private let permissionValidator = PermissionValidator.shared

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

        // Configure script plugin loader
        scriptLoader.configure(
            appState: appState,
            slashCommandService: slashCommandService,
            commandRegistry: commandRegistry
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
        for manifest in discoveredManifests {
            print("  - \(manifest.manifest.identifier): \(manifest.manifest.name) (\(manifest.source.displayName))")
        }
    }

    /// Load only plugins that are enabled
    private func loadEnabledPlugins() {
        guard let context = context else { return }

        // Load enabled built-in plugins
        for pluginType in availablePluginTypes {
            if stateManager.isEnabled(pluginType.identifier) {
                loadPlugin(pluginType, context: context)
            }
        }
        
        // Load enabled discovered plugins (dynamic loading)
        for discovered in discoveredManifests {
            if stateManager.isEnabled(discovered.manifest.identifier) {
                loadDiscoveredPlugin(discovered, context: context)
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
    
    /// Load a discovered plugin dynamically (native framework or script)
    private func loadDiscoveredPlugin(
        _ discovered: (url: URL, manifest: PluginManifest, source: PluginSource),
        context: PluginContext,
        skipPermissionCheck: Bool = false
    ) {
        let identifier = discovered.manifest.identifier
        let manifest = discovered.manifest

        // Don't load if already loaded
        guard !isLoaded(identifier) else { return }

        // Validate permissions (unless skipped - e.g., after user approval)
        if !skipPermissionCheck {
            let validationResult = permissionValidator.validateForLoading(manifest: manifest)

            switch validationResult {
            case .approved:
                break  // Continue loading
            case .needsApproval(let permissions):
                // Request user approval
                pendingApprovalRequest = PermissionApprovalRequest(
                    manifest: manifest,
                    onApprove: { [weak self] in
                        self?.permissionValidator.approvePermissions(
                            for: identifier,
                            permissions: permissions
                        )
                        self?.pendingApprovalRequest = nil
                        // Retry loading with permission check skipped
                        self?.loadDiscoveredPlugin(discovered, context: context, skipPermissionCheck: true)
                    },
                    onDeny: { [weak self] in
                        self?.pendingApprovalRequest = nil
                        self?.stateManager.setEnabled(identifier, false)
                    }
                )
                return
            case .denied(let reason):
                pluginErrors[identifier] = PluginLoadingError.permissionDenied(reason.localizedDescription)
                print("Plugin \(identifier) denied: \(reason.localizedDescription)")
                return
            }
        }

        // Determine plugin type and load accordingly
        let pluginType = manifest.resolvedPluginType

        do {
            switch pluginType {
            case .script:
                try loadScriptPlugin(discovered)
            case .native:
                try loadNativePlugin(discovered, context: context)
            }
        } catch {
            pluginErrors[identifier] = error
            print("Failed to load discovered plugin \(identifier): \(error)")
        }
    }

    /// Load a native Swift framework plugin
    private func loadNativePlugin(
        _ discovered: (url: URL, manifest: PluginManifest, source: PluginSource),
        context: PluginContext
    ) throws {
        let identifier = discovered.manifest.identifier

        // Validate entry point
        guard let entryPoint = discovered.manifest.entryPoint else {
            throw PluginLoadingError.missingEntryPoint
        }

        guard let frameworkName = entryPoint.framework else {
            throw PluginLoadingError.missingEntryPoint
        }

        guard let className = entryPoint.className else {
            throw PluginLoadingError.missingEntryPoint
        }

        // Find framework
        let frameworkURL = discovered.url.appendingPathComponent("\(frameworkName).framework")

        // Load plugin dynamically
        let plugin = try dynamicLoader.loadPlugin(
            from: frameworkURL,
            className: className,
            identifier: identifier
        )

        // Register plugin
        plugin.register(with: context)
        loadedPlugins.append(plugin)
        pluginErrors.removeValue(forKey: identifier)

        print("Successfully loaded native plugin: \(identifier)")
    }

    /// Load a JavaScript script plugin
    private func loadScriptPlugin(
        _ discovered: (url: URL, manifest: PluginManifest, source: PluginSource)
    ) throws {
        let identifier = discovered.manifest.identifier

        // Load via script loader
        _ = try scriptLoader.loadPlugin(
            from: discovered.url,
            manifest: discovered.manifest
        )

        loadedScriptPlugins.append(identifier)
        pluginErrors.removeValue(forKey: identifier)
    }

    /// Enable a plugin by identifier
    func enablePlugin(_ identifier: String) {
        guard let context = context else { return }

        stateManager.setEnabled(identifier, true)

        // Try built-in plugins first
        if let pluginType = availablePluginTypes.first(where: { $0.identifier == identifier }) {
            loadPlugin(pluginType, context: context)
            return
        }
        
        // Try discovered plugins (dynamic loading)
        if let discovered = discoveredManifests.first(where: { $0.manifest.identifier == identifier }) {
            loadDiscoveredPlugin(discovered, context: context)
        }
    }

    /// Disable a plugin by identifier
    func disablePlugin(_ identifier: String) {
        stateManager.setEnabled(identifier, false)
        unloadPlugin(identifier)

        // Revoke permissions for community plugins so they require re-approval on next enable
        if let discovered = discoveredManifests.first(where: { $0.manifest.identifier == identifier }) {
            if discovered.manifest.resolvedTrustTier == .community {
                permissionValidator.revokeApproval(for: identifier)
                print("Revoked permissions for community plugin: \(identifier)")
            }
        }
    }

    /// Unload a plugin and remove its contributions
    func unloadPlugin(_ identifier: String) {
        // Check if it's a native plugin
        if let index = loadedPlugins.firstIndex(where: { type(of: $0).identifier == identifier }) {
            let plugin = loadedPlugins[index]

            // Deactivate and remove from registries
            plugin.deactivate()
            context?.slashCommandService.unregister(source: identifier)
            context?.commandRegistry.unregister(source: identifier)

            loadedPlugins.remove(at: index)

            // If this was a dynamically loaded plugin, mark framework as unloaded
            if let discovered = discoveredManifests.first(where: { $0.manifest.identifier == identifier }),
               let entryPoint = discovered.manifest.entryPoint,
               let frameworkName = entryPoint.framework {
                let frameworkURL = discovered.url.appendingPathComponent("\(frameworkName).framework")
                dynamicLoader.unloadFramework(at: frameworkURL)
            }
            return
        }

        // Check if it's a script plugin
        if loadedScriptPlugins.contains(identifier) {
            scriptLoader.unloadPlugin(identifier)
            loadedScriptPlugins.removeAll { $0 == identifier }
        }
    }

    /// Deactivate all plugins (called on app termination)
    func deactivateAll() {
        // Deactivate native plugins
        for plugin in loadedPlugins {
            plugin.deactivate()
        }
        loadedPlugins.removeAll()

        // Deactivate script plugins
        scriptLoader.unloadAll()
        loadedScriptPlugins.removeAll()
    }

    /// Check if a plugin is loaded (native or script)
    func isLoaded(_ identifier: String) -> Bool {
        loadedPlugins.contains { type(of: $0).identifier == identifier } ||
        loadedScriptPlugins.contains(identifier) ||
        scriptLoader.isLoaded(identifier)
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

    /// Uninstall a plugin completely: unload, revoke permissions, delete files
    /// Returns true if successful, false if plugin cannot be uninstalled (e.g., built-in)
    @discardableResult
    func uninstallPlugin(_ identifier: String) -> Bool {
        // Cannot uninstall built-in plugins
        if availablePluginTypes.contains(where: { $0.identifier == identifier }) {
            print("Cannot uninstall built-in plugin: \(identifier)")
            return false
        }

        // Find the discovered plugin
        guard let discoveredIndex = discoveredManifests.firstIndex(where: { $0.manifest.identifier == identifier }) else {
            print("Plugin not found for uninstall: \(identifier)")
            return false
        }

        let discovered = discoveredManifests[discoveredIndex]

        // Unload from memory first
        unloadPlugin(identifier)

        // Disable the plugin
        stateManager.setEnabled(identifier, false)

        // Revoke all permissions
        permissionValidator.revokeApproval(for: identifier)

        // Delete the plugin folder
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(at: discovered.url)
            print("Deleted plugin folder: \(discovered.url.path)")
        } catch {
            print("Failed to delete plugin folder: \(error)")
            // Continue anyway - the plugin is already unloaded
        }

        // Remove from discovered manifests
        discoveredManifests.remove(at: discoveredIndex)

        return true
    }

    /// Check if a plugin can be uninstalled (i.e., it's not a built-in plugin)
    func canUninstall(_ identifier: String) -> Bool {
        // Built-in plugins cannot be uninstalled
        if availablePluginTypes.contains(where: { $0.identifier == identifier }) {
            return false
        }
        // Only discovered plugins (from folders) can be uninstalled
        return discoveredManifests.contains { $0.manifest.identifier == identifier }
    }
}
