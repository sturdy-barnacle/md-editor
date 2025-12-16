//
//  FrontmatterPlugin.swift
//  tibok
//
//  Plugin providing frontmatter-related slash commands for Jekyll/Hugo.
//

import Foundation

/// Plugin providing frontmatter slash commands for Jekyll and Hugo static site generators.
@MainActor
final class FrontmatterPlugin: TibokPlugin {
    static let identifier = "com.tibok.frontmatter"
    static let name = "Frontmatter Commands"
    static let version = "1.0.0"
    static let description: String? = "Slash commands for Jekyll/Hugo frontmatter"
    static let icon = "doc.badge.gearshape"
    static let author: String? = "tibok"

    init() {}

    func register(with context: PluginContext) {
        context.slashCommandRegistry.register(Self.frontmatterCommands)
    }

    func deactivate() {
        // Built-in plugin stays active
    }

    // MARK: - Frontmatter Commands

    private static var frontmatterCommands: [SlashCommand] {
        [
            // Add Jekyll frontmatter
            SlashCommand(
                id: "frontmatter-jekyll",
                name: "Jekyll Frontmatter",
                description: "Add Jekyll YAML frontmatter",
                icon: "doc.badge.gearshape",
                insert: "{{FRONTMATTER:jekyll}}",
                source: identifier,
                keywords: ["yaml", "metadata", "blog", "header"],
                category: .frontmatter
            ),

            // Add Hugo frontmatter
            SlashCommand(
                id: "frontmatter-hugo",
                name: "Hugo Frontmatter",
                description: "Add Hugo frontmatter (YAML/TOML)",
                icon: "doc.badge.gearshape",
                insert: "{{FRONTMATTER:hugo}}",
                source: identifier,
                keywords: ["toml", "yaml", "metadata", "blog", "header"],
                category: .frontmatter
            ),

            // Toggle draft status
            SlashCommand(
                id: "frontmatter-draft",
                name: "Toggle Draft",
                description: "Toggle draft status in frontmatter",
                icon: "doc.badge.ellipsis",
                insert: "{{FRONTMATTER:toggle-draft}}",
                source: identifier,
                keywords: ["publish", "unpublish"],
                category: .frontmatter
            ),

            // Open inspector
            SlashCommand(
                id: "frontmatter-inspector",
                name: "Open Inspector",
                description: "Open frontmatter inspector panel",
                icon: "pencil",
                insert: "{{FRONTMATTER:inspector}}",
                source: identifier,
                keywords: ["edit", "panel", "sidebar"],
                category: .frontmatter
            ),
        ]
    }
}
