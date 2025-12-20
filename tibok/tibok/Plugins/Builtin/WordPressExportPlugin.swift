//
//  WordPressExportPlugin.swift
//  tibok
//
//  Plugin for publishing markdown documents to WordPress via REST API or Post by Email
//
//  MIT License - See LICENSE file in Plugins directory
//

import Foundation
import SwiftUI
import AppKit

/// Plugin that adds WordPress publishing capability to tibok
@MainActor
final class WordPressExportPlugin: TibokPlugin {

    // MARK: - Plugin Metadata

    static let identifier = "com.tibok.wordpress-export"
    static let name = "WordPress Export"
    static let version = "1.0.0"
    static let description: String? = "Publish markdown posts to WordPress via REST API or Post by Email"
    static let icon = "w.square"
    static let author: String? = "tibok"

    // MARK: - Lifecycle

    init() {}

    func register(with context: PluginContext) {
        // Register command palette command for WordPress publishing
        context.commandRegistry.register(Command(
            id: "wordpress-publish",
            title: "Publish to WordPress",
            subtitle: "Publish current document to WordPress site",
            icon: "w.square",
            shortcut: KeyboardShortcut("p", modifiers: [.command, .shift]),
            category: .export,
            source: Self.identifier,
            action: { [weak context] in
                guard let appState = context?.appState,
                      let doc = appState.activeDocument else {
                    UIStateService.shared.showToast(
                        "No document to publish",
                        icon: "exclamationmark.triangle"
                    )
                    return
                }

                // Parse frontmatter to preview publish details
                let (frontmatter, _) = Frontmatter.parse(from: doc.content)

                // Read settings from UserDefaults
                let defaultStatus = UserDefaults.standard.string(forKey: "plugin.wordpress.defaultStatus") ?? "draft"
                let defaultCategories = UserDefaults.standard.string(forKey: "plugin.wordpress.defaultCategories") ?? ""

                // Determine publish details
                let title = frontmatter?.title ?? doc.title
                let categoriesArray = frontmatter?.categories.isEmpty == false
                    ? frontmatter!.categories
                    : defaultCategories.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                let status = frontmatter?.draft == true ? "draft" : defaultStatus
                let excerpt = frontmatter?.description ?? "(none)"

                // Get content preview (first 200 chars)
                let (_, body) = Frontmatter.parse(from: doc.content)
                let contentPreview = String(body.prefix(200)) + (body.count > 200 ? "..." : "")

                // Show confirmation dialog
                let alert = NSAlert()

                // Draft warning: use warning style if publishing live
                if status == "publish" {
                    alert.alertStyle = .warning
                    alert.messageText = "⚠️ Publish Live to WordPress?"
                } else {
                    alert.alertStyle = .informational
                    alert.messageText = "Publish to WordPress?"
                }

                alert.informativeText = """
                Title: \(title)
                Status: \(status)\(status == "publish" ? " (⚠️ publicly visible)" : "")
                Categories: \(categoriesArray.isEmpty ? "(none)" : categoriesArray.joined(separator: ", "))
                Excerpt: \(excerpt)

                Content Preview:
                \(contentPreview)
                """
                alert.addButton(withTitle: "Publish")
                alert.addButton(withTitle: "Cancel")

                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    Task {
                        await WordPressExporter.shared.publish(
                            document: doc,
                            appState: appState
                        )
                    }
                }
            }
        ))
    }

    func deactivate() {
        // Commands are auto-unregistered by CommandService when plugin is disabled
    }
}
