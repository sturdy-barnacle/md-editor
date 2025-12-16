//
//  PluginContext.swift
//  tibok
//
//  Context provided to plugins during registration.
//

import Foundation

/// Context provided to plugins during registration.
/// Provides access to registries and services plugins can extend.
@MainActor
final class PluginContext {
    /// Registry for slash commands (editor inline commands)
    let slashCommandRegistry: SlashCommandRegistry

    /// Registry for command palette commands
    let commandRegistry: CommandRegistry

    /// App state for accessing document/workspace info (read-only for Phase 1)
    weak var appState: AppState?

    init(
        slashCommandRegistry: SlashCommandRegistry,
        commandRegistry: CommandRegistry,
        appState: AppState?
    ) {
        self.slashCommandRegistry = slashCommandRegistry
        self.commandRegistry = commandRegistry
        self.appState = appState
    }
}
