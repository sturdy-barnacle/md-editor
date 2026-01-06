//
//  GitModels.swift
//  tibok
//
//  Git-related data models
//

import Foundation

// MARK: - Git File Status

enum GitFileStatus: Hashable {
    case untracked      // ? - New file not in git
    case modified       // M - Modified in working tree (unstaged)
    case added          // A - Staged new file
    case deleted        // D - Deleted
    case renamed        // R - Renamed
    case copied         // C - Copied
    case unmerged       // U - Conflict
    case ignored        // ! - In .gitignore
    case staged         // Staged modification
    case stagedDeleted  // Staged deletion
    case clean          // No changes

    var color: String {
        switch self {
        case .modified: return "blue"
        case .added, .staged: return "green"
        case .untracked: return "yellow"
        case .unmerged: return "red"
        case .deleted, .stagedDeleted: return "gray"
        default: return "clear"
        }
    }

    var displayName: String {
        switch self {
        case .untracked: return "Untracked"
        case .modified: return "Modified"
        case .added: return "Added"
        case .deleted: return "Deleted"
        case .renamed: return "Renamed"
        case .copied: return "Copied"
        case .unmerged: return "Conflict"
        case .ignored: return "Ignored"
        case .staged: return "Staged"
        case .stagedDeleted: return "Deleted (staged)"
        case .clean: return "Clean"
        }
    }

    var isStaged: Bool {
        switch self {
        case .added, .staged, .stagedDeleted, .renamed, .copied:
            return true
        default:
            return false
        }
    }
}

// MARK: - Git Changed File

struct GitChangedFile: Identifiable, Hashable {
    let id: URL
    let url: URL
    let filename: String
    let status: GitFileStatus
    let isStaged: Bool

    init(url: URL, status: GitFileStatus, isStaged: Bool) {
        self.id = url
        self.url = url
        self.filename = url.lastPathComponent
        self.status = status
        self.isStaged = isStaged
    }
}

// MARK: - Git Commit

/// Represents a git commit
struct GitCommit: Identifiable, Hashable {
    let id: String // Same as hash
    let hash: String
    let shortHash: String
    let author: String
    let email: String
    let date: Date
    let message: String

    init(hash: String, shortHash: String, author: String, email: String, date: Date, message: String) {
        self.id = hash
        self.hash = hash
        self.shortHash = shortHash
        self.author = author
        self.email = email
        self.date = date
        self.message = message
    }
}
