//
//  FrontmatterInspectorView.swift
//  tibok
//
//  Inspector panel for editing Jekyll/Hugo frontmatter metadata.
//

import SwiftUI
import AppKit

struct FrontmatterInspectorView: View {
    @EnvironmentObject var appState: AppState
    @State private var frontmatter: Frontmatter?
    @State private var hasFrontmatter = false
    @State private var selectedFormat: FrontmatterFormat = .yaml
    @State private var selectedSSG: SSGType = .jekyll

    enum SSGType: String, CaseIterable {
        case jekyll = "Jekyll"
        case hugo = "Hugo"
        case wordpress = "WordPress"
    }

    // Computed property for available SSG types (checks plugin status)
    private var availableSSGTypes: [SSGType] {
        var types: [SSGType] = [.jekyll, .hugo]
        // Only show WordPress if plugin is enabled
        if PluginManager.shared.isLoaded("com.tibok.wordpress-export") {
            types.append(.wordpress)
        }
        return types
    }

    // Jekyll defaults from settings
    @AppStorage(SettingsKeys.jekyllDefaultAuthor) private var jekyllAuthor: String = ""
    @AppStorage(SettingsKeys.jekyllDefaultLayout) private var jekyllLayout: String = "post"
    @AppStorage(SettingsKeys.jekyllDefaultDraft) private var jekyllDraft: Bool = true
    @AppStorage(SettingsKeys.jekyllDefaultTags) private var jekyllTags: String = ""
    @AppStorage(SettingsKeys.jekyllDefaultCategories) private var jekyllCategories: String = ""

    // Hugo defaults from settings
    @AppStorage(SettingsKeys.hugoDefaultAuthor) private var hugoAuthor: String = ""
    @AppStorage(SettingsKeys.hugoDefaultLayout) private var hugoLayout: String = ""
    @AppStorage(SettingsKeys.hugoDefaultDraft) private var hugoDraft: Bool = true
    @AppStorage(SettingsKeys.hugoDefaultTags) private var hugoTags: String = ""
    @AppStorage(SettingsKeys.hugoDefaultCategories) private var hugoCategories: String = ""
    @AppStorage(SettingsKeys.hugoDefaultFormat) private var hugoDefaultFormat: String = "yaml"

    // WordPress defaults from settings
    @AppStorage("plugin.wordpress.defaultStatus") private var wordpressStatus: String = "draft"
    @AppStorage("plugin.wordpress.defaultCategories") private var wordpressCategories: String = ""
    @AppStorage("plugin.wordpress.defaultAuthor") private var wordpressAuthor: String = ""
    @AppStorage("plugin.wordpress.defaultDescription") private var wordpressDescription: String = ""

    // Timezone setting
    @AppStorage(SettingsKeys.frontmatterTimezone) private var timezoneIdentifier: String = ""

    // Local state for form fields
    @State private var title: String = ""
    @State private var author: String = ""
    @State private var layout: String = ""
    @State private var description: String = ""
    @State private var draft: Bool = false
    @State private var date: Date = Date()
    @State private var hasDate: Bool = false
    @State private var includeTime: Bool = false
    @State private var tags: String = ""
    @State private var categories: String = ""
    @State private var customFields: [CustomField] = []
    @State private var isUpdating: Bool = false  // Prevent reload loop
    @State private var showConversionAlert: Bool = false
    @State private var pendingConversion: (from: SSGType, to: SSGType)?

    struct CustomField: Identifiable {
        let id = UUID()
        var key: String
        var value: String
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Text("Frontmatter")
                        .font(.headline)
                    Spacer()
                    if hasFrontmatter {
                        Text(frontmatter?.format.rawValue.uppercased() ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                .padding(.bottom, 4)

                if !hasFrontmatter {
                    Spacer()

                    // No frontmatter - offer to create (centered)
                    VStack(spacing: 12) {
                        Text("No frontmatter detected")
                            .foregroundColor(.secondary)

                        Picker("Generator", selection: $selectedSSG) {
                            ForEach(availableSSGTypes, id: \.self) { ssg in
                                Text(ssg.rawValue).tag(ssg)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .onChange(of: selectedSSG) { _, newValue in
                            // Update format based on SSG and settings
                            if newValue == .hugo && hugoDefaultFormat == "toml" {
                                selectedFormat = .toml
                            } else {
                                selectedFormat = .yaml
                            }
                        }

                        Text({
                            switch selectedSSG {
                            case .jekyll:
                                return "YAML frontmatter (---)"
                            case .hugo:
                                return hugoDefaultFormat == "toml" ? "TOML frontmatter (+++)" : "YAML frontmatter (---)"
                            case .wordpress:
                                return "YAML frontmatter (---) for WordPress"
                            }
                        }())
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Button("Add Frontmatter") {
                            createFrontmatter()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity)

                    Spacer()
                } else {
                    // SSG Type picker - always visible when frontmatter exists
                    VStack(spacing: 8) {
                        Text("Export Type")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Picker("Export Type", selection: $selectedSSG) {
                            ForEach(availableSSGTypes, id: \.self) { ssg in
                                Text(ssg.rawValue).tag(ssg)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .onChange(of: selectedSSG) { oldValue, newValue in
                            if oldValue != newValue {
                                convertFrontmatterType(from: oldValue, to: newValue)
                            }
                        }
                    }
                    .padding(.bottom, 8)
                    // Frontmatter editor
                    VStack(alignment: .leading, spacing: 16) {
                        // Status section - Draft first
                        GroupBox("Status") {
                            VStack(alignment: .leading, spacing: 12) {
                                Toggle(isOn: $draft) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Draft")
                                        Text("Mark as unpublished")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .toggleStyle(.switch)
                                .onChange(of: draft) { _, _ in updateDocument() }
                            }
                            .padding(.vertical, 4)
                        }

                        // Document section
                        GroupBox("Document") {
                            VStack(alignment: .leading, spacing: 8) {
                                LabeledField("Title") {
                                    TextField("Document title", text: $title)
                                        .textFieldStyle(.roundedBorder)
                                        .onChange(of: title) { _, _ in updateDocument() }
                                }

                                LabeledField("Description") {
                                    TextField("Brief description", text: $description)
                                        .textFieldStyle(.roundedBorder)
                                        .onChange(of: description) { _, _ in updateDocument() }
                                }

                                LabeledField("Date") {
                                    HStack {
                                        DatePicker("", selection: $date, displayedComponents: .date)
                                            .labelsHidden()
                                            .onChange(of: date) { _, _ in
                                                hasDate = true
                                                updateDocument()
                                            }

                                        Button("Now") {
                                            date = Date()
                                            hasDate = true
                                            updateDocument()
                                        }
                                        .buttonStyle(.borderless)
                                        .font(.caption)
                                    }
                                }

                                if includeTime {
                                    LabeledField("Time") {
                                        HStack {
                                            DatePicker("", selection: $date, displayedComponents: .hourAndMinute)
                                                .labelsHidden()
                                                .onChange(of: date) { _, _ in updateDocument() }
                                            Text(timezoneShortName)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }

                                Picker("", selection: $includeTime) {
                                    Text("Date only").tag(false)
                                    Text("Date & Time").tag(true)
                                }
                                .pickerStyle(.segmented)
                                .labelsHidden()
                                .onChange(of: includeTime) { _, _ in updateDocument() }
                            }
                            .padding(.vertical, 4)
                        }

                        // Author & Layout section
                        GroupBox("Metadata") {
                            VStack(alignment: .leading, spacing: 8) {
                                LabeledField("Author") {
                                    TextField("Author name", text: $author)
                                        .textFieldStyle(.roundedBorder)
                                        .onChange(of: author) { _, _ in updateDocument() }
                                }

                                // Layout field only for Jekyll/Hugo (not WordPress)
                                if selectedSSG != .wordpress {
                                    LabeledField("Layout") {
                                        TextField("Layout template", text: $layout)
                                            .textFieldStyle(.roundedBorder)
                                            .onChange(of: layout) { _, _ in updateDocument() }
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        // Taxonomy section
                        GroupBox("Taxonomy") {
                            VStack(alignment: .leading, spacing: 8) {
                                LabeledField("Tags") {
                                    TextField("tag1, tag2, tag3", text: $tags)
                                        .textFieldStyle(.roundedBorder)
                                        .onChange(of: tags) { _, _ in updateDocument() }
                                }

                                LabeledField("Categories") {
                                    TextField("cat1, cat2", text: $categories)
                                        .textFieldStyle(.roundedBorder)
                                        .onChange(of: categories) { _, _ in updateDocument() }
                                }

                                Text("Separate multiple values with commas")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }

                        // WordPress Publishing section (only shows if WordPress is selected and plugin is enabled)
                        if selectedSSG == .wordpress && PluginManager.shared.isLoaded("com.tibok.wordpress-export") {
                            GroupBox {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "w.square")
                                            .foregroundColor(.accentColor)
                                        Text("WordPress Publishing")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }

                                    Text("These frontmatter fields will be used when publishing to WordPress:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text("•")
                                            Text("**Title** → Post title")
                                        }
                                        HStack {
                                            Text("•")
                                            Text("**Description** → Post excerpt")
                                        }
                                        HStack {
                                            Text("•")
                                            Text("**Categories** → WordPress categories")
                                        }
                                        HStack {
                                            Text("•")
                                            Text("**Draft** → Post status (draft/publish)")
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 8)

                                    Divider()
                                        .padding(.vertical, 4)

                                    // Post status indicator
                                    if let docPath = appState.activeDocument?.fileURL?.path ?? appState.activeDocument?.title,
                                       let publishInfo = WordPressExporter.getPublishInfo(for: docPath) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(alignment: .top, spacing: 6) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.green)
                                                    .font(.caption)
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text("Published to WordPress")
                                                        .font(.caption)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(.green)
                                                    Text(publishInfo.date, style: .relative)
                                                        .font(.caption2)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            Button("View on WordPress") {
                                                if let url = URL(string: publishInfo.url) {
                                                    NSWorkspace.shared.open(url)
                                                }
                                            }
                                            .font(.caption)
                                        }
                                        .padding(.vertical, 4)

                                        Divider()
                                            .padding(.vertical, 4)
                                    }

                                    HStack {
                                        Image(systemName: "info.circle")
                                            .foregroundColor(.blue)
                                        Text("Use **⌘⇧P** or Command Palette to publish")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }

                        // Custom fields section
                        GroupBox("Custom Fields") {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach($customFields) { $field in
                                    HStack {
                                        TextField("Key", text: $field.key)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(width: 80)
                                        TextField("Value", text: $field.value)
                                            .textFieldStyle(.roundedBorder)
                                        Button {
                                            customFields.removeAll { $0.id == field.id }
                                            updateDocument()
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(.red)
                                        }
                                        .buttonStyle(.animatedIcon)
                                    }
                                    .onChange(of: field.key) { _, _ in updateDocument() }
                                    .onChange(of: field.value) { _, _ in updateDocument() }
                                }

                                Button {
                                    customFields.append(CustomField(key: "", value: ""))
                                } label: {
                                    Label("Add Field", systemImage: "plus.circle")
                                }
                                .buttonStyle(.animatedIcon)
                            }
                            .padding(.vertical, 4)
                        }

                        // Actions
                        HStack {
                            Button("Remove Frontmatter") {
                                removeFrontmatter()
                            }
                            .foregroundColor(.red)

                            Spacer()
                        }
                    }
                }

                Spacer()
            }
            .padding()
        }
        .frame(width: 280)
        .background(VisualEffectBackground(material: .sidebar))
        .onAppear { loadFrontmatter() }
        .onChange(of: appState.currentDocument.content) { _, _ in
            // Don't reload if we're the ones updating the content
            if !isUpdating {
                loadFrontmatter()
            }
        }
        .alert("Convert Frontmatter Type?", isPresented: $showConversionAlert) {
            Button("Cancel", role: .cancel) {
                // Revert to previous selection
                if let conversion = pendingConversion {
                    selectedSSG = conversion.from
                }
                pendingConversion = nil
            }
            Button("Convert") {
                if let conversion = pendingConversion {
                    performConversion(from: conversion.from, to: conversion.to)
                }
                pendingConversion = nil
            }
        } message: {
            if let conversion = pendingConversion {
                Text(conversionWarningMessage(from: conversion.from, to: conversion.to))
            }
        }
    }

    // MARK: - Computed Properties

    private var timezoneDisplayName: String {
        if timezoneIdentifier.isEmpty {
            return "System Default"
        }
        guard let tz = TimeZone(identifier: timezoneIdentifier) else {
            return timezoneIdentifier
        }
        let seconds = tz.secondsFromGMT()
        let hours = abs(seconds) / 3600
        let minutes = (abs(seconds) % 3600) / 60
        let sign = seconds >= 0 ? "+" : "-"
        let offset = String(format: "%@%02d:%02d", sign, hours, minutes)
        // Get a friendly name if available
        let name = tz.localizedName(for: .shortGeneric, locale: .current) ?? timezoneIdentifier
        return "\(name) (\(offset))"
    }

    private var timezoneShortName: String {
        let tz: TimeZone
        if !timezoneIdentifier.isEmpty, let customTZ = TimeZone(identifier: timezoneIdentifier) {
            tz = customTZ
        } else {
            tz = TimeZone.current
        }
        // Return abbreviation like "PST", "EST", "UTC"
        return tz.abbreviation() ?? tz.identifier
    }

    // MARK: - Helper Views

    struct LabeledField<Content: View>: View {
        let label: String
        let content: Content

        init(_ label: String, @ViewBuilder content: () -> Content) {
            self.label = label
            self.content = content()
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                content
            }
        }
    }

    // MARK: - Actions

    private func loadFrontmatter() {
        let (parsed, _) = Frontmatter.parse(from: appState.currentDocument.content)
        frontmatter = parsed
        hasFrontmatter = parsed != nil

        if let fm = parsed {
            title = fm.title ?? ""
            author = fm.author ?? ""
            layout = fm.layout ?? ""
            description = fm.description ?? ""
            draft = fm.draft
            hasDate = fm.date != nil
            date = fm.date ?? Date()
            includeTime = fm.includeDateWithTime
            tags = fm.tags.joined(separator: ", ")
            categories = fm.categories.joined(separator: ", ")

            // Load custom fields (non-standard fields)
            let standardKeys = Set(["title", "author", "layout", "description", "draft", "date", "tags", "categories"])
            customFields = fm.fields.compactMap { key, value in
                guard !standardKeys.contains(key) else { return nil }
                return CustomField(key: key, value: value.stringValue ?? "")
            }

            // Detect SSG type from frontmatter characteristics
            detectSSGType(from: fm)
        } else {
            // Reset to defaults
            title = ""
            author = ""
            layout = ""
            description = ""
            draft = false
            hasDate = false
            date = Date()
            includeTime = false
            tags = ""
            categories = ""
            customFields = []
        }
    }

    private func detectSSGType(from fm: Frontmatter) {
        // Detection logic:
        // 1. TOML format -> Hugo
        // 2. Has layout field -> likely Jekyll or Hugo (default to Jekyll)
        // 3. No layout but has description -> possibly WordPress
        // 4. Default to Jekyll (most common)

        if fm.format == .toml {
            selectedSSG = .hugo
        } else if fm.layout != nil {
            // Both Jekyll and Hugo use layout, default to Jekyll
            selectedSSG = .jekyll
        } else if fm.layout == nil && fm.description != nil && PluginManager.shared.isLoaded("com.tibok.wordpress-export") {
            // No layout but has description - possibly WordPress
            selectedSSG = .wordpress
        } else {
            // Default to Jekyll
            selectedSSG = .jekyll
        }
    }

    private func createFrontmatter() {
        var fm = Frontmatter(format: selectedFormat)
        fm.title = appState.currentDocument.title.replacingOccurrences(of: ".md", with: "")
        fm.date = Date()
        fm.timezoneIdentifier = timezoneIdentifier

        // Apply defaults based on SSG type
        switch selectedSSG {
        case .jekyll:
            // Jekyll defaults
            fm.draft = jekyllDraft
            if !jekyllAuthor.isEmpty { fm.author = jekyllAuthor }
            if !jekyllLayout.isEmpty { fm.layout = jekyllLayout }
            if !jekyllTags.isEmpty {
                fm.tags = jekyllTags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            }
            if !jekyllCategories.isEmpty {
                fm.categories = jekyllCategories.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            }
        case .hugo:
            // Hugo defaults
            fm.draft = hugoDraft
            if !hugoAuthor.isEmpty { fm.author = hugoAuthor }
            if !hugoLayout.isEmpty { fm.layout = hugoLayout }
            if !hugoTags.isEmpty {
                fm.tags = hugoTags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            }
            if !hugoCategories.isEmpty {
                fm.categories = hugoCategories.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            }
        case .wordpress:
            // WordPress defaults
            fm.draft = wordpressStatus == "draft"
            if !wordpressAuthor.isEmpty { fm.author = wordpressAuthor }
            if !wordpressDescription.isEmpty { fm.description = wordpressDescription }
            if !wordpressCategories.isEmpty {
                fm.categories = wordpressCategories.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            }
        }

        let newContent = fm.apply(to: appState.currentDocument.content)
        appState.updateActiveDocumentContent(newContent)
    }

    private func updateDocument() {
        guard hasFrontmatter, var fm = frontmatter else { return }

        // Update frontmatter from form fields
        fm.title = title.isEmpty ? nil : title
        fm.author = author.isEmpty ? nil : author
        fm.layout = layout.isEmpty ? nil : layout
        fm.description = description.isEmpty ? nil : description
        fm.draft = draft
        fm.date = hasDate ? date : nil
        fm.includeDateWithTime = includeTime
        fm.timezoneIdentifier = timezoneIdentifier

        // Parse tags and categories
        fm.tags = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        fm.categories = categories.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

        // Add custom fields
        for field in customFields where !field.key.isEmpty {
            fm.fields[field.key] = .string(field.value)
        }

        // Apply to document
        let newContent = fm.apply(to: appState.currentDocument.content)
        if newContent != appState.currentDocument.content {
            isUpdating = true
            appState.updateActiveDocumentContent(newContent)

            // Invalidate frontmatter cache for this file
            if let fileURL = appState.currentDocument.fileURL {
                FrontmatterCacheService.shared.invalidate(url: fileURL)
            }

            // Reset flag after a brief delay to allow change to propagate
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isUpdating = false
            }
        }

        frontmatter = fm
    }

    private func removeFrontmatter() {
        let (_, body) = Frontmatter.parse(from: appState.currentDocument.content)
        appState.updateActiveDocumentContent(body)
    }

    private func convertFrontmatterType(from oldType: SSGType, to newType: SSGType) {
        // Show warning dialog
        pendingConversion = (from: oldType, to: newType)
        showConversionAlert = true
    }

    private func conversionWarningMessage(from oldType: SSGType, to newType: SSGType) -> String {
        var message = "Converting from \(oldType.rawValue) to \(newType.rawValue) will transform the frontmatter.\n\n"

        // Specific warnings based on conversion type
        switch (oldType, newType) {
        case (.jekyll, .hugo), (.hugo, .jekyll):
            message += "• Layout field will be preserved\n"
            message += "• All standard fields will be kept\n"
            if newType == .hugo {
                message += "• Format will remain YAML (use settings to change Hugo default to TOML)"
            }

        case (.jekyll, .wordpress), (.hugo, .wordpress):
            message += "⚠️ Layout field will be removed (not used in WordPress)\n"
            message += "• Description field will be used for post excerpt\n"
            message += "• Categories and tags will be used for WordPress taxonomy"

        case (.wordpress, .jekyll), (.wordpress, .hugo):
            message += "• Description will be preserved\n"
            message += "• Default layout will be added for \(newType.rawValue)\n"
            message += "• All other fields will be kept"

        default:
            message += "Common fields (title, date, author, tags, categories) will be preserved."
        }

        return message
    }

    private func performConversion(from oldType: SSGType, to newType: SSGType) {
        guard hasFrontmatter, var fm = frontmatter else { return }

        // Transform format-specific fields
        switch (oldType, newType) {
        case (.jekyll, .hugo):
            // Jekyll to Hugo: mostly compatible, keep layout
            // Hugo prefers YAML by default unless settings say otherwise
            if hugoDefaultFormat == "toml" {
                fm.format = .toml
                selectedFormat = .toml
            }
            // Add Hugo-specific defaults if not present
            if fm.layout == nil && !hugoLayout.isEmpty {
                fm.layout = hugoLayout
            }

        case (.hugo, .jekyll):
            // Hugo to Jekyll: convert TOML to YAML if needed
            fm.format = .yaml
            selectedFormat = .yaml
            // Add Jekyll-specific defaults if not present
            if fm.layout == nil && !jekyllLayout.isEmpty {
                fm.layout = jekyllLayout
            }

        case (.jekyll, .wordpress), (.hugo, .wordpress):
            // To WordPress: remove layout field, ensure description exists
            fm.layout = nil
            layout = ""
            if fm.description == nil && !wordpressDescription.isEmpty {
                fm.description = wordpressDescription
                description = wordpressDescription
            }
            // WordPress always uses YAML
            fm.format = .yaml
            selectedFormat = .yaml

        case (.wordpress, .jekyll):
            // WordPress to Jekyll: add layout field
            if !jekyllLayout.isEmpty {
                fm.layout = jekyllLayout
                layout = jekyllLayout
            }

        case (.wordpress, .hugo):
            // WordPress to Hugo: add layout field
            if !hugoLayout.isEmpty {
                fm.layout = hugoLayout
                layout = hugoLayout
            }
            // Check if Hugo default is TOML
            if hugoDefaultFormat == "toml" {
                fm.format = .toml
                selectedFormat = .toml
            }

        default:
            break
        }

        // Apply the converted frontmatter to document
        let newContent = fm.apply(to: appState.currentDocument.content)
        if newContent != appState.currentDocument.content {
            isUpdating = true
            appState.updateActiveDocumentContent(newContent)

            // Invalidate cache
            if let fileURL = appState.currentDocument.fileURL {
                FrontmatterCacheService.shared.invalidate(url: fileURL)
            }

            // Reload the frontmatter to update UI
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                loadFrontmatter()
                isUpdating = false
            }
        }

        frontmatter = fm
    }
}
