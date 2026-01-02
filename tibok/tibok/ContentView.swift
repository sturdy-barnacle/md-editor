//
//  ContentView.swift
//  tibok
//
//  Main content view with sidebar, editor, and preview panes.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var uiState = UIStateService.shared
    @AppStorage("appearanceMode") private var appearanceMode: String = AppearanceMode.system.rawValue
    @AppStorage(SettingsKeys.editorFocusMode) private var editorFocusMode: Bool = false
    @AppStorage("ui.previewVisible") private var previewVisible = true
    @AppStorage("ui.sidebarVisible") private var sidebarVisible = true
    @State private var focusMode = false
    @State private var showCommandPalette = false
    @State private var showDocumentPopover = false
    @State private var showGitCommitSheet = false
    @State private var gitCommitMessage = ""
    @State private var pendingGitCommitMessage: String?
    @AppStorage("ui.showInspector") private var showInspector = false

    // Store state before focus mode to restore later
    @State private var preFocusSidebarVisible = true
    @State private var preFocusPreviewVisible = true

    private var windowTitle: String {
        let docName = appState.currentDocument.fileURL?.lastPathComponent ?? "Untitled.md"
        let modified = appState.currentDocument.isModified ? " •" : ""
        return "\(docName)\(modified)"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom title bar (hidden in focus mode)
            if !focusMode {
                TitleBarView(
                    sidebarVisible: $sidebarVisible,
                    previewVisible: $previewVisible,
                    showInspector: $showInspector,
                    showDocumentPopover: $showDocumentPopover,
                    appearanceMode: $appearanceMode,
                    applyAppearance: applyAppearance
                )
                .environmentObject(appState)

                // Tab bar (always shown for consistent layout)
                if !appState.documents.isEmpty {
                    TabBarView()
                        .environmentObject(appState)
                }
            }

            // Main content area
            HSplitView {
                // Sidebar (toggleable, hidden in focus mode)
                if sidebarVisible && !focusMode {
                    SidebarView()
                        .frame(minWidth: 140, idealWidth: 180, maxWidth: 300)
                }

                // Editor
                EditorView()
                    .frame(minWidth: 300)

                // Preview (toggleable, hidden in focus mode)
                if previewVisible && !focusMode {
                    PreviewView()
                        .frame(minWidth: 300)
                }

                // Inspector panel (toggleable, hidden in focus mode)
                if showInspector && !focusMode {
                    FrontmatterInspectorView()
                        .environmentObject(appState)
                }
            }

            // Status bar at bottom (hidden in focus mode)
            if !focusMode {
                StatusBarView()
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .overlay(alignment: .top) {
            // Toast notification - transition handles animation without affecting other views
            if let message = uiState.toastMessage {
                ToastView(message: message, icon: uiState.toastIcon)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 60)
            }
        }
        .onAppear {
            registerCommands()
            // Aggressively activate the app and make window key for keyboard input
            NSApplication.shared.setActivationPolicy(.regular)
            NSApplication.shared.activate(ignoringOtherApps: true)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                if let window = NSApplication.shared.windows.first {
                    window.makeKeyAndOrderFront(nil)
                    window.makeKey()
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                if let window = NSApplication.shared.windows.first {
                    window.makeKey()
                    if let editor = window.firstResponder as? NSTextView {
                        window.makeFirstResponder(editor)
                    }
                }
            }
        }
        .sheet(isPresented: $showCommandPalette) {
            CommandPaletteSheet(isPresented: $showCommandPalette)
        }
        .sheet(isPresented: $appState.showWelcomeSheet) {
            WelcomeView(
                onDismiss: {
                    appState.showWelcomeSheet = false
                },
                onOpenFolder: {
                    appState.openWorkspace()
                }
            )
            .environmentObject(appState)
        }
        .onReceive(NotificationCenter.default.publisher(for: .showCommandPalette)) { _ in
            showCommandPalette = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .togglePreview)) { _ in
            withAnimation {
                previewVisible.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleSidebar)) { _ in
            withAnimation {
                sidebarVisible.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleFocusMode)) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                if focusMode {
                    // Exit focus mode - restore previous state
                    focusMode = false
                    sidebarVisible = preFocusSidebarVisible
                    previewVisible = preFocusPreviewVisible
                } else {
                    // Enter focus mode - save state and hide everything
                    preFocusSidebarVisible = sidebarVisible
                    preFocusPreviewVisible = previewVisible
                    focusMode = true
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showGitCommit)) { _ in
            showGitCommitSheet = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleEditorFocusMode)) { _ in
            editorFocusMode.toggle()
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleInspector)) { _ in
            withAnimation {
                showInspector.toggle()
            }
        }
        .sheet(isPresented: $showGitCommitSheet, onDismiss: {
            if let message = pendingGitCommitMessage {
                let result = appState.commitChanges(message: message)
                if result.success {
                    appState.refreshGitStatus()
                    gitCommitMessage = ""
                } else {
                    showGitError("Commit Failed", result.error)
                }
                pendingGitCommitMessage = nil
            }
        }) {
            GitCommitSheet(
                message: $gitCommitMessage,
                stagedCount: appState.stagedFiles.count,
                onCommit: {
                    pendingGitCommitMessage = gitCommitMessage
                    showGitCommitSheet = false
                },
                onCancel: {
                    showGitCommitSheet = false
                }
            )
        }
    }

    private func applyAppearance(_ mode: AppearanceMode) {
        switch mode {
        case .system:
            NSApp.appearance = nil
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }

    private func registerCommands() {
        let registry = CommandService.shared

        registry.register([
            // File commands
            Command(
                id: "file.new",
                title: "New Document",
                icon: "doc.badge.plus",
                shortcut: KeyboardShortcut("n", modifiers: .command),
                category: .file
            ) { appState.createNewDocument() },

            Command(
                id: "file.open",
                title: "Open File...",
                icon: "doc",
                shortcut: KeyboardShortcut("o", modifiers: .command),
                category: .file
            ) { appState.openDocument() },

            Command(
                id: "file.openFolder",
                title: "Open Folder...",
                icon: "folder",
                shortcut: KeyboardShortcut("o", modifiers: [.command, .shift]),
                category: .file
            ) { appState.openWorkspace() },

            Command(
                id: "file.save",
                title: "Save",
                icon: "square.and.arrow.down",
                shortcut: KeyboardShortcut("s", modifiers: .command),
                category: .file
            ) { appState.saveCurrentDocument() },

            Command(
                id: "file.saveAs",
                title: "Save As...",
                icon: "square.and.arrow.down.on.square",
                shortcut: KeyboardShortcut("s", modifiers: [.command, .shift]),
                category: .file
            ) { appState.saveDocumentAs() },

            // View commands
            Command(
                id: "view.toggleSidebar",
                title: "Toggle Sidebar",
                subtitle: sidebarVisible ? "Hide sidebar" : "Show sidebar",
                icon: "sidebar.left",
                shortcut: KeyboardShortcut("0", modifiers: .command),
                category: .view
            ) { sidebarVisible.toggle() },

            Command(
                id: "view.togglePreview",
                title: "Toggle Preview",
                subtitle: previewVisible ? "Hide preview pane" : "Show preview pane",
                icon: previewVisible ? "eye.slash" : "eye",
                shortcut: KeyboardShortcut("\\", modifiers: .command),
                category: .view
            ) { previewVisible.toggle() },

            Command(
                id: "view.focusMode",
                title: "Focus Mode",
                subtitle: focusMode ? "Exit focus mode" : "Enter distraction-free writing",
                icon: focusMode ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right",
                shortcut: KeyboardShortcut(".", modifiers: [.command, .control]),
                category: .view
            ) {
                NotificationCenter.default.post(name: .toggleFocusMode, object: nil)
            },

            Command(
                id: "view.toggleInspector",
                title: "Toggle Inspector",
                subtitle: showInspector ? "Hide frontmatter inspector" : "Show frontmatter inspector",
                icon: "pencil",
                shortcut: KeyboardShortcut("i", modifiers: .command),
                category: .view
            ) {
                NotificationCenter.default.post(name: .toggleInspector, object: nil)
            },

            // Export commands
            Command(
                id: "export.pdf",
                title: "Export as PDF",
                icon: "doc.richtext",
                category: .export
            ) { appState.exportAsPDF() },

            Command(
                id: "export.html",
                title: "Export as HTML",
                icon: "doc.text",
                category: .export
            ) { appState.exportAsHTML() },

            Command(
                id: "export.rtf",
                title: "Export as RTF",
                icon: "doc.plaintext",
                category: .export
            ) { appState.exportAsRTF() },

            Command(
                id: "export.txt",
                title: "Export as Plain Text",
                icon: "doc.text",
                category: .export
            ) { appState.exportAsPlainText() },

            Command(
                id: "export.wordpress",
                title: "Export to WordPress",
                icon: "envelope.fill",
                category: .export
            ) { appState.exportToWordPress() },

            Command(
                id: "export.copyMarkdown",
                title: "Copy as Markdown",
                icon: "doc.on.clipboard",
                category: .export
            ) { appState.copyAsMarkdown() },

            // Edit commands
            Command(
                id: "edit.find",
                title: "Find...",
                icon: "magnifyingglass",
                shortcut: KeyboardShortcut("f", modifiers: .command),
                category: .edit
            ) { performFind(.showFindPanel) },

            Command(
                id: "edit.findReplace",
                title: "Find and Replace...",
                icon: "arrow.left.arrow.right",
                shortcut: KeyboardShortcut("f", modifiers: [.command, .option]),
                category: .edit
            ) { performFind(.replace) },

            // Tab commands
            Command(
                id: "tab.close",
                title: "Close Tab",
                icon: "xmark.square",
                shortcut: KeyboardShortcut("w", modifiers: .command),
                category: .file
            ) { appState.closeCurrentTab() },

            Command(
                id: "tab.closeOthers",
                title: "Close Other Tabs",
                icon: "xmark.square.fill",
                category: .file
            ) {
                if let id = appState.activeDocumentID {
                    appState.closeOtherTabs(except: id)
                }
            },

            Command(
                id: "tab.closeAll",
                title: "Close All Tabs",
                icon: "xmark.rectangle",
                category: .file
            ) { appState.closeAllTabs() },

            Command(
                id: "tab.reopen",
                title: "Reopen Closed Tab",
                icon: "arrow.uturn.backward",
                shortcut: KeyboardShortcut("t", modifiers: [.command, .shift]),
                category: .file
            ) { appState.reopenLastClosedTab() },

            Command(
                id: "tab.next",
                title: "Next Tab",
                icon: "arrow.right.square",
                shortcut: KeyboardShortcut("]", modifiers: [.command, .shift]),
                category: .view
            ) { appState.nextTab() },

            Command(
                id: "tab.previous",
                title: "Previous Tab",
                icon: "arrow.left.square",
                shortcut: KeyboardShortcut("[", modifiers: [.command, .shift]),
                category: .view
            ) { appState.previousTab() },

            // Git commands
            Command(
                id: "git.stageAll",
                title: "Stage All Changes",
                icon: "plus.circle",
                category: .git
            ) { appState.stageAll() },

            Command(
                id: "git.unstageAll",
                title: "Unstage All",
                icon: "minus.circle",
                category: .git
            ) { appState.unstageAll() },

            Command(
                id: "git.commit",
                title: "Commit...",
                icon: "checkmark.circle",
                shortcut: KeyboardShortcut("k", modifiers: [.command, .shift]),
                category: .git
            ) { showGitCommitSheet = true },

            Command(
                id: "git.push",
                title: "Push",
                icon: "arrow.up.circle",
                category: .git
            ) {
                let result = appState.pushChanges()
                if result.success {
                    if result.alreadyUpToDate {
                        UIStateService.shared.showToast("Already up to date", icon: "checkmark.circle.fill", duration: 2.0)
                    } else {
                        UIStateService.shared.showToast("Push successful", icon: "checkmark.circle.fill", duration: 2.0)
                    }
                } else {
                    let errorMessage = result.error ?? "Unknown error occurred during push"
                    UIStateService.shared.showToast(
                        "Push failed: \(errorMessage)",
                        icon: "xmark.circle",
                        duration: 3.0
                    )
                }
            },

            Command(
                id: "git.pull",
                title: "Pull",
                icon: "arrow.down.circle",
                category: .git
            ) {
                let result = appState.pullChanges()
                if result.success {
                    UIStateService.shared.showToast("Pull successful", icon: "checkmark.circle.fill", duration: 2.0)
                } else {
                    let errorMessage = result.error ?? "Unknown error occurred during pull"
                    UIStateService.shared.showToast(
                        "Pull failed: \(errorMessage)",
                        icon: "xmark.circle",
                        duration: 3.0
                    )
                }
            },

            Command(
                id: "git.refresh",
                title: "Refresh Git Status",
                icon: "arrow.clockwise",
                category: .git
            ) { appState.refreshGitStatus() }
        ])
    }
}

// MARK: - Document Popover

struct DocumentPopover: View {
    @EnvironmentObject var appState: AppState
    @Binding var isPresented: Bool
    @State private var isRenaming = false
    @State private var newName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // File info header
            if let url = appState.currentDocument.fileURL {
                VStack(alignment: .leading, spacing: 4) {
                    Text(url.lastPathComponent)
                        .font(.system(size: 13, weight: .semibold))

                    Text(url.deletingLastPathComponent().path)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

                Divider()
            }

            // Actions
            VStack(spacing: 0) {
                if isRenaming {
                    HStack {
                        TextField("Filename", text: $newName)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                performRename()
                            }

                        Button("Rename") {
                            performRename()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .padding(12)
                } else {
                    if appState.currentDocument.fileURL != nil {
                        PopoverButton(title: "Rename...", icon: "pencil") {
                            newName = appState.currentDocument.fileURL?.deletingPathExtension().lastPathComponent ?? ""
                            isRenaming = true
                        }

                        PopoverButton(title: "Move To...", icon: "folder") {
                            moveDocument()
                        }

                        PopoverButton(title: "Reveal in Finder", icon: "arrow.right.circle") {
                            if let url = appState.currentDocument.fileURL {
                                appState.revealInFinder(url)
                            }
                            isPresented = false
                        }

                        Divider()
                            .padding(.vertical, 4)
                    }

                    PopoverButton(title: "Save", icon: "square.and.arrow.down", shortcut: "⌘S") {
                        appState.saveCurrentDocument()
                        isPresented = false
                    }

                    PopoverButton(title: "Save As...", icon: "square.and.arrow.down.on.square", shortcut: "⇧⌘S") {
                        appState.saveDocumentAs()
                        isPresented = false
                    }

                    PopoverButton(title: "Duplicate", icon: "plus.square.on.square") {
                        duplicateDocument()
                    }
                }
            }
            .padding(.vertical, 6)
        }
        .frame(width: 220)
    }

    private func performRename() {
        guard !newName.isEmpty,
              let currentURL = appState.currentDocument.fileURL else {
            isRenaming = false
            return
        }

        let newFileName = newName.hasSuffix(".md") ? newName : "\(newName).md"
        let newURL = currentURL.deletingLastPathComponent().appendingPathComponent(newFileName)

        do {
            try FileManager.default.moveItem(at: currentURL, to: newURL)
            appState.currentDocument.fileURL = newURL
            appState.currentDocument.title = newURL.deletingPathExtension().lastPathComponent
        } catch {
            // Error handled silently - user can retry
        }

        isRenaming = false
        isPresented = false
    }

    private func moveDocument() {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = appState.currentDocument.fileURL?.lastPathComponent ?? "Untitled.md"

        if panel.runModal() == .OK, let newURL = panel.url {
            if let currentURL = appState.currentDocument.fileURL {
                do {
                    try FileManager.default.moveItem(at: currentURL, to: newURL)
                    appState.currentDocument.fileURL = newURL
                    appState.currentDocument.title = newURL.deletingPathExtension().lastPathComponent
                } catch {
                    // Error handled silently - user can retry
                }
            } else {
                // Save new document to chosen location
                do {
                    try appState.currentDocument.content.write(to: newURL, atomically: true, encoding: .utf8)
                    appState.currentDocument.fileURL = newURL
                    appState.currentDocument.title = newURL.deletingPathExtension().lastPathComponent
                    appState.currentDocument.isModified = false
                } catch {
                    // Error handled silently - user can retry
                }
            }
        }
        isPresented = false
    }

    private func duplicateDocument() {
        guard let currentURL = appState.currentDocument.fileURL else {
            // For unsaved documents, just create a new one with same content
            let content = appState.currentDocument.content
            appState.createNewDocument()
            appState.currentDocument.content = content
            isPresented = false
            return
        }

        let baseName = currentURL.deletingPathExtension().lastPathComponent
        let ext = currentURL.pathExtension
        let directory = currentURL.deletingLastPathComponent()

        var counter = 1
        var newURL = directory.appendingPathComponent("\(baseName) copy.\(ext)")
        while FileManager.default.fileExists(atPath: newURL.path) {
            counter += 1
            newURL = directory.appendingPathComponent("\(baseName) copy \(counter).\(ext)")
        }

        do {
            try FileManager.default.copyItem(at: currentURL, to: newURL)
            appState.loadDocument(from: newURL)
        } catch {
            // Error handled silently - user can retry
        }
        isPresented = false
    }
}

struct PopoverButton: View {
    let title: String
    let icon: String
    var shortcut: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 16)
                    .foregroundColor(.secondary)
                Text(title)
                Spacer()
                if let shortcut = shortcut {
                    Text(shortcut)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Toast View

struct ToastView: View {
    let message: String
    let icon: String?

    var body: some View {
        HStack(spacing: 8) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.green)
            }
            Text(message)
                .font(.system(size: 13, weight: .medium))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Command Palette Notification

extension Notification.Name {
    static let showCommandPalette = Notification.Name("showCommandPalette")
    static let togglePreview = Notification.Name("togglePreview")
    static let toggleSidebar = Notification.Name("toggleSidebar")
    static let toggleFocusMode = Notification.Name("toggleFocusMode")
    static let toggleEditorFocusMode = Notification.Name("toggleEditorFocusMode")
    static let performFormatting = Notification.Name("performFormatting")
    static let showGitCommit = Notification.Name("showGitCommit")
    static let toggleInspector = Notification.Name("toggleInspector")
}

// MARK: - Command Palette Sheet

struct CommandPaletteSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject var registry: CommandService = .shared
    @State private var searchText = ""
    @State private var selectedIndex = 0

    private var filteredCommands: [Command] {
        registry.search(searchText)
    }

    /// Group commands by category when no search query
    private var groupedCommands: [(category: CommandCategory, commands: [Command])] {
        if !searchText.isEmpty {
            return []  // Don't group when searching
        }
        var groups: [CommandCategory: [Command]] = [:]
        for command in filteredCommands {
            groups[command.category, default: []].append(command)
        }
        // Sort by category order
        let categoryOrder: [CommandCategory] = [.file, .edit, .view, .export, .git]
        return categoryOrder.compactMap { category in
            if let commands = groups[category], !commands.isEmpty {
                return (category, commands)
            }
            return nil
        }
    }

    /// Flat list for keyboard navigation with section info
    private var flatCommandsWithSections: [(command: Command, isFirstInCategory: Bool, category: CommandCategory?)] {
        if !searchText.isEmpty {
            return filteredCommands.map { ($0, false, nil) }
        }
        var result: [(Command, Bool, CommandCategory?)] = []
        for (category, commands) in groupedCommands {
            for (index, command) in commands.enumerated() {
                result.append((command, index == 0, category))
            }
        }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Search commands...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))

                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()

            Divider()

            // Command list with optional category headers
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(flatCommandsWithSections.enumerated()), id: \.offset) { index, item in
                            VStack(spacing: 0) {
                                // Category header (only when not searching)
                                if item.isFirstInCategory, let category = item.category {
                                    HStack {
                                        Text(category.rawValue.uppercased())
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.top, index == 0 ? 4 : 12)
                                    .padding(.bottom, 4)
                                }

                                CommandRow(command: item.command, isSelected: index == selectedIndex, showCategory: !searchText.isEmpty)
                                    .id(index)
                                    .onTapGesture {
                                        selectedIndex = index
                                        executeSelected()
                                    }
                            }
                        }

                        if filteredCommands.isEmpty {
                            Text("No commands found")
                                .foregroundColor(.secondary)
                                .padding(.vertical, 20)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onChange(of: selectedIndex) { _, newIndex in
                    withAnimation(.easeOut(duration: 0.15)) {
                        proxy.scrollTo(newIndex, anchor: nil)
                    }
                }
            }

            Divider()

            // Footer with instructions
            HStack(spacing: 16) {
                Text("↑↓ Navigate")
                Text("↩ Execute")
                Text("esc Cancel")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(8)
        }
        .frame(width: 500, height: 400)
        .onKeyPress(.upArrow) {
            moveSelection(by: -1)
            return .handled
        }
        .onKeyPress(.downArrow) {
            moveSelection(by: 1)
            return .handled
        }
        .onKeyPress(.return) {
            executeSelected()
            return .handled
        }
        .onChange(of: searchText) { _, _ in
            selectedIndex = 0
        }
    }

    private func moveSelection(by offset: Int) {
        let newIndex = selectedIndex + offset
        let count = searchText.isEmpty ? flatCommandsWithSections.count : filteredCommands.count
        if newIndex >= 0 && newIndex < count {
            selectedIndex = newIndex
        }
    }

    private func executeSelected() {
        let commands = searchText.isEmpty ? flatCommandsWithSections.map { $0.command } : filteredCommands
        guard selectedIndex < commands.count else { return }
        let command = commands[selectedIndex]
        isPresented = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            registry.execute(command)
        }
    }
}

// MARK: - Command Row

struct CommandRow: View {
    let command: Command
    let isSelected: Bool
    var showCategory: Bool = true

    var body: some View {
        HStack(spacing: 10) {
            if let icon = command.icon {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? .white : .secondary)
                    .frame(width: 20)
            } else {
                Image(systemName: command.category.icon)
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? .white : .secondary)
                    .frame(width: 20)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(command.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)

                if let subtitle = command.subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
            }

            Spacer()

            // Only show category badge when searching (categories have headers otherwise)
            if showCategory {
                Text(command.category.rawValue)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.white.opacity(0.2) : Color.primary.opacity(0.08))
                    .cornerRadius(4)
            }

            if let shortcut = command.shortcut {
                Text(shortcut.displayString)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor : Color.clear)
        .cornerRadius(6)
        .contentShape(Rectangle())
    }
}

// MARK: - Title Bar

struct TitleBarView: View {
    @EnvironmentObject var appState: AppState
    @Binding var sidebarVisible: Bool
    @Binding var previewVisible: Bool
    @Binding var showInspector: Bool
    @Binding var showDocumentPopover: Bool
    @Binding var appearanceMode: String
    let applyAppearance: (AppearanceMode) -> Void

    private var appearanceIcon: String {
        switch AppearanceMode(rawValue: appearanceMode) ?? .system {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon.fill"
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left side - sidebar toggle
            TitleBarButton(icon: "sidebar.left", help: "Toggle Sidebar (⌘0)") {
                withAnimation { sidebarVisible.toggle() }
            }
            .padding(.leading, 12)

            Spacer()

            // Center - document name (hidden in empty state)
            if !appState.currentDocument.isEmpty {
                Button {
                    showDocumentPopover.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Text(appState.currentDocument.fileURL?.lastPathComponent ?? "Untitled.md")
                            .font(.system(size: 13, weight: .medium))
                        // Show indicator for unsaved (no file) or modified documents
                        if appState.currentDocument.fileURL == nil {
                            Text("— Edited")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        } else if appState.currentDocument.isModified {
                            Circle()
                                .fill(Color.primary.opacity(0.5))
                                .frame(width: 6, height: 6)
                        }
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showDocumentPopover, arrowEdge: .bottom) {
                    DocumentPopover(isPresented: $showDocumentPopover)
                        .environmentObject(appState)
                }
            }

            Spacer()

            // Right side - actions
            HStack(spacing: 12) {
                TitleBarButton(icon: previewVisible ? "eye" : "eye.slash", help: "Toggle Preview (⌘\\)") {
                    withAnimation { previewVisible.toggle() }
                }

                TitleBarButton(icon: "pencil", help: "Toggle Inspector (⌘I)") {
                    withAnimation { showInspector.toggle() }
                }

                TitleBarMenuButton(
                    icon: appearanceIcon,
                    help: "Appearance",
                    menuItems: AppearanceMode.allCases.map { mode in
                        MenuItemConfig(
                            title: mode.displayName,
                            action: {
                                appearanceMode = mode.rawValue
                                applyAppearance(mode)
                            }
                        )
                    }
                )

                TitleBarButton(icon: "doc.on.doc", help: "Copy as Markdown") {
                    appState.copyAsMarkdown()
                }

                TitleBarMenuButton(
                    icon: "square.and.arrow.up",
                    help: "Export",
                    menuItems: createExportMenuItems(appState: appState)
                )
            }
            .padding(.trailing, 12)
        }
        .frame(height: 38)
        .background(Color(NSColor.textBackgroundColor))
        .overlay(
            Rectangle()
                .fill(Color.primary.opacity(0.03))
                .allowsHitTesting(false)
        )
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.primary.opacity(0.08)),
            alignment: .bottom
        )
    }
}

struct TitleBarButton: View {
    let icon: String
    let help: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(isHovered ? .primary : .secondary)
            .frame(width: 24, height: 24)
            .scaleEffect(isHovered ? 1.1 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isHovered)
            .contentShape(Rectangle())
            .onTapGesture { action() }
            .onHover { isHovered = $0 }
            .help(help)
    }
}

// MARK: - Menu Item Structure

struct MenuItemConfig {
    let title: String
    let action: () -> Void
    let isEnabled: Bool
    let disabledReason: String?

    init(title: String, action: @escaping () -> Void, isEnabled: Bool = true, disabledReason: String? = nil) {
        self.title = title
        self.action = action
        self.isEnabled = isEnabled
        self.disabledReason = disabledReason
    }
}

struct TitleBarMenuButton: View {
    let icon: String
    let help: String
    let menuItems: [MenuItemConfig]

    @State private var isHovered = false
    @State private var isShowingMenu = false

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(isHovered ? .primary : .secondary)
            .frame(width: 24, height: 24)
            .contentShape(Rectangle())
            .onTapGesture { isShowingMenu = true }
            .onHover { isHovered = $0 }
            .help(help)
            .background(
                MenuTrigger(isPresented: $isShowingMenu, menuItems: menuItems)
            )
    }
}

struct MenuTrigger: NSViewRepresentable {
    @Binding var isPresented: Bool
    let menuItems: [MenuItemConfig]

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 24, height: 24))
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if isPresented {
            DispatchQueue.main.async {
                let menu = NSMenu()
                for (index, item) in menuItems.enumerated() {
                    let menuItem = NSMenuItem(title: item.title, action: #selector(context.coordinator.menuItemClicked(_:)), keyEquivalent: "")
                    menuItem.target = context.coordinator
                    menuItem.tag = index
                    menuItem.isEnabled = item.isEnabled

                    // Add tooltip for disabled items
                    if !item.isEnabled, let reason = item.disabledReason {
                        menuItem.toolTip = reason
                    }

                    menu.addItem(menuItem)
                }
                let point = NSPoint(x: 0, y: nsView.bounds.height)
                menu.popUp(positioning: nil, at: point, in: nsView)
                isPresented = false
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(menuItems: menuItems)
    }

    class Coordinator: NSObject {
        let menuItems: [MenuItemConfig]

        init(menuItems: [MenuItemConfig]) {
            self.menuItems = menuItems
        }

        @objc func menuItemClicked(_ sender: NSMenuItem) {
            menuItems[sender.tag].action()
        }
    }
}

// MARK: - Toolbar Components

struct ToolbarButton: NSViewRepresentable {
    let icon: String
    let help: String
    let action: () -> Void

    func makeNSView(context: Context) -> IconButtonView {
        let view = IconButtonView(frame: NSRect(x: 0, y: 0, width: 28, height: 22))
        view.iconName = icon
        view.toolTip = help
        view.action = action
        return view
    }

    func updateNSView(_ view: IconButtonView, context: Context) {
        view.iconName = icon
        view.action = action
        view.needsDisplay = true
    }

    class IconButtonView: NSView {
        var iconName: String = ""
        var action: (() -> Void)?
        var isHovered = false

        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            setupTracking()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setupTracking()
        }

        private func setupTracking() {
            let trackingArea = NSTrackingArea(
                rect: bounds,
                options: [.mouseEnteredAndExited, .activeInActiveApp, .inVisibleRect],
                owner: self,
                userInfo: nil
            )
            addTrackingArea(trackingArea)
        }

        override func draw(_ dirtyRect: NSRect) {
            guard let image = NSImage(systemSymbolName: iconName, accessibilityDescription: nil) else { return }

            let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
            let configuredImage = image.withSymbolConfiguration(config) ?? image

            let tintColor = isHovered ? NSColor.labelColor : NSColor.secondaryLabelColor
            let tintedImage = configuredImage.tinted(with: tintColor)

            let imageSize = tintedImage.size
            let x = (bounds.width - imageSize.width) / 2
            let y = (bounds.height - imageSize.height) / 2
            tintedImage.draw(in: NSRect(x: x, y: y, width: imageSize.width, height: imageSize.height))
        }

        override func mouseEntered(with event: NSEvent) {
            isHovered = true
            needsDisplay = true
        }

        override func mouseExited(with event: NSEvent) {
            isHovered = false
            needsDisplay = true
        }

        override func mouseDown(with event: NSEvent) {
            action?()
        }
    }
}

struct ToolbarMenuButton: NSViewRepresentable {
    let icon: String
    let help: String
    let menuItems: [(String, () -> Void)]

    func makeNSView(context: Context) -> IconMenuView {
        let view = IconMenuView(frame: NSRect(x: 0, y: 0, width: 28, height: 22))
        view.iconName = icon
        view.toolTip = help
        view.menuItems = menuItems
        return view
    }

    func updateNSView(_ view: IconMenuView, context: Context) {
        view.iconName = icon
        view.menuItems = menuItems
        view.needsDisplay = true
    }

    class IconMenuView: NSView {
        var iconName: String = ""
        var menuItems: [(String, () -> Void)] = []
        var isHovered = false

        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            setupTracking()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setupTracking()
        }

        private func setupTracking() {
            let trackingArea = NSTrackingArea(
                rect: bounds,
                options: [.mouseEnteredAndExited, .activeInActiveApp, .inVisibleRect],
                owner: self,
                userInfo: nil
            )
            addTrackingArea(trackingArea)
        }

        override func draw(_ dirtyRect: NSRect) {
            guard let image = NSImage(systemSymbolName: iconName, accessibilityDescription: nil) else { return }

            let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
            let configuredImage = image.withSymbolConfiguration(config) ?? image

            let tintColor = isHovered ? NSColor.labelColor : NSColor.secondaryLabelColor
            let tintedImage = configuredImage.tinted(with: tintColor)

            let imageSize = tintedImage.size
            let x = (bounds.width - imageSize.width) / 2
            let y = (bounds.height - imageSize.height) / 2
            tintedImage.draw(in: NSRect(x: x, y: y, width: imageSize.width, height: imageSize.height))
        }

        override func mouseEntered(with event: NSEvent) {
            isHovered = true
            needsDisplay = true
        }

        override func mouseExited(with event: NSEvent) {
            isHovered = false
            needsDisplay = true
        }

        override func mouseDown(with event: NSEvent) {
            let menu = NSMenu()
            for (index, item) in menuItems.enumerated() {
                let menuItem = NSMenuItem(title: item.0, action: #selector(menuItemClicked(_:)), keyEquivalent: "")
                menuItem.target = self
                menuItem.tag = index
                menu.addItem(menuItem)
            }
            let point = NSPoint(x: 0, y: bounds.height + 4)
            menu.popUp(positioning: nil, at: point, in: self)
        }

        @objc func menuItemClicked(_ sender: NSMenuItem) {
            menuItems[sender.tag].1()
        }
    }
}

// MARK: - Menu Helpers

@MainActor
func createExportMenuItems(appState: AppState) -> [MenuItemConfig] {
    // Check plugin status
    let pluginEnabled = PluginManager.shared.isLoaded("com.tibok.wordpress-export")

    // Check configuration status
    let emailAddress = UserDefaults.standard.string(forKey: "plugin.wordpress.emailAddress") ?? ""
    let hasEmailConfig = !emailAddress.isEmpty

    let siteURL = UserDefaults.standard.string(forKey: "plugin.wordpress.siteURL") ?? ""
    let username = UserDefaults.standard.string(forKey: "plugin.wordpress.username") ?? ""
    // Just check if URL and username exist - don't access keychain here to avoid prompts
    // The password will be validated when actually publishing
    let hasAPIConfig = !siteURL.isEmpty && !username.isEmpty

    return [
        MenuItemConfig(
            title: "Export as PDF",
            action: { appState.exportAsPDF() }
        ),
        MenuItemConfig(
            title: "Export as HTML",
            action: { appState.exportAsHTML() }
        ),
        MenuItemConfig(
            title: "Export as RTF",
            action: { appState.exportAsRTF() }
        ),
        MenuItemConfig(
            title: "Export as Plain Text",
            action: { appState.exportAsPlainText() }
        ),
        MenuItemConfig(
            title: "Email to WordPress",
            action: { appState.exportToWordPress() },
            isEnabled: pluginEnabled && hasEmailConfig,
            disabledReason: !pluginEnabled
                ? "Enable WordPress plugin in Settings > Plugins"
                : !hasEmailConfig
                    ? "Posting to WordPress by email is not configured. Go to Settings > WordPress"
                    : nil
        ),
        MenuItemConfig(
            title: "Publish to WordPress (API)",
            action: {
                guard let document = appState.activeDocument else { return }
                Task {
                    await WordPressExporter.shared.publish(
                        document: document,
                        appState: appState
                    )
                }
            },
            isEnabled: pluginEnabled && hasAPIConfig,
            disabledReason: !pluginEnabled
                ? "Enable WordPress plugin in Settings > Plugins"
                : !hasAPIConfig
                    ? "Configure site URL and credentials in Settings > WordPress"
                    : nil
        )
    ]
}

extension NSImage {
    func tinted(with color: NSColor) -> NSImage {
        let image = self.copy() as! NSImage
        image.lockFocus()
        color.set()
        let imageRect = NSRect(origin: .zero, size: image.size)
        imageRect.fill(using: .sourceAtop)
        image.unlockFocus()
        return image
    }
}

