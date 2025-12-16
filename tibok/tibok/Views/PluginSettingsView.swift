//
//  PluginSettingsView.swift
//  tibok
//
//  Settings view for managing plugins.
//

import SwiftUI
import AppKit

/// Display info for a plugin in the settings UI
struct PluginDisplayInfo: Identifiable {
    let id: String
    let identifier: String
    let name: String
    let version: String
    let description: String?
    let icon: String
    let author: String?
    let isLoaded: Bool
}

struct PluginSettingsView: View {
    @ObservedObject var pluginManager = PluginManager.shared
    @ObservedObject var stateManager = PluginStateManager.shared

    private var plugins: [PluginDisplayInfo] {
        pluginManager.availablePluginTypes.map { pluginType in
            PluginDisplayInfo(
                id: pluginType.identifier,
                identifier: pluginType.identifier,
                name: pluginType.name,
                version: pluginType.version,
                description: pluginType.description,
                icon: pluginType.icon,
                author: pluginType.author,
                isLoaded: pluginManager.isLoaded(pluginType.identifier)
            )
        }
    }

    var body: some View {
        Form {
            Section("Installed Plugins") {
                if plugins.isEmpty {
                    Text("No plugins installed")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(plugins) { plugin in
                        PluginRow(plugin: plugin)
                    }
                }
            }

            Section {
                Text("Plugins extend tibok with additional commands and features. Disable a plugin to remove its contributions.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct PluginRow: View {
    let plugin: PluginDisplayInfo
    @ObservedObject var stateManager = PluginStateManager.shared

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: plugin.icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(plugin.name)
                    .fontWeight(.medium)
                if let desc = plugin.description {
                    Text(desc)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                if let author = plugin.author {
                    Text("by \(author)")
                        .font(.caption2)
                        .foregroundColor(Color(NSColor.tertiaryLabelColor))
                }
            }

            Spacer()

            Text("v\(plugin.version)")
                .font(.caption)
                .foregroundColor(.secondary)

            Toggle("", isOn: Binding(
                get: { stateManager.isEnabled(plugin.identifier) },
                set: { enabled in
                    if enabled {
                        PluginManager.shared.enablePlugin(plugin.identifier)
                    } else {
                        PluginManager.shared.disablePlugin(plugin.identifier)
                    }
                }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}
