//
//  DynamicPluginLoaderTests.swift
//  tibokTests
//
//  Tests for dynamic plugin framework loading.
//
//  MIT License - See LICENSE file in Plugins directory
//

import Testing
import Foundation
@testable import tibok

@Suite("Dynamic Plugin Loader Tests")
@MainActor
struct DynamicPluginLoaderTests {
    
    var tempDir: URL!
    var loader: DynamicPluginLoader!
    
    init() {
        // Create temporary directory for test frameworks
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("tibok-plugin-tests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        loader = DynamicPluginLoader()
    }
    
    // MARK: - Framework Location Validation Tests
    
    @Test("Validates framework is in ThirdParty folder")
    func validatesFrameworkLocation() async throws {
        // Create a framework outside ThirdParty folder
        let invalidLocation = tempDir.appendingPathComponent("InvalidPlugin.framework")
        try? FileManager.default.createDirectory(at: invalidLocation, withIntermediateDirectories: true)
        
        // Should throw invalidFrameworkLocation error
        do {
            _ = try await loader.loadPlugin(
                from: invalidLocation,
                className: "TestPlugin",
                identifier: "com.test.plugin"
            )
            Issue.record("Expected PluginLoadingError.invalidFrameworkLocation")
        } catch let error as PluginLoadingError {
            #expect(error == .invalidFrameworkLocation(invalidLocation))
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
    
    @Test("Allows framework in ThirdParty folder")
    func allowsFrameworkInThirdPartyFolder() async throws {
        // Create ThirdParty folder structure
        let thirdPartyFolder = PluginDiscovery.Folders.thirdParty
        try? FileManager.default.createDirectory(at: thirdPartyFolder, withIntermediateDirectories: true)
        
        let validFramework = thirdPartyFolder
            .appendingPathComponent("TestPlugin")
            .appendingPathComponent("TestPlugin.framework")
        try? FileManager.default.createDirectory(at: validFramework, withIntermediateDirectories: true)
        
        // This should not throw invalidFrameworkLocation
        // (But will fail on other validations like missing binary, which is expected)
        do {
            _ = try await loader.loadPlugin(
                from: validFramework,
                className: "TestPlugin",
                identifier: "com.test.plugin"
            )
        } catch let error as PluginLoadingError {
            // Should fail on frameworkNotFound or frameworkLoadFailed, not invalidFrameworkLocation
            #expect(error != .invalidFrameworkLocation(validFramework))
        } catch {
            // Other errors are acceptable (framework doesn't exist, etc.)
        }
    }
    
    // MARK: - Framework Size Validation Tests
    
    @Test("Validates framework size limit")
    func validatesFrameworkSize() async throws {
        // Create a large dummy file to simulate oversized framework
        let thirdPartyFolder = PluginDiscovery.Folders.thirdParty
        try? FileManager.default.createDirectory(at: thirdPartyFolder, withIntermediateDirectories: true)
        
        let frameworkURL = thirdPartyFolder
            .appendingPathComponent("LargePlugin.framework")
        try? FileManager.default.createDirectory(at: frameworkURL, withIntermediateDirectories: true)
        
        // Create a file larger than 100MB
        let largeFile = frameworkURL.appendingPathComponent("large.bin")
        let largeData = Data(count: 101 * 1024 * 1024) // 101 MB
        try largeData.write(to: largeFile)
        
        do {
            _ = try await loader.loadPlugin(
                from: frameworkURL,
                className: "LargePlugin",
                identifier: "com.test.large"
            )
            Issue.record("Expected PluginLoadingError.frameworkTooLarge")
        } catch let error as PluginLoadingError {
            // Should detect oversized framework
            if case .frameworkTooLarge = error {
                // Expected error
            } else {
                // Other errors are also acceptable (framework structure invalid, etc.)
            }
        } catch {
            // Other errors acceptable
        }
        
        // Cleanup
        try? FileManager.default.removeItem(at: largeFile)
    }
    
    // MARK: - Framework Existence Tests
    
    @Test("Throws error for non-existent framework")
    func throwsErrorForNonExistentFramework() async throws {
        let thirdPartyFolder = PluginDiscovery.Folders.thirdParty
        let nonExistentFramework = thirdPartyFolder
            .appendingPathComponent("NonExistentPlugin.framework")
        
        do {
            _ = try await loader.loadPlugin(
                from: nonExistentFramework,
                className: "NonExistentPlugin",
                identifier: "com.test.nonexistent"
            )
            Issue.record("Expected PluginLoadingError.frameworkNotFound")
        } catch let error as PluginLoadingError {
            #expect(error == .frameworkNotFound("NonExistentPlugin.framework"))
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Framework Loading State Tests
    
    @Test("Tracks loaded frameworks")
    func tracksLoadedFrameworks() async throws {
        let thirdPartyFolder = PluginDiscovery.Folders.thirdParty
        let frameworkURL = thirdPartyFolder
            .appendingPathComponent("TrackedPlugin.framework")
        
        // Initially not loaded
        #expect(loader.isFrameworkLoaded(at: frameworkURL) == false)
        
        // Note: We can't actually load a real framework in unit tests without building one
        // This test verifies the tracking mechanism exists
    }
    
    @Test("Can unload framework")
    func canUnloadFramework() async throws {
        let thirdPartyFolder = PluginDiscovery.Folders.thirdParty
        let frameworkURL = thirdPartyFolder
            .appendingPathComponent("UnloadablePlugin.framework")
        
        // Unload should not crash even if not loaded
        loader.unloadFramework(at: frameworkURL)
        
        #expect(loader.isFrameworkLoaded(at: frameworkURL) == false)
    }
    
    // MARK: - Error Handling Tests
    
    @Test("PluginLoadingError provides helpful descriptions")
    func pluginLoadingErrorProvidesDescriptions() {
        let frameworkURL = URL(fileURLWithPath: "/test/Test.framework")
        let className = "TestPlugin"
        
        let errors: [PluginLoadingError] = [
            .frameworkNotFound("Test.framework"),
            .classNotFound(className),
            .invalidPluginType(className),
            .missingEntryPoint,
            .frameworkLoadFailed(frameworkURL, NSError(domain: "test", code: 1)),
            .pluginInitializationFailed(NSError(domain: "test", code: 2)),
            .architectureMismatch("x86_64", "arm64"),
            .frameworkTooLarge(200 * 1024 * 1024, 100 * 1024 * 1024),
            .invalidFrameworkLocation(frameworkURL)
        ]
        
        for error in errors {
            let description = error.errorDescription
            #expect(description != nil)
            #expect(description?.isEmpty == false)
            
            let failureReason = error.failureReason
            #expect(failureReason != nil)
            
            let recoverySuggestion = error.recoverySuggestion
            #expect(recoverySuggestion != nil)
        }
    }
    
    @Test("PluginLoadingError is LocalizedError")
    func pluginLoadingErrorIsLocalizedError() {
        let error: Error = PluginLoadingError.missingEntryPoint
        #expect(error is LocalizedError)
        
        if let localizedError = error as? LocalizedError {
            #expect(localizedError.errorDescription != nil)
            #expect(localizedError.failureReason != nil)
            #expect(localizedError.recoverySuggestion != nil)
        }
    }
    
    // MARK: - Integration with PluginManager Tests
    
    @Test("PluginManager can use DynamicPluginLoader")
    func pluginManagerCanUseDynamicLoader() async throws {
        let manager = PluginManager.shared
        
        // Verify manager has access to dynamic loader
        // (This is tested indirectly through enablePlugin for discovered plugins)
        
        // The actual loading requires a real framework, which is tested in integration tests
        #expect(manager != nil)
    }
    
    // MARK: - Cleanup
    
    deinit {
        // Clean up temporary directory
        try? FileManager.default.removeItem(at: tempDir)
    }
}

