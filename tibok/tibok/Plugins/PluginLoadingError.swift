//
//  PluginLoadingError.swift
//  tibok
//
//  Error types for dynamic plugin loading.
//
//  MIT License - See LICENSE file in Plugins directory
//

import Foundation

/// Errors that can occur during dynamic plugin loading.
enum PluginLoadingError: LocalizedError {
    /// Framework file not found at expected path
    case frameworkNotFound(String)
    
    /// Plugin class not found in loaded framework
    case classNotFound(String)
    
    /// Class found but does not conform to TibokPlugin protocol
    case invalidPluginType(String)
    
    /// Plugin manifest missing entryPoint configuration
    case missingEntryPoint
    
    /// Framework failed to load (bundle load error)
    case frameworkLoadFailed(URL, Error)
    
    /// Plugin initialization failed (init() threw error)
    case pluginInitializationFailed(Error)
    
    /// Framework architecture mismatch (e.g., x86_64 vs arm64)
    case architectureMismatch(String, String)
    
    /// Framework is too large (potential DoS protection)
    case frameworkTooLarge(Int64, Int64)
    
    /// Framework is not in allowed location
    case invalidFrameworkLocation(URL)
    
    var errorDescription: String? {
        switch self {
        case .frameworkNotFound(let name):
            return "Framework '\(name).framework' not found"
        case .classNotFound(let name):
            return "Plugin class '\(name)' not found in framework"
        case .invalidPluginType(let name):
            return "Class '\(name)' does not conform to TibokPlugin protocol"
        case .missingEntryPoint:
            return "Plugin manifest missing entryPoint configuration"
        case .frameworkLoadFailed(let url, let error):
            return "Failed to load framework at \(url.path): \(error.localizedDescription)"
        case .pluginInitializationFailed(let error):
            return "Failed to initialize plugin: \(error.localizedDescription)"
        case .architectureMismatch(let frameworkArch, let appArch):
            return "Framework architecture (\(frameworkArch)) does not match app architecture (\(appArch))"
        case .frameworkTooLarge(let size, let maxSize):
            return "Framework size (\(size) bytes) exceeds maximum allowed size (\(maxSize) bytes)"
        case .invalidFrameworkLocation(let url):
            return "Framework at \(url.path) is not in allowed location (must be in ThirdParty folder)"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .frameworkNotFound:
            return "The plugin framework file is missing or could not be found."
        case .classNotFound:
            return "The specified plugin class does not exist in the framework."
        case .invalidPluginType:
            return "The class does not implement the TibokPlugin protocol."
        case .missingEntryPoint:
            return "The plugin manifest does not specify how to load the plugin."
        case .frameworkLoadFailed:
            return "The framework could not be loaded. It may be corrupted or incompatible."
        case .pluginInitializationFailed:
            return "The plugin failed to initialize. Check the plugin's init() method."
        case .architectureMismatch:
            return "The plugin was built for a different architecture than this app."
        case .frameworkTooLarge:
            return "The plugin framework is too large and may be malicious."
        case .invalidFrameworkLocation:
            return "The plugin framework is not in the allowed location."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .frameworkNotFound:
            return "Verify the plugin is properly installed and the framework file exists."
        case .classNotFound:
            return "Check that the className in manifest.json matches the actual class name in the framework."
        case .invalidPluginType:
            return "Ensure the plugin class conforms to the TibokPlugin protocol."
        case .missingEntryPoint:
            return "Add an entryPoint section to manifest.json with framework and className fields."
        case .frameworkLoadFailed:
            return "Try reinstalling the plugin. If the problem persists, contact the plugin developer."
        case .pluginInitializationFailed:
            return "Check the plugin's initialization code for errors."
        case .architectureMismatch:
            return "Rebuild the plugin for the correct architecture (arm64 for Apple Silicon, x86_64 for Intel)."
        case .frameworkTooLarge:
            return "Contact the plugin developer. The plugin may be corrupted."
        case .invalidFrameworkLocation:
            return "Install the plugin using the Install Plugin button in Settings."
        }
    }
}

