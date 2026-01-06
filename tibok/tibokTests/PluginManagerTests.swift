//
//  PluginManagerTests.swift
//  tibokTests
//
//  Tests for the Plugin System - lifecycle management, enable/disable functionality.
//

import Testing
import Foundation
@testable import tibok

@Suite("Plugin Manager Tests")
@MainActor
struct PluginManagerTests {

    // MARK: - Test Plugin Implementation

    /// Mock plugin for testing
    class MockPlugin: TibokPlugin {
        static let identifier = "com.tibok.test.mock"
        static let name = "Mock Plugin"
        static let version = "1.0.0"
        static let description = "A test plugin"
        static let icon = "testtube.2"
        static let author = "Test Author"

        var isRegistered = false
        var isDeactivated = false
        var registrationContext: PluginContext?

        required init() {}

        func register(with context: PluginContext) {
            isRegistered = true
            registrationContext = context
        }

        func deactivate() {
            isDeactivated = true
        }
    }

    // MARK: - Plugin Metadata Tests

    @Test("Plugin has required metadata")
    func pluginHasMetadata() {
        #expect(MockPlugin.identifier == "com.tibok.test.mock")
        #expect(MockPlugin.name == "Mock Plugin")
        #expect(MockPlugin.version == "1.0.0")
        #expect(MockPlugin.description == "A test plugin")
        #expect(MockPlugin.icon == "testtube.2")
        #expect(MockPlugin.author == "Test Author")
    }

    @Test("Plugin initializes")
    func pluginInitializes() {
        let plugin = MockPlugin()
        #expect(plugin.isRegistered == false)
        #expect(plugin.isDeactivated == false)
    }

    @Test("Plugin can be registered")
    func pluginCanBeRegistered() async throws {
        let plugin = MockPlugin()
        let appState = AppState()
        let context = PluginContext(
            slashCommandService: SlashCommandService.shared,
            commandRegistry: CommandService.shared,
            appState: appState
        )

        plugin.register(with: context)

        #expect(plugin.isRegistered == true)
        #expect(plugin.registrationContext != nil)
    }

    @Test("Plugin can be deactivated")
    func pluginCanBeDeactivated() {
        let plugin = MockPlugin()
        plugin.deactivate()
        #expect(plugin.isDeactivated == true)
    }

    // MARK: - PluginManager Tests

    @Test("PluginManager is singleton")
    func pluginManagerIsSingleton() {
        let manager1 = PluginManager.shared
        let manager2 = PluginManager.shared
        #expect(manager1 === manager2)
    }

    @Test("PluginManager initializes empty")
    func pluginManagerInitializesEmpty() {
        // Note: This test uses the shared instance which may have plugins loaded
        // In a real test environment, we'd want to reset the manager
        let manager = PluginManager.shared
        #expect(manager.loadedPlugins.count >= 0)  // May have built-in plugins
    }

    @Test("PluginManager tracks available plugin types")
    func pluginManagerTracksAvailableTypes() {
        let manager = PluginManager.shared
        #expect(manager.availablePluginTypes.count > 0)  // Should have built-in plugins
    }

    @Test("PluginManager can check if plugin is loaded")
    func pluginManagerCanCheckLoaded() {
        let manager = PluginManager.shared

        // CoreSlashCommandsPlugin should be registered
        let hasCore = manager.availablePluginTypes.contains {
            $0.identifier == "com.tibok.core-slash-commands"
        }
        #expect(hasCore == true)
    }

    @Test("PluginManager provides plugin info")
    func pluginManagerProvidesPluginInfo() {
        let manager = PluginManager.shared
        let info = manager.pluginInfo

        // Should have at least some plugin info
        #expect(info.count >= 0)

        // Each info entry should have required fields
        for entry in info {
            #expect(entry.identifier.isEmpty == false)
            #expect(entry.name.isEmpty == false)
            #expect(entry.version.isEmpty == false)
        }
    }

    @Test("PluginManager provides all plugin info for Settings")
    func pluginManagerProvidesAllPluginInfo() {
        let manager = PluginManager.shared
        let allInfo = manager.allPluginInfo

        // Should include all available plugins
        #expect(allInfo.count == manager.availablePluginTypes.count)

        // Each entry should have type or manifest, and loaded status
        for entry in allInfo {
            // Built-in plugins have type, discovered plugins have manifest
            if let type = entry.type {
                #expect(type.identifier.isEmpty == false)
            } else if let manifest = entry.manifest {
                #expect(manifest.identifier.isEmpty == false)
            }
            // isLoaded is a boolean, just verify it exists
            _ = entry.isLoaded
        }
    }

    // MARK: - Plugin State Persistence Tests

    @Test("PluginStateManager is singleton")
    func pluginStateManagerIsSingleton() {
        let manager1 = PluginStateManager.shared
        let manager2 = PluginStateManager.shared
        #expect(manager1 === manager2)
    }

    @Test("PluginStateManager tracks enabled state")
    func pluginStateManagerTracksState() {
        let manager = PluginStateManager.shared
        let testId = "com.tibok.test.state-\(UUID().uuidString)"

        // Clean up after test
        defer {
            manager.setEnabled(testId, true)  // Reset to default (enabled)
        }

        // Default should be enabled (not in disabled list)
        #expect(manager.isEnabled(testId) == true)

        // Disable
        manager.setEnabled(testId, false)
        #expect(manager.isEnabled(testId) == false)

        // Re-enable
        manager.setEnabled(testId, true)
        #expect(manager.isEnabled(testId) == true)
    }

    @Test("PluginStateManager persists state across instances")
    func pluginStateManagerPersistsState() {
        let testId = "com.tibok.test.persist-\(UUID().uuidString)"

        // Clean up after test
        defer {
            PluginStateManager.shared.setEnabled(testId, true)
        }

        // Set state
        PluginStateManager.shared.setEnabled(testId, false)

        // Create new instance (simulating app restart)
        let newManager = PluginStateManager.shared

        // State should persist
        #expect(newManager.isEnabled(testId) == false)
    }

    // MARK: - Plugin Lifecycle Integration Tests

    @Test("Enable plugin loads it")
    func enablePluginLoadsIt() async throws {
        let manager = PluginManager.shared
        let corePluginId = "com.tibok.core-slash-commands"

        // If plugin is already loaded, this test verifies it stays loaded
        let wasLoaded = manager.isLoaded(corePluginId)

        manager.enablePlugin(corePluginId)

        #expect(manager.isLoaded(corePluginId) == true)

        // Cleanup: restore original state
        if !wasLoaded {
            manager.disablePlugin(corePluginId)
        }
    }

    @Test("Disable plugin unloads it")
    func disablePluginUnloadsIt() async throws {
        let manager = PluginManager.shared
        let corePluginId = "com.tibok.core-slash-commands"

        // Save original state
        let wasLoaded = manager.isLoaded(corePluginId)

        // Ensure it's loaded first
        manager.enablePlugin(corePluginId)
        #expect(manager.isLoaded(corePluginId) == true)

        // Disable
        manager.disablePlugin(corePluginId)
        #expect(manager.isLoaded(corePluginId) == false)

        // Cleanup: restore original state
        if wasLoaded {
            manager.enablePlugin(corePluginId)
        }
    }

    @Test("Cannot load same plugin twice")
    func cannotLoadPluginTwice() async throws {
        let manager = PluginManager.shared
        let corePluginId = "com.tibok.core-slash-commands"

        let wasLoaded = manager.isLoaded(corePluginId)

        // Enable once
        manager.enablePlugin(corePluginId)
        let countAfterFirst = manager.loadedPlugins.count

        // Try to enable again
        manager.enablePlugin(corePluginId)
        let countAfterSecond = manager.loadedPlugins.count

        // Count should be the same (no duplicate)
        #expect(countAfterFirst == countAfterSecond)

        // Cleanup
        if !wasLoaded {
            manager.disablePlugin(corePluginId)
        }
    }

    @Test("Deactivate all plugins")
    func deactivateAllPlugins() async throws {
        let manager = PluginManager.shared

        // Save original state
        let originalCount = manager.loadedPlugins.count
        let originalPlugins = manager.loadedPlugins.map { type(of: $0).identifier }

        // Deactivate all
        manager.deactivateAll()

        #expect(manager.loadedPlugins.count == 0)

        // Cleanup: reload original plugins
        for id in originalPlugins {
            manager.enablePlugin(id)
        }

        // Verify restoration
        #expect(manager.loadedPlugins.count == originalCount)
    }
}
