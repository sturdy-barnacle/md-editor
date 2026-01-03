//
//  PluginPermission.swift
//  tibok
//
//  Defines all available plugin permissions and their metadata.
//
//  MIT License - See LICENSE file in Plugins directory
//

import Foundation

/// All available permissions that plugins can request.
/// Permissions are divided into safe (script-compatible) and elevated (native-only) tiers.
enum PluginPermission: String, Codable, CaseIterable, Hashable {

    // MARK: - Safe Permissions (Script plugins can use these)

    /// Register slash commands in the editor (e.g., /table, /code)
    case slashCommands = "slash-commands"

    /// Add commands to the command palette (Cmd+K)
    case commandPalette = "command-palette"

    /// Read the current document's content (read-only)
    case readCurrentDocument = "read-current-document"

    /// Insert text at the current cursor position
    case insertText = "insert-text"

    /// Get information about the current selection
    case readSelection = "read-selection"

    /// Access document metadata (filename, path, frontmatter)
    case readDocumentMetadata = "read-document-metadata"

    // MARK: - Elevated Permissions (Native plugins only, require explicit consent)

    /// Modify document content (beyond just inserting at cursor)
    case writeDocument = "write-document"

    /// Access all files in the current workspace
    case workspaceAccess = "workspace-access"

    /// Make HTTP/HTTPS network requests
    case networkAccess = "network-access"

    /// Read/write files outside the current workspace
    case fileSystemAccess = "filesystem-access"

    /// Execute shell commands or external processes
    case executeProcess = "execute-process"

    /// Access system clipboard
    case clipboardAccess = "clipboard-access"

    /// Store persistent data (UserDefaults, files)
    case persistentStorage = "persistent-storage"

    // MARK: - Properties

    /// Whether this permission is safe for sandboxed script plugins
    var isSafe: Bool {
        switch self {
        case .slashCommands, .commandPalette, .readCurrentDocument,
             .insertText, .readSelection, .readDocumentMetadata:
            return true
        default:
            return false
        }
    }

    /// Whether this permission is elevated (requires native plugin or explicit consent)
    var isElevated: Bool {
        !isSafe
    }

    /// Human-readable name for display in UI
    var displayName: String {
        switch self {
        case .slashCommands: return "Slash Commands"
        case .commandPalette: return "Command Palette"
        case .readCurrentDocument: return "Read Document"
        case .insertText: return "Insert Text"
        case .readSelection: return "Read Selection"
        case .readDocumentMetadata: return "Document Metadata"
        case .writeDocument: return "Write Document"
        case .workspaceAccess: return "Workspace Access"
        case .networkAccess: return "Network Access"
        case .fileSystemAccess: return "File System Access"
        case .executeProcess: return "Execute Processes"
        case .clipboardAccess: return "Clipboard Access"
        case .persistentStorage: return "Persistent Storage"
        }
    }

    /// Description of what this permission allows
    var userDescription: String {
        switch self {
        case .slashCommands:
            return "Register slash commands that appear when typing '/' in the editor"
        case .commandPalette:
            return "Add commands to the command palette (Cmd+K)"
        case .readCurrentDocument:
            return "Read the content of the currently open document"
        case .insertText:
            return "Insert text at the current cursor position"
        case .readSelection:
            return "Access the currently selected text"
        case .readDocumentMetadata:
            return "Read document information like filename, path, and frontmatter"
        case .writeDocument:
            return "Modify the document content directly"
        case .workspaceAccess:
            return "Access and read all files in the current workspace folder"
        case .networkAccess:
            return "Make network requests to external servers"
        case .fileSystemAccess:
            return "Read and write files anywhere on your computer"
        case .executeProcess:
            return "Run shell commands and external programs"
        case .clipboardAccess:
            return "Read from and write to the system clipboard"
        case .persistentStorage:
            return "Store settings and data that persists between sessions"
        }
    }

    /// SF Symbol icon for this permission
    var icon: String {
        switch self {
        case .slashCommands: return "slash.circle"
        case .commandPalette: return "command"
        case .readCurrentDocument: return "doc.text"
        case .insertText: return "text.cursor"
        case .readSelection: return "text.badge.checkmark"
        case .readDocumentMetadata: return "info.circle"
        case .writeDocument: return "pencil"
        case .workspaceAccess: return "folder"
        case .networkAccess: return "network"
        case .fileSystemAccess: return "externaldrive"
        case .executeProcess: return "terminal"
        case .clipboardAccess: return "doc.on.clipboard"
        case .persistentStorage: return "internaldrive"
        }
    }

    /// Risk level for UI display (determines warning color)
    var riskLevel: PermissionRiskLevel {
        switch self {
        case .slashCommands, .commandPalette, .readCurrentDocument,
             .insertText, .readSelection, .readDocumentMetadata:
            return .safe
        case .writeDocument, .workspaceAccess, .clipboardAccess, .persistentStorage:
            return .moderate
        case .networkAccess, .fileSystemAccess, .executeProcess:
            return .high
        }
    }

    /// All safe permissions
    static var safePermissions: [PluginPermission] {
        allCases.filter { $0.isSafe }
    }

    /// All elevated permissions
    static var elevatedPermissions: [PluginPermission] {
        allCases.filter { $0.isElevated }
    }
}

// MARK: - Permission Risk Level

/// Risk level for permissions, used for UI styling
enum PermissionRiskLevel: String, Codable {
    case safe       // Green checkmark
    case moderate   // Yellow warning
    case high       // Red warning

    var color: String {
        switch self {
        case .safe: return "green"
        case .moderate: return "orange"
        case .high: return "red"
        }
    }

    var icon: String {
        switch self {
        case .safe: return "checkmark.circle.fill"
        case .moderate: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.octagon.fill"
        }
    }
}

// MARK: - Permission Set Helper

/// A set of permissions for a plugin
struct PluginPermissionSet: Codable, Hashable {
    let permissions: Set<PluginPermission>

    init(_ permissions: [PluginPermission]) {
        self.permissions = Set(permissions)
    }

    init(_ permissions: Set<PluginPermission>) {
        self.permissions = permissions
    }

    /// Check if this set contains a specific permission
    func has(_ permission: PluginPermission) -> Bool {
        permissions.contains(permission)
    }

    /// Check if any permission in this set is elevated
    var hasElevatedPermissions: Bool {
        permissions.contains { $0.isElevated }
    }

    /// Get all elevated permissions in this set
    var elevatedPermissions: [PluginPermission] {
        permissions.filter { $0.isElevated }.sorted { $0.rawValue < $1.rawValue }
    }

    /// Get all safe permissions in this set
    var safePermissions: [PluginPermission] {
        permissions.filter { $0.isSafe }.sorted { $0.rawValue < $1.rawValue }
    }

    /// Check if all permissions in this set are safe (suitable for script plugins)
    var isScriptCompatible: Bool {
        permissions.allSatisfy { $0.isSafe }
    }

    /// Maximum risk level among all permissions
    var maxRiskLevel: PermissionRiskLevel {
        if permissions.contains(where: { $0.riskLevel == .high }) {
            return .high
        } else if permissions.contains(where: { $0.riskLevel == .moderate }) {
            return .moderate
        }
        return .safe
    }
}
