//
//  SlashCommandService.swift
//  tibok
//
//  Registry for slash commands, mirroring CommandService pattern.
//

import SwiftUI

// MARK: - Slash Command Category

enum SlashCommandCategory: String, CaseIterable {
    case headings = "Headings"
    case blocks = "Blocks"
    case links = "Links & Media"
    case lists = "Lists"
    case formatting = "Formatting"
    case math = "Math"
    case structure = "Structure"
    case datetime = "Date & Time"
    case frontmatter = "Frontmatter"
    case general = "General"
}

// MARK: - Slash Command

/// A slash command that can be triggered in the editor by typing "/"
struct SlashCommand: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let insert: String

    /// Source identifier (plugin ID or "builtin")
    let source: String

    /// Additional keywords for search
    let keywords: [String]

    /// Category for grouping in UI
    let category: SlashCommandCategory

    init(
        id: String,
        name: String,
        description: String,
        icon: String,
        insert: String,
        source: String = "builtin",
        keywords: [String] = [],
        category: SlashCommandCategory = .general
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.insert = insert
        self.source = source
        self.keywords = keywords
        self.category = category
    }

    static func == (lhs: SlashCommand, rhs: SlashCommand) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Slash Command Registry

/// Registry for slash commands, mirroring CommandService pattern.
/// Manages all available slash commands including built-in and plugin-provided.
@MainActor
final class SlashCommandService: ObservableObject {
    static let shared = SlashCommandService()

    /// Nonisolated accessor for use from NSTextView delegates (which run on main thread)
    nonisolated static var syncShared: SlashCommandService {
        MainActor.assumeIsolated { shared }
    }

    @Published private(set) var commands: [SlashCommand] = []
    @Published var recentCommandIds: [String] = []

    private let maxRecent = 10

    private init() {
        loadRecentCommands()
    }

    // MARK: - Registration

    /// Register a single slash command
    func register(_ command: SlashCommand) {
        guard !commands.contains(where: { $0.id == command.id }) else {
            // Duplicate command ID - skip
            return
        }
        commands.append(command)
    }

    /// Register multiple slash commands
    func register(_ commands: [SlashCommand]) {
        for command in commands {
            register(command)
        }
    }

    /// Unregister a command by ID (for plugin deactivation)
    func unregister(id: String) {
        commands.removeAll { $0.id == id }
    }

    /// Unregister all commands from a specific source/plugin
    func unregister(source: String) {
        commands.removeAll { $0.source == source }
    }

    // MARK: - Search & Filter

    /// Filter commands by query string
    /// This is nonisolated to allow calling from non-MainActor contexts (like NSTextView delegates)
    nonisolated func filtered(by query: String) -> [SlashCommand] {
        // Access actor-isolated properties synchronously since we're on MainActor at runtime
        // (NSTextView delegates run on main thread)
        return MainActor.assumeIsolated {
            if query.isEmpty {
                // Return recent first, then others
                let recentCommands = recentCommandIds.compactMap { id in
                    commands.first { $0.id == id }
                }
                let otherCommands = commands.filter { !recentCommandIds.contains($0.id) }
                return recentCommands + otherCommands
            }

            let lower = query.lowercased()
            return commands.filter {
                $0.id.contains(lower) ||
                $0.name.lowercased().contains(lower) ||
                $0.keywords.contains { $0.lowercased().contains(lower) }
            }
        }
    }

    /// Record command usage for recent tracking
    /// This is nonisolated to allow calling from non-MainActor contexts
    nonisolated func recordUsage(_ commandId: String) {
        MainActor.assumeIsolated {
            recentCommandIds.removeAll { $0 == commandId }
            recentCommandIds.insert(commandId, at: 0)
            if recentCommandIds.count > maxRecent {
                recentCommandIds = Array(recentCommandIds.prefix(maxRecent))
            }
            saveRecentCommands()
        }
    }

    // MARK: - Persistence

    private func loadRecentCommands() {
        if let ids = UserDefaults.standard.stringArray(forKey: "recentSlashCommands") {
            recentCommandIds = ids
        }
    }

    private func saveRecentCommands() {
        UserDefaults.standard.set(recentCommandIds, forKey: "recentSlashCommands")
    }
}
