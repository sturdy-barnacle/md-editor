//
//  AppState.swift
//  tibok
//
//  Central application state using @Observable pattern.
//

import SwiftUI
import UniformTypeIdentifiers
import WebKit

// MARK: - Command

struct Command: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String?
    let icon: String?
    let shortcut: KeyboardShortcut?
    let category: CommandCategory
    let source: String
    let action: () -> Void

    init(
        id: String,
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        shortcut: KeyboardShortcut? = nil,
        category: CommandCategory = .general,
        source: String = "builtin",
        action: @escaping () -> Void
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.shortcut = shortcut
        self.category = category
        self.source = source
        self.action = action
    }

    static func == (lhs: Command, rhs: Command) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Command Category

enum CommandCategory: String, CaseIterable {
    case file = "File"
    case edit = "Edit"
    case view = "View"
    case insert = "Insert"
    case export = "Export"
    case git = "Git"
    case general = "General"

    var icon: String {
        switch self {
        case .file: return "doc"
        case .edit: return "pencil"
        case .view: return "eye"
        case .insert: return "plus.square"
        case .export: return "square.and.arrow.up"
        case .git: return "arrow.triangle.branch"
        case .general: return "command"
        }
    }
}

// MARK: - Command Registry

@MainActor
class CommandRegistry: ObservableObject {
    static let shared = CommandRegistry()

    @Published private(set) var commands: [Command] = []
    @Published var recentCommandIds: [String] = []

    private let maxRecent = 5

    private init() {
        loadRecentCommands()
    }

    func register(_ command: Command) {
        if !commands.contains(where: { $0.id == command.id }) {
            commands.append(command)
        }
    }

    func register(_ commands: [Command]) {
        for command in commands {
            register(command)
        }
    }

    /// Unregister all commands from a specific source (plugin)
    func unregister(source: String) {
        commands.removeAll { $0.source == source }
    }

    func execute(_ command: Command) {
        command.action()
        addToRecent(command.id)
    }

    func search(_ query: String) -> [Command] {
        if query.isEmpty {
            let recentCommands = recentCommandIds.compactMap { id in
                commands.first { $0.id == id }
            }
            let otherCommands = commands.filter { !recentCommandIds.contains($0.id) }
            return recentCommands + otherCommands
        }

        let lowercaseQuery = query.lowercased()

        return commands
            .map { command -> (Command, Int) in
                let score = fuzzyScore(query: lowercaseQuery, target: command.title.lowercased())
                return (command, score)
            }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
    }

    private func fuzzyScore(query: String, target: String) -> Int {
        var score = 0
        var queryIndex = query.startIndex
        var targetIndex = target.startIndex
        var consecutiveBonus = 0

        while queryIndex < query.endIndex && targetIndex < target.endIndex {
            if query[queryIndex] == target[targetIndex] {
                score += 1 + consecutiveBonus
                consecutiveBonus += 1
                queryIndex = query.index(after: queryIndex)

                if targetIndex == target.startIndex ||
                   target[target.index(before: targetIndex)] == " " {
                    score += 5
                }
            } else {
                consecutiveBonus = 0
            }
            targetIndex = target.index(after: targetIndex)
        }

        return queryIndex == query.endIndex ? score : 0
    }

    private func addToRecent(_ commandId: String) {
        recentCommandIds.removeAll { $0 == commandId }
        recentCommandIds.insert(commandId, at: 0)
        if recentCommandIds.count > maxRecent {
            recentCommandIds = Array(recentCommandIds.prefix(maxRecent))
        }
        saveRecentCommands()
    }

    private func loadRecentCommands() {
        if let ids = UserDefaults.standard.stringArray(forKey: "recentCommands") {
            recentCommandIds = ids
        }
    }

    private func saveRecentCommands() {
        UserDefaults.standard.set(recentCommandIds, forKey: "recentCommands")
    }
}

// MARK: - Keyboard Shortcut Display

extension KeyboardShortcut {
    var displayString: String {
        var parts: [String] = []

        if modifiers.contains(.command) { parts.append("⌘") }
        if modifiers.contains(.shift) { parts.append("⇧") }
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.control) { parts.append("⌃") }

        parts.append(String(key.character).uppercased())

        return parts.joined()
    }
}

// MARK: - FileItem

struct FileItem: Identifiable, Hashable {
    let id: URL
    let url: URL
    let name: String
    let isDirectory: Bool
    var children: [FileItem]?

    init(url: URL) {
        self.id = url
        self.url = url
        self.name = url.lastPathComponent

        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        self.isDirectory = isDir.boolValue
        self.children = nil
    }

    /// Load children for a directory
    mutating func loadChildren() {
        guard isDirectory else { return }

        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )

            children = contents
                .filter { $0.pathExtension == "md" || isDirectory(at: $0) }
                .sorted { lhs, rhs in
                    // Folders first, then alphabetically
                    let lhsIsDir = isDirectory(at: lhs)
                    let rhsIsDir = isDirectory(at: rhs)
                    if lhsIsDir != rhsIsDir {
                        return lhsIsDir
                    }
                    return lhs.lastPathComponent.localizedCaseInsensitiveCompare(rhs.lastPathComponent) == .orderedAscending
                }
                .map { FileItem(url: $0) }
        } catch {
            children = []
        }
    }

    private func isDirectory(at url: URL) -> Bool {
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        return isDir.boolValue
    }
}

// MARK: - AppState

@MainActor
class AppState: ObservableObject {
    // Multi-document state (tabs)
    @Published var documents: [Document] = []
    @Published var activeDocumentID: UUID?
    @Published var closedTabs: [Document] = []  // For "reopen last closed tab"

    @Published var recentFiles: [URL] = []
    @Published var favoriteFiles: [URL] = []
    @Published var workspaceURL: URL?
    @Published var workspaceFiles: [FileItem] = []

    // Git state
    @Published var isGitRepository: Bool = false
    @Published var currentBranch: String?
    @Published var gitFileStatuses: [URL: GitFileStatus] = [:]
    @Published var stagedFiles: [GitChangedFile] = []
    @Published var unstagedFiles: [GitChangedFile] = []

    // Toast notification state
    @Published var toastMessage: String?
    @Published var toastIcon: String?
    private var toastDismissTask: Task<Void, Never>?

    private var autoSaveTimer: Timer?
    private var gitRefreshTask: Task<Void, Never>?
    private let autoSaveDelay: TimeInterval = 0.5  // 500ms debounce
    private var exportWebView: WKWebView?  // Retain WebView during export
    private var exportDelegate: WebViewExportDelegate?  // Retain delegate
    private var pendingPDFURL: URL?

    private let maxClosedTabs = 10

    init() {
        loadRecentFiles()
        loadFavorites()
        loadOpenTabs()
    }

    // MARK: - Active Document Access

    /// The currently active document (displayed in editor)
    var activeDocument: Document? {
        guard let id = activeDocumentID else { return nil }
        return documents.first { $0.id == id }
    }

    /// Index of the active document in the documents array
    var activeDocumentIndex: Int? {
        guard let id = activeDocumentID else { return nil }
        return documents.firstIndex { $0.id == id }
    }

    /// Convenience for backward compatibility - returns active document or empty
    var currentDocument: Document {
        get { activeDocument ?? Document.empty() }
        set {
            if let index = activeDocumentIndex {
                documents[index] = newValue
            }
        }
    }

    /// Whether there are no documents open (show empty state)
    var hasNoDocuments: Bool {
        documents.isEmpty
    }

    // MARK: - Tab Operations

    func switchToTab(id: UUID) {
        guard documents.contains(where: { $0.id == id }) else { return }
        activeDocumentID = id
    }

    func switchToTab(at index: Int) {
        guard index >= 0, index < documents.count else { return }
        activeDocumentID = documents[index].id
    }

    func nextTab() {
        guard let currentIndex = activeDocumentIndex, documents.count > 1 else { return }
        let nextIndex = (currentIndex + 1) % documents.count
        activeDocumentID = documents[nextIndex].id
    }

    func previousTab() {
        guard let currentIndex = activeDocumentIndex, documents.count > 1 else { return }
        let previousIndex = (currentIndex - 1 + documents.count) % documents.count
        activeDocumentID = documents[previousIndex].id
    }

    func closeTab(id: UUID) {
        guard let index = documents.firstIndex(where: { $0.id == id }) else { return }
        let doc = documents[index]

        // Check for unsaved changes
        if doc.isModified {
            let shouldClose = showSavePrompt(for: doc)
            if !shouldClose { return }
        }

        // Add to closed tabs for reopening
        closedTabs.insert(doc, at: 0)
        if closedTabs.count > maxClosedTabs {
            closedTabs = Array(closedTabs.prefix(maxClosedTabs))
        }

        // Remove the document
        documents.remove(at: index)

        // Update active document
        if activeDocumentID == id {
            if documents.isEmpty {
                activeDocumentID = nil
            } else {
                // Switch to previous tab, or first if we closed the first
                let newIndex = min(index, documents.count - 1)
                activeDocumentID = documents[newIndex].id
            }
        }

        saveOpenTabs()
    }

    func closeCurrentTab() {
        guard let id = activeDocumentID else { return }
        closeTab(id: id)
    }

    func closeOtherTabs(except id: UUID) {
        let documentsToClose = documents.filter { $0.id != id }
        for doc in documentsToClose {
            if doc.isModified {
                let shouldClose = showSavePrompt(for: doc)
                if !shouldClose { continue }
            }
            closedTabs.insert(doc, at: 0)
        }
        documents = documents.filter { $0.id == id }
        if closedTabs.count > maxClosedTabs {
            closedTabs = Array(closedTabs.prefix(maxClosedTabs))
        }
        saveOpenTabs()
    }

    func closeAllTabs() {
        for doc in documents {
            if doc.isModified {
                let shouldClose = showSavePrompt(for: doc)
                if !shouldClose { continue }
            }
            closedTabs.insert(doc, at: 0)
        }
        documents = []
        activeDocumentID = nil
        if closedTabs.count > maxClosedTabs {
            closedTabs = Array(closedTabs.prefix(maxClosedTabs))
        }
        saveOpenTabs()
    }

    func reopenLastClosedTab() {
        guard let doc = closedTabs.first else { return }
        closedTabs.removeFirst()

        // If it had a file URL, try to reload from disk
        if let url = doc.fileURL, FileManager.default.fileExists(atPath: url.path) {
            loadDocument(from: url)
        } else {
            // Restore the in-memory document
            documents.append(doc)
            activeDocumentID = doc.id
            saveOpenTabs()
        }
    }

    func moveTab(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex,
              sourceIndex >= 0, sourceIndex < documents.count,
              destinationIndex >= 0, destinationIndex < documents.count else { return }

        let doc = documents.remove(at: sourceIndex)
        documents.insert(doc, at: destinationIndex)
        saveOpenTabs()
    }

    private func showSavePrompt(for doc: Document) -> Bool {
        let alert = NSAlert()
        alert.messageText = "Do you want to save changes to \"\(doc.fileURL?.lastPathComponent ?? "Untitled")\"?"
        alert.informativeText = "Your changes will be lost if you don't save them."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Don't Save")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        switch response {
        case .alertFirstButtonReturn:  // Save
            if let url = doc.fileURL {
                saveDocument(doc, to: url)
            } else {
                // Need to Save As
                let panel = NSSavePanel()
                panel.allowedContentTypes = [UTType(filenameExtension: "md")!]
                panel.nameFieldStringValue = "\(doc.title).md"
                if panel.runModal() == .OK, let url = panel.url {
                    saveDocument(doc, to: url)
                } else {
                    return false  // User cancelled Save As
                }
            }
            return true
        case .alertSecondButtonReturn:  // Don't Save
            return true
        default:  // Cancel
            return false
        }
    }

    // MARK: - Workspace Operations

    func openWorkspace() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            setWorkspace(url)
        }
    }

    func setWorkspace(_ url: URL) {
        workspaceURL = url
        refreshWorkspaceFiles()
    }

    func closeWorkspace() {
        workspaceURL = nil
        workspaceFiles = []
        clearGitState()
    }

    func refreshWorkspaceFiles() {
        guard let url = workspaceURL else {
            workspaceFiles = []
            clearGitState()
            return
        }

        var root = FileItem(url: url)
        root.loadChildren()
        workspaceFiles = root.children ?? []

        // Refresh git status after loading files
        refreshGitStatus()
    }

    // MARK: - Git Operations

    func refreshGitStatus() {
        guard let url = workspaceURL else {
            clearGitState()
            return
        }

        // Cancel any pending refresh
        gitRefreshTask?.cancel()

        gitRefreshTask = Task {
            // Small delay to debounce rapid refreshes
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

            guard !Task.isCancelled else { return }

            let gitService = GitService.shared

            // Check if workspace is a git repo
            let isRepo = gitService.isGitRepository(at: url)

            await MainActor.run {
                self.isGitRepository = isRepo
            }

            guard isRepo else {
                await MainActor.run {
                    self.clearGitState()
                }
                return
            }

            // Get branch and file statuses
            let branch = gitService.getCurrentBranch(for: url)
            let changedFiles = gitService.getChangedFiles(for: url)
            let statuses = gitService.getFileStatuses(for: url)

            let staged = changedFiles.filter { $0.isStaged }
            let unstaged = changedFiles.filter { !$0.isStaged }

            await MainActor.run {
                self.currentBranch = branch
                self.gitFileStatuses = statuses
                self.stagedFiles = staged
                self.unstagedFiles = unstaged
            }
        }
    }

    private func clearGitState() {
        isGitRepository = false
        currentBranch = nil
        gitFileStatuses = [:]
        stagedFiles = []
        unstagedFiles = []
    }

    func stageFile(_ url: URL) {
        guard let workspaceURL else { return }
        _ = GitService.shared.stageFiles([url], in: workspaceURL)
        refreshGitStatus()
    }

    func stageAllFiles() {
        guard let workspaceURL else { return }
        _ = GitService.shared.stageAll(in: workspaceURL)
        refreshGitStatus()
    }

    /// Alias for stageAllFiles
    func stageAll() {
        stageAllFiles()
    }

    func unstageFile(_ url: URL) {
        guard let workspaceURL else { return }
        _ = GitService.shared.unstageFiles([url], in: workspaceURL)
        refreshGitStatus()
    }

    func unstageAllFiles() {
        guard let workspaceURL else { return }
        _ = GitService.shared.unstageAll(in: workspaceURL)
        refreshGitStatus()
    }

    /// Alias for unstageAllFiles
    func unstageAll() {
        unstageAllFiles()
    }

    func discardChanges(_ url: URL) {
        guard let workspaceURL else { return }
        _ = GitService.shared.discardChanges([url], in: workspaceURL)
        refreshGitStatus()
        refreshWorkspaceFiles()
    }

    func commitChanges(message: String) -> (success: Bool, error: String?) {
        guard let workspaceURL else { return (false, "No workspace open") }
        let result = GitService.shared.commit(message: message, in: workspaceURL)
        if result.success {
            refreshGitStatus()
        }
        return result
    }

    func pushChanges() -> (success: Bool, error: String?) {
        guard let workspaceURL else { return (false, "No workspace open") }
        let result = GitService.shared.push(in: workspaceURL)
        if result.success {
            refreshGitStatus()

            // Trigger git.push webhooks
            Task {
                await WebhookService.shared.triggerGitPush(repositoryPath: workspaceURL.path)
            }
        }
        return result
    }

    func pullChanges() -> (success: Bool, error: String?) {
        guard let workspaceURL else { return (false, "No workspace open") }
        let result = GitService.shared.pull(in: workspaceURL)
        if result.success {
            refreshGitStatus()
            refreshWorkspaceFiles()
        }
        return result
    }

    func createFileInWorkspace(name: String) {
        guard let workspaceURL = workspaceURL else { return }

        let filename = name.hasSuffix(".md") ? name : "\(name).md"
        let fileURL = workspaceURL.appendingPathComponent(filename)

        do {
            try "".write(to: fileURL, atomically: true, encoding: .utf8)
            refreshWorkspaceFiles()
            loadDocument(from: fileURL)
        } catch {
            showToast("Failed to create file", icon: "exclamationmark.triangle.fill")
        }
    }

    func deleteFile(at url: URL) {
        do {
            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
            refreshWorkspaceFiles()
        } catch {
            showToast("Failed to delete file", icon: "exclamationmark.triangle.fill")
        }
    }

    func renameFile(at url: URL, to newName: String) {
        let newURL = url.deletingLastPathComponent().appendingPathComponent(newName)

        do {
            try FileManager.default.moveItem(at: url, to: newURL)
            refreshWorkspaceFiles()

            // Update any open document with this file
            if let index = documents.firstIndex(where: { $0.fileURL == url }) {
                documents[index].fileURL = newURL
                documents[index].title = newURL.deletingPathExtension().lastPathComponent
            }

            // Update recent files list
            if let recentIndex = recentFiles.firstIndex(of: url) {
                recentFiles[recentIndex] = newURL
                saveRecentFiles()
            }

            // Update favorites list
            if let favoriteIndex = favoriteFiles.firstIndex(of: url) {
                favoriteFiles[favoriteIndex] = newURL
                saveFavorites()
            }
        } catch {
            showToast("Failed to rename file", icon: "exclamationmark.triangle.fill")
        }
    }

    // MARK: - Document Operations

    func createNewDocument() {
        let doc = Document.new()
        documents.append(doc)
        activeDocumentID = doc.id
        saveOpenTabs()
    }

    func closeDocument() {
        closeCurrentTab()
    }

    func openDocument() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.plainText, UTType(filenameExtension: "md")!]
        panel.allowsMultipleSelection = true  // Allow multiple selection
        panel.canChooseDirectories = false

        if panel.runModal() == .OK {
            for url in panel.urls {
                loadDocument(from: url)
            }
        }
    }

    func loadDocument(from url: URL) {
        // Check if already open - if so, just switch to that tab
        if let existingDoc = documents.first(where: { $0.fileURL == url }) {
            activeDocumentID = existingDoc.id
            return
        }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let doc = Document(
                title: url.deletingPathExtension().lastPathComponent,
                content: content,
                fileURL: url,
                isModified: false,
                lastSaved: Date(),
                isActive: true
            )
            documents.append(doc)
            activeDocumentID = doc.id
            addToRecentFiles(url)
            saveOpenTabs()
        } catch {
            showToast("Failed to open file", icon: "exclamationmark.triangle.fill")
        }
    }

    func saveCurrentDocument() {
        guard let doc = activeDocument else { return }
        guard let url = doc.fileURL else {
            saveDocumentAs()
            return
        }
        saveDocument(doc, to: url)
    }

    func saveDocumentAs() {
        guard let doc = activeDocument else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "md")!]
        panel.nameFieldStringValue = "\(doc.title).md"

        if panel.runModal() == .OK, let url = panel.url {
            saveDocument(doc, to: url)
        }
    }

    private func saveDocument(_ doc: Document, to url: URL) {
        guard let index = documents.firstIndex(where: { $0.id == doc.id }) else { return }

        do {
            try doc.content.write(to: url, atomically: true, encoding: .utf8)
            documents[index].fileURL = url
            documents[index].isModified = false
            documents[index].lastSaved = Date()
            documents[index].title = url.deletingPathExtension().lastPathComponent
            addToRecentFiles(url)
            saveOpenTabs()

            // Trigger document.save webhooks
            let (frontmatter, _) = Frontmatter.parse(from: doc.content)
            Task {
                await WebhookService.shared.triggerDocumentSave(
                    filename: url.lastPathComponent,
                    title: frontmatter?.title,
                    path: url.path
                )
            }
        } catch {
            showToast("Failed to save document", icon: "exclamationmark.triangle.fill")
        }
    }

    // MARK: - Auto-save

    func documentDidChange() {
        guard let index = activeDocumentIndex else { return }
        documents[index].isModified = true
        scheduleAutoSave()
    }

    /// Update the content of the active document
    func updateActiveDocumentContent(_ content: String) {
        guard let index = activeDocumentIndex else { return }
        documents[index].content = content
        documents[index].isModified = true
        scheduleAutoSave()
    }

    private func scheduleAutoSave() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: autoSaveDelay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.autoSave()
            }
        }
    }

    private func autoSave() {
        guard let doc = activeDocument, doc.fileURL != nil else { return }
        saveCurrentDocument()
    }

    // MARK: - Export

    func exportAsPDF() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.pdf]
        panel.nameFieldStringValue = "\(currentDocument.title).pdf"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        // Check for relative images and warn
        let hasRelativeImages = currentDocument.content.contains("](./assets/") ||
                               currentDocument.content.contains("](assets/")
        if hasRelativeImages {
            showToast("Note: Relative image paths may not work in PDF",
                     icon: "photo.badge.exclamationmark", duration: 3.0)
        }

        showToast("Generating PDF...", icon: "doc.text", duration: 1.0)

        // Render markdown to HTML with print styles
        let html = wrapHTMLForPrint(MarkdownRenderer.render(currentDocument.content))

        // Create and retain WebView and delegate
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 612, height: 792))
        let delegate = WebViewExportDelegate { [weak self] in
            self?.finishPDFExport()
        }
        self.exportWebView = webView
        self.exportDelegate = delegate
        self.pendingPDFURL = url

        webView.navigationDelegate = delegate
        webView.loadHTMLString(html, baseURL: nil)
    }

    private func finishPDFExport() {
        guard let webView = exportWebView, let url = pendingPDFURL else { return }

        // Use print operation for proper multi-page PDF
        let printInfo = NSPrintInfo()
        printInfo.paperSize = NSSize(width: 612, height: 792) // Letter
        printInfo.topMargin = 54    // 0.75 inch
        printInfo.bottomMargin = 54
        printInfo.leftMargin = 54
        printInfo.rightMargin = 54
        printInfo.horizontalPagination = .fit
        printInfo.verticalPagination = .automatic
        printInfo.isHorizontallyCentered = false
        printInfo.isVerticallyCentered = false
        printInfo.jobDisposition = .save
        printInfo.dictionary()[NSPrintInfo.AttributeKey.jobSavingURL] = url

        let printOp = webView.printOperation(with: printInfo)
        printOp.showsPrintPanel = false
        printOp.showsProgressPanel = false

        printOp.runModal(for: NSApp.mainWindow ?? NSWindow(), delegate: nil, didRun: nil, contextInfo: nil)

        showToast("PDF exported successfully", icon: "checkmark.circle.fill", duration: 2.0)

        // Trigger document.export webhooks
        let (frontmatter, _) = Frontmatter.parse(from: currentDocument.content)
        Task {
            await WebhookService.shared.triggerDocumentExport(
                filename: url.lastPathComponent,
                title: frontmatter?.title,
                path: url.path,
                exportFormat: "pdf"
            )
        }

        // Clean up after print
        exportWebView = nil
        exportDelegate = nil
        pendingPDFURL = nil
    }

    private func wrapHTMLForPrint(_ content: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <title>\(currentDocument.title)</title>
            <style>
                @page {
                    size: letter;
                    margin: 0.75in 1in;
                }
                body {
                    font-family: 'Georgia', 'Times New Roman', serif;
                    font-size: 11pt;
                    line-height: 1.6;
                    color: #1a1a1a;
                    margin: 0;
                    padding: 0;
                }
                /* Headings */
                h1 {
                    font-family: -apple-system, BlinkMacSystemFont, 'Helvetica Neue', sans-serif;
                    font-size: 22pt;
                    font-weight: 600;
                    margin: 0 0 14pt 0;
                    padding-bottom: 6pt;
                    border-bottom: 1pt solid #e0e0e0;
                    page-break-after: avoid;
                }
                h2 {
                    font-family: -apple-system, BlinkMacSystemFont, 'Helvetica Neue', sans-serif;
                    font-size: 16pt;
                    font-weight: 600;
                    margin: 18pt 0 10pt 0;
                    page-break-after: avoid;
                }
                h3 {
                    font-family: -apple-system, BlinkMacSystemFont, 'Helvetica Neue', sans-serif;
                    font-size: 13pt;
                    font-weight: 600;
                    margin: 14pt 0 8pt 0;
                    page-break-after: avoid;
                }
                h4, h5, h6 {
                    font-family: -apple-system, BlinkMacSystemFont, 'Helvetica Neue', sans-serif;
                    font-size: 11pt;
                    font-weight: 600;
                    margin: 12pt 0 6pt 0;
                    page-break-after: avoid;
                }
                h5, h6 { color: #4a4a4a; }

                /* Paragraphs */
                p {
                    margin: 0 0 10pt 0;
                    orphans: 3;
                    widows: 3;
                    text-align: justify;
                    hyphens: auto;
                }

                /* Code */
                code {
                    font-family: 'SF Mono', 'Menlo', 'Consolas', monospace;
                    background: #f4f4f4;
                    padding: 1pt 4pt;
                    border-radius: 2pt;
                    font-size: 9pt;
                    color: #333;
                }
                pre {
                    background: #f8f8f8;
                    padding: 10pt;
                    border-radius: 4pt;
                    border: 0.5pt solid #e0e0e0;
                    overflow-x: auto;
                    page-break-inside: avoid;
                    margin: 0 0 10pt 0;
                }
                pre code {
                    background: none;
                    padding: 0;
                    font-size: 8.5pt;
                    line-height: 1.4;
                    border: none;
                }

                /* Blockquotes */
                blockquote {
                    border-left: 3pt solid #d0d0d0;
                    margin: 0 0 10pt 0;
                    padding: 6pt 0 6pt 12pt;
                    color: #555;
                    font-style: italic;
                    page-break-inside: avoid;
                }
                blockquote p { margin-bottom: 6pt; }
                blockquote p:last-child { margin-bottom: 0; }

                /* Links */
                a {
                    color: #0055aa;
                    text-decoration: none;
                }

                /* Lists */
                ul, ol {
                    margin: 0 0 10pt 0;
                    padding-left: 20pt;
                }
                li {
                    margin-bottom: 4pt;
                }
                li > ul, li > ol {
                    margin-top: 4pt;
                    margin-bottom: 0;
                }

                /* Task lists */
                input[type="checkbox"] {
                    margin-right: 6pt;
                }

                /* Horizontal rule */
                hr {
                    border: none;
                    border-top: 0.5pt solid #ccc;
                    margin: 16pt 0;
                }

                /* Tables */
                table {
                    border-collapse: collapse;
                    margin: 0 0 10pt 0;
                    page-break-inside: avoid;
                    width: 100%;
                    font-size: 10pt;
                }
                th, td {
                    border: 0.5pt solid #ccc;
                    padding: 6pt 10pt;
                    text-align: left;
                }
                th {
                    background: #f4f4f4;
                    font-weight: 600;
                }

                /* Images */
                img {
                    max-width: 100%;
                    height: auto;
                    page-break-inside: avoid;
                }

                /* Callouts */
                .callout {
                    padding: 10pt 12pt;
                    border-radius: 4pt;
                    margin: 0 0 10pt 0;
                    border-left: 4pt solid;
                    page-break-inside: avoid;
                }
                .callout strong { display: block; margin-bottom: 4pt; }
                .callout p { margin: 4pt 0; }
                .callout p:last-child { margin-bottom: 0; }
                .callout-note { background: #e8f4fd; border-color: #0969da; }
                .callout-tip { background: #e6f6e6; border-color: #1a7f37; }
                .callout-warning { background: #fff8e6; border-color: #d29922; }
                .callout-important { background: #f6e8ff; border-color: #8250df; }
                .callout-caution { background: #ffe8e8; border-color: #cf222e; }

                /* Footnotes */
                .footnotes {
                    margin-top: 24pt;
                    padding-top: 12pt;
                    border-top: 0.5pt solid #ccc;
                    font-size: 9pt;
                    color: #555;
                }
                .footnotes ol { padding-left: 16pt; }
                .footnotes li { margin-bottom: 6pt; }
                sup a {
                    color: #0055aa;
                    font-weight: 500;
                }

                /* Table of Contents */
                .toc {
                    background: #f8f8f8;
                    border: 0.5pt solid #e0e0e0;
                    border-radius: 4pt;
                    padding: 12pt 16pt;
                    margin: 0 0 16pt 0;
                    page-break-inside: avoid;
                }
                .toc ul { list-style: none; padding-left: 0; margin: 0; }
                .toc ul ul { padding-left: 14pt; margin-top: 4pt; }
                .toc li { margin-bottom: 4pt; }
                .toc a { color: #333; }

                /* Definition lists */
                dl { margin: 0 0 10pt 0; }
                dt { font-weight: 600; margin-top: 8pt; }
                dt:first-child { margin-top: 0; }
                dd { margin: 2pt 0 6pt 20pt; color: #444; }

                /* Collapsible sections (print expanded) */
                details { margin: 0 0 10pt 0; }
                summary { font-weight: 600; cursor: default; }

                /* Strikethrough and mark */
                del { color: #666; }
                mark { background: #fff3b0; padding: 1pt 2pt; }

                /* Print-specific */
                @media print {
                    a[href]:after { content: ""; }  /* Don't show URLs after links */
                }
            </style>
        </head>
        <body>
            \(content)
        </body>
        </html>
        """
    }

    func exportAsHTML() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.html]
        panel.nameFieldStringValue = "\(currentDocument.title).html"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let html = wrapHTMLForExport(MarkdownRenderer.render(currentDocument.content))

        do {
            try html.write(to: url, atomically: true, encoding: .utf8)

            // Context-aware success notification
            let hasRelativeImages = currentDocument.content.contains("](./assets/") ||
                                   currentDocument.content.contains("](assets/")
            if hasRelativeImages {
                showToast("Images use relative paths - keep assets folder",
                         icon: "photo", duration: 3.0)
            } else {
                showToast("HTML exported successfully",
                         icon: "checkmark.circle.fill", duration: 2.0)
            }

            // Trigger document.export webhooks
            let (frontmatter, _) = Frontmatter.parse(from: currentDocument.content)
            Task {
                await WebhookService.shared.triggerDocumentExport(
                    filename: url.lastPathComponent,
                    title: frontmatter?.title,
                    path: url.path,
                    exportFormat: "html"
                )
            }
        } catch {
            showToast("Failed to export HTML", icon: "exclamationmark.triangle.fill")
        }
    }

    private func wrapHTMLForExport(_ content: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <title>\(currentDocument.title)</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    font-size: 14px;
                    line-height: 1.6;
                    color: #333;
                    max-width: 700px;
                    margin: 40px auto;
                    padding: 0 20px;
                }
                h1 { font-size: 28px; font-weight: 700; margin: 0 0 16px 0; }
                h2 { font-size: 22px; font-weight: 600; margin: 32px 0 12px 0; }
                h3 { font-size: 18px; font-weight: 600; margin: 24px 0 8px 0; }
                p { margin: 0 0 16px 0; }
                code {
                    font-family: 'SF Mono', Menlo, monospace;
                    background: #f5f5f5;
                    padding: 2px 6px;
                    border-radius: 4px;
                    font-size: 13px;
                }
                pre {
                    background: #f5f5f5;
                    padding: 16px;
                    border-radius: 8px;
                    overflow-x: auto;
                }
                pre code { background: none; padding: 0; }
                blockquote {
                    border-left: 4px solid #ddd;
                    margin: 0 0 16px 0;
                    padding: 0 0 0 16px;
                    color: #666;
                }
                a { color: #0066cc; }
                ul, ol { margin: 0 0 16px 0; padding-left: 24px; }
                hr { border: none; border-top: 1px solid #ddd; margin: 24px 0; }
                table { border-collapse: collapse; margin: 0 0 16px 0; }
                th, td { border: 1px solid #ddd; padding: 8px 12px; }
                th { background: #f9f9f9; }
                img { max-width: 100%; }
            </style>
        </head>
        <body>
            \(content)
        </body>
        </html>
        """
    }

    func copyAsMarkdown() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(currentDocument.content, forType: .string)

        // Context-aware notification
        let hasRelativeImages = currentDocument.content.contains("](./assets/") ||
                               currentDocument.content.contains("](assets/")

        if hasRelativeImages {
            showToast("Copied (images not included)", icon: "doc.on.clipboard", duration: 2.5)
        } else {
            showToast("Copied to clipboard", icon: "doc.on.clipboard.fill", duration: 1.5)
        }
    }

    // MARK: - Toast Notifications

    func showToast(_ message: String, icon: String? = nil, duration: TimeInterval = 1.5) {
        toastDismissTask?.cancel()
        toastMessage = message
        toastIcon = icon

        toastDismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            if !Task.isCancelled {
                withAnimation(.easeOut(duration: 0.2)) {
                    self.toastMessage = nil
                    self.toastIcon = nil
                }
            }
        }
    }

    func exportAsRTF() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.rtf]
        panel.nameFieldStringValue = "\(currentDocument.title).rtf"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        // Convert HTML to attributed string, then to RTF
        let html = wrapHTMLForExport(MarkdownRenderer.render(currentDocument.content))

        guard let htmlData = html.data(using: .utf8),
              let attributedString = try? NSAttributedString(
                  data: htmlData,
                  options: [
                      .documentType: NSAttributedString.DocumentType.html,
                      .characterEncoding: String.Encoding.utf8.rawValue
                  ],
                  documentAttributes: nil
              ) else {
            showToast("Failed to export RTF", icon: "exclamationmark.triangle.fill")
            return
        }

        // Convert to RTF
        guard let rtfData = try? attributedString.data(
            from: NSRange(location: 0, length: attributedString.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        ) else {
            showToast("Failed to export RTF", icon: "exclamationmark.triangle.fill")
            return
        }

        do {
            try rtfData.write(to: url)

            // Trigger document.export webhooks
            let (frontmatter, _) = Frontmatter.parse(from: currentDocument.content)
            Task {
                await WebhookService.shared.triggerDocumentExport(
                    filename: url.lastPathComponent,
                    title: frontmatter?.title,
                    path: url.path,
                    exportFormat: "rtf"
                )
            }
        } catch {
            showToast("Failed to export RTF", icon: "exclamationmark.triangle.fill")
        }
    }

    func exportAsPlainText() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.plainText]
        panel.nameFieldStringValue = "\(currentDocument.title).txt"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try currentDocument.content.write(to: url, atomically: true, encoding: .utf8)

            // Trigger document.export webhooks
            let (frontmatter, _) = Frontmatter.parse(from: currentDocument.content)
            Task {
                await WebhookService.shared.triggerDocumentExport(
                    filename: url.lastPathComponent,
                    title: frontmatter?.title,
                    path: url.path,
                    exportFormat: "txt"
                )
            }
        } catch {
            showToast("Failed to export text", icon: "exclamationmark.triangle.fill")
        }
    }

    func exportToWordPress() {
        // Get WordPress email address from settings
        let wordpressEmail = UserDefaults.standard.string(forKey: SettingsKeys.wordpressEmailAddress) ?? ""

        guard !wordpressEmail.isEmpty else {
            showToast("Configure WordPress email in Settings", icon: "envelope.badge.fill")
            return
        }

        // Parse frontmatter for title, categories, and tags
        let (frontmatter, body) = Frontmatter.parse(from: currentDocument.content)
        let title = frontmatter?.title ?? currentDocument.title

        // Convert markdown to HTML (WordPress supports HTML in email)
        let htmlContent = MarkdownRenderer.render(body)

        // Build email body with WordPress formatting
        var emailBody = htmlContent

        // Add categories if present (WordPress syntax: [category CategoryName])
        if let categories = frontmatter?.categories, !categories.isEmpty {
            let categorySyntax = categories.map { "[category \($0)]" }.joined(separator: " ")
            emailBody = "\(categorySyntax)\n\n\(emailBody)"
        }

        // Add tags if present (WordPress syntax: tags: tag1, tag2, tag3)
        if let tags = frontmatter?.tags, !tags.isEmpty {
            let tagSyntax = "tags: \(tags.joined(separator: ", "))"
            emailBody = "\(tagSyntax)\n\n\(emailBody)"
        }

        // URL encode the subject and body
        guard let encodedSubject = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedBody = emailBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            showToast("Failed to encode email", icon: "exclamationmark.triangle.fill")
            return
        }

        // Create mailto URL
        let mailtoURL = "mailto:\(wordpressEmail)?subject=\(encodedSubject)&body=\(encodedBody)"

        // Open default email client
        if let url = URL(string: mailtoURL) {
            NSWorkspace.shared.open(url)
            showToast("Opening email client...", icon: "envelope.fill")

            // Trigger document.export webhooks
            Task {
                await WebhookService.shared.triggerDocumentExport(
                    filename: currentDocument.fileURL?.lastPathComponent ?? "\(title).md",
                    title: frontmatter?.title,
                    path: currentDocument.fileURL?.path ?? "",
                    exportFormat: "wordpress"
                )
            }
        } else {
            showToast("Failed to open email client", icon: "exclamationmark.triangle.fill")
        }
    }

    // MARK: - Print

    /// WebView and delegate for printing (retained during print operation)
    private var printWebView: WKWebView?
    private var printDelegate: WebViewPrintDelegate?

    func printDocument() {
        guard !currentDocument.isEmpty else { return }

        // Render markdown to HTML for printing
        let html = wrapHTMLForPrint(MarkdownRenderer.render(currentDocument.content))

        // Create WebView for rendering
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 612, height: 792))
        let delegate = WebViewPrintDelegate { [weak self] in
            self?.showPrintDialog()
        }
        self.printWebView = webView
        self.printDelegate = delegate

        webView.navigationDelegate = delegate
        webView.loadHTMLString(html, baseURL: Bundle.main.resourceURL)
    }

    private func showPrintDialog() {
        guard let webView = printWebView else { return }

        let printInfo = NSPrintInfo.shared
        printInfo.paperSize = NSSize(width: 612, height: 792)
        printInfo.topMargin = 54
        printInfo.bottomMargin = 54
        printInfo.leftMargin = 54
        printInfo.rightMargin = 54
        printInfo.horizontalPagination = .fit
        printInfo.verticalPagination = .automatic

        let printOp = webView.printOperation(with: printInfo)
        printOp.showsPrintPanel = true
        printOp.showsProgressPanel = true

        printOp.runModal(for: NSApp.mainWindow ?? NSWindow(), delegate: nil, didRun: nil, contextInfo: nil)

        // Clean up
        printWebView = nil
        printDelegate = nil
    }

    // MARK: - Recent Files

    private func loadRecentFiles() {
        if let data = UserDefaults.standard.data(forKey: "recentFiles"),
           let urls = try? JSONDecoder().decode([URL].self, from: data) {
            recentFiles = urls.filter { FileManager.default.fileExists(atPath: $0.path) }
        }
    }

    private func addToRecentFiles(_ url: URL) {
        recentFiles.removeAll { $0 == url }
        recentFiles.insert(url, at: 0)
        if recentFiles.count > 10 {
            recentFiles = Array(recentFiles.prefix(10))
        }
        saveRecentFiles()
    }

    func removeFromRecentFiles(_ url: URL) {
        recentFiles.removeAll { $0 == url }
        saveRecentFiles()
    }

    func clearRecentFiles() {
        recentFiles = []
        saveRecentFiles()
    }

    private func saveRecentFiles() {
        if let data = try? JSONEncoder().encode(recentFiles) {
            UserDefaults.standard.set(data, forKey: "recentFiles")
        }
    }

    // MARK: - Favorites

    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: "favoriteFiles"),
           let urls = try? JSONDecoder().decode([URL].self, from: data) {
            favoriteFiles = urls.filter { FileManager.default.fileExists(atPath: $0.path) }
        }
    }

    func addToFavorites(_ url: URL) {
        guard !favoriteFiles.contains(url) else { return }
        favoriteFiles.insert(url, at: 0)
        saveFavorites()
    }

    func removeFromFavorites(_ url: URL) {
        favoriteFiles.removeAll { $0 == url }
        saveFavorites()
    }

    func isFavorite(_ url: URL) -> Bool {
        favoriteFiles.contains(url)
    }

    private func saveFavorites() {
        if let data = try? JSONEncoder().encode(favoriteFiles) {
            UserDefaults.standard.set(data, forKey: "favoriteFiles")
        }
    }

    func revealInFinder(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func copyPathToClipboard(_ url: URL) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url.path, forType: .string)
        showToast("Path copied", icon: "doc.on.clipboard.fill")
    }

    // MARK: - Tab Persistence

    private func loadOpenTabs() {
        // Load saved tab URLs
        guard let data = UserDefaults.standard.data(forKey: "openTabs"),
              let tabInfo = try? JSONDecoder().decode(SavedTabInfo.self, from: data) else {
            return
        }

        // Reload documents from saved URLs
        for url in tabInfo.tabURLs {
            if FileManager.default.fileExists(atPath: url.path) {
                do {
                    let content = try String(contentsOf: url, encoding: .utf8)
                    let doc = Document(
                        title: url.deletingPathExtension().lastPathComponent,
                        content: content,
                        fileURL: url,
                        isModified: false,
                        lastSaved: Date(),
                        isActive: true
                    )
                    documents.append(doc)
                } catch {
                    // Skip files that can't be restored
                }
            }
        }

        // Set active tab - try to match by URL if possible
        if let activeURL = tabInfo.activeTabURL,
           let doc = documents.first(where: { $0.fileURL == activeURL }) {
            activeDocumentID = doc.id
        } else if let firstDoc = documents.first {
            activeDocumentID = firstDoc.id
        }
    }

    func saveOpenTabs() {
        // Only save tabs with file URLs (unsaved documents can't be restored)
        let tabURLs = documents.compactMap { $0.fileURL }
        let activeURL = activeDocument?.fileURL

        let tabInfo = SavedTabInfo(tabURLs: tabURLs, activeTabURL: activeURL)

        if let data = try? JSONEncoder().encode(tabInfo) {
            UserDefaults.standard.set(data, forKey: "openTabs")
        }
    }
}

// MARK: - Saved Tab Info

private struct SavedTabInfo: Codable {
    let tabURLs: [URL]
    let activeTabURL: URL?
}

// MARK: - WebView Export Delegate

class WebViewExportDelegate: NSObject, WKNavigationDelegate {
    private let onFinish: () -> Void

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Small delay to ensure rendering is complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.onFinish()
        }
    }
}

// MARK: - WebView Print Delegate

class WebViewPrintDelegate: NSObject, WKNavigationDelegate {
    private let onFinish: () -> Void

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Small delay to ensure rendering is complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.onFinish()
        }
    }
}
