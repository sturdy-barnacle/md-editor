//
//  MyNativePlugin.swift
//  MyNativePlugin
//
//  A template for creating native Swift plugins for Tibok.
//
//  To use this template:
//  1. Create a new Swift Package with framework target
//  2. Copy this file into your Sources directory
//  3. Rename the class and update the static properties
//  4. Implement your plugin logic in register(with:)
//  5. Build the framework and package with manifest.json
//

import Foundation

// IMPORTANT: Your framework must import the TibokPlugin protocol.
// In a real plugin, you would have TibokPluginSDK as a dependency.
// For this template, we'll define the protocol inline for illustration.

// This would normally come from: import TibokPluginSDK

/// Protocol that all Tibok plugins must implement.
/// Your plugin class must be @MainActor and final.
@MainActor
public protocol TibokPlugin {
    static var identifier: String { get }
    static var name: String { get }
    static var version: String { get }
    static var description: String? { get }
    static var icon: String { get }
    static var author: String? { get }

    init()
    func register(with context: PluginContext)
    func deactivate()
}

/// Context provided to plugins during registration.
/// Provides access to Tibok services.
@MainActor
public class PluginContext {
    public let slashCommandService: SlashCommandService
    public let commandRegistry: CommandService
    public weak var appState: AppState?

    public init(
        slashCommandService: SlashCommandService,
        commandRegistry: CommandService,
        appState: AppState?
    ) {
        self.slashCommandService = slashCommandService
        self.commandRegistry = commandRegistry
        self.appState = appState
    }
}

// Placeholder types - in a real plugin, these would come from TibokPluginSDK
@MainActor public class SlashCommandService {
    public func register(_ commands: [SlashCommand]) {}
}

@MainActor public class CommandService {
    public func register(_ command: Command) {}
}

@MainActor public class AppState {
    public var selectedText: String? { nil }
    public func insertTextAtCursor(_ text: String) {}
}

public struct SlashCommand {
    public let id: String
    public let name: String
    public let description: String
    public let icon: String
    public let insert: String
    public let source: String
    public let keywords: [String]

    public init(
        id: String,
        name: String,
        description: String,
        icon: String,
        insert: String,
        source: String,
        keywords: [String] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.insert = insert
        self.source = source
        self.keywords = keywords
    }
}

public struct Command {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let icon: String?
    public let source: String
    public let action: () -> Void

    public init(
        id: String,
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        source: String,
        action: @escaping () -> Void
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.source = source
        self.action = action
    }
}

// =============================================================================
// YOUR PLUGIN IMPLEMENTATION
// =============================================================================

/// My Native Plugin
///
/// This is a template plugin demonstrating how to create a native Swift plugin.
/// Customize the static properties and register() method for your use case.
@MainActor
public final class MyNativePlugin: TibokPlugin {

    // MARK: - Plugin Metadata

    /// Unique identifier (reverse-DNS style)
    public static let identifier = "com.example.my-native-plugin"

    /// Display name shown in UI
    public static let name = "My Native Plugin"

    /// Plugin version (semantic versioning)
    public static let version = "1.0.0"

    /// Description of what the plugin does
    public static let description: String? = "A template for creating native Swift plugins"

    /// SF Symbol icon name
    public static let icon = "swift"

    /// Author name
    public static let author: String? = "Your Name"

    // MARK: - Plugin State

    /// Store any plugin state here
    private var isActive = false

    // MARK: - Lifecycle

    /// Required initializer
    public required init() {
        print("[\(Self.identifier)] Plugin initialized")
    }

    /// Called when the plugin should register its contributions
    public func register(with context: PluginContext) {
        print("[\(Self.identifier)] Registering plugin...")

        // Register slash commands
        registerSlashCommands(context.slashCommandService)

        // Register command palette commands
        registerCommands(context.commandRegistry, appState: context.appState)

        isActive = true
        print("[\(Self.identifier)] Plugin registered successfully!")
    }

    /// Called when the plugin should clean up
    public func deactivate() {
        print("[\(Self.identifier)] Deactivating plugin...")
        isActive = false
    }

    // MARK: - Slash Commands

    private func registerSlashCommands(_ service: SlashCommandService) {
        service.register([
            // Example: Simple text insertion
            SlashCommand(
                id: "\(Self.identifier):hello",
                name: "hello",
                description: "Insert a friendly greeting",
                icon: "hand.wave",
                insert: "Hello from My Native Plugin!",
                source: Self.identifier,
                keywords: ["greeting", "hi", "wave"]
            ),

            // Example: Multi-line template
            SlashCommand(
                id: "\(Self.identifier):template",
                name: "mytemplate",
                description: "Insert a custom template",
                icon: "doc.text",
                insert: """
                # Title

                ## Section 1

                Content goes here...

                ## Section 2

                More content...
                """,
                source: Self.identifier,
                keywords: ["template", "document", "structure"]
            ),

            // Example: Placeholder with cursor position
            SlashCommand(
                id: "\(Self.identifier):note",
                name: "mynote",
                description: "Insert a note block",
                icon: "note.text",
                insert: "> **Note:** {{CURSOR}}",
                source: Self.identifier,
                keywords: ["note", "callout", "info"]
            )
        ])
    }

    // MARK: - Command Palette Commands

    private func registerCommands(_ registry: CommandService, appState: AppState?) {
        // Example: Simple action command
        registry.register(Command(
            id: "\(Self.identifier):action",
            title: "My Plugin Action",
            subtitle: "Do something useful",
            icon: "sparkle",
            source: Self.identifier,
            action: { [weak appState] in
                print("[\(Self.identifier)] Action executed!")
                // Example: Insert text at cursor
                appState?.insertTextAtCursor("Action completed!")
            }
        ))

        // Example: Command that uses selection
        registry.register(Command(
            id: "\(Self.identifier):transform",
            title: "Transform Selection",
            subtitle: "Transform the selected text",
            icon: "arrow.triangle.2.circlepath",
            source: Self.identifier,
            action: { [weak appState] in
                guard let selection = appState?.selectedText, !selection.isEmpty else {
                    print("[\(Self.identifier)] No text selected")
                    return
                }

                // Example: Transform to uppercase
                let transformed = selection.uppercased()
                appState?.insertTextAtCursor(transformed)
                print("[\(Self.identifier)] Transformed: \(selection) -> \(transformed)")
            }
        ))
    }
}
