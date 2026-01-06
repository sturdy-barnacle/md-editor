//
//  PermissionApprovalView.swift
//  tibok
//
//  UI for approving plugin permissions before installation/enabling.
//
//  MIT License
//

import SwiftUI

/// View for displaying and approving plugin permissions
struct PermissionApprovalView: View {
    let request: PermissionApprovalRequest
    let onApprove: () -> Void
    let onDeny: () -> Void

    @State private var hasAcknowledged = false

    private var manifest: PluginManifest { request.manifest }
    private var permissions: PluginPermissionSet { request.permissions }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            Divider()

            // Permissions list
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    permissionsSection

                    if permissions.hasElevatedPermissions {
                        warningSection
                    }

                    pluginInfoSection
                }
                .padding(20)
            }

            Divider()

            // Footer with actions
            footerSection
        }
        .frame(width: 480, height: 520)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: manifest.iconName)
                .font(.system(size: 48))
                .foregroundColor(.accentColor)

            Text("Install \"\(manifest.name)\"?")
                .font(.title2)
                .fontWeight(.semibold)

            trustTierBadge
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private var trustTierBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: manifest.resolvedTrustTier.icon)
            Text(manifest.resolvedTrustTier.displayName)
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(trustTierColor.opacity(0.15))
        .foregroundColor(trustTierColor)
        .cornerRadius(12)
    }

    private var trustTierColor: Color {
        switch manifest.resolvedTrustTier {
        case .official: return .blue
        case .verified: return .green
        case .community: return .orange
        }
    }

    // MARK: - Permissions Section

    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This plugin requests the following permissions:")
                .font(.headline)

            VStack(spacing: 8) {
                // Safe permissions first
                ForEach(permissions.safePermissions, id: \.self) { permission in
                    PermissionRow(permission: permission)
                }

                // Then elevated permissions
                ForEach(permissions.elevatedPermissions, id: \.self) { permission in
                    PermissionRow(permission: permission)
                }
            }
        }
    }

    // MARK: - Warning Section

    private var warningSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Elevated Permissions")
                    .fontWeight(.semibold)
            }
            .font(.subheadline)

            Text("This plugin requests elevated permissions that could access your files or network. Only install if you trust the source.")
                .font(.caption)
                .foregroundColor(.secondary)

            if manifest.resolvedTrustTier == .community {
                acknowledgmentCheckbox
            }
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }

    private var acknowledgmentCheckbox: some View {
        Toggle(isOn: $hasAcknowledged) {
            Text("I understand this is a community plugin that has not been verified")
                .font(.caption)
        }
        .toggleStyle(.checkbox)
        .padding(.top, 4)
    }

    // MARK: - Plugin Info Section

    private var pluginInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About this plugin")
                .font(.headline)

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
                GridRow {
                    Text("Version:")
                        .foregroundColor(.secondary)
                    Text(manifest.version)
                }

                if let author = manifest.resolvedAuthorName {
                    GridRow {
                        Text("Author:")
                            .foregroundColor(.secondary)
                        Text(author)
                    }
                }

                GridRow {
                    Text("Type:")
                        .foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: manifest.resolvedPluginType.icon)
                        Text(manifest.resolvedPluginType.displayName)
                    }
                }

                if let repository = manifest.repository {
                    GridRow {
                        Text("Source:")
                            .foregroundColor(.secondary)
                        Link(repositoryDisplayName(repository), destination: URL(string: repository)!)
                    }
                }
            }
            .font(.caption)

            if let description = manifest.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }

    private func repositoryDisplayName(_ url: String) -> String {
        if url.contains("github.com") {
            return url.replacingOccurrences(of: "https://github.com/", with: "")
        }
        return url
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack(spacing: 12) {
            Button("Cancel") {
                onDeny()
            }
            .keyboardShortcut(.escape)

            Spacer()

            Button("Install") {
                onApprove()
            }
            .keyboardShortcut(.return)
            .buttonStyle(.borderedProminent)
            .disabled(needsAcknowledgment && !hasAcknowledged)
        }
        .padding(16)
    }

    private var needsAcknowledgment: Bool {
        manifest.resolvedTrustTier == .community && permissions.hasElevatedPermissions
    }
}

// MARK: - Permission Row

struct PermissionRow: View {
    let permission: PluginPermission

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: permission.icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(permission.displayName)
                    .fontWeight(.medium)
                Text(permission.userDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            riskIndicator
        }
        .padding(10)
        .background(backgroundColor)
        .cornerRadius(8)
    }

    private var iconColor: Color {
        switch permission.riskLevel {
        case .safe: return .green
        case .moderate: return .orange
        case .high: return .red
        }
    }

    private var backgroundColor: Color {
        switch permission.riskLevel {
        case .safe: return Color(NSColor.controlBackgroundColor)
        case .moderate: return Color.orange.opacity(0.05)
        case .high: return Color.red.opacity(0.05)
        }
    }

    @ViewBuilder
    private var riskIndicator: some View {
        switch permission.riskLevel {
        case .safe:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .moderate:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
        case .high:
            Image(systemName: "exclamationmark.octagon.fill")
                .foregroundColor(.red)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct PermissionApprovalView_Previews: PreviewProvider {
    static var previews: some View {
        let manifest = PluginManifest(
            identifier: "com.example.test-plugin",
            name: "Test Plugin",
            version: "1.0.0",
            description: "A test plugin for demonstrating the permission approval UI.",
            icon: "sparkle",
            author: "Test Author",
            authorInfo: nil,
            minimumTibokVersion: "1.0.0",
            pluginType: .script,
            permissions: ["slash-commands", "command-palette", "network-access"],
            trustTier: .community,
            signature: nil,
            capabilities: nil,
            entryPoint: nil,
            configSchema: nil,
            homepage: nil,
            repository: "https://github.com/example/test-plugin",
            license: "MIT",
            keywords: nil
        )

        let request = PermissionApprovalRequest(manifest: manifest)

        return PermissionApprovalView(
            request: request,
            onApprove: { print("Approved") },
            onDeny: { print("Denied") }
        )
    }
}
#endif
