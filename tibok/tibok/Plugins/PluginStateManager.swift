//
//  PluginStateManager.swift
//  tibok
//
//  Manages persistence for plugin enabled/disabled state.
//

import Foundation

/// Manages persistence for plugin enabled/disabled state.
@MainActor
final class PluginStateManager: ObservableObject {
    static let shared = PluginStateManager()

    @Published var disabledPlugins: Set<String> = []

    private let key = "disabledPlugins"

    private init() {
        load()
    }

    /// Check if a plugin is enabled (default is enabled)
    func isEnabled(_ identifier: String) -> Bool {
        !disabledPlugins.contains(identifier)
    }

    /// Set plugin enabled state
    func setEnabled(_ identifier: String, _ enabled: Bool) {
        if enabled {
            disabledPlugins.remove(identifier)
        } else {
            disabledPlugins.insert(identifier)
        }
        save()
    }

    private func load() {
        if let ids = UserDefaults.standard.stringArray(forKey: key) {
            disabledPlugins = Set(ids)
        }
    }

    private func save() {
        UserDefaults.standard.set(Array(disabledPlugins), forKey: key)
    }
}
