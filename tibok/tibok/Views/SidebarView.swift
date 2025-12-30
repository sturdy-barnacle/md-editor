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
    @State private var contentSearchResults: [ContentSearchResult] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    @State private var showWorkspacePath = false

    @AppStorage("sidebar.showWorkspace") private var persistShowWorkspace = true
    @AppStorage("sidebar.showRecent") private var persistShowRecent = true
    @AppStorage("sidebar.showFavorites") private var persistShowFavorites = true
    // Default collapsed for distraction-free experience (brand alignment)
    @AppStorage("sidebar.showGit") private var persistShowGit = false
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

                            // File tree
                            ForEach(filteredWorkspaceFiles) { item in
                                FileTreeRow(item: item)
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
                if !newFileName.isEmpty {
                    appState.createFileInWorkspace(name: newFileName)
                    newFileName = ""
                }
                showNewFileSheet = false
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
    @State private var isExpanded = false
    @State private var loadedChildren: [FileItem]?
    @State private var hasFrontmatter: Bool = false
    @State private var isScanning: Bool = false

    init(item: FileItem, depth: Int = 0) {
        self.item = item
        self.depth = depth
        // Initialize with existing children if already loaded
        _loadedChildren = State(initialValue: item.children)
    }

    var body: some View {
        if item.isDirectory {
            DisclosureGroup(isExpanded: $isExpanded) {
                // Show loading indicator while scanning
                if isScanning {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.6)
                        Text("Scanning...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.leading, 20)
                }

                ForEach(loadedChildren ?? []) { child in
                    FileTreeRow(item: child, depth: depth + 1)
                }
            } label: {
                HStack {
                    Image(systemName: isExpanded ? "folder.fill" : "folder")
                        .foregroundColor(.blue)
                    Text(item.name)

                    // Show small spinner if scanning
                    if isScanning && !isExpanded {
                        ProgressView()
                            .scaleEffect(0.5)
                            .padding(.leading, 4)
                    }
                }
                .padding(.leading, CGFloat(depth * 16))
            }
            .contextMenu {
                Button("Reveal in Finder") {
                    appState.revealInFinder(item.url)
                }
                Button("Copy Path") {
                    appState.copyPathToClipboard(item.url)
                }
            }
            .onChange(of: isExpanded) { _, expanded in
                // Save expansion state to AppState
                appState.toggleFolderExpansion(item.url.path)

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
                isExpanded = appState.isFolderExpanded(item.url.path)
            }
        } else {
            Button {
                appState.loadDocument(from: item.url)
            } label: {
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
            }
            .buttonStyle(.animatedIcon)
            .onAppear {
                if !item.isDirectory {
                    hasFrontmatter = FrontmatterCacheService.shared.hasFrontmatter(url: item.url)
                }
            }
            .contextMenu {
                Button("Open") {
                    appState.loadDocument(from: item.url)
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
            }
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
