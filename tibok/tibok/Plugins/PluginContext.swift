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
    let slashCommandService: SlashCommandService

    /// Registry for command palette commands
    let commandRegistry: CommandService

    /// App state for accessing document/workspace info (read-only for Phase 1)
    weak var appState: AppState?

    init(
        slashCommandService: SlashCommandService,
        commandRegistry: CommandService,
        appState: AppState?
    ) {
        self.slashCommandService = slashCommandService
        self.commandRegistry = commandRegistry
        self.appState = appState
    }
}
