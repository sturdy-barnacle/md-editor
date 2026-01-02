//
//  GitPanelView.swift
//  tibok
//
//  Git changes panel showing staged and unstaged files with commit functionality.
//

import SwiftUI
import AppKit

/// Atomic state for diff preview to prevent race condition
struct DiffPresentationState: Equatable {
    let file: GitChangedFile
    let isStaged: Bool

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.file.id == rhs.file.id && lhs.isStaged == rhs.isStaged
    }
}

struct GitPanelView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var panelManager = GitPanelManager()
    @State private var diffState: DiffPresentationState?
    @State private var commitError: String?
    @State private var showError = false
    @State private var pushError: String?
    @State private var showPushErrorAlert = false
    @AppStorage("sidebar.showGit") private var persistShowGit = true

    let uiState = UIStateService.shared

    var body: some View {
        Section {
            if persistShowGit {
                // Branch selector
                if let currentBranch = appState.currentBranch {
                    Menu {
                        ForEach(appState.availableBranches, id: \.self) { branch in
                            Button {
                                let result = appState.switchBranch(to: branch)
                                if !result.success, let error = result.error {
                                    uiState.showToast(error, icon: "exclamationmark.triangle.fill", duration: 4.0)
                                }
                            } label: {
                                HStack {
                                    Text(branch)
                                    if branch == currentBranch {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                        Divider()
                        Button("New Branch...") {
                            panelManager.showBranchPanel { branchName in
                                let result = appState.createBranch(name: branchName, switchTo: true)
                                if !result.success, let error = result.error {
                                    uiState.showToast(error, icon: "exclamationmark.triangle.fill")
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.triangle.branch")
                                .foregroundColor(.purple)
                                .font(.system(size: 11))
                            Text(currentBranch)
                                .font(.system(size: 11, weight: .medium))
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 8)
                }

                // Staged changes section
                if !appState.stagedFiles.isEmpty {
                    DisclosureGroup {
                        ForEach(appState.stagedFiles, id: \.id) { file in
                            GitFileRow(file: file, isStaged: true) {
                                diffState = DiffPresentationState(file: file, isStaged: true)
                            }
                        }
                    } label: {
                        HStack {
                            Text("Staged")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.green)
                            Spacer()
                            Text("\(appState.stagedFiles.count)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Unstaged changes section
                if !appState.unstagedFiles.isEmpty {
                    DisclosureGroup {
                        ForEach(appState.unstagedFiles, id: \.id) { file in
                            GitFileRow(file: file, isStaged: false) {
                                diffState = DiffPresentationState(file: file, isStaged: false)
                            }
                        }
                    } label: {
                        HStack {
                            Text("Changes")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.blue)
                            Spacer()
                            Text("\(appState.unstagedFiles.count)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // No changes message
                if appState.stagedFiles.isEmpty && appState.unstagedFiles.isEmpty {
                    Text("No changes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                }

                // Action buttons
                HStack(spacing: 8) {
                    // Stage all button
                    if !appState.unstagedFiles.isEmpty {
                        Button {
                            appState.stageAll()
                        } label: {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.animatedIcon)
                        .help("Stage All")
                    }

                    // Unstage all button
                    if !appState.stagedFiles.isEmpty {
                        Button {
                            appState.unstageAll()
                        } label: {
                            Image(systemName: "minus.circle")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.animatedIcon)
                        .help("Unstage All")
                    }

                    // History button
                    Button {
                        if let repoURL = appState.workspaceURL {
                            panelManager.showHistoryPanel(repoURL: repoURL)
                        }
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.animatedIcon)
                    .help("Commit History")

                    // Open Remote button
                    Button {
                        openRemoteRepository()
                    } label: {
                        Image(systemName: "link")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.animatedIcon)
                    .help("Open Remote Repository")

                    Spacer()

                    // Commit button
                    if !appState.stagedFiles.isEmpty || !appState.unstagedFiles.isEmpty {
                        Button {
                            // Silently stage all unstaged files first
                            if !appState.unstagedFiles.isEmpty {
                                appState.stageAll()
                            }

                            panelManager.showCommitPanel(
                                stagedCount: appState.stagedFiles.count,
                                onCommit: { message in
                                    let result = appState.commitChanges(message: message)
                                    if result.success {
                                        appState.refreshGitStatus()
                                    } else {
                                        commitError = result.error
                                        showError = true
                                    }
                                },
                                onCancel: { }
                            )
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 11))
                                Text("Commit")
                                    .font(.system(size: 11))
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }

                    // Refresh button
                    Button {
                        appState.refreshGitStatus()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.animatedIcon)
                    .help("Refresh Status")

                    // Push button
                    Button {
                        uiState.showToast("Pushing...", icon: "arrow.up", duration: 1.0)
                        let result = appState.pushChanges()

                        if result.success {
                            if result.alreadyUpToDate {
                                uiState.showToast("Already up to date", icon: "checkmark.circle.fill", duration: 2.0)
                            } else {
                                uiState.showToast("Push successful", icon: "checkmark.circle.fill", duration: 2.0)
                            }
                        } else {
                            // Show detailed error alert instead of brief toast
                            pushError = result.error ?? "Unknown error occurred during push"
                            showPushErrorAlert = true
                        }
                    } label: {
                        Image(systemName: "arrow.up.circle")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.animatedIcon)
                    .help("Push")

                    // Pull button
                    Button {
                        uiState.showToast("Pulling...", icon: "arrow.down", duration: 1.0)
                        let result = appState.pullChanges()
                        uiState.showToast(
                            result.success ? "Pull successful" : "Pull failed: \(result.error ?? "unknown")",
                            icon: result.success ? "checkmark.circle.fill" : "xmark.circle",
                            duration: 2.0
                        )
                    } label: {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.animatedIcon)
                    .help("Pull")
                }
                .padding(.top, 4)
            }
        } header: {
            CollapsibleSectionHeader(
                title: "Git",
                isExpanded: $persistShowGit
            )
        }
        .onChange(of: diffState) { oldValue, newValue in
            if let state = newValue, let repoURL = appState.workspaceURL {
                panelManager.showDiffPanel(
                    fileURL: state.file.url,
                    repoURL: repoURL,
                    isStaged: state.isStaged
                )
                diffState = nil
            }
        }
        .alert("Commit Failed", isPresented: $showError) {
            Button("OK") {
                showError = false
            }
        } message: {
            Text(commitError ?? "Unknown error")
        }
        .alert("Push Failed", isPresented: $showPushErrorAlert) {
            Button("OK") {
                showPushErrorAlert = false
                pushError = nil
            }
            Button("Copy Error") {
                if let error = pushError {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(error, forType: .string)
                }
                showPushErrorAlert = false
                pushError = nil
            }
        } message: {
            if let error = pushError {
                Text(error)
            } else {
                Text("An unknown error occurred during push")
            }
        }
    }

    // MARK: - Helper Methods

    private func openRemoteRepository() {
        guard let repoURL = appState.workspaceURL else {
            uiState.showToast("No workspace open", icon: "exclamationmark.triangle.fill")
            return
        }

        // Get remote URL from git config
        let gitService = LibGit2Service.shared
        let (remoteURL, _) = gitService.getRemoteURL(for: repoURL)

        guard let remoteURL = remoteURL else {
            uiState.showToast("No remote repository configured", icon: "exclamationmark.triangle.fill", duration: 2.5)
            return
        }

        // Convert to web URL with current branch
        guard let webURL = gitService.convertToWebURL(remoteURL, branch: appState.currentBranch) else {
            uiState.showToast("Invalid remote URL format", icon: "exclamationmark.triangle.fill")
            return
        }

        // Open in default browser
        if let url = URL(string: webURL) {
            NSWorkspace.shared.open(url)
            uiState.showToast("Opening repository...", icon: "link", duration: 1.5)
        } else {
            uiState.showToast("Failed to open URL", icon: "exclamationmark.triangle.fill")
        }
    }
}

// MARK: - Git File Row

struct GitFileRow: View {
    @EnvironmentObject var appState: AppState
    let file: GitChangedFile
    let isStaged: Bool
    var onShowDiff: (() -> Void)?

    var body: some View {
        HStack(spacing: 4) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)

            // Filename - clickable to open file
            Button {
                appState.loadDocument(from: file.url)
            } label: {
                Text(file.filename)
                    .font(.system(size: 11))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
            .help("Open File")

            Spacer()

            // Diff button - only show for tracked files
            if file.status != .untracked {
                Button {
                    onShowDiff?()
                } label: {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.animatedIcon)
                .help("View Diff")
            }

            // Action buttons
            if isStaged {
                Button {
                    appState.unstageFile(file.url)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.animatedIcon)
                .help("Unstage")
            } else {
                Button {
                    appState.stageFile(file.url)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.animatedIcon)
                .help("Stage")

                if file.status != .untracked {
                    Button {
                        appState.discardChanges(file.url)
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.animatedIcon)
                    .help("Discard Changes")
                }
            }
        }
        .padding(.vertical, 1)
        .contextMenu {
            if file.status != .untracked {
                Button("View Diff") {
                    onShowDiff?()
                }
                Divider()
            }
            Button("Open File") {
                appState.loadDocument(from: file.url)
            }
            Divider()
            if isStaged {
                Button("Unstage") {
                    appState.unstageFile(file.url)
                }
            } else {
                Button("Stage") {
                    appState.stageFile(file.url)
                }
                if file.status != .untracked {
                    Button("Discard Changes", role: .destructive) {
                        appState.discardChanges(file.url)
                    }
                }
            }
            Divider()
            Button("Reveal in Finder") {
                appState.revealInFinder(file.url)
            }
        }
    }

    private var statusColor: Color {
        switch file.status {
        case .modified:
            return .blue
        case .added, .staged:
            return .green
        case .untracked:
            return .yellow
        case .unmerged:
            return .red
        case .deleted, .stagedDeleted:
            return .gray
        default:
            return .clear
        }
    }
}

// MARK: - Git Commit Sheet

struct GitCommitSheet: View {
    @Binding var message: String
    let stagedCount: Int
    let onCommit: () -> Void
    let onCancel: () -> Void
    @FocusState private var isMessageFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Commit Changes")
                    .font(.headline)
                Spacer()
            }

            // Staged count
            HStack {
                Text("\(stagedCount) file\(stagedCount == 1 ? "" : "s") staged")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }

            // Message input
            VStack(alignment: .leading, spacing: 4) {
                Text("Commit message")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextEditor(text: $message)
                    .font(.system(size: 13))
                    .frame(height: 80)
                    .scrollContentBackground(.hidden)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
                    .focused($isMessageFocused)
            }

            // Buttons
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Commit") {
                    onCommit()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 400)
        .onAppear {
            isMessageFocused = true
        }
    }
}

// MARK: - Animated Icon Button Style

struct AnimatedIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == AnimatedIconButtonStyle {
    static var animatedIcon: AnimatedIconButtonStyle {
        AnimatedIconButtonStyle()
    }
}

// MARK: - New Branch Sheet

struct NewBranchSheet: View {
    @Binding var branchName: String
    var onCreate: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            Text("New Branch")
                .font(.headline)

            TextField("Branch Name", text: $branchName)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .onSubmit {
                    if !branchName.isEmpty {
                        onCreate()
                    }
                }

            HStack {
                Button("Cancel") {
                    branchName = ""
                    onCreate()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Create") {
                    onCreate()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(branchName.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 300)
        .onAppear {
            isFocused = true
        }
    }
}
