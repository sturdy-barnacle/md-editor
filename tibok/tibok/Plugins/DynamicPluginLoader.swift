//
//  DynamicPluginLoader.swift
//  tibok
//
//  Service for dynamically loading Swift framework plugins at runtime.
//
//  MIT License - See LICENSE file in Plugins directory
//

import Foundation

/// Loads and manages dynamically loaded plugin frameworks.
@MainActor
final class DynamicPluginLoader {
    /// Maximum allowed framework size (100 MB)
    private static let maxFrameworkSize: Int64 = 100 * 1024 * 1024
    
    /// Track loaded bundles to prevent duplicate loads
    private var loadedBundles: [URL: Bundle] = [:]
    
    /// Load a plugin from a Swift framework.
    /// - Parameters:
    ///   - frameworkURL: URL to the .framework bundle
    ///   - className: Name of the plugin class (e.g., "MyPlugin" or "ModuleName.MyPlugin")
    ///   - identifier: Expected plugin identifier for validation
    /// - Returns: An instance of the plugin conforming to TibokPlugin
    /// - Throws: PluginLoadingError if loading fails
    func loadPlugin(
        from frameworkURL: URL,
        className: String,
        identifier: String
    ) throws -> any TibokPlugin {
        // Validate framework exists
        guard FileManager.default.fileExists(atPath: frameworkURL.path) else {
            throw PluginLoadingError.frameworkNotFound(frameworkURL.lastPathComponent)
        }
        
        // Validate framework location (security: only allow ThirdParty folder)
        try validateFrameworkLocation(frameworkURL)
        
        // Validate framework size
        try validateFrameworkSize(frameworkURL)
        
        // Validate framework architecture
        try validateFrameworkArchitecture(frameworkURL)
        
        // Load the bundle
        let bundle: Bundle
        if let existingBundle = loadedBundles[frameworkURL] {
            bundle = existingBundle
        } else {
            guard let loadedBundle = Bundle(url: frameworkURL) else {
                throw PluginLoadingError.frameworkLoadFailed(
                    frameworkURL,
                    NSError(domain: "tibok", code: -1, userInfo: [NSLocalizedDescriptionKey: "Bundle initialization failed"])
                )
            }
            
            // Load the bundle
            // Note: load() returns false if already loaded, which is fine
            if !loadedBundle.isLoaded {
                guard loadedBundle.load() else {
                    let error = NSError(
                        domain: "tibok",
                        code: -2,
                        userInfo: [
                            NSLocalizedDescriptionKey: "Bundle failed to load",
                            NSLocalizedFailureReasonErrorKey: "The framework bundle could not be loaded. It may be corrupted or incompatible."
                        ]
                    )
                    throw PluginLoadingError.frameworkLoadFailed(frameworkURL, error)
                }
            }
            
            loadedBundles[frameworkURL] = loadedBundle
            bundle = loadedBundle
        }
        
        // Resolve the plugin class
        guard let pluginClass = resolvePluginClass(className: className, bundle: bundle) else {
            throw PluginLoadingError.classNotFound(className)
        }
        
        // Validate the class conforms to TibokPlugin
        guard let pluginType = pluginClass as? any TibokPlugin.Type else {
            throw PluginLoadingError.invalidPluginType(className)
        }
        
        // Validate identifier matches
        guard pluginType.identifier == identifier else {
            throw PluginLoadingError.invalidPluginType(
                "Plugin identifier '\(pluginType.identifier)' does not match manifest identifier '\(identifier)'"
            )
        }
        
        // Instantiate the plugin
        do {
            let plugin = pluginType.init()
            return plugin
        } catch {
            throw PluginLoadingError.pluginInitializationFailed(error)
        }
    }
    
    /// Unload a framework (marks as unloaded, but framework may remain in memory).
    /// Note: macOS doesn't fully support unloading frameworks, so this is mainly for tracking.
    func unloadFramework(at url: URL) {
        loadedBundles.removeValue(forKey: url)
        // Note: We don't actually unload the bundle as macOS doesn't support it reliably
    }
    
    /// Check if a framework is currently loaded.
    func isFrameworkLoaded(at url: URL) -> Bool {
        return loadedBundles[url] != nil
    }
    
    // MARK: - Private Helpers
    
    /// Resolve a plugin class from a bundle.
    /// Tries multiple strategies to find the class.
    private func resolvePluginClass(className: String, bundle: Bundle) -> AnyClass? {
        // Strategy 1: Try with module name prefix
        if let moduleName = bundle.bundleIdentifier ?? bundle.infoDictionary?["CFBundleName"] as? String {
            let fullClassName = "\(moduleName).\(className)"
            if let cls = NSClassFromString(fullClassName) {
                return cls
            }
        }
        
        // Strategy 2: Try class name directly
        if let cls = NSClassFromString(className) {
            return cls
        }
        
        // Strategy 3: Try with bundle identifier as module
        if let bundleID = bundle.bundleIdentifier {
            let fullClassName = "\(bundleID).\(className)"
            if let cls = NSClassFromString(fullClassName) {
                return cls
            }
        }
        
        // Strategy 4: Try with framework name as module
        let frameworkName = bundle.bundleURL.deletingPathExtension().lastPathComponent
        let fullClassName = "\(frameworkName).\(className)"
        if let cls = NSClassFromString(fullClassName) {
            return cls
        }
        
        return nil
    }
    
    /// Validate framework is in allowed location (security check).
    private func validateFrameworkLocation(_ url: URL) throws {
        let thirdPartyFolder = PluginDiscovery.Folders.thirdParty
        let resolvedURL = url.resolvingSymlinksInPath()
        let resolvedThirdParty = thirdPartyFolder.resolvingSymlinksInPath()
        
        // Check if framework is within ThirdParty folder
        guard resolvedURL.path.hasPrefix(resolvedThirdParty.path) else {
            throw PluginLoadingError.invalidFrameworkLocation(url)
        }
    }
    
    /// Validate framework size (DoS protection).
    private func validateFrameworkSize(_ url: URL) throws {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        if let size = attributes[.size] as? Int64, size > Self.maxFrameworkSize {
            throw PluginLoadingError.frameworkTooLarge(size, Self.maxFrameworkSize)
        }
    }
    
    /// Validate framework architecture matches app architecture.
    private func validateFrameworkArchitecture(_ url: URL) throws {
        // Get app architecture
        #if arch(arm64)
        let appArch = "arm64"
        #elseif arch(x86_64)
        let appArch = "x86_64"
        #else
        let appArch = "unknown"
        #endif
        
        // Check framework binary
        let binaryPath = url.appendingPathComponent(url.deletingPathExtension().lastPathComponent)
        
        // Use file command to check architecture (if available)
        // For now, we'll be lenient and allow universal binaries
        // In the future, we can add more strict checking
        
        // Note: This is a simplified check. A more robust implementation would
        // use `lipo -info` or similar to check architectures.
        // For v1.1, we'll allow the load and let the system handle architecture mismatches.
    }
}

