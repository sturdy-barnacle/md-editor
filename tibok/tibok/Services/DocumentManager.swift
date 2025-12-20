import Foundation
import AppKit
import UniformTypeIdentifiers

@MainActor
class DocumentManager: ObservableObject {
    static let shared = DocumentManager()

    // MARK: - Published State

    @Published var documents: [Document] = []
    @Published var activeDocumentID: UUID?
    @Published var closedTabs: [Document] = []  // For "reopen last closed tab"

    private let maxClosedTabs = 10

    private init() {}

    // MARK: - Computed Properties

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

    // MARK: - Document Operations

    func createNewDocument() {
        let doc = Document.new()
        documents.append(doc)
        activeDocumentID = doc.id
    }

    func addDocument(_ doc: Document, makeActive: Bool = true) {
        documents.append(doc)
        if makeActive {
            activeDocumentID = doc.id
        }
    }

    func updateDocument(id: UUID, content: String) {
        guard let index = documents.firstIndex(where: { $0.id == id }) else { return }
        documents[index].content = content
        documents[index].isModified = true
    }

    func updateActiveDocumentContent(_ content: String) {
        guard let index = activeDocumentIndex else { return }
        documents[index].content = content
        documents[index].isModified = true
    }

    func markDocumentSaved(id: UUID, url: URL) {
        guard let index = documents.firstIndex(where: { $0.id == id }) else { return }
        documents[index].fileURL = url
        documents[index].isModified = false
        documents[index].lastSaved = Date()
        documents[index].title = url.deletingPathExtension().lastPathComponent
    }

    func updateDocumentFileURL(from oldURL: URL, to newURL: URL) {
        guard let index = documents.firstIndex(where: { $0.fileURL == oldURL }) else { return }
        documents[index].fileURL = newURL
        documents[index].title = newURL.deletingPathExtension().lastPathComponent
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

    func closeTab(id: UUID, savePrompt: ((Document) -> Bool)? = nil) {
        guard let index = documents.firstIndex(where: { $0.id == id }) else { return }
        let doc = documents[index]

        // Check for unsaved changes
        if doc.isModified, let savePrompt = savePrompt {
            let shouldClose = savePrompt(doc)
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
    }

    func closeCurrentTab(savePrompt: ((Document) -> Bool)? = nil) {
        guard let id = activeDocumentID else { return }
        closeTab(id: id, savePrompt: savePrompt)
    }

    func closeOtherTabs(except id: UUID, savePrompt: ((Document) -> Bool)? = nil) {
        let documentsToClose = documents.filter { $0.id != id }
        for doc in documentsToClose {
            if doc.isModified, let savePrompt = savePrompt {
                let shouldClose = savePrompt(doc)
                if !shouldClose { continue }
            }
            closedTabs.insert(doc, at: 0)
        }
        documents = documents.filter { $0.id == id }
        if closedTabs.count > maxClosedTabs {
            closedTabs = Array(closedTabs.prefix(maxClosedTabs))
        }
    }

    func closeAllTabs(savePrompt: ((Document) -> Bool)? = nil) {
        for doc in documents {
            if doc.isModified, let savePrompt = savePrompt {
                let shouldClose = savePrompt(doc)
                if !shouldClose { continue }
            }
            closedTabs.insert(doc, at: 0)
        }
        documents = []
        activeDocumentID = nil
        if closedTabs.count > maxClosedTabs {
            closedTabs = Array(closedTabs.prefix(maxClosedTabs))
        }
    }

    func reopenLastClosedTab(loadFromDisk: ((URL) -> Void)? = nil) {
        guard let doc = closedTabs.first else { return }
        closedTabs.removeFirst()

        // If it had a file URL, try to reload from disk
        if let url = doc.fileURL, FileManager.default.fileExists(atPath: url.path), let loadFromDisk = loadFromDisk {
            loadFromDisk(url)
        } else {
            // Restore the in-memory document
            documents.append(doc)
            activeDocumentID = doc.id
        }
    }

    func moveTab(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex,
              sourceIndex >= 0, sourceIndex < documents.count,
              destinationIndex >= 0, destinationIndex < documents.count else { return }

        let doc = documents.remove(at: sourceIndex)
        documents.insert(doc, at: destinationIndex)
    }

    // MARK: - Tab Persistence

    func loadOpenTabs(from urls: [URL], activeURL: URL?, loader: (URL) throws -> (title: String, content: String)) {
        for url in urls {
            if FileManager.default.fileExists(atPath: url.path) {
                do {
                    let (title, content) = try loader(url)
                    let doc = Document(
                        title: title,
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
        if let activeURL = activeURL,
           let doc = documents.first(where: { $0.fileURL == activeURL }) {
            activeDocumentID = doc.id
        } else if let firstDoc = documents.first {
            activeDocumentID = firstDoc.id
        }
    }

    func getOpenTabsInfo() -> (tabURLs: [URL], activeURL: URL?) {
        let tabURLs = documents.compactMap { $0.fileURL }
        let activeURL = activeDocument?.fileURL
        return (tabURLs, activeURL)
    }
}
