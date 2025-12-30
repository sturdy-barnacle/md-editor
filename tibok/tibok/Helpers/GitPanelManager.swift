//
//  GitPanelManager.swift
//  tibok
//
//  Manages NSPanel-based git modals to eliminate sheet dismissal flash.
//  Pattern inspired by EditorView's slash menu, date picker, and emoji picker.
//

import SwiftUI
import AppKit

@MainActor
class GitPanelManager: ObservableObject {

    // MARK: - Panel Windows

    private var commitPanel: NSPanel?
    private var branchPanel: NSPanel?
    private var diffPanel: NSPanel?
    private var historyPanel: NSPanel?

    // MARK: - Commit Panel

    func showCommitPanel(
        stagedCount: Int,
        onCommit: @escaping (String) -> Void,
        onCancel: @escaping () -> Void
    ) {
        dismissCommitPanel()

        var message = ""

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 230),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        panel.title = "Commit Changes"
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.becomesKeyOnlyIfNeeded = true

        let hostingView = NSHostingView(rootView:
            GitCommitSheet(
                message: Binding(
                    get: { message },
                    set: { message = $0 }
                ),
                stagedCount: stagedCount,
                onCommit: {
                    onCommit(message)
                    self.dismissCommitPanel()
                },
                onCancel: {
                    onCancel()
                    self.dismissCommitPanel()
                }
            )
        )
        panel.contentView = hostingView
        panel.center()

        commitPanel = panel
        panel.makeKeyAndOrderFront(nil)
    }

    func dismissCommitPanel() {
        commitPanel?.close()
        commitPanel = nil
    }

    // MARK: - Branch Panel

    func showBranchPanel(
        onCreate: @escaping (String) -> Void
    ) {
        dismissBranchPanel()

        var branchName = ""

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 150),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        panel.title = "New Branch"
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.becomesKeyOnlyIfNeeded = true

        let hostingView = NSHostingView(rootView:
            NewBranchSheet(
                branchName: Binding(
                    get: { branchName },
                    set: { branchName = $0 }
                ),
                onCreate: {
                    guard !branchName.isEmpty else {
                        self.dismissBranchPanel()
                        return
                    }
                    onCreate(branchName)
                    self.dismissBranchPanel()
                }
            )
        )
        panel.contentView = hostingView
        panel.center()

        branchPanel = panel
        panel.makeKeyAndOrderFront(nil)
    }

    func dismissBranchPanel() {
        branchPanel?.close()
        branchPanel = nil
    }

    // MARK: - Diff Panel

    func showDiffPanel(
        fileURL: URL,
        repoURL: URL,
        isStaged: Bool
    ) {
        dismissDiffPanel()

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 520),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        panel.title = "Diff: \(fileURL.lastPathComponent)"
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.becomesKeyOnlyIfNeeded = true
        panel.minSize = NSSize(width: 500, height: 300)

        let hostingView = NSHostingView(rootView:
            GitDiffView(
                fileURL: fileURL,
                repoURL: repoURL,
                isStaged: isStaged,
                onDismiss: { [weak self] in
                    self?.dismissDiffPanel()
                }
            )
        )
        panel.contentView = hostingView
        panel.center()

        diffPanel = panel
        panel.makeKeyAndOrderFront(nil)
    }

    func dismissDiffPanel() {
        diffPanel?.close()
        diffPanel = nil
    }

    // MARK: - History Panel

    func showHistoryPanel(repoURL: URL) {
        dismissHistoryPanel()

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 920, height: 620),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        panel.title = "Commit History"
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.becomesKeyOnlyIfNeeded = true
        panel.minSize = NSSize(width: 700, height: 400)

        let hostingView = NSHostingView(rootView:
            GitHistoryView(
                repoURL: repoURL,
                onDismiss: { [weak self] in
                    self?.dismissHistoryPanel()
                }
            )
        )
        panel.contentView = hostingView
        panel.center()

        historyPanel = panel
        panel.makeKeyAndOrderFront(nil)
    }

    func dismissHistoryPanel() {
        historyPanel?.close()
        historyPanel = nil
    }

    // MARK: - Cleanup

    func dismissAll() {
        dismissCommitPanel()
        dismissBranchPanel()
        dismissDiffPanel()
        dismissHistoryPanel()
    }
}
