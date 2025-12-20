//
//  PluginInstaller.swift
//  tibok
//
//  Service for installing third-party plugins from folders or ZIP files.
//
//  MIT License - See LICENSE file in Plugins directory
//

import Foundation
import AppKit
import UniformTypeIdentifiers

/// Errors that can occur during plugin installation
enum PluginInstallationError: LocalizedError {
    case cancelled
    case extractionFailed(String)
    case invalidPlugin(String)
    case manifestReadFailed
    case installationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .cancelled:
            return "Installation cancelled"
        case .extractionFailed(let message):
            return "Failed to extract ZIP: \(message)"
        case .invalidPlugin(let message):
            return "Invalid plugin: \(message)"
        case .manifestReadFailed:
            return "Failed to read plugin manifest"
        case .installationFailed(let message):
            return "Failed to install plugin: \(message)"
        }
    }
}

/// Service for installing third-party plugins
@MainActor
final class PluginInstaller {
    static let shared = PluginInstaller()
    
    private init() {}
    
    /// Show file picker and install selected plugin
    /// Returns success message or error
    func installPlugin() async -> Result<String, Error> {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            .folder,
            .zip,
            UTType(filenameExtension: "zip")!
        ]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.title = "Select Plugin Folder or ZIP File"
        panel.message = "Choose a plugin folder or ZIP archive to install"
        
        guard panel.runModal() == .OK, let selectedURL = panel.url else {
            return .failure(PluginInstallationError.cancelled)
        }
        
        return await installPlugin(from: selectedURL)
    }
    
    /// Install plugin from a URL (folder or ZIP)
    func installPlugin(from sourceURL: URL) async -> Result<String, Error> {
        // Determine if it's a ZIP file or folder
        let isZIP = sourceURL.pathExtension.lowercased() == "zip"
        
        // If ZIP, extract it first
        let pluginFolder: URL
        if isZIP {
            // Extract ZIP to temporary directory
            let tempDir = FileManager.default.temporaryDirectory
                .appendingPathComponent("tibok-plugin-install-\(UUID().uuidString)")
            
            do {
                try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
                
                // Extract ZIP using system unzip command
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
                process.arguments = [
                    "-q", // Quiet mode
                    "-o", // Overwrite files
                    sourceURL.path,
                    "-d", tempDir.path
                ]
                
                try process.run()
                process.waitUntilExit()
                
                guard process.terminationStatus == 0 else {
                    try? FileManager.default.removeItem(at: tempDir)
                    return .failure(PluginInstallationError.extractionFailed("unzip command failed"))
                }
                
                // Find the plugin folder inside extracted contents
                // Check if tempDir itself contains manifest.json (files at root)
                let rootManifest = tempDir.appendingPathComponent("manifest.json")
                var foundPluginFolder: URL?
                
                if FileManager.default.fileExists(atPath: rootManifest.path) {
                    // Files are at the root of the ZIP
                    foundPluginFolder = tempDir
                } else {
                    // Look for folder containing manifest.json
                    let contents = try FileManager.default.contentsOfDirectory(
                        at: tempDir,
                        includingPropertiesForKeys: [.isDirectoryKey]
                    )
                    
                    for item in contents {
                        let resourceValues = try? item.resourceValues(forKeys: [.isDirectoryKey])
                        guard resourceValues?.isDirectory == true else { continue }
                        
                        let manifestPath = item.appendingPathComponent("manifest.json")
                        if FileManager.default.fileExists(atPath: manifestPath.path) {
                            foundPluginFolder = item
                            break
                        }
                    }
                    
                    // If still not found and there's only one folder, assume it's the plugin
                    if foundPluginFolder == nil, contents.count == 1,
                       let first = contents.first,
                       (try? first.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
                        // Check if this folder contains manifest.json
                        let nestedManifest = first.appendingPathComponent("manifest.json")
                        if FileManager.default.fileExists(atPath: nestedManifest.path) {
                            foundPluginFolder = first
                        }
                    }
                }
                
                guard let folder = foundPluginFolder else {
                    try? FileManager.default.removeItem(at: tempDir)
                    return .failure(PluginInstallationError.extractionFailed("Could not find plugin folder in ZIP. Expected a folder containing manifest.json"))
                }
                
                pluginFolder = folder
            } catch {
                try? FileManager.default.removeItem(at: tempDir)
                return .failure(PluginInstallationError.extractionFailed(error.localizedDescription))
            }
        } else {
            // It's a folder
            pluginFolder = sourceURL
        }
        
        // Validate plugin structure
        let validation = PluginDiscovery.verifyPluginStructure(at: pluginFolder)
        guard validation.isValid else {
            if isZIP {
                try? FileManager.default.removeItem(at: pluginFolder.deletingLastPathComponent())
            }
            return .failure(PluginInstallationError.invalidPlugin(validation.errors.joined(separator: ", ")))
        }
        
        // Load manifest to get plugin identifier
        let manifestPath = PluginDiscovery.getManifestPath(for: pluginFolder)
        guard let manifestData = try? Data(contentsOf: manifestPath),
              let manifest = try? JSONDecoder().decode(PluginManifest.self, from: manifestData) else {
            if isZIP {
                try? FileManager.default.removeItem(at: pluginFolder.deletingLastPathComponent())
            }
            return .failure(PluginInstallationError.manifestReadFailed)
        }
        
        // Check if plugin already exists
        let targetFolder = PluginDiscovery.Folders.thirdParty
            .appendingPathComponent(manifest.identifier)
        
        if FileManager.default.fileExists(atPath: targetFolder.path) {
            // Ask user if they want to replace
            let alert = NSAlert()
            alert.messageText = "Plugin Already Installed"
            alert.informativeText = "A plugin with identifier '\(manifest.identifier)' is already installed. Do you want to replace it?"
            alert.addButton(withTitle: "Replace")
            alert.addButton(withTitle: "Cancel")
            alert.alertStyle = .warning
            
            guard alert.runModal() == .alertFirstButtonReturn else {
                if isZIP {
                    try? FileManager.default.removeItem(at: pluginFolder.deletingLastPathComponent())
                }
                return .failure(PluginInstallationError.cancelled)
            }
            
            // Remove existing plugin
            try? FileManager.default.removeItem(at: targetFolder)
        }
        
        // Ensure ThirdParty folder exists
        PluginDiscovery.Folders.ensureDirectoriesExist()
        
        // Copy plugin to ThirdParty folder
        do {
            try FileManager.default.copyItem(at: pluginFolder, to: targetFolder)
            
            // Clean up temporary directory if we extracted a ZIP
            if isZIP {
                try? FileManager.default.removeItem(at: pluginFolder.deletingLastPathComponent())
            }
            
            // Reload plugin discovery
            PluginManager.shared.reloadDiscovery()
            
            return .success("Plugin '\(manifest.name)' installed successfully")
        } catch {
            if isZIP {
                try? FileManager.default.removeItem(at: pluginFolder.deletingLastPathComponent())
            }
            return .failure(PluginInstallationError.installationFailed(error.localizedDescription))
        }
    }
}

