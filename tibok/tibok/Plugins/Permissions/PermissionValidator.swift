//
//  PermissionValidator.swift
//  tibok
//
//  Validates and tracks user approval of plugin permissions.
//
//  MIT License - See LICENSE file in Plugins directory
//

import Foundation

/// Manages validation and user approval of plugin permissions.
@MainActor
final class PermissionValidator: ObservableObject {
    static let shared = PermissionValidator()

    /// Key prefix for storing permission approvals in UserDefaults
    private let approvalKeyPrefix = "plugin.permissions.approved."

    /// Plugins pending permission approval
    @Published private(set) var pendingApprovals: [String: PluginPermissionSet] = [:]

    private init() {}

    // MARK: - Permission Checking

    /// Check if a plugin's permissions have been approved by the user
    func isApproved(pluginId: String, permissions: PluginPermissionSet) -> Bool {
        // Official plugins are always approved
        // Verified plugins with only safe permissions are auto-approved
        // All others need explicit user approval

        guard let approvedPermissions = getApprovedPermissions(for: pluginId) else {
            // Never approved - needs approval
            return false
        }

        // Check if all requested permissions are in the approved set
        return permissions.permissions.isSubset(of: approvedPermissions.permissions)
    }

    /// Check if a manifest's permissions are approved
    func isApproved(manifest: PluginManifest) -> Bool {
        // Official plugins are always approved
        if manifest.resolvedTrustTier == .official {
            return true
        }

        // Verified plugins with only safe permissions are auto-approved
        if manifest.resolvedTrustTier == .verified && !manifest.hasElevatedPermissions {
            return true
        }

        return isApproved(pluginId: manifest.identifier, permissions: manifest.permissionSet)
    }

    /// Get the approved permissions for a plugin (if any)
    func getApprovedPermissions(for pluginId: String) -> PluginPermissionSet? {
        let key = approvalKeyPrefix + pluginId

        guard let data = UserDefaults.standard.data(forKey: key) else {
            return nil
        }

        do {
            let permissions = try JSONDecoder().decode([String].self, from: data)
            let parsed = permissions.compactMap { PluginPermission(rawValue: $0) }
            return PluginPermissionSet(parsed)
        } catch {
            print("Failed to decode approved permissions for \(pluginId): \(error)")
            return nil
        }
    }

    // MARK: - Permission Approval

    /// Record user approval for a plugin's permissions
    func approvePermissions(for pluginId: String, permissions: PluginPermissionSet) {
        let key = approvalKeyPrefix + pluginId
        let permissionStrings = permissions.permissions.map { $0.rawValue }

        do {
            let data = try JSONEncoder().encode(permissionStrings)
            UserDefaults.standard.set(data, forKey: key)
            pendingApprovals.removeValue(forKey: pluginId)
        } catch {
            print("Failed to save approved permissions for \(pluginId): \(error)")
        }
    }

    /// Revoke permission approval for a plugin
    func revokeApproval(for pluginId: String) {
        let key = approvalKeyPrefix + pluginId
        UserDefaults.standard.removeObject(forKey: key)
    }

    /// Request approval for a plugin (adds to pending queue)
    func requestApproval(for pluginId: String, permissions: PluginPermissionSet) {
        pendingApprovals[pluginId] = permissions
    }

    /// Cancel a pending approval request
    func cancelApprovalRequest(for pluginId: String) {
        pendingApprovals.removeValue(forKey: pluginId)
    }

    // MARK: - Validation

    /// Validate a plugin can be loaded based on its permissions and type
    func validateForLoading(manifest: PluginManifest) -> PermissionValidationResult {
        let permissions = manifest.permissionSet

        // Check if script plugin is requesting elevated permissions
        if manifest.resolvedPluginType == .script && permissions.hasElevatedPermissions {
            return .denied(reason: .scriptElevatedPermissions(permissions.elevatedPermissions))
        }

        // Check if permissions are approved
        if !isApproved(manifest: manifest) {
            return .needsApproval(permissions: permissions)
        }

        return .approved
    }

    /// Validate a specific permission is granted to a plugin
    func hasPermission(_ permission: PluginPermission, for pluginId: String) -> Bool {
        guard let approved = getApprovedPermissions(for: pluginId) else {
            return false
        }
        return approved.has(permission)
    }

    // MARK: - Migration

    /// Migrate old capabilities to new permissions format
    func migrateCapabilities(_ capabilities: [String]) -> [PluginPermission] {
        // Map old capability names to new permission names
        let mapping: [String: PluginPermission] = [
            "slash-commands": .slashCommands,
            "command-palette": .commandPalette,
            "export": .writeDocument,
            "webhooks": .networkAccess,
            "read-document": .readCurrentDocument,
            "write-document": .writeDocument,
            "workspace": .workspaceAccess,
            "network": .networkAccess,
            "filesystem": .fileSystemAccess,
            "process": .executeProcess,
        ]

        return capabilities.compactMap { mapping[$0] }
    }
}

// MARK: - Validation Result

/// Result of permission validation
enum PermissionValidationResult {
    /// Plugin has all required permissions approved
    case approved

    /// Plugin needs user approval for its permissions
    case needsApproval(permissions: PluginPermissionSet)

    /// Plugin cannot be loaded due to permission issues
    case denied(reason: PermissionDenialReason)

    var isApproved: Bool {
        if case .approved = self { return true }
        return false
    }
}

/// Reason why a plugin was denied loading
enum PermissionDenialReason {
    /// Script plugin requested elevated permissions (not allowed)
    case scriptElevatedPermissions([PluginPermission])

    /// Plugin version mismatch or incompatibility
    case incompatibleVersion(required: String, current: String)

    /// Signature verification failed
    case signatureInvalid

    /// Other reason
    case other(String)

    var localizedDescription: String {
        switch self {
        case .scriptElevatedPermissions(let permissions):
            let names = permissions.map { $0.displayName }.joined(separator: ", ")
            return "Script plugins cannot request elevated permissions: \(names)"
        case .incompatibleVersion(let required, let current):
            return "Plugin requires Tibok \(required) or later (current: \(current))"
        case .signatureInvalid:
            return "Plugin signature verification failed"
        case .other(let message):
            return message
        }
    }
}

// MARK: - Permission Request

/// A request for permission approval
struct PermissionApprovalRequest: Identifiable {
    let id: String  // Plugin identifier
    let manifest: PluginManifest
    let permissions: PluginPermissionSet

    /// Callback when approval is granted
    var onApprove: (() -> Void)?

    /// Callback when approval is denied
    var onDeny: (() -> Void)?

    init(manifest: PluginManifest, onApprove: (() -> Void)? = nil, onDeny: (() -> Void)? = nil) {
        self.id = manifest.identifier
        self.manifest = manifest
        self.permissions = manifest.permissionSet
        self.onApprove = onApprove
        self.onDeny = onDeny
    }
}
