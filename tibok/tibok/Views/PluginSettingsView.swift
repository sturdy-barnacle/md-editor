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
    @ObservedObject var uiState = UIStateService.shared
    @State private var isInstalling = false

    private var plugins: [PluginDisplayInfo] {
        var allPlugins: [PluginDisplayInfo] = []
        
        // Add built-in plugins
        for pluginType in pluginManager.availablePluginTypes {
            allPlugins.append(PluginDisplayInfo(
                id: pluginType.identifier,
                identifier: pluginType.identifier,
                name: pluginType.name,
                version: pluginType.version,
                description: pluginType.description,
                icon: pluginType.icon,
                author: pluginType.author,
                isLoaded: pluginManager.isLoaded(pluginType.identifier)
            ))
        }
        
        // Add discovered third-party plugins
        for (type, manifest, source, isLoaded) in pluginManager.allPluginInfo {
            // Skip if already added as built-in
            if type != nil { continue }
            
            guard let manifest = manifest else { continue }
            
            allPlugins.append(PluginDisplayInfo(
                id: manifest.identifier,
                identifier: manifest.identifier,
                name: manifest.name,
                version: manifest.version,
                description: manifest.description,
                icon: manifest.iconName,
                author: manifest.author,
                isLoaded: isLoaded
            ))
        }
        
        return allPlugins
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
                Button(action: installPlugin) {
                    HStack {
                        if isInstalling {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 16, height: 16)
                        } else {
                            Image(systemName: "plus.circle.fill")
                        }
                        Text("Install Plugin...")
                    }
                }
                .disabled(isInstalling)
                .help("Install a plugin from a folder or ZIP file")
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
    
    private func installPlugin() {
        guard !isInstalling else { return }
        isInstalling = true
        
        Task {
            let result = await PluginInstaller.shared.installPlugin()
            
            await MainActor.run {
                isInstalling = false
                
                switch result {
                case .success(let message):
                    uiState.showToast(message, icon: "checkmark.circle.fill", duration: 2.0)
                case .failure(let error):
                    uiState.showToast(error, icon: "exclamationmark.triangle.fill", duration: 3.0)
                }
            }
        }
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

            // Check if plugin has an error
            if let error = PluginManager.shared.pluginErrors[plugin.identifier] {
                VStack(alignment: .trailing, spacing: 2) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Error")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
                .help(error.localizedDescription)
            } else {
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
        }
        .padding(.vertical, 4)
    }
}
