import Foundation

@MainActor
class WorkspaceService: ObservableObject {
    static let shared = WorkspaceService()

    // MARK: - Published State

    @Published var workspaceURL: URL?
    @Published var workspaceFiles: [FileItem] = []
    @Published private var allRecentFiles: [URL] = []
    @Published var favoriteFiles: [URL] = []

    // Computed property that filters out favorited files from recents
    var recentFiles: [URL] {
        allRecentFiles.filter { !favoriteFiles.contains($0) }
    }

    private let maxRecentFiles = 10

    private init() {
        loadRecentFiles()
        loadFavorites()
    }

    // MARK: - Workspace Operations

    func setWorkspace(_ url: URL) {
        workspaceURL = url
    }

    func closeWorkspace() {
        workspaceURL = nil
        workspaceFiles = []
    }

    func updateWorkspaceFiles(_ files: [FileItem]) {
        workspaceFiles = files
    }

    func clearWorkspaceFiles() {
        workspaceFiles = []
    }

    // MARK: - Recent Files

    private func loadRecentFiles() {
        if let data = UserDefaults.standard.data(forKey: "recentFiles"),
           let urls = try? JSONDecoder().decode([URL].self, from: data) {
            allRecentFiles = urls.filter { FileManager.default.fileExists(atPath: $0.path) }
        }
    }

    func addToRecentFiles(_ url: URL) {
        // Don't add to recents if it's already a favorite
        guard !favoriteFiles.contains(url) else { return }

        // Only reorder if this is a NEW file not already in recents
        if !allRecentFiles.contains(url) {
            allRecentFiles.insert(url, at: 0)
            if allRecentFiles.count > maxRecentFiles {
                allRecentFiles = Array(allRecentFiles.prefix(maxRecentFiles))
            }
            saveRecentFiles()
        }
        // If file already in recents, do nothing (don't reorder)
    }

    func removeFromRecentFiles(_ url: URL) {
        allRecentFiles.removeAll { $0 == url }
        saveRecentFiles()
    }

    func clearRecentFiles() {
        allRecentFiles = []
        saveRecentFiles()
    }

    func updateRecentFileURL(from oldURL: URL, to newURL: URL) {
        if let index = allRecentFiles.firstIndex(of: oldURL) {
            allRecentFiles[index] = newURL
            saveRecentFiles()
        }
    }

    private func saveRecentFiles() {
        if let data = try? JSONEncoder().encode(allRecentFiles) {
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

        // Remove from recents when adding to favorites
        removeFromRecentFiles(url)
    }

    func removeFromFavorites(_ url: URL) {
        favoriteFiles.removeAll { $0 == url }
        saveFavorites()

        // Add back to recents when removing from favorites
        addToRecentFiles(url)
    }

    func isFavorite(_ url: URL) -> Bool {
        favoriteFiles.contains(url)
    }

    func updateFavoriteURL(from oldURL: URL, to newURL: URL) {
        if let index = favoriteFiles.firstIndex(of: oldURL) {
            favoriteFiles[index] = newURL
            saveFavorites()
        }
    }

    private func saveFavorites() {
        if let data = try? JSONEncoder().encode(favoriteFiles) {
            UserDefaults.standard.set(data, forKey: "favoriteFiles")
        }
    }
}
