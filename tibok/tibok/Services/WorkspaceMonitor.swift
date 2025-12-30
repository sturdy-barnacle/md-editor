import Foundation

/// Monitors a workspace directory for file system changes
@MainActor
class WorkspaceMonitor: ObservableObject {
    private var monitorSource: DispatchSourceFileSystemObject?
    private var monitoredURL: URL?
    private var fileDescriptor: CInt = -1

    var onWorkspaceChanged: (() -> Void)?

    func startMonitoring(url: URL, onChange: @escaping () -> Void) {
        stopMonitoring()

        self.onWorkspaceChanged = onChange
        self.monitoredURL = url

        let path = url.path
        fileDescriptor = open(path, O_EVTONLY)

        guard fileDescriptor >= 0 else {
            print("WorkspaceMonitor: Failed to open directory at \(path)")
            return
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .delete, .rename],
            queue: DispatchQueue.main
        )

        source.setEventHandler { [weak self] in
            self?.handleFileSystemEvent()
        }

        source.setCancelHandler { [weak self] in
            guard let self = self, self.fileDescriptor >= 0 else { return }
            close(self.fileDescriptor)
            self.fileDescriptor = -1
        }

        source.resume()
        monitorSource = source

        print("WorkspaceMonitor: Started monitoring \(path)")
    }

    func stopMonitoring() {
        monitorSource?.cancel()
        monitorSource = nil
        monitoredURL = nil

        if fileDescriptor >= 0 {
            close(fileDescriptor)
            fileDescriptor = -1
        }
    }

    private func handleFileSystemEvent() {
        // 100ms debounce for batch operations
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000)
            onWorkspaceChanged?()
        }
    }

    deinit {
        // Cleanup file descriptor if still open
        // Note: We can't call stopMonitoring() here because deinit is non-async
        if fileDescriptor >= 0 {
            close(fileDescriptor)
        }
        monitorSource?.cancel()
    }
}
