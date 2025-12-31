//
//  SidebarView.swift
//  tibok
//
//  File tree sidebar with workspace navigation.
//

import SwiftUI
import AppKit

// MARK: - Visual Effect Background

/// NSVisualEffectView wrapper for SwiftUI - provides macOS translucent/vibrancy effect
struct VisualEffectBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    init(
        material: NSVisualEffectView.Material = .sidebar,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    ) {
        self.material = material
        self.blendingMode = blendingMode
    }

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .followsWindowActiveState
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

/// Result of searching file contents
struct ContentSearchResult: Identifiable {
    let id = UUID()
    let url: URL
    let matchingLine: String
    let lineNumber: Int
}

struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var showNewFileSheet = false
    @State private var newFileName = ""
    @State private var showFolderNewFileSheet = false
    @State private var newFolderFileName = ""
    @State private var selectedFolderURL: URL?
    @State private var showNewFolderSheet = false
    @State private var newFolderName = ""
    @State private var showRenameFolderSheet = false
    @State private var renameFolderName = ""
    @State private var selectedFolderForRename: URL?
    @State private var folderToDelete: URL?
    @State private var showDeleteFolderAlert = false
    @State private var fileToDelete: URL?
    @State private var showDeleteFileAlert = false

    // Multi-select state
    @State private var selectedFileURLs: Set<URL> = []
    @State private var lastSelectedURL: URL?
    @State private var contentSearchResults: [ContentSearchResult] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    @State private var showWorkspacePath = false

    @AppStorage("sidebar.showWorkspace") private var persistShowWorkspace = true
    @AppStorage("sidebar.showRecent") private var persistShowRecent = true
    @AppStorage("sidebar.showFavorites") private var persistShowFavorites = true
    // Note: persistShowGit is defined in GitPanelView.swift, not here
    @AppStorage("sidebar.showAI") private var persistShowAI = false

    var body: some View {
        VStack(spacing: 0) {
            // Minimal toolbar with icon-only buttons
            HStack(spacing: 12) {
                Button {
                    appState.openWorkspace()
                } label: {
                    Image(systemName: "folder")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.animatedIcon)
                .help("Open Workspace (⌘⇧O)")

                Button {
                    appState.openDocument()
                } label: {
                    Image(systemName: "doc")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.animatedIcon)
                .help("Open Document (⌘O)")

                Button {
                    appState.createNewDocument()
                } label: {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.animatedIcon)
                .help("New Document (⌘N)")

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)

            Divider()

            // Search field with inline results
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search files...", text: $searchText)
                        .textFieldStyle(.plain)
                        .onChange(of: searchText) { _, newValue in
                            performContentSearch(query: newValue)
                        }
                    if isSearching {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 16, height: 16)
                    } else if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            contentSearchResults = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.animatedIcon)
                    }
                }
                .padding(8)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(6)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)

                // Inline search results (below search field, not in list)
                if !contentSearchResults.isEmpty {
                    VStack(spacing: 0) {
                        HStack {
                            Text("\(contentSearchResults.count) results")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                            Spacer()
                            Button {
                                searchText = ""
                                contentSearchResults = []
                            } label: {
                                Text("Clear")
                                    .font(.system(size: 10))
                                    .foregroundColor(.accentColor)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)

                        ScrollView {
                            LazyVStack(spacing: 1) {
                                ForEach(contentSearchResults) { result in
                                    Button {
                                        appState.loadDocument(from: result.url)
                                    } label: {
                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack(spacing: 4) {
                                                Image(systemName: "doc.text")
                                                    .foregroundColor(.secondary)
                                                    .font(.system(size: 10))
                                                Text(result.url.lastPathComponent)
                                                    .font(.system(size: 11, weight: .medium))
                                                Text(":\(result.lineNumber)")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.secondary)
                                            }
                                            Text(result.matchingLine.trimmingCharacters(in: .whitespaces))
                                                .font(.system(size: 10))
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                    }
                                    .buttonStyle(.animatedIcon)
                                }
                            }
                        }
                        .frame(maxHeight: 150)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    }
                    .background(Color(NSColor.textBackgroundColor))
                }
            }

            Divider()

            // File tree (simplified - removed Open section, search results moved above)
            List {
                // MARK: - 1. Workspace Section
                if let workspaceURL = appState.workspaceURL {
                    Section {
                        if persistShowWorkspace {
                            // Workspace folder row with path tooltip
                            HoverableCloseRow {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.blue)
                                Text(workspaceURL.lastPathComponent)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                            } onClose: {
                                appState.closeWorkspace()
                            }
                            .help(workspaceURL.path)
                            .contextMenu {
                                Button("New File...") {
                                    showNewFileSheet = true
                                }
                                Divider()
                                Button("Copy Path") {
                                    appState.copyPathToClipboard(workspaceURL)
                                }
                                Button("Reveal in Finder") {
                                    appState.revealInFinder(workspaceURL)
                                }
                                Divider()
                                Button("Close Workspace") {
                                    appState.closeWorkspace()
                                }
                            }

                            // Selection toolbar (appears when files are selected)
                            if !selectedFileURLs.isEmpty {
                                HStack(spacing: 8) {
                                    Text("\(selectedFileURLs.count) selected")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.white)

                                    Spacer()

                                    Button("Clear") {
                                        selectedFileURLs.removeAll()
                                        lastSelectedURL = nil
                                    }
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white)
                                    .buttonStyle(.plain)

                                    if appState.isGitRepository {
                                        Button("Stage") {
                                            guard appState.workspaceURL != nil else { return }
                                            for url in selectedFileURLs {
                                                appState.stageFile(url)
                                            }
                                            selectedFileURLs.removeAll()
                                        }
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white)
                                        .buttonStyle(.plain)
                                    }

                                    Button("Delete") {
                                        appState.deleteFiles(Array(selectedFileURLs))
                                        selectedFileURLs.removeAll()
                                        lastSelectedURL = nil
                                    }
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white)
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.accentColor)
                                .cornerRadius(6)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                            }

                            // File tree
                            ForEach(filteredWorkspaceFiles) { item in
                                FileTreeRow(item: item,
                                    onNewFileInFolder: { folderURL in
                                        selectedFolderURL = folderURL
                                        showFolderNewFileSheet = true
                                    },
                                    onNewFolderInFolder: { folderURL in
                                        selectedFolderURL = folderURL
                                        showNewFolderSheet = true
                                    },
                                    onRenameFolder: { folderURL, currentName in
                                        selectedFolderForRename = folderURL
                                        renameFolderName = currentName
                                        showRenameFolderSheet = true
                                    },
                                    onDeleteFolder: { folderURL in
                                        folderToDelete = folderURL
                                        showDeleteFolderAlert = true
                                    },
                                    onDeleteFile: { fileURL in
                                        fileToDelete = fileURL
                                        showDeleteFileAlert = true
                                    },
                                    selectedFileURLs: $selectedFileURLs,
                                    onFileClick: handleFileSelection
                                )
                            }
                        }
                    } header: {
                        CollapsibleSectionHeader(
                            title: "Workspace",
                            isExpanded: $persistShowWorkspace,
                            trailing: {
                                // New file button
                                Button {
                                    showNewFileSheet = true
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.animatedIcon)
                                .help("New file in workspace")
                            }
                        )
                    }
                }

                // MARK: - 2. Favorites Section
                if !appState.favoriteFiles.isEmpty {
                    Section {
                        if persistShowFavorites {
                            ForEach(appState.favoriteFiles, id: \.self) { url in
                                FavoriteFileRow(url: url)
                            }
                        }
                    } header: {
                        CollapsibleSectionHeader(
                            title: "Favorites",
                            isExpanded: $persistShowFavorites,
                            count: appState.favoriteFiles.count
                        )
                    }
                }

                // MARK: - 3. Recent Files Section
                Section {
                    if persistShowRecent {
                        ForEach(filteredRecentFiles, id: \.self) { url in
                            RecentFileRow(url: url)
                        }

                        if appState.recentFiles.isEmpty && appState.hasNoDocuments {
                            Text("No recent files")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        } else if !appState.recentFiles.isEmpty {
                            Button {
                                appState.clearRecentFiles()
                            } label: {
                                Label("Clear Recent", systemImage: "trash")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            .font(.caption)
                        }
                    }
                } header: {
                    CollapsibleSectionHeader(
                        title: "Recent",
                        isExpanded: $persistShowRecent
                    )
                }

                // MARK: - 4. Git Section (collapsed by default)
                if appState.isGitRepository {
                    GitPanelView()
                        .environmentObject(appState)
                }
            }
            .listStyle(.sidebar)

            // Bottom action - only show when no documents (avoid redundancy with editor empty state)
            if appState.hasNoDocuments && appState.workspaceURL == nil {
                Divider()
                Button {
                    appState.createNewDocument()
                } label: {
                    Label("New Document", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(8)
            }
        }
        .background(VisualEffectBackground(material: .sidebar))
        .sheet(isPresented: $showNewFileSheet) {
            NewFileSheet(fileName: $newFileName) {
                guard !newFileName.isEmpty else {
                    showNewFileSheet = false
                    newFileName = ""
                    return
                }

                // Only close sheet if file creation succeeds
                if appState.createFileInWorkspace(name: newFileName) {
                    showNewFileSheet = false
                    newFileName = ""
                }
            }
        }
        .sheet(isPresented: $showFolderNewFileSheet) {
            NewFileSheet(fileName: $newFolderFileName) {
                guard !newFolderFileName.isEmpty, let folderURL = selectedFolderURL else {
                    showFolderNewFileSheet = false
                    newFolderFileName = ""
                    return
                }

                // Only close sheet if file creation succeeds
                if appState.createFileInFolder(folderURL: folderURL, name: newFolderFileName) {
                    showFolderNewFileSheet = false
                    newFolderFileName = ""
                }
            }
        }
        .sheet(isPresented: $showNewFolderSheet) {
            NewFolderSheet(folderName: $newFolderName) {
                guard !newFolderName.isEmpty else {
                    showNewFolderSheet = false
                    newFolderName = ""
                    return
                }

                // Create in selected folder or workspace root
                let success = if let folderURL = selectedFolderURL {
                    appState.createFolderInFolder(parentURL: folderURL, name: newFolderName)
                } else {
                    appState.createFolderInWorkspace(name: newFolderName)
                }

                if success {
                    showNewFolderSheet = false
                    newFolderName = ""
                }
            }
        }
        .sheet(isPresented: $showRenameFolderSheet) {
            RenameFolderSheet(folderName: $renameFolderName) {
                guard !renameFolderName.isEmpty, let folderURL = selectedFolderForRename else {
                    showRenameFolderSheet = false
                    renameFolderName = ""
                    return
                }

                appState.renameFolder(at: folderURL, to: renameFolderName)
                showRenameFolderSheet = false
                renameFolderName = ""
            }
        }
        .alert("Delete Folder", isPresented: $showDeleteFolderAlert) {
            Button("Cancel", role: .cancel) {
                folderToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let url = folderToDelete {
                    appState.deleteFolder(at: url)
                    folderToDelete = nil
                }
            }
        } message: {
            if let url = folderToDelete {
                Text("Are you sure you want to move '\(url.lastPathComponent)' to the trash?")
            }
        }
        .alert("Delete File", isPresented: $showDeleteFileAlert) {
            Button("Cancel", role: .cancel) {
                fileToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let url = fileToDelete {
                    appState.deleteFile(at: url)
                    fileToDelete = nil
                }
            }
        } message: {
            if let url = fileToDelete {
                Text("Are you sure you want to move '\(url.lastPathComponent)' to the trash?")
            }
        }
    }

    private var filteredWorkspaceFiles: [FileItem] {
        if searchText.isEmpty {
            return appState.workspaceFiles
        }
        return filterFiles(appState.workspaceFiles, searchText: searchText)
    }

    private var filteredRecentFiles: [URL] {
        if searchText.isEmpty {
            return appState.recentFiles
        }
        return appState.recentFiles.filter {
            $0.lastPathComponent.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func filterFiles(_ files: [FileItem], searchText: String) -> [FileItem] {
        files.compactMap { item in
            if item.name.localizedCaseInsensitiveContains(searchText) {
                return item
            }
            if let children = item.children, !children.isEmpty {
                let filteredChildren = filterFiles(children, searchText: searchText)
                if !filteredChildren.isEmpty {
                    var copy = item
                    copy.children = filteredChildren
                    return copy
                }
            }
            return nil
        }
    }

    private func performContentSearch(query: String) {
        searchTask?.cancel()

        guard !query.isEmpty, query.count >= 2, let workspaceURL = appState.workspaceURL else {
            contentSearchResults = []
            isSearching = false
            return
        }

        isSearching = true

        // Collect file URLs synchronously on main thread to avoid Swift 6 concurrency warning
        let fileManager = FileManager.default
        let resourceKeys: [URLResourceKey] = [.isRegularFileKey, .isDirectoryKey]
        let textExtensions = ["md", "txt", "markdown", "csv", "json", "yaml", "yml"]

        guard let enumerator = fileManager.enumerator(
            at: workspaceURL,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles]
        ) else {
            isSearching = false
            return
        }

        // Collect all file URLs synchronously
        var fileURLs: [URL] = []
        for case let fileURL as URL in enumerator {
            let resourceValues = try? fileURL.resourceValues(forKeys: Set(resourceKeys))
            guard resourceValues?.isRegularFile == true else { continue }
            guard textExtensions.contains(fileURL.pathExtension.lowercased()) else { continue }
            fileURLs.append(fileURL)
        }

        // Process files asynchronously
        searchTask = Task {
            var results: [ContentSearchResult] = []

            for fileURL in fileURLs {
                if Task.isCancelled { break }

                if let content = try? String(contentsOf: fileURL, encoding: .utf8) {
                    let lines = content.components(separatedBy: .newlines)
                    for (index, line) in lines.enumerated() {
                        if line.localizedCaseInsensitiveContains(query) {
                            results.append(ContentSearchResult(
                                url: fileURL,
                                matchingLine: line,
                                lineNumber: index + 1
                            ))
                            if results.count >= 50 { break }
                        }
                    }
                }
                if results.count >= 50 { break }
            }

            if !Task.isCancelled {
                await MainActor.run {
                    contentSearchResults = results
                    isSearching = false
                }
            }
        }
    }

    // MARK: - Multi-Select Helper Methods

    /// Handle file selection with modifier keys
    private func handleFileSelection(_ url: URL, modifiers: NSEvent.ModifierFlags) {
        if modifiers.contains(.command) {
            // Command-click: toggle selection
            if selectedFileURLs.contains(url) {
                selectedFileURLs.remove(url)
            } else {
                selectedFileURLs.insert(url)
            }
            lastSelectedURL = url
        } else if modifiers.contains(.shift), let lastURL = lastSelectedURL {
            // Shift-click: range selection
            selectRange(from: lastURL, to: url)
        } else {
            // Normal click: clear selection and open file
            selectedFileURLs.removeAll()
            lastSelectedURL = nil
            appState.loadDocument(from: url)
        }
    }

    /// Select all files in range from one URL to another
    private func selectRange(from startURL: URL, to endURL: URL) {
        let allFiles = flattenFileTree(appState.workspaceFiles)
        guard let startIndex = allFiles.firstIndex(of: startURL),
              let endIndex = allFiles.firstIndex(of: endURL) else {
            return
        }

        let range = min(startIndex, endIndex)...max(startIndex, endIndex)
        for index in range {
            selectedFileURLs.insert(allFiles[index])
        }
    }

    /// Flatten file tree into ordered list of file URLs
    private func flattenFileTree(_ items: [FileItem]) -> [URL] {
        var urls: [URL] = []
        for item in items {
            if !item.isDirectory {
                urls.append(item.url)
            }
            if let children = item.children {
                urls.append(contentsOf: flattenFileTree(children))
            }
        }
        return urls
    }
}

// MARK: - Collapsible Section Header

struct CollapsibleSectionHeader<Trailing: View>: View {
    let title: String
    @Binding var isExpanded: Bool
    var count: Int? = nil
    var trailing: (() -> Trailing)?

    init(
        title: String,
        isExpanded: Binding<Bool>,
        count: Int? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.title = title
        self._isExpanded = isExpanded
        self.count = count
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: 6) {
            // Clickable area for toggle (title + chevron)
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 12)

                    Text(title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)

                    if let count = count {
                        Text("\(count)")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary.opacity(0.7))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(4)
                    }
                }
            }
            .buttonStyle(.animatedIcon)

            Spacer()

            // Trailing content (e.g., plus button)
            if let trailing = trailing {
                trailing()
            }
        }
        .contentShape(Rectangle())
    }
}

// Extension for headers without trailing content
extension CollapsibleSectionHeader where Trailing == EmptyView {
    init(title: String, isExpanded: Binding<Bool>, count: Int? = nil) {
        self.title = title
        self._isExpanded = isExpanded
        self.count = count
        self.trailing = nil
    }
}

// MARK: - Open Document Row

struct OpenDocumentRow: View {
    @EnvironmentObject var appState: AppState
    let doc: Document
    let isActive: Bool

    var body: some View {
        Button {
            appState.switchToTab(id: doc.id)
        } label: {
            HStack {
                Image(systemName: doc.fileURL != nil ? "doc.text.fill" : "doc.text")
                    .foregroundColor(doc.fileURL != nil ? .blue : .orange)
                Text(doc.fileURL?.lastPathComponent ?? "Untitled.md")
                    .fontWeight(isActive ? .medium : .regular)
                if doc.isModified {
                    Circle()
                        .fill(Color.primary.opacity(0.5))
                        .frame(width: 6, height: 6)
                }
                Spacer()
                if isActive {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(.animatedIcon)
        .contextMenu {
            if isActive {
                Button("Save") {
                    appState.saveCurrentDocument()
                }
                Button("Save As...") {
                    appState.saveDocumentAs()
                }
                Divider()
            }
            if let url = doc.fileURL {
                if appState.isFavorite(url) {
                    Button("Remove from Favorites") {
                        appState.removeFromFavorites(url)
                    }
                } else {
                    Button("Add to Favorites") {
                        appState.addToFavorites(url)
                    }
                }
                Divider()
                Button("Reveal in Finder") {
                    appState.revealInFinder(url)
                }
                Button("Copy Path") {
                    appState.copyPathToClipboard(url)
                }
                Divider()
            }
            Button("Close Tab") {
                appState.closeTab(id: doc.id)
            }
            Button("Close Other Tabs") {
                appState.closeOtherTabs(except: doc.id)
            }
        }
    }
}

// MARK: - Recent File Row

struct RecentFileRow: View {
    @EnvironmentObject var appState: AppState
    let url: URL
    @State private var hasFrontmatter: Bool = false

    var body: some View {
        Button {
            appState.loadDocument(from: url)
        } label: {
            HStack {
                Label(url.lastPathComponent, systemImage: "doc.text")
                Spacer()
                if hasFrontmatter {
                    Image(systemName: "doc.badge.gearshape")
                        .font(.system(size: 9))
                        .foregroundColor(.purple.opacity(0.6))
                }
                if appState.isFavorite(url) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.pink)
                }
            }
        }
        .buttonStyle(.animatedIcon)
        .onAppear {
            hasFrontmatter = FrontmatterCacheService.shared.hasFrontmatter(url: url)
        }
        .contextMenu {
            Button("Open") {
                appState.loadDocument(from: url)
            }
            Divider()
            if appState.isFavorite(url) {
                Button("Remove from Favorites") {
                    appState.removeFromFavorites(url)
                }
            } else {
                Button("Add to Favorites") {
                    appState.addToFavorites(url)
                }
            }
            Divider()
            Button("Reveal in Finder") {
                appState.revealInFinder(url)
            }
            Button("Copy Path") {
                appState.copyPathToClipboard(url)
            }
            Divider()
            Button("Remove from Recent", role: .destructive) {
                appState.removeFromRecentFiles(url)
            }
        }
    }
}

// MARK: - Favorite File Row

struct FavoriteFileRow: View {
    @EnvironmentObject var appState: AppState
    let url: URL
    @State private var hasFrontmatter: Bool = false

    var body: some View {
        Button {
            appState.loadDocument(from: url)
        } label: {
            HStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.pink)
                Text(url.lastPathComponent)
                Spacer()
                if hasFrontmatter {
                    Image(systemName: "doc.badge.gearshape")
                        .font(.system(size: 9))
                        .foregroundColor(.purple.opacity(0.6))
                }
            }
        }
        .buttonStyle(.animatedIcon)
        .onAppear {
            hasFrontmatter = FrontmatterCacheService.shared.hasFrontmatter(url: url)
        }
        .contextMenu {
            Button("Open") {
                appState.loadDocument(from: url)
            }
            Divider()
            Button("Remove from Favorites") {
                appState.removeFromFavorites(url)
            }
            Divider()
            Button("Reveal in Finder") {
                appState.revealInFinder(url)
            }
            Button("Copy Path") {
                appState.copyPathToClipboard(url)
            }
        }
    }
}

// MARK: - File Tree Row

struct FileTreeRow: View {
    @EnvironmentObject var appState: AppState
    let item: FileItem
    let depth: Int
    var onNewFileInFolder: ((URL) -> Void)?
    var onNewFolderInFolder: ((URL) -> Void)?
    var onRenameFolder: ((URL, String) -> Void)?
    var onDeleteFolder: ((URL) -> Void)?
    var onDeleteFile: ((URL) -> Void)?
    var selectedFileURLs: Binding<Set<URL>>?
    var onFileClick: ((URL, NSEvent.ModifierFlags) -> Void)?
    @State private var isExpanded = false
    @State private var loadedChildren: [FileItem]?
    @State private var hasFrontmatter: Bool = false
    @State private var isScanning: Bool = false

    init(item: FileItem, depth: Int = 0, onNewFileInFolder: ((URL) -> Void)? = nil, onNewFolderInFolder: ((URL) -> Void)? = nil, onRenameFolder: ((URL, String) -> Void)? = nil, onDeleteFolder: ((URL) -> Void)? = nil, onDeleteFile: ((URL) -> Void)? = nil, selectedFileURLs: Binding<Set<URL>>? = nil, onFileClick: ((URL, NSEvent.ModifierFlags) -> Void)? = nil) {
        self.item = item
        self.depth = depth
        self.onNewFileInFolder = onNewFileInFolder
        self.onNewFolderInFolder = onNewFolderInFolder
        self.onRenameFolder = onRenameFolder
        self.onDeleteFolder = onDeleteFolder
        self.onDeleteFile = onDeleteFile
        self.selectedFileURLs = selectedFileURLs
        self.onFileClick = onFileClick
        // Initialize with existing children if already loaded
        _loadedChildren = State(initialValue: item.children)
    }

    var body: some View {
        if item.isDirectory {
            VStack(alignment: .leading, spacing: 0) {
                // Folder row with manual disclosure control
                HStack(spacing: 4) {
                    // Disclosure triangle button
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(width: 12, height: 12)
                    }
                    .buttonStyle(.plain)

                    Image(systemName: isExpanded ? "folder.fill" : "folder")
                        .foregroundColor(depth == 0 ? .blue : .blue.opacity(0.7))
                        .font(.system(size: depth == 0 ? 14 : 13))
                    Text(item.name)
                        .fontWeight(depth == 0 ? .semibold : .regular)

                    // Show heart if favorited
                    if appState.isFavorite(item.url) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.pink)
                    }

                    // Show small spinner if scanning
                    if isScanning && !isExpanded {
                        ProgressView()
                            .scaleEffect(0.5)
                            .padding(.leading, 4)
                    }

                    Spacer()
                }
                .padding(.leading, CGFloat(depth * 16))
                .contentShape(Rectangle())

                // Expanded content
                if isExpanded {
                    // Show loading indicator while scanning
                    if isScanning {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.6)
                            Text("Scanning...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, CGFloat((depth + 1) * 16) + 16)
                    }

                    ForEach(loadedChildren ?? []) { child in
                        FileTreeRow(item: child, depth: depth + 1, onNewFileInFolder: onNewFileInFolder, onNewFolderInFolder: onNewFolderInFolder, onRenameFolder: onRenameFolder, onDeleteFolder: onDeleteFolder, onDeleteFile: onDeleteFile, selectedFileURLs: selectedFileURLs, onFileClick: onFileClick)
                    }
                }
            }
            .contextMenu {
                Button("New File...") {
                    onNewFileInFolder?(item.url)
                }
                Button("New Folder...") {
                    onNewFolderInFolder?(item.url)
                }
                Divider()
                Button("Rename...") {
                    onRenameFolder?(item.url, item.name)
                }
                Divider()
                if appState.isFavorite(item.url) {
                    Button("Remove from Favorites") {
                        appState.removeFromFavorites(item.url)
                    }
                } else {
                    Button("Add to Favorites") {
                        appState.addToFavorites(item.url)
                    }
                }
                Divider()
                Button("Reveal in Finder") {
                    appState.revealInFinder(item.url)
                }
                Button("Copy Path") {
                    appState.copyPathToClipboard(item.url)
                }
                Divider()
                Button("Delete Folder", role: .destructive) {
                    onDeleteFolder?(item.url)
                }
            }
            .dropDestination(for: URL.self) { droppedURLs, _ in
                // Handle file drop on folder
                guard let fileURL = droppedURLs.first else { return false }
                return appState.moveFile(from: fileURL, to: item.url)
            }
            .onChange(of: isExpanded) { _, expanded in
                print("🔄 [FileTreeRow] onChange: \(item.name) isExpanded=\(expanded)")
                // Only update AppState if it differs (prevents toggle on restoration from onAppear)
                if appState.isFolderExpanded(item.url.path) != expanded {
                    appState.setFolderExpanded(item.url.path, expanded: expanded)
                }

                if expanded && loadedChildren == nil {
                    // Lazy load children on first expand
                    var mutableItem = item
                    mutableItem.loadChildren()

                    if appState.smartFilteringEnabled {
                        // Show loading indicator and filter in background
                        isScanning = true
                        let childrenToFilter = mutableItem.children ?? []

                        Task {
                            var filteredChildren: [FileItem] = []

                            for var child in childrenToFilter {
                                if child.isDirectory {
                                    let containsMarkdown = await FolderScanCache.shared.scanFolder(at: child.url)
                                    if containsMarkdown {
                                        filteredChildren.append(child)
                                    } else {
                                        child.isFiltered = true
                                    }
                                } else {
                                    filteredChildren.append(child)
                                }
                            }

                            await MainActor.run {
                                loadedChildren = filteredChildren
                                isScanning = false
                            }
                        }
                    } else {
                        // No filtering - show all children
                        loadedChildren = mutableItem.children
                    }
                }
            }
            .onAppear {
                // Initialize expansion state from AppState
                let savedExpansion = appState.isFolderExpanded(item.url.path)
                print("👁️ [FileTreeRow] onAppear: \(item.name) savedExpansion=\(savedExpansion) current=\(isExpanded)")
                isExpanded = savedExpansion
            }
            .onChange(of: item.children) { _, newChildren in
                // Update cached children when item.children changes (e.g., after workspace refresh)
                if isExpanded && newChildren != nil {
                    loadedChildren = newChildren
                }
            }
        } else {
            HStack {
                Image(systemName: fileIcon(for: item))
                    .foregroundColor(fileColor(for: item))
                Text(item.name)
                Spacer()
                // Show frontmatter indicator
                if hasFrontmatter {
                    Image(systemName: "doc.badge.gearshape")
                        .font(.system(size: 9))
                        .foregroundColor(.purple.opacity(0.6))
                }
                // Show heart if favorited
                if appState.isFavorite(item.url) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.pink)
                }
                // Show indicator if modified in open tabs
                if appState.documents.first(where: { $0.fileURL == item.url })?.isModified == true {
                    Circle()
                        .fill(Color.primary.opacity(0.5))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.leading, CGFloat(depth * 16))
            .padding(.vertical, 3)
            .padding(.horizontal, 8)
            .background(
                // Selection highlight
                (selectedFileURLs?.wrappedValue.contains(item.url) ?? false)
                    ? Color.accentColor.opacity(0.2)
                    : Color.clear
            )
            .cornerRadius(4)
            .contentShape(Rectangle())
            .onTapGesture {
                // Handle clicks with modifier detection
                let modifiers = NSEvent.modifierFlags
                if let onFileClick = onFileClick {
                    onFileClick(item.url, modifiers)
                } else {
                    appState.loadDocument(from: item.url)
                }
            }
            .onAppear {
                if !item.isDirectory {
                    hasFrontmatter = FrontmatterCacheService.shared.hasFrontmatter(url: item.url)
                }
            }
            .contextMenu {
                Button("Open") {
                    appState.loadDocument(from: item.url)
                }
                Button("Duplicate") {
                    // Duplicate in same folder
                    let parentFolder = item.url.deletingLastPathComponent()
                    _ = appState.copyFile(from: item.url, to: parentFolder)
                }
                Divider()
                if appState.isFavorite(item.url) {
                    Button("Remove from Favorites") {
                        appState.removeFromFavorites(item.url)
                    }
                } else {
                    Button("Add to Favorites") {
                        appState.addToFavorites(item.url)
                    }
                }
                Divider()
                Button("Reveal in Finder") {
                    appState.revealInFinder(item.url)
                }
                Button("Copy Path") {
                    appState.copyPathToClipboard(item.url)
                }
                Divider()
                Button("Delete File", role: .destructive) {
                    onDeleteFile?(item.url)
                }
            }
            .draggable(item.url)
        }
    }

    private func fileIcon(for item: FileItem) -> String {
        let ext = item.url.pathExtension.lowercased()
        switch ext {
        case "md", "markdown":
            return "doc.text.fill"
        case "txt":
            return "doc.text"
        case "json":
            return "curlybraces"
        case "yaml", "yml":
            return "list.bullet.indent"
        case "csv":
            return "tablecells"
        default:
            return "doc"
        }
    }

    private func fileColor(for item: FileItem) -> Color {
        let ext = item.url.pathExtension.lowercased()
        switch ext {
        case "md", "markdown":
            return .blue
        case "json":
            return .orange
        case "yaml", "yml":
            return .purple
        default:
            return .secondary
        }
    }
}

// MARK: - Hoverable Close Row

struct HoverableCloseRow<Content: View>: View {
    @ViewBuilder var content: Content
    var onClose: () -> Void
    @State private var isHovering = false

    var body: some View {
        HStack {
            content
            Spacer()
            if isHovering {
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.animatedIcon)
            }
        }
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - New File Sheet

struct NewFileSheet: View {
    @Binding var fileName: String
    var onCreate: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            Text("New File")
                .font(.headline)

            TextField("Filename.md", text: $fileName)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .onSubmit {
                    if !fileName.isEmpty {
                        onCreate()
                    }
                }

            HStack {
                Button("Cancel") {
                    fileName = ""
                    onCreate()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Create") {
                    onCreate()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(fileName.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 300)
        .onAppear {
            isFocused = true
        }
    }
}

// MARK: - New Folder Sheet

struct NewFolderSheet: View {
    @Binding var folderName: String
    var onCreate: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            Text("New Folder")
                .font(.headline)

            TextField("Folder Name", text: $folderName)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .onSubmit {
                    if !folderName.isEmpty {
                        onCreate()
                    }
                }

            HStack {
                Button("Cancel") {
                    folderName = ""
                    onCreate()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Create") {
                    onCreate()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(folderName.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 300)
        .onAppear {
            isFocused = true
        }
    }
}

// MARK: - Rename Folder Sheet

struct RenameFolderSheet: View {
    @Binding var folderName: String
    var onRename: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            Text("Rename Folder")
                .font(.headline)

            TextField("Folder Name", text: $folderName)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .onSubmit {
                    if !folderName.isEmpty {
                        onRename()
                    }
                }

            HStack {
                Button("Cancel") {
                    onRename()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Rename") {
                    onRename()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(folderName.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 300)
        .onAppear {
            isFocused = true
        }
    }
}
