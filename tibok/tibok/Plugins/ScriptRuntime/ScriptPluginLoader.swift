//
//  ScriptPluginLoader.swift
//  tibok
//
//  Loads and manages JavaScript-based script plugins.
//
//  MIT License - See LICENSE file in Plugins directory
//

import Foundation

/// Loads and manages JavaScript-based script plugins.
@MainActor
final class ScriptPluginLoader {
    static let shared = ScriptPluginLoader()

    /// Active script plugin runtimes
    private var runtimes: [String: ScriptPluginRuntime] = [:]

    /// Reference to app state
    private weak var appState: AppState?

    /// Reference to slash command service
    private weak var slashCommandService: SlashCommandService?

    /// Reference to command registry
    private weak var commandRegistry: CommandService?

    private init() {}

    // MARK: - Configuration

    /// Configure the loader with required services
    func configure(
        appState: AppState,
        slashCommandService: SlashCommandService,
        commandRegistry: CommandService
    ) {
        self.appState = appState
        self.slashCommandService = slashCommandService
        self.commandRegistry = commandRegistry
    }

    // MARK: - Plugin Loading

    /// Load a script plugin from a directory
    func loadPlugin(
        from url: URL,
        manifest: PluginManifest
    ) throws -> ScriptPluginRuntime {
        // Validate this is a script plugin
        guard manifest.resolvedPluginType == .script else {
            throw ScriptPluginError.invalidManifest("Not a script plugin")
        }

        // Check permissions are script-compatible
        if manifest.permissionSet.hasElevatedPermissions {
            let elevated = manifest.permissionSet.elevatedPermissions
            throw ScriptPluginError.invalidManifest(
                "Script plugins cannot request elevated permissions: \(elevated.map { $0.displayName }.joined(separator: ", "))"
            )
        }

        // Find the entry point script
        guard let entryPoint = manifest.entryPoint,
              let scriptPath = entryPoint.script else {
            throw ScriptPluginError.invalidManifest("Missing script entry point")
        }

        let scriptURL = url.appendingPathComponent(scriptPath)

        guard FileManager.default.fileExists(atPath: scriptURL.path) else {
            throw ScriptPluginError.scriptNotFound(path: scriptPath)
        }

        // Check if already loaded
        if let existing = runtimes[manifest.identifier] {
            return existing
        }

        // Create the runtime
        let runtime = ScriptPluginRuntime(
            pluginId: manifest.identifier,
            manifest: manifest,
            appState: appState
        )

        // Set up error handling
        runtime.onError = { message in
            print("[\(manifest.identifier)] Error: \(message)")
        }

        // Load the script
        try runtime.loadScript(from: scriptURL)

        // Register the plugin's contributions
        registerContributions(from: runtime)

        // Store the runtime
        runtimes[manifest.identifier] = runtime

        print("Loaded script plugin: \(manifest.identifier) (\(runtime.registeredSlashCommands.count) slash commands, \(runtime.registeredCommands.count) commands)")

        return runtime
    }

    /// Register a plugin's contributions with the app services
    private func registerContributions(from runtime: ScriptPluginRuntime) {
        print("[DEBUG] registerContributions: \(runtime.registeredSlashCommands.count) slash commands, \(runtime.registeredCommands.count) commands")
        print("[DEBUG] slashCommandService is \(slashCommandService == nil ? "nil" : "set")")
        print("[DEBUG] commandRegistry is \(commandRegistry == nil ? "nil" : "set")")

        // Register slash commands
        for command in runtime.registeredSlashCommands {
            print("[DEBUG] Registering slash command: /\(command.name)")
            slashCommandService?.register(command)
        }

        // Register palette commands
        for command in runtime.registeredCommands {
            print("[DEBUG] Registering palette command: \(command.title) (id: \(command.id))")
            commandRegistry?.register(command)
        }
    }

    // MARK: - Plugin Management

    /// Unload a script plugin
    func unloadPlugin(_ identifier: String) {
        guard let runtime = runtimes[identifier] else { return }

        // Unregister contributions
        slashCommandService?.unregister(source: identifier)
        commandRegistry?.unregister(source: identifier)

        // Deactivate the runtime
        runtime.deactivate()

        // Remove from tracked runtimes
        runtimes.removeValue(forKey: identifier)

        print("Unloaded script plugin: \(identifier)")
    }

    /// Check if a plugin is loaded
    func isLoaded(_ identifier: String) -> Bool {
        runtimes[identifier] != nil
    }

    /// Get a loaded runtime
    func getRuntime(_ identifier: String) -> ScriptPluginRuntime? {
        runtimes[identifier]
    }

    /// Get all loaded script plugins
    var loadedPlugins: [ScriptPluginRuntime] {
        Array(runtimes.values)
    }

    /// Unload all script plugins
    func unloadAll() {
        for identifier in runtimes.keys {
            unloadPlugin(identifier)
        }
    }

    // MARK: - Command Execution

    /// Execute a dynamic slash command by its full ID (pluginId:commandName)
    func executeSlashCommand(_ commandId: String) {
        // Parse: "com.example.plugin:commandname"
        let parts = commandId.split(separator: ":", maxSplits: 1)
        guard parts.count == 2 else {
            print("Invalid command ID format: \(commandId)")
            return
        }

        let pluginId = String(parts[0])
        let commandName = String(parts[1])

        guard let runtime = runtimes[pluginId] else {
            print("Plugin not loaded: \(pluginId)")
            return
        }

        runtime.executeSlashCommand(name: commandName)
    }

    // MARK: - Script Validation

    /// Validate a script plugin before loading (static analysis)
    func validatePlugin(at url: URL, manifest: PluginManifest) -> [String] {
        var warnings: [String] = []

        // Check plugin type
        if manifest.resolvedPluginType != .script {
            warnings.append("Plugin type is not 'script'")
        }

        // Check for elevated permissions
        if manifest.permissionSet.hasElevatedPermissions {
            warnings.append("Script plugins cannot use elevated permissions")
        }

        // Check entry point
        guard let entryPoint = manifest.entryPoint,
              let scriptPath = entryPoint.script else {
            warnings.append("Missing script entry point in manifest")
            return warnings
        }

        // Check script file exists
        let scriptURL = url.appendingPathComponent(scriptPath)
        if !FileManager.default.fileExists(atPath: scriptURL.path) {
            warnings.append("Script file not found: \(scriptPath)")
        }

        // Check script size (limit to 1MB for performance)
        if let attrs = try? FileManager.default.attributesOfItem(atPath: scriptURL.path),
           let size = attrs[.size] as? Int64,
           size > 1_000_000 {
            warnings.append("Script file is larger than 1MB, may impact performance")
        }

        return warnings
    }
}

// MARK: - Script Plugin Discovery

extension PluginDiscovery {
    /// Check if a discovered plugin is a script plugin
    static func isScriptPlugin(manifest: PluginManifest) -> Bool {
        manifest.resolvedPluginType == .script
    }

    /// Get all script plugins from discovered manifests
    static func scriptPlugins(from manifests: [(url: URL, manifest: PluginManifest, source: PluginSource)]) -> [(url: URL, manifest: PluginManifest, source: PluginSource)] {
        manifests.filter { isScriptPlugin(manifest: $0.manifest) }
    }
}
