import Foundation
import AppKit
import UniformTypeIdentifiers

@MainActor
class FileOperationsService {
    static let shared = FileOperationsService()

    private init() {}

    // MARK: - File Operations

    /// Create a new file in the workspace
    func createFile(named name: String, in workspaceURL: URL) throws -> URL {
        let filename = name.hasSuffix(".md") ? name : "\(name).md"
        let fileURL = workspaceURL.appendingPathComponent(filename)

        try "".write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }

    /// Delete a file (moves to trash)
    func deleteFile(at url: URL) throws {
        try FileManager.default.trashItem(at: url, resultingItemURL: nil)
    }

    /// Rename a file
    func renameFile(at url: URL, to newName: String) throws -> URL {
        let newURL = url.deletingLastPathComponent().appendingPathComponent(newName)
        try FileManager.default.moveItem(at: url, to: newURL)
        return newURL
    }

    // MARK: - Document Operations

    /// Load document content from URL
    func loadDocument(from url: URL) throws -> (title: String, content: String) {
        let content = try String(contentsOf: url, encoding: .utf8)
        let title = url.deletingPathExtension().lastPathComponent
        return (title, content)
    }

    /// Save document content to URL
    func saveDocument(content: String, to url: URL) throws {
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    /// Show save panel and get URL for saving
    func showSavePanel(defaultName: String) -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "md")!]
        panel.nameFieldStringValue = defaultName

        guard panel.runModal() == .OK else { return nil }
        return panel.url
    }

    /// Show open panel and get URLs to open
    func showOpenPanel() -> [URL] {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.plainText, UTType(filenameExtension: "md")!]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK else { return [] }
        return panel.urls
    }

    /// Show workspace panel and get workspace URL
    func showWorkspacePanel() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK else { return nil }
        return panel.url
    }

    // MARK: - Workspace Operations

    /// Load workspace file tree
    func loadWorkspaceFiles(from url: URL) -> [FileItem] {
        var root = FileItem(url: url)
        root.loadChildren()
        return root.children ?? []
    }

    // MARK: - System Operations

    /// Reveal file in Finder
    func revealInFinder(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    /// Copy path to clipboard
    func copyPathToClipboard(_ url: URL) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url.path, forType: .string)
    }
}
