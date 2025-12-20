//
//  PluginDiscovery.swift
//  tibok
//
//  Plugin discovery from file system folders.
//
//  MIT License - See LICENSE file in Plugins directory
//

import Foundation

/// Handles discovery and loading of plugin manifests from folders.
struct PluginDiscovery {
    /// Standard plugin folders
    struct Folders {
        /// Built-in plugins folder: ~/Library/Application Support/tibok/Plugins/BuiltIn
        /// Contains plugins that ship with tibok
        static let builtIn: URL = {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            return appSupport.appendingPathComponent("tibok/Plugins/BuiltIn")
        }()

        /// Third-party plugins folder: ~/Library/Application Support/tibok/Plugins/ThirdParty
        /// Users can install community-created plugins here
        static let thirdParty: URL = {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            return appSupport.appendingPathComponent("tibok/Plugins/ThirdParty")
        }()

        /// Create all necessary plugin directories if they don't exist
        static func ensureDirectoriesExist() {
            for folder in [builtIn, thirdParty] {
                try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            }
        }
    }

    /// Manifest file name
    private static let manifestFileName = "manifest.json"

    /// Discover all plugin manifests from plugin folders
    static func discoverAllManifests() -> [(url: URL, manifest: PluginManifest, source: PluginSource)] {
        var manifests: [(url: URL, manifest: PluginManifest, source: PluginSource)] = []

        // Discover from built-in and third-party folders
        manifests.append(contentsOf: discoverManifests(in: Folders.builtIn, source: .builtin))
        manifests.append(contentsOf: discoverManifests(in: Folders.thirdParty, source: .thirdParty))

        return manifests
    }

    /// Discover plugin manifests in a specific folder
    static func discoverManifests(in folder: URL, source: PluginSource) -> [(url: URL, manifest: PluginManifest, source: PluginSource)] {
        guard FileManager.default.fileExists(atPath: folder.path) else {
            return []
        }

        var manifests: [(url: URL, manifest: PluginManifest, source: PluginSource)] = []

        do {
            let contents = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)

            // Look for manifest.json files in subdirectories and root
            for item in contents {
                let manifestPath = item.appendingPathComponent(manifestFileName)
                let manifestAtRoot = item.appendingPathComponent("manifest.json")

                if FileManager.default.fileExists(atPath: manifestPath.path) {
                    if let manifest = loadManifest(from: manifestPath) {
                        manifests.append((url: item, manifest: manifest, source: source))
                    }
                } else if FileManager.default.fileExists(atPath: manifestAtRoot.path) {
                    if let manifest = loadManifest(from: manifestAtRoot) {
                        manifests.append((url: item, manifest: manifest, source: source))
                    }
                }
            }

            // Also check root folder for manifest.json
            let rootManifest = folder.appendingPathComponent(manifestFileName)
            if FileManager.default.fileExists(atPath: rootManifest.path) {
                if let manifest = loadManifest(from: rootManifest) {
                    manifests.append((url: folder, manifest: manifest, source: source))
                }
            }
        } catch {
            print("Error discovering plugins in \(folder.path): \(error)")
        }

        return manifests
    }

    /// Load a manifest from a JSON file
    private static func loadManifest(from url: URL) -> PluginManifest? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let manifest = try decoder.decode(PluginManifest.self, from: data)

            guard manifest.isValid() else {
                print("Invalid manifest at \(url.path): missing required fields")
                return nil
            }

            return manifest
        } catch {
            print("Error loading manifest from \(url.path): \(error)")
            return nil
        }
    }

    /// Get manifest file URL for a plugin directory
    static func getManifestPath(for pluginDirectory: URL) -> URL {
        let manifestInRoot = pluginDirectory.appendingPathComponent(manifestFileName)
        if FileManager.default.fileExists(atPath: manifestInRoot.path) {
            return manifestInRoot
        }

        // Fallback to subdirectory
        return pluginDirectory.appendingPathComponent(manifestFileName)
    }

    /// Verify plugin folder structure
    /// Returns (isValid, errors)
    static func verifyPluginStructure(at path: URL) -> (isValid: Bool, errors: [String]) {
        var errors: [String] = []

        // Check for manifest
        let manifestPath = getManifestPath(for: path)
        if !FileManager.default.fileExists(atPath: manifestPath.path) {
            errors.append("Missing manifest.json")
        }

        // Check for expected structure based on manifest
        if let manifest = loadManifest(from: manifestPath) {
            if let entryPoint = manifest.entryPoint {
                if let framework = entryPoint.framework {
                    let frameworkPath = path.appendingPathComponent("\(framework).framework")
                    if !FileManager.default.fileExists(atPath: frameworkPath.path) {
                        errors.append("Framework '\(framework).framework' not found")
                    }
                }

                if let script = entryPoint.script {
                    let scriptPath = path.appendingPathComponent(script)
                    if !FileManager.default.fileExists(atPath: scriptPath.path) {
                        errors.append("Script '\(script)' not found")
                    }
                }
            }
        }

        return (errors.isEmpty, errors)
    }
}

/// Source of a plugin
enum PluginSource: String, Codable {
    case builtin = "builtin"
    case thirdParty = "thirdparty"

    var displayName: String {
        switch self {
        case .builtin:
            return "Built-in"
        case .thirdParty:
            return "Community"
        }
    }

    var description: String {
        switch self {
        case .builtin:
            return "Included with tibok"
        case .thirdParty:
            return "Community-created plugins"
        }
    }
}
