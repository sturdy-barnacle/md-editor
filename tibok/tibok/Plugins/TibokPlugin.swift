//
//  TibokPlugin.swift
//  tibok
//
//  Plugin protocol definition for tibok extensions.
//

import Foundation

/// Protocol that all tibok plugins must implement.
/// Plugins are Swift Package-based and loaded at compile time.
@MainActor
protocol TibokPlugin {
    /// Unique identifier for the plugin (reverse-DNS style recommended)
    static var identifier: String { get }

    /// Human-readable name shown in UI
    static var name: String { get }

    /// Plugin version string
    static var version: String { get }

    /// Optional description of what the plugin does
    static var description: String? { get }

    /// SF Symbol icon name for display in settings
    static var icon: String { get }

    /// Author name
    static var author: String? { get }

    /// Initialize the plugin. Called once during app startup.
    init()

    /// Register the plugin's contributions.
    /// Called after init, before any plugin features are used.
    /// - Parameter context: Provides access to registries and app services
    func register(with context: PluginContext)

    /// Called when the plugin should clean up (app termination or plugin disable)
    func deactivate()
}

// Default implementations for optional members
extension TibokPlugin {
    static var description: String? { nil }
    static var icon: String { "puzzlepiece.extension" }
    static var author: String? { nil }
    func deactivate() {}
}
