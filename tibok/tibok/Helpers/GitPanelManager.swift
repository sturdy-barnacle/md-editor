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

        // Use a wrapper view that holds @State internally
        let hostingView = NSHostingView(rootView:
            CommitPanelWrapper(
                stagedCount: stagedCount,
                onCommit: { message in
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

        // Use a wrapper view that holds @State internally
        let hostingView = NSHostingView(rootView:
            BranchPanelWrapper(
                onCreate: { branchName in
                    onCreate(branchName)
                    self.dismissBranchPanel()
                },
                onCancel: {
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

// MARK: - Panel Wrapper Views
// These wrappers hold @State internally to ensure SwiftUI reactivity works correctly
// when embedded in NSHostingView inside NSPanel.

struct CommitPanelWrapper: View {
    let stagedCount: Int
    let onCommit: (String) -> Void
    let onCancel: () -> Void

    @State private var message = ""

    var body: some View {
        GitCommitSheet(
            message: $message,
            stagedCount: stagedCount,
            onCommit: { onCommit(message) },
            onCancel: onCancel
        )
    }
}

struct BranchPanelWrapper: View {
    let onCreate: (String) -> Void
    let onCancel: () -> Void

    @State private var branchName = ""

    var body: some View {
        NewBranchSheet(
            branchName: $branchName,
            onCreate: {
                guard !branchName.isEmpty else {
                    onCancel()
                    return
                }
                onCreate(branchName)
            }
        )
    }
}
