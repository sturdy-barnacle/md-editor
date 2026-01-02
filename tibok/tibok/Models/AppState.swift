//
//  AppState.swift
//  tibok
//
//  Central application state using @Observable pattern.
//

import SwiftUI
import UniformTypeIdentifiers
import WebKit

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
    var isScanning: Bool = false  // For loading indicator
    var isFiltered: Bool = false  // True if folder was filtered out for not having markdown

    init(url: URL) {
        self.id = url
        self.url = url
        self.name = url.lastPathComponent

        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        self.isDirectory = isDir.boolValue
        self.children = nil
    }

    /// Load children for a directory (without smart filtering)
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
    @Published var expandedFolders: Set<String> = []  // Stores relative paths of expanded folders
    @AppStorage("workspace.smartFiltering") var smartFilteringEnabled = true

    // Workspace monitoring
    private let workspaceMonitor = WorkspaceMonitor()

    // Security-scoped URL for sandbox access (grants access to .git)
    private var workspaceAccessURL: URL?

    // Git state
    @Published var isGitRepository: Bool = false
    @Published var currentBranch: String?
    @Published var availableBranches: [String] = []
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

    private let maxClosedTabs = 10

    init() {
        loadRecentFiles()
        loadFavorites()
        loadOpenTabs()
        loadWorkspaceState()
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
        // Stop accessing previous workspace
        workspaceAccessURL?.stopAccessingSecurityScopedResource()

        // Start accessing new workspace (grants .git access in sandbox)
        let hasAccess = url.startAccessingSecurityScopedResource()
        workspaceAccessURL = hasAccess ? url : nil

        // Create bookmark for persistence across app launches
        if hasAccess {
            do {
                let bookmarkData = try url.bookmarkData(
                    options: .withSecurityScope,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
                UserDefaults.standard.set(bookmarkData, forKey: "workspaceBookmark")
                print("✅ [AppState] Created security-scoped bookmark for: \(url.path)")
            } catch {
                print("⚠️ [AppState] Failed to create bookmark: \(error.localizedDescription)")
            }
        }

        workspaceURL = url
        saveWorkspaceState()
        refreshWorkspaceFiles()

        // Start monitoring workspace for external changes
        workspaceMonitor.startMonitoring(url: url) { [weak self] in
            Task { @MainActor in
                self?.refreshWorkspaceFiles()
            }
        }
    }

    func closeWorkspace() {
        workspaceMonitor.stopMonitoring()
        // Cleanup security-scoped resource access
        workspaceAccessURL?.stopAccessingSecurityScopedResource()
        workspaceAccessURL = nil
        saveWorkspaceState()  // Save before closing
        workspaceURL = nil
        workspaceFiles = []
        clearGitState()
    }

    private func saveWorkspaceState() {
        if let url = workspaceURL {
            UserDefaults.standard.set(url, forKey: "lastWorkspaceURL")
        }
    }

    private func loadWorkspaceState() {
        // Load expanded folders BEFORE setWorkspace so refreshWorkspaceFiles can use them
        loadExpandedFolders()

        // Try security-scoped bookmark first (required for sandbox access to .git)
        if let bookmarkData = UserDefaults.standard.data(forKey: "workspaceBookmark") {
            do {
                var isStale = false
                let url = try URL(
                    resolvingBookmarkData: bookmarkData,
                    options: .withSecurityScope,
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )

                if !isStale {
                    print("✅ [AppState] Restored workspace from bookmark: \(url.path)")
                    setWorkspace(url)
                    return
                } else {
                    print("⚠️ [AppState] Bookmark is stale, removing")
                    UserDefaults.standard.removeObject(forKey: "workspaceBookmark")
                }
            } catch {
                print("⚠️ [AppState] Failed to restore bookmark: \(error.localizedDescription)")
                UserDefaults.standard.removeObject(forKey: "workspaceBookmark")
            }
        }

        // Fallback to URL only (won't have sandbox access but handles migration)
        if let url = UserDefaults.standard.url(forKey: "lastWorkspaceURL"),
           FileManager.default.fileExists(atPath: url.path) {
            setWorkspace(url)
        }
    }

    func toggleFolderExpansion(_ path: String) {
        if expandedFolders.contains(path) {
            expandedFolders.remove(path)
        } else {
            expandedFolders.insert(path)
        }
        saveExpandedFolders()
    }

    func isFolderExpanded(_ path: String) -> Bool {
        expandedFolders.contains(path)
    }

    func setFolderExpanded(_ path: String, expanded: Bool) {
        if expanded {
            expandedFolders.insert(path)
        } else {
            expandedFolders.remove(path)
        }
        saveExpandedFolders()
    }

    private func saveExpandedFolders() {
        if let data = try? JSONEncoder().encode(Array(expandedFolders)) {
            UserDefaults.standard.set(data, forKey: "expandedFolders")
        }
    }

    private func loadExpandedFolders() {
        if let data = UserDefaults.standard.data(forKey: "expandedFolders"),
           let folders = try? JSONDecoder().decode([String].self, from: data) {
            expandedFolders = Set(folders)
        }
    }

    func clearExpandedFolders() {
        expandedFolders = []
        UserDefaults.standard.removeObject(forKey: "expandedFolders")
    }

    func refreshWorkspaceFiles() {
        guard let url = workspaceURL else {
            workspaceFiles = []
            clearGitState()
            return
        }

        // Save currently expanded folder paths before refresh
        let previouslyExpanded = expandedFolders

        var root = FileItem(url: url)

        if smartFilteringEnabled {
            // Load children first
            root.loadChildren()

            // Start filtering in background
            Task {
                let filteredChildren = await filterChildren(root.children ?? [])
                await MainActor.run {
                    var updatedRoot = root
                    updatedRoot.children = filteredChildren
                    // Recursively load children for expanded folders
                    updatedRoot.children = self.loadExpandedFolderChildren(updatedRoot.children ?? [], expandedPaths: previouslyExpanded)
                    self.workspaceFiles = updatedRoot.children ?? []
                    // Restore expansion states after refresh
                    self.expandedFolders = previouslyExpanded
                }
            }
        } else {
            // Load all files immediately (no filtering)
            root.loadChildren()
            // Recursively load children for expanded folders
            root.children = loadExpandedFolderChildren(root.children ?? [], expandedPaths: previouslyExpanded)
            workspaceFiles = root.children ?? []
            // Restore expansion states after refresh
            self.expandedFolders = previouslyExpanded
        }

        // Refresh git status after loading files
        refreshGitStatus()
    }

    /// Recursively loads children for folders that are currently expanded
    private func loadExpandedFolderChildren(_ items: [FileItem], expandedPaths: Set<String>) -> [FileItem] {
        return items.map { item in
            var mutableItem = item
            if mutableItem.isDirectory && expandedPaths.contains(mutableItem.url.path) {
                // Load this folder's children
                mutableItem.loadChildren()
                // Recursively load nested expanded folders
                if let children = mutableItem.children {
                    mutableItem.children = loadExpandedFolderChildren(children, expandedPaths: expandedPaths)
                }
            }
            return mutableItem
        }
    }

    /// Filter children based on whether folders contain markdown files
    private func filterChildren(_ children: [FileItem]) async -> [FileItem] {
        var filteredChildren: [FileItem] = []

        for var child in children {
            if child.isDirectory {
                // Check cache or scan folder
                let containsMarkdown = await FolderScanCache.shared.scanFolder(at: child.url)
                if containsMarkdown {
                    filteredChildren.append(child)
                } else {
                    child.isFiltered = true
                }
            } else {
                // Always include markdown files
                filteredChildren.append(child)
            }
        }

        return filteredChildren
    }

    /// Expand a folder and load its children (with smart filtering if enabled)
    func expandFolder(at index: Int) {
        guard index < workspaceFiles.count else { return }

        var item = workspaceFiles[index]
        item.loadChildren()

        if smartFilteringEnabled {
            // Filter in background
            Task {
                let filteredChildren = await filterChildren(item.children ?? [])
                await MainActor.run {
                    self.workspaceFiles[index].children = filteredChildren
                    self.workspaceFiles[index].isScanning = false
                }
            }
        } else {
            workspaceFiles[index].children = item.children
        }
    }

    // MARK: - Git Operations

    func refreshGitStatus() {
        print("🔍 [AppState] Starting git status refresh...")

        guard let url = workspaceURL else {
            print("❌ [AppState] No workspace URL set")
            clearGitState()
            return
        }

        // Cancel any pending refresh
        gitRefreshTask?.cancel()

        gitRefreshTask = Task {
            // Small delay to debounce rapid refreshes
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

            guard !Task.isCancelled else {
                print("⚠️ [AppState] Git status refresh was cancelled")
                return
            }

            let gitService = LibGit2Service.shared

            // Check if workspace is a git repo and get the actual repo root
            guard let repoRoot = gitService.getRepositoryRoot(for: url) else {
                await MainActor.run {
                    print("❌ [AppState] Git repository not found in workspace")
                    self.isGitRepository = false
                    self.clearGitState()
                }
                return
            }

            print("✅ [AppState] Git repository detected, loading status...")
            await MainActor.run {
                self.isGitRepository = true
            }

            // Get branch and file statuses using the repo root
            let branch = gitService.getCurrentBranch(for: repoRoot)
            let branches = gitService.getBranches(for: repoRoot)
            let changedFiles = gitService.getChangedFiles(for: repoRoot)
            let statuses = gitService.getFileStatuses(for: repoRoot)

            let staged = changedFiles.filter { $0.isStaged }
            let unstaged = changedFiles.filter { !$0.isStaged }

            await MainActor.run {
                self.currentBranch = branch
                self.availableBranches = branches
                self.gitFileStatuses = statuses
                self.stagedFiles = staged
                self.unstagedFiles = unstaged
            }
        }
    }

    private func clearGitState() {
        isGitRepository = false
        currentBranch = nil
        availableBranches = []
        gitFileStatuses = [:]
        stagedFiles = []
        unstagedFiles = []
    }

    /// Get the git repository root for the current workspace
    private func getGitRepoRoot() -> URL? {
        guard let workspaceURL else { return nil }
        return LibGit2Service.shared.getRepositoryRoot(for: workspaceURL)
    }

    func stageFile(_ url: URL) {
        guard let repoRoot = getGitRepoRoot() else { return }
        _ = LibGit2Service.shared.stageFiles([url], in: repoRoot)
        refreshGitStatus()
    }

    func stageAllFiles() {
        guard let repoRoot = getGitRepoRoot() else { return }
        _ = LibGit2Service.shared.stageAll(in: repoRoot)
        refreshGitStatus()
    }

    /// Alias for stageAllFiles
    func stageAll() {
        stageAllFiles()
    }

    func unstageFile(_ url: URL) {
        guard let repoRoot = getGitRepoRoot() else { return }
        _ = LibGit2Service.shared.unstageFiles([url], in: repoRoot)
        refreshGitStatus()
    }

    func unstageAllFiles() {
        guard let repoRoot = getGitRepoRoot() else { return }
        _ = LibGit2Service.shared.unstageAll(in: repoRoot)
        refreshGitStatus()
    }

    /// Alias for unstageAllFiles
    func unstageAll() {
        unstageAllFiles()
    }

    func discardChanges(_ url: URL) {
        guard let repoRoot = getGitRepoRoot() else { return }
        _ = LibGit2Service.shared.discardChanges([url], in: repoRoot)
        refreshGitStatus()
        refreshWorkspaceFiles()
    }

    func commitChanges(message: String, deferRefresh: Bool = false) -> (success: Bool, error: String?) {
        guard let repoRoot = getGitRepoRoot() else { return (false, "No workspace open") }
        let result = LibGit2Service.shared.commit(message: message, in: repoRoot)
        if result.success && !deferRefresh {
            refreshGitStatus()
        }
        return result
    }

    func pushChanges() -> (success: Bool, error: String?, alreadyUpToDate: Bool) {
        guard let repoRoot = getGitRepoRoot() else { return (false, "No workspace open", false) }
        let result = LibGit2Service.shared.push(in: repoRoot)
        if result.success {
            refreshGitStatus()

            // Trigger git.push webhooks (use repo root for webhook path)
            Task {
                await WebhookService.shared.triggerGitPush(repositoryPath: repoRoot.path)
            }
        }
        return (result.success, result.error, result.alreadyUpToDate)
    }

    func pullChanges() -> (success: Bool, error: String?) {
        guard let repoRoot = getGitRepoRoot() else { return (false, "No workspace open") }
        let result = LibGit2Service.shared.pull(in: repoRoot)
        if result.success {
            refreshGitStatus()
            refreshWorkspaceFiles()
        }
        return result
    }

    // MARK: - Git Branch Operations

    /// Switch to a different git branch
    func switchBranch(to branchName: String) -> (success: Bool, error: String?) {
        print("🔀 [AppState] Attempting to switch to branch: \(branchName)")

        guard let repoRoot = getGitRepoRoot() else {
            print("❌ [AppState] No git repository found")
            return (false, "No workspace open")
        }

        // Check for uncommitted changes
        if !stagedFiles.isEmpty || !unstagedFiles.isEmpty {
            let count = stagedFiles.count + unstagedFiles.count
            print("⚠️ [AppState] Cannot switch: \(count) uncommitted change(s)")
            print("   Staged: \(stagedFiles.count), Unstaged: \(unstagedFiles.count)")
            return (false, "You have uncommitted changes. Please commit or stash them before switching branches.")
        }

        print("✅ [AppState] No uncommitted changes, proceeding with switch")
        let result = LibGit2Service.shared.switchBranch(to: branchName, in: repoRoot)

        if result.success {
            print("✅ [AppState] Branch switch successful, refreshing state")
            refreshGitStatus()
            refreshWorkspaceFiles()
            showToast("Switched to \(branchName)", icon: "arrow.triangle.branch")
        } else {
            print("❌ [AppState] Branch switch failed: \(result.error ?? "unknown")")
        }

        return result
    }

    /// Create a new git branch
    func createBranch(name: String, switchTo: Bool = true) -> (success: Bool, error: String?) {
        guard let repoRoot = getGitRepoRoot() else {
            return (false, "No workspace open")
        }

        // Check if branch already exists
        if availableBranches.contains(name) {
            return (false, "Branch '\(name)' already exists")
        }

        let result = LibGit2Service.shared.createBranch(name: name, switchTo: switchTo, in: repoRoot)
        if result.success {
            refreshGitStatus()
            if switchTo {
                showToast("Created and switched to \(name)", icon: "arrow.triangle.branch")
            } else {
                showToast("Created branch \(name)", icon: "arrow.triangle.branch")
            }
        }
        return result
    }

    func createFileInWorkspace(name: String) -> Bool {
        guard let workspaceURL = workspaceURL else { return false }

        let filename = name.hasSuffix(".md") ? name : "\(name).md"
        let fileURL = workspaceURL.appendingPathComponent(filename)

        // Check for file conflict
        if FileManager.default.fileExists(atPath: fileURL.path) {
            showToast("File '\(filename)' already exists", icon: "exclamationmark.triangle.fill")
            return false
        }

        do {
            try "".write(to: fileURL, atomically: true, encoding: .utf8)
            refreshWorkspaceFiles()
            loadDocument(from: fileURL)
            return true
        } catch {
            showToast("Failed to create file", icon: "exclamationmark.triangle.fill")
            return false
        }
    }

    func createFileInFolder(folderURL: URL, name: String) -> Bool {
        let filename = name.hasSuffix(".md") ? name : "\(name).md"
        let fileURL = folderURL.appendingPathComponent(filename)

        // Check for file conflict
        if FileManager.default.fileExists(atPath: fileURL.path) {
            showToast("File '\(filename)' already exists", icon: "exclamationmark.triangle.fill")
            return false
        }

        do {
            try "".write(to: fileURL, atomically: true, encoding: .utf8)

            // Expand the folder to show the new file
            if !isFolderExpanded(folderURL.path) {
                toggleFolderExpansion(folderURL.path)
            }

            // Refresh workspace to show new file (no delay needed, sheet is in stable parent now)
            refreshWorkspaceFiles()
            loadDocument(from: fileURL)
            return true
        } catch {
            showToast("Failed to create file", icon: "exclamationmark.triangle.fill")
            return false
        }
    }

    // MARK: - Folder Operations

    func createFolderInWorkspace(name: String) -> Bool {
        guard let workspaceURL = workspaceURL else { return false }
        let folderURL = workspaceURL.appendingPathComponent(name)

        if FileManager.default.fileExists(atPath: folderURL.path) {
            showToast("Folder '\(name)' already exists", icon: "exclamationmark.triangle.fill")
            return false
        }

        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: false)
            if !isFolderExpanded(workspaceURL.path) {
                toggleFolderExpansion(workspaceURL.path)
            }
            refreshWorkspaceFiles()
            showToast("Folder created", icon: "folder")
            return true
        } catch {
            showToast("Failed to create folder", icon: "exclamationmark.triangle.fill")
            return false
        }
    }

    func createFolderInFolder(parentURL: URL, name: String) -> Bool {
        let folderURL = parentURL.appendingPathComponent(name)

        if FileManager.default.fileExists(atPath: folderURL.path) {
            showToast("Folder '\(name)' already exists", icon: "exclamationmark.triangle.fill")
            return false
        }

        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: false)
            if !isFolderExpanded(parentURL.path) {
                toggleFolderExpansion(parentURL.path)
            }
            refreshWorkspaceFiles()
            showToast("Folder created", icon: "folder")
            return true
        } catch {
            showToast("Failed to create folder", icon: "exclamationmark.triangle.fill")
            return false
        }
    }

    func deleteFolder(at url: URL) {
        do {
            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
            refreshWorkspaceFiles()
            showToast("Folder moved to trash", icon: "trash")
        } catch {
            showToast("Failed to delete folder", icon: "exclamationmark.triangle.fill")
        }
    }

    func renameFolder(at url: URL, to newName: String) {
        let newURL = url.deletingLastPathComponent().appendingPathComponent(newName)

        if FileManager.default.fileExists(atPath: newURL.path) {
            showToast("A folder named '\(newName)' already exists", icon: "exclamationmark.triangle.fill")
            return
        }

        do {
            try FileManager.default.moveItem(at: url, to: newURL)
            refreshWorkspaceFiles()
            showToast("Folder renamed", icon: "folder")
        } catch {
            showToast("Failed to rename folder", icon: "exclamationmark.triangle.fill")
        }
    }

    // MARK: - File Operations

    func deleteFile(at url: URL) {
        do {
            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
            refreshWorkspaceFiles()
        } catch {
            showToast("Failed to delete file", icon: "exclamationmark.triangle.fill")
        }
    }

    /// Delete multiple files
    func deleteFiles(_ urls: [URL]) {
        var successCount = 0
        var failCount = 0

        for url in urls {
            do {
                try FileManager.default.trashItem(at: url, resultingItemURL: nil)
                successCount += 1
            } catch {
                failCount += 1
            }
        }

        refreshWorkspaceFiles()

        if failCount == 0 {
            showToast("Moved \(successCount) file\(successCount == 1 ? "" : "s") to trash", icon: "trash")
        } else {
            showToast("Deleted \(successCount), failed \(failCount)", icon: "exclamationmark.triangle.fill")
        }
    }

    /// Move a file from one location to another
    /// Uses git mv for tracked files to preserve history
    func moveFile(from sourceURL: URL, to destinationFolder: URL) -> Bool {
        // Validate source and destination
        guard sourceURL.deletingLastPathComponent() != destinationFolder else {
            showToast("File is already in this folder", icon: "exclamationmark.triangle.fill")
            return false
        }

        let fileName = sourceURL.lastPathComponent
        let destinationURL = destinationFolder.appendingPathComponent(fileName)

        // Check if destination already exists
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            showToast("A file named '\(fileName)' already exists", icon: "exclamationmark.triangle.fill")
            return false
        }

        // Check if file is git tracked
        guard let workspaceURL = workspaceURL else {
            return moveFileFileSystem(from: sourceURL, to: destinationURL)
        }

        let isGitTracked = LibGit2Service.shared.isFileTracked(sourceURL, in: workspaceURL)

        if isGitTracked {
            // Use git mv for tracked files
            if LibGit2Service.shared.moveFile(from: sourceURL, to: destinationURL, in: workspaceURL) {
                updateFileReferences(from: sourceURL, to: destinationURL)
                refreshWorkspaceFiles()
                showToast("File moved", icon: "arrow.right")
                return true
            } else {
                showToast("Failed to move file", icon: "exclamationmark.triangle.fill")
                return false
            }
        } else {
            // Use filesystem move for untracked files
            return moveFileFileSystem(from: sourceURL, to: destinationURL)
        }
    }

    /// Move file using filesystem operations
    private func moveFileFileSystem(from sourceURL: URL, to destinationURL: URL) -> Bool {
        do {
            try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
            updateFileReferences(from: sourceURL, to: destinationURL)
            refreshWorkspaceFiles()
            showToast("File moved", icon: "arrow.right")
            return true
        } catch {
            showToast("Failed to move file", icon: "exclamationmark.triangle.fill")
            return false
        }
    }

    /// Copy a file with automatic renaming if conflict exists
    func copyFile(from sourceURL: URL, to destinationFolder: URL) -> Bool {
        let fileName = sourceURL.lastPathComponent
        let fileExtension = sourceURL.pathExtension
        let baseName = fileName.replacingOccurrences(of: ".\(fileExtension)", with: "")

        var destinationURL = destinationFolder.appendingPathComponent(fileName)
        var counter = 1

        // Auto-rename if file exists
        while FileManager.default.fileExists(atPath: destinationURL.path) {
            let newName = fileExtension.isEmpty
                ? "\(baseName) copy \(counter)"
                : "\(baseName) copy \(counter).\(fileExtension)"
            destinationURL = destinationFolder.appendingPathComponent(newName)
            counter += 1
        }

        do {
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            refreshWorkspaceFiles()
            showToast("File duplicated", icon: "doc.on.doc")
            return true
        } catch {
            showToast("Failed to duplicate file", icon: "exclamationmark.triangle.fill")
            return false
        }
    }

    /// Move multiple files to a destination folder
    func moveFiles(_ sourceURLs: [URL], to destinationFolder: URL) -> Bool {
        var successCount = 0
        var failCount = 0

        for sourceURL in sourceURLs {
            if moveFile(from: sourceURL, to: destinationFolder) {
                successCount += 1
            } else {
                failCount += 1
            }
        }

        if failCount == 0 {
            showToast("Moved \(successCount) file\(successCount == 1 ? "" : "s")", icon: "arrow.right")
        } else {
            showToast("Moved \(successCount), failed \(failCount)", icon: "exclamationmark.triangle.fill")
        }

        return failCount == 0
    }

    /// Update all references when a file is moved
    private func updateFileReferences(from oldURL: URL, to newURL: URL) {
        // Update currently open document
        if currentDocument.fileURL == oldURL {
            currentDocument.fileURL = newURL
        }

        // Update recent files
        if let index = recentFiles.firstIndex(of: oldURL) {
            recentFiles[index] = newURL
            saveRecentFiles()
        }

        // Update favorites
        if let index = favoriteFiles.firstIndex(of: oldURL) {
            favoriteFiles[index] = newURL
            saveFavorites()
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
        ExportService.shared.exportAsPDF(document: currentDocument, showToast: showToast)
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
        let wordpressEmail = UserDefaults.standard.string(forKey: "plugin.wordpress.emailAddress") ?? ""

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

        // Check content length - mailto URLs have practical limits of ~2000-8000 chars
        // URL encoding makes it 2-3x longer, so we need to be conservative
        let estimatedEncodedLength = emailBody.count * 3

        if estimatedEncodedLength > 7000 {
            // Content too long for mailto URL - save to temp file and show instructions
            let tempDir = FileManager.default.temporaryDirectory
            let tempFile = tempDir.appendingPathComponent("\(title).html")

            do {
                try emailBody.write(to: tempFile, atomically: true, encoding: .utf8)
                NSWorkspace.shared.activateFileViewerSelecting([tempFile])

                showToast("Content too long for email. HTML file saved - copy content manually",
                         icon: "exclamationmark.triangle.fill", duration: 5.0)

                // Also copy to clipboard for convenience
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(emailBody, forType: .string)

                // Show dialog with instructions
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Document Too Long for Email"
                    alert.informativeText = """
                    Your document (\(emailBody.count) characters) exceeds email URL limits.

                    Options:
                    1. HTML file opened in Finder - manually attach to email
                    2. Content copied to clipboard - paste into email
                    3. Consider using WordPress API publishing instead

                    Send to: \(wordpressEmail)
                    Subject: \(title)
                    """
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
            } catch {
                showToast("Failed to save content: \(error.localizedDescription)",
                         icon: "exclamationmark.triangle.fill", duration: 3.0)
            }
            return
        }

        // URL encode the subject and body
        guard let encodedSubject = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedBody = emailBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            showToast("Failed to encode email", icon: "exclamationmark.triangle.fill")
            return
        }

        // Create mailto URL
        let mailtoURL = "mailto:\(wordpressEmail)?subject=\(encodedSubject)&body=\(encodedBody)"

        // Verify URL is not too long
        if mailtoURL.count > 8000 {
            showToast("Email content too long - try shorter document",
                     icon: "exclamationmark.triangle.fill", duration: 3.0)
            return
        }

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

    func printDocument() {
        ExportService.shared.printDocument(currentDocument)
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
