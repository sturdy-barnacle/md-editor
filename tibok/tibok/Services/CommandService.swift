import SwiftUI

// MARK: - Command

struct Command: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String?
    let icon: String?
    let shortcut: KeyboardShortcut?
    let category: CommandCategory
    let source: String
    let action: () -> Void

    init(
        id: String,
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        shortcut: KeyboardShortcut? = nil,
        category: CommandCategory = .general,
        source: String = "builtin",
        action: @escaping () -> Void
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.shortcut = shortcut
        self.category = category
        self.source = source
        self.action = action
    }

    static func == (lhs: Command, rhs: Command) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Command Category

enum CommandCategory: String, CaseIterable {
    case file = "File"
    case edit = "Edit"
    case view = "View"
    case insert = "Insert"
    case export = "Export"
    case git = "Git"
    case general = "General"

    var icon: String {
        switch self {
        case .file: return "doc"
        case .edit: return "pencil"
        case .view: return "eye"
        case .insert: return "plus.square"
        case .export: return "square.and.arrow.up"
        case .git: return "arrow.triangle.branch"
        case .general: return "command"
        }
    }
}

// MARK: - Command Service

@MainActor
class CommandService: ObservableObject {
    static let shared = CommandService()

    @Published private(set) var commands: [Command] = []
    @Published var recentCommandIds: [String] = []

    private let maxRecent = 5

    private init() {
        loadRecentCommands()
    }

    func register(_ command: Command) {
        if !commands.contains(where: { $0.id == command.id }) {
            commands.append(command)
        }
    }

    func register(_ commands: [Command]) {
        for command in commands {
            register(command)
        }
    }

    /// Unregister all commands from a specific source (plugin)
    func unregister(source: String) {
        commands.removeAll { $0.source == source }
    }

    func execute(_ command: Command) {
        command.action()
        addToRecent(command.id)
    }

    func search(_ query: String) -> [Command] {
        if query.isEmpty {
            let recentCommands = recentCommandIds.compactMap { id in
                commands.first { $0.id == id }
            }
            let otherCommands = commands.filter { !recentCommandIds.contains($0.id) }
            return recentCommands + otherCommands
        }

        let lowercaseQuery = query.lowercased()

        return commands
            .map { command -> (Command, Int) in
                let score = fuzzyScore(query: lowercaseQuery, target: command.title.lowercased())
                return (command, score)
            }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
    }

    private func fuzzyScore(query: String, target: String) -> Int {
        var score = 0
        var queryIndex = query.startIndex
        var targetIndex = target.startIndex
        var consecutiveBonus = 0

        while queryIndex < query.endIndex && targetIndex < target.endIndex {
            if query[queryIndex] == target[targetIndex] {
                score += 1 + consecutiveBonus
                consecutiveBonus += 1
                queryIndex = query.index(after: queryIndex)

                if targetIndex == target.startIndex ||
                   target[target.index(before: targetIndex)] == " " {
                    score += 5
                }
            } else {
                consecutiveBonus = 0
            }
            targetIndex = target.index(after: targetIndex)
        }

        return queryIndex == query.endIndex ? score : 0
    }

    private func addToRecent(_ commandId: String) {
        recentCommandIds.removeAll { $0 == commandId }
        recentCommandIds.insert(commandId, at: 0)
        if recentCommandIds.count > maxRecent {
            recentCommandIds = Array(recentCommandIds.prefix(maxRecent))
        }
        saveRecentCommands()
    }

    private func loadRecentCommands() {
        if let ids = UserDefaults.standard.stringArray(forKey: "recentCommands") {
            recentCommandIds = ids
        }
    }

    private func saveRecentCommands() {
        UserDefaults.standard.set(recentCommandIds, forKey: "recentCommands")
    }
}
