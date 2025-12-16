//
//  CoreSlashCommandsPlugin.swift
//  tibok
//
//  Built-in plugin providing the core slash commands.
//

import Foundation

/// Built-in plugin providing the core slash commands.
/// Migrates existing hardcoded SlashCommand.all to the registry.
@MainActor
final class CoreSlashCommandsPlugin: TibokPlugin {
    static let identifier = "com.tibok.core-slash-commands"
    static let name = "Core Slash Commands"
    static let version = "1.0.0"
    static let description: String? = "Provides the built-in markdown slash commands"
    static let icon = "command"
    static let author: String? = "tibok"

    init() {}

    func register(with context: PluginContext) {
        context.slashCommandRegistry.register(Self.coreCommands)
    }

    func deactivate() {
        // Core commands stay loaded - this is a built-in plugin
    }

    // MARK: - Core Commands Definition

    private static var coreCommands: [SlashCommand] {
        [
            // MARK: Headings
            SlashCommand(
                id: "h1", name: "Heading 1", description: "Large heading",
                icon: "textformat.size.larger", insert: "# {{CURSOR}}",
                source: identifier, keywords: ["title", "header"], category: .headings
            ),
            SlashCommand(
                id: "h2", name: "Heading 2", description: "Medium heading",
                icon: "textformat.size", insert: "## {{CURSOR}}",
                source: identifier, keywords: ["subtitle", "header"], category: .headings
            ),
            SlashCommand(
                id: "h3", name: "Heading 3", description: "Small heading",
                icon: "textformat.size.smaller", insert: "### {{CURSOR}}",
                source: identifier, keywords: ["header"], category: .headings
            ),
            SlashCommand(
                id: "h4", name: "Heading 4", description: "Smaller heading",
                icon: "textformat.size.smaller", insert: "#### {{CURSOR}}",
                source: identifier, keywords: ["header"], category: .headings
            ),
            SlashCommand(
                id: "h5", name: "Heading 5", description: "Small heading",
                icon: "textformat.size.smaller", insert: "##### {{CURSOR}}",
                source: identifier, keywords: ["header"], category: .headings
            ),
            SlashCommand(
                id: "h6", name: "Heading 6", description: "Smallest heading",
                icon: "textformat.size.smaller", insert: "###### {{CURSOR}}",
                source: identifier, keywords: ["header"], category: .headings
            ),

            // MARK: Blocks
            SlashCommand(
                id: "table", name: "Table", description: "Insert table",
                icon: "tablecells", insert: "| {{CURSOR}} | Column 2 | Column 3 |\n|----------|----------|----------|\n| Cell 1   | Cell 2   | Cell 3   |\n",
                source: identifier, keywords: ["grid", "columns"], category: .blocks
            ),
            SlashCommand(
                id: "code", name: "Code Block", description: "Fenced code block",
                icon: "chevron.left.forwardslash.chevron.right", insert: "```{{CURSOR}}\n\n```",
                source: identifier, keywords: ["syntax", "pre", "snippet"], category: .blocks
            ),
            SlashCommand(
                id: "quote", name: "Blockquote", description: "Quote block",
                icon: "text.quote", insert: "> {{CURSOR}}",
                source: identifier, keywords: ["citation"], category: .blocks
            ),
            SlashCommand(
                id: "callout", name: "Callout", description: "Note or warning block",
                icon: "exclamationmark.bubble", insert: "> [!NOTE]\n> {{CURSOR}}",
                source: identifier, keywords: ["note", "warning", "tip", "important", "caution"], category: .blocks
            ),
            SlashCommand(
                id: "collapse", name: "Collapsible", description: "Expandable section",
                icon: "chevron.down.circle", insert: "<details>\n<summary>{{CURSOR}}</summary>\n\n</details>",
                source: identifier, keywords: ["details", "accordion", "expand"], category: .blocks
            ),
            SlashCommand(
                id: "definition", name: "Definition List", description: "Term and definition",
                icon: "list.bullet.rectangle", insert: "{{CURSOR}}\n: Definition here",
                source: identifier, keywords: ["term", "glossary"], category: .blocks
            ),

            // MARK: Links & Media
            SlashCommand(
                id: "link", name: "Link", description: "Insert hyperlink",
                icon: "link", insert: "[{{CURSOR}}](url)",
                source: identifier, keywords: ["url", "href", "anchor"], category: .links
            ),
            SlashCommand(
                id: "image", name: "Image", description: "Insert image",
                icon: "photo", insert: "![{{CURSOR}}](image-url)",
                source: identifier, keywords: ["picture", "photo", "img"], category: .links
            ),
            SlashCommand(
                id: "footnote", name: "Footnote", description: "Add footnote reference",
                icon: "text.append", insert: "[^{{CURSOR}}]",
                source: identifier, keywords: ["reference", "note"], category: .links
            ),

            // MARK: Lists
            SlashCommand(
                id: "list", name: "Bullet List", description: "Unordered list",
                icon: "list.bullet", insert: "- {{CURSOR}}\n- \n- \n",
                source: identifier, keywords: ["unordered", "bullets"], category: .lists
            ),
            SlashCommand(
                id: "numbered", name: "Numbered List", description: "Ordered list",
                icon: "list.number", insert: "1. {{CURSOR}}\n2. \n3. \n",
                source: identifier, keywords: ["ordered", "numbers"], category: .lists
            ),
            SlashCommand(
                id: "task", name: "Task List", description: "Checkbox list",
                icon: "checklist", insert: "- [ ] {{CURSOR}}\n- [ ] \n- [ ] \n",
                source: identifier, keywords: ["todo", "checkbox", "checklist"], category: .lists
            ),

            // MARK: Formatting
            SlashCommand(
                id: "bold", name: "Bold", description: "Bold text",
                icon: "bold", insert: "**{{CURSOR}}**",
                source: identifier, keywords: ["strong"], category: .formatting
            ),
            SlashCommand(
                id: "italic", name: "Italic", description: "Italic text",
                icon: "italic", insert: "*{{CURSOR}}*",
                source: identifier, keywords: ["emphasis", "em"], category: .formatting
            ),
            SlashCommand(
                id: "bolditalic", name: "Bold Italic", description: "Bold and italic text",
                icon: "bold.italic.underline", insert: "***{{CURSOR}}***",
                source: identifier, keywords: ["strong emphasis"], category: .formatting
            ),
            SlashCommand(
                id: "strikethrough", name: "Strikethrough", description: "Crossed out text",
                icon: "strikethrough", insert: "~~{{CURSOR}}~~",
                source: identifier, keywords: ["delete", "cross"], category: .formatting
            ),
            SlashCommand(
                id: "underline", name: "Underline", description: "Underlined text",
                icon: "underline", insert: "<u>{{CURSOR}}</u>",
                source: identifier, keywords: [], category: .formatting
            ),
            SlashCommand(
                id: "inlinecode", name: "Inline Code", description: "Code snippet",
                icon: "chevron.left.forwardslash.chevron.right", insert: "`{{CURSOR}}`",
                source: identifier, keywords: ["monospace", "backtick"], category: .formatting
            ),
            SlashCommand(
                id: "highlight", name: "Highlight", description: "Highlighted text",
                icon: "highlighter", insert: "=={{CURSOR}}==",
                source: identifier, keywords: ["mark", "yellow"], category: .formatting
            ),
            SlashCommand(
                id: "subscript", name: "Subscript", description: "Subscript text (H₂O)",
                icon: "textformat.subscript", insert: "~{{CURSOR}}~",
                source: identifier, keywords: ["sub", "below"], category: .formatting
            ),
            SlashCommand(
                id: "superscript", name: "Superscript", description: "Superscript text (x²)",
                icon: "textformat.superscript", insert: "^{{CURSOR}}^",
                source: identifier, keywords: ["sup", "above", "power"], category: .formatting
            ),

            // MARK: Math
            SlashCommand(
                id: "math", name: "Math Inline", description: "Inline LaTeX formula",
                icon: "function", insert: "${{CURSOR}}$",
                source: identifier, keywords: ["latex", "equation", "formula"], category: .math
            ),
            SlashCommand(
                id: "mathblock", name: "Math Block", description: "Display LaTeX formula",
                icon: "function", insert: "$$\n{{CURSOR}}\n$$",
                source: identifier, keywords: ["latex", "equation", "formula", "display"], category: .math
            ),

            // MARK: Structure
            SlashCommand(
                id: "hr", name: "Divider", description: "Horizontal rule",
                icon: "minus", insert: "\n---\n",
                source: identifier, keywords: ["separator", "line", "horizontal"], category: .structure
            ),
            SlashCommand(
                id: "toc", name: "Table of Contents", description: "TOC placeholder",
                icon: "list.bullet.indent", insert: "[[toc]]",
                source: identifier, keywords: ["contents", "navigation", "outline"], category: .structure
            ),

            // MARK: Date & Time
            SlashCommand(
                id: "date", name: "Date", description: "Today (YYYY-MM-DD)",
                icon: "calendar", insert: "{{DATE:yyyy-MM-dd}}",
                source: identifier, keywords: ["today", "iso"], category: .datetime
            ),
            SlashCommand(
                id: "datelong", name: "Date (Long)", description: "Today (Month Day, Year)",
                icon: "calendar", insert: "{{DATE:MMMM d, yyyy}}",
                source: identifier, keywords: ["today", "full"], category: .datetime
            ),
            SlashCommand(
                id: "time", name: "Time", description: "Current time (HH:MM)",
                icon: "clock", insert: "{{TIME:HH:mm}}",
                source: identifier, keywords: ["now", "clock"], category: .datetime
            ),
            SlashCommand(
                id: "datetime", name: "Date & Time", description: "Full timestamp",
                icon: "calendar.badge.clock", insert: "{{DATE:yyyy-MM-dd}} {{TIME:HH:mm}}",
                source: identifier, keywords: ["timestamp", "now"], category: .datetime
            ),
            SlashCommand(
                id: "pickdate", name: "Pick Date", description: "Choose from calendar",
                icon: "calendar.badge.plus", insert: "{{DATEPICKER}}",
                source: identifier, keywords: ["choose", "select", "calendar"], category: .datetime
            ),
        ]
    }
}
